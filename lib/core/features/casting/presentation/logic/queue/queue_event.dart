import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

abstract class QueueEvent {
  const QueueEvent();
}

class LoadQueueEvent extends QueueEvent {
  const LoadQueueEvent();
}

class AddToQueueEvent extends QueueEvent {
  final PureCastMedia media;

  const AddToQueueEvent(this.media);
}

class RemoveFromQueueEvent extends QueueEvent {
  final String mediaUri;

  const RemoveFromQueueEvent(this.mediaUri);
}

class ReorderQueueEvent extends QueueEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderQueueEvent(this.oldIndex, this.newIndex);
}

class ClearQueueEvent extends QueueEvent {
  const ClearQueueEvent();
}

class NextQueueItemEvent extends QueueEvent {
  const NextQueueItemEvent();
}

class PreviousQueueItemEvent extends QueueEvent {
  const PreviousQueueItemEvent();
}

class SetCurrentIndexEvent extends QueueEvent {
  final int index;

  const SetCurrentIndexEvent(this.index);
}
