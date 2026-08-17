import 'package:equatable/equatable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

abstract class CastSessionEvent extends Equatable {
  const CastSessionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectDeviceEvent extends CastSessionEvent {
  final PureCastDevice device;

  const ConnectDeviceEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class DisconnectDeviceEvent extends CastSessionEvent {
  const DisconnectDeviceEvent();
}

class LoadMediaEvent extends CastSessionEvent {
  final PureCastMedia media;

  const LoadMediaEvent(this.media);

  @override
  List<Object?> get props => [media];
}

class PlayMediaEvent extends CastSessionEvent {
  const PlayMediaEvent();
}

class PauseMediaEvent extends CastSessionEvent {
  const PauseMediaEvent();
}

class StopMediaEvent extends CastSessionEvent {
  const StopMediaEvent();
}

class SeekMediaEvent extends CastSessionEvent {
  final Duration position;

  const SeekMediaEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class SetVolumeEvent extends CastSessionEvent {
  final double volume;

  const SetVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SessionStateChangedEvent extends CastSessionEvent {
  final PureCastSessionState newState;

  const SessionStateChangedEvent(this.newState);

  @override
  List<Object?> get props => [newState];
}

class PositionUpdatedEvent extends CastSessionEvent {
  final Duration position;

  const PositionUpdatedEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class DurationUpdatedEvent extends CastSessionEvent {
  final Duration duration;

  const DurationUpdatedEvent(this.duration);

  @override
  List<Object?> get props => [duration];
}
