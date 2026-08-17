import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_event.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeCastService fakeCastService;
  late FakeAppDatabase fakeDb;

  setUp(() {
    fakeCastService = FakeCastService();
    fakeDb = FakeAppDatabase();
  });

  tearDown(() async {
    await fakeCastService.dispose();
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
      final bloc = CastSessionBloc(fakeCastService);

      fakeCastService.sessionStateController.add(PureCastSessionState.playing);
      await pumpEventQueue();

      expect(bloc.state.sessionState, equals(PureCastSessionState.playing));

      fakeCastService.positionController.add(const Duration(seconds: 45));
      await pumpEventQueue();

      expect(bloc.state.position, equals(const Duration(seconds: 45)));

      await bloc.close();
    });

    test('Disposal cancels stream subscriptions', () async {
      final bloc = CastSessionBloc(fakeCastService);
      await bloc.close();

      fakeCastService.sessionStateController.add(PureCastSessionState.paused);
      await pumpEventQueue();

      expect(bloc.state.sessionState, equals(PureCastSessionState.disconnected));
    });
  });
}
