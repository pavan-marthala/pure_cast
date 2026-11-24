import 'dart:async';

import 'dart:developer';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/data_source/airplay_credential_store.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/data_source/transcode_settings.dart';
import 'package:pure_cast/core/features/casting/data/data_source/receiver_codec_memory.dart';
import 'package:pure_cast/core/features/casting/data/repository/live_timeline_mapper.dart';

/// Probes a local file and returns the media information needed to map audio
/// tracks. Injectable so tests can avoid starting FFmpeg.
typedef DartCastMediaProbe = Future<dart_cast.MediaProbe?> Function(
  String path,
);

/// Returns the FFmpeg/transcode capabilities for local-file preparation.
typedef DartCastCapsProvider = Future<dart_cast.CastDeviceCaps> Function();

/// Concrete adapter wrapping dart_cast package services.
class DartCastAdapter implements ICastService {
  final dart_cast.CastService _castService;
  final DartCastMediaProbe _mediaProbe;
  final DartCastCapsProvider _capsProvider;

  StreamSubscription<dart_cast.SessionState>? _sessionStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  // Subtitle track ID mapping keyed by subtitle URL, per active session.
  final Map<String, int> _subtitleTrackIds = <String, int>{};

  /// Maps live receiver time onto the source-file timeline and guards the
  /// restart race (see [LiveTimelineMapper]).
  final LiveTimelineMapper _liveTimeline = LiveTimelineMapper();

  /// Last duration value pushed to [durationStream], used to avoid duplicate
  /// live-duration emissions when the receiver reports no duration at all.
  Duration? _lastDurationEmitted;

  final StreamController<PureCastSessionState> _sessionStateController =
      StreamController<PureCastSessionState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  PureCastSessionState _currentState = PureCastSessionState.disconnected;

  @factoryMethod
  DartCastAdapter({
    dart_cast.CastService? castService,
    DartCastMediaProbe? mediaProbe,
    DartCastCapsProvider? capsProvider,
    dart_cast.MediaProber? prober,
  }) : _castService =
           castService ??
           dart_cast.CastService(
             discoveryProviders: defaultDiscoveryProviders(),
             sessionFactory: defaultSessionFactory,
           ),
       _mediaProbe =
           mediaProbe ??
           _probeWithProber(prober ?? const dart_cast.FfprobeMediaProber()),
       _capsProvider = capsProvider ?? _detectCaps;

  /// Discovery providers used when the adapter creates its own service.
  static List<dart_cast.DeviceDiscoveryProvider> defaultDiscoveryProviders() =>
      [
        dart_cast.ChromecastDiscoveryProvider(),
        dart_cast.DlnaDiscoveryProvider(),
        dart_cast.AirPlayDiscoveryProvider(),
      ];

  /// Session factory used when the adapter creates its own service.
  static dart_cast.CastSession defaultSessionFactory(
    dart_cast.CastDevice device,
  ) {
    switch (device.protocol) {
      case dart_cast.CastProtocol.chromecast:
        return dart_cast.ChromecastSession(device: device);
      case dart_cast.CastProtocol.dlna:
        return dart_cast.DlnaSession.fromDevice(device);
      case dart_cast.CastProtocol.airplay:
        final session = dart_cast.AirPlaySession(device);
        // Reuse a previous pair-setup so the receiver does not ask for a PIN
        // again. The cache is loaded before connect() creates the session.
        session.credentials = AirPlayCredentialStore.instance.credentialsFor(
          device.id,
        );
        return session;
    }
  }

  /// Protocols scanned when the caller does not pass a filter.
  static const Set<PureCastProtocol> defaultProtocols = {
    PureCastProtocol.chromecast,
    PureCastProtocol.dlna,
    PureCastProtocol.airplay,
  };

  @override
  Stream<List<PureCastDevice>> discoverDevices({
    Set<PureCastProtocol>? protocols,
  }) {
    final targetProtocols = protocols != null
        ? protocols.map(mapProtocolToDartCast).toSet()
        : defaultProtocols.map(mapProtocolToDartCast).toSet();

    return _castService
        .startDiscovery(protocols: targetProtocols)
        .map((devices) => devices.map(mapDeviceToDomain).toList());
  }

  @override
  Future<void> stopDiscovery() async {
    _castService.stopDiscovery();
  }

  @override
  Future<void> connect(PureCastDevice device) async {
    try {
      // AirPlay session factories are synchronous, so credentials must be in
      // the cache before the package creates the session.
      await AirPlayCredentialStore.instance.ensureLoaded();
      final dartDevice = mapDeviceToDartCast(device);
      final session = await _castService.connect(dartDevice);

      _subscribeToSession(session);
    } on dart_cast.NeedsPairingException catch (e) {
      // Stored credentials that no longer verify are useless; drop them so
      // the next attempt asks for a PIN instead of failing the same way.
      await AirPlayCredentialStore.instance.delete(device.id);
      throw PairingRequiredException(device.id, device.name, e);
    } catch (e) {
      dart_cast.CastLogger.error(
        'PureCast: connect failed to ${device.name}: $e',
      );
      throw PureCastException('Failed to connect to ${device.name}', e);
    }
  }

  @override
  Future<void> connectWithPin(PureCastDevice device, String pin) async {
    final session = _castService.pendingPairingSession;
    if (session is! dart_cast.AirPlaySession) {
      throw PureCastException(
        'No pending AirPlay pairing session for ${device.name}',
      );
    }

    try {
      final credentials = await session.pairSetup(pin);
      await AirPlayCredentialStore.instance.save(device.id, credentials);
    } catch (e) {
      dart_cast.CastLogger.error(
        'PureCast: pairing failed with ${device.name}: $e',
      );
      throw PureCastException('Failed to pair with ${device.name}', e);
    }

    try {
      final connected = await _castService.completePendingConnect(
        mapDeviceToDartCast(device),
      );
      _subscribeToSession(connected);
    } catch (e) {
      dart_cast.CastLogger.error(
        'PureCast: connect after pairing failed to ${device.name}: $e',
      );
      throw PureCastException(
        'Pairing succeeded but connecting to ${device.name} failed',
        e,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    final session = _castService.activeSession;
    try {
      if (session != null) {
        await session.disconnect();
      }
    } catch (e) {
      throw PureCastException('Failed to disconnect from device', e);
    } finally {
      // Forget the session even if its teardown threw, so the next connect does
      // not try to disconnect it again.
      _castService.clearActiveSession();
    }
    _updateState(PureCastSessionState.disconnected);
  }

  @override
  Future<void> loadMedia(
    PureCastMedia media, {
    bool bypassTransform = false,
  }) async {
    if (media.isLocalFile) {
      try {
        return await loadLocalFile(
          media.uri,
          subtitle: media.defaultSubtitle,
          subtitles: media.subtitles,
        );
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
      await session.loadMedia(dartMedia, bypassTransform: bypassTransform);

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

  static Future<dart_cast.CastDeviceCaps> _detectCaps() async {
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
  Future<void> switchLiveAudio({
    required String filePath,
    required int audioIndex,
    required Duration position,
    required String streamType,
    Duration? duration,
    List<PureCastAudioTrack>? audioTracks,
  }) async {
    final session = _castService.activeSession;
    if (session == null) {
      throw const PureCastException('No active cast session');
    }
    // Drop late position events from the media session being replaced.
    _liveTimeline.armRestart(session.liveSessionToken);
    try {
      await session.switchLiveAudio(
        filePath: filePath,
        audioIndex: audioIndex,
        position: position,
        streamType: streamType,
        duration: duration,
        audioTracks: audioTracks
            ?.map(
              (t) => dart_cast.AudioStream(
                index: t.index,
                codec: t.codec,
                channels: t.channels,
                language: t.language.isEmpty ? null : t.language,
                isDefault: t.isDefault,
              ),
            )
            .toList(growable: false),
      );
    } catch (e) {
      _liveTimeline.cancel();
      throw PureCastException('Failed to switch live audio: $filePath', e);
    }
  }

  @override
  Future<void> switchLiveSubtitle({
    required PureCastSubtitleTrack? subtitle,
    required Duration position,
  }) async {
    final session = _castService.activeSession;
    if (session == null) {
      throw const PureCastException('No active cast session');
    }
    // A subtitle restarts the live stream (new playback session) exactly like
    // an audio switch, so late events from the replaced session must be
    // dropped. Disabling subtitles on Chromecast keeps the session, but the
    // guard is harmless there because no replacement happens.
    if (subtitle != null) {
      _liveTimeline.armRestart(session.liveSessionToken);
    }
    try {
      await session.switchLiveSubtitle(
        subtitle: subtitle != null ? _mapSubtitleToDartCast(subtitle) : null,
        position: position,
      );
    } on dart_cast.SubtitleAttachException catch (e) {
      if (subtitle != null) _liveTimeline.cancel();
      // The message is user-facing and deliberately path-free.
      dart_cast.CastLogger.error('PureCast: switch live subtitle failed: $e');
      rethrow;
    } catch (e) {
      if (subtitle != null) _liveTimeline.cancel();
      dart_cast.CastLogger.error(
        'PureCast: switch live subtitle failed (${e.runtimeType})',
      );
      throw PureCastException('Failed to switch live subtitle', e);
    }
  }

  @override
  Future<List<PureCastAudioTrack>> probeAudioTracks(String filePath) async {
    final probe = await _mediaProbe(filePath);
    if (probe == null) return const [];
    return [
      for (var i = 0; i < probe.audio.length; i++)
        PureCastAudioTrack(
          index: i,
          language: probe.audio[i].language ?? '',
          codec: probe.audio[i].codec,
          channels: probe.audio[i].channels,
          isDefault: probe.audio[i].isDefault,
        ),
    ];
  }

  /// Default probe used in production, backed by a [dart_cast.MediaProber].
  ///
  /// The prober resolves `file://` paths and applies its default 8 s timeout.
  /// A probe failure becomes null, so [probeAudioTracks] returns an empty list
  /// instead of throwing (the bloc also guards with its own timeout).
  static DartCastMediaProbe _probeWithProber(dart_cast.MediaProber prober) {
    return (String path) async {
      try {
        return await prober.probe(path);
      } on dart_cast.ProbeFailedException {
        return null;
      }
    };
  }

  @override
  Duration get liveStartOffset {
    return _castService.activeSession?.liveStartOffset ?? Duration.zero;
  }

  @override
  bool get isLiveStream {
    return _castService.activeSession?.isLive ?? false;
  }

  @override
  List<PureCastAudioTrack> get audioTracks {
    final session = _castService.activeSession;
    if (session == null) return const [];
    // Protocol-neutral: live sessions report their live tracks and AirPlay
    // reports the tracks found while preparing a local file.
    final streams = session.audioTracks;
    return [
      for (var i = 0; i < streams.length; i++)
        PureCastAudioTrack(
          index: i,
          language: streams[i].language ?? '',
          codec: streams[i].codec,
          channels: streams[i].channels,
          isDefault: streams[i].isDefault,
        ),
    ];
  }

  @override
  int get activeAudioIndex {
    return _castService.activeSession?.activeAudioIndex ?? 0;
  }

  @override
  Duration get position =>
      _castService.activeSession?.position ?? Duration.zero;

  @override
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    PureCastSubtitleTrack? subtitle,
    List<PureCastSubtitleTrack>? subtitles,
    String streamType = 'BUFFERED',
  }) async {
    final session = _castService.activeSession;
    if (session == null) {
      throw const PureCastException('No active cast session');
    }
    try {
      final effectiveSubtitle =
          subtitle ??
          (subtitles != null && subtitles.isNotEmpty ? subtitles.first : null);
      final dartSubtitle = effectiveSubtitle != null
          ? _mapSubtitleToDartCast(effectiveSubtitle)
          : null;
      if (session is dart_cast.ChromecastSession) {
        await session.loadLocalFile(
          path,
          audioStreamIndex: audioStreamIndex,
          // Detect FFmpeg capabilities at runtime instead of hardcoding false.
          caps: await _capsProvider(),
          subtitle: dartSubtitle,
          streamType: streamType,
          memoryLookup: (receiverId, codecKey) =>
              ReceiverCodecMemory.lookup(receiverId, codecKey),
          memoryRecord: (receiverId, codecKey, directOk) =>
              ReceiverCodecMemory.record(receiverId, codecKey, directOk),
        );
      } else {
        // DLNA probes and plans the file itself (direct / remux / transcode).
        await session.loadLocalFile(
          path,
          audioStreamIndex: audioStreamIndex,
          caps: await _capsProvider(),
          subtitle: dartSubtitle,
          streamType: streamType,
        );
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
      throw PureCastException(
        'Failed to load local file: $path — ${e.toString()}',
        e,
      );
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
    final isLive = session.isLive;
    try {
      if (session.state == dart_cast.SessionState.idle ||
          session.state == dart_cast.SessionState.disconnected) {
        throw const PureCastException('No active media session to seek');
      }
      if (isLive) {
        // Live seek restarts the stream; ignore late events from the old one.
        _liveTimeline.armRestart(session.liveSessionToken);
      }
      await session.seek(position);
    } catch (e) {
      if (isLive) _liveTimeline.cancel();
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
  Stream<PureCastSessionState> get sessionStateStream =>
      _sessionStateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  PureCastSessionState get currentState => _currentState;

  @override
  Future<void> dispose() async {
    _bufferingDebounceTimer?.cancel();
    _liveTimeline.dispose();
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
    _lastDurationEmitted = null;

    // The state stream does not replay its current value, and the session has
    // already transitioned to `connected` before this subscription exists.
    // Publish it so a freshly opened session is not reported as disconnected.
    _updateState(_mapStateToDomain(session.state));

    _sessionStateSub = session.stateStream.listen((state) {
      // A previous session emits `disconnected` while CastService tears it down
      // for a new connect. Forwarding that event resets the BLoC mid-connect,
      // so drop anything that no longer belongs to the active session.
      if (!identical(_castService.activeSession, session)) return;

      final domainState = _mapStateToDomain(state);

      if (domainState == PureCastSessionState.disconnected) {
        // No restart can complete anymore; don't keep dropping positions.
        _liveTimeline.cancel();
      }

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
      if (session.isLive) {
        // The receiver's clock restarts at ~0 on every live restart, so the
        // real position is offset + receiver time.
        final mapped = _liveTimeline.mapPosition(
          receiverPosition: pos,
          offset: session.liveStartOffset,
          mediaSessionId: session.liveSessionToken,
        );
        if (mapped == null) return; // stale event from the replaced session
        _positionController.add(mapped);
        // The live stream reports no duration. Push the known source
        // duration as soon as playback produces a position event so the UI
        // has a seekable range.
        final known = session.liveDuration;
        if (known != null && known != _lastDurationEmitted) {
          _lastDurationEmitted = known;
          _durationController.add(known);
        }
        return;
      }
      _positionController.add(pos);
    });

    _durationSub = session.durationStream.listen((dur) {
      if (session.isLive) {
        final mapped = _liveTimeline.mapDuration(
          reportedDuration: dur,
          knownLiveDuration: session.liveDuration,
        );
        _lastDurationEmitted = mapped;
        _durationController.add(mapped);
        return;
      }
      _lastDurationEmitted = dur;
      _durationController.add(dur);
    });
  }

  void _updateState(PureCastSessionState newState) {
    _currentState = newState;
    _sessionStateController.add(newState);
  }

  // ── Data Mappers ──

  /// Maps a package device to the application model.
  ///
  /// AirPlay capabilities come from the receiver's advertised feature bits:
  /// HLS support gates track switching, and bit 3 gates volume.
  static PureCastDevice mapDeviceToDomain(dart_cast.CastDevice d) {
    final protocol = mapProtocolToDomain(d.protocol);
    var supportsHls = false;
    var supportsVolume = false;
    if (protocol == PureCastProtocol.airplay) {
      final features = dart_cast.AirPlayFeatures.parse(
        d.metadata['features'] ?? d.metadata['ft'] ?? '',
      );
      supportsHls = features.supportsHLS;
      supportsVolume = features.supportsVideoVolumeControl;
    }
    return PureCastDevice(
      id: d.id,
      name: d.name,
      protocol: protocol,
      host: d.address.address,
      port: d.port,
      metadata: Map.unmodifiable(d.metadata),
      capabilities: PureCastCapabilities.forProtocol(
        protocol,
        supportsHls: supportsHls,
        supportsVolume: supportsVolume,
      ),
    );
  }

  /// Maps the application model back to the package device.
  static dart_cast.CastDevice mapDeviceToDartCast(PureCastDevice d) {
    return dart_cast.CastDevice(
      id: d.id,
      name: d.name,
      protocol: mapProtocolToDartCast(d.protocol),
      address: InternetAddress(d.host),
      port: d.port,
      metadata: d.metadata,
    );
  }

  /// Maps a package protocol to the application value.
  static PureCastProtocol mapProtocolToDomain(dart_cast.CastProtocol p) {
    switch (p) {
      case dart_cast.CastProtocol.chromecast:
        return PureCastProtocol.chromecast;
      case dart_cast.CastProtocol.dlna:
        return PureCastProtocol.dlna;
      case dart_cast.CastProtocol.airplay:
        return PureCastProtocol.airplay;
    }
  }

  /// Maps an application protocol to the package value.
  static dart_cast.CastProtocol mapProtocolToDartCast(PureCastProtocol p) {
    switch (p) {
      case PureCastProtocol.chromecast:
        return dart_cast.CastProtocol.chromecast;
      case PureCastProtocol.dlna:
        return dart_cast.CastProtocol.dlna;
      case PureCastProtocol.airplay:
        return dart_cast.CastProtocol.airplay;
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
        defaultSubtitle: m.defaultSubtitle != null
            ? _mapSubtitleToDartCast(m.defaultSubtitle!)
            : null,
      );
    } else {
      return dart_cast.CastMedia(
        url: m.uri,
        type: mediaType,
        title: m.title,
        imageUrl: m.thumbnailUrl,
        duration: m.duration,
        subtitles: subtitles,
        defaultSubtitle: m.defaultSubtitle != null
            ? _mapSubtitleToDartCast(m.defaultSubtitle!)
            : null,
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
    if (e is PureCastException &&
        e.originalError is dart_cast.ProbeFailedException) {
      return true;
    }
    return false;
  }
}
