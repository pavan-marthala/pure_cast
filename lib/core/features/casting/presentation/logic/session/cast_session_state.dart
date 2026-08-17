import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'cast_session_state.freezed.dart';

@freezed
abstract class CastSessionState with _$CastSessionState {
  const factory CastSessionState({
    @Default(PureCastSessionState.disconnected) PureCastSessionState sessionState,
    PureCastDevice? activeDevice,
    PureCastMedia? activeMedia,
    @Default(StateStatus.initial) StateStatus sessionStatus,
    String? sessionError,
    @Default(StateStatus.initial) StateStatus playbackStatus,
    String? playbackError,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(1.0) double volume,
  }) = _CastSessionState;
}
