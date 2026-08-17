import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'cast_discovery_event.dart';
part 'cast_discovery_state.dart';
part 'cast_discovery_bloc.freezed.dart';

@injectable
class CastDiscoveryBloc extends Bloc<CastDiscoveryEvent, CastDiscoveryState> {
  final ICastService _castService;
  final AppDatabase _db;
  StreamSubscription<List<PureCastDevice>>? _discoverySubscription;

  CastDiscoveryBloc(this._castService, this._db) : super(const CastDiscoveryState()) {
    on<StartDiscoveryEvent>(_onStartDiscovery);
    on<StopDiscoveryEvent>(_onStopDiscovery);
    on<RefreshDiscoveryEvent>(_onRefreshDiscovery);
    on<DevicesUpdatedEvent>(_onDevicesUpdated);
    on<DiscoveryErrorEvent>(_onDiscoveryError);
    on<SelectDeviceEvent>(_onSelectDevice);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
  }

  Future<void> _onStartDiscovery(
    StartDiscoveryEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    emit(state.copyWith(
      discoveryStatus: StateStatus.loading,
      discoveryError: null,
    ));
    await _discoverySubscription?.cancel();

    _discoverySubscription = _castService
        .discoverDevices(protocols: event.protocols)
        .listen(
          (devices) => add(DevicesUpdatedEvent(devices)),
          onError: (Object error) => add(DiscoveryErrorEvent(error.toString())),
        );
  }

  Future<void> _onStopDiscovery(
    StopDiscoveryEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    await _castService.stopDiscovery();
    emit(state.copyWith(
      discoveryStatus: state.devices.isEmpty ? StateStatus.empty : StateStatus.loaded,
    ));
  }

  Future<void> _onRefreshDiscovery(
    RefreshDiscoveryEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    add(const StartDiscoveryEvent());
  }

  void _onDevicesUpdated(
    DevicesUpdatedEvent event,
    Emitter<CastDiscoveryState> emit,
  ) {
    final status = event.devices.isEmpty ? StateStatus.empty : StateStatus.loaded;
    emit(state.copyWith(
      devices: event.devices,
      discoveryStatus: status,
    ));

    // Phase 4: Automatic Last-Device Reconnection
    _attemptAutoReconnection(event.devices);
  }

  Future<void> _attemptAutoReconnection(List<PureCastDevice> discoveredDevices) async {
    if (state.connectionStatus == StateStatus.loading ||
        state.connectionStatus == StateStatus.loaded) {
      return;
    }

    final lastDeviceRecord = await _db.getLastCastedDevice();
    if (lastDeviceRecord == null) return;

    final match = discoveredDevices.firstWhere(
      (d) => d.id == lastDeviceRecord.deviceId,
      orElse: () => const PureCastDevice(
        id: '',
        name: '',
        protocol: PureCastProtocol.chromecast,
        host: '',
        port: 0,
        capabilities: PureCastCapabilities(),
      ),
    );

    if (match.id.isNotEmpty) {
      add(ConnectToDeviceEvent(match));
    }
  }

  void _onDiscoveryError(
    DiscoveryErrorEvent event,
    Emitter<CastDiscoveryState> emit,
  ) {
    emit(state.copyWith(
      discoveryStatus: StateStatus.error,
      discoveryError: event.message,
    ));
  }

  void _onSelectDevice(
    SelectDeviceEvent event,
    Emitter<CastDiscoveryState> emit,
  ) {
    emit(state.copyWith(selectedDevice: event.device));
  }

  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    emit(state.copyWith(
      selectedDevice: event.device,
      connectionStatus: StateStatus.loading,
      connectionError: null,
    ));

    try {
      await _castService.connect(event.device);
      await _db.setLastCastedDevice(
        deviceId: event.device.id,
        deviceName: event.device.name,
        protocol: event.device.protocol.name,
      );

      emit(state.copyWith(
        connectionStatus: StateStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        connectionStatus: StateStatus.error,
        connectionError: e.toString(),
      ));
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDeviceEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    try {
      await _castService.disconnect();
      emit(state.copyWith(
        selectedDevice: null,
        connectionStatus: StateStatus.initial,
        connectionError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        connectionStatus: StateStatus.error,
        connectionError: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _discoverySubscription?.cancel();
    return super.close();
  }
}
