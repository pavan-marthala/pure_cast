// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cast_session_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CastSessionEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CastSessionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent()';
}


}

/// @nodoc
class $CastSessionEventCopyWith<$Res>  {
$CastSessionEventCopyWith(CastSessionEvent _, $Res Function(CastSessionEvent) __);
}


/// Adds pattern-matching-related methods to [CastSessionEvent].
extension CastSessionEventPatterns on CastSessionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConnectDeviceEvent value)?  connectDevice,TResult Function( DisconnectDeviceEvent value)?  disconnectDevice,TResult Function( LoadMediaEvent value)?  loadMedia,TResult Function( PlayMediaEvent value)?  playMedia,TResult Function( PauseMediaEvent value)?  pauseMedia,TResult Function( StopMediaEvent value)?  stopMedia,TResult Function( SeekMediaEvent value)?  seekMedia,TResult Function( SeekRelativeEvent value)?  seekRelative,TResult Function( CommitSeekPreviewEvent value)?  commitSeekPreview,TResult Function( SelectAudioEvent value)?  selectAudio,TResult Function( SetVolumeEvent value)?  setVolume,TResult Function( SetSubtitleEvent value)?  setSubtitle,TResult Function( ExtractAndSetSubtitleEvent value)?  extractAndSetSubtitle,TResult Function( SessionStateChangedEvent value)?  sessionStateChanged,TResult Function( PositionUpdatedEvent value)?  positionUpdated,TResult Function( DurationUpdatedEvent value)?  durationUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice(_that);case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that);case PlayMediaEvent() when playMedia != null:
return playMedia(_that);case PauseMediaEvent() when pauseMedia != null:
return pauseMedia(_that);case StopMediaEvent() when stopMedia != null:
return stopMedia(_that);case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that);case SeekRelativeEvent() when seekRelative != null:
return seekRelative(_that);case CommitSeekPreviewEvent() when commitSeekPreview != null:
return commitSeekPreview(_that);case SelectAudioEvent() when selectAudio != null:
return selectAudio(_that);case SetVolumeEvent() when setVolume != null:
return setVolume(_that);case SetSubtitleEvent() when setSubtitle != null:
return setSubtitle(_that);case ExtractAndSetSubtitleEvent() when extractAndSetSubtitle != null:
return extractAndSetSubtitle(_that);case SessionStateChangedEvent() when sessionStateChanged != null:
return sessionStateChanged(_that);case PositionUpdatedEvent() when positionUpdated != null:
return positionUpdated(_that);case DurationUpdatedEvent() when durationUpdated != null:
return durationUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConnectDeviceEvent value)  connectDevice,required TResult Function( DisconnectDeviceEvent value)  disconnectDevice,required TResult Function( LoadMediaEvent value)  loadMedia,required TResult Function( PlayMediaEvent value)  playMedia,required TResult Function( PauseMediaEvent value)  pauseMedia,required TResult Function( StopMediaEvent value)  stopMedia,required TResult Function( SeekMediaEvent value)  seekMedia,required TResult Function( SeekRelativeEvent value)  seekRelative,required TResult Function( CommitSeekPreviewEvent value)  commitSeekPreview,required TResult Function( SelectAudioEvent value)  selectAudio,required TResult Function( SetVolumeEvent value)  setVolume,required TResult Function( SetSubtitleEvent value)  setSubtitle,required TResult Function( ExtractAndSetSubtitleEvent value)  extractAndSetSubtitle,required TResult Function( SessionStateChangedEvent value)  sessionStateChanged,required TResult Function( PositionUpdatedEvent value)  positionUpdated,required TResult Function( DurationUpdatedEvent value)  durationUpdated,}){
final _that = this;
switch (_that) {
case ConnectDeviceEvent():
return connectDevice(_that);case DisconnectDeviceEvent():
return disconnectDevice(_that);case LoadMediaEvent():
return loadMedia(_that);case PlayMediaEvent():
return playMedia(_that);case PauseMediaEvent():
return pauseMedia(_that);case StopMediaEvent():
return stopMedia(_that);case SeekMediaEvent():
return seekMedia(_that);case SeekRelativeEvent():
return seekRelative(_that);case CommitSeekPreviewEvent():
return commitSeekPreview(_that);case SelectAudioEvent():
return selectAudio(_that);case SetVolumeEvent():
return setVolume(_that);case SetSubtitleEvent():
return setSubtitle(_that);case ExtractAndSetSubtitleEvent():
return extractAndSetSubtitle(_that);case SessionStateChangedEvent():
return sessionStateChanged(_that);case PositionUpdatedEvent():
return positionUpdated(_that);case DurationUpdatedEvent():
return durationUpdated(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConnectDeviceEvent value)?  connectDevice,TResult? Function( DisconnectDeviceEvent value)?  disconnectDevice,TResult? Function( LoadMediaEvent value)?  loadMedia,TResult? Function( PlayMediaEvent value)?  playMedia,TResult? Function( PauseMediaEvent value)?  pauseMedia,TResult? Function( StopMediaEvent value)?  stopMedia,TResult? Function( SeekMediaEvent value)?  seekMedia,TResult? Function( SeekRelativeEvent value)?  seekRelative,TResult? Function( CommitSeekPreviewEvent value)?  commitSeekPreview,TResult? Function( SelectAudioEvent value)?  selectAudio,TResult? Function( SetVolumeEvent value)?  setVolume,TResult? Function( SetSubtitleEvent value)?  setSubtitle,TResult? Function( ExtractAndSetSubtitleEvent value)?  extractAndSetSubtitle,TResult? Function( SessionStateChangedEvent value)?  sessionStateChanged,TResult? Function( PositionUpdatedEvent value)?  positionUpdated,TResult? Function( DurationUpdatedEvent value)?  durationUpdated,}){
final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice(_that);case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that);case PlayMediaEvent() when playMedia != null:
return playMedia(_that);case PauseMediaEvent() when pauseMedia != null:
return pauseMedia(_that);case StopMediaEvent() when stopMedia != null:
return stopMedia(_that);case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that);case SeekRelativeEvent() when seekRelative != null:
return seekRelative(_that);case CommitSeekPreviewEvent() when commitSeekPreview != null:
return commitSeekPreview(_that);case SelectAudioEvent() when selectAudio != null:
return selectAudio(_that);case SetVolumeEvent() when setVolume != null:
return setVolume(_that);case SetSubtitleEvent() when setSubtitle != null:
return setSubtitle(_that);case ExtractAndSetSubtitleEvent() when extractAndSetSubtitle != null:
return extractAndSetSubtitle(_that);case SessionStateChangedEvent() when sessionStateChanged != null:
return sessionStateChanged(_that);case PositionUpdatedEvent() when positionUpdated != null:
return positionUpdated(_that);case DurationUpdatedEvent() when durationUpdated != null:
return durationUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PureCastDevice device)?  connectDevice,TResult Function()?  disconnectDevice,TResult Function( PureCastMedia media)?  loadMedia,TResult Function()?  playMedia,TResult Function()?  pauseMedia,TResult Function()?  stopMedia,TResult Function( Duration position)?  seekMedia,TResult Function( Duration delta)?  seekRelative,TResult Function()?  commitSeekPreview,TResult Function( int index)?  selectAudio,TResult Function( double volume)?  setVolume,TResult Function( PureCastSubtitleTrack? subtitle)?  setSubtitle,TResult Function( PureCastSubtitleTrack subtitle)?  extractAndSetSubtitle,TResult Function( PureCastSessionState newState)?  sessionStateChanged,TResult Function( Duration position)?  positionUpdated,TResult Function( Duration duration)?  durationUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that.device);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice();case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that.media);case PlayMediaEvent() when playMedia != null:
return playMedia();case PauseMediaEvent() when pauseMedia != null:
return pauseMedia();case StopMediaEvent() when stopMedia != null:
return stopMedia();case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that.position);case SeekRelativeEvent() when seekRelative != null:
return seekRelative(_that.delta);case CommitSeekPreviewEvent() when commitSeekPreview != null:
return commitSeekPreview();case SelectAudioEvent() when selectAudio != null:
return selectAudio(_that.index);case SetVolumeEvent() when setVolume != null:
return setVolume(_that.volume);case SetSubtitleEvent() when setSubtitle != null:
return setSubtitle(_that.subtitle);case ExtractAndSetSubtitleEvent() when extractAndSetSubtitle != null:
return extractAndSetSubtitle(_that.subtitle);case SessionStateChangedEvent() when sessionStateChanged != null:
return sessionStateChanged(_that.newState);case PositionUpdatedEvent() when positionUpdated != null:
return positionUpdated(_that.position);case DurationUpdatedEvent() when durationUpdated != null:
return durationUpdated(_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PureCastDevice device)  connectDevice,required TResult Function()  disconnectDevice,required TResult Function( PureCastMedia media)  loadMedia,required TResult Function()  playMedia,required TResult Function()  pauseMedia,required TResult Function()  stopMedia,required TResult Function( Duration position)  seekMedia,required TResult Function( Duration delta)  seekRelative,required TResult Function()  commitSeekPreview,required TResult Function( int index)  selectAudio,required TResult Function( double volume)  setVolume,required TResult Function( PureCastSubtitleTrack? subtitle)  setSubtitle,required TResult Function( PureCastSubtitleTrack subtitle)  extractAndSetSubtitle,required TResult Function( PureCastSessionState newState)  sessionStateChanged,required TResult Function( Duration position)  positionUpdated,required TResult Function( Duration duration)  durationUpdated,}) {final _that = this;
switch (_that) {
case ConnectDeviceEvent():
return connectDevice(_that.device);case DisconnectDeviceEvent():
return disconnectDevice();case LoadMediaEvent():
return loadMedia(_that.media);case PlayMediaEvent():
return playMedia();case PauseMediaEvent():
return pauseMedia();case StopMediaEvent():
return stopMedia();case SeekMediaEvent():
return seekMedia(_that.position);case SeekRelativeEvent():
return seekRelative(_that.delta);case CommitSeekPreviewEvent():
return commitSeekPreview();case SelectAudioEvent():
return selectAudio(_that.index);case SetVolumeEvent():
return setVolume(_that.volume);case SetSubtitleEvent():
return setSubtitle(_that.subtitle);case ExtractAndSetSubtitleEvent():
return extractAndSetSubtitle(_that.subtitle);case SessionStateChangedEvent():
return sessionStateChanged(_that.newState);case PositionUpdatedEvent():
return positionUpdated(_that.position);case DurationUpdatedEvent():
return durationUpdated(_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PureCastDevice device)?  connectDevice,TResult? Function()?  disconnectDevice,TResult? Function( PureCastMedia media)?  loadMedia,TResult? Function()?  playMedia,TResult? Function()?  pauseMedia,TResult? Function()?  stopMedia,TResult? Function( Duration position)?  seekMedia,TResult? Function( Duration delta)?  seekRelative,TResult? Function()?  commitSeekPreview,TResult? Function( int index)?  selectAudio,TResult? Function( double volume)?  setVolume,TResult? Function( PureCastSubtitleTrack? subtitle)?  setSubtitle,TResult? Function( PureCastSubtitleTrack subtitle)?  extractAndSetSubtitle,TResult? Function( PureCastSessionState newState)?  sessionStateChanged,TResult? Function( Duration position)?  positionUpdated,TResult? Function( Duration duration)?  durationUpdated,}) {final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that.device);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice();case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that.media);case PlayMediaEvent() when playMedia != null:
return playMedia();case PauseMediaEvent() when pauseMedia != null:
return pauseMedia();case StopMediaEvent() when stopMedia != null:
return stopMedia();case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that.position);case SeekRelativeEvent() when seekRelative != null:
return seekRelative(_that.delta);case CommitSeekPreviewEvent() when commitSeekPreview != null:
return commitSeekPreview();case SelectAudioEvent() when selectAudio != null:
return selectAudio(_that.index);case SetVolumeEvent() when setVolume != null:
return setVolume(_that.volume);case SetSubtitleEvent() when setSubtitle != null:
return setSubtitle(_that.subtitle);case ExtractAndSetSubtitleEvent() when extractAndSetSubtitle != null:
return extractAndSetSubtitle(_that.subtitle);case SessionStateChangedEvent() when sessionStateChanged != null:
return sessionStateChanged(_that.newState);case PositionUpdatedEvent() when positionUpdated != null:
return positionUpdated(_that.position);case DurationUpdatedEvent() when durationUpdated != null:
return durationUpdated(_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class ConnectDeviceEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const ConnectDeviceEvent(this.device);
  

 final  PureCastDevice device;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectDeviceEventCopyWith<ConnectDeviceEvent> get copyWith => _$ConnectDeviceEventCopyWithImpl<ConnectDeviceEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.connectDevice'))
    ..add(DiagnosticsProperty('device', device));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectDeviceEvent&&(identical(other.device, device) || other.device == device));
}


@override
int get hashCode {
    return Object.hash(runtimeType,device);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.connectDevice(device: $device)';
}


}

/// @nodoc
abstract mixin class $ConnectDeviceEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $ConnectDeviceEventCopyWith(ConnectDeviceEvent value, $Res Function(ConnectDeviceEvent) _then) = _$ConnectDeviceEventCopyWithImpl;
@useResult
$Res call({
 PureCastDevice device
});




}
/// @nodoc
class _$ConnectDeviceEventCopyWithImpl<$Res>
    implements $ConnectDeviceEventCopyWith<$Res> {
  _$ConnectDeviceEventCopyWithImpl(this._self, this._then);

  final ConnectDeviceEvent _self;
  final $Res Function(ConnectDeviceEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? device = null,}) {
  return _then(ConnectDeviceEvent(
null == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as PureCastDevice,
  ));
}


}

/// @nodoc


class DisconnectDeviceEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const DisconnectDeviceEvent();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.disconnectDevice'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DisconnectDeviceEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.disconnectDevice()';
}


}




/// @nodoc


class LoadMediaEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const LoadMediaEvent(this.media);
  

 final  PureCastMedia media;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadMediaEventCopyWith<LoadMediaEvent> get copyWith => _$LoadMediaEventCopyWithImpl<LoadMediaEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.loadMedia'))
    ..add(DiagnosticsProperty('media', media));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadMediaEvent&&(identical(other.media, media) || other.media == media));
}


@override
int get hashCode {
    return Object.hash(runtimeType,media);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.loadMedia(media: $media)';
}


}

/// @nodoc
abstract mixin class $LoadMediaEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $LoadMediaEventCopyWith(LoadMediaEvent value, $Res Function(LoadMediaEvent) _then) = _$LoadMediaEventCopyWithImpl;
@useResult
$Res call({
 PureCastMedia media
});




}
/// @nodoc
class _$LoadMediaEventCopyWithImpl<$Res>
    implements $LoadMediaEventCopyWith<$Res> {
  _$LoadMediaEventCopyWithImpl(this._self, this._then);

  final LoadMediaEvent _self;
  final $Res Function(LoadMediaEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? media = null,}) {
  return _then(LoadMediaEvent(
null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as PureCastMedia,
  ));
}


}

/// @nodoc


class PlayMediaEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const PlayMediaEvent();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.playMedia'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.playMedia()';
}


}




/// @nodoc


class PauseMediaEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const PauseMediaEvent();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.pauseMedia'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.pauseMedia()';
}


}




/// @nodoc


class StopMediaEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const StopMediaEvent();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.stopMedia'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StopMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.stopMedia()';
}


}




/// @nodoc


class SeekMediaEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const SeekMediaEvent(this.position);
  

 final  Duration position;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeekMediaEventCopyWith<SeekMediaEvent> get copyWith => _$SeekMediaEventCopyWithImpl<SeekMediaEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.seekMedia'))
    ..add(DiagnosticsProperty('position', position));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SeekMediaEvent&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode {
    return Object.hash(runtimeType,position);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.seekMedia(position: $position)';
}


}

/// @nodoc
abstract mixin class $SeekMediaEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $SeekMediaEventCopyWith(SeekMediaEvent value, $Res Function(SeekMediaEvent) _then) = _$SeekMediaEventCopyWithImpl;
@useResult
$Res call({
 Duration position
});




}
/// @nodoc
class _$SeekMediaEventCopyWithImpl<$Res>
    implements $SeekMediaEventCopyWith<$Res> {
  _$SeekMediaEventCopyWithImpl(this._self, this._then);

  final SeekMediaEvent _self;
  final $Res Function(SeekMediaEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? position = null,}) {
  return _then(SeekMediaEvent(
null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class SeekRelativeEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const SeekRelativeEvent(this.delta);
  

 final  Duration delta;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeekRelativeEventCopyWith<SeekRelativeEvent> get copyWith => _$SeekRelativeEventCopyWithImpl<SeekRelativeEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.seekRelative'))
    ..add(DiagnosticsProperty('delta', delta));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SeekRelativeEvent&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode {
    return Object.hash(runtimeType,delta);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.seekRelative(delta: $delta)';
}


}

/// @nodoc
abstract mixin class $SeekRelativeEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $SeekRelativeEventCopyWith(SeekRelativeEvent value, $Res Function(SeekRelativeEvent) _then) = _$SeekRelativeEventCopyWithImpl;
@useResult
$Res call({
 Duration delta
});




}
/// @nodoc
class _$SeekRelativeEventCopyWithImpl<$Res>
    implements $SeekRelativeEventCopyWith<$Res> {
  _$SeekRelativeEventCopyWithImpl(this._self, this._then);

  final SeekRelativeEvent _self;
  final $Res Function(SeekRelativeEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? delta = null,}) {
  return _then(SeekRelativeEvent(
null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class CommitSeekPreviewEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const CommitSeekPreviewEvent();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.commitSeekPreview'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitSeekPreviewEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.commitSeekPreview()';
}


}




/// @nodoc


class SelectAudioEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const SelectAudioEvent(this.index);
  

 final  int index;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectAudioEventCopyWith<SelectAudioEvent> get copyWith => _$SelectAudioEventCopyWithImpl<SelectAudioEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.selectAudio'))
    ..add(DiagnosticsProperty('index', index));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectAudioEvent&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode {
    return Object.hash(runtimeType,index);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.selectAudio(index: $index)';
}


}

/// @nodoc
abstract mixin class $SelectAudioEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $SelectAudioEventCopyWith(SelectAudioEvent value, $Res Function(SelectAudioEvent) _then) = _$SelectAudioEventCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class _$SelectAudioEventCopyWithImpl<$Res>
    implements $SelectAudioEventCopyWith<$Res> {
  _$SelectAudioEventCopyWithImpl(this._self, this._then);

  final SelectAudioEvent _self;
  final $Res Function(SelectAudioEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(SelectAudioEvent(
null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SetVolumeEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const SetVolumeEvent(this.volume);
  

 final  double volume;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetVolumeEventCopyWith<SetVolumeEvent> get copyWith => _$SetVolumeEventCopyWithImpl<SetVolumeEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.setVolume'))
    ..add(DiagnosticsProperty('volume', volume));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetVolumeEvent&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode {
    return Object.hash(runtimeType,volume);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.setVolume(volume: $volume)';
}


}

/// @nodoc
abstract mixin class $SetVolumeEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $SetVolumeEventCopyWith(SetVolumeEvent value, $Res Function(SetVolumeEvent) _then) = _$SetVolumeEventCopyWithImpl;
@useResult
$Res call({
 double volume
});




}
/// @nodoc
class _$SetVolumeEventCopyWithImpl<$Res>
    implements $SetVolumeEventCopyWith<$Res> {
  _$SetVolumeEventCopyWithImpl(this._self, this._then);

  final SetVolumeEvent _self;
  final $Res Function(SetVolumeEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? volume = null,}) {
  return _then(SetVolumeEvent(
null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class SetSubtitleEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const SetSubtitleEvent(this.subtitle);
  

 final  PureCastSubtitleTrack? subtitle;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetSubtitleEventCopyWith<SetSubtitleEvent> get copyWith => _$SetSubtitleEventCopyWithImpl<SetSubtitleEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.setSubtitle'))
    ..add(DiagnosticsProperty('subtitle', subtitle));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetSubtitleEvent&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle));
}


@override
int get hashCode {
    return Object.hash(runtimeType,subtitle);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.setSubtitle(subtitle: $subtitle)';
}


}

/// @nodoc
abstract mixin class $SetSubtitleEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $SetSubtitleEventCopyWith(SetSubtitleEvent value, $Res Function(SetSubtitleEvent) _then) = _$SetSubtitleEventCopyWithImpl;
@useResult
$Res call({
 PureCastSubtitleTrack? subtitle
});




}
/// @nodoc
class _$SetSubtitleEventCopyWithImpl<$Res>
    implements $SetSubtitleEventCopyWith<$Res> {
  _$SetSubtitleEventCopyWithImpl(this._self, this._then);

  final SetSubtitleEvent _self;
  final $Res Function(SetSubtitleEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? subtitle = freezed,}) {
  return _then(SetSubtitleEvent(
freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as PureCastSubtitleTrack?,
  ));
}


}

/// @nodoc


class ExtractAndSetSubtitleEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const ExtractAndSetSubtitleEvent(this.subtitle);
  

 final  PureCastSubtitleTrack subtitle;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractAndSetSubtitleEventCopyWith<ExtractAndSetSubtitleEvent> get copyWith => _$ExtractAndSetSubtitleEventCopyWithImpl<ExtractAndSetSubtitleEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.extractAndSetSubtitle'))
    ..add(DiagnosticsProperty('subtitle', subtitle));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractAndSetSubtitleEvent&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle));
}


@override
int get hashCode {
    return Object.hash(runtimeType,subtitle);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.extractAndSetSubtitle(subtitle: $subtitle)';
}


}

/// @nodoc
abstract mixin class $ExtractAndSetSubtitleEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $ExtractAndSetSubtitleEventCopyWith(ExtractAndSetSubtitleEvent value, $Res Function(ExtractAndSetSubtitleEvent) _then) = _$ExtractAndSetSubtitleEventCopyWithImpl;
@useResult
$Res call({
 PureCastSubtitleTrack subtitle
});




}
/// @nodoc
class _$ExtractAndSetSubtitleEventCopyWithImpl<$Res>
    implements $ExtractAndSetSubtitleEventCopyWith<$Res> {
  _$ExtractAndSetSubtitleEventCopyWithImpl(this._self, this._then);

  final ExtractAndSetSubtitleEvent _self;
  final $Res Function(ExtractAndSetSubtitleEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? subtitle = null,}) {
  return _then(ExtractAndSetSubtitleEvent(
null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as PureCastSubtitleTrack,
  ));
}


}

/// @nodoc


class SessionStateChangedEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const SessionStateChangedEvent(this.newState);
  

 final  PureCastSessionState newState;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateChangedEventCopyWith<SessionStateChangedEvent> get copyWith => _$SessionStateChangedEventCopyWithImpl<SessionStateChangedEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.sessionStateChanged'))
    ..add(DiagnosticsProperty('newState', newState));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionStateChangedEvent&&(identical(other.newState, newState) || other.newState == newState));
}


@override
int get hashCode {
    return Object.hash(runtimeType,newState);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.sessionStateChanged(newState: $newState)';
}


}

/// @nodoc
abstract mixin class $SessionStateChangedEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $SessionStateChangedEventCopyWith(SessionStateChangedEvent value, $Res Function(SessionStateChangedEvent) _then) = _$SessionStateChangedEventCopyWithImpl;
@useResult
$Res call({
 PureCastSessionState newState
});




}
/// @nodoc
class _$SessionStateChangedEventCopyWithImpl<$Res>
    implements $SessionStateChangedEventCopyWith<$Res> {
  _$SessionStateChangedEventCopyWithImpl(this._self, this._then);

  final SessionStateChangedEvent _self;
  final $Res Function(SessionStateChangedEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? newState = null,}) {
  return _then(SessionStateChangedEvent(
null == newState ? _self.newState : newState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,
  ));
}


}

/// @nodoc


class PositionUpdatedEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const PositionUpdatedEvent(this.position);
  

 final  Duration position;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionUpdatedEventCopyWith<PositionUpdatedEvent> get copyWith => _$PositionUpdatedEventCopyWithImpl<PositionUpdatedEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.positionUpdated'))
    ..add(DiagnosticsProperty('position', position));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionUpdatedEvent&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode {
    return Object.hash(runtimeType,position);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.positionUpdated(position: $position)';
}


}

/// @nodoc
abstract mixin class $PositionUpdatedEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $PositionUpdatedEventCopyWith(PositionUpdatedEvent value, $Res Function(PositionUpdatedEvent) _then) = _$PositionUpdatedEventCopyWithImpl;
@useResult
$Res call({
 Duration position
});




}
/// @nodoc
class _$PositionUpdatedEventCopyWithImpl<$Res>
    implements $PositionUpdatedEventCopyWith<$Res> {
  _$PositionUpdatedEventCopyWithImpl(this._self, this._then);

  final PositionUpdatedEvent _self;
  final $Res Function(PositionUpdatedEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? position = null,}) {
  return _then(PositionUpdatedEvent(
null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class DurationUpdatedEvent with DiagnosticableTreeMixin implements CastSessionEvent {
  const DurationUpdatedEvent(this.duration);
  

 final  Duration duration;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DurationUpdatedEventCopyWith<DurationUpdatedEvent> get copyWith => _$DurationUpdatedEventCopyWithImpl<DurationUpdatedEvent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionEvent.durationUpdated'))
    ..add(DiagnosticsProperty('duration', duration));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DurationUpdatedEvent&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode {
    return Object.hash(runtimeType,duration);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionEvent.durationUpdated(duration: $duration)';
}


}

/// @nodoc
abstract mixin class $DurationUpdatedEventCopyWith<$Res> implements $CastSessionEventCopyWith<$Res> {
  factory $DurationUpdatedEventCopyWith(DurationUpdatedEvent value, $Res Function(DurationUpdatedEvent) _then) = _$DurationUpdatedEventCopyWithImpl;
@useResult
$Res call({
 Duration duration
});




}
/// @nodoc
class _$DurationUpdatedEventCopyWithImpl<$Res>
    implements $DurationUpdatedEventCopyWith<$Res> {
  _$DurationUpdatedEventCopyWithImpl(this._self, this._then);

  final DurationUpdatedEvent _self;
  final $Res Function(DurationUpdatedEvent) _then;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? duration = null,}) {
  return _then(DurationUpdatedEvent(
null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$CastSessionState implements DiagnosticableTreeMixin {

 PureCastSessionState get sessionState; PureCastDevice? get activeDevice; PureCastMedia? get activeMedia; PureCastSubtitleTrack? get activeSubtitle; StateStatus get connectionStatus; String? get connectionError; StateStatus get playbackStatus; String? get playbackError; Duration get position; bool get preparing; bool get preparingSubtitles; String? get castPlan; String? get castPlanReason; String? get prepareError; String? get prepareSubtitlesError; Duration get duration; double get volume; List<PureCastAudioTrack> get audioTracks; int? get activeAudioIndex; bool get isLive; bool get restarting;/// Accumulated target of pending relative-seek taps, shown by the seek bar
/// and the time labels until the debounced seek is committed.
 Duration? get seekPreview;
/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CastSessionStateCopyWith<CastSessionState> get copyWith => _$CastSessionStateCopyWithImpl<CastSessionState>(this as CastSessionState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as CastSessionState;
  properties
    ..add(DiagnosticsProperty('type', 'CastSessionState'))
    ..add(DiagnosticsProperty('sessionState', _this.sessionState))..add(DiagnosticsProperty('activeDevice', _this.activeDevice))..add(DiagnosticsProperty('activeMedia', _this.activeMedia))..add(DiagnosticsProperty('activeSubtitle', _this.activeSubtitle))..add(DiagnosticsProperty('connectionStatus', _this.connectionStatus))..add(DiagnosticsProperty('connectionError', _this.connectionError))..add(DiagnosticsProperty('playbackStatus', _this.playbackStatus))..add(DiagnosticsProperty('playbackError', _this.playbackError))..add(DiagnosticsProperty('position', _this.position))..add(DiagnosticsProperty('preparing', _this.preparing))..add(DiagnosticsProperty('preparingSubtitles', _this.preparingSubtitles))..add(DiagnosticsProperty('castPlan', _this.castPlan))..add(DiagnosticsProperty('castPlanReason', _this.castPlanReason))..add(DiagnosticsProperty('prepareError', _this.prepareError))..add(DiagnosticsProperty('prepareSubtitlesError', _this.prepareSubtitlesError))..add(DiagnosticsProperty('duration', _this.duration))..add(DiagnosticsProperty('volume', _this.volume))..add(DiagnosticsProperty('audioTracks', _this.audioTracks))..add(DiagnosticsProperty('activeAudioIndex', _this.activeAudioIndex))..add(DiagnosticsProperty('isLive', _this.isLive))..add(DiagnosticsProperty('restarting', _this.restarting))..add(DiagnosticsProperty('seekPreview', _this.seekPreview));
}

@override
bool operator ==(Object other) {
  final _this = this as CastSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastSessionState&&(identical(other.sessionState, _this.sessionState) || other.sessionState == _this.sessionState)&&(identical(other.activeDevice, _this.activeDevice) || other.activeDevice == _this.activeDevice)&&(identical(other.activeMedia, _this.activeMedia) || other.activeMedia == _this.activeMedia)&&(identical(other.activeSubtitle, _this.activeSubtitle) || other.activeSubtitle == _this.activeSubtitle)&&(identical(other.connectionStatus, _this.connectionStatus) || other.connectionStatus == _this.connectionStatus)&&(identical(other.connectionError, _this.connectionError) || other.connectionError == _this.connectionError)&&(identical(other.playbackStatus, _this.playbackStatus) || other.playbackStatus == _this.playbackStatus)&&(identical(other.playbackError, _this.playbackError) || other.playbackError == _this.playbackError)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.preparing, _this.preparing) || other.preparing == _this.preparing)&&(identical(other.preparingSubtitles, _this.preparingSubtitles) || other.preparingSubtitles == _this.preparingSubtitles)&&(identical(other.castPlan, _this.castPlan) || other.castPlan == _this.castPlan)&&(identical(other.castPlanReason, _this.castPlanReason) || other.castPlanReason == _this.castPlanReason)&&(identical(other.prepareError, _this.prepareError) || other.prepareError == _this.prepareError)&&(identical(other.prepareSubtitlesError, _this.prepareSubtitlesError) || other.prepareSubtitlesError == _this.prepareSubtitlesError)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&const DeepCollectionEquality().equals(other.audioTracks, _this.audioTracks)&&(identical(other.activeAudioIndex, _this.activeAudioIndex) || other.activeAudioIndex == _this.activeAudioIndex)&&(identical(other.isLive, _this.isLive) || other.isLive == _this.isLive)&&(identical(other.restarting, _this.restarting) || other.restarting == _this.restarting)&&(identical(other.seekPreview, _this.seekPreview) || other.seekPreview == _this.seekPreview));
}


@override
int get hashCode {
  final _this = this as CastSessionState;
  return Object.hashAll([runtimeType,_this.sessionState,_this.activeDevice,_this.activeMedia,_this.activeSubtitle,_this.connectionStatus,_this.connectionError,_this.playbackStatus,_this.playbackError,_this.position,_this.preparing,_this.preparingSubtitles,_this.castPlan,_this.castPlanReason,_this.prepareError,_this.prepareSubtitlesError,_this.duration,_this.volume,const DeepCollectionEquality().hash(_this.audioTracks),_this.activeAudioIndex,_this.isLive,_this.restarting,_this.seekPreview]);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as CastSessionState;
  return 'CastSessionState(sessionState: ${_this.sessionState}, activeDevice: ${_this.activeDevice}, activeMedia: ${_this.activeMedia}, activeSubtitle: ${_this.activeSubtitle}, connectionStatus: ${_this.connectionStatus}, connectionError: ${_this.connectionError}, playbackStatus: ${_this.playbackStatus}, playbackError: ${_this.playbackError}, position: ${_this.position}, preparing: ${_this.preparing}, preparingSubtitles: ${_this.preparingSubtitles}, castPlan: ${_this.castPlan}, castPlanReason: ${_this.castPlanReason}, prepareError: ${_this.prepareError}, prepareSubtitlesError: ${_this.prepareSubtitlesError}, duration: ${_this.duration}, volume: ${_this.volume}, audioTracks: ${_this.audioTracks}, activeAudioIndex: ${_this.activeAudioIndex}, isLive: ${_this.isLive}, restarting: ${_this.restarting}, seekPreview: ${_this.seekPreview})';
}


}

/// @nodoc
abstract mixin class $CastSessionStateCopyWith<$Res>  {
  factory $CastSessionStateCopyWith(CastSessionState value, $Res Function(CastSessionState) _then) = _$CastSessionStateCopyWithImpl;
@useResult
$Res call({
 PureCastSessionState sessionState, PureCastDevice? activeDevice, PureCastMedia? activeMedia, PureCastSubtitleTrack? activeSubtitle, StateStatus connectionStatus, String? connectionError, StateStatus playbackStatus, String? playbackError, Duration position, bool preparing, bool preparingSubtitles, String? castPlan, String? castPlanReason, String? prepareError, String? prepareSubtitlesError, Duration duration, double volume, List<PureCastAudioTrack> audioTracks, int? activeAudioIndex, bool isLive, bool restarting, Duration? seekPreview
});




}
/// @nodoc
class _$CastSessionStateCopyWithImpl<$Res>
    implements $CastSessionStateCopyWith<$Res> {
  _$CastSessionStateCopyWithImpl(this._self, this._then);

  final CastSessionState _self;
  final $Res Function(CastSessionState) _then;

/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionState = null,Object? activeDevice = freezed,Object? activeMedia = freezed,Object? activeSubtitle = freezed,Object? connectionStatus = null,Object? connectionError = freezed,Object? playbackStatus = null,Object? playbackError = freezed,Object? position = null,Object? preparing = null,Object? preparingSubtitles = null,Object? castPlan = freezed,Object? castPlanReason = freezed,Object? prepareError = freezed,Object? prepareSubtitlesError = freezed,Object? duration = null,Object? volume = null,Object? audioTracks = null,Object? activeAudioIndex = freezed,Object? isLive = null,Object? restarting = null,Object? seekPreview = freezed,}) {
  return _then(CastSessionState(
sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,activeDevice: freezed == activeDevice ? _self.activeDevice : activeDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,activeMedia: freezed == activeMedia ? _self.activeMedia : activeMedia // ignore: cast_nullable_to_non_nullable
as PureCastMedia?,activeSubtitle: freezed == activeSubtitle ? _self.activeSubtitle : activeSubtitle // ignore: cast_nullable_to_non_nullable
as PureCastSubtitleTrack?,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,connectionError: freezed == connectionError ? _self.connectionError : connectionError // ignore: cast_nullable_to_non_nullable
as String?,playbackStatus: null == playbackStatus ? _self.playbackStatus : playbackStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,playbackError: freezed == playbackError ? _self.playbackError : playbackError // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,preparing: null == preparing ? _self.preparing : preparing // ignore: cast_nullable_to_non_nullable
as bool,preparingSubtitles: null == preparingSubtitles ? _self.preparingSubtitles : preparingSubtitles // ignore: cast_nullable_to_non_nullable
as bool,castPlan: freezed == castPlan ? _self.castPlan : castPlan // ignore: cast_nullable_to_non_nullable
as String?,castPlanReason: freezed == castPlanReason ? _self.castPlanReason : castPlanReason // ignore: cast_nullable_to_non_nullable
as String?,prepareError: freezed == prepareError ? _self.prepareError : prepareError // ignore: cast_nullable_to_non_nullable
as String?,prepareSubtitlesError: freezed == prepareSubtitlesError ? _self.prepareSubtitlesError : prepareSubtitlesError // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,audioTracks: null == audioTracks ? _self.audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as List<PureCastAudioTrack>,activeAudioIndex: freezed == activeAudioIndex ? _self.activeAudioIndex : activeAudioIndex // ignore: cast_nullable_to_non_nullable
as int?,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,restarting: null == restarting ? _self.restarting : restarting // ignore: cast_nullable_to_non_nullable
as bool,seekPreview: freezed == seekPreview ? _self.seekPreview : seekPreview // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [CastSessionState].
extension CastSessionStatePatterns on CastSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CastSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CastSessionState value)  $default,){
final _that = this;
switch (_that) {
case _CastSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CastSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  PureCastSubtitleTrack? activeSubtitle,  StateStatus connectionStatus,  String? connectionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  bool preparing,  bool preparingSubtitles,  String? castPlan,  String? castPlanReason,  String? prepareError,  String? prepareSubtitlesError,  Duration duration,  double volume,  List<PureCastAudioTrack> audioTracks,  int? activeAudioIndex,  bool isLive,  bool restarting,  Duration? seekPreview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.activeSubtitle,_that.connectionStatus,_that.connectionError,_that.playbackStatus,_that.playbackError,_that.position,_that.preparing,_that.preparingSubtitles,_that.castPlan,_that.castPlanReason,_that.prepareError,_that.prepareSubtitlesError,_that.duration,_that.volume,_that.audioTracks,_that.activeAudioIndex,_that.isLive,_that.restarting,_that.seekPreview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  PureCastSubtitleTrack? activeSubtitle,  StateStatus connectionStatus,  String? connectionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  bool preparing,  bool preparingSubtitles,  String? castPlan,  String? castPlanReason,  String? prepareError,  String? prepareSubtitlesError,  Duration duration,  double volume,  List<PureCastAudioTrack> audioTracks,  int? activeAudioIndex,  bool isLive,  bool restarting,  Duration? seekPreview)  $default,) {final _that = this;
switch (_that) {
case _CastSessionState():
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.activeSubtitle,_that.connectionStatus,_that.connectionError,_that.playbackStatus,_that.playbackError,_that.position,_that.preparing,_that.preparingSubtitles,_that.castPlan,_that.castPlanReason,_that.prepareError,_that.prepareSubtitlesError,_that.duration,_that.volume,_that.audioTracks,_that.activeAudioIndex,_that.isLive,_that.restarting,_that.seekPreview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  PureCastSubtitleTrack? activeSubtitle,  StateStatus connectionStatus,  String? connectionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  bool preparing,  bool preparingSubtitles,  String? castPlan,  String? castPlanReason,  String? prepareError,  String? prepareSubtitlesError,  Duration duration,  double volume,  List<PureCastAudioTrack> audioTracks,  int? activeAudioIndex,  bool isLive,  bool restarting,  Duration? seekPreview)?  $default,) {final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.activeSubtitle,_that.connectionStatus,_that.connectionError,_that.playbackStatus,_that.playbackError,_that.position,_that.preparing,_that.preparingSubtitles,_that.castPlan,_that.castPlanReason,_that.prepareError,_that.prepareSubtitlesError,_that.duration,_that.volume,_that.audioTracks,_that.activeAudioIndex,_that.isLive,_that.restarting,_that.seekPreview);case _:
  return null;

}
}

}

/// @nodoc


class _CastSessionState extends CastSessionState with DiagnosticableTreeMixin {
  const _CastSessionState({this.sessionState = PureCastSessionState.disconnected, this.activeDevice, this.activeMedia, this.activeSubtitle = null, this.connectionStatus = StateStatus.initial, this.connectionError, this.playbackStatus = StateStatus.initial, this.playbackError, this.position = Duration.zero, this.preparing = false, this.preparingSubtitles = false, this.castPlan, this.castPlanReason, this.prepareError, this.prepareSubtitlesError, this.duration = Duration.zero, this.volume = 1.0,  List<PureCastAudioTrack> audioTracks = const <PureCastAudioTrack>[], this.activeAudioIndex, this.isLive = false, this.restarting = false, this.seekPreview}): _audioTracks = audioTracks,super._();
  

@override@JsonKey() final  PureCastSessionState sessionState;
@override final  PureCastDevice? activeDevice;
@override final  PureCastMedia? activeMedia;
@override@JsonKey() final  PureCastSubtitleTrack? activeSubtitle;
@override@JsonKey() final  StateStatus connectionStatus;
@override final  String? connectionError;
@override@JsonKey() final  StateStatus playbackStatus;
@override final  String? playbackError;
@override@JsonKey() final  Duration position;
@override@JsonKey() final  bool preparing;
@override@JsonKey() final  bool preparingSubtitles;
@override final  String? castPlan;
@override final  String? castPlanReason;
@override final  String? prepareError;
@override final  String? prepareSubtitlesError;
@override@JsonKey() final  Duration duration;
@override@JsonKey() final  double volume;
 final  List<PureCastAudioTrack> _audioTracks;
@override@JsonKey() List<PureCastAudioTrack> get audioTracks {
  if (_audioTracks is EqualUnmodifiableListView) return _audioTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioTracks);
}

@override final  int? activeAudioIndex;
@override@JsonKey() final  bool isLive;
@override@JsonKey() final  bool restarting;
/// Accumulated target of pending relative-seek taps, shown by the seek bar
/// and the time labels until the debounced seek is committed.
@override final  Duration? seekPreview;

/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CastSessionStateCopyWith<_CastSessionState> get copyWith => __$CastSessionStateCopyWithImpl<_CastSessionState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'CastSessionState'))
    ..add(DiagnosticsProperty('sessionState', sessionState))..add(DiagnosticsProperty('activeDevice', activeDevice))..add(DiagnosticsProperty('activeMedia', activeMedia))..add(DiagnosticsProperty('activeSubtitle', activeSubtitle))..add(DiagnosticsProperty('connectionStatus', connectionStatus))..add(DiagnosticsProperty('connectionError', connectionError))..add(DiagnosticsProperty('playbackStatus', playbackStatus))..add(DiagnosticsProperty('playbackError', playbackError))..add(DiagnosticsProperty('position', position))..add(DiagnosticsProperty('preparing', preparing))..add(DiagnosticsProperty('preparingSubtitles', preparingSubtitles))..add(DiagnosticsProperty('castPlan', castPlan))..add(DiagnosticsProperty('castPlanReason', castPlanReason))..add(DiagnosticsProperty('prepareError', prepareError))..add(DiagnosticsProperty('prepareSubtitlesError', prepareSubtitlesError))..add(DiagnosticsProperty('duration', duration))..add(DiagnosticsProperty('volume', volume))..add(DiagnosticsProperty('audioTracks', audioTracks))..add(DiagnosticsProperty('activeAudioIndex', activeAudioIndex))..add(DiagnosticsProperty('isLive', isLive))..add(DiagnosticsProperty('restarting', restarting))..add(DiagnosticsProperty('seekPreview', seekPreview));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CastSessionState&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState)&&(identical(other.activeDevice, activeDevice) || other.activeDevice == activeDevice)&&(identical(other.activeMedia, activeMedia) || other.activeMedia == activeMedia)&&(identical(other.activeSubtitle, activeSubtitle) || other.activeSubtitle == activeSubtitle)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&(identical(other.connectionError, connectionError) || other.connectionError == connectionError)&&(identical(other.playbackStatus, playbackStatus) || other.playbackStatus == playbackStatus)&&(identical(other.playbackError, playbackError) || other.playbackError == playbackError)&&(identical(other.position, position) || other.position == position)&&(identical(other.preparing, preparing) || other.preparing == preparing)&&(identical(other.preparingSubtitles, preparingSubtitles) || other.preparingSubtitles == preparingSubtitles)&&(identical(other.castPlan, castPlan) || other.castPlan == castPlan)&&(identical(other.castPlanReason, castPlanReason) || other.castPlanReason == castPlanReason)&&(identical(other.prepareError, prepareError) || other.prepareError == prepareError)&&(identical(other.prepareSubtitlesError, prepareSubtitlesError) || other.prepareSubtitlesError == prepareSubtitlesError)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume)&&const DeepCollectionEquality().equals(other.audioTracks, _audioTracks)&&(identical(other.activeAudioIndex, activeAudioIndex) || other.activeAudioIndex == activeAudioIndex)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.restarting, restarting) || other.restarting == restarting)&&(identical(other.seekPreview, seekPreview) || other.seekPreview == seekPreview));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,sessionState,activeDevice,activeMedia,activeSubtitle,connectionStatus,connectionError,playbackStatus,playbackError,position,preparing,preparingSubtitles,castPlan,castPlanReason,prepareError,prepareSubtitlesError,duration,volume,const DeepCollectionEquality().hash(_audioTracks),activeAudioIndex,isLive,restarting,seekPreview]);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'CastSessionState(sessionState: $sessionState, activeDevice: $activeDevice, activeMedia: $activeMedia, activeSubtitle: $activeSubtitle, connectionStatus: $connectionStatus, connectionError: $connectionError, playbackStatus: $playbackStatus, playbackError: $playbackError, position: $position, preparing: $preparing, preparingSubtitles: $preparingSubtitles, castPlan: $castPlan, castPlanReason: $castPlanReason, prepareError: $prepareError, prepareSubtitlesError: $prepareSubtitlesError, duration: $duration, volume: $volume, audioTracks: $audioTracks, activeAudioIndex: $activeAudioIndex, isLive: $isLive, restarting: $restarting, seekPreview: $seekPreview)';
}


}

/// @nodoc
abstract mixin class _$CastSessionStateCopyWith<$Res> implements $CastSessionStateCopyWith<$Res> {
  factory _$CastSessionStateCopyWith(_CastSessionState value, $Res Function(_CastSessionState) _then) = __$CastSessionStateCopyWithImpl;
@override @useResult
$Res call({
 PureCastSessionState sessionState, PureCastDevice? activeDevice, PureCastMedia? activeMedia, PureCastSubtitleTrack? activeSubtitle, StateStatus connectionStatus, String? connectionError, StateStatus playbackStatus, String? playbackError, Duration position, bool preparing, bool preparingSubtitles, String? castPlan, String? castPlanReason, String? prepareError, String? prepareSubtitlesError, Duration duration, double volume, List<PureCastAudioTrack> audioTracks, int? activeAudioIndex, bool isLive, bool restarting, Duration? seekPreview
});




}
/// @nodoc
class __$CastSessionStateCopyWithImpl<$Res>
    implements _$CastSessionStateCopyWith<$Res> {
  __$CastSessionStateCopyWithImpl(this._self, this._then);

  final _CastSessionState _self;
  final $Res Function(_CastSessionState) _then;

/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionState = null,Object? activeDevice = freezed,Object? activeMedia = freezed,Object? activeSubtitle = freezed,Object? connectionStatus = null,Object? connectionError = freezed,Object? playbackStatus = null,Object? playbackError = freezed,Object? position = null,Object? preparing = null,Object? preparingSubtitles = null,Object? castPlan = freezed,Object? castPlanReason = freezed,Object? prepareError = freezed,Object? prepareSubtitlesError = freezed,Object? duration = null,Object? volume = null,Object? audioTracks = null,Object? activeAudioIndex = freezed,Object? isLive = null,Object? restarting = null,Object? seekPreview = freezed,}) {
  return _then(_CastSessionState(
sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,activeDevice: freezed == activeDevice ? _self.activeDevice : activeDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,activeMedia: freezed == activeMedia ? _self.activeMedia : activeMedia // ignore: cast_nullable_to_non_nullable
as PureCastMedia?,activeSubtitle: freezed == activeSubtitle ? _self.activeSubtitle : activeSubtitle // ignore: cast_nullable_to_non_nullable
as PureCastSubtitleTrack?,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,connectionError: freezed == connectionError ? _self.connectionError : connectionError // ignore: cast_nullable_to_non_nullable
as String?,playbackStatus: null == playbackStatus ? _self.playbackStatus : playbackStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,playbackError: freezed == playbackError ? _self.playbackError : playbackError // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,preparing: null == preparing ? _self.preparing : preparing // ignore: cast_nullable_to_non_nullable
as bool,preparingSubtitles: null == preparingSubtitles ? _self.preparingSubtitles : preparingSubtitles // ignore: cast_nullable_to_non_nullable
as bool,castPlan: freezed == castPlan ? _self.castPlan : castPlan // ignore: cast_nullable_to_non_nullable
as String?,castPlanReason: freezed == castPlanReason ? _self.castPlanReason : castPlanReason // ignore: cast_nullable_to_non_nullable
as String?,prepareError: freezed == prepareError ? _self.prepareError : prepareError // ignore: cast_nullable_to_non_nullable
as String?,prepareSubtitlesError: freezed == prepareSubtitlesError ? _self.prepareSubtitlesError : prepareSubtitlesError // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,audioTracks: null == audioTracks ? _self._audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as List<PureCastAudioTrack>,activeAudioIndex: freezed == activeAudioIndex ? _self.activeAudioIndex : activeAudioIndex // ignore: cast_nullable_to_non_nullable
as int?,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,restarting: null == restarting ? _self.restarting : restarting // ignore: cast_nullable_to_non_nullable
as bool,seekPreview: freezed == seekPreview ? _self.seekPreview : seekPreview // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
