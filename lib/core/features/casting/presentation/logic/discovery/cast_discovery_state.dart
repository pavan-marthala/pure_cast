import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'cast_discovery_state.freezed.dart';

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
