import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'cast_discovery_event.dart';
import 'cast_discovery_state.dart';

@injectable
class CastDiscoveryBloc extends Bloc<CastDiscoveryEvent, CastDiscoveryState> {
  final ICastService _castService;
  StreamSubscription<List<PureCastDevice>>? _discoverySubscription;

  CastDiscoveryBloc(this._castService) : super(const CastDiscoveryInitial()) {
    on<StartDiscoveryEvent>(_onStartDiscovery);
    on<StopDiscoveryEvent>(_onStopDiscovery);
    on<DevicesUpdatedEvent>(_onDevicesUpdated);
    on<DiscoveryErrorEvent>(_onDiscoveryError);
  }

  Future<void> _onStartDiscovery(
    StartDiscoveryEvent event,
    Emitter<CastDiscoveryState> emit,
  ) async {
    emit(const CastDiscoveryLoading());
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
    emit(const CastDiscoveryStopped());
  }

  void _onDevicesUpdated(
    DevicesUpdatedEvent event,
    Emitter<CastDiscoveryState> emit,
  ) {
    emit(CastDiscoveryLoaded(event.devices));
  }

  void _onDiscoveryError(
    DiscoveryErrorEvent event,
    Emitter<CastDiscoveryState> emit,
  ) {
    emit(CastDiscoveryError(event.message));
  }

  @override
  Future<void> close() {
    _discoverySubscription?.cancel();
    return super.close();
  }
}
