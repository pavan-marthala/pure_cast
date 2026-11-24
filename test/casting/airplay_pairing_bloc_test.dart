import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/utils/state_status.dart';

import 'support/fake_cast_session_bloc.dart';

const PureCastDevice _device = PureCastDevice(
  id: 'airplay-1',
  name: 'Living room TV',
  protocol: PureCastProtocol.airplay,
  host: '192.168.1.20',
  port: 7000,
  capabilities: PureCastCapabilities(),
);

class _PairingCastService implements ICastService {
  _PairingCastService({this.pinWorks = true});

  final StreamController<PureCastSessionState> _states =
      StreamController<PureCastSessionState>.broadcast();
  final List<String> calls = <String>[];
  bool requiresPin = true;
  bool pinWorks;

  @override
  Stream<PureCastSessionState> get sessionStateStream => _states.stream;

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration> get durationStream => const Stream.empty();

  @override
  Future<void> connect(PureCastDevice device) async {
    calls.add('connect');
    if (requiresPin) {
      throw PairingRequiredException(device.id, device.name);
    }
  }

  @override
  Future<void> connectWithPin(PureCastDevice device, String pin) async {
    calls.add('pin:$pin');
    if (!pinWorks) {
      throw const PureCastException('Wrong PIN');
    }
  }

  @override
  Future<void> disconnect() async {
    calls.add('disconnect');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CastSessionBloc _blocFor(_PairingCastService service) => CastSessionBloc(
  service,
  PlaybackHistoryRepository(NoopAppDatabase()),
  connectTimeout: const Duration(seconds: 2),
);

void main() {
  test(
    'a pairing requirement is exposed as state for the PIN prompt',
    () async {
      final service = _PairingCastService();
      final bloc = _blocFor(service);
      addTearDown(bloc.close);

      bloc.add(const CastSessionEvent.connectDevice(_device));
      await pumpEventQueue();

      expect(bloc.state.pairingRequired, isTrue);
      expect(bloc.state.activeDevice, _device);
      expect(bloc.state.connectionError, isNull);
      expect(bloc.state.connectionStatus, StateStatus.loading);
      expect(service.calls, ['connect']);
    },
  );

  test('a PIN completes the connection and clears the prompt', () async {
    final service = _PairingCastService();
    final bloc = _blocFor(service);
    addTearDown(bloc.close);

    bloc.add(const CastSessionEvent.connectDevice(_device));
    await pumpEventQueue();
    bloc.add(const CastSessionEvent.connectWithPin('4821'));
    await pumpEventQueue();

    expect(service.calls, ['connect', 'pin:4821']);
    expect(bloc.state.pairingRequired, isFalse);
    expect(bloc.state.connectionStatus, StateStatus.loaded);
    expect(bloc.state.activeDevice, _device);
  });

  test(
    'a wrong PIN reports an error instead of pretending to connect',
    () async {
      final service = _PairingCastService(pinWorks: false);
      final bloc = _blocFor(service);
      addTearDown(bloc.close);

      bloc.add(const CastSessionEvent.connectDevice(_device));
      await pumpEventQueue();
      bloc.add(const CastSessionEvent.connectWithPin('0000'));
      await pumpEventQueue();

      expect(bloc.state.pairingRequired, isFalse);
      expect(bloc.state.connectionStatus, StateStatus.error);
      expect(bloc.state.connectionError, contains('Wrong PIN'));
    },
  );

  test('cancelling the prompt discards the pending pairing', () async {
    final service = _PairingCastService();
    final bloc = _blocFor(service);
    addTearDown(bloc.close);

    bloc.add(const CastSessionEvent.connectDevice(_device));
    await pumpEventQueue();
    bloc.add(const CastSessionEvent.cancelPairing());
    await pumpEventQueue();

    expect(service.calls, ['connect', 'disconnect']);
    expect(bloc.state.pairingRequired, isFalse);
    expect(bloc.state.activeDevice, isNull);
  });
}
