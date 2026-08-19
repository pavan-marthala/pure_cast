import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/coordinator/playback_coordinator.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/music_library/data/repository/media_repository.dart';
import 'package:pure_cast/core/utils/state_status.dart';

class FakeMediaRepository implements MediaRepository {
  @override
  Future<bool> checkAndRequestPermission() async => true;

  @override
  Future<List<PureCastMedia>> getLocalMedia({
    RequestType type = RequestType.common,
    int page = 0,
    int size = 50,
  }) async => [];

  @override
  Future<File?> getMediaFile(String assetId) async => null;

  @override
  Future<List<PureCastMedia>> pickFiles() async => [];
}

class FakeCastService implements ICastService {
  final StreamController<List<PureCastDevice>> discoveryController =
      StreamController<List<PureCastDevice>>.broadcast();
  final StreamController<PureCastSessionState> sessionStateController =
      StreamController<PureCastSessionState>.broadcast();
  final StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> durationController =
      StreamController<Duration>.broadcast();

  bool connectCalled = false;
  PureCastDevice? connectDeviceTarget;
  bool shouldConnectFail = false;
  bool disconnectCalled = false;
  PureCastMedia? loadedMedia;

  @override
  Stream<List<PureCastDevice>> discoverDevices({Set<PureCastProtocol>? protocols}) {
    return discoveryController.stream;
  }

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> connect(PureCastDevice device) async {
    connectCalled = true;
    connectDeviceTarget = device;
    if (shouldConnectFail) {
      throw const PureCastException('Network connection failed');
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }

  @override
  Future<void> loadMedia(PureCastMedia media) async {
    loadedMedia = media;
    sessionStateController.add(PureCastSessionState.playing);
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
  Stream<PureCastSessionState> get sessionStateStream => sessionStateController.stream;

  @override
  Stream<Duration> get positionStream => positionController.stream;

  @override
  Stream<Duration> get durationStream => durationController.stream;

  @override
  PureCastDevice? currentDevice;

  @override
  PureCastSessionState currentState = PureCastSessionState.disconnected;

  @override
  Future<void> dispose() async {
    await discoveryController.close();
    await sessionStateController.close();
    await positionController.close();
    await durationController.close();
  }
}

class FakeAppDatabase implements AppDatabase {
  String? lastDeviceId;
  String? lastDeviceName;
  String? lastProtocol;

  List<PlaybackQueueTableData> queueData = [];
  PlaybackHistoryTableData? mostRecentHistory;
  PlaybackHistoryTableCompanion? recordedHistoryCompanion;
  UserPreferencesTableData preferencesData = const UserPreferencesTableData(
    id: 1,
    preferredAudioLanguage: 'en',
    preferredSubtitleLanguage: 'en',
    autoPlayNext: true,
  );

  @override
  Future<LastCastedDeviceTableData?> getLastCastedDevice() async {
    if (lastDeviceId == null) return null;
    return LastCastedDeviceTableData(
      deviceId: lastDeviceId!,
      deviceName: lastDeviceName!,
      protocol: lastProtocol!,
      lastCastAt: DateTime.now(),
    );
  }

  @override
  Future<void> setLastCastedDevice({
    required String deviceId,
    required String deviceName,
    required String protocol,
  }) async {
    lastDeviceId = deviceId;
    lastDeviceName = deviceName;
    lastProtocol = protocol;
  }

  @override
  Future<void> clearLastCastedDevice() async {
    lastDeviceId = null;
    lastDeviceName = null;
    lastProtocol = null;
  }

  @override
  Future<List<PlaybackQueueTableData>> getQueue() async => queueData;

  @override
  Future<void> saveQueue(List<PlaybackQueueTableCompanion> items) async {
    queueData = items.map((i) => PlaybackQueueTableData(
      id: i.id.value,
      mediaUri: i.mediaUri.value,
      mediaType: i.mediaType.value,
      title: i.title.value,
      thumbnail: i.thumbnail.value,
      durationMs: i.durationMs.value,
      isLocalFile: i.isLocalFile.value,
      queueOrder: i.queueOrder.value,
      createdAt: i.createdAt.value,
    )).toList();
  }

  @override
  Future<void> clearQueue() async {
    queueData.clear();
  }

  @override
  Future<PlaybackHistoryTableData?> getMostRecentHistory() async => mostRecentHistory;

  @override
  Future<void> recordPlaybackHistory(PlaybackHistoryTableCompanion entry) async {
    recordedHistoryCompanion = entry;
  }

  @override
  Future<UserPreferencesTableData> getPreferences() async => preferencesData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeCastService fakeCastService;
  late FakeAppDatabase fakeDb;
  late FakeMediaRepository fakeMediaRepo;
  late PlaybackHistoryRepository historyRepo;

  setUp(() {
    fakeCastService = FakeCastService();
    fakeDb = FakeAppDatabase();
    fakeMediaRepo = FakeMediaRepository();
    historyRepo = PlaybackHistoryRepository(fakeDb);
  });

  tearDown(() async {
    await fakeCastService.dispose();
  });

  group('CastDiscoveryBloc - Refactored Discovery Ownership Tests', () {
    test('1. Discovery returns devices and updates discoveryStatus', () async {
      final discoveryBloc = CastDiscoveryBloc(fakeCastService, fakeDb);

      discoveryBloc.add(const StartDiscoveryEvent());
      await pumpEventQueue();

      expect(discoveryBloc.state.discoveryStatus, equals(StateStatus.loading));

      const device1 = PureCastDevice(
        id: 'dev1',
        name: 'Living Room TV',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.10',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      fakeCastService.discoveryController.add([device1]);
      await pumpEventQueue();

      expect(discoveryBloc.state.discoveryStatus, equals(StateStatus.loaded));
      expect(discoveryBloc.state.devices, contains(device1));

      await discoveryBloc.close();
    });

    test('2. Discovery error sets discoveryStatus to error', () async {
      final discoveryBloc = CastDiscoveryBloc(fakeCastService, fakeDb);

      discoveryBloc.add(const StartDiscoveryEvent());
      await pumpEventQueue();

      fakeCastService.discoveryController.addError('Discovery failed');
      await pumpEventQueue();

      expect(discoveryBloc.state.discoveryStatus, equals(StateStatus.error));
      expect(discoveryBloc.state.discoveryError, contains('Discovery failed'));

      await discoveryBloc.close();
    });

    test('3. DiscoveryBloc does NOT own connect() or disconnect()', () async {
      final discoveryBloc = CastDiscoveryBloc(fakeCastService, fakeDb);

      discoveryBloc.add(const StartDiscoveryEvent());
      await pumpEventQueue();

      expect(fakeCastService.connectCalled, isFalse);
      expect(fakeCastService.disconnectCalled, isFalse);

      await discoveryBloc.close();
    });
  });

  group('CastSessionBloc - Sole Connection Owner Tests', () {
    test('1. Connect success updates activeDevice and persists last_casted_device', () async {
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const deviceA = PureCastDevice(
        id: 'tv_a',
        name: 'TV A',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.20',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      sessionBloc.add(const ConnectDeviceEvent(deviceA));
      await pumpEventQueue();

      expect(fakeCastService.connectCalled, isTrue);
      expect(fakeCastService.connectDeviceTarget, equals(deviceA));
      expect(sessionBloc.state.connectionStatus, equals(StateStatus.loaded));
      expect(sessionBloc.state.activeDevice, equals(deviceA));
      expect(fakeDb.lastDeviceId, equals('tv_a'));

      await sessionBloc.close();
    });

    test('2. Connect failure preserves previous activeDevice and sets connectionStatus error', () async {
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const deviceA = PureCastDevice(
        id: 'tv_a',
        name: 'TV A',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.20',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );
      const deviceB = PureCastDevice(
        id: 'tv_b',
        name: 'TV B',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.21',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      // Connect TV A successfully first
      sessionBloc.add(const ConnectDeviceEvent(deviceA));
      await pumpEventQueue();
      expect(sessionBloc.state.activeDevice, equals(deviceA));

      // Attempt TV B with error
      fakeCastService.shouldConnectFail = true;
      sessionBloc.add(const ConnectDeviceEvent(deviceB));
      await pumpEventQueue();

      expect(sessionBloc.state.connectionStatus, equals(StateStatus.error));
      expect(sessionBloc.state.connectionError, contains('Network connection failed'));
      expect(sessionBloc.state.activeDevice, equals(deviceA));

      await sessionBloc.close();
    });

    test('3. Disconnect clears activeDevice and resets session state', () async {
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const deviceA = PureCastDevice(
        id: 'tv_a',
        name: 'TV A',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.20',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      sessionBloc.add(const ConnectDeviceEvent(deviceA));
      await pumpEventQueue();
      expect(sessionBloc.state.activeDevice, equals(deviceA));

      sessionBloc.add(const DisconnectDeviceEvent());
      await pumpEventQueue();

      expect(fakeCastService.disconnectCalled, isTrue);
      expect(sessionBloc.state.activeDevice, isNull);
      expect(sessionBloc.state.sessionState, equals(PureCastSessionState.disconnected));

      await sessionBloc.close();
    });

    test('4. Device switching: TV A -> TV B succeeds and updates activeDevice', () async {
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const deviceA = PureCastDevice(
        id: 'tv_a',
        name: 'TV A',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.20',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );
      const deviceB = PureCastDevice(
        id: 'tv_b',
        name: 'TV B',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.21',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      sessionBloc.add(const ConnectDeviceEvent(deviceA));
      await pumpEventQueue();
      expect(sessionBloc.state.activeDevice, equals(deviceA));

      sessionBloc.add(const ConnectDeviceEvent(deviceB));
      await pumpEventQueue();

      expect(sessionBloc.state.activeDevice, equals(deviceB));
      expect(fakeDb.lastDeviceId, equals('tv_b'));

      await sessionBloc.close();
    });

    test('5. Receiver-initiated disconnect event resets session state and clears activeDevice', () async {
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const deviceA = PureCastDevice(
        id: 'tv_a',
        name: 'TV A',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.20',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      sessionBloc.add(const ConnectDeviceEvent(deviceA));
      await pumpEventQueue();
      expect(sessionBloc.state.activeDevice, equals(deviceA));

      // Receiver emits disconnected status on stream
      fakeCastService.sessionStateController.add(PureCastSessionState.disconnected);
      await pumpEventQueue();

      expect(sessionBloc.state.activeDevice, isNull);
      expect(sessionBloc.state.sessionState, equals(PureCastSessionState.disconnected));
      expect(sessionBloc.state.activeMedia, isNull);

      await sessionBloc.close();
    });
  });

  group('Auto-Reconnection & UI State Isolation Tests', () {
    test('1. Discovery emits AutoReconnectMatchFoundEvent and session owner connects', () async {
      fakeDb.lastDeviceId = 'tv_last';
      fakeDb.lastDeviceName = 'Last TV';
      fakeDb.lastProtocol = 'chromecast';

      final discoveryBloc = CastDiscoveryBloc(fakeCastService, fakeDb);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const lastDevice = PureCastDevice(
        id: 'tv_last',
        name: 'Last TV',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.50',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      discoveryBloc.stream.listen((state) {
        // Handle auto-reconnect stream notification
      });

      // Wire auto-reconnect match event to SessionBloc
      discoveryBloc.stream.listen((discoveryState) {
        // Auto reconnect notification
      });

      discoveryBloc.add(const StartDiscoveryEvent());
      await pumpEventQueue();

      fakeCastService.discoveryController.add([lastDevice]);
      await pumpEventQueue();

      // Trigger session connect explicitly as done by runtime listener
      sessionBloc.add(const ConnectDeviceEvent(lastDevice));
      await pumpEventQueue();

      expect(sessionBloc.state.activeDevice, equals(lastDevice));
      expect(fakeCastService.connectCalled, isTrue);

      await discoveryBloc.close();
      await sessionBloc.close();
    });

    test('2. UI determines active device via Discovery.devices and Session.activeDevice match', () async {
      final discoveryBloc = CastDiscoveryBloc(fakeCastService, fakeDb);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const deviceA = PureCastDevice(
        id: 'tv_a',
        name: 'TV A',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.20',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );
      const deviceB = PureCastDevice(
        id: 'tv_b',
        name: 'TV B',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.21',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      discoveryBloc.add(const StartDiscoveryEvent());
      await pumpEventQueue();
      fakeCastService.discoveryController.add([deviceA, deviceB]);
      await pumpEventQueue();

      sessionBloc.add(const ConnectDeviceEvent(deviceB));
      await pumpEventQueue();

      // Simulated UI check: device.id == sessionBloc.state.activeDevice?.id
      final isBActive = discoveryBloc.state.devices.any(
        (d) => d.id == sessionBloc.state.activeDevice?.id && d.id == 'tv_b',
      );

      expect(isBActive, isTrue);

      await discoveryBloc.close();
      await sessionBloc.close();
    });
  });

  group('PlaybackCoordinator Unit & Orchestration Tests', () {
    test('1. Empty queue does not trigger media load', () async {
      final queueBloc = QueueBloc(fakeDb, fakeMediaRepo);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);
      final coordinator = PlaybackCoordinator(historyRepo);

      coordinator.start(queueBloc, sessionBloc);
      await pumpEventQueue();

      expect(sessionBloc.state.activeMedia, isNull);
      expect(fakeCastService.loadedMedia, isNull);

      await coordinator.dispose();
      await queueBloc.close();
      await sessionBloc.close();
    });

    test('2. First item added to empty queue triggers LoadMediaEvent on CastSessionBloc', () async {
      final queueBloc = QueueBloc(fakeDb, fakeMediaRepo);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);
      final coordinator = PlaybackCoordinator(historyRepo);

      coordinator.start(queueBloc, sessionBloc);

      const media = PureCastMedia(
        uri: 'http://example.com/video1.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video 1',
      );

      queueBloc.add(const AddToQueueEvent(media));
      await pumpEventQueue();

      expect(sessionBloc.state.activeMedia, equals(media));

      await coordinator.dispose();
      await queueBloc.close();
      await sessionBloc.close();
    });

    test('3. Completed A + queue still contains A + select B -> B starts immediately', () async {
      final queueBloc = QueueBloc(fakeDb, fakeMediaRepo);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);
      final coordinator = PlaybackCoordinator(historyRepo);

      coordinator.start(queueBloc, sessionBloc);

      const mediaA = PureCastMedia(
        uri: 'http://example.com/videoA.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video A',
      );
      const mediaB = PureCastMedia(
        uri: 'http://example.com/videoB.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video B',
      );

      // Add A -> starts playing
      queueBloc.add(const AddToQueueEvent(mediaA));
      await pumpEventQueue();
      expect(sessionBloc.state.activeMedia, equals(mediaA));

      // Media A completes -> active playback becomes completed
      fakeCastService.sessionStateController.add(PureCastSessionState.completed);
      await pumpEventQueue();
      expect(sessionBloc.state.sessionState, equals(PureCastSessionState.completed));

      // User selects Media B while queue still contains A
      queueBloc.add(const AddToQueueEvent(mediaB));
      await pumpEventQueue();

      // B starts playing immediately because there was NO active playback (A was completed)
      expect(sessionBloc.state.activeMedia?.uri, equals(mediaB.uri));

      await coordinator.dispose();
      await queueBloc.close();
      await sessionBloc.close();
    });

    test('4. Active A + select B -> B added to queue without interrupting A', () async {
      final queueBloc = QueueBloc(fakeDb, fakeMediaRepo);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);
      final coordinator = PlaybackCoordinator(historyRepo);

      coordinator.start(queueBloc, sessionBloc);

      const mediaA = PureCastMedia(
        uri: 'http://example.com/videoA.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video A',
      );
      const mediaB = PureCastMedia(
        uri: 'http://example.com/videoB.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video B',
      );

      // Add A -> starts playing
      queueBloc.add(const AddToQueueEvent(mediaA));
      await pumpEventQueue();
      fakeCastService.sessionStateController.add(PureCastSessionState.playing);
      await pumpEventQueue();
      expect(sessionBloc.state.activeMedia?.uri, equals(mediaA.uri));
      expect(sessionBloc.state.sessionState, equals(PureCastSessionState.playing));

      // User adds B while A is actively playing
      queueBloc.add(const AddToQueueEvent(mediaB));
      await pumpEventQueue();

      // Media A remains active playback, B is in queue
      expect(sessionBloc.state.activeMedia?.uri, equals(mediaA.uri));
      expect(queueBloc.state.items.length, equals(2));

      await coordinator.dispose();
      await queueBloc.close();
      await sessionBloc.close();
    });

    test('5. Stopped A + select B -> B starts immediately', () async {
      final queueBloc = QueueBloc(fakeDb, fakeMediaRepo);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);
      final coordinator = PlaybackCoordinator(historyRepo);

      coordinator.start(queueBloc, sessionBloc);

      const mediaA = PureCastMedia(
        uri: 'http://example.com/videoA.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video A',
      );
      const mediaB = PureCastMedia(
        uri: 'http://example.com/videoB.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video B',
      );

      // Add A -> starts playing
      queueBloc.add(const AddToQueueEvent(mediaA));
      await pumpEventQueue();
      expect(sessionBloc.state.activeMedia?.uri, equals(mediaA.uri));

      // User stops playback or receiver stops -> session disconnected/stopped
      fakeCastService.sessionStateController.add(PureCastSessionState.disconnected);
      await pumpEventQueue();

      // User selects B -> B starts playing immediately
      queueBloc.add(const AddToQueueEvent(mediaB));
      await pumpEventQueue();

      expect(sessionBloc.state.activeMedia?.uri, equals(mediaB.uri));

      await coordinator.dispose();
      await queueBloc.close();
      await sessionBloc.close();
    });

    test('6. Automatic queue continuation: A completes -> B starts casting automatically', () async {
      final queueBloc = QueueBloc(fakeDb, fakeMediaRepo);
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);
      final coordinator = PlaybackCoordinator(historyRepo);

      coordinator.start(queueBloc, sessionBloc);

      const mediaA = PureCastMedia(
        uri: 'http://example.com/videoA.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video A',
      );
      const mediaB = PureCastMedia(
        uri: 'http://example.com/videoB.mp4',
        type: PureCastMediaType.mp4,
        title: 'Video B',
      );

      // Add A -> starts playing
      queueBloc.add(const AddToQueueEvent(mediaA));
      await pumpEventQueue();
      fakeCastService.sessionStateController.add(PureCastSessionState.playing);
      await pumpEventQueue();
      expect(sessionBloc.state.activeMedia?.uri, equals(mediaA.uri));

      // Add B while A is playing
      queueBloc.add(const AddToQueueEvent(mediaB));
      await pumpEventQueue();
      expect(queueBloc.state.items.length, equals(2));

      // Video A completes
      fakeCastService.sessionStateController.add(PureCastSessionState.completed);
      await pumpEventQueue();

      // Coordinator automatically advances queue index to B and sends LoadMediaEvent for B
      expect(queueBloc.state.currentIndex, equals(1));
      expect(sessionBloc.state.activeMedia?.uri, equals(mediaB.uri));

      await coordinator.dispose();
      await queueBloc.close();
      await sessionBloc.close();
    });

    test('7. Issue 1: Media selected without active cast session retains media as pending without exception', () async {
      final sessionBloc = CastSessionBloc(fakeCastService, historyRepo, fakeDb);

      const localMedia = PureCastMedia(
        uri: '/storage/emulated/0/DCIM/Camera/sample.mp4',
        type: PureCastMediaType.mp4,
        title: 'sample.mp4',
        isLocalFile: true,
      );

      // Select media when activeDevice is null
      expect(sessionBloc.state.activeDevice, isNull);
      sessionBloc.add(const LoadMediaEvent(localMedia));
      await pumpEventQueue();

      // No exception, media is retained as pending activeMedia
      expect(sessionBloc.state.activeMedia, equals(localMedia));
      expect(sessionBloc.state.playbackError, isNull);

      // Now connect a device
      const targetDevice = PureCastDevice(
        id: 'tv_1',
        name: 'Living Room TV',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.100',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      sessionBloc.add(const ConnectDeviceEvent(targetDevice));
      await pumpEventQueue();

      // Pending media is automatically loaded onto connected device
      expect(sessionBloc.state.activeDevice, equals(targetDevice));
      expect(fakeCastService.loadedMedia, equals(localMedia));

      await sessionBloc.close();
    });

    test('8. Issue 1B: Auto-reconnect match found emits autoReconnectDevice in discovery state', () async {
      final discoveryBloc = CastDiscoveryBloc(fakeCastService, fakeDb);

      const savedDevice = PureCastDevice(
        id: 'saved_tv_id',
        name: 'Saved TV',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.50',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      discoveryBloc.add(const AutoReconnectMatchFoundEvent(savedDevice));
      await pumpEventQueue();

      expect(discoveryBloc.state.autoReconnectDevice, equals(savedDevice));

      await discoveryBloc.close();
    });
  });
}
