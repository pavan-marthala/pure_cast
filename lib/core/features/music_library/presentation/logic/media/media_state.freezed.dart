// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaState {

 List<PureCastMedia> get mediaItems; StateStatus get status; String? get error; bool get hasPermission; RequestType get selectedFilter; int get page; bool get hasMore;
/// Create a copy of MediaState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaStateCopyWith<MediaState> get copyWith => _$MediaStateCopyWithImpl<MediaState>(this as MediaState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaState&&const DeepCollectionEquality().equals(other.mediaItems, mediaItems)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasPermission, hasPermission) || other.hasPermission == hasPermission)&&(identical(other.selectedFilter, selectedFilter) || other.selectedFilter == selectedFilter)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(mediaItems),status,error,hasPermission,selectedFilter,page,hasMore);

@override
String toString() {
  return 'MediaState(mediaItems: $mediaItems, status: $status, error: $error, hasPermission: $hasPermission, selectedFilter: $selectedFilter, page: $page, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $MediaStateCopyWith<$Res>  {
  factory $MediaStateCopyWith(MediaState value, $Res Function(MediaState) _then) = _$MediaStateCopyWithImpl;
@useResult
$Res call({
 List<PureCastMedia> mediaItems, StateStatus status, String? error, bool hasPermission, RequestType selectedFilter, int page, bool hasMore
});




}
/// @nodoc
class _$MediaStateCopyWithImpl<$Res>
    implements $MediaStateCopyWith<$Res> {
  _$MediaStateCopyWithImpl(this._self, this._then);

  final MediaState _self;
  final $Res Function(MediaState) _then;

/// Create a copy of MediaState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaItems = null,Object? status = null,Object? error = freezed,Object? hasPermission = null,Object? selectedFilter = null,Object? page = null,Object? hasMore = null,}) {
  return _then(MediaState(
mediaItems: null == mediaItems ? _self.mediaItems : mediaItems // ignore: cast_nullable_to_non_nullable
as List<PureCastMedia>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StateStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasPermission: null == hasPermission ? _self.hasPermission : hasPermission // ignore: cast_nullable_to_non_nullable
as bool,selectedFilter: null == selectedFilter ? _self.selectedFilter : selectedFilter // ignore: cast_nullable_to_non_nullable
as RequestType,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaState].
extension MediaStatePatterns on MediaState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaState value)  $default,){
final _that = this;
switch (_that) {
case _MediaState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaState value)?  $default,){
final _that = this;
switch (_that) {
case _MediaState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PureCastMedia> mediaItems,  StateStatus status,  String? error,  bool hasPermission,  RequestType selectedFilter,  int page,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaState() when $default != null:
return $default(_that.mediaItems,_that.status,_that.error,_that.hasPermission,_that.selectedFilter,_that.page,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PureCastMedia> mediaItems,  StateStatus status,  String? error,  bool hasPermission,  RequestType selectedFilter,  int page,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _MediaState():
return $default(_that.mediaItems,_that.status,_that.error,_that.hasPermission,_that.selectedFilter,_that.page,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PureCastMedia> mediaItems,  StateStatus status,  String? error,  bool hasPermission,  RequestType selectedFilter,  int page,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _MediaState() when $default != null:
return $default(_that.mediaItems,_that.status,_that.error,_that.hasPermission,_that.selectedFilter,_that.page,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _MediaState implements MediaState {
  const _MediaState({ List<PureCastMedia> mediaItems = const [], this.status = StateStatus.initial, this.error, this.hasPermission = false, this.selectedFilter = RequestType.common, this.page = 0, this.hasMore = false}): _mediaItems = mediaItems;
  

 final  List<PureCastMedia> _mediaItems;
@override@JsonKey() List<PureCastMedia> get mediaItems {
  if (_mediaItems is EqualUnmodifiableListView) return _mediaItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaItems);
}

@override@JsonKey() final  StateStatus status;
@override final  String? error;
@override@JsonKey() final  bool hasPermission;
@override@JsonKey() final  RequestType selectedFilter;
@override@JsonKey() final  int page;
@override@JsonKey() final  bool hasMore;

/// Create a copy of MediaState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaStateCopyWith<_MediaState> get copyWith => __$MediaStateCopyWithImpl<_MediaState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaState&&const DeepCollectionEquality().equals(other._mediaItems, _mediaItems)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasPermission, hasPermission) || other.hasPermission == hasPermission)&&(identical(other.selectedFilter, selectedFilter) || other.selectedFilter == selectedFilter)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_mediaItems),status,error,hasPermission,selectedFilter,page,hasMore);

@override
String toString() {
  return 'MediaState(mediaItems: $mediaItems, status: $status, error: $error, hasPermission: $hasPermission, selectedFilter: $selectedFilter, page: $page, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$MediaStateCopyWith<$Res> implements $MediaStateCopyWith<$Res> {
  factory _$MediaStateCopyWith(_MediaState value, $Res Function(_MediaState) _then) = __$MediaStateCopyWithImpl;
@override @useResult
$Res call({
 List<PureCastMedia> mediaItems, StateStatus status, String? error, bool hasPermission, RequestType selectedFilter, int page, bool hasMore
});




}
/// @nodoc
class __$MediaStateCopyWithImpl<$Res>
    implements _$MediaStateCopyWith<$Res> {
  __$MediaStateCopyWithImpl(this._self, this._then);

  final _MediaState _self;
  final $Res Function(_MediaState) _then;

/// Create a copy of MediaState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaItems = null,Object? status = null,Object? error = freezed,Object? hasPermission = null,Object? selectedFilter = null,Object? page = null,Object? hasMore = null,}) {
  return _then(_MediaState(
mediaItems: null == mediaItems ? _self._mediaItems : mediaItems // ignore: cast_nullable_to_non_nullable
as List<PureCastMedia>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StateStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasPermission: null == hasPermission ? _self.hasPermission : hasPermission // ignore: cast_nullable_to_non_nullable
as bool,selectedFilter: null == selectedFilter ? _self.selectedFilter : selectedFilter // ignore: cast_nullable_to_non_nullable
as RequestType,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
