// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cast_discovery_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CastDiscoveryEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastDiscoveryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastDiscoveryEvent()';
}


}

/// @nodoc
class $CastDiscoveryEventCopyWith<$Res>  {
$CastDiscoveryEventCopyWith(CastDiscoveryEvent _, $Res Function(CastDiscoveryEvent) __);
}


/// Adds pattern-matching-related methods to [CastDiscoveryEvent].
extension CastDiscoveryEventPatterns on CastDiscoveryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StartDiscoveryEvent value)?  startDiscovery,TResult Function( StopDiscoveryEvent value)?  stopDiscovery,TResult Function( RefreshDiscoveryEvent value)?  refreshDiscovery,TResult Function( DevicesUpdatedEvent value)?  devicesUpdated,TResult Function( DiscoveryErrorEvent value)?  discoveryError,TResult Function( SelectDeviceEvent value)?  selectDevice,TResult Function( ConnectToDeviceEvent value)?  connectToDevice,TResult Function( DisconnectDeviceEvent value)?  disconnectDevice,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StartDiscoveryEvent() when startDiscovery != null:
return startDiscovery(_that);case StopDiscoveryEvent() when stopDiscovery != null:
return stopDiscovery(_that);case RefreshDiscoveryEvent() when refreshDiscovery != null:
return refreshDiscovery(_that);case DevicesUpdatedEvent() when devicesUpdated != null:
return devicesUpdated(_that);case DiscoveryErrorEvent() when discoveryError != null:
return discoveryError(_that);case SelectDeviceEvent() when selectDevice != null:
return selectDevice(_that);case ConnectToDeviceEvent() when connectToDevice != null:
return connectToDevice(_that);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StartDiscoveryEvent value)  startDiscovery,required TResult Function( StopDiscoveryEvent value)  stopDiscovery,required TResult Function( RefreshDiscoveryEvent value)  refreshDiscovery,required TResult Function( DevicesUpdatedEvent value)  devicesUpdated,required TResult Function( DiscoveryErrorEvent value)  discoveryError,required TResult Function( SelectDeviceEvent value)  selectDevice,required TResult Function( ConnectToDeviceEvent value)  connectToDevice,required TResult Function( DisconnectDeviceEvent value)  disconnectDevice,}){
final _that = this;
switch (_that) {
case StartDiscoveryEvent():
return startDiscovery(_that);case StopDiscoveryEvent():
return stopDiscovery(_that);case RefreshDiscoveryEvent():
return refreshDiscovery(_that);case DevicesUpdatedEvent():
return devicesUpdated(_that);case DiscoveryErrorEvent():
return discoveryError(_that);case SelectDeviceEvent():
return selectDevice(_that);case ConnectToDeviceEvent():
return connectToDevice(_that);case DisconnectDeviceEvent():
return disconnectDevice(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StartDiscoveryEvent value)?  startDiscovery,TResult? Function( StopDiscoveryEvent value)?  stopDiscovery,TResult? Function( RefreshDiscoveryEvent value)?  refreshDiscovery,TResult? Function( DevicesUpdatedEvent value)?  devicesUpdated,TResult? Function( DiscoveryErrorEvent value)?  discoveryError,TResult? Function( SelectDeviceEvent value)?  selectDevice,TResult? Function( ConnectToDeviceEvent value)?  connectToDevice,TResult? Function( DisconnectDeviceEvent value)?  disconnectDevice,}){
final _that = this;
switch (_that) {
case StartDiscoveryEvent() when startDiscovery != null:
return startDiscovery(_that);case StopDiscoveryEvent() when stopDiscovery != null:
return stopDiscovery(_that);case RefreshDiscoveryEvent() when refreshDiscovery != null:
return refreshDiscovery(_that);case DevicesUpdatedEvent() when devicesUpdated != null:
return devicesUpdated(_that);case DiscoveryErrorEvent() when discoveryError != null:
return discoveryError(_that);case SelectDeviceEvent() when selectDevice != null:
return selectDevice(_that);case ConnectToDeviceEvent() when connectToDevice != null:
return connectToDevice(_that);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Set<PureCastProtocol>? protocols)?  startDiscovery,TResult Function()?  stopDiscovery,TResult Function()?  refreshDiscovery,TResult Function( List<PureCastDevice> devices)?  devicesUpdated,TResult Function( String message)?  discoveryError,TResult Function( PureCastDevice device)?  selectDevice,TResult Function( PureCastDevice device)?  connectToDevice,TResult Function()?  disconnectDevice,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StartDiscoveryEvent() when startDiscovery != null:
return startDiscovery(_that.protocols);case StopDiscoveryEvent() when stopDiscovery != null:
return stopDiscovery();case RefreshDiscoveryEvent() when refreshDiscovery != null:
return refreshDiscovery();case DevicesUpdatedEvent() when devicesUpdated != null:
return devicesUpdated(_that.devices);case DiscoveryErrorEvent() when discoveryError != null:
return discoveryError(_that.message);case SelectDeviceEvent() when selectDevice != null:
return selectDevice(_that.device);case ConnectToDeviceEvent() when connectToDevice != null:
return connectToDevice(_that.device);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Set<PureCastProtocol>? protocols)  startDiscovery,required TResult Function()  stopDiscovery,required TResult Function()  refreshDiscovery,required TResult Function( List<PureCastDevice> devices)  devicesUpdated,required TResult Function( String message)  discoveryError,required TResult Function( PureCastDevice device)  selectDevice,required TResult Function( PureCastDevice device)  connectToDevice,required TResult Function()  disconnectDevice,}) {final _that = this;
switch (_that) {
case StartDiscoveryEvent():
return startDiscovery(_that.protocols);case StopDiscoveryEvent():
return stopDiscovery();case RefreshDiscoveryEvent():
return refreshDiscovery();case DevicesUpdatedEvent():
return devicesUpdated(_that.devices);case DiscoveryErrorEvent():
return discoveryError(_that.message);case SelectDeviceEvent():
return selectDevice(_that.device);case ConnectToDeviceEvent():
return connectToDevice(_that.device);case DisconnectDeviceEvent():
return disconnectDevice();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Set<PureCastProtocol>? protocols)?  startDiscovery,TResult? Function()?  stopDiscovery,TResult? Function()?  refreshDiscovery,TResult? Function( List<PureCastDevice> devices)?  devicesUpdated,TResult? Function( String message)?  discoveryError,TResult? Function( PureCastDevice device)?  selectDevice,TResult? Function( PureCastDevice device)?  connectToDevice,TResult? Function()?  disconnectDevice,}) {final _that = this;
switch (_that) {
case StartDiscoveryEvent() when startDiscovery != null:
return startDiscovery(_that.protocols);case StopDiscoveryEvent() when stopDiscovery != null:
return stopDiscovery();case RefreshDiscoveryEvent() when refreshDiscovery != null:
return refreshDiscovery();case DevicesUpdatedEvent() when devicesUpdated != null:
return devicesUpdated(_that.devices);case DiscoveryErrorEvent() when discoveryError != null:
return discoveryError(_that.message);case SelectDeviceEvent() when selectDevice != null:
return selectDevice(_that.device);case ConnectToDeviceEvent() when connectToDevice != null:
return connectToDevice(_that.device);case DisconnectDeviceEvent() when disconnectDevice != null:
return disconnectDevice();case _:
  return null;

}
}

}

/// @nodoc


class StartDiscoveryEvent implements CastDiscoveryEvent {
  const StartDiscoveryEvent({ Set<PureCastProtocol>? protocols}): _protocols = protocols;
  

 final  Set<PureCastProtocol>? _protocols;
 Set<PureCastProtocol>? get protocols {
  final value = _protocols;
  if (value == null) return null;
  if (_protocols is EqualUnmodifiableSetView) return _protocols;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}


/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartDiscoveryEventCopyWith<StartDiscoveryEvent> get copyWith => _$StartDiscoveryEventCopyWithImpl<StartDiscoveryEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartDiscoveryEvent&&const DeepCollectionEquality().equals(other._protocols, _protocols));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_protocols));

@override
String toString() {
  return 'CastDiscoveryEvent.startDiscovery(protocols: $protocols)';
}


}

/// @nodoc
abstract mixin class $StartDiscoveryEventCopyWith<$Res> implements $CastDiscoveryEventCopyWith<$Res> {
  factory $StartDiscoveryEventCopyWith(StartDiscoveryEvent value, $Res Function(StartDiscoveryEvent) _then) = _$StartDiscoveryEventCopyWithImpl;
@useResult
$Res call({
 Set<PureCastProtocol>? protocols
});




}
/// @nodoc
class _$StartDiscoveryEventCopyWithImpl<$Res>
    implements $StartDiscoveryEventCopyWith<$Res> {
  _$StartDiscoveryEventCopyWithImpl(this._self, this._then);

  final StartDiscoveryEvent _self;
  final $Res Function(StartDiscoveryEvent) _then;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? protocols = freezed,}) {
  return _then(StartDiscoveryEvent(
protocols: freezed == protocols ? _self._protocols : protocols // ignore: cast_nullable_to_non_nullable
as Set<PureCastProtocol>?,
  ));
}


}

/// @nodoc


class StopDiscoveryEvent implements CastDiscoveryEvent {
  const StopDiscoveryEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopDiscoveryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastDiscoveryEvent.stopDiscovery()';
}


}




/// @nodoc


class RefreshDiscoveryEvent implements CastDiscoveryEvent {
  const RefreshDiscoveryEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshDiscoveryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastDiscoveryEvent.refreshDiscovery()';
}


}




/// @nodoc


class DevicesUpdatedEvent implements CastDiscoveryEvent {
  const DevicesUpdatedEvent( List<PureCastDevice> devices): _devices = devices;
  

 final  List<PureCastDevice> _devices;
 List<PureCastDevice> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}


/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DevicesUpdatedEventCopyWith<DevicesUpdatedEvent> get copyWith => _$DevicesUpdatedEventCopyWithImpl<DevicesUpdatedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicesUpdatedEvent&&const DeepCollectionEquality().equals(other._devices, _devices));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_devices));

@override
String toString() {
  return 'CastDiscoveryEvent.devicesUpdated(devices: $devices)';
}


}

/// @nodoc
abstract mixin class $DevicesUpdatedEventCopyWith<$Res> implements $CastDiscoveryEventCopyWith<$Res> {
  factory $DevicesUpdatedEventCopyWith(DevicesUpdatedEvent value, $Res Function(DevicesUpdatedEvent) _then) = _$DevicesUpdatedEventCopyWithImpl;
@useResult
$Res call({
 List<PureCastDevice> devices
});




}
/// @nodoc
class _$DevicesUpdatedEventCopyWithImpl<$Res>
    implements $DevicesUpdatedEventCopyWith<$Res> {
  _$DevicesUpdatedEventCopyWithImpl(this._self, this._then);

  final DevicesUpdatedEvent _self;
  final $Res Function(DevicesUpdatedEvent) _then;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? devices = null,}) {
  return _then(DevicesUpdatedEvent(
null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<PureCastDevice>,
  ));
}


}

/// @nodoc


class DiscoveryErrorEvent implements CastDiscoveryEvent {
  const DiscoveryErrorEvent(this.message);
  

 final  String message;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryErrorEventCopyWith<DiscoveryErrorEvent> get copyWith => _$DiscoveryErrorEventCopyWithImpl<DiscoveryErrorEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryErrorEvent&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CastDiscoveryEvent.discoveryError(message: $message)';
}


}

/// @nodoc
abstract mixin class $DiscoveryErrorEventCopyWith<$Res> implements $CastDiscoveryEventCopyWith<$Res> {
  factory $DiscoveryErrorEventCopyWith(DiscoveryErrorEvent value, $Res Function(DiscoveryErrorEvent) _then) = _$DiscoveryErrorEventCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DiscoveryErrorEventCopyWithImpl<$Res>
    implements $DiscoveryErrorEventCopyWith<$Res> {
  _$DiscoveryErrorEventCopyWithImpl(this._self, this._then);

  final DiscoveryErrorEvent _self;
  final $Res Function(DiscoveryErrorEvent) _then;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DiscoveryErrorEvent(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SelectDeviceEvent implements CastDiscoveryEvent {
  const SelectDeviceEvent(this.device);
  

 final  PureCastDevice device;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectDeviceEventCopyWith<SelectDeviceEvent> get copyWith => _$SelectDeviceEventCopyWithImpl<SelectDeviceEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectDeviceEvent&&(identical(other.device, device) || other.device == device));
}


@override
int get hashCode => Object.hash(runtimeType,device);

@override
String toString() {
  return 'CastDiscoveryEvent.selectDevice(device: $device)';
}


}

/// @nodoc
abstract mixin class $SelectDeviceEventCopyWith<$Res> implements $CastDiscoveryEventCopyWith<$Res> {
  factory $SelectDeviceEventCopyWith(SelectDeviceEvent value, $Res Function(SelectDeviceEvent) _then) = _$SelectDeviceEventCopyWithImpl;
@useResult
$Res call({
 PureCastDevice device
});




}
/// @nodoc
class _$SelectDeviceEventCopyWithImpl<$Res>
    implements $SelectDeviceEventCopyWith<$Res> {
  _$SelectDeviceEventCopyWithImpl(this._self, this._then);

  final SelectDeviceEvent _self;
  final $Res Function(SelectDeviceEvent) _then;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? device = null,}) {
  return _then(SelectDeviceEvent(
null == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as PureCastDevice,
  ));
}


}

/// @nodoc


class ConnectToDeviceEvent implements CastDiscoveryEvent {
  const ConnectToDeviceEvent(this.device);
  

 final  PureCastDevice device;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectToDeviceEventCopyWith<ConnectToDeviceEvent> get copyWith => _$ConnectToDeviceEventCopyWithImpl<ConnectToDeviceEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectToDeviceEvent&&(identical(other.device, device) || other.device == device));
}


@override
int get hashCode => Object.hash(runtimeType,device);

@override
String toString() {
  return 'CastDiscoveryEvent.connectToDevice(device: $device)';
}


}

/// @nodoc
abstract mixin class $ConnectToDeviceEventCopyWith<$Res> implements $CastDiscoveryEventCopyWith<$Res> {
  factory $ConnectToDeviceEventCopyWith(ConnectToDeviceEvent value, $Res Function(ConnectToDeviceEvent) _then) = _$ConnectToDeviceEventCopyWithImpl;
@useResult
$Res call({
 PureCastDevice device
});




}
/// @nodoc
class _$ConnectToDeviceEventCopyWithImpl<$Res>
    implements $ConnectToDeviceEventCopyWith<$Res> {
  _$ConnectToDeviceEventCopyWithImpl(this._self, this._then);

  final ConnectToDeviceEvent _self;
  final $Res Function(ConnectToDeviceEvent) _then;

/// Create a copy of CastDiscoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? device = null,}) {
  return _then(ConnectToDeviceEvent(
null == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as PureCastDevice,
  ));
}


}

/// @nodoc


class DisconnectDeviceEvent implements CastDiscoveryEvent {
  const DisconnectDeviceEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisconnectDeviceEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CastDiscoveryEvent.disconnectDevice()';
}


}




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
