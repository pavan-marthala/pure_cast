// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cast_discovery_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CastDiscoveryState {

 List<PureCastDevice> get devices; StateStatus get discoveryStatus; String? get discoveryError; PureCastDevice? get selectedDevice; StateStatus get connectionStatus; String? get connectionError;
/// Create a copy of CastDiscoveryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CastDiscoveryStateCopyWith<CastDiscoveryState> get copyWith => _$CastDiscoveryStateCopyWithImpl<CastDiscoveryState>(this as CastDiscoveryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastDiscoveryState&&const DeepCollectionEquality().equals(other.devices, devices)&&(identical(other.discoveryStatus, discoveryStatus) || other.discoveryStatus == discoveryStatus)&&(identical(other.discoveryError, discoveryError) || other.discoveryError == discoveryError)&&(identical(other.selectedDevice, selectedDevice) || other.selectedDevice == selectedDevice)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&(identical(other.connectionError, connectionError) || other.connectionError == connectionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(devices),discoveryStatus,discoveryError,selectedDevice,connectionStatus,connectionError);

@override
String toString() {
  return 'CastDiscoveryState(devices: $devices, discoveryStatus: $discoveryStatus, discoveryError: $discoveryError, selectedDevice: $selectedDevice, connectionStatus: $connectionStatus, connectionError: $connectionError)';
}


}

/// @nodoc
abstract mixin class $CastDiscoveryStateCopyWith<$Res>  {
  factory $CastDiscoveryStateCopyWith(CastDiscoveryState value, $Res Function(CastDiscoveryState) _then) = _$CastDiscoveryStateCopyWithImpl;
@useResult
$Res call({
 List<PureCastDevice> devices, StateStatus discoveryStatus, String? discoveryError, PureCastDevice? selectedDevice, StateStatus connectionStatus, String? connectionError
});




}
/// @nodoc
class _$CastDiscoveryStateCopyWithImpl<$Res>
    implements $CastDiscoveryStateCopyWith<$Res> {
  _$CastDiscoveryStateCopyWithImpl(this._self, this._then);

  final CastDiscoveryState _self;
  final $Res Function(CastDiscoveryState) _then;

/// Create a copy of CastDiscoveryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? devices = null,Object? discoveryStatus = null,Object? discoveryError = freezed,Object? selectedDevice = freezed,Object? connectionStatus = null,Object? connectionError = freezed,}) {
  return _then(CastDiscoveryState(
devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<PureCastDevice>,discoveryStatus: null == discoveryStatus ? _self.discoveryStatus : discoveryStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,discoveryError: freezed == discoveryError ? _self.discoveryError : discoveryError // ignore: cast_nullable_to_non_nullable
as String?,selectedDevice: freezed == selectedDevice ? _self.selectedDevice : selectedDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,connectionError: freezed == connectionError ? _self.connectionError : connectionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CastDiscoveryState].
extension CastDiscoveryStatePatterns on CastDiscoveryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CastDiscoveryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CastDiscoveryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CastDiscoveryState value)  $default,){
final _that = this;
switch (_that) {
case _CastDiscoveryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CastDiscoveryState value)?  $default,){
final _that = this;
switch (_that) {
case _CastDiscoveryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PureCastDevice> devices,  StateStatus discoveryStatus,  String? discoveryError,  PureCastDevice? selectedDevice,  StateStatus connectionStatus,  String? connectionError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CastDiscoveryState() when $default != null:
return $default(_that.devices,_that.discoveryStatus,_that.discoveryError,_that.selectedDevice,_that.connectionStatus,_that.connectionError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PureCastDevice> devices,  StateStatus discoveryStatus,  String? discoveryError,  PureCastDevice? selectedDevice,  StateStatus connectionStatus,  String? connectionError)  $default,) {final _that = this;
switch (_that) {
case _CastDiscoveryState():
return $default(_that.devices,_that.discoveryStatus,_that.discoveryError,_that.selectedDevice,_that.connectionStatus,_that.connectionError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PureCastDevice> devices,  StateStatus discoveryStatus,  String? discoveryError,  PureCastDevice? selectedDevice,  StateStatus connectionStatus,  String? connectionError)?  $default,) {final _that = this;
switch (_that) {
case _CastDiscoveryState() when $default != null:
return $default(_that.devices,_that.discoveryStatus,_that.discoveryError,_that.selectedDevice,_that.connectionStatus,_that.connectionError);case _:
  return null;

}
}

}

/// @nodoc


class _CastDiscoveryState implements CastDiscoveryState {
  const _CastDiscoveryState({ List<PureCastDevice> devices = const [], this.discoveryStatus = StateStatus.initial, this.discoveryError, this.selectedDevice, this.connectionStatus = StateStatus.initial, this.connectionError}): _devices = devices;
  

 final  List<PureCastDevice> _devices;
@override@JsonKey() List<PureCastDevice> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}

@override@JsonKey() final  StateStatus discoveryStatus;
@override final  String? discoveryError;
@override final  PureCastDevice? selectedDevice;
@override@JsonKey() final  StateStatus connectionStatus;
@override final  String? connectionError;

/// Create a copy of CastDiscoveryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CastDiscoveryStateCopyWith<_CastDiscoveryState> get copyWith => __$CastDiscoveryStateCopyWithImpl<_CastDiscoveryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CastDiscoveryState&&const DeepCollectionEquality().equals(other._devices, _devices)&&(identical(other.discoveryStatus, discoveryStatus) || other.discoveryStatus == discoveryStatus)&&(identical(other.discoveryError, discoveryError) || other.discoveryError == discoveryError)&&(identical(other.selectedDevice, selectedDevice) || other.selectedDevice == selectedDevice)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&(identical(other.connectionError, connectionError) || other.connectionError == connectionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_devices),discoveryStatus,discoveryError,selectedDevice,connectionStatus,connectionError);

@override
String toString() {
  return 'CastDiscoveryState(devices: $devices, discoveryStatus: $discoveryStatus, discoveryError: $discoveryError, selectedDevice: $selectedDevice, connectionStatus: $connectionStatus, connectionError: $connectionError)';
}


}

/// @nodoc
abstract mixin class _$CastDiscoveryStateCopyWith<$Res> implements $CastDiscoveryStateCopyWith<$Res> {
  factory _$CastDiscoveryStateCopyWith(_CastDiscoveryState value, $Res Function(_CastDiscoveryState) _then) = __$CastDiscoveryStateCopyWithImpl;
@override @useResult
$Res call({
 List<PureCastDevice> devices, StateStatus discoveryStatus, String? discoveryError, PureCastDevice? selectedDevice, StateStatus connectionStatus, String? connectionError
});




}
/// @nodoc
class __$CastDiscoveryStateCopyWithImpl<$Res>
    implements _$CastDiscoveryStateCopyWith<$Res> {
  __$CastDiscoveryStateCopyWithImpl(this._self, this._then);

  final _CastDiscoveryState _self;
  final $Res Function(_CastDiscoveryState) _then;

/// Create a copy of CastDiscoveryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? devices = null,Object? discoveryStatus = null,Object? discoveryError = freezed,Object? selectedDevice = freezed,Object? connectionStatus = null,Object? connectionError = freezed,}) {
  return _then(_CastDiscoveryState(
devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<PureCastDevice>,discoveryStatus: null == discoveryStatus ? _self.discoveryStatus : discoveryStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,discoveryError: freezed == discoveryError ? _self.discoveryError : discoveryError // ignore: cast_nullable_to_non_nullable
as String?,selectedDevice: freezed == selectedDevice ? _self.selectedDevice : selectedDevice // ignore: cast_nullable_to_non_nullable
as PureCastDevice?,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as StateStatus,connectionError: freezed == connectionError ? _self.connectionError : connectionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
