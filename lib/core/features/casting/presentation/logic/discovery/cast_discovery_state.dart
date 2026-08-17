import 'package:equatable/equatable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

abstract class CastDiscoveryState extends Equatable {
  const CastDiscoveryState();

  @override
  List<Object?> get props => [];
}

class CastDiscoveryInitial extends CastDiscoveryState {
  const CastDiscoveryInitial();
}

class CastDiscoveryLoading extends CastDiscoveryState {
  const CastDiscoveryLoading();
}

class CastDiscoveryLoaded extends CastDiscoveryState {
  final List<PureCastDevice> devices;

  const CastDiscoveryLoaded(this.devices);

  @override
  List<Object?> get props => [devices];
}

class CastDiscoveryStopped extends CastDiscoveryState {
  const CastDiscoveryStopped();
}

class CastDiscoveryError extends CastDiscoveryState {
  final String message;

  const CastDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
