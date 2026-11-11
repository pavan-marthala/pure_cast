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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InspectSubtitlesEvent value)?  inspectSubtitles,TResult Function( ExtractSingleTrackEvent value)?  extractSingleTrack,TResult Function( ExtractAllTracksEvent value)?  extractAllTracks,TResult Function( CancelExtractionEvent value)?  cancelExtraction,TResult Function( ClearResultsEvent value)?  clearResults,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that);case ExtractSingleTrackEvent() when extractSingleTrack != null:
return extractSingleTrack(_that);case ExtractAllTracksEvent() when extractAllTracks != null:
return extractAllTracks(_that);case CancelExtractionEvent() when cancelExtraction != null:
return cancelExtraction(_that);case ClearResultsEvent() when clearResults != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InspectSubtitlesEvent value)  inspectSubtitles,required TResult Function( ExtractSingleTrackEvent value)  extractSingleTrack,required TResult Function( ExtractAllTracksEvent value)  extractAllTracks,required TResult Function( CancelExtractionEvent value)  cancelExtraction,required TResult Function( ClearResultsEvent value)  clearResults,}){
final _that = this;
switch (_that) {
case InspectSubtitlesEvent():
return inspectSubtitles(_that);case ExtractSingleTrackEvent():
return extractSingleTrack(_that);case ExtractAllTracksEvent():
return extractAllTracks(_that);case CancelExtractionEvent():
return cancelExtraction(_that);case ClearResultsEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InspectSubtitlesEvent value)?  inspectSubtitles,TResult? Function( ExtractSingleTrackEvent value)?  extractSingleTrack,TResult? Function( ExtractAllTracksEvent value)?  extractAllTracks,TResult? Function( CancelExtractionEvent value)?  cancelExtraction,TResult? Function( ClearResultsEvent value)?  clearResults,}){
final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that);case ExtractSingleTrackEvent() when extractSingleTrack != null:
return extractSingleTrack(_that);case ExtractAllTracksEvent() when extractAllTracks != null:
return extractAllTracks(_that);case CancelExtractionEvent() when cancelExtraction != null:
return cancelExtraction(_that);case ClearResultsEvent() when clearResults != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String filePath,  int fileSize,  DateTime lastModified)?  inspectSubtitles,TResult Function( SubtitleStreamInfo stream,  String sourcePath)?  extractSingleTrack,TResult Function( String sourcePath)?  extractAllTracks,TResult Function()?  cancelExtraction,TResult Function()?  clearResults,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that.filePath,_that.fileSize,_that.lastModified);case ExtractSingleTrackEvent() when extractSingleTrack != null:
return extractSingleTrack(_that.stream,_that.sourcePath);case ExtractAllTracksEvent() when extractAllTracks != null:
return extractAllTracks(_that.sourcePath);case CancelExtractionEvent() when cancelExtraction != null:
return cancelExtraction();case ClearResultsEvent() when clearResults != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String filePath,  int fileSize,  DateTime lastModified)  inspectSubtitles,required TResult Function( SubtitleStreamInfo stream,  String sourcePath)  extractSingleTrack,required TResult Function( String sourcePath)  extractAllTracks,required TResult Function()  cancelExtraction,required TResult Function()  clearResults,}) {final _that = this;
switch (_that) {
case InspectSubtitlesEvent():
return inspectSubtitles(_that.filePath,_that.fileSize,_that.lastModified);case ExtractSingleTrackEvent():
return extractSingleTrack(_that.stream,_that.sourcePath);case ExtractAllTracksEvent():
return extractAllTracks(_that.sourcePath);case CancelExtractionEvent():
return cancelExtraction();case ClearResultsEvent():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String filePath,  int fileSize,  DateTime lastModified)?  inspectSubtitles,TResult? Function( SubtitleStreamInfo stream,  String sourcePath)?  extractSingleTrack,TResult? Function( String sourcePath)?  extractAllTracks,TResult? Function()?  cancelExtraction,TResult? Function()?  clearResults,}) {final _that = this;
switch (_that) {
case InspectSubtitlesEvent() when inspectSubtitles != null:
return inspectSubtitles(_that.filePath,_that.fileSize,_that.lastModified);case ExtractSingleTrackEvent() when extractSingleTrack != null:
return extractSingleTrack(_that.stream,_that.sourcePath);case ExtractAllTracksEvent() when extractAllTracks != null:
return extractAllTracks(_that.sourcePath);case CancelExtractionEvent() when cancelExtraction != null:
return cancelExtraction();case ClearResultsEvent() when clearResults != null:
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


class ExtractSingleTrackEvent implements SubtitleExtractionEvent {
  const ExtractSingleTrackEvent({required this.stream, required this.sourcePath});
  

 final  SubtitleStreamInfo stream;
 final  String sourcePath;

/// Create a copy of SubtitleExtractionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractSingleTrackEventCopyWith<ExtractSingleTrackEvent> get copyWith => _$ExtractSingleTrackEventCopyWithImpl<ExtractSingleTrackEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractSingleTrackEvent&&(identical(other.stream, stream) || other.stream == stream)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stream,sourcePath);
}

@override
String toString() {
    return 'SubtitleExtractionEvent.extractSingleTrack(stream: $stream, sourcePath: $sourcePath)';
}


}

/// @nodoc
abstract mixin class $ExtractSingleTrackEventCopyWith<$Res> implements $SubtitleExtractionEventCopyWith<$Res> {
  factory $ExtractSingleTrackEventCopyWith(ExtractSingleTrackEvent value, $Res Function(ExtractSingleTrackEvent) _then) = _$ExtractSingleTrackEventCopyWithImpl;
@useResult
$Res call({
 SubtitleStreamInfo stream, String sourcePath
});




}
/// @nodoc
class _$ExtractSingleTrackEventCopyWithImpl<$Res>
    implements $ExtractSingleTrackEventCopyWith<$Res> {
  _$ExtractSingleTrackEventCopyWithImpl(this._self, this._then);

  final ExtractSingleTrackEvent _self;
  final $Res Function(ExtractSingleTrackEvent) _then;

/// Create a copy of SubtitleExtractionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stream = null,Object? sourcePath = null,}) {
  return _then(ExtractSingleTrackEvent(
stream: null == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as SubtitleStreamInfo,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ExtractAllTracksEvent implements SubtitleExtractionEvent {
  const ExtractAllTracksEvent({required this.sourcePath});
  

 final  String sourcePath;

/// Create a copy of SubtitleExtractionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractAllTracksEventCopyWith<ExtractAllTracksEvent> get copyWith => _$ExtractAllTracksEventCopyWithImpl<ExtractAllTracksEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractAllTracksEvent&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sourcePath);
}

@override
String toString() {
    return 'SubtitleExtractionEvent.extractAllTracks(sourcePath: $sourcePath)';
}


}

/// @nodoc
abstract mixin class $ExtractAllTracksEventCopyWith<$Res> implements $SubtitleExtractionEventCopyWith<$Res> {
  factory $ExtractAllTracksEventCopyWith(ExtractAllTracksEvent value, $Res Function(ExtractAllTracksEvent) _then) = _$ExtractAllTracksEventCopyWithImpl;
@useResult
$Res call({
 String sourcePath
});




}
/// @nodoc
class _$ExtractAllTracksEventCopyWithImpl<$Res>
    implements $ExtractAllTracksEventCopyWith<$Res> {
  _$ExtractAllTracksEventCopyWithImpl(this._self, this._then);

  final ExtractAllTracksEvent _self;
  final $Res Function(ExtractAllTracksEvent) _then;

/// Create a copy of SubtitleExtractionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sourcePath = null,}) {
  return _then(ExtractAllTracksEvent(
sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CancelExtractionEvent implements SubtitleExtractionEvent {
  const CancelExtractionEvent();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CancelExtractionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SubtitleExtractionEvent.cancelExtraction()';
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

 SubtitleExtractionStatus get status; String? get currentFilePath; String? get error; List<SubtitleStreamInfo> get streams; SubtitleExtractionResult? get lastResult; List<SubtitleExtractionResult> get extractionResults;
/// Create a copy of SubtitleExtractionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleExtractionStateCopyWith<SubtitleExtractionState> get copyWith => _$SubtitleExtractionStateCopyWithImpl<SubtitleExtractionState>(this as SubtitleExtractionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubtitleExtractionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleExtractionState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.currentFilePath, _this.currentFilePath) || other.currentFilePath == _this.currentFilePath)&&(identical(other.error, _this.error) || other.error == _this.error)&&const DeepCollectionEquality().equals(other.streams, _this.streams)&&(identical(other.lastResult, _this.lastResult) || other.lastResult == _this.lastResult)&&const DeepCollectionEquality().equals(other.extractionResults, _this.extractionResults));
}


@override
int get hashCode {
  final _this = this as SubtitleExtractionState;
  return Object.hash(runtimeType,_this.status,_this.currentFilePath,_this.error,const DeepCollectionEquality().hash(_this.streams),_this.lastResult,const DeepCollectionEquality().hash(_this.extractionResults));
}

@override
String toString() {
  final _this = this as SubtitleExtractionState;
  return 'SubtitleExtractionState(status: ${_this.status}, currentFilePath: ${_this.currentFilePath}, error: ${_this.error}, streams: ${_this.streams}, lastResult: ${_this.lastResult}, extractionResults: ${_this.extractionResults})';
}


}

/// @nodoc
abstract mixin class $SubtitleExtractionStateCopyWith<$Res>  {
  factory $SubtitleExtractionStateCopyWith(SubtitleExtractionState value, $Res Function(SubtitleExtractionState) _then) = _$SubtitleExtractionStateCopyWithImpl;
@useResult
$Res call({
 SubtitleExtractionStatus status, String? currentFilePath, String? error, List<SubtitleStreamInfo> streams, SubtitleExtractionResult? lastResult, List<SubtitleExtractionResult> extractionResults
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
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? currentFilePath = freezed,Object? error = freezed,Object? streams = null,Object? lastResult = freezed,Object? extractionResults = null,}) {
  return _then(SubtitleExtractionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubtitleExtractionStatus,currentFilePath: freezed == currentFilePath ? _self.currentFilePath : currentFilePath // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,streams: null == streams ? _self.streams : streams // ignore: cast_nullable_to_non_nullable
as List<SubtitleStreamInfo>,lastResult: freezed == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as SubtitleExtractionResult?,extractionResults: null == extractionResults ? _self.extractionResults : extractionResults // ignore: cast_nullable_to_non_nullable
as List<SubtitleExtractionResult>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubtitleExtractionStatus status,  String? currentFilePath,  String? error,  List<SubtitleStreamInfo> streams,  SubtitleExtractionResult? lastResult,  List<SubtitleExtractionResult> extractionResults)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleExtractionState() when $default != null:
return $default(_that.status,_that.currentFilePath,_that.error,_that.streams,_that.lastResult,_that.extractionResults);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubtitleExtractionStatus status,  String? currentFilePath,  String? error,  List<SubtitleStreamInfo> streams,  SubtitleExtractionResult? lastResult,  List<SubtitleExtractionResult> extractionResults)  $default,) {final _that = this;
switch (_that) {
case _SubtitleExtractionState():
return $default(_that.status,_that.currentFilePath,_that.error,_that.streams,_that.lastResult,_that.extractionResults);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubtitleExtractionStatus status,  String? currentFilePath,  String? error,  List<SubtitleStreamInfo> streams,  SubtitleExtractionResult? lastResult,  List<SubtitleExtractionResult> extractionResults)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleExtractionState() when $default != null:
return $default(_that.status,_that.currentFilePath,_that.error,_that.streams,_that.lastResult,_that.extractionResults);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleExtractionState extends SubtitleExtractionState {
  const _SubtitleExtractionState({this.status = SubtitleExtractionStatus.initial, this.currentFilePath, this.error,  List<SubtitleStreamInfo> streams = const [], this.lastResult,  List<SubtitleExtractionResult> extractionResults = const []}): _streams = streams,_extractionResults = extractionResults,super._();
  

@override@JsonKey() final  SubtitleExtractionStatus status;
@override final  String? currentFilePath;
@override final  String? error;
 final  List<SubtitleStreamInfo> _streams;
@override@JsonKey() List<SubtitleStreamInfo> get streams {
  if (_streams is EqualUnmodifiableListView) return _streams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_streams);
}

@override final  SubtitleExtractionResult? lastResult;
 final  List<SubtitleExtractionResult> _extractionResults;
@override@JsonKey() List<SubtitleExtractionResult> get extractionResults {
  if (_extractionResults is EqualUnmodifiableListView) return _extractionResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extractionResults);
}


/// Create a copy of SubtitleExtractionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleExtractionStateCopyWith<_SubtitleExtractionState> get copyWith => __$SubtitleExtractionStateCopyWithImpl<_SubtitleExtractionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleExtractionState&&(identical(other.status, status) || other.status == status)&&(identical(other.currentFilePath, currentFilePath) || other.currentFilePath == currentFilePath)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.streams, _streams)&&(identical(other.lastResult, lastResult) || other.lastResult == lastResult)&&const DeepCollectionEquality().equals(other.extractionResults, _extractionResults));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,currentFilePath,error,const DeepCollectionEquality().hash(_streams),lastResult,const DeepCollectionEquality().hash(_extractionResults));
}

@override
String toString() {
    return 'SubtitleExtractionState(status: $status, currentFilePath: $currentFilePath, error: $error, streams: $streams, lastResult: $lastResult, extractionResults: $extractionResults)';
}


}

/// @nodoc
abstract mixin class _$SubtitleExtractionStateCopyWith<$Res> implements $SubtitleExtractionStateCopyWith<$Res> {
  factory _$SubtitleExtractionStateCopyWith(_SubtitleExtractionState value, $Res Function(_SubtitleExtractionState) _then) = __$SubtitleExtractionStateCopyWithImpl;
@override @useResult
$Res call({
 SubtitleExtractionStatus status, String? currentFilePath, String? error, List<SubtitleStreamInfo> streams, SubtitleExtractionResult? lastResult, List<SubtitleExtractionResult> extractionResults
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
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? currentFilePath = freezed,Object? error = freezed,Object? streams = null,Object? lastResult = freezed,Object? extractionResults = null,}) {
  return _then(_SubtitleExtractionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubtitleExtractionStatus,currentFilePath: freezed == currentFilePath ? _self.currentFilePath : currentFilePath // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,streams: null == streams ? _self._streams : streams // ignore: cast_nullable_to_non_nullable
as List<SubtitleStreamInfo>,lastResult: freezed == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as SubtitleExtractionResult?,extractionResults: null == extractionResults ? _self._extractionResults : extractionResults // ignore: cast_nullable_to_non_nullable
as List<SubtitleExtractionResult>,
  ));
}


}

// dart format on
