part of 'cast_session_bloc.dart';

@freezed
abstract class CastSessionEvent with _$CastSessionEvent {
  const factory CastSessionEvent.connectDevice(PureCastDevice device) =
      ConnectDeviceEvent;

  /// Completes a connection that requires a receiver PIN.
  const factory CastSessionEvent.connectWithPin(String pin) =
      ConnectWithPinEvent;

  /// Cancels a PIN prompt and discards the half-connected session.
  const factory CastSessionEvent.cancelPairing() = CancelPairingEvent;
  const factory CastSessionEvent.disconnectDevice() = DisconnectDeviceEvent;
  const factory CastSessionEvent.loadMedia(PureCastMedia media) =
      LoadMediaEvent;
  const factory CastSessionEvent.playMedia() = PlayMediaEvent;
  const factory CastSessionEvent.pauseMedia() = PauseMediaEvent;
  const factory CastSessionEvent.stopMedia() = StopMediaEvent;
  const factory CastSessionEvent.seekMedia(Duration position) = SeekMediaEvent;
  const factory CastSessionEvent.seekRelative(Duration delta) =
      SeekRelativeEvent;

  /// Internal: commits the accumulated [CastSessionState.seekPreview].
  const factory CastSessionEvent.commitSeekPreview() = CommitSeekPreviewEvent;
  const factory CastSessionEvent.selectAudio(int index) = SelectAudioEvent;
  const factory CastSessionEvent.setVolume(double volume) = SetVolumeEvent;
  const factory CastSessionEvent.setSubtitle(PureCastSubtitleTrack? subtitle) =
      SetSubtitleEvent;
  const factory CastSessionEvent.extractAndSetSubtitle(
    PureCastSubtitleTrack subtitle,
  ) = ExtractAndSetSubtitleEvent;
  const factory CastSessionEvent.sessionStateChanged(
    PureCastSessionState newState,
  ) = SessionStateChangedEvent;
  const factory CastSessionEvent.positionUpdated(Duration position) =
      PositionUpdatedEvent;
  const factory CastSessionEvent.durationUpdated(Duration duration) =
      DurationUpdatedEvent;
}
