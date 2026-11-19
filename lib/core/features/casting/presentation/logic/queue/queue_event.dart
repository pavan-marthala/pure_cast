part of 'queue_bloc.dart';

@freezed
abstract class QueueEvent with _$QueueEvent {
  const factory QueueEvent.loadQueue() = LoadQueueEvent;
  const factory QueueEvent.addToQueue(PureCastMedia media) = AddToQueueEvent;

  /// Plays [media] now, adding it to the queue if needed.
  ///
  /// When the media is already queued the existing entry is reused instead of
  /// adding a duplicate. [startPosition] is an optional resume offset applied
  /// on the next load only.
  const factory QueueEvent.playMedia(
    PureCastMedia media, {
    Duration? startPosition,
  }) = PlayMediaInQueueEvent;
  const factory QueueEvent.removeFromQueue(String mediaUri) =
      RemoveFromQueueEvent;
  const factory QueueEvent.reorderQueue(int oldIndex, int newIndex) =
      ReorderQueueEvent;
  const factory QueueEvent.clearQueue() = ClearQueueEvent;
  const factory QueueEvent.nextQueueItem() = NextQueueItemEvent;
  const factory QueueEvent.previousQueueItem() = PreviousQueueItemEvent;
  const factory QueueEvent.setCurrentIndex(int index) = SetCurrentIndexEvent;
  const factory QueueEvent.pickFiles() = PicFilesEvent;
}
