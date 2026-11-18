import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:dart_cast/dart_cast.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'cast_discovery_event.dart';
part 'cast_discovery_state.dart';
part 'cast_discovery_bloc.freezed.dart';

@injectable
class CastDiscoveryBloc extends Bloc<CastDiscoveryEvent, CastDiscoveryState> {
  final ICastService _castService;
  StreamSubscription<List<PureCastDevice>>? _discoverySubscription;

  CastDiscoveryBloc(this._castService) : super(const CastDiscoveryState()) {
    on<StartDiscoveryEvent>(_onStartDiscovery);
    on<StopDiscoveryEvent>(_onStopDiscovery);
    on<RefreshDiscoveryEvent>(_onRefreshDiscovery);
    on<DevicesUpdatedEvent>(_onDevicesUpdated);
    on<DiscoveryErrorEvent>(_onDiscoveryError);
  }

  Future<void> _onStartDiscovery(
    StartDiscoveryEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    emit(
      state.copyWith(
        discoveryStatus: StateStatus.loading,
        discoveryError: null,
      ),
    );
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
    emit(
      state.copyWith(
        discoveryStatus: state.devices.isEmpty
            ? StateStatus.empty
            : StateStatus.loaded,
      ),
    );
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
    final status = event.devices.isEmpty
        ? StateStatus.empty
        : StateStatus.loaded;
    emit(state.copyWith(devices: event.devices, discoveryStatus: status));
  }

  void _onDiscoveryError(
    DiscoveryErrorEvent event,
    Emitter<CastDiscoveryState> emit,
  ) {
    CastLogger.error('Discovery Error: ${event.message}');
    emit(
      state.copyWith(
        discoveryStatus: StateStatus.error,
        discoveryError: event.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _discoverySubscription?.cancel();
    return super.close();
  }
}
