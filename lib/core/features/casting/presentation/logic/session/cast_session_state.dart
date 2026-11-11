part of 'cast_session_bloc.dart';

@freezed
abstract class CastSessionState with _$CastSessionState {
  const CastSessionState._();
  const factory CastSessionState({
    @Default(PureCastSessionState.disconnected)
    PureCastSessionState sessionState,
    PureCastDevice? activeDevice,
    PureCastMedia? activeMedia,
    @Default(null) PureCastSubtitleTrack? activeSubtitle,
    @Default(StateStatus.initial) StateStatus connectionStatus,
    String? connectionError,
    @Default(StateStatus.initial) StateStatus playbackStatus,
    String? playbackError,
    @Default(Duration.zero) Duration position,
    @Default(false) bool preparing,
    String? castPlan,
    String? castPlanReason,
    String? prepareError,
    @Default(Duration.zero) Duration duration,
    @Default(1.0) double volume,
  }) = _CastSessionState;
  bool get isCasting =>
      activeDevice != null &&
      activeMedia != null &&
      sessionState != PureCastSessionState.disconnected &&
      sessionState != PureCastSessionState.completed;
}
