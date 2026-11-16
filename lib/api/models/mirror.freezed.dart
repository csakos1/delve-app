// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mirror.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MirrorStatus {

 DeskLink get desk;
/// Create a copy of MirrorStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MirrorStatusCopyWith<MirrorStatus> get copyWith => _$MirrorStatusCopyWithImpl<MirrorStatus>(this as MirrorStatus, _$identity);

  /// Serializes this MirrorStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MirrorStatus&&(identical(other.desk, desk) || other.desk == desk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,desk);

@override
String toString() {
  return 'MirrorStatus(desk: $desk)';
}


}

/// @nodoc
abstract mixin class $MirrorStatusCopyWith<$Res>  {
  factory $MirrorStatusCopyWith(MirrorStatus value, $Res Function(MirrorStatus) _then) = _$MirrorStatusCopyWithImpl;
@useResult
$Res call({
 DeskLink desk
});


$DeskLinkCopyWith<$Res> get desk;

}
/// @nodoc
class _$MirrorStatusCopyWithImpl<$Res>
    implements $MirrorStatusCopyWith<$Res> {
  _$MirrorStatusCopyWithImpl(this._self, this._then);

  final MirrorStatus _self;
  final $Res Function(MirrorStatus) _then;

/// Create a copy of MirrorStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? desk = null,}) {
  return _then(_self.copyWith(
desk: null == desk ? _self.desk : desk // ignore: cast_nullable_to_non_nullable
as DeskLink,
  ));
}
/// Create a copy of MirrorStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeskLinkCopyWith<$Res> get desk {
  
  return $DeskLinkCopyWith<$Res>(_self.desk, (value) {
    return _then(_self.copyWith(desk: value));
  });
}
}


/// Adds pattern-matching-related methods to [MirrorStatus].
extension MirrorStatusPatterns on MirrorStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MirrorStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MirrorStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MirrorStatus value)  $default,){
final _that = this;
switch (_that) {
case _MirrorStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MirrorStatus value)?  $default,){
final _that = this;
switch (_that) {
case _MirrorStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeskLink desk)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MirrorStatus() when $default != null:
return $default(_that.desk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeskLink desk)  $default,) {final _that = this;
switch (_that) {
case _MirrorStatus():
return $default(_that.desk);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeskLink desk)?  $default,) {final _that = this;
switch (_that) {
case _MirrorStatus() when $default != null:
return $default(_that.desk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MirrorStatus implements MirrorStatus {
  const _MirrorStatus({required this.desk});
  factory _MirrorStatus.fromJson(Map<String, dynamic> json) => _$MirrorStatusFromJson(json);

@override final  DeskLink desk;

/// Create a copy of MirrorStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MirrorStatusCopyWith<_MirrorStatus> get copyWith => __$MirrorStatusCopyWithImpl<_MirrorStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MirrorStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MirrorStatus&&(identical(other.desk, desk) || other.desk == desk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,desk);

@override
String toString() {
  return 'MirrorStatus(desk: $desk)';
}


}

/// @nodoc
abstract mixin class _$MirrorStatusCopyWith<$Res> implements $MirrorStatusCopyWith<$Res> {
  factory _$MirrorStatusCopyWith(_MirrorStatus value, $Res Function(_MirrorStatus) _then) = __$MirrorStatusCopyWithImpl;
@override @useResult
$Res call({
 DeskLink desk
});


@override $DeskLinkCopyWith<$Res> get desk;

}
/// @nodoc
class __$MirrorStatusCopyWithImpl<$Res>
    implements _$MirrorStatusCopyWith<$Res> {
  __$MirrorStatusCopyWithImpl(this._self, this._then);

  final _MirrorStatus _self;
  final $Res Function(_MirrorStatus) _then;

/// Create a copy of MirrorStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? desk = null,}) {
  return _then(_MirrorStatus(
desk: null == desk ? _self.desk : desk // ignore: cast_nullable_to_non_nullable
as DeskLink,
  ));
}

/// Create a copy of MirrorStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeskLinkCopyWith<$Res> get desk {
  
  return $DeskLinkCopyWith<$Res>(_self.desk, (value) {
    return _then(_self.copyWith(desk: value));
  });
}
}


/// @nodoc
mixin _$DeskLink {

 bool get connected; int? get lastSeenS;
/// Create a copy of DeskLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeskLinkCopyWith<DeskLink> get copyWith => _$DeskLinkCopyWithImpl<DeskLink>(this as DeskLink, _$identity);

  /// Serializes this DeskLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeskLink&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.lastSeenS, lastSeenS) || other.lastSeenS == lastSeenS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connected,lastSeenS);

@override
String toString() {
  return 'DeskLink(connected: $connected, lastSeenS: $lastSeenS)';
}


}

/// @nodoc
abstract mixin class $DeskLinkCopyWith<$Res>  {
  factory $DeskLinkCopyWith(DeskLink value, $Res Function(DeskLink) _then) = _$DeskLinkCopyWithImpl;
@useResult
$Res call({
 bool connected, int? lastSeenS
});




}
/// @nodoc
class _$DeskLinkCopyWithImpl<$Res>
    implements $DeskLinkCopyWith<$Res> {
  _$DeskLinkCopyWithImpl(this._self, this._then);

  final DeskLink _self;
  final $Res Function(DeskLink) _then;

/// Create a copy of DeskLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connected = null,Object? lastSeenS = freezed,}) {
  return _then(_self.copyWith(
connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,lastSeenS: freezed == lastSeenS ? _self.lastSeenS : lastSeenS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeskLink].
extension DeskLinkPatterns on DeskLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeskLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeskLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeskLink value)  $default,){
final _that = this;
switch (_that) {
case _DeskLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeskLink value)?  $default,){
final _that = this;
switch (_that) {
case _DeskLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool connected,  int? lastSeenS)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeskLink() when $default != null:
return $default(_that.connected,_that.lastSeenS);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool connected,  int? lastSeenS)  $default,) {final _that = this;
switch (_that) {
case _DeskLink():
return $default(_that.connected,_that.lastSeenS);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool connected,  int? lastSeenS)?  $default,) {final _that = this;
switch (_that) {
case _DeskLink() when $default != null:
return $default(_that.connected,_that.lastSeenS);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeskLink implements DeskLink {
  const _DeskLink({required this.connected, this.lastSeenS});
  factory _DeskLink.fromJson(Map<String, dynamic> json) => _$DeskLinkFromJson(json);

@override final  bool connected;
@override final  int? lastSeenS;

/// Create a copy of DeskLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeskLinkCopyWith<_DeskLink> get copyWith => __$DeskLinkCopyWithImpl<_DeskLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeskLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeskLink&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.lastSeenS, lastSeenS) || other.lastSeenS == lastSeenS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connected,lastSeenS);

@override
String toString() {
  return 'DeskLink(connected: $connected, lastSeenS: $lastSeenS)';
}


}

/// @nodoc
abstract mixin class _$DeskLinkCopyWith<$Res> implements $DeskLinkCopyWith<$Res> {
  factory _$DeskLinkCopyWith(_DeskLink value, $Res Function(_DeskLink) _then) = __$DeskLinkCopyWithImpl;
@override @useResult
$Res call({
 bool connected, int? lastSeenS
});




}
/// @nodoc
class __$DeskLinkCopyWithImpl<$Res>
    implements _$DeskLinkCopyWith<$Res> {
  __$DeskLinkCopyWithImpl(this._self, this._then);

  final _DeskLink _self;
  final $Res Function(_DeskLink) _then;

/// Create a copy of DeskLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connected = null,Object? lastSeenS = freezed,}) {
  return _then(_DeskLink(
connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,lastSeenS: freezed == lastSeenS ? _self.lastSeenS : lastSeenS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
