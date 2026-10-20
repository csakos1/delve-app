// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerMeta {

 String get serverVersion; int get apiRevision; String? get revision; String? get hermesExpectedVersion; int? get approvalTimeoutS;
/// Create a copy of ServerMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerMetaCopyWith<ServerMeta> get copyWith => _$ServerMetaCopyWithImpl<ServerMeta>(this as ServerMeta, _$identity);

  /// Serializes this ServerMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerMeta&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.apiRevision, apiRevision) || other.apiRevision == apiRevision)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.hermesExpectedVersion, hermesExpectedVersion) || other.hermesExpectedVersion == hermesExpectedVersion)&&(identical(other.approvalTimeoutS, approvalTimeoutS) || other.approvalTimeoutS == approvalTimeoutS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverVersion,apiRevision,revision,hermesExpectedVersion,approvalTimeoutS);

@override
String toString() {
  return 'ServerMeta(serverVersion: $serverVersion, apiRevision: $apiRevision, revision: $revision, hermesExpectedVersion: $hermesExpectedVersion, approvalTimeoutS: $approvalTimeoutS)';
}


}

/// @nodoc
abstract mixin class $ServerMetaCopyWith<$Res>  {
  factory $ServerMetaCopyWith(ServerMeta value, $Res Function(ServerMeta) _then) = _$ServerMetaCopyWithImpl;
@useResult
$Res call({
 String serverVersion, int apiRevision, String? revision, String? hermesExpectedVersion, int? approvalTimeoutS
});




}
/// @nodoc
class _$ServerMetaCopyWithImpl<$Res>
    implements $ServerMetaCopyWith<$Res> {
  _$ServerMetaCopyWithImpl(this._self, this._then);

  final ServerMeta _self;
  final $Res Function(ServerMeta) _then;

/// Create a copy of ServerMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverVersion = null,Object? apiRevision = null,Object? revision = freezed,Object? hermesExpectedVersion = freezed,Object? approvalTimeoutS = freezed,}) {
  return _then(_self.copyWith(
serverVersion: null == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String,apiRevision: null == apiRevision ? _self.apiRevision : apiRevision // ignore: cast_nullable_to_non_nullable
as int,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,hermesExpectedVersion: freezed == hermesExpectedVersion ? _self.hermesExpectedVersion : hermesExpectedVersion // ignore: cast_nullable_to_non_nullable
as String?,approvalTimeoutS: freezed == approvalTimeoutS ? _self.approvalTimeoutS : approvalTimeoutS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerMeta].
extension ServerMetaPatterns on ServerMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerMeta value)  $default,){
final _that = this;
switch (_that) {
case _ServerMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerMeta value)?  $default,){
final _that = this;
switch (_that) {
case _ServerMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverVersion,  int apiRevision,  String? revision,  String? hermesExpectedVersion,  int? approvalTimeoutS)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerMeta() when $default != null:
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermesExpectedVersion,_that.approvalTimeoutS);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverVersion,  int apiRevision,  String? revision,  String? hermesExpectedVersion,  int? approvalTimeoutS)  $default,) {final _that = this;
switch (_that) {
case _ServerMeta():
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermesExpectedVersion,_that.approvalTimeoutS);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverVersion,  int apiRevision,  String? revision,  String? hermesExpectedVersion,  int? approvalTimeoutS)?  $default,) {final _that = this;
switch (_that) {
case _ServerMeta() when $default != null:
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermesExpectedVersion,_that.approvalTimeoutS);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerMeta implements ServerMeta {
  const _ServerMeta({required this.serverVersion, required this.apiRevision, this.revision, this.hermesExpectedVersion, this.approvalTimeoutS});
  factory _ServerMeta.fromJson(Map<String, dynamic> json) => _$ServerMetaFromJson(json);

@override final  String serverVersion;
@override final  int apiRevision;
@override final  String? revision;
@override final  String? hermesExpectedVersion;
@override final  int? approvalTimeoutS;

/// Create a copy of ServerMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerMetaCopyWith<_ServerMeta> get copyWith => __$ServerMetaCopyWithImpl<_ServerMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerMeta&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.apiRevision, apiRevision) || other.apiRevision == apiRevision)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.hermesExpectedVersion, hermesExpectedVersion) || other.hermesExpectedVersion == hermesExpectedVersion)&&(identical(other.approvalTimeoutS, approvalTimeoutS) || other.approvalTimeoutS == approvalTimeoutS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverVersion,apiRevision,revision,hermesExpectedVersion,approvalTimeoutS);

@override
String toString() {
  return 'ServerMeta(serverVersion: $serverVersion, apiRevision: $apiRevision, revision: $revision, hermesExpectedVersion: $hermesExpectedVersion, approvalTimeoutS: $approvalTimeoutS)';
}


}

/// @nodoc
abstract mixin class _$ServerMetaCopyWith<$Res> implements $ServerMetaCopyWith<$Res> {
  factory _$ServerMetaCopyWith(_ServerMeta value, $Res Function(_ServerMeta) _then) = __$ServerMetaCopyWithImpl;
@override @useResult
$Res call({
 String serverVersion, int apiRevision, String? revision, String? hermesExpectedVersion, int? approvalTimeoutS
});




}
/// @nodoc
class __$ServerMetaCopyWithImpl<$Res>
    implements _$ServerMetaCopyWith<$Res> {
  __$ServerMetaCopyWithImpl(this._self, this._then);

  final _ServerMeta _self;
  final $Res Function(_ServerMeta) _then;

/// Create a copy of ServerMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverVersion = null,Object? apiRevision = null,Object? revision = freezed,Object? hermesExpectedVersion = freezed,Object? approvalTimeoutS = freezed,}) {
  return _then(_ServerMeta(
serverVersion: null == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String,apiRevision: null == apiRevision ? _self.apiRevision : apiRevision // ignore: cast_nullable_to_non_nullable
as int,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,hermesExpectedVersion: freezed == hermesExpectedVersion ? _self.hermesExpectedVersion : hermesExpectedVersion // ignore: cast_nullable_to_non_nullable
as String?,approvalTimeoutS: freezed == approvalTimeoutS ? _self.approvalTimeoutS : approvalTimeoutS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ThinkingRoute {

 bool get ok; String? get runId; DateTime? get at;
/// Create a copy of ThinkingRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThinkingRouteCopyWith<ThinkingRoute> get copyWith => _$ThinkingRouteCopyWithImpl<ThinkingRoute>(this as ThinkingRoute, _$identity);

  /// Serializes this ThinkingRoute to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThinkingRoute&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,runId,at);

@override
String toString() {
  return 'ThinkingRoute(ok: $ok, runId: $runId, at: $at)';
}


}

/// @nodoc
abstract mixin class $ThinkingRouteCopyWith<$Res>  {
  factory $ThinkingRouteCopyWith(ThinkingRoute value, $Res Function(ThinkingRoute) _then) = _$ThinkingRouteCopyWithImpl;
@useResult
$Res call({
 bool ok, String? runId, DateTime? at
});




}
/// @nodoc
class _$ThinkingRouteCopyWithImpl<$Res>
    implements $ThinkingRouteCopyWith<$Res> {
  _$ThinkingRouteCopyWithImpl(this._self, this._then);

  final ThinkingRoute _self;
  final $Res Function(ThinkingRoute) _then;

/// Create a copy of ThinkingRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? runId = freezed,Object? at = freezed,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ThinkingRoute].
extension ThinkingRoutePatterns on ThinkingRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThinkingRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThinkingRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThinkingRoute value)  $default,){
final _that = this;
switch (_that) {
case _ThinkingRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThinkingRoute value)?  $default,){
final _that = this;
switch (_that) {
case _ThinkingRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  String? runId,  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThinkingRoute() when $default != null:
return $default(_that.ok,_that.runId,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  String? runId,  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _ThinkingRoute():
return $default(_that.ok,_that.runId,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  String? runId,  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _ThinkingRoute() when $default != null:
return $default(_that.ok,_that.runId,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ThinkingRoute implements ThinkingRoute {
  const _ThinkingRoute({required this.ok, this.runId, this.at});
  factory _ThinkingRoute.fromJson(Map<String, dynamic> json) => _$ThinkingRouteFromJson(json);

@override final  bool ok;
@override final  String? runId;
@override final  DateTime? at;

/// Create a copy of ThinkingRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThinkingRouteCopyWith<_ThinkingRoute> get copyWith => __$ThinkingRouteCopyWithImpl<_ThinkingRoute>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ThinkingRouteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThinkingRoute&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,runId,at);

@override
String toString() {
  return 'ThinkingRoute(ok: $ok, runId: $runId, at: $at)';
}


}

/// @nodoc
abstract mixin class _$ThinkingRouteCopyWith<$Res> implements $ThinkingRouteCopyWith<$Res> {
  factory _$ThinkingRouteCopyWith(_ThinkingRoute value, $Res Function(_ThinkingRoute) _then) = __$ThinkingRouteCopyWithImpl;
@override @useResult
$Res call({
 bool ok, String? runId, DateTime? at
});




}
/// @nodoc
class __$ThinkingRouteCopyWithImpl<$Res>
    implements _$ThinkingRouteCopyWith<$Res> {
  __$ThinkingRouteCopyWithImpl(this._self, this._then);

  final _ThinkingRoute _self;
  final $Res Function(_ThinkingRoute) _then;

/// Create a copy of ThinkingRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? runId = freezed,Object? at = freezed,}) {
  return _then(_ThinkingRoute(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ServerStatus {

 String get serverVersion; int get apiRevision; String? get revision; String? get hermes; String? get hermesVersion; ThinkingRoute? get thinkingRoute;
/// Create a copy of ServerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerStatusCopyWith<ServerStatus> get copyWith => _$ServerStatusCopyWithImpl<ServerStatus>(this as ServerStatus, _$identity);

  /// Serializes this ServerStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerStatus&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.apiRevision, apiRevision) || other.apiRevision == apiRevision)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.hermes, hermes) || other.hermes == hermes)&&(identical(other.hermesVersion, hermesVersion) || other.hermesVersion == hermesVersion)&&(identical(other.thinkingRoute, thinkingRoute) || other.thinkingRoute == thinkingRoute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverVersion,apiRevision,revision,hermes,hermesVersion,thinkingRoute);

@override
String toString() {
  return 'ServerStatus(serverVersion: $serverVersion, apiRevision: $apiRevision, revision: $revision, hermes: $hermes, hermesVersion: $hermesVersion, thinkingRoute: $thinkingRoute)';
}


}

/// @nodoc
abstract mixin class $ServerStatusCopyWith<$Res>  {
  factory $ServerStatusCopyWith(ServerStatus value, $Res Function(ServerStatus) _then) = _$ServerStatusCopyWithImpl;
@useResult
$Res call({
 String serverVersion, int apiRevision, String? revision, String? hermes, String? hermesVersion, ThinkingRoute? thinkingRoute
});


$ThinkingRouteCopyWith<$Res>? get thinkingRoute;

}
/// @nodoc
class _$ServerStatusCopyWithImpl<$Res>
    implements $ServerStatusCopyWith<$Res> {
  _$ServerStatusCopyWithImpl(this._self, this._then);

  final ServerStatus _self;
  final $Res Function(ServerStatus) _then;

/// Create a copy of ServerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverVersion = null,Object? apiRevision = null,Object? revision = freezed,Object? hermes = freezed,Object? hermesVersion = freezed,Object? thinkingRoute = freezed,}) {
  return _then(_self.copyWith(
serverVersion: null == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String,apiRevision: null == apiRevision ? _self.apiRevision : apiRevision // ignore: cast_nullable_to_non_nullable
as int,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,hermes: freezed == hermes ? _self.hermes : hermes // ignore: cast_nullable_to_non_nullable
as String?,hermesVersion: freezed == hermesVersion ? _self.hermesVersion : hermesVersion // ignore: cast_nullable_to_non_nullable
as String?,thinkingRoute: freezed == thinkingRoute ? _self.thinkingRoute : thinkingRoute // ignore: cast_nullable_to_non_nullable
as ThinkingRoute?,
  ));
}
/// Create a copy of ServerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThinkingRouteCopyWith<$Res>? get thinkingRoute {
    if (_self.thinkingRoute == null) {
    return null;
  }

  return $ThinkingRouteCopyWith<$Res>(_self.thinkingRoute!, (value) {
    return _then(_self.copyWith(thinkingRoute: value));
  });
}
}


/// Adds pattern-matching-related methods to [ServerStatus].
extension ServerStatusPatterns on ServerStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerStatus value)  $default,){
final _that = this;
switch (_that) {
case _ServerStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ServerStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverVersion,  int apiRevision,  String? revision,  String? hermes,  String? hermesVersion,  ThinkingRoute? thinkingRoute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerStatus() when $default != null:
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermes,_that.hermesVersion,_that.thinkingRoute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverVersion,  int apiRevision,  String? revision,  String? hermes,  String? hermesVersion,  ThinkingRoute? thinkingRoute)  $default,) {final _that = this;
switch (_that) {
case _ServerStatus():
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermes,_that.hermesVersion,_that.thinkingRoute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverVersion,  int apiRevision,  String? revision,  String? hermes,  String? hermesVersion,  ThinkingRoute? thinkingRoute)?  $default,) {final _that = this;
switch (_that) {
case _ServerStatus() when $default != null:
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermes,_that.hermesVersion,_that.thinkingRoute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerStatus implements ServerStatus {
  const _ServerStatus({required this.serverVersion, required this.apiRevision, this.revision, this.hermes, this.hermesVersion, this.thinkingRoute});
  factory _ServerStatus.fromJson(Map<String, dynamic> json) => _$ServerStatusFromJson(json);

@override final  String serverVersion;
@override final  int apiRevision;
@override final  String? revision;
@override final  String? hermes;
@override final  String? hermesVersion;
@override final  ThinkingRoute? thinkingRoute;

/// Create a copy of ServerStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerStatusCopyWith<_ServerStatus> get copyWith => __$ServerStatusCopyWithImpl<_ServerStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerStatus&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.apiRevision, apiRevision) || other.apiRevision == apiRevision)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.hermes, hermes) || other.hermes == hermes)&&(identical(other.hermesVersion, hermesVersion) || other.hermesVersion == hermesVersion)&&(identical(other.thinkingRoute, thinkingRoute) || other.thinkingRoute == thinkingRoute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverVersion,apiRevision,revision,hermes,hermesVersion,thinkingRoute);

@override
String toString() {
  return 'ServerStatus(serverVersion: $serverVersion, apiRevision: $apiRevision, revision: $revision, hermes: $hermes, hermesVersion: $hermesVersion, thinkingRoute: $thinkingRoute)';
}


}

/// @nodoc
abstract mixin class _$ServerStatusCopyWith<$Res> implements $ServerStatusCopyWith<$Res> {
  factory _$ServerStatusCopyWith(_ServerStatus value, $Res Function(_ServerStatus) _then) = __$ServerStatusCopyWithImpl;
@override @useResult
$Res call({
 String serverVersion, int apiRevision, String? revision, String? hermes, String? hermesVersion, ThinkingRoute? thinkingRoute
});


@override $ThinkingRouteCopyWith<$Res>? get thinkingRoute;

}
/// @nodoc
class __$ServerStatusCopyWithImpl<$Res>
    implements _$ServerStatusCopyWith<$Res> {
  __$ServerStatusCopyWithImpl(this._self, this._then);

  final _ServerStatus _self;
  final $Res Function(_ServerStatus) _then;

/// Create a copy of ServerStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverVersion = null,Object? apiRevision = null,Object? revision = freezed,Object? hermes = freezed,Object? hermesVersion = freezed,Object? thinkingRoute = freezed,}) {
  return _then(_ServerStatus(
serverVersion: null == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String,apiRevision: null == apiRevision ? _self.apiRevision : apiRevision // ignore: cast_nullable_to_non_nullable
as int,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,hermes: freezed == hermes ? _self.hermes : hermes // ignore: cast_nullable_to_non_nullable
as String?,hermesVersion: freezed == hermesVersion ? _self.hermesVersion : hermesVersion // ignore: cast_nullable_to_non_nullable
as String?,thinkingRoute: freezed == thinkingRoute ? _self.thinkingRoute : thinkingRoute // ignore: cast_nullable_to_non_nullable
as ThinkingRoute?,
  ));
}

/// Create a copy of ServerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThinkingRouteCopyWith<$Res>? get thinkingRoute {
    if (_self.thinkingRoute == null) {
    return null;
  }

  return $ThinkingRouteCopyWith<$Res>(_self.thinkingRoute!, (value) {
    return _then(_self.copyWith(thinkingRoute: value));
  });
}
}


/// @nodoc
mixin _$HelloOk {

 String get serverVersion; int get apiRevision; String? get revision; String? get hermes; String? get hermesVersion; ThinkingRoute? get thinkingRoute; String get epoch; int get seq; bool get resyncRequired;
/// Create a copy of HelloOk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelloOkCopyWith<HelloOk> get copyWith => _$HelloOkCopyWithImpl<HelloOk>(this as HelloOk, _$identity);

  /// Serializes this HelloOk to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelloOk&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.apiRevision, apiRevision) || other.apiRevision == apiRevision)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.hermes, hermes) || other.hermes == hermes)&&(identical(other.hermesVersion, hermesVersion) || other.hermesVersion == hermesVersion)&&(identical(other.thinkingRoute, thinkingRoute) || other.thinkingRoute == thinkingRoute)&&(identical(other.epoch, epoch) || other.epoch == epoch)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.resyncRequired, resyncRequired) || other.resyncRequired == resyncRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverVersion,apiRevision,revision,hermes,hermesVersion,thinkingRoute,epoch,seq,resyncRequired);

@override
String toString() {
  return 'HelloOk(serverVersion: $serverVersion, apiRevision: $apiRevision, revision: $revision, hermes: $hermes, hermesVersion: $hermesVersion, thinkingRoute: $thinkingRoute, epoch: $epoch, seq: $seq, resyncRequired: $resyncRequired)';
}


}

/// @nodoc
abstract mixin class $HelloOkCopyWith<$Res>  {
  factory $HelloOkCopyWith(HelloOk value, $Res Function(HelloOk) _then) = _$HelloOkCopyWithImpl;
@useResult
$Res call({
 String serverVersion, int apiRevision, String? revision, String? hermes, String? hermesVersion, ThinkingRoute? thinkingRoute, String epoch, int seq, bool resyncRequired
});


$ThinkingRouteCopyWith<$Res>? get thinkingRoute;

}
/// @nodoc
class _$HelloOkCopyWithImpl<$Res>
    implements $HelloOkCopyWith<$Res> {
  _$HelloOkCopyWithImpl(this._self, this._then);

  final HelloOk _self;
  final $Res Function(HelloOk) _then;

/// Create a copy of HelloOk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverVersion = null,Object? apiRevision = null,Object? revision = freezed,Object? hermes = freezed,Object? hermesVersion = freezed,Object? thinkingRoute = freezed,Object? epoch = null,Object? seq = null,Object? resyncRequired = null,}) {
  return _then(_self.copyWith(
serverVersion: null == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String,apiRevision: null == apiRevision ? _self.apiRevision : apiRevision // ignore: cast_nullable_to_non_nullable
as int,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,hermes: freezed == hermes ? _self.hermes : hermes // ignore: cast_nullable_to_non_nullable
as String?,hermesVersion: freezed == hermesVersion ? _self.hermesVersion : hermesVersion // ignore: cast_nullable_to_non_nullable
as String?,thinkingRoute: freezed == thinkingRoute ? _self.thinkingRoute : thinkingRoute // ignore: cast_nullable_to_non_nullable
as ThinkingRoute?,epoch: null == epoch ? _self.epoch : epoch // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,resyncRequired: null == resyncRequired ? _self.resyncRequired : resyncRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of HelloOk
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThinkingRouteCopyWith<$Res>? get thinkingRoute {
    if (_self.thinkingRoute == null) {
    return null;
  }

  return $ThinkingRouteCopyWith<$Res>(_self.thinkingRoute!, (value) {
    return _then(_self.copyWith(thinkingRoute: value));
  });
}
}


/// Adds pattern-matching-related methods to [HelloOk].
extension HelloOkPatterns on HelloOk {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelloOk value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelloOk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelloOk value)  $default,){
final _that = this;
switch (_that) {
case _HelloOk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelloOk value)?  $default,){
final _that = this;
switch (_that) {
case _HelloOk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverVersion,  int apiRevision,  String? revision,  String? hermes,  String? hermesVersion,  ThinkingRoute? thinkingRoute,  String epoch,  int seq,  bool resyncRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelloOk() when $default != null:
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermes,_that.hermesVersion,_that.thinkingRoute,_that.epoch,_that.seq,_that.resyncRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverVersion,  int apiRevision,  String? revision,  String? hermes,  String? hermesVersion,  ThinkingRoute? thinkingRoute,  String epoch,  int seq,  bool resyncRequired)  $default,) {final _that = this;
switch (_that) {
case _HelloOk():
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermes,_that.hermesVersion,_that.thinkingRoute,_that.epoch,_that.seq,_that.resyncRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverVersion,  int apiRevision,  String? revision,  String? hermes,  String? hermesVersion,  ThinkingRoute? thinkingRoute,  String epoch,  int seq,  bool resyncRequired)?  $default,) {final _that = this;
switch (_that) {
case _HelloOk() when $default != null:
return $default(_that.serverVersion,_that.apiRevision,_that.revision,_that.hermes,_that.hermesVersion,_that.thinkingRoute,_that.epoch,_that.seq,_that.resyncRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelloOk implements HelloOk {
  const _HelloOk({required this.serverVersion, required this.apiRevision, this.revision, this.hermes, this.hermesVersion, this.thinkingRoute, required this.epoch, required this.seq, required this.resyncRequired});
  factory _HelloOk.fromJson(Map<String, dynamic> json) => _$HelloOkFromJson(json);

@override final  String serverVersion;
@override final  int apiRevision;
@override final  String? revision;
@override final  String? hermes;
@override final  String? hermesVersion;
@override final  ThinkingRoute? thinkingRoute;
@override final  String epoch;
@override final  int seq;
@override final  bool resyncRequired;

/// Create a copy of HelloOk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelloOkCopyWith<_HelloOk> get copyWith => __$HelloOkCopyWithImpl<_HelloOk>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelloOkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelloOk&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.apiRevision, apiRevision) || other.apiRevision == apiRevision)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.hermes, hermes) || other.hermes == hermes)&&(identical(other.hermesVersion, hermesVersion) || other.hermesVersion == hermesVersion)&&(identical(other.thinkingRoute, thinkingRoute) || other.thinkingRoute == thinkingRoute)&&(identical(other.epoch, epoch) || other.epoch == epoch)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.resyncRequired, resyncRequired) || other.resyncRequired == resyncRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverVersion,apiRevision,revision,hermes,hermesVersion,thinkingRoute,epoch,seq,resyncRequired);

@override
String toString() {
  return 'HelloOk(serverVersion: $serverVersion, apiRevision: $apiRevision, revision: $revision, hermes: $hermes, hermesVersion: $hermesVersion, thinkingRoute: $thinkingRoute, epoch: $epoch, seq: $seq, resyncRequired: $resyncRequired)';
}


}

/// @nodoc
abstract mixin class _$HelloOkCopyWith<$Res> implements $HelloOkCopyWith<$Res> {
  factory _$HelloOkCopyWith(_HelloOk value, $Res Function(_HelloOk) _then) = __$HelloOkCopyWithImpl;
@override @useResult
$Res call({
 String serverVersion, int apiRevision, String? revision, String? hermes, String? hermesVersion, ThinkingRoute? thinkingRoute, String epoch, int seq, bool resyncRequired
});


@override $ThinkingRouteCopyWith<$Res>? get thinkingRoute;

}
/// @nodoc
class __$HelloOkCopyWithImpl<$Res>
    implements _$HelloOkCopyWith<$Res> {
  __$HelloOkCopyWithImpl(this._self, this._then);

  final _HelloOk _self;
  final $Res Function(_HelloOk) _then;

/// Create a copy of HelloOk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverVersion = null,Object? apiRevision = null,Object? revision = freezed,Object? hermes = freezed,Object? hermesVersion = freezed,Object? thinkingRoute = freezed,Object? epoch = null,Object? seq = null,Object? resyncRequired = null,}) {
  return _then(_HelloOk(
serverVersion: null == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String,apiRevision: null == apiRevision ? _self.apiRevision : apiRevision // ignore: cast_nullable_to_non_nullable
as int,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,hermes: freezed == hermes ? _self.hermes : hermes // ignore: cast_nullable_to_non_nullable
as String?,hermesVersion: freezed == hermesVersion ? _self.hermesVersion : hermesVersion // ignore: cast_nullable_to_non_nullable
as String?,thinkingRoute: freezed == thinkingRoute ? _self.thinkingRoute : thinkingRoute // ignore: cast_nullable_to_non_nullable
as ThinkingRoute?,epoch: null == epoch ? _self.epoch : epoch // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,resyncRequired: null == resyncRequired ? _self.resyncRequired : resyncRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of HelloOk
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThinkingRouteCopyWith<$Res>? get thinkingRoute {
    if (_self.thinkingRoute == null) {
    return null;
  }

  return $ThinkingRouteCopyWith<$Res>(_self.thinkingRoute!, (value) {
    return _then(_self.copyWith(thinkingRoute: value));
  });
}
}

// dart format on
