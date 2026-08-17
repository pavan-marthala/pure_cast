part of 'cast_discovery_bloc.dart';

@freezed
abstract class CastDiscoveryState with _$CastDiscoveryState {
  const factory CastDiscoveryState({
    @Default([]) List<PureCastDevice> devices,
    @Default(StateStatus.initial) StateStatus discoveryStatus,
    String? discoveryError,
    PureCastDevice? selectedDevice,
    @Default(StateStatus.initial) StateStatus connectionStatus,
    String? connectionError,
  }) = _CastDiscoveryState;
}
