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
mixin _$CastSessionEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastSessionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConnectDeviceEvent value)?  connectDevice,TResult Function( DisconnectDeviceEvent value)?  disconnectDevice,TResult Function( LoadMediaEvent value)?  loadMedia,TResult Function( PlayMediaEvent value)?  playMedia,TResult Function( PauseMediaEvent value)?  pauseMedia,TResult Function( StopMediaEvent value)?  stopMedia,TResult Function( SeekMediaEvent value)?  seekMedia,TResult Function( SetVolumeEvent value)?  setVolume,TResult Function( SessionStateChangedEvent value)?  sessionStateChanged,TResult Function( PositionUpdatedEvent value)?  positionUpdated,TResult Function( DurationUpdatedEvent value)?  durationUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice(_that);case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that);case PlayMediaEvent() when playMedia != null:
return playMedia(_that);case PauseMediaEvent() when pauseMedia != null:
return pauseMedia(_that);case StopMediaEvent() when stopMedia != null:
return stopMedia(_that);case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that);case SetVolumeEvent() when setVolume != null:
return setVolume(_that);case SessionStateChangedEvent() when sessionStateChanged != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConnectDeviceEvent value)  connectDevice,required TResult Function( DisconnectDeviceEvent value)  disconnectDevice,required TResult Function( LoadMediaEvent value)  loadMedia,required TResult Function( PlayMediaEvent value)  playMedia,required TResult Function( PauseMediaEvent value)  pauseMedia,required TResult Function( StopMediaEvent value)  stopMedia,required TResult Function( SeekMediaEvent value)  seekMedia,required TResult Function( SetVolumeEvent value)  setVolume,required TResult Function( SessionStateChangedEvent value)  sessionStateChanged,required TResult Function( PositionUpdatedEvent value)  positionUpdated,required TResult Function( DurationUpdatedEvent value)  durationUpdated,}){
final _that = this;
switch (_that) {
case ConnectDeviceEvent():
return connectDevice(_that);case DisconnectDeviceEvent():
return disconnectDevice(_that);case LoadMediaEvent():
return loadMedia(_that);case PlayMediaEvent():
return playMedia(_that);case PauseMediaEvent():
return pauseMedia(_that);case StopMediaEvent():
return stopMedia(_that);case SeekMediaEvent():
return seekMedia(_that);case SetVolumeEvent():
return setVolume(_that);case SessionStateChangedEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConnectDeviceEvent value)?  connectDevice,TResult? Function( DisconnectDeviceEvent value)?  disconnectDevice,TResult? Function( LoadMediaEvent value)?  loadMedia,TResult? Function( PlayMediaEvent value)?  playMedia,TResult? Function( PauseMediaEvent value)?  pauseMedia,TResult? Function( StopMediaEvent value)?  stopMedia,TResult? Function( SeekMediaEvent value)?  seekMedia,TResult? Function( SetVolumeEvent value)?  setVolume,TResult? Function( SessionStateChangedEvent value)?  sessionStateChanged,TResult? Function( PositionUpdatedEvent value)?  positionUpdated,TResult? Function( DurationUpdatedEvent value)?  durationUpdated,}){
final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice(_that);case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that);case PlayMediaEvent() when playMedia != null:
return playMedia(_that);case PauseMediaEvent() when pauseMedia != null:
return pauseMedia(_that);case StopMediaEvent() when stopMedia != null:
return stopMedia(_that);case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that);case SetVolumeEvent() when setVolume != null:
return setVolume(_that);case SessionStateChangedEvent() when sessionStateChanged != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PureCastDevice device)?  connectDevice,TResult Function()?  disconnectDevice,TResult Function( PureCastMedia media)?  loadMedia,TResult Function()?  playMedia,TResult Function()?  pauseMedia,TResult Function()?  stopMedia,TResult Function( Duration position)?  seekMedia,TResult Function( double volume)?  setVolume,TResult Function( PureCastSessionState newState)?  sessionStateChanged,TResult Function( Duration position)?  positionUpdated,TResult Function( Duration duration)?  durationUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that.device);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice();case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that.media);case PlayMediaEvent() when playMedia != null:
return playMedia();case PauseMediaEvent() when pauseMedia != null:
return pauseMedia();case StopMediaEvent() when stopMedia != null:
return stopMedia();case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that.position);case SetVolumeEvent() when setVolume != null:
return setVolume(_that.volume);case SessionStateChangedEvent() when sessionStateChanged != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PureCastDevice device)  connectDevice,required TResult Function()  disconnectDevice,required TResult Function( PureCastMedia media)  loadMedia,required TResult Function()  playMedia,required TResult Function()  pauseMedia,required TResult Function()  stopMedia,required TResult Function( Duration position)  seekMedia,required TResult Function( double volume)  setVolume,required TResult Function( PureCastSessionState newState)  sessionStateChanged,required TResult Function( Duration position)  positionUpdated,required TResult Function( Duration duration)  durationUpdated,}) {final _that = this;
switch (_that) {
case ConnectDeviceEvent():
return connectDevice(_that.device);case DisconnectDeviceEvent():
return disconnectDevice();case LoadMediaEvent():
return loadMedia(_that.media);case PlayMediaEvent():
return playMedia();case PauseMediaEvent():
return pauseMedia();case StopMediaEvent():
return stopMedia();case SeekMediaEvent():
return seekMedia(_that.position);case SetVolumeEvent():
return setVolume(_that.volume);case SessionStateChangedEvent():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PureCastDevice device)?  connectDevice,TResult? Function()?  disconnectDevice,TResult? Function( PureCastMedia media)?  loadMedia,TResult? Function()?  playMedia,TResult? Function()?  pauseMedia,TResult? Function()?  stopMedia,TResult? Function( Duration position)?  seekMedia,TResult? Function( double volume)?  setVolume,TResult? Function( PureCastSessionState newState)?  sessionStateChanged,TResult? Function( Duration position)?  positionUpdated,TResult? Function( Duration duration)?  durationUpdated,}) {final _that = this;
switch (_that) {
case ConnectDeviceEvent() when connectDevice != null:
return connectDevice(_that.device);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice();case LoadMediaEvent() when loadMedia != null:
return loadMedia(_that.media);case PlayMediaEvent() when playMedia != null:
return playMedia();case PauseMediaEvent() when pauseMedia != null:
return pauseMedia();case StopMediaEvent() when stopMedia != null:
return stopMedia();case SeekMediaEvent() when seekMedia != null:
return seekMedia(_that.position);case SetVolumeEvent() when setVolume != null:
return setVolume(_that.volume);case SessionStateChangedEvent() when sessionStateChanged != null:
return sessionStateChanged(_that.newState);case PositionUpdatedEvent() when positionUpdated != null:
return positionUpdated(_that.position);case DurationUpdatedEvent() when durationUpdated != null:
return durationUpdated(_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class ConnectDeviceEvent implements CastSessionEvent {
  const ConnectDeviceEvent(this.device);
  

 final  PureCastDevice device;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectDeviceEventCopyWith<ConnectDeviceEvent> get copyWith => _$ConnectDeviceEventCopyWithImpl<ConnectDeviceEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectDeviceEvent&&(identical(other.device, device) || other.device == device));
}


@override
int get hashCode => Object.hash(runtimeType,device);

@override
String toString() {
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


class DisconnectDeviceEvent implements CastSessionEvent {
  const DisconnectDeviceEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisconnectDeviceEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastSessionEvent.disconnectDevice()';
}


}




/// @nodoc


class LoadMediaEvent implements CastSessionEvent {
  const LoadMediaEvent(this.media);
  

 final  PureCastMedia media;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadMediaEventCopyWith<LoadMediaEvent> get copyWith => _$LoadMediaEventCopyWithImpl<LoadMediaEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadMediaEvent&&(identical(other.media, media) || other.media == media));
}


@override
int get hashCode => Object.hash(runtimeType,media);

@override
String toString() {
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


class PlayMediaEvent implements CastSessionEvent {
  const PlayMediaEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastSessionEvent.playMedia()';
}


}




/// @nodoc


class PauseMediaEvent implements CastSessionEvent {
  const PauseMediaEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastSessionEvent.pauseMedia()';
}


}




/// @nodoc


class StopMediaEvent implements CastSessionEvent {
  const StopMediaEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopMediaEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastSessionEvent.stopMedia()';
}


}




/// @nodoc


class SeekMediaEvent implements CastSessionEvent {
  const SeekMediaEvent(this.position);
  

 final  Duration position;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeekMediaEventCopyWith<SeekMediaEvent> get copyWith => _$SeekMediaEventCopyWithImpl<SeekMediaEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeekMediaEvent&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,position);

@override
String toString() {
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


class SetVolumeEvent implements CastSessionEvent {
  const SetVolumeEvent(this.volume);
  

 final  double volume;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetVolumeEventCopyWith<SetVolumeEvent> get copyWith => _$SetVolumeEventCopyWithImpl<SetVolumeEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetVolumeEvent&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
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


class SessionStateChangedEvent implements CastSessionEvent {
  const SessionStateChangedEvent(this.newState);
  

 final  PureCastSessionState newState;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateChangedEventCopyWith<SessionStateChangedEvent> get copyWith => _$SessionStateChangedEventCopyWithImpl<SessionStateChangedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionStateChangedEvent&&(identical(other.newState, newState) || other.newState == newState));
}


@override
int get hashCode => Object.hash(runtimeType,newState);

@override
String toString() {
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


class PositionUpdatedEvent implements CastSessionEvent {
  const PositionUpdatedEvent(this.position);
  

 final  Duration position;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionUpdatedEventCopyWith<PositionUpdatedEvent> get copyWith => _$PositionUpdatedEventCopyWithImpl<PositionUpdatedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionUpdatedEvent&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,position);

@override
String toString() {
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


class DurationUpdatedEvent implements CastSessionEvent {
  const DurationUpdatedEvent(this.duration);
  

 final  Duration duration;

/// Create a copy of CastSessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DurationUpdatedEventCopyWith<DurationUpdatedEvent> get copyWith => _$DurationUpdatedEventCopyWithImpl<DurationUpdatedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DurationUpdatedEvent&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,duration);

@override
String toString() {
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
mixin _$CastSessionState {

 PureCastSessionState get sessionState; PureCastDevice? get activeDevice; PureCastMedia? get activeMedia; StateStatus get connectionStatus; String? get connectionError; StateStatus get playbackStatus; String? get playbackError; Duration get position; Duration get duration; double get volume;
/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CastSessionStateCopyWith<CastSessionState> get copyWith => _$CastSessionStateCopyWithImpl<CastSessionState>(this as CastSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastSessionState&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState)&&(identical(other.activeDevice, activeDevice) || other.activeDevice == activeDevice)&&(identical(other.activeMedia, activeMedia) || other.activeMedia == activeMedia)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&(identical(other.connectionError, connectionError) || other.connectionError == connectionError)&&(identical(other.playbackStatus, playbackStatus) || other.playbackStatus == playbackStatus)&&(identical(other.playbackError, playbackError) || other.playbackError == playbackError)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,sessionState,activeDevice,activeMedia,connectionStatus,connectionError,playbackStatus,playbackError,position,duration,volume);

@override
String toString() {
  return 'CastSessionState(sessionState: $sessionState, activeDevice: $activeDevice, activeMedia: $activeMedia, connectionStatus: $connectionStatus, connectionError: $connectionError, playbackStatus: $playbackStatus, playbackError: $playbackError, position: $position, duration: $duration, volume: $volume)';
}


}

/// @nodoc
abstract mixin class $CastSessionStateCopyWith<$Res>  {
  factory $CastSessionStateCopyWith(CastSessionState value, $Res Function(CastSessionState) _then) = _$CastSessionStateCopyWithImpl;
@useResult
$Res call({
 PureCastSessionState sessionState, PureCastDevice? activeDevice, PureCastMedia? activeMedia, StateStatus connectionStatus, String? connectionError, StateStatus playbackStatus, String? playbackError, Duration position, Duration duration, double volume
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
@pragma('vm:prefer-inline') @override $Res call({Object? sessionState = null,Object? activeDevice = freezed,Object? activeMedia = freezed,Object? connectionStatus = null,Object? connectionError = freezed,Object? playbackStatus = null,Object? playbackError = freezed,Object? position = null,Object? duration = null,Object? volume = null,}) {
  return _then(CastSessionState(
sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,activeDevice: freezed == activeDevice ? _self.activeDevice : activeDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,activeMedia: freezed == activeMedia ? _self.activeMedia : activeMedia // ignore: cast_nullable_to_non_nullable
as PureCastMedia?,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,connectionError: freezed == connectionError ? _self.connectionError : connectionError // ignore: cast_nullable_to_non_nullable
as String?,playbackStatus: null == playbackStatus ? _self.playbackStatus : playbackStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,playbackError: freezed == playbackError ? _self.playbackError : playbackError // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  StateStatus connectionStatus,  String? connectionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  Duration duration,  double volume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.connectionStatus,_that.connectionError,_that.playbackStatus,_that.playbackError,_that.position,_that.duration,_that.volume);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  StateStatus connectionStatus,  String? connectionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  Duration duration,  double volume)  $default,) {final _that = this;
switch (_that) {
case _CastSessionState():
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.connectionStatus,_that.connectionError,_that.playbackStatus,_that.playbackError,_that.position,_that.duration,_that.volume);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  StateStatus connectionStatus,  String? connectionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  Duration duration,  double volume)?  $default,) {final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.connectionStatus,_that.connectionError,_that.playbackStatus,_that.playbackError,_that.position,_that.duration,_that.volume);case _:
  return null;

}
}

}

/// @nodoc


class _CastSessionState extends CastSessionState {
  const _CastSessionState({this.sessionState = PureCastSessionState.disconnected, this.activeDevice, this.activeMedia, this.connectionStatus = StateStatus.initial, this.connectionError, this.playbackStatus = StateStatus.initial, this.playbackError, this.position = Duration.zero, this.duration = Duration.zero, this.volume = 1.0}): super._();
  

@override@JsonKey() final  PureCastSessionState sessionState;
@override final  PureCastDevice? activeDevice;
@override final  PureCastMedia? activeMedia;
@override@JsonKey() final  StateStatus connectionStatus;
@override final  String? connectionError;
@override@JsonKey() final  StateStatus playbackStatus;
@override final  String? playbackError;
@override@JsonKey() final  Duration position;
@override@JsonKey() final  Duration duration;
@override@JsonKey() final  double volume;

/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CastSessionStateCopyWith<_CastSessionState> get copyWith => __$CastSessionStateCopyWithImpl<_CastSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CastSessionState&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState)&&(identical(other.activeDevice, activeDevice) || other.activeDevice == activeDevice)&&(identical(other.activeMedia, activeMedia) || other.activeMedia == activeMedia)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&(identical(other.connectionError, connectionError) || other.connectionError == connectionError)&&(identical(other.playbackStatus, playbackStatus) || other.playbackStatus == playbackStatus)&&(identical(other.playbackError, playbackError) || other.playbackError == playbackError)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,sessionState,activeDevice,activeMedia,connectionStatus,connectionError,playbackStatus,playbackError,position,duration,volume);

@override
String toString() {
  return 'CastSessionState(sessionState: $sessionState, activeDevice: $activeDevice, activeMedia: $activeMedia, connectionStatus: $connectionStatus, connectionError: $connectionError, playbackStatus: $playbackStatus, playbackError: $playbackError, position: $position, duration: $duration, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$CastSessionStateCopyWith<$Res> implements $CastSessionStateCopyWith<$Res> {
  factory _$CastSessionStateCopyWith(_CastSessionState value, $Res Function(_CastSessionState) _then) = __$CastSessionStateCopyWithImpl;
@override @useResult
$Res call({
 PureCastSessionState sessionState, PureCastDevice? activeDevice, PureCastMedia? activeMedia, StateStatus connectionStatus, String? connectionError, StateStatus playbackStatus, String? playbackError, Duration position, Duration duration, double volume
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
@override @pragma('vm:prefer-inline') $Res call({Object? sessionState = null,Object? activeDevice = freezed,Object? activeMedia = freezed,Object? connectionStatus = null,Object? connectionError = freezed,Object? playbackStatus = null,Object? playbackError = freezed,Object? position = null,Object? duration = null,Object? volume = null,}) {
  return _then(_CastSessionState(
sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,activeDevice: freezed == activeDevice ? _self.activeDevice : activeDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,activeMedia: freezed == activeMedia ? _self.activeMedia : activeMedia // ignore: cast_nullable_to_non_nullable
as PureCastMedia?,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,connectionError: freezed == connectionError ? _self.connectionError : connectionError // ignore: cast_nullable_to_non_nullable
as String?,playbackStatus: null == playbackStatus ? _self.playbackStatus : playbackStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,playbackError: freezed == playbackError ? _self.playbackError : playbackError // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
