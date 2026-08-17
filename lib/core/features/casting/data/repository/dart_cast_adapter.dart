import 'dart:async';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

@LazySingleton(as: ICastService)
/// Concrete adapter wrapping dart_cast package services.
class DartCastAdapter implements ICastService {
  final dart_cast.CastService _castService;

  StreamSubscription<dart_cast.SessionState>? _sessionStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

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
    final session = _castService.activeSession;
    if (session == null) {
      throw const PureCastException('No active cast session');
    }

    try {
      final dartMedia = _mapMediaToDartCast(media);
      await session.loadMedia(dartMedia);
    } catch (e) {
      throw PureCastException('Failed to load media: ${media.title}', e);
    }
  }

  @override
  Future<void> play() async {
    final session = _castService.activeSession;
    if (session == null) throw const PureCastException('No active session');
    try {
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
    _sessionStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _sessionStateController.close();
    _positionController.close();
    _durationController.close();
    await _castService.dispose();
  }

  // ── Subscriptions & Helpers ──
  void _subscribeToSession(dart_cast.CastSession session) {
    _sessionStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();

    _sessionStateSub = session.stateStream.listen((state) {
      final domainState = _mapStateToDomain(state);
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
    final subtitles = m.subtitles
        .map(
          (s) => dart_cast.CastSubtitle(
            url: s.url,
            label: s.label,
            language: s.language,
            format: 'vtt',
          ),
        )
        .toList();

    if (m.isLocalFile) {
      return dart_cast.CastMedia.file(
        filePath: m.uri,
        type: mediaType,
        title: m.title,
        imageUrl: m.thumbnailUrl,
        duration: m.duration,
        subtitles: subtitles,
      );
    } else {
      return dart_cast.CastMedia(
        url: m.uri,
        type: mediaType,
        title: m.title,
        imageUrl: m.thumbnailUrl,
        duration: m.duration,
        subtitles: subtitles,
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
}
