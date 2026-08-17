part of 'queue_bloc.dart';

@freezed
abstract class QueueEvent with _$QueueEvent {
  const factory QueueEvent.loadQueue() = LoadQueueEvent;
  const factory QueueEvent.addToQueue(PureCastMedia media) = AddToQueueEvent;
  const factory QueueEvent.removeFromQueue(String mediaUri) = RemoveFromQueueEvent;
  const factory QueueEvent.reorderQueue(int oldIndex, int newIndex) = ReorderQueueEvent;
  const factory QueueEvent.clearQueue() = ClearQueueEvent;
  const factory QueueEvent.nextQueueItem() = NextQueueItemEvent;
  const factory QueueEvent.previousQueueItem() = PreviousQueueItemEvent;
  const factory QueueEvent.setCurrentIndex(int index) = SetCurrentIndexEvent;
  const factory QueueEvent.pickFiles() = PicFilesEvent;
}
