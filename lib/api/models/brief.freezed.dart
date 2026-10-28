// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'brief.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Brief {

/// Local date, `YYYY-MM-DD`.
 String get date; int? get uptimeS; DateTime? get bootedAt; int? get openIncidents; List<BriefIncident> get incidents; int? get updatesCount; DateTime? get updatesCheckedAt; BriefWater? get water; String? get llamaState; String? get hermesState; List<String> get missing;/// Written this long after its time: the desktop was off then (N74).
 int? get lateByS;
/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefCopyWith<Brief> get copyWith => _$BriefCopyWithImpl<Brief>(this as Brief, _$identity);

  /// Serializes this Brief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Brief&&(identical(other.date, date) || other.date == date)&&(identical(other.uptimeS, uptimeS) || other.uptimeS == uptimeS)&&(identical(other.bootedAt, bootedAt) || other.bootedAt == bootedAt)&&(identical(other.openIncidents, openIncidents) || other.openIncidents == openIncidents)&&const DeepCollectionEquality().equals(other.incidents, incidents)&&(identical(other.updatesCount, updatesCount) || other.updatesCount == updatesCount)&&(identical(other.updatesCheckedAt, updatesCheckedAt) || other.updatesCheckedAt == updatesCheckedAt)&&(identical(other.water, water) || other.water == water)&&(identical(other.llamaState, llamaState) || other.llamaState == llamaState)&&(identical(other.hermesState, hermesState) || other.hermesState == hermesState)&&const DeepCollectionEquality().equals(other.missing, missing)&&(identical(other.lateByS, lateByS) || other.lateByS == lateByS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,uptimeS,bootedAt,openIncidents,const DeepCollectionEquality().hash(incidents),updatesCount,updatesCheckedAt,water,llamaState,hermesState,const DeepCollectionEquality().hash(missing),lateByS);

@override
String toString() {
  return 'Brief(date: $date, uptimeS: $uptimeS, bootedAt: $bootedAt, openIncidents: $openIncidents, incidents: $incidents, updatesCount: $updatesCount, updatesCheckedAt: $updatesCheckedAt, water: $water, llamaState: $llamaState, hermesState: $hermesState, missing: $missing, lateByS: $lateByS)';
}


}

/// @nodoc
abstract mixin class $BriefCopyWith<$Res>  {
  factory $BriefCopyWith(Brief value, $Res Function(Brief) _then) = _$BriefCopyWithImpl;
@useResult
$Res call({
 String date, int? uptimeS, DateTime? bootedAt, int? openIncidents, List<BriefIncident> incidents, int? updatesCount, DateTime? updatesCheckedAt, BriefWater? water, String? llamaState, String? hermesState, List<String> missing, int? lateByS
});


$BriefWaterCopyWith<$Res>? get water;

}
/// @nodoc
class _$BriefCopyWithImpl<$Res>
    implements $BriefCopyWith<$Res> {
  _$BriefCopyWithImpl(this._self, this._then);

  final Brief _self;
  final $Res Function(Brief) _then;

/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? uptimeS = freezed,Object? bootedAt = freezed,Object? openIncidents = freezed,Object? incidents = null,Object? updatesCount = freezed,Object? updatesCheckedAt = freezed,Object? water = freezed,Object? llamaState = freezed,Object? hermesState = freezed,Object? missing = null,Object? lateByS = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,uptimeS: freezed == uptimeS ? _self.uptimeS : uptimeS // ignore: cast_nullable_to_non_nullable
as int?,bootedAt: freezed == bootedAt ? _self.bootedAt : bootedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openIncidents: freezed == openIncidents ? _self.openIncidents : openIncidents // ignore: cast_nullable_to_non_nullable
as int?,incidents: null == incidents ? _self.incidents : incidents // ignore: cast_nullable_to_non_nullable
as List<BriefIncident>,updatesCount: freezed == updatesCount ? _self.updatesCount : updatesCount // ignore: cast_nullable_to_non_nullable
as int?,updatesCheckedAt: freezed == updatesCheckedAt ? _self.updatesCheckedAt : updatesCheckedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,water: freezed == water ? _self.water : water // ignore: cast_nullable_to_non_nullable
as BriefWater?,llamaState: freezed == llamaState ? _self.llamaState : llamaState // ignore: cast_nullable_to_non_nullable
as String?,hermesState: freezed == hermesState ? _self.hermesState : hermesState // ignore: cast_nullable_to_non_nullable
as String?,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as List<String>,lateByS: freezed == lateByS ? _self.lateByS : lateByS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefWaterCopyWith<$Res>? get water {
    if (_self.water == null) {
    return null;
  }

  return $BriefWaterCopyWith<$Res>(_self.water!, (value) {
    return _then(_self.copyWith(water: value));
  });
}
}


/// Adds pattern-matching-related methods to [Brief].
extension BriefPatterns on Brief {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Brief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Brief() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Brief value)  $default,){
final _that = this;
switch (_that) {
case _Brief():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Brief value)?  $default,){
final _that = this;
switch (_that) {
case _Brief() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int? uptimeS,  DateTime? bootedAt,  int? openIncidents,  List<BriefIncident> incidents,  int? updatesCount,  DateTime? updatesCheckedAt,  BriefWater? water,  String? llamaState,  String? hermesState,  List<String> missing,  int? lateByS)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Brief() when $default != null:
return $default(_that.date,_that.uptimeS,_that.bootedAt,_that.openIncidents,_that.incidents,_that.updatesCount,_that.updatesCheckedAt,_that.water,_that.llamaState,_that.hermesState,_that.missing,_that.lateByS);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int? uptimeS,  DateTime? bootedAt,  int? openIncidents,  List<BriefIncident> incidents,  int? updatesCount,  DateTime? updatesCheckedAt,  BriefWater? water,  String? llamaState,  String? hermesState,  List<String> missing,  int? lateByS)  $default,) {final _that = this;
switch (_that) {
case _Brief():
return $default(_that.date,_that.uptimeS,_that.bootedAt,_that.openIncidents,_that.incidents,_that.updatesCount,_that.updatesCheckedAt,_that.water,_that.llamaState,_that.hermesState,_that.missing,_that.lateByS);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int? uptimeS,  DateTime? bootedAt,  int? openIncidents,  List<BriefIncident> incidents,  int? updatesCount,  DateTime? updatesCheckedAt,  BriefWater? water,  String? llamaState,  String? hermesState,  List<String> missing,  int? lateByS)?  $default,) {final _that = this;
switch (_that) {
case _Brief() when $default != null:
return $default(_that.date,_that.uptimeS,_that.bootedAt,_that.openIncidents,_that.incidents,_that.updatesCount,_that.updatesCheckedAt,_that.water,_that.llamaState,_that.hermesState,_that.missing,_that.lateByS);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Brief implements Brief {
  const _Brief({required this.date, this.uptimeS, this.bootedAt, this.openIncidents, final  List<BriefIncident> incidents = const <BriefIncident>[], this.updatesCount, this.updatesCheckedAt, this.water, this.llamaState, this.hermesState, final  List<String> missing = const <String>[], this.lateByS}): _incidents = incidents,_missing = missing;
  factory _Brief.fromJson(Map<String, dynamic> json) => _$BriefFromJson(json);

/// Local date, `YYYY-MM-DD`.
@override final  String date;
@override final  int? uptimeS;
@override final  DateTime? bootedAt;
@override final  int? openIncidents;
 final  List<BriefIncident> _incidents;
@override@JsonKey() List<BriefIncident> get incidents {
  if (_incidents is EqualUnmodifiableListView) return _incidents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_incidents);
}

@override final  int? updatesCount;
@override final  DateTime? updatesCheckedAt;
@override final  BriefWater? water;
@override final  String? llamaState;
@override final  String? hermesState;
 final  List<String> _missing;
@override@JsonKey() List<String> get missing {
  if (_missing is EqualUnmodifiableListView) return _missing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missing);
}

/// Written this long after its time: the desktop was off then (N74).
@override final  int? lateByS;

/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefCopyWith<_Brief> get copyWith => __$BriefCopyWithImpl<_Brief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Brief&&(identical(other.date, date) || other.date == date)&&(identical(other.uptimeS, uptimeS) || other.uptimeS == uptimeS)&&(identical(other.bootedAt, bootedAt) || other.bootedAt == bootedAt)&&(identical(other.openIncidents, openIncidents) || other.openIncidents == openIncidents)&&const DeepCollectionEquality().equals(other._incidents, _incidents)&&(identical(other.updatesCount, updatesCount) || other.updatesCount == updatesCount)&&(identical(other.updatesCheckedAt, updatesCheckedAt) || other.updatesCheckedAt == updatesCheckedAt)&&(identical(other.water, water) || other.water == water)&&(identical(other.llamaState, llamaState) || other.llamaState == llamaState)&&(identical(other.hermesState, hermesState) || other.hermesState == hermesState)&&const DeepCollectionEquality().equals(other._missing, _missing)&&(identical(other.lateByS, lateByS) || other.lateByS == lateByS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,uptimeS,bootedAt,openIncidents,const DeepCollectionEquality().hash(_incidents),updatesCount,updatesCheckedAt,water,llamaState,hermesState,const DeepCollectionEquality().hash(_missing),lateByS);

@override
String toString() {
  return 'Brief(date: $date, uptimeS: $uptimeS, bootedAt: $bootedAt, openIncidents: $openIncidents, incidents: $incidents, updatesCount: $updatesCount, updatesCheckedAt: $updatesCheckedAt, water: $water, llamaState: $llamaState, hermesState: $hermesState, missing: $missing, lateByS: $lateByS)';
}


}

/// @nodoc
abstract mixin class _$BriefCopyWith<$Res> implements $BriefCopyWith<$Res> {
  factory _$BriefCopyWith(_Brief value, $Res Function(_Brief) _then) = __$BriefCopyWithImpl;
@override @useResult
$Res call({
 String date, int? uptimeS, DateTime? bootedAt, int? openIncidents, List<BriefIncident> incidents, int? updatesCount, DateTime? updatesCheckedAt, BriefWater? water, String? llamaState, String? hermesState, List<String> missing, int? lateByS
});


@override $BriefWaterCopyWith<$Res>? get water;

}
/// @nodoc
class __$BriefCopyWithImpl<$Res>
    implements _$BriefCopyWith<$Res> {
  __$BriefCopyWithImpl(this._self, this._then);

  final _Brief _self;
  final $Res Function(_Brief) _then;

/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? uptimeS = freezed,Object? bootedAt = freezed,Object? openIncidents = freezed,Object? incidents = null,Object? updatesCount = freezed,Object? updatesCheckedAt = freezed,Object? water = freezed,Object? llamaState = freezed,Object? hermesState = freezed,Object? missing = null,Object? lateByS = freezed,}) {
  return _then(_Brief(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,uptimeS: freezed == uptimeS ? _self.uptimeS : uptimeS // ignore: cast_nullable_to_non_nullable
as int?,bootedAt: freezed == bootedAt ? _self.bootedAt : bootedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openIncidents: freezed == openIncidents ? _self.openIncidents : openIncidents // ignore: cast_nullable_to_non_nullable
as int?,incidents: null == incidents ? _self._incidents : incidents // ignore: cast_nullable_to_non_nullable
as List<BriefIncident>,updatesCount: freezed == updatesCount ? _self.updatesCount : updatesCount // ignore: cast_nullable_to_non_nullable
as int?,updatesCheckedAt: freezed == updatesCheckedAt ? _self.updatesCheckedAt : updatesCheckedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,water: freezed == water ? _self.water : water // ignore: cast_nullable_to_non_nullable
as BriefWater?,llamaState: freezed == llamaState ? _self.llamaState : llamaState // ignore: cast_nullable_to_non_nullable
as String?,hermesState: freezed == hermesState ? _self.hermesState : hermesState // ignore: cast_nullable_to_non_nullable
as String?,missing: null == missing ? _self._missing : missing // ignore: cast_nullable_to_non_nullable
as List<String>,lateByS: freezed == lateByS ? _self.lateByS : lateByS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefWaterCopyWith<$Res>? get water {
    if (_self.water == null) {
    return null;
  }

  return $BriefWaterCopyWith<$Res>(_self.water!, (value) {
    return _then(_self.copyWith(water: value));
  });
}
}


/// @nodoc
mixin _$BriefIncident {

 String get id;/// `detected` | `alerted` | `resolved`.
 String get state; String? get job; String? get error; String? get lastSeen;
/// Create a copy of BriefIncident
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefIncidentCopyWith<BriefIncident> get copyWith => _$BriefIncidentCopyWithImpl<BriefIncident>(this as BriefIncident, _$identity);

  /// Serializes this BriefIncident to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefIncident&&(identical(other.id, id) || other.id == id)&&(identical(other.state, state) || other.state == state)&&(identical(other.job, job) || other.job == job)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,state,job,error,lastSeen);

@override
String toString() {
  return 'BriefIncident(id: $id, state: $state, job: $job, error: $error, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class $BriefIncidentCopyWith<$Res>  {
  factory $BriefIncidentCopyWith(BriefIncident value, $Res Function(BriefIncident) _then) = _$BriefIncidentCopyWithImpl;
@useResult
$Res call({
 String id, String state, String? job, String? error, String? lastSeen
});




}
/// @nodoc
class _$BriefIncidentCopyWithImpl<$Res>
    implements $BriefIncidentCopyWith<$Res> {
  _$BriefIncidentCopyWithImpl(this._self, this._then);

  final BriefIncident _self;
  final $Res Function(BriefIncident) _then;

/// Create a copy of BriefIncident
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? state = null,Object? job = freezed,Object? error = freezed,Object? lastSeen = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefIncident].
extension BriefIncidentPatterns on BriefIncident {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefIncident value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefIncident() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefIncident value)  $default,){
final _that = this;
switch (_that) {
case _BriefIncident():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefIncident value)?  $default,){
final _that = this;
switch (_that) {
case _BriefIncident() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String state,  String? job,  String? error,  String? lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefIncident() when $default != null:
return $default(_that.id,_that.state,_that.job,_that.error,_that.lastSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String state,  String? job,  String? error,  String? lastSeen)  $default,) {final _that = this;
switch (_that) {
case _BriefIncident():
return $default(_that.id,_that.state,_that.job,_that.error,_that.lastSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String state,  String? job,  String? error,  String? lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _BriefIncident() when $default != null:
return $default(_that.id,_that.state,_that.job,_that.error,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefIncident implements BriefIncident {
  const _BriefIncident({required this.id, required this.state, this.job, this.error, this.lastSeen});
  factory _BriefIncident.fromJson(Map<String, dynamic> json) => _$BriefIncidentFromJson(json);

@override final  String id;
/// `detected` | `alerted` | `resolved`.
@override final  String state;
@override final  String? job;
@override final  String? error;
@override final  String? lastSeen;

/// Create a copy of BriefIncident
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefIncidentCopyWith<_BriefIncident> get copyWith => __$BriefIncidentCopyWithImpl<_BriefIncident>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefIncidentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefIncident&&(identical(other.id, id) || other.id == id)&&(identical(other.state, state) || other.state == state)&&(identical(other.job, job) || other.job == job)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,state,job,error,lastSeen);

@override
String toString() {
  return 'BriefIncident(id: $id, state: $state, job: $job, error: $error, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$BriefIncidentCopyWith<$Res> implements $BriefIncidentCopyWith<$Res> {
  factory _$BriefIncidentCopyWith(_BriefIncident value, $Res Function(_BriefIncident) _then) = __$BriefIncidentCopyWithImpl;
@override @useResult
$Res call({
 String id, String state, String? job, String? error, String? lastSeen
});




}
/// @nodoc
class __$BriefIncidentCopyWithImpl<$Res>
    implements _$BriefIncidentCopyWith<$Res> {
  __$BriefIncidentCopyWithImpl(this._self, this._then);

  final _BriefIncident _self;
  final $Res Function(_BriefIncident) _then;

/// Create a copy of BriefIncident
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? state = null,Object? job = freezed,Object? error = freezed,Object? lastSeen = freezed,}) {
  return _then(_BriefIncident(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BriefWater {

 String? get station; double? get levelCm; double? get lakeAvgCm;@JsonKey(name: 'trend_cm_24h') double? get trendCm24h;@JsonKey(name: 'lake_avg_trend_cm_24h') double? get lakeAvgTrendCm24h; String? get measuredAt;
/// Create a copy of BriefWater
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefWaterCopyWith<BriefWater> get copyWith => _$BriefWaterCopyWithImpl<BriefWater>(this as BriefWater, _$identity);

  /// Serializes this BriefWater to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefWater&&(identical(other.station, station) || other.station == station)&&(identical(other.levelCm, levelCm) || other.levelCm == levelCm)&&(identical(other.lakeAvgCm, lakeAvgCm) || other.lakeAvgCm == lakeAvgCm)&&(identical(other.trendCm24h, trendCm24h) || other.trendCm24h == trendCm24h)&&(identical(other.lakeAvgTrendCm24h, lakeAvgTrendCm24h) || other.lakeAvgTrendCm24h == lakeAvgTrendCm24h)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,station,levelCm,lakeAvgCm,trendCm24h,lakeAvgTrendCm24h,measuredAt);

@override
String toString() {
  return 'BriefWater(station: $station, levelCm: $levelCm, lakeAvgCm: $lakeAvgCm, trendCm24h: $trendCm24h, lakeAvgTrendCm24h: $lakeAvgTrendCm24h, measuredAt: $measuredAt)';
}


}

/// @nodoc
abstract mixin class $BriefWaterCopyWith<$Res>  {
  factory $BriefWaterCopyWith(BriefWater value, $Res Function(BriefWater) _then) = _$BriefWaterCopyWithImpl;
@useResult
$Res call({
 String? station, double? levelCm, double? lakeAvgCm,@JsonKey(name: 'trend_cm_24h') double? trendCm24h,@JsonKey(name: 'lake_avg_trend_cm_24h') double? lakeAvgTrendCm24h, String? measuredAt
});




}
/// @nodoc
class _$BriefWaterCopyWithImpl<$Res>
    implements $BriefWaterCopyWith<$Res> {
  _$BriefWaterCopyWithImpl(this._self, this._then);

  final BriefWater _self;
  final $Res Function(BriefWater) _then;

/// Create a copy of BriefWater
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? station = freezed,Object? levelCm = freezed,Object? lakeAvgCm = freezed,Object? trendCm24h = freezed,Object? lakeAvgTrendCm24h = freezed,Object? measuredAt = freezed,}) {
  return _then(_self.copyWith(
station: freezed == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String?,levelCm: freezed == levelCm ? _self.levelCm : levelCm // ignore: cast_nullable_to_non_nullable
as double?,lakeAvgCm: freezed == lakeAvgCm ? _self.lakeAvgCm : lakeAvgCm // ignore: cast_nullable_to_non_nullable
as double?,trendCm24h: freezed == trendCm24h ? _self.trendCm24h : trendCm24h // ignore: cast_nullable_to_non_nullable
as double?,lakeAvgTrendCm24h: freezed == lakeAvgTrendCm24h ? _self.lakeAvgTrendCm24h : lakeAvgTrendCm24h // ignore: cast_nullable_to_non_nullable
as double?,measuredAt: freezed == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefWater].
extension BriefWaterPatterns on BriefWater {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefWater value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefWater() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefWater value)  $default,){
final _that = this;
switch (_that) {
case _BriefWater():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefWater value)?  $default,){
final _that = this;
switch (_that) {
case _BriefWater() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? station,  double? levelCm,  double? lakeAvgCm, @JsonKey(name: 'trend_cm_24h')  double? trendCm24h, @JsonKey(name: 'lake_avg_trend_cm_24h')  double? lakeAvgTrendCm24h,  String? measuredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefWater() when $default != null:
return $default(_that.station,_that.levelCm,_that.lakeAvgCm,_that.trendCm24h,_that.lakeAvgTrendCm24h,_that.measuredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? station,  double? levelCm,  double? lakeAvgCm, @JsonKey(name: 'trend_cm_24h')  double? trendCm24h, @JsonKey(name: 'lake_avg_trend_cm_24h')  double? lakeAvgTrendCm24h,  String? measuredAt)  $default,) {final _that = this;
switch (_that) {
case _BriefWater():
return $default(_that.station,_that.levelCm,_that.lakeAvgCm,_that.trendCm24h,_that.lakeAvgTrendCm24h,_that.measuredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? station,  double? levelCm,  double? lakeAvgCm, @JsonKey(name: 'trend_cm_24h')  double? trendCm24h, @JsonKey(name: 'lake_avg_trend_cm_24h')  double? lakeAvgTrendCm24h,  String? measuredAt)?  $default,) {final _that = this;
switch (_that) {
case _BriefWater() when $default != null:
return $default(_that.station,_that.levelCm,_that.lakeAvgCm,_that.trendCm24h,_that.lakeAvgTrendCm24h,_that.measuredAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefWater implements BriefWater {
  const _BriefWater({this.station, this.levelCm, this.lakeAvgCm, @JsonKey(name: 'trend_cm_24h') this.trendCm24h, @JsonKey(name: 'lake_avg_trend_cm_24h') this.lakeAvgTrendCm24h, this.measuredAt});
  factory _BriefWater.fromJson(Map<String, dynamic> json) => _$BriefWaterFromJson(json);

@override final  String? station;
@override final  double? levelCm;
@override final  double? lakeAvgCm;
@override@JsonKey(name: 'trend_cm_24h') final  double? trendCm24h;
@override@JsonKey(name: 'lake_avg_trend_cm_24h') final  double? lakeAvgTrendCm24h;
@override final  String? measuredAt;

/// Create a copy of BriefWater
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefWaterCopyWith<_BriefWater> get copyWith => __$BriefWaterCopyWithImpl<_BriefWater>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefWaterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefWater&&(identical(other.station, station) || other.station == station)&&(identical(other.levelCm, levelCm) || other.levelCm == levelCm)&&(identical(other.lakeAvgCm, lakeAvgCm) || other.lakeAvgCm == lakeAvgCm)&&(identical(other.trendCm24h, trendCm24h) || other.trendCm24h == trendCm24h)&&(identical(other.lakeAvgTrendCm24h, lakeAvgTrendCm24h) || other.lakeAvgTrendCm24h == lakeAvgTrendCm24h)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,station,levelCm,lakeAvgCm,trendCm24h,lakeAvgTrendCm24h,measuredAt);

@override
String toString() {
  return 'BriefWater(station: $station, levelCm: $levelCm, lakeAvgCm: $lakeAvgCm, trendCm24h: $trendCm24h, lakeAvgTrendCm24h: $lakeAvgTrendCm24h, measuredAt: $measuredAt)';
}


}

/// @nodoc
abstract mixin class _$BriefWaterCopyWith<$Res> implements $BriefWaterCopyWith<$Res> {
  factory _$BriefWaterCopyWith(_BriefWater value, $Res Function(_BriefWater) _then) = __$BriefWaterCopyWithImpl;
@override @useResult
$Res call({
 String? station, double? levelCm, double? lakeAvgCm,@JsonKey(name: 'trend_cm_24h') double? trendCm24h,@JsonKey(name: 'lake_avg_trend_cm_24h') double? lakeAvgTrendCm24h, String? measuredAt
});




}
/// @nodoc
class __$BriefWaterCopyWithImpl<$Res>
    implements _$BriefWaterCopyWith<$Res> {
  __$BriefWaterCopyWithImpl(this._self, this._then);

  final _BriefWater _self;
  final $Res Function(_BriefWater) _then;

/// Create a copy of BriefWater
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? station = freezed,Object? levelCm = freezed,Object? lakeAvgCm = freezed,Object? trendCm24h = freezed,Object? lakeAvgTrendCm24h = freezed,Object? measuredAt = freezed,}) {
  return _then(_BriefWater(
station: freezed == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String?,levelCm: freezed == levelCm ? _self.levelCm : levelCm // ignore: cast_nullable_to_non_nullable
as double?,lakeAvgCm: freezed == lakeAvgCm ? _self.lakeAvgCm : lakeAvgCm // ignore: cast_nullable_to_non_nullable
as double?,trendCm24h: freezed == trendCm24h ? _self.trendCm24h : trendCm24h // ignore: cast_nullable_to_non_nullable
as double?,lakeAvgTrendCm24h: freezed == lakeAvgTrendCm24h ? _self.lakeAvgTrendCm24h : lakeAvgTrendCm24h // ignore: cast_nullable_to_non_nullable
as double?,measuredAt: freezed == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
