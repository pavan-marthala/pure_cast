part of 'cast_discovery_bloc.dart';

@freezed
abstract class CastDiscoveryEvent with _$CastDiscoveryEvent {
  const factory CastDiscoveryEvent.startDiscovery({Set<PureCastProtocol>? protocols}) = StartDiscoveryEvent;
  const factory CastDiscoveryEvent.stopDiscovery() = StopDiscoveryEvent;
  const factory CastDiscoveryEvent.refreshDiscovery() = RefreshDiscoveryEvent;
  const factory CastDiscoveryEvent.devicesUpdated(List<PureCastDevice> devices) = DevicesUpdatedEvent;
  const factory CastDiscoveryEvent.discoveryError(String message) = DiscoveryErrorEvent;
  const factory CastDiscoveryEvent.autoReconnectMatchFound(PureCastDevice device) = AutoReconnectMatchFoundEvent;
}
