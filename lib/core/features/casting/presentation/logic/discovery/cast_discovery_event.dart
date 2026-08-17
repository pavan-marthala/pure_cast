import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

abstract class CastDiscoveryEvent {
  const CastDiscoveryEvent();
}

class StartDiscoveryEvent extends CastDiscoveryEvent {
  final Set<PureCastProtocol>? protocols;

  const StartDiscoveryEvent({this.protocols});
}

class StopDiscoveryEvent extends CastDiscoveryEvent {
  const StopDiscoveryEvent();
}

class RefreshDiscoveryEvent extends CastDiscoveryEvent {
  const RefreshDiscoveryEvent();
}

class DevicesUpdatedEvent extends CastDiscoveryEvent {
  final List<PureCastDevice> devices;

  const DevicesUpdatedEvent(this.devices);
}

class DiscoveryErrorEvent extends CastDiscoveryEvent {
  final String message;

  const DiscoveryErrorEvent(this.message);
}

class SelectDeviceEvent extends CastDiscoveryEvent {
  final PureCastDevice device;

  const SelectDeviceEvent(this.device);
}

class ConnectToDeviceEvent extends CastDiscoveryEvent {
  final PureCastDevice device;

  const ConnectToDeviceEvent(this.device);
}

class DisconnectDeviceEvent extends CastDiscoveryEvent {
  const DisconnectDeviceEvent();
}
