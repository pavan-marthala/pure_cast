// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MediaEvent()';
}


}

/// @nodoc
class $MediaEventCopyWith<$Res>  {
$MediaEventCopyWith(MediaEvent _, $Res Function(MediaEvent) __);
}


/// Adds pattern-matching-related methods to [MediaEvent].
extension MediaEventPatterns on MediaEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RequestPermissionMediaEvent value)?  requestPermission,TResult Function( LoadMediaItemsEvent value)?  loadMedia,TResult Function( LoadNextPageMediaEvent value)?  loadNextPage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RequestPermissionMediaEvent() when requestPermission != null:
return requestPermission(_that);case LoadMediaItemsEvent() when loadMedia != null:
return loadMedia(_that);case LoadNextPageMediaEvent() when loadNextPage != null:
return loadNextPage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RequestPermissionMediaEvent value)  requestPermission,required TResult Function( LoadMediaItemsEvent value)  loadMedia,required TResult Function( LoadNextPageMediaEvent value)  loadNextPage,}){
final _that = this;
switch (_that) {
case RequestPermissionMediaEvent():
return requestPermission(_that);case LoadMediaItemsEvent():
return loadMedia(_that);case LoadNextPageMediaEvent():
return loadNextPage(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RequestPermissionMediaEvent value)?  requestPermission,TResult? Function( LoadMediaItemsEvent value)?  loadMedia,TResult? Function( LoadNextPageMediaEvent value)?  loadNextPage,}){
final _that = this;
switch (_that) {
case RequestPermissionMediaEvent() when requestPermission != null:
return requestPermission(_that);case LoadMediaItemsEvent() when loadMedia != null:
return loadMedia(_that);case LoadNextPageMediaEvent() when loadNextPage != null:
return loadNextPage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  requestPermission,TResult Function( RequestType filterType,  bool refresh)?  loadMedia,TResult Function()?  loadNextPage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RequestPermissionMediaEvent() when requestPermission != null:
return requestPermission();case LoadMediaItemsEvent() when loadMedia != null:
return loadMedia(_that.filterType,_that.refresh);case LoadNextPageMediaEvent() when loadNextPage != null:
return loadNextPage();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  requestPermission,required TResult Function( RequestType filterType,  bool refresh)  loadMedia,required TResult Function()  loadNextPage,}) {final _that = this;
switch (_that) {
case RequestPermissionMediaEvent():
return requestPermission();case LoadMediaItemsEvent():
return loadMedia(_that.filterType,_that.refresh);case LoadNextPageMediaEvent():
return loadNextPage();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  requestPermission,TResult? Function( RequestType filterType,  bool refresh)?  loadMedia,TResult? Function()?  loadNextPage,}) {final _that = this;
switch (_that) {
case RequestPermissionMediaEvent() when requestPermission != null:
return requestPermission();case LoadMediaItemsEvent() when loadMedia != null:
return loadMedia(_that.filterType,_that.refresh);case LoadNextPageMediaEvent() when loadNextPage != null:
return loadNextPage();case _:
  return null;

}
}

}

/// @nodoc


class RequestPermissionMediaEvent implements MediaEvent {
  const RequestPermissionMediaEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestPermissionMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MediaEvent.requestPermission()';
}


}




/// @nodoc


class LoadMediaItemsEvent implements MediaEvent {
  const LoadMediaItemsEvent({this.filterType = RequestType.common, this.refresh = false});
  

@JsonKey() final  RequestType filterType;
@JsonKey() final  bool refresh;

/// Create a copy of MediaEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadMediaItemsEventCopyWith<LoadMediaItemsEvent> get copyWith => _$LoadMediaItemsEventCopyWithImpl<LoadMediaItemsEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadMediaItemsEvent&&(identical(other.filterType, filterType) || other.filterType == filterType)&&(identical(other.refresh, refresh) || other.refresh == refresh));
}


@override
int get hashCode => Object.hash(runtimeType,filterType,refresh);

@override
String toString() {
  return 'MediaEvent.loadMedia(filterType: $filterType, refresh: $refresh)';
}


}

/// @nodoc
abstract mixin class $LoadMediaItemsEventCopyWith<$Res> implements $MediaEventCopyWith<$Res> {
  factory $LoadMediaItemsEventCopyWith(LoadMediaItemsEvent value, $Res Function(LoadMediaItemsEvent) _then) = _$LoadMediaItemsEventCopyWithImpl;
@useResult
$Res call({
 RequestType filterType, bool refresh
});




}
/// @nodoc
class _$LoadMediaItemsEventCopyWithImpl<$Res>
    implements $LoadMediaItemsEventCopyWith<$Res> {
  _$LoadMediaItemsEventCopyWithImpl(this._self, this._then);

  final LoadMediaItemsEvent _self;
  final $Res Function(LoadMediaItemsEvent) _then;

/// Create a copy of MediaEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filterType = null,Object? refresh = null,}) {
  return _then(LoadMediaItemsEvent(
filterType: null == filterType ? _self.filterType : filterType // ignore: cast_nullable_to_non_nullable
as RequestType,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LoadNextPageMediaEvent implements MediaEvent {
  const LoadNextPageMediaEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadNextPageMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MediaEvent.loadNextPage()';
}


}




// dart format on
