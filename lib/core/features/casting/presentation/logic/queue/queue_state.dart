import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'queue_state.freezed.dart';

@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    @Default([]) List<PureCastMedia> items,
    @Default(0) int currentIndex,
    @Default(StateStatus.initial) StateStatus status,
    String? error,
  }) = _QueueState;
}
