part of 'queue_bloc.dart';

@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    @Default([]) List<PureCastMedia> items,
    @Default(0) int currentIndex,
    @Default(StateStatus.initial) StateStatus status,
    String? error,
    /// True when [items] were restored from storage on launch rather than
    /// produced by a user action. The playback coordinator must not start
    /// playback for a restored queue.
    @Default(false) bool restoredFromStorage,
  }) = _QueueState;
}
