part of 'queue_bloc.dart';

@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    @Default([]) List<PureCastMedia> items,
    @Default(0) int currentIndex,
    @Default(StateStatus.initial) StateStatus status,
    String? error,
  }) = _QueueState;
}
