// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recently_played_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecentlyPlayedEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentlyPlayedEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecentlyPlayedEvent()';
}


}

/// @nodoc
class $RecentlyPlayedEventCopyWith<$Res>  {
$RecentlyPlayedEventCopyWith(RecentlyPlayedEvent _, $Res Function(RecentlyPlayedEvent) __);
}


/// Adds pattern-matching-related methods to [RecentlyPlayedEvent].
extension RecentlyPlayedEventPatterns on RecentlyPlayedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadRecentlyPlayedEvent value)?  load,TResult Function( RefreshRecentlyPlayedEvent value)?  refresh,TResult Function( RemoveRecentlyPlayedEvent value)?  remove,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadRecentlyPlayedEvent() when load != null:
return load(_that);case RefreshRecentlyPlayedEvent() when refresh != null:
return refresh(_that);case RemoveRecentlyPlayedEvent() when remove != null:
return remove(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadRecentlyPlayedEvent value)  load,required TResult Function( RefreshRecentlyPlayedEvent value)  refresh,required TResult Function( RemoveRecentlyPlayedEvent value)  remove,}){
final _that = this;
switch (_that) {
case LoadRecentlyPlayedEvent():
return load(_that);case RefreshRecentlyPlayedEvent():
return refresh(_that);case RemoveRecentlyPlayedEvent():
return remove(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadRecentlyPlayedEvent value)?  load,TResult? Function( RefreshRecentlyPlayedEvent value)?  refresh,TResult? Function( RemoveRecentlyPlayedEvent value)?  remove,}){
final _that = this;
switch (_that) {
case LoadRecentlyPlayedEvent() when load != null:
return load(_that);case RefreshRecentlyPlayedEvent() when refresh != null:
return refresh(_that);case RemoveRecentlyPlayedEvent() when remove != null:
return remove(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  load,TResult Function()?  refresh,TResult Function( String mediaUri)?  remove,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadRecentlyPlayedEvent() when load != null:
return load();case RefreshRecentlyPlayedEvent() when refresh != null:
return refresh();case RemoveRecentlyPlayedEvent() when remove != null:
return remove(_that.mediaUri);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  load,required TResult Function()  refresh,required TResult Function( String mediaUri)  remove,}) {final _that = this;
switch (_that) {
case LoadRecentlyPlayedEvent():
return load();case RefreshRecentlyPlayedEvent():
return refresh();case RemoveRecentlyPlayedEvent():
return remove(_that.mediaUri);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  load,TResult? Function()?  refresh,TResult? Function( String mediaUri)?  remove,}) {final _that = this;
switch (_that) {
case LoadRecentlyPlayedEvent() when load != null:
return load();case RefreshRecentlyPlayedEvent() when refresh != null:
return refresh();case RemoveRecentlyPlayedEvent() when remove != null:
return remove(_that.mediaUri);case _:
  return null;

}
}

}

/// @nodoc


class LoadRecentlyPlayedEvent implements RecentlyPlayedEvent {
  const LoadRecentlyPlayedEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadRecentlyPlayedEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecentlyPlayedEvent.load()';
}


}




/// @nodoc


class RefreshRecentlyPlayedEvent implements RecentlyPlayedEvent {
  const RefreshRecentlyPlayedEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshRecentlyPlayedEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecentlyPlayedEvent.refresh()';
}


}




/// @nodoc


class RemoveRecentlyPlayedEvent implements RecentlyPlayedEvent {
  const RemoveRecentlyPlayedEvent(this.mediaUri);
  

 final  String mediaUri;

/// Create a copy of RecentlyPlayedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveRecentlyPlayedEventCopyWith<RemoveRecentlyPlayedEvent> get copyWith => _$RemoveRecentlyPlayedEventCopyWithImpl<RemoveRecentlyPlayedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveRecentlyPlayedEvent&&(identical(other.mediaUri, mediaUri) || other.mediaUri == mediaUri));
}


@override
int get hashCode => Object.hash(runtimeType,mediaUri);

@override
String toString() {
  return 'RecentlyPlayedEvent.remove(mediaUri: $mediaUri)';
}


}

/// @nodoc
abstract mixin class $RemoveRecentlyPlayedEventCopyWith<$Res> implements $RecentlyPlayedEventCopyWith<$Res> {
  factory $RemoveRecentlyPlayedEventCopyWith(RemoveRecentlyPlayedEvent value, $Res Function(RemoveRecentlyPlayedEvent) _then) = _$RemoveRecentlyPlayedEventCopyWithImpl;
@useResult
$Res call({
 String mediaUri
});




}
/// @nodoc
class _$RemoveRecentlyPlayedEventCopyWithImpl<$Res>
    implements $RemoveRecentlyPlayedEventCopyWith<$Res> {
  _$RemoveRecentlyPlayedEventCopyWithImpl(this._self, this._then);

  final RemoveRecentlyPlayedEvent _self;
  final $Res Function(RemoveRecentlyPlayedEvent) _then;

/// Create a copy of RecentlyPlayedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mediaUri = null,}) {
  return _then(RemoveRecentlyPlayedEvent(
null == mediaUri ? _self.mediaUri : mediaUri // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RecentlyPlayedState {

 List<PureCastMedia> get media; StateStatus get status; String? get error;
/// Create a copy of RecentlyPlayedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentlyPlayedStateCopyWith<RecentlyPlayedState> get copyWith => _$RecentlyPlayedStateCopyWithImpl<RecentlyPlayedState>(this as RecentlyPlayedState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentlyPlayedState&&const DeepCollectionEquality().equals(other.media, media)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(media),status,error);

@override
String toString() {
  return 'RecentlyPlayedState(media: $media, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class $RecentlyPlayedStateCopyWith<$Res>  {
  factory $RecentlyPlayedStateCopyWith(RecentlyPlayedState value, $Res Function(RecentlyPlayedState) _then) = _$RecentlyPlayedStateCopyWithImpl;
@useResult
$Res call({
 List<PureCastMedia> media, StateStatus status, String? error
});




}
/// @nodoc
class _$RecentlyPlayedStateCopyWithImpl<$Res>
    implements $RecentlyPlayedStateCopyWith<$Res> {
  _$RecentlyPlayedStateCopyWithImpl(this._self, this._then);

  final RecentlyPlayedState _self;
  final $Res Function(RecentlyPlayedState) _then;

/// Create a copy of RecentlyPlayedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? media = null,Object? status = null,Object? error = freezed,}) {
  return _then(RecentlyPlayedState(
media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<PureCastMedia>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StateStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentlyPlayedState].
extension RecentlyPlayedStatePatterns on RecentlyPlayedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentlyPlayedState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentlyPlayedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentlyPlayedState value)  $default,){
final _that = this;
switch (_that) {
case _RecentlyPlayedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentlyPlayedState value)?  $default,){
final _that = this;
switch (_that) {
case _RecentlyPlayedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PureCastMedia> media,  StateStatus status,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentlyPlayedState() when $default != null:
return $default(_that.media,_that.status,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PureCastMedia> media,  StateStatus status,  String? error)  $default,) {final _that = this;
switch (_that) {
case _RecentlyPlayedState():
return $default(_that.media,_that.status,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PureCastMedia> media,  StateStatus status,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _RecentlyPlayedState() when $default != null:
return $default(_that.media,_that.status,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _RecentlyPlayedState implements RecentlyPlayedState {
  const _RecentlyPlayedState({ List<PureCastMedia> media = const [], this.status = StateStatus.initial, this.error}): _media = media;
  

 final  List<PureCastMedia> _media;
@override@JsonKey() List<PureCastMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override@JsonKey() final  StateStatus status;
@override final  String? error;

/// Create a copy of RecentlyPlayedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentlyPlayedStateCopyWith<_RecentlyPlayedState> get copyWith => __$RecentlyPlayedStateCopyWithImpl<_RecentlyPlayedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentlyPlayedState&&const DeepCollectionEquality().equals(other._media, _media)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_media),status,error);

@override
String toString() {
  return 'RecentlyPlayedState(media: $media, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class _$RecentlyPlayedStateCopyWith<$Res> implements $RecentlyPlayedStateCopyWith<$Res> {
  factory _$RecentlyPlayedStateCopyWith(_RecentlyPlayedState value, $Res Function(_RecentlyPlayedState) _then) = __$RecentlyPlayedStateCopyWithImpl;
@override @useResult
$Res call({
 List<PureCastMedia> media, StateStatus status, String? error
});




}
/// @nodoc
class __$RecentlyPlayedStateCopyWithImpl<$Res>
    implements _$RecentlyPlayedStateCopyWith<$Res> {
  __$RecentlyPlayedStateCopyWithImpl(this._self, this._then);

  final _RecentlyPlayedState _self;
  final $Res Function(_RecentlyPlayedState) _then;

/// Create a copy of RecentlyPlayedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? media = null,Object? status = null,Object? error = freezed,}) {
  return _then(_RecentlyPlayedState(
media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<PureCastMedia>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StateStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
