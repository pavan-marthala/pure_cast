// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cast_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CastSessionState {

 PureCastSessionState get sessionState; PureCastDevice? get activeDevice; PureCastMedia? get activeMedia; StateStatus get sessionStatus; String? get sessionError; StateStatus get playbackStatus; String? get playbackError; Duration get position; Duration get duration; double get volume;
/// Create a copy of CastSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CastSessionStateCopyWith<CastSessionState> get copyWith => _$CastSessionStateCopyWithImpl<CastSessionState>(this as CastSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastSessionState&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState)&&(identical(other.activeDevice, activeDevice) || other.activeDevice == activeDevice)&&(identical(other.activeMedia, activeMedia) || other.activeMedia == activeMedia)&&(identical(other.sessionStatus, sessionStatus) || other.sessionStatus == sessionStatus)&&(identical(other.sessionError, sessionError) || other.sessionError == sessionError)&&(identical(other.playbackStatus, playbackStatus) || other.playbackStatus == playbackStatus)&&(identical(other.playbackError, playbackError) || other.playbackError == playbackError)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,sessionState,activeDevice,activeMedia,sessionStatus,sessionError,playbackStatus,playbackError,position,duration,volume);

@override
String toString() {
  return 'CastSessionState(sessionState: $sessionState, activeDevice: $activeDevice, activeMedia: $activeMedia, sessionStatus: $sessionStatus, sessionError: $sessionError, playbackStatus: $playbackStatus, playbackError: $playbackError, position: $position, duration: $duration, volume: $volume)';
}


}

/// @nodoc
abstract mixin class $CastSessionStateCopyWith<$Res>  {
  factory $CastSessionStateCopyWith(CastSessionState value, $Res Function(CastSessionState) _then) = _$CastSessionStateCopyWithImpl;
@useResult
$Res call({
 PureCastSessionState sessionState, PureCastDevice? activeDevice, PureCastMedia? activeMedia, StateStatus sessionStatus, String? sessionError, StateStatus playbackStatus, String? playbackError, Duration position, Duration duration, double volume
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
@pragma('vm:prefer-inline') @override $Res call({Object? sessionState = null,Object? activeDevice = freezed,Object? activeMedia = freezed,Object? sessionStatus = null,Object? sessionError = freezed,Object? playbackStatus = null,Object? playbackError = freezed,Object? position = null,Object? duration = null,Object? volume = null,}) {
  return _then(CastSessionState(
sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,activeDevice: freezed == activeDevice ? _self.activeDevice : activeDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,activeMedia: freezed == activeMedia ? _self.activeMedia : activeMedia // ignore: cast_nullable_to_non_nullable
as PureCastMedia?,sessionStatus: null == sessionStatus ? _self.sessionStatus : sessionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,sessionError: freezed == sessionError ? _self.sessionError : sessionError // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  StateStatus sessionStatus,  String? sessionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  Duration duration,  double volume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.sessionStatus,_that.sessionError,_that.playbackStatus,_that.playbackError,_that.position,_that.duration,_that.volume);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  StateStatus sessionStatus,  String? sessionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  Duration duration,  double volume)  $default,) {final _that = this;
switch (_that) {
case _CastSessionState():
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.sessionStatus,_that.sessionError,_that.playbackStatus,_that.playbackError,_that.position,_that.duration,_that.volume);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PureCastSessionState sessionState,  PureCastDevice? activeDevice,  PureCastMedia? activeMedia,  StateStatus sessionStatus,  String? sessionError,  StateStatus playbackStatus,  String? playbackError,  Duration position,  Duration duration,  double volume)?  $default,) {final _that = this;
switch (_that) {
case _CastSessionState() when $default != null:
return $default(_that.sessionState,_that.activeDevice,_that.activeMedia,_that.sessionStatus,_that.sessionError,_that.playbackStatus,_that.playbackError,_that.position,_that.duration,_that.volume);case _:
  return null;

}
}

}

/// @nodoc


class _CastSessionState implements CastSessionState {
  const _CastSessionState({this.sessionState = PureCastSessionState.disconnected, this.activeDevice, this.activeMedia, this.sessionStatus = StateStatus.initial, this.sessionError, this.playbackStatus = StateStatus.initial, this.playbackError, this.position = Duration.zero, this.duration = Duration.zero, this.volume = 1.0});
  

@override@JsonKey() final  PureCastSessionState sessionState;
@override final  PureCastDevice? activeDevice;
@override final  PureCastMedia? activeMedia;
@override@JsonKey() final  StateStatus sessionStatus;
@override final  String? sessionError;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CastSessionState&&(identical(other.sessionState, sessionState) || other.sessionState == sessionState)&&(identical(other.activeDevice, activeDevice) || other.activeDevice == activeDevice)&&(identical(other.activeMedia, activeMedia) || other.activeMedia == activeMedia)&&(identical(other.sessionStatus, sessionStatus) || other.sessionStatus == sessionStatus)&&(identical(other.sessionError, sessionError) || other.sessionError == sessionError)&&(identical(other.playbackStatus, playbackStatus) || other.playbackStatus == playbackStatus)&&(identical(other.playbackError, playbackError) || other.playbackError == playbackError)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,sessionState,activeDevice,activeMedia,sessionStatus,sessionError,playbackStatus,playbackError,position,duration,volume);

@override
String toString() {
  return 'CastSessionState(sessionState: $sessionState, activeDevice: $activeDevice, activeMedia: $activeMedia, sessionStatus: $sessionStatus, sessionError: $sessionError, playbackStatus: $playbackStatus, playbackError: $playbackError, position: $position, duration: $duration, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$CastSessionStateCopyWith<$Res> implements $CastSessionStateCopyWith<$Res> {
  factory _$CastSessionStateCopyWith(_CastSessionState value, $Res Function(_CastSessionState) _then) = __$CastSessionStateCopyWithImpl;
@override @useResult
$Res call({
 PureCastSessionState sessionState, PureCastDevice? activeDevice, PureCastMedia? activeMedia, StateStatus sessionStatus, String? sessionError, StateStatus playbackStatus, String? playbackError, Duration position, Duration duration, double volume
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
@override @pragma('vm:prefer-inline') $Res call({Object? sessionState = null,Object? activeDevice = freezed,Object? activeMedia = freezed,Object? sessionStatus = null,Object? sessionError = freezed,Object? playbackStatus = null,Object? playbackError = freezed,Object? position = null,Object? duration = null,Object? volume = null,}) {
  return _then(_CastSessionState(
sessionState: null == sessionState ? _self.sessionState : sessionState // ignore: cast_nullable_to_non_nullable
as PureCastSessionState,activeDevice: freezed == activeDevice ? _self.activeDevice : activeDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,activeMedia: freezed == activeMedia ? _self.activeMedia : activeMedia // ignore: cast_nullable_to_non_nullable
as PureCastMedia?,sessionStatus: null == sessionStatus ? _self.sessionStatus : sessionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,sessionError: freezed == sessionError ? _self.sessionError : sessionError // ignore: cast_nullable_to_non_nullable
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
