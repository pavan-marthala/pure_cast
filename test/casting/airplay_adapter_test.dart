import 'dart:io';
import 'dart:typed_data';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/airplay_credential_store.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSession extends dart_cast.CastSession {
  _RecordingSession(super.device);

  String? localPath;
  int? audioStreamIndex;
  dart_cast.CastSubtitle? subtitle;
  dart_cast.CastMedia? media;
  List<dart_cast.AudioStream> tracks = const [];
  int activeTrack = 0;

  @override
  List<dart_cast.AudioStream> get audioTracks => tracks;

  @override
  int get activeAudioIndex => activeTrack;

  @override
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    dart_cast.CastDeviceCaps caps = const dart_cast.CastDeviceCaps(),
    dart_cast.CastSubtitle? subtitle,
    String streamType = 'BUFFERED',
  }) async {
    localPath = path;
    this.audioStreamIndex = audioStreamIndex;
    this.subtitle = subtitle;
  }

  @override
  Future<void> loadMedia(
    dart_cast.CastMedia media, {
    bool bypassTransform = false,
  }) async {
    this.media = media;
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSubtitle(dart_cast.CastSubtitle? subtitle) async {}
  @override
  Future<void> disconnect() async {
    stateMachine.forceState(dart_cast.SessionState.disconnected);
  }
}

dart_cast.CastDevice _packageDevice({
  String id = 'airplay-1',
  dart_cast.CastProtocol protocol = dart_cast.CastProtocol.airplay,
  Map<String, String> metadata = const {'features': '0x19'},
}) => dart_cast.CastDevice(
  id: id,
  name: 'Living room',
  protocol: protocol,
  address: InternetAddress('192.168.1.20'),
  port: 7000,
  metadata: metadata,
);

const PureCastDevice _appDevice = PureCastDevice(
  id: 'airplay-1',
  name: 'Living room',
  protocol: PureCastProtocol.airplay,
  host: '192.168.1.20',
  port: 7000,
  capabilities: PureCastCapabilities(),
);

dart_cast.HapCredentials _fakeCredentials() => dart_cast.HapCredentials(
  clientPrivateKey: Uint8List(64),
  clientPublicKey: Uint8List(32),
  clientId: 'client',
  devicePublicKey: Uint8List(32),
  deviceId: 'device',
);

/// AirPlay session whose first connect asks for a PIN.
class _PairingSession extends dart_cast.AirPlaySession {
  _PairingSession(super.device);

  bool paired = false;
  int connectCalls = 0;
  String? usedPin;

  @override
  Future<void> connect() async {
    connectCalls++;
    stateMachine.forceState(dart_cast.SessionState.connecting);
    if (!paired) {
      stateMachine.forceState(dart_cast.SessionState.disconnected);
      throw dart_cast.NeedsPairingException('Receiver requires a PIN');
    }
    stateMachine.forceState(dart_cast.SessionState.connected);
  }

  @override
  Future<dart_cast.HapCredentials> pairSetup(
    String pin, {
    String? clientId,
    bool triggerPinDisplay = true,
  }) async {
    usedPin = pin;
    paired = true;
    return credentials = _fakeCredentials();
  }

  @override
  Future<void> disconnect() async {
    stateMachine.forceState(dart_cast.SessionState.disconnected);
  }
}

void main() {
  group('protocol mapping', () {
    test('AirPlay maps in both directions', () {
      expect(
        DartCastAdapter.mapProtocolToDomain(dart_cast.CastProtocol.airplay),
        PureCastProtocol.airplay,
      );
      expect(
        DartCastAdapter.mapProtocolToDartCast(PureCastProtocol.airplay),
        dart_cast.CastProtocol.airplay,
      );
    });

    test('AirPlay is in the default protocol and provider sets', () {
      expect(
        DartCastAdapter.defaultProtocols,
        contains(PureCastProtocol.airplay),
      );
      final providers = DartCastAdapter.defaultDiscoveryProviders();
      expect(
        providers.map((p) => p.protocol),
        containsAll([
          dart_cast.CastProtocol.chromecast,
          dart_cast.CastProtocol.dlna,
          dart_cast.CastProtocol.airplay,
        ]),
      );
    });

    test('the default session factory creates an AirPlay session', () {
      final session = DartCastAdapter.defaultSessionFactory(_packageDevice());
      expect(session, isA<dart_cast.AirPlaySession>());
      expect(session.device.protocol, dart_cast.CastProtocol.airplay);
    });
  });

  group('device mapping', () {
    test('an AirPlay device keeps its protocol, features and capabilities', () {
      final device = DartCastAdapter.mapDeviceToDomain(_packageDevice());

      expect(device.protocol, PureCastProtocol.airplay);
      expect(device.metadata['features'], '0x19');
      expect(device.capabilities.canPlay, isTrue);
      expect(device.capabilities.canPause, isTrue);
      expect(device.capabilities.canSeek, isTrue);
      expect(device.capabilities.canChangeAudioTrack, isTrue);
      expect(device.capabilities.canChangeSubtitle, isTrue);
      expect(device.capabilities.canSetVolume, isTrue);
      expect(device.capabilities.canQueue, isFalse);
    });

    test('a receiver without HLS or volume bits disables those controls', () {
      final device = DartCastAdapter.mapDeviceToDomain(
        _packageDevice(metadata: const {'features': '0x1'}),
      );

      expect(device.capabilities.canChangeAudioTrack, isFalse);
      expect(device.capabilities.canChangeSubtitle, isFalse);
      expect(device.capabilities.canSetVolume, isFalse);
    });

    test('a round trip preserves the feature metadata for reconnecting', () {
      final original = _packageDevice(metadata: const {'features': '0x11'});
      final domain = DartCastAdapter.mapDeviceToDomain(original);
      final roundTripped = DartCastAdapter.mapDeviceToDartCast(domain);

      expect(roundTripped.metadata['features'], '0x11');
      expect(roundTripped.protocol, dart_cast.CastProtocol.airplay);
    });

    test('Chromecast and DLNA capabilities are unchanged', () {
      final chromecast = DartCastAdapter.mapDeviceToDomain(
        _packageDevice(id: 'c', protocol: dart_cast.CastProtocol.chromecast),
      );
      final dlna = DartCastAdapter.mapDeviceToDomain(
        _packageDevice(id: 'd', protocol: dart_cast.CastProtocol.dlna),
      );

      expect(chromecast.protocol, PureCastProtocol.chromecast);
      expect(chromecast.capabilities.canQueue, isTrue);
      expect(dlna.protocol, PureCastProtocol.dlna);
      expect(dlna.capabilities.canQueue, isFalse);
      expect(dlna.capabilities.canChangeAudioTrack, isTrue);
    });
  });

  group('local AirPlay media', () {
    late _RecordingSession session;
    late DartCastAdapter adapter;

    setUp(() async {
      final castService = dart_cast.CastService(
        sessionFactory: (device) {
          session = _RecordingSession(device);
          return session;
        },
      );
      adapter = DartCastAdapter(
        castService: castService,
        mediaProbe: (path) async => null,
        capsProvider: () async => const dart_cast.CastDeviceCaps(),
      );
      await adapter.connect(
        const PureCastDevice(
          id: 'airplay-1',
          name: 'Living room',
          protocol: PureCastProtocol.airplay,
          host: '127.0.0.1',
          port: 7000,
          capabilities: PureCastCapabilities(),
        ),
      );
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('a local path reaches loadLocalFile', () async {
      await adapter.loadLocalFile('/media/movie.mkv', audioStreamIndex: 1);

      expect(session.localPath, '/media/movie.mkv');
      expect(session.audioStreamIndex, 1);
    });

    test('a content URI reaches loadLocalFile unchanged', () async {
      await adapter.loadLocalFile(
        'content://com.android.providers.media/movie/42',
      );

      expect(
        session.localPath,
        'content://com.android.providers.media/movie/42',
      );
    });

    test('loadMedia routes a local file through loadLocalFile', () async {
      await adapter.loadMedia(
        const PureCastMedia(
          uri: '/media/movie.mp4',
          type: PureCastMediaType.mp4,
          title: 'Movie',
          isLocalFile: true,
        ),
      );

      expect(session.localPath, '/media/movie.mp4');
      expect(session.media, isNull, reason: 'local loads never use loadMedia');
    });

    test('an AirPlay local load exposes tracks and the active index', () async {
      session.tracks = const [
        dart_cast.AudioStream(index: 0, codec: 'aac', channels: 2),
        dart_cast.AudioStream(
          index: 1,
          codec: 'ac3',
          channels: 6,
          language: 'spa',
        ),
      ];
      session.activeTrack = 1;

      expect(adapter.audioTracks, hasLength(2));
      expect(adapter.audioTracks[1].language, 'spa');
      expect(adapter.audioTracks[1].codec, 'ac3');
      expect(adapter.activeAudioIndex, 1);
    });
  });

  group('AirPlay pairing', () {
    late _PairingSession session;
    late dart_cast.CastService castService;
    late DartCastAdapter adapter;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AirPlayCredentialStore.instance.resetForTesting();
      castService = dart_cast.CastService(
        sessionFactory: (device) => session = _PairingSession(device),
      );
      adapter = DartCastAdapter(
        castService: castService,
        mediaProbe: (path) async => null,
        capsProvider: () async => const dart_cast.CastDeviceCaps(),
      );
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test(
      'a receiver that needs a PIN raises PairingRequiredException',
      () async {
        await expectLater(
          adapter.connect(_appDevice),
          throwsA(isA<PairingRequiredException>()),
        );

        expect(castService.pendingPairingSession, same(session));
        expect(castService.activeSession, isNull);
        expect(
          AirPlayCredentialStore.instance.credentialsFor('airplay-1'),
          isNull,
        );
      },
    );

    test('connectWithPin pairs, persists credentials and completes', () async {
      await expectLater(
        adapter.connect(_appDevice),
        throwsA(isA<PairingRequiredException>()),
      );

      await adapter.connectWithPin(_appDevice, '4821');

      expect(session.usedPin, '4821');
      expect(session.paired, isTrue);
      expect(session.connectCalls, 2);
      expect(castService.activeSession, same(session));
      expect(castService.pendingPairingSession, isNull);
      expect(
        AirPlayCredentialStore.instance.credentialsFor('airplay-1'),
        isNotNull,
      );
    });

    test('saved credentials are handed to a later AirPlay session', () async {
      AirPlayCredentialStore.instance.save('airplay-1', _fakeCredentials());
      await AirPlayCredentialStore.instance.ensureLoaded();

      final reused = DartCastAdapter.defaultSessionFactory(_packageDevice());

      expect(reused, isA<dart_cast.AirPlaySession>());
      expect((reused as dart_cast.AirPlaySession).credentials, isNotNull);
    });

    test(
      'stale credentials are dropped when pair-verify is rejected',
      () async {
        AirPlayCredentialStore.instance.save('airplay-1', _fakeCredentials());

        await expectLater(
          adapter.connect(_appDevice),
          throwsA(isA<PairingRequiredException>()),
        );

        expect(
          AirPlayCredentialStore.instance.credentialsFor('airplay-1'),
          isNull,
        );
      },
    );

    test('connectWithPin without a pending session fails clearly', () async {
      await expectLater(
        adapter.connectWithPin(_appDevice, '1234'),
        throwsA(isA<PureCastException>()),
      );
    });
  });
}
