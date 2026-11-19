// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueueEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'QueueEvent()';
}


}

/// @nodoc
class $QueueEventCopyWith<$Res>  {
$QueueEventCopyWith(QueueEvent _, $Res Function(QueueEvent) __);
}


/// Adds pattern-matching-related methods to [QueueEvent].
extension QueueEventPatterns on QueueEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadQueueEvent value)?  loadQueue,TResult Function( AddToQueueEvent value)?  addToQueue,TResult Function( PlayMediaInQueueEvent value)?  playMedia,TResult Function( RemoveFromQueueEvent value)?  removeFromQueue,TResult Function( ReorderQueueEvent value)?  reorderQueue,TResult Function( ClearQueueEvent value)?  clearQueue,TResult Function( NextQueueItemEvent value)?  nextQueueItem,TResult Function( PreviousQueueItemEvent value)?  previousQueueItem,TResult Function( SetCurrentIndexEvent value)?  setCurrentIndex,TResult Function( PicFilesEvent value)?  pickFiles,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadQueueEvent() when loadQueue != null:
return loadQueue(_that);case AddToQueueEvent() when addToQueue != null:
return addToQueue(_that);case PlayMediaInQueueEvent() when playMedia != null:
return playMedia(_that);case RemoveFromQueueEvent() when removeFromQueue != null:
return removeFromQueue(_that);case ReorderQueueEvent() when reorderQueue != null:
return reorderQueue(_that);case ClearQueueEvent() when clearQueue != null:
return clearQueue(_that);case NextQueueItemEvent() when nextQueueItem != null:
return nextQueueItem(_that);case PreviousQueueItemEvent() when previousQueueItem != null:
return previousQueueItem(_that);case SetCurrentIndexEvent() when setCurrentIndex != null:
return setCurrentIndex(_that);case PicFilesEvent() when pickFiles != null:
return pickFiles(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadQueueEvent value)  loadQueue,required TResult Function( AddToQueueEvent value)  addToQueue,required TResult Function( PlayMediaInQueueEvent value)  playMedia,required TResult Function( RemoveFromQueueEvent value)  removeFromQueue,required TResult Function( ReorderQueueEvent value)  reorderQueue,required TResult Function( ClearQueueEvent value)  clearQueue,required TResult Function( NextQueueItemEvent value)  nextQueueItem,required TResult Function( PreviousQueueItemEvent value)  previousQueueItem,required TResult Function( SetCurrentIndexEvent value)  setCurrentIndex,required TResult Function( PicFilesEvent value)  pickFiles,}){
final _that = this;
switch (_that) {
case LoadQueueEvent():
return loadQueue(_that);case AddToQueueEvent():
return addToQueue(_that);case PlayMediaInQueueEvent():
return playMedia(_that);case RemoveFromQueueEvent():
return removeFromQueue(_that);case ReorderQueueEvent():
return reorderQueue(_that);case ClearQueueEvent():
return clearQueue(_that);case NextQueueItemEvent():
return nextQueueItem(_that);case PreviousQueueItemEvent():
return previousQueueItem(_that);case SetCurrentIndexEvent():
return setCurrentIndex(_that);case PicFilesEvent():
return pickFiles(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadQueueEvent value)?  loadQueue,TResult? Function( AddToQueueEvent value)?  addToQueue,TResult? Function( PlayMediaInQueueEvent value)?  playMedia,TResult? Function( RemoveFromQueueEvent value)?  removeFromQueue,TResult? Function( ReorderQueueEvent value)?  reorderQueue,TResult? Function( ClearQueueEvent value)?  clearQueue,TResult? Function( NextQueueItemEvent value)?  nextQueueItem,TResult? Function( PreviousQueueItemEvent value)?  previousQueueItem,TResult? Function( SetCurrentIndexEvent value)?  setCurrentIndex,TResult? Function( PicFilesEvent value)?  pickFiles,}){
final _that = this;
switch (_that) {
case LoadQueueEvent() when loadQueue != null:
return loadQueue(_that);case AddToQueueEvent() when addToQueue != null:
return addToQueue(_that);case PlayMediaInQueueEvent() when playMedia != null:
return playMedia(_that);case RemoveFromQueueEvent() when removeFromQueue != null:
return removeFromQueue(_that);case ReorderQueueEvent() when reorderQueue != null:
return reorderQueue(_that);case ClearQueueEvent() when clearQueue != null:
return clearQueue(_that);case NextQueueItemEvent() when nextQueueItem != null:
return nextQueueItem(_that);case PreviousQueueItemEvent() when previousQueueItem != null:
return previousQueueItem(_that);case SetCurrentIndexEvent() when setCurrentIndex != null:
return setCurrentIndex(_that);case PicFilesEvent() when pickFiles != null:
return pickFiles(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadQueue,TResult Function( PureCastMedia media)?  addToQueue,TResult Function( PureCastMedia media,  Duration? startPosition)?  playMedia,TResult Function( String mediaUri)?  removeFromQueue,TResult Function( int oldIndex,  int newIndex)?  reorderQueue,TResult Function()?  clearQueue,TResult Function()?  nextQueueItem,TResult Function()?  previousQueueItem,TResult Function( int index)?  setCurrentIndex,TResult Function()?  pickFiles,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadQueueEvent() when loadQueue != null:
return loadQueue();case AddToQueueEvent() when addToQueue != null:
return addToQueue(_that.media);case PlayMediaInQueueEvent() when playMedia != null:
return playMedia(_that.media,_that.startPosition);case RemoveFromQueueEvent() when removeFromQueue != null:
return removeFromQueue(_that.mediaUri);case ReorderQueueEvent() when reorderQueue != null:
return reorderQueue(_that.oldIndex,_that.newIndex);case ClearQueueEvent() when clearQueue != null:
return clearQueue();case NextQueueItemEvent() when nextQueueItem != null:
return nextQueueItem();case PreviousQueueItemEvent() when previousQueueItem != null:
return previousQueueItem();case SetCurrentIndexEvent() when setCurrentIndex != null:
return setCurrentIndex(_that.index);case PicFilesEvent() when pickFiles != null:
return pickFiles();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadQueue,required TResult Function( PureCastMedia media)  addToQueue,required TResult Function( PureCastMedia media,  Duration? startPosition)  playMedia,required TResult Function( String mediaUri)  removeFromQueue,required TResult Function( int oldIndex,  int newIndex)  reorderQueue,required TResult Function()  clearQueue,required TResult Function()  nextQueueItem,required TResult Function()  previousQueueItem,required TResult Function( int index)  setCurrentIndex,required TResult Function()  pickFiles,}) {final _that = this;
switch (_that) {
case LoadQueueEvent():
return loadQueue();case AddToQueueEvent():
return addToQueue(_that.media);case PlayMediaInQueueEvent():
return playMedia(_that.media,_that.startPosition);case RemoveFromQueueEvent():
return removeFromQueue(_that.mediaUri);case ReorderQueueEvent():
return reorderQueue(_that.oldIndex,_that.newIndex);case ClearQueueEvent():
return clearQueue();case NextQueueItemEvent():
return nextQueueItem();case PreviousQueueItemEvent():
return previousQueueItem();case SetCurrentIndexEvent():
return setCurrentIndex(_that.index);case PicFilesEvent():
return pickFiles();case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadQueue,TResult? Function( PureCastMedia media)?  addToQueue,TResult? Function( PureCastMedia media,  Duration? startPosition)?  playMedia,TResult? Function( String mediaUri)?  removeFromQueue,TResult? Function( int oldIndex,  int newIndex)?  reorderQueue,TResult? Function()?  clearQueue,TResult? Function()?  nextQueueItem,TResult? Function()?  previousQueueItem,TResult? Function( int index)?  setCurrentIndex,TResult? Function()?  pickFiles,}) {final _that = this;
switch (_that) {
case LoadQueueEvent() when loadQueue != null:
return loadQueue();case AddToQueueEvent() when addToQueue != null:
return addToQueue(_that.media);case PlayMediaInQueueEvent() when playMedia != null:
return playMedia(_that.media,_that.startPosition);case RemoveFromQueueEvent() when removeFromQueue != null:
return removeFromQueue(_that.mediaUri);case ReorderQueueEvent() when reorderQueue != null:
return reorderQueue(_that.oldIndex,_that.newIndex);case ClearQueueEvent() when clearQueue != null:
return clearQueue();case NextQueueItemEvent() when nextQueueItem != null:
return nextQueueItem();case PreviousQueueItemEvent() when previousQueueItem != null:
return previousQueueItem();case SetCurrentIndexEvent() when setCurrentIndex != null:
return setCurrentIndex(_that.index);case PicFilesEvent() when pickFiles != null:
return pickFiles();case _:
  return null;

}
}

}

/// @nodoc


class LoadQueueEvent implements QueueEvent {
  const LoadQueueEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadQueueEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'QueueEvent.loadQueue()';
}


}




/// @nodoc


class AddToQueueEvent implements QueueEvent {
  const AddToQueueEvent(this.media);
  

 final  PureCastMedia media;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddToQueueEventCopyWith<AddToQueueEvent> get copyWith => _$AddToQueueEventCopyWithImpl<AddToQueueEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AddToQueueEvent&&(identical(other.media, media) || other.media == media));
}


@override
int get hashCode {
    return Object.hash(runtimeType,media);
}

@override
String toString() {
    return 'QueueEvent.addToQueue(media: $media)';
}


}

/// @nodoc
abstract mixin class $AddToQueueEventCopyWith<$Res> implements $QueueEventCopyWith<$Res> {
  factory $AddToQueueEventCopyWith(AddToQueueEvent value, $Res Function(AddToQueueEvent) _then) = _$AddToQueueEventCopyWithImpl;
@useResult
$Res call({
 PureCastMedia media
});




}
/// @nodoc
class _$AddToQueueEventCopyWithImpl<$Res>
    implements $AddToQueueEventCopyWith<$Res> {
  _$AddToQueueEventCopyWithImpl(this._self, this._then);

  final AddToQueueEvent _self;
  final $Res Function(AddToQueueEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? media = null,}) {
  return _then(AddToQueueEvent(
null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as PureCastMedia,
  ));
}


}

/// @nodoc


class PlayMediaInQueueEvent implements QueueEvent {
  const PlayMediaInQueueEvent(this.media, {this.startPosition});
  

 final  PureCastMedia media;
 final  Duration? startPosition;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayMediaInQueueEventCopyWith<PlayMediaInQueueEvent> get copyWith => _$PlayMediaInQueueEventCopyWithImpl<PlayMediaInQueueEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayMediaInQueueEvent&&(identical(other.media, media) || other.media == media)&&(identical(other.startPosition, startPosition) || other.startPosition == startPosition));
}


@override
int get hashCode {
    return Object.hash(runtimeType,media,startPosition);
}

@override
String toString() {
    return 'QueueEvent.playMedia(media: $media, startPosition: $startPosition)';
}


}

/// @nodoc
abstract mixin class $PlayMediaInQueueEventCopyWith<$Res> implements $QueueEventCopyWith<$Res> {
  factory $PlayMediaInQueueEventCopyWith(PlayMediaInQueueEvent value, $Res Function(PlayMediaInQueueEvent) _then) = _$PlayMediaInQueueEventCopyWithImpl;
@useResult
$Res call({
 PureCastMedia media, Duration? startPosition
});




}
/// @nodoc
class _$PlayMediaInQueueEventCopyWithImpl<$Res>
    implements $PlayMediaInQueueEventCopyWith<$Res> {
  _$PlayMediaInQueueEventCopyWithImpl(this._self, this._then);

  final PlayMediaInQueueEvent _self;
  final $Res Function(PlayMediaInQueueEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? media = null,Object? startPosition = freezed,}) {
  return _then(PlayMediaInQueueEvent(
null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as PureCastMedia,startPosition: freezed == startPosition ? _self.startPosition : startPosition // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class RemoveFromQueueEvent implements QueueEvent {
  const RemoveFromQueueEvent(this.mediaUri);
  

 final  String mediaUri;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveFromQueueEventCopyWith<RemoveFromQueueEvent> get copyWith => _$RemoveFromQueueEventCopyWithImpl<RemoveFromQueueEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveFromQueueEvent&&(identical(other.mediaUri, mediaUri) || other.mediaUri == mediaUri));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mediaUri);
}

@override
String toString() {
    return 'QueueEvent.removeFromQueue(mediaUri: $mediaUri)';
}


}

/// @nodoc
abstract mixin class $RemoveFromQueueEventCopyWith<$Res> implements $QueueEventCopyWith<$Res> {
  factory $RemoveFromQueueEventCopyWith(RemoveFromQueueEvent value, $Res Function(RemoveFromQueueEvent) _then) = _$RemoveFromQueueEventCopyWithImpl;
@useResult
$Res call({
 String mediaUri
});




}
/// @nodoc
class _$RemoveFromQueueEventCopyWithImpl<$Res>
    implements $RemoveFromQueueEventCopyWith<$Res> {
  _$RemoveFromQueueEventCopyWithImpl(this._self, this._then);

  final RemoveFromQueueEvent _self;
  final $Res Function(RemoveFromQueueEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mediaUri = null,}) {
  return _then(RemoveFromQueueEvent(
null == mediaUri ? _self.mediaUri : mediaUri // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReorderQueueEvent implements QueueEvent {
  const ReorderQueueEvent(this.oldIndex, this.newIndex);
  

 final  int oldIndex;
 final  int newIndex;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReorderQueueEventCopyWith<ReorderQueueEvent> get copyWith => _$ReorderQueueEventCopyWithImpl<ReorderQueueEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderQueueEvent&&(identical(other.oldIndex, oldIndex) || other.oldIndex == oldIndex)&&(identical(other.newIndex, newIndex) || other.newIndex == newIndex));
}


@override
int get hashCode {
    return Object.hash(runtimeType,oldIndex,newIndex);
}

@override
String toString() {
    return 'QueueEvent.reorderQueue(oldIndex: $oldIndex, newIndex: $newIndex)';
}


}

/// @nodoc
abstract mixin class $ReorderQueueEventCopyWith<$Res> implements $QueueEventCopyWith<$Res> {
  factory $ReorderQueueEventCopyWith(ReorderQueueEvent value, $Res Function(ReorderQueueEvent) _then) = _$ReorderQueueEventCopyWithImpl;
@useResult
$Res call({
 int oldIndex, int newIndex
});




}
/// @nodoc
class _$ReorderQueueEventCopyWithImpl<$Res>
    implements $ReorderQueueEventCopyWith<$Res> {
  _$ReorderQueueEventCopyWithImpl(this._self, this._then);

  final ReorderQueueEvent _self;
  final $Res Function(ReorderQueueEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? oldIndex = null,Object? newIndex = null,}) {
  return _then(ReorderQueueEvent(
null == oldIndex ? _self.oldIndex : oldIndex // ignore: cast_nullable_to_non_nullable
as int,null == newIndex ? _self.newIndex : newIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ClearQueueEvent implements QueueEvent {
  const ClearQueueEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ClearQueueEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'QueueEvent.clearQueue()';
}


}




/// @nodoc


class NextQueueItemEvent implements QueueEvent {
  const NextQueueItemEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NextQueueItemEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'QueueEvent.nextQueueItem()';
}


}




/// @nodoc


class PreviousQueueItemEvent implements QueueEvent {
  const PreviousQueueItemEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PreviousQueueItemEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'QueueEvent.previousQueueItem()';
}


}




/// @nodoc


class SetCurrentIndexEvent implements QueueEvent {
  const SetCurrentIndexEvent(this.index);
  

 final  int index;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetCurrentIndexEventCopyWith<SetCurrentIndexEvent> get copyWith => _$SetCurrentIndexEventCopyWithImpl<SetCurrentIndexEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetCurrentIndexEvent&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode {
    return Object.hash(runtimeType,index);
}

@override
String toString() {
    return 'QueueEvent.setCurrentIndex(index: $index)';
}


}

/// @nodoc
abstract mixin class $SetCurrentIndexEventCopyWith<$Res> implements $QueueEventCopyWith<$Res> {
  factory $SetCurrentIndexEventCopyWith(SetCurrentIndexEvent value, $Res Function(SetCurrentIndexEvent) _then) = _$SetCurrentIndexEventCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class _$SetCurrentIndexEventCopyWithImpl<$Res>
    implements $SetCurrentIndexEventCopyWith<$Res> {
  _$SetCurrentIndexEventCopyWithImpl(this._self, this._then);

  final SetCurrentIndexEvent _self;
  final $Res Function(SetCurrentIndexEvent) _then;

/// Create a copy of QueueEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(SetCurrentIndexEvent(
null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PicFilesEvent implements QueueEvent {
  const PicFilesEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PicFilesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'QueueEvent.pickFiles()';
}


}




/// @nodoc
mixin _$QueueState {

 List<PureCastMedia> get items; int get currentIndex; StateStatus get status; String? get error;/// True when [items] were restored from storage on launch rather than
/// produced by a user action. The playback coordinator must not start
/// playback for a restored queue.
 bool get restoredFromStorage;/// Incremented whenever the user explicitly asks to play a queue item.
/// The playback coordinator loads that item (with its start position)
/// even when the selected index did not change.
 int get playRequestId;/// Offset applied to the next explicit play request only.
///
/// Transient: it is never persisted and auto-advance never reads it.
 Duration? get pendingStartPosition;
/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueStateCopyWith<QueueState> get copyWith => _$QueueStateCopyWithImpl<QueueState>(this as QueueState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QueueState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.restoredFromStorage, _this.restoredFromStorage) || other.restoredFromStorage == _this.restoredFromStorage)&&(identical(other.playRequestId, _this.playRequestId) || other.playRequestId == _this.playRequestId)&&(identical(other.pendingStartPosition, _this.pendingStartPosition) || other.pendingStartPosition == _this.pendingStartPosition));
}


@override
int get hashCode {
  final _this = this as QueueState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.currentIndex,_this.status,_this.error,_this.restoredFromStorage,_this.playRequestId,_this.pendingStartPosition);
}

@override
String toString() {
  final _this = this as QueueState;
  return 'QueueState(items: ${_this.items}, currentIndex: ${_this.currentIndex}, status: ${_this.status}, error: ${_this.error}, restoredFromStorage: ${_this.restoredFromStorage}, playRequestId: ${_this.playRequestId}, pendingStartPosition: ${_this.pendingStartPosition})';
}


}

/// @nodoc
abstract mixin class $QueueStateCopyWith<$Res>  {
  factory $QueueStateCopyWith(QueueState value, $Res Function(QueueState) _then) = _$QueueStateCopyWithImpl;
@useResult
$Res call({
 List<PureCastMedia> items, int currentIndex, StateStatus status, String? error, bool restoredFromStorage, int playRequestId, Duration? pendingStartPosition
});




}
/// @nodoc
class _$QueueStateCopyWithImpl<$Res>
    implements $QueueStateCopyWith<$Res> {
  _$QueueStateCopyWithImpl(this._self, this._then);

  final QueueState _self;
  final $Res Function(QueueState) _then;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? currentIndex = null,Object? status = null,Object? error = freezed,Object? restoredFromStorage = null,Object? playRequestId = null,Object? pendingStartPosition = freezed,}) {
  return _then(QueueState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PureCastMedia>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StateStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,restoredFromStorage: null == restoredFromStorage ? _self.restoredFromStorage : restoredFromStorage // ignore: cast_nullable_to_non_nullable
as bool,playRequestId: null == playRequestId ? _self.playRequestId : playRequestId // ignore: cast_nullable_to_non_nullable
as int,pendingStartPosition: freezed == pendingStartPosition ? _self.pendingStartPosition : pendingStartPosition // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueState].
extension QueueStatePatterns on QueueState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueState value)  $default,){
final _that = this;
switch (_that) {
case _QueueState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueState value)?  $default,){
final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PureCastMedia> items,  int currentIndex,  StateStatus status,  String? error,  bool restoredFromStorage,  int playRequestId,  Duration? pendingStartPosition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that.items,_that.currentIndex,_that.status,_that.error,_that.restoredFromStorage,_that.playRequestId,_that.pendingStartPosition);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PureCastMedia> items,  int currentIndex,  StateStatus status,  String? error,  bool restoredFromStorage,  int playRequestId,  Duration? pendingStartPosition)  $default,) {final _that = this;
switch (_that) {
case _QueueState():
return $default(_that.items,_that.currentIndex,_that.status,_that.error,_that.restoredFromStorage,_that.playRequestId,_that.pendingStartPosition);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PureCastMedia> items,  int currentIndex,  StateStatus status,  String? error,  bool restoredFromStorage,  int playRequestId,  Duration? pendingStartPosition)?  $default,) {final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that.items,_that.currentIndex,_that.status,_that.error,_that.restoredFromStorage,_that.playRequestId,_that.pendingStartPosition);case _:
  return null;

}
}

}

/// @nodoc


class _QueueState implements QueueState {
  const _QueueState({ List<PureCastMedia> items = const [], this.currentIndex = 0, this.status = StateStatus.initial, this.error, this.restoredFromStorage = false, this.playRequestId = 0, this.pendingStartPosition}): _items = items;
  

 final  List<PureCastMedia> _items;
@override@JsonKey() List<PureCastMedia> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int currentIndex;
@override@JsonKey() final  StateStatus status;
@override final  String? error;
/// True when [items] were restored from storage on launch rather than
/// produced by a user action. The playback coordinator must not start
/// playback for a restored queue.
@override@JsonKey() final  bool restoredFromStorage;
/// Incremented whenever the user explicitly asks to play a queue item.
/// The playback coordinator loads that item (with its start position)
/// even when the selected index did not change.
@override@JsonKey() final  int playRequestId;
/// Offset applied to the next explicit play request only.
///
/// Transient: it is never persisted and auto-advance never reads it.
@override final  Duration? pendingStartPosition;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueStateCopyWith<_QueueState> get copyWith => __$QueueStateCopyWithImpl<_QueueState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.restoredFromStorage, restoredFromStorage) || other.restoredFromStorage == restoredFromStorage)&&(identical(other.playRequestId, playRequestId) || other.playRequestId == playRequestId)&&(identical(other.pendingStartPosition, pendingStartPosition) || other.pendingStartPosition == pendingStartPosition));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),currentIndex,status,error,restoredFromStorage,playRequestId,pendingStartPosition);
}

@override
String toString() {
    return 'QueueState(items: $items, currentIndex: $currentIndex, status: $status, error: $error, restoredFromStorage: $restoredFromStorage, playRequestId: $playRequestId, pendingStartPosition: $pendingStartPosition)';
}


}

/// @nodoc
abstract mixin class _$QueueStateCopyWith<$Res> implements $QueueStateCopyWith<$Res> {
  factory _$QueueStateCopyWith(_QueueState value, $Res Function(_QueueState) _then) = __$QueueStateCopyWithImpl;
@override @useResult
$Res call({
 List<PureCastMedia> items, int currentIndex, StateStatus status, String? error, bool restoredFromStorage, int playRequestId, Duration? pendingStartPosition
});




}
/// @nodoc
class __$QueueStateCopyWithImpl<$Res>
    implements _$QueueStateCopyWith<$Res> {
  __$QueueStateCopyWithImpl(this._self, this._then);

  final _QueueState _self;
  final $Res Function(_QueueState) _then;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? currentIndex = null,Object? status = null,Object? error = freezed,Object? restoredFromStorage = null,Object? playRequestId = null,Object? pendingStartPosition = freezed,}) {
  return _then(_QueueState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PureCastMedia>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StateStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,restoredFromStorage: null == restoredFromStorage ? _self.restoredFromStorage : restoredFromStorage // ignore: cast_nullable_to_non_nullable
as bool,playRequestId: null == playRequestId ? _self.playRequestId : playRequestId // ignore: cast_nullable_to_non_nullable
as int,pendingStartPosition: freezed == pendingStartPosition ? _self.pendingStartPosition : pendingStartPosition // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
