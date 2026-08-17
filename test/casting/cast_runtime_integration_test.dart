import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_event.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_event.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/utils/state_status.dart';

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
  Future<void> loadMedia(PureCastMedia media) async {}

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
  Future<int> setLastCastedDevice({
    required String deviceId,
    required String deviceName,
    required String protocol,
  }) async {
    lastDeviceId = deviceId;
    lastDeviceName = deviceName;
    lastProtocol = protocol;
    return 1;
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
  late PlaybackHistoryRepository historyRepo;

  setUp(() {
    fakeCastService = FakeCastService();
    fakeDb = FakeAppDatabase();
    historyRepo = PlaybackHistoryRepository(fakeDb);
  });

  tearDown(() async {
    await fakeCastService.dispose();
  });

  group('QueueBloc & PlaybackHistoryRepository Integration Tests', () {
    test('QueueBloc restores queue from database on LoadQueueEvent', () async {
      fakeDb.queueData = [
        PlaybackQueueTableData(
          id: 'q_1',
          mediaUri: 'http://example.com/item1.mp4',
          mediaType: 'mp4',
          title: 'Persisted Video 1',
          isLocalFile: false,
          queueOrder: 0,
          createdAt: DateTime.now(),
        ),
      ];

      final queueBloc = QueueBloc(fakeDb);
      expect(queueBloc.state.status, equals(StateStatus.initial));

      queueBloc.add(const LoadQueueEvent());
      await pumpEventQueue();

      expect(queueBloc.state.status, equals(StateStatus.loaded));
      expect(queueBloc.state.items.length, equals(1));
      expect(queueBloc.state.items.first.title, equals('Persisted Video 1'));

      await queueBloc.close();
    });

    test('PlaybackHistoryRepository fetches most recent played item', () async {
      fakeDb.mostRecentHistory = PlaybackHistoryTableData(
        id: 'hist_1',
        title: 'Last Watched Movie',
        mediaUri: 'http://example.com/movie.mkv',
        mediaType: 'mkv',
        isLocalFile: false,
        lastPositionMs: 120000,
        totalDurationMs: 600000,
        lastPlayedAt: DateTime.now(),
        completed: false,
      );

      final item = await historyRepo.getMostRecentHistory();
      expect(item?.title, equals('Last Watched Movie'));
      expect(item?.lastPositionMs, equals(120000));
    });
  });

  group('CastDiscoveryBloc Runtime Integration Tests', () {
    test('StartDiscovery transitions to loading and emits loaded on devices stream update', () async {
      final bloc = CastDiscoveryBloc(fakeCastService, fakeDb);

      expect(bloc.state.discoveryStatus, equals(StateStatus.initial));

      bloc.add(const StartDiscoveryEvent());
      await pumpEventQueue();

      expect(bloc.state.discoveryStatus, equals(StateStatus.loading));

      const testDevice = PureCastDevice(
        id: 'dev_1',
        name: 'Living Room Chromecast',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.10',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      fakeCastService.discoveryController.add([testDevice]);
      await pumpEventQueue();

      expect(bloc.state.discoveryStatus, equals(StateStatus.loaded));
      expect(bloc.state.devices, equals([testDevice]));

      await bloc.close();
    });

    test('Successful connection persists last device', () async {
      final bloc = CastDiscoveryBloc(fakeCastService, fakeDb);
      const testDevice = PureCastDevice(
        id: 'dev_1',
        name: 'Living Room Chromecast',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.10',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      bloc.add(const ConnectToDeviceEvent(testDevice));
      await pumpEventQueue();

      expect(bloc.state.connectionStatus, equals(StateStatus.loaded));
      expect(bloc.state.selectedDevice, equals(testDevice));
      expect(fakeCastService.connectCalled, isTrue);
      expect(fakeDb.lastDeviceId, equals('dev_1'));
      expect(fakeDb.lastDeviceName, equals('Living Room Chromecast'));
      expect(fakeDb.lastProtocol, equals('chromecast'));

      await bloc.close();
    });

    test('Failed connection sets error state and does not persist device', () async {
      final bloc = CastDiscoveryBloc(fakeCastService, fakeDb);
      fakeCastService.shouldConnectFail = true;

      const testDevice = PureCastDevice(
        id: 'dev_1',
        name: 'Living Room Chromecast',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.10',
        port: 8009,
        capabilities: PureCastCapabilities(),
      );

      bloc.add(const ConnectToDeviceEvent(testDevice));
      await pumpEventQueue();

      expect(bloc.state.connectionStatus, equals(StateStatus.error));
      expect(bloc.state.connectionError, contains('Network connection failed'));
      expect(fakeDb.lastDeviceId, isNull);

      await bloc.close();
    });
  });

  group('CastSessionBloc Runtime Integration Tests', () {
    test('Subscribes to session streams and updates state', () async {
      final bloc = CastSessionBloc(fakeCastService, historyRepo);

      fakeCastService.sessionStateController.add(PureCastSessionState.playing);
      await pumpEventQueue();

      expect(bloc.state.sessionState, equals(PureCastSessionState.playing));

      fakeCastService.positionController.add(const Duration(seconds: 45));
      await pumpEventQueue();

      expect(bloc.state.position, equals(const Duration(seconds: 45)));

      await bloc.close();
    });

    test('Disposal cancels stream subscriptions', () async {
      final bloc = CastSessionBloc(fakeCastService, historyRepo);
      await bloc.close();

      fakeCastService.sessionStateController.add(PureCastSessionState.paused);
      await pumpEventQueue();

      expect(bloc.state.sessionState, equals(PureCastSessionState.disconnected));
    });
  });
}
