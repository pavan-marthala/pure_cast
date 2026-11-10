// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_extraction_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubtitleExtractionEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleExtractionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SubtitleExtractionEvent()';
}


}

/// @nodoc
class $SubtitleExtractionEventCopyWith<$Res>  {
$SubtitleExtractionEventCopyWith(SubtitleExtractionEvent _, $Res Function(SubtitleExtractionEvent) __);
}


/// Adds pattern-matching-related methods to [SubtitleExtractionEvent].
extension SubtitleExtractionEventPatterns on SubtitleExtractionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InspectSubtitlesEvent value)?  inspectSubtitles,TResult Function( ClearResultsEvent value)?  clearResults,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that);case ClearResultsEvent() when clearResults != null:
return clearResults(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InspectSubtitlesEvent value)  inspectSubtitles,required TResult Function( ClearResultsEvent value)  clearResults,}){
final _that = this;
switch (_that) {
case InspectSubtitlesEvent():
return inspectSubtitles(_that);case ClearResultsEvent():
return clearResults(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InspectSubtitlesEvent value)?  inspectSubtitles,TResult? Function( ClearResultsEvent value)?  clearResults,}){
final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that);case ClearResultsEvent() when clearResults != null:
return clearResults(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String filePath,  int fileSize,  DateTime lastModified)?  inspectSubtitles,TResult Function()?  clearResults,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that.filePath,_that.fileSize,_that.lastModified);case ClearResultsEvent() when clearResults != null:
return clearResults();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String filePath,  int fileSize,  DateTime lastModified)  inspectSubtitles,required TResult Function()  clearResults,}) {final _that = this;
switch (_that) {
case InspectSubtitlesEvent():
return inspectSubtitles(_that.filePath,_that.fileSize,_that.lastModified);case ClearResultsEvent():
return clearResults();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String filePath,  int fileSize,  DateTime lastModified)?  inspectSubtitles,TResult? Function()?  clearResults,}) {final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that.filePath,_that.fileSize,_that.lastModified);case ClearResultsEvent() when clearResults != null:
return clearResults();case _:
  return null;

}
}

}

/// @nodoc


class InspectSubtitlesEvent implements SubtitleExtractionEvent {
  const InspectSubtitlesEvent({required this.filePath, required this.fileSize, required this.lastModified});
  

 final  String filePath;
 final  int fileSize;
 final  DateTime lastModified;

/// Create a copy of SubtitleExtractionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectSubtitlesEventCopyWith<InspectSubtitlesEvent> get copyWith => _$InspectSubtitlesEventCopyWithImpl<InspectSubtitlesEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectSubtitlesEvent&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified));
}


@override
int get hashCode {
    return Object.hash(runtimeType,filePath,fileSize,lastModified);
}

@override
String toString() {
    return 'SubtitleExtractionEvent.inspectSubtitles(filePath: $filePath, fileSize: $fileSize, lastModified: $lastModified)';
}


}

/// @nodoc
abstract mixin class $InspectSubtitlesEventCopyWith<$Res> implements $SubtitleExtractionEventCopyWith<$Res> {
  factory $InspectSubtitlesEventCopyWith(InspectSubtitlesEvent value, $Res Function(InspectSubtitlesEvent) _then) = _$InspectSubtitlesEventCopyWithImpl;
@useResult
$Res call({
 String filePath, int fileSize, DateTime lastModified
});




}
/// @nodoc
class _$InspectSubtitlesEventCopyWithImpl<$Res>
    implements $InspectSubtitlesEventCopyWith<$Res> {
  _$InspectSubtitlesEventCopyWithImpl(this._self, this._then);

  final InspectSubtitlesEvent _self;
  final $Res Function(InspectSubtitlesEvent) _then;

/// Create a copy of SubtitleExtractionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filePath = null,Object? fileSize = null,Object? lastModified = null,}) {
  return _then(InspectSubtitlesEvent(
filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ClearResultsEvent implements SubtitleExtractionEvent {
  const ClearResultsEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ClearResultsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SubtitleExtractionEvent.clearResults()';
}


}




/// @nodoc
mixin _$SubtitleExtractionState {

 SubtitleExtractionStatus get status; String? get currentFilePath; String? get error; List<SubtitleStreamInfo> get streams;
/// Create a copy of SubtitleExtractionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleExtractionStateCopyWith<SubtitleExtractionState> get copyWith => _$SubtitleExtractionStateCopyWithImpl<SubtitleExtractionState>(this as SubtitleExtractionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubtitleExtractionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleExtractionState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.currentFilePath, _this.currentFilePath) || other.currentFilePath == _this.currentFilePath)&&(identical(other.error, _this.error) || other.error == _this.error)&&const DeepCollectionEquality().equals(other.streams, _this.streams));
}


@override
int get hashCode {
  final _this = this as SubtitleExtractionState;
  return Object.hash(runtimeType,_this.status,_this.currentFilePath,_this.error,const DeepCollectionEquality().hash(_this.streams));
}

@override
String toString() {
  final _this = this as SubtitleExtractionState;
  return 'SubtitleExtractionState(status: ${_this.status}, currentFilePath: ${_this.currentFilePath}, error: ${_this.error}, streams: ${_this.streams})';
}


}

/// @nodoc
abstract mixin class $SubtitleExtractionStateCopyWith<$Res>  {
  factory $SubtitleExtractionStateCopyWith(SubtitleExtractionState value, $Res Function(SubtitleExtractionState) _then) = _$SubtitleExtractionStateCopyWithImpl;
@useResult
$Res call({
 SubtitleExtractionStatus status, String? currentFilePath, String? error, List<SubtitleStreamInfo> streams
});




}
/// @nodoc
class _$SubtitleExtractionStateCopyWithImpl<$Res>
    implements $SubtitleExtractionStateCopyWith<$Res> {
  _$SubtitleExtractionStateCopyWithImpl(this._self, this._then);

  final SubtitleExtractionState _self;
  final $Res Function(SubtitleExtractionState) _then;

/// Create a copy of SubtitleExtractionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? currentFilePath = freezed,Object? error = freezed,Object? streams = null,}) {
  return _then(SubtitleExtractionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubtitleExtractionStatus,currentFilePath: freezed == currentFilePath ? _self.currentFilePath : currentFilePath // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,streams: null == streams ? _self.streams : streams // ignore: cast_nullable_to_non_nullable
as List<SubtitleStreamInfo>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleExtractionState].
extension SubtitleExtractionStatePatterns on SubtitleExtractionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleExtractionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleExtractionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleExtractionState value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleExtractionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleExtractionState value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleExtractionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubtitleExtractionStatus status,  String? currentFilePath,  String? error,  List<SubtitleStreamInfo> streams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleExtractionState() when $default != null:
return $default(_that.status,_that.currentFilePath,_that.error,_that.streams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubtitleExtractionStatus status,  String? currentFilePath,  String? error,  List<SubtitleStreamInfo> streams)  $default,) {final _that = this;
switch (_that) {
case _SubtitleExtractionState():
return $default(_that.status,_that.currentFilePath,_that.error,_that.streams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubtitleExtractionStatus status,  String? currentFilePath,  String? error,  List<SubtitleStreamInfo> streams)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleExtractionState() when $default != null:
return $default(_that.status,_that.currentFilePath,_that.error,_that.streams);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleExtractionState extends SubtitleExtractionState {
  const _SubtitleExtractionState({this.status = SubtitleExtractionStatus.initial, this.currentFilePath, this.error,  List<SubtitleStreamInfo> streams = const []}): _streams = streams,super._();
  

@override@JsonKey() final  SubtitleExtractionStatus status;
@override final  String? currentFilePath;
@override final  String? error;
 final  List<SubtitleStreamInfo> _streams;
@override@JsonKey() List<SubtitleStreamInfo> get streams {
  if (_streams is EqualUnmodifiableListView) return _streams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_streams);
}


/// Create a copy of SubtitleExtractionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleExtractionStateCopyWith<_SubtitleExtractionState> get copyWith => __$SubtitleExtractionStateCopyWithImpl<_SubtitleExtractionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleExtractionState&&(identical(other.status, status) || other.status == status)&&(identical(other.currentFilePath, currentFilePath) || other.currentFilePath == currentFilePath)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.streams, _streams));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,currentFilePath,error,const DeepCollectionEquality().hash(_streams));
}

@override
String toString() {
    return 'SubtitleExtractionState(status: $status, currentFilePath: $currentFilePath, error: $error, streams: $streams)';
}


}

/// @nodoc
abstract mixin class _$SubtitleExtractionStateCopyWith<$Res> implements $SubtitleExtractionStateCopyWith<$Res> {
  factory _$SubtitleExtractionStateCopyWith(_SubtitleExtractionState value, $Res Function(_SubtitleExtractionState) _then) = __$SubtitleExtractionStateCopyWithImpl;
@override @useResult
$Res call({
 SubtitleExtractionStatus status, String? currentFilePath, String? error, List<SubtitleStreamInfo> streams
});




}
/// @nodoc
class __$SubtitleExtractionStateCopyWithImpl<$Res>
    implements _$SubtitleExtractionStateCopyWith<$Res> {
  __$SubtitleExtractionStateCopyWithImpl(this._self, this._then);

  final _SubtitleExtractionState _self;
  final $Res Function(_SubtitleExtractionState) _then;

/// Create a copy of SubtitleExtractionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? currentFilePath = freezed,Object? error = freezed,Object? streams = null,}) {
  return _then(_SubtitleExtractionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubtitleExtractionStatus,currentFilePath: freezed == currentFilePath ? _self.currentFilePath : currentFilePath // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,streams: null == streams ? _self._streams : streams // ignore: cast_nullable_to_non_nullable
as List<SubtitleStreamInfo>,
  ));
}


}

// dart format on
