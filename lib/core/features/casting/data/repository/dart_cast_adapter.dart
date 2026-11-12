import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/data_source/transcode_settings.dart';
import 'package:pure_cast/core/features/casting/data/data_source/receiver_codec_memory.dart';

/// Concrete adapter wrapping dart_cast package services.
class DartCastAdapter implements ICastService {
  final dart_cast.CastService _castService;

  StreamSubscription<dart_cast.SessionState>? _sessionStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  // Subtitle track ID mapping keyed by subtitle URL, per active session.
  final Map<String, int> _subtitleTrackIds = <String, int>{};

  final StreamController<PureCastSessionState> _sessionStateController =
      StreamController<PureCastSessionState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  PureCastDevice? _currentDevice;
  PureCastSessionState _currentState = PureCastSessionState.disconnected;

  @factoryMethod
  DartCastAdapter({dart_cast.CastService? castService})
    : _castService =
          castService ??
          dart_cast.CastService(
            discoveryProviders: [
              dart_cast.ChromecastDiscoveryProvider(),
              dart_cast.DlnaDiscoveryProvider(),
            ],
            sessionFactory: (device) {
              switch (device.protocol) {
                case dart_cast.CastProtocol.chromecast:
                  return dart_cast.ChromecastSession(device: device);
                case dart_cast.CastProtocol.dlna:
                  return dart_cast.DlnaSession.fromDevice(device);
                case dart_cast.CastProtocol.airplay:
                  throw UnsupportedError('AirPlay is not enabled for V1');
              }
            },
          );

  @override
  Stream<List<PureCastDevice>> discoverDevices({
    Set<PureCastProtocol>? protocols,
  }) {
    final targetProtocols = protocols != null
        ? protocols.map(_mapProtocolToDartCast).toSet()
        : {dart_cast.CastProtocol.chromecast, dart_cast.CastProtocol.dlna};

    return _castService
        .startDiscovery(protocols: targetProtocols)
        .map((devices) => devices.map(_mapDeviceToDomain).toList());
  }

  @override
  Future<void> stopDiscovery() async {
    _castService.stopDiscovery();
  }

  @override
  Future<void> connect(PureCastDevice device) async {
    try {
      final dartDevice = _mapDeviceToDartCast(device);
      final session = await _castService.connect(dartDevice);
      _currentDevice = device;

      _subscribeToSession(session);
    } catch (e) {
      print("Error connecting to device ${device.name}: $e");
      throw PureCastException('Failed to connect to ${device.name}', e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      final session = _castService.activeSession;
      if (session != null) {
        await session.disconnect();
      }
      _currentDevice = null;
      _updateState(PureCastSessionState.disconnected);
    } catch (e) {
      throw PureCastException('Failed to disconnect from device', e);
    }
  }

  @override
  Future<void> loadMedia(PureCastMedia media) async {
    if (media.isLocalFile) {
      try {
        return await loadLocalFile(media.uri, subtitles: media.subtitles);
      } catch (e) {
        // Only fall back to direct load for probe failures.
        if (shouldFallbackToDirect(e)) {
          final session = _castService.activeSession;
          if (session == null) rethrow;
          try {
            final dartMedia = _mapMediaToDartCast(media);
            await session.loadMedia(dartMedia);
            return;
          } catch (e2) {
            throw PureCastException('Failed to load media: ${media.title}', e2);
          }
        }
        // Surface all other errors without fallback.
        throw PureCastException(e.toString(), e);
      }
    }
    final session = _castService.activeSession;
    if (session == null) {
      throw const PureCastException('No active cast session');
    }

    try {
      final dartMedia = _mapMediaToDartCast(media);
      await session.loadMedia(dartMedia);

      // dart_cast may return from loadMedia() once the receiver acknowledges
      // the LOAD, but the session might still be idle/disconnected if the
      // receiver rejected the media (e.g., unsupported format, unreachable
      // proxy URL). Guard against calling play() on a dead session.
      final state = session.state;
      if (state == dart_cast.SessionState.idle ||
          state == dart_cast.SessionState.disconnected) {
        throw PureCastException(
          'Receiver rejected media: ${media.title} (session state: $state)',
        );
      }
    } on PureCastException {
      rethrow;
    } catch (e) {
      throw PureCastException('Failed to load media: ${media.title}', e);
    }
  }

  Future<dart_cast.CastDeviceCaps> _detectCaps() async {
    final caps = await dart_cast.CastFfmpegCapabilities.detect();
    final transcodeEnabled = await TranscodeSettings.isEnabled();
    return dart_cast.CastDeviceCaps(
      supportsHevc: caps.supportsHevc,
      hasH264Encoder: caps.hasH264Encoder,
      hasLibx264: caps.hasLibx264,
      hasH264Mediacodec: caps.hasH264Mediacodec,
      transcodeEnabled: transcodeEnabled && caps.hasH264Encoder,
      modelName: caps.modelName,
    );
  }

  @override
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    PureCastSubtitleTrack? subtitle,
    List<PureCastSubtitleTrack>? subtitles,
    String? forcePlan,
    bool waitForFinish = false,
    bool includeDuration = false,
    String streamType = 'BUFFERED',
    String? hlsSegmentFormat,
    String? hlsVideoSegmentFormat,
  }) async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active cast session');
    try {
      final effectiveSubtitle = subtitle ?? (subtitles != null && subtitles.isNotEmpty ? subtitles.first : null);
      final dartSubtitle = effectiveSubtitle != null ? _mapSubtitleToDartCast(effectiveSubtitle) : null;
      if (session is dart_cast.ChromecastSession) {
        await session.loadLocalFile(
          path,
          audioStreamIndex: audioStreamIndex,
          // Detect FFmpeg capabilities at runtime instead of hardcoding false.
          caps: await _detectCaps(),
          forcePlan: forcePlan,
          subtitle: dartSubtitle,
          waitForFinish: waitForFinish,
          includeDuration: includeDuration,
          streamType: streamType,
          hlsSegmentFormat: hlsSegmentFormat,
          hlsVideoSegmentFormat: hlsVideoSegmentFormat,
          memoryLookup: (receiverId, codecKey) =>
              ReceiverCodecMemory.lookup(receiverId, codecKey),
          memoryRecord: (receiverId, codecKey, directOk) =>
              ReceiverCodecMemory.record(receiverId, codecKey, directOk),
        );
      } else {
        // DLNA / others: direct load
        await loadMedia(PureCastMedia(
          uri: path,
          type: PureCastMediaType.video,
          title: '',
          isLocalFile: true,
          subtitles: subtitle != null ? [subtitle] : const [],
        ));
      }
    } catch (e) {
      // Rethrow typed dart_cast exceptions as-is so callers can inspect
      // the concrete type (e.g. ProbeFailedException for fallback).
      if (e is dart_cast.ProbeFailedException ||
          e is dart_cast.UnsupportedMediaException ||
          e is dart_cast.PrepareFailedException ||
          e is dart_cast.MediaLoadFailedException) {
        rethrow;
      }
      throw PureCastException('Failed to load local file: $path — ${e.toString()}', e);
    }
  }

  @override
  Future<void> play() async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
      // If the receiver is already playing (e.g., autoplay from LOAD), skip.
      if (session.state == dart_cast.SessionState.playing) return;
      await session.play();
    } catch (e) {
      throw PureCastException('Failed to send play command', e);
    }
  }

  @override
  Future<void> pause() async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
      if (session.state == dart_cast.SessionState.paused ||
          session.state == dart_cast.SessionState.idle ||
          session.state == dart_cast.SessionState.disconnected) {
        return;
      }
      await session.pause();
    } catch (e) {
      throw PureCastException('Failed to send pause command', e);
    }
  }

  @override
  Future<void> stop() async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
      if (session.state == dart_cast.SessionState.idle ||
          session.state == dart_cast.SessionState.disconnected) {
        return;
      }
      await session.stop();
    } catch (e) {
      throw PureCastException('Failed to send stop command', e);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
      if (session.state == dart_cast.SessionState.idle ||
          session.state == dart_cast.SessionState.disconnected) {
        throw const PureCastException('No active media session to seek');
      }
      await session.seek(position);
    } catch (e) {
      throw PureCastException('Failed to seek', e);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
      final clamped = volume.clamp(0.0, 1.0);
      await session.setVolume(clamped);
    } catch (e) {
      throw PureCastException('Failed to set volume', e);
    }
  }

  @override
  Future<void> setSubtitle(PureCastSubtitleTrack? subtitle) async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
      final dartSubtitle = subtitle != null
          ? _mapSubtitleToDartCast(subtitle)
          : null;
      log('PureCast: setSubtitle -> ${dartSubtitle?.url ?? 'None'}');
      await session.setSubtitle(dartSubtitle);
      log('PureCast: setSubtitle completed');
    } catch (e) {
      log('PureCast: setSubtitle error: $e');
      throw PureCastException('Failed to set subtitle', e);
    }
  }

  @override
  Future<String> getDebugMediaStatus() async {
    final session = _castService.activeSession;
    if (session == null) return 'no session';
    final buf = StringBuffer();
    buf.writeln('sessionState=${session.state}');
    buf.writeln('position=${session.position}');
    buf.writeln('duration=${session.duration}');
    if (session is dart_cast.ChromecastSession) {
      buf.writeln('mediaSessionId=${session.mediaSessionId}');
      buf.writeln('idleReason=${session.idleReason ?? "<none>"}');
    }
    return buf.toString();
  }

  @override
  Stream<PureCastSessionState> get sessionStateStream =>
      _sessionStateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  PureCastDevice? get currentDevice => _currentDevice;

  @override
  PureCastSessionState get currentState => _currentState;

  @override
  Future<void> dispose() async {
    _bufferingDebounceTimer?.cancel();
    _sessionStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _subtitleTrackIds.clear();
    _sessionStateController.close();
    _positionController.close();
    _durationController.close();
    await _castService.dispose();
  }

  // ── Subscriptions & Helpers ──
  Timer? _bufferingDebounceTimer;

  void _subscribeToSession(dart_cast.CastSession session) {
    _sessionStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _bufferingDebounceTimer?.cancel();

    _sessionStateSub = session.stateStream.listen((state) {
      final domainState = _mapStateToDomain(state);

      if (domainState == PureCastSessionState.buffering &&
          _currentState == PureCastSessionState.playing) {
        // Debounce transient buffering status returned during periodic position polling.
        // If buffering lasts longer than 1.5 seconds, emit buffering.
        _bufferingDebounceTimer?.cancel();
        _bufferingDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
          _updateState(PureCastSessionState.buffering);
        });
        return;
      }

      _bufferingDebounceTimer?.cancel();
      _updateState(domainState);
    });

    _positionSub = session.positionStream.listen((pos) {
      _positionController.add(pos);
    });

    _durationSub = session.durationStream.listen((dur) {
      _durationController.add(dur);
    });
  }

  void _updateState(PureCastSessionState newState) {
    _currentState = newState;
    _sessionStateController.add(newState);
  }

  // ── Data Mappers ──
  static PureCastDevice _mapDeviceToDomain(dart_cast.CastDevice d) {
    final protocol = _mapProtocolToDomain(d.protocol);
    return PureCastDevice(
      id: d.id,
      name: d.name,
      protocol: protocol,
      host: d.address.address,
      port: d.port,
      capabilities: PureCastCapabilities.forProtocol(protocol),
    );
  }

  static dart_cast.CastDevice _mapDeviceToDartCast(PureCastDevice d) {
    return dart_cast.CastDevice(
      id: d.id,
      name: d.name,
      protocol: _mapProtocolToDartCast(d.protocol),
      address: InternetAddress(d.host),
      port: d.port,
    );
  }

  static PureCastProtocol _mapProtocolToDomain(dart_cast.CastProtocol p) {
    switch (p) {
      case dart_cast.CastProtocol.chromecast:
        return PureCastProtocol.chromecast;
      case dart_cast.CastProtocol.dlna:
        return PureCastProtocol.dlna;
      case dart_cast.CastProtocol.airplay:
        return PureCastProtocol.chromecast;
    }
  }

  static dart_cast.CastProtocol _mapProtocolToDartCast(PureCastProtocol p) {
    switch (p) {
      case PureCastProtocol.chromecast:
        return dart_cast.CastProtocol.chromecast;
      case PureCastProtocol.dlna:
        return dart_cast.CastProtocol.dlna;
    }
  }

  static PureCastSessionState _mapStateToDomain(dart_cast.SessionState s) {
    switch (s) {
      case dart_cast.SessionState.disconnected:
        return PureCastSessionState.disconnected;
      case dart_cast.SessionState.connecting:
        return PureCastSessionState.connecting;
      case dart_cast.SessionState.connected:
        return PureCastSessionState.connected;
      case dart_cast.SessionState.loading:
        return PureCastSessionState.loading;
      case dart_cast.SessionState.playing:
        return PureCastSessionState.playing;
      case dart_cast.SessionState.paused:
        return PureCastSessionState.paused;
      case dart_cast.SessionState.buffering:
        return PureCastSessionState.buffering;
      case dart_cast.SessionState.idle:
        return PureCastSessionState.completed;
    }
  }

  static dart_cast.CastMedia _mapMediaToDartCast(PureCastMedia m) {
    final mediaType = _mapMediaTypeToDartCast(m.type);
    final subtitles = m.subtitles.map(_mapSubtitleToDartCast).toList();

    if (m.isLocalFile) {
      return dart_cast.CastMedia.file(
        filePath: m.uri,
        type: mediaType,
        title: m.title,
        imageUrl: m.thumbnailUrl,
        duration: m.duration,
        subtitles: subtitles,
        defaultSubtitle: m.defaultSubtitle != null ? _mapSubtitleToDartCast(m.defaultSubtitle!) : null,
      );
    } else {
      return dart_cast.CastMedia(
        url: m.uri,
        type: mediaType,
        title: m.title,
        imageUrl: m.thumbnailUrl,
        duration: m.duration,
        subtitles: subtitles,
        defaultSubtitle: m.defaultSubtitle != null ? _mapSubtitleToDartCast(m.defaultSubtitle!) : null,
      );
    }
  }

  static dart_cast.CastMediaType _mapMediaTypeToDartCast(PureCastMediaType t) {
    switch (t) {
      case PureCastMediaType.hls:
        return dart_cast.CastMediaType.hls;
      case PureCastMediaType.mp4:
        return dart_cast.CastMediaType.mp4;
      case PureCastMediaType.mkv:
        return dart_cast.CastMediaType.mkv;
      case PureCastMediaType.video:
        return dart_cast.CastMediaType.mp4;
      case PureCastMediaType.audio:
        return dart_cast.CastMediaType.mp4;
    }
  }

  static dart_cast.CastSubtitle _mapSubtitleToDartCast(
    PureCastSubtitleTrack s,
  ) {
    // dart_cast's registerSubtitle() checks for 'file://' prefix to decide
    // whether to serve the file locally (registerFile) or proxy it remotely
    // (registerMedia). Local file paths must be prefixed with 'file://' so
    // they are served through the local HTTP proxy correctly.
    final url = s.url.startsWith('/') ? 'file://${s.url}' : s.url;
    debugPrint('[SUBDBG] _mapSubtitleToDartCast url=$url format=vtt label=${s.label}');
    return dart_cast.CastSubtitle(
      url: url,
      label: s.label.isNotEmpty ? s.label : s.language,
      language: s.language.isNotEmpty ? s.language : 'und',
      format: 'vtt',
    );
  }

  /// Pure decision: should we fall back to direct load for this exception?
  ///
  /// Only probe failures trigger a fallback. All other errors (typed
  /// dart_cast exceptions, wrapped PureCastExceptions, etc.) are surfaced
  /// without retrying.
  static bool shouldFallbackToDirect(Object e) {
    if (e is dart_cast.ProbeFailedException) return true;
    // Handle wrapped form: PureCastException with originalError = ProbeFailedException
    if (e is PureCastException && e.originalError is dart_cast.ProbeFailedException) {
      return true;
    }
    return false;
  }
}
