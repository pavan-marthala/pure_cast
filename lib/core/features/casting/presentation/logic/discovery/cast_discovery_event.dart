import 'package:equatable/equatable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

abstract class CastDiscoveryEvent extends Equatable {
  const CastDiscoveryEvent();

  @override
  List<Object?> get props => [];
}

class StartDiscoveryEvent extends CastDiscoveryEvent {
  final Set<PureCastProtocol>? protocols;

  const StartDiscoveryEvent({this.protocols});

  @override
  List<Object?> get props => [protocols];
}

class StopDiscoveryEvent extends CastDiscoveryEvent {
  const StopDiscoveryEvent();
}

class DevicesUpdatedEvent extends CastDiscoveryEvent {
  final List<PureCastDevice> devices;

  const DevicesUpdatedEvent(this.devices);

  @override
  List<Object?> get props => [devices];
}

class DiscoveryErrorEvent extends CastDiscoveryEvent {
  final String message;

  const DiscoveryErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}
