part of 'cast_session_bloc.dart';

@freezed
abstract class CastSessionEvent with _$CastSessionEvent {
  const factory CastSessionEvent.connectDevice(PureCastDevice device) =
      ConnectDeviceEvent;
  const factory CastSessionEvent.disconnectDevice() = DisconnectDeviceEvent;
  const factory CastSessionEvent.loadMedia(PureCastMedia media) =
      LoadMediaEvent;
  const factory CastSessionEvent.playMedia() = PlayMediaEvent;
  const factory CastSessionEvent.pauseMedia() = PauseMediaEvent;
  const factory CastSessionEvent.stopMedia() = StopMediaEvent;
  const factory CastSessionEvent.seekMedia(Duration position) = SeekMediaEvent;
  const factory CastSessionEvent.setVolume(double volume) = SetVolumeEvent;
  const factory CastSessionEvent.sessionStateChanged(
    PureCastSessionState newState,
  ) = SessionStateChangedEvent;
  const factory CastSessionEvent.positionUpdated(Duration position) =
      PositionUpdatedEvent;
  const factory CastSessionEvent.durationUpdated(Duration duration) =
      DurationUpdatedEvent;
}
