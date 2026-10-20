// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentCard {

 String get id; String get type;/// `info` | `warn` | `alert`.
 String get severity; DateTime get ts;/// `agent` | `script` | `backend`.
 String get origin; String? get sessionId; Map<String, Object?> get payload; DateTime get receivedAt;
/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentCardCopyWith<AgentCard> get copyWith => _$AgentCardCopyWithImpl<AgentCard>(this as AgentCard, _$identity);

  /// Serializes this AgentCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentCard&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.ts, ts) || other.ts == ts)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,severity,ts,origin,sessionId,const DeepCollectionEquality().hash(payload),receivedAt);

@override
String toString() {
  return 'AgentCard(id: $id, type: $type, severity: $severity, ts: $ts, origin: $origin, sessionId: $sessionId, payload: $payload, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class $AgentCardCopyWith<$Res>  {
  factory $AgentCardCopyWith(AgentCard value, $Res Function(AgentCard) _then) = _$AgentCardCopyWithImpl;
@useResult
$Res call({
 String id, String type, String severity, DateTime ts, String origin, String? sessionId, Map<String, Object?> payload, DateTime receivedAt
});




}
/// @nodoc
class _$AgentCardCopyWithImpl<$Res>
    implements $AgentCardCopyWith<$Res> {
  _$AgentCardCopyWithImpl(this._self, this._then);

  final AgentCard _self;
  final $Res Function(AgentCard) _then;

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? severity = null,Object? ts = null,Object? origin = null,Object? sessionId = freezed,Object? payload = null,Object? receivedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as DateTime,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentCard].
extension AgentCardPatterns on AgentCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentCard value)  $default,){
final _that = this;
switch (_that) {
case _AgentCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentCard value)?  $default,){
final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String severity,  DateTime ts,  String origin,  String? sessionId,  Map<String, Object?> payload,  DateTime receivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
return $default(_that.id,_that.type,_that.severity,_that.ts,_that.origin,_that.sessionId,_that.payload,_that.receivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String severity,  DateTime ts,  String origin,  String? sessionId,  Map<String, Object?> payload,  DateTime receivedAt)  $default,) {final _that = this;
switch (_that) {
case _AgentCard():
return $default(_that.id,_that.type,_that.severity,_that.ts,_that.origin,_that.sessionId,_that.payload,_that.receivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String severity,  DateTime ts,  String origin,  String? sessionId,  Map<String, Object?> payload,  DateTime receivedAt)?  $default,) {final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
return $default(_that.id,_that.type,_that.severity,_that.ts,_that.origin,_that.sessionId,_that.payload,_that.receivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentCard implements AgentCard {
  const _AgentCard({required this.id, required this.type, required this.severity, required this.ts, required this.origin, this.sessionId, required final  Map<String, Object?> payload, required this.receivedAt}): _payload = payload;
  factory _AgentCard.fromJson(Map<String, dynamic> json) => _$AgentCardFromJson(json);

@override final  String id;
@override final  String type;
/// `info` | `warn` | `alert`.
@override final  String severity;
@override final  DateTime ts;
/// `agent` | `script` | `backend`.
@override final  String origin;
@override final  String? sessionId;
 final  Map<String, Object?> _payload;
@override Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  DateTime receivedAt;

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentCardCopyWith<_AgentCard> get copyWith => __$AgentCardCopyWithImpl<_AgentCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentCard&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.ts, ts) || other.ts == ts)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,severity,ts,origin,sessionId,const DeepCollectionEquality().hash(_payload),receivedAt);

@override
String toString() {
  return 'AgentCard(id: $id, type: $type, severity: $severity, ts: $ts, origin: $origin, sessionId: $sessionId, payload: $payload, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class _$AgentCardCopyWith<$Res> implements $AgentCardCopyWith<$Res> {
  factory _$AgentCardCopyWith(_AgentCard value, $Res Function(_AgentCard) _then) = __$AgentCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String severity, DateTime ts, String origin, String? sessionId, Map<String, Object?> payload, DateTime receivedAt
});




}
/// @nodoc
class __$AgentCardCopyWithImpl<$Res>
    implements _$AgentCardCopyWith<$Res> {
  __$AgentCardCopyWithImpl(this._self, this._then);

  final _AgentCard _self;
  final $Res Function(_AgentCard) _then;

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? severity = null,Object? ts = null,Object? origin = null,Object? sessionId = freezed,Object? payload = null,Object? receivedAt = null,}) {
  return _then(_AgentCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,ts: null == ts ? _self.ts : ts // ignore: cast_nullable_to_non_nullable
as DateTime,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
