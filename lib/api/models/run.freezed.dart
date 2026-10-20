// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Run {

 String get runId; String get conversationId; String get status; bool get thinking; String get origin; DateTime get queuedAt; DateTime? get startedAt; DateTime? get endedAt; Map<String, Object?>? get usage; Map<String, Object?>? get perf; String? get error;
/// Create a copy of Run
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunCopyWith<Run> get copyWith => _$RunCopyWithImpl<Run>(this as Run, _$identity);

  /// Serializes this Run to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Run&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other.usage, usage)&&const DeepCollectionEquality().equals(other.perf, perf)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,conversationId,status,thinking,origin,queuedAt,startedAt,endedAt,const DeepCollectionEquality().hash(usage),const DeepCollectionEquality().hash(perf),error);

@override
String toString() {
  return 'Run(runId: $runId, conversationId: $conversationId, status: $status, thinking: $thinking, origin: $origin, queuedAt: $queuedAt, startedAt: $startedAt, endedAt: $endedAt, usage: $usage, perf: $perf, error: $error)';
}


}

/// @nodoc
abstract mixin class $RunCopyWith<$Res>  {
  factory $RunCopyWith(Run value, $Res Function(Run) _then) = _$RunCopyWithImpl;
@useResult
$Res call({
 String runId, String conversationId, String status, bool thinking, String origin, DateTime queuedAt, DateTime? startedAt, DateTime? endedAt, Map<String, Object?>? usage, Map<String, Object?>? perf, String? error
});




}
/// @nodoc
class _$RunCopyWithImpl<$Res>
    implements $RunCopyWith<$Res> {
  _$RunCopyWithImpl(this._self, this._then);

  final Run _self;
  final $Res Function(Run) _then;

/// Create a copy of Run
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? conversationId = null,Object? status = null,Object? thinking = null,Object? origin = null,Object? queuedAt = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? usage = freezed,Object? perf = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,perf: freezed == perf ? _self.perf : perf // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Run].
extension RunPatterns on Run {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Run value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Run() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Run value)  $default,){
final _that = this;
switch (_that) {
case _Run():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Run value)?  $default,){
final _that = this;
switch (_that) {
case _Run() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String conversationId,  String status,  bool thinking,  String origin,  DateTime queuedAt,  DateTime? startedAt,  DateTime? endedAt,  Map<String, Object?>? usage,  Map<String, Object?>? perf,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Run() when $default != null:
return $default(_that.runId,_that.conversationId,_that.status,_that.thinking,_that.origin,_that.queuedAt,_that.startedAt,_that.endedAt,_that.usage,_that.perf,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String conversationId,  String status,  bool thinking,  String origin,  DateTime queuedAt,  DateTime? startedAt,  DateTime? endedAt,  Map<String, Object?>? usage,  Map<String, Object?>? perf,  String? error)  $default,) {final _that = this;
switch (_that) {
case _Run():
return $default(_that.runId,_that.conversationId,_that.status,_that.thinking,_that.origin,_that.queuedAt,_that.startedAt,_that.endedAt,_that.usage,_that.perf,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String conversationId,  String status,  bool thinking,  String origin,  DateTime queuedAt,  DateTime? startedAt,  DateTime? endedAt,  Map<String, Object?>? usage,  Map<String, Object?>? perf,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _Run() when $default != null:
return $default(_that.runId,_that.conversationId,_that.status,_that.thinking,_that.origin,_that.queuedAt,_that.startedAt,_that.endedAt,_that.usage,_that.perf,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Run implements Run {
  const _Run({required this.runId, required this.conversationId, required this.status, required this.thinking, required this.origin, required this.queuedAt, this.startedAt, this.endedAt, final  Map<String, Object?>? usage, final  Map<String, Object?>? perf, this.error}): _usage = usage,_perf = perf;
  factory _Run.fromJson(Map<String, dynamic> json) => _$RunFromJson(json);

@override final  String runId;
@override final  String conversationId;
@override final  String status;
@override final  bool thinking;
@override final  String origin;
@override final  DateTime queuedAt;
@override final  DateTime? startedAt;
@override final  DateTime? endedAt;
 final  Map<String, Object?>? _usage;
@override Map<String, Object?>? get usage {
  final value = _usage;
  if (value == null) return null;
  if (_usage is EqualUnmodifiableMapView) return _usage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, Object?>? _perf;
@override Map<String, Object?>? get perf {
  final value = _perf;
  if (value == null) return null;
  if (_perf is EqualUnmodifiableMapView) return _perf;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? error;

/// Create a copy of Run
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunCopyWith<_Run> get copyWith => __$RunCopyWithImpl<_Run>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Run&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other._usage, _usage)&&const DeepCollectionEquality().equals(other._perf, _perf)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,conversationId,status,thinking,origin,queuedAt,startedAt,endedAt,const DeepCollectionEquality().hash(_usage),const DeepCollectionEquality().hash(_perf),error);

@override
String toString() {
  return 'Run(runId: $runId, conversationId: $conversationId, status: $status, thinking: $thinking, origin: $origin, queuedAt: $queuedAt, startedAt: $startedAt, endedAt: $endedAt, usage: $usage, perf: $perf, error: $error)';
}


}

/// @nodoc
abstract mixin class _$RunCopyWith<$Res> implements $RunCopyWith<$Res> {
  factory _$RunCopyWith(_Run value, $Res Function(_Run) _then) = __$RunCopyWithImpl;
@override @useResult
$Res call({
 String runId, String conversationId, String status, bool thinking, String origin, DateTime queuedAt, DateTime? startedAt, DateTime? endedAt, Map<String, Object?>? usage, Map<String, Object?>? perf, String? error
});




}
/// @nodoc
class __$RunCopyWithImpl<$Res>
    implements _$RunCopyWith<$Res> {
  __$RunCopyWithImpl(this._self, this._then);

  final _Run _self;
  final $Res Function(_Run) _then;

/// Create a copy of Run
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? conversationId = null,Object? status = null,Object? thinking = null,Object? origin = null,Object? queuedAt = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? usage = freezed,Object? perf = freezed,Object? error = freezed,}) {
  return _then(_Run(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usage: freezed == usage ? _self._usage : usage // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,perf: freezed == perf ? _self._perf : perf // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OpenRun {

 String get runId; String get conversationId; String get status; bool get thinking; String get origin; DateTime get queuedAt; DateTime? get startedAt; DateTime? get endedAt; Map<String, Object?>? get usage; Map<String, Object?>? get perf; String? get error; int get position;
/// Create a copy of OpenRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenRunCopyWith<OpenRun> get copyWith => _$OpenRunCopyWithImpl<OpenRun>(this as OpenRun, _$identity);

  /// Serializes this OpenRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other.usage, usage)&&const DeepCollectionEquality().equals(other.perf, perf)&&(identical(other.error, error) || other.error == error)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,conversationId,status,thinking,origin,queuedAt,startedAt,endedAt,const DeepCollectionEquality().hash(usage),const DeepCollectionEquality().hash(perf),error,position);

@override
String toString() {
  return 'OpenRun(runId: $runId, conversationId: $conversationId, status: $status, thinking: $thinking, origin: $origin, queuedAt: $queuedAt, startedAt: $startedAt, endedAt: $endedAt, usage: $usage, perf: $perf, error: $error, position: $position)';
}


}

/// @nodoc
abstract mixin class $OpenRunCopyWith<$Res>  {
  factory $OpenRunCopyWith(OpenRun value, $Res Function(OpenRun) _then) = _$OpenRunCopyWithImpl;
@useResult
$Res call({
 String runId, String conversationId, String status, bool thinking, String origin, DateTime queuedAt, DateTime? startedAt, DateTime? endedAt, Map<String, Object?>? usage, Map<String, Object?>? perf, String? error, int position
});




}
/// @nodoc
class _$OpenRunCopyWithImpl<$Res>
    implements $OpenRunCopyWith<$Res> {
  _$OpenRunCopyWithImpl(this._self, this._then);

  final OpenRun _self;
  final $Res Function(OpenRun) _then;

/// Create a copy of OpenRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? conversationId = null,Object? status = null,Object? thinking = null,Object? origin = null,Object? queuedAt = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? usage = freezed,Object? perf = freezed,Object? error = freezed,Object? position = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,perf: freezed == perf ? _self.perf : perf // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenRun].
extension OpenRunPatterns on OpenRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenRun value)  $default,){
final _that = this;
switch (_that) {
case _OpenRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenRun value)?  $default,){
final _that = this;
switch (_that) {
case _OpenRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String conversationId,  String status,  bool thinking,  String origin,  DateTime queuedAt,  DateTime? startedAt,  DateTime? endedAt,  Map<String, Object?>? usage,  Map<String, Object?>? perf,  String? error,  int position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenRun() when $default != null:
return $default(_that.runId,_that.conversationId,_that.status,_that.thinking,_that.origin,_that.queuedAt,_that.startedAt,_that.endedAt,_that.usage,_that.perf,_that.error,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String conversationId,  String status,  bool thinking,  String origin,  DateTime queuedAt,  DateTime? startedAt,  DateTime? endedAt,  Map<String, Object?>? usage,  Map<String, Object?>? perf,  String? error,  int position)  $default,) {final _that = this;
switch (_that) {
case _OpenRun():
return $default(_that.runId,_that.conversationId,_that.status,_that.thinking,_that.origin,_that.queuedAt,_that.startedAt,_that.endedAt,_that.usage,_that.perf,_that.error,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String conversationId,  String status,  bool thinking,  String origin,  DateTime queuedAt,  DateTime? startedAt,  DateTime? endedAt,  Map<String, Object?>? usage,  Map<String, Object?>? perf,  String? error,  int position)?  $default,) {final _that = this;
switch (_that) {
case _OpenRun() when $default != null:
return $default(_that.runId,_that.conversationId,_that.status,_that.thinking,_that.origin,_that.queuedAt,_that.startedAt,_that.endedAt,_that.usage,_that.perf,_that.error,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenRun implements OpenRun {
  const _OpenRun({required this.runId, required this.conversationId, required this.status, required this.thinking, required this.origin, required this.queuedAt, this.startedAt, this.endedAt, final  Map<String, Object?>? usage, final  Map<String, Object?>? perf, this.error, required this.position}): _usage = usage,_perf = perf;
  factory _OpenRun.fromJson(Map<String, dynamic> json) => _$OpenRunFromJson(json);

@override final  String runId;
@override final  String conversationId;
@override final  String status;
@override final  bool thinking;
@override final  String origin;
@override final  DateTime queuedAt;
@override final  DateTime? startedAt;
@override final  DateTime? endedAt;
 final  Map<String, Object?>? _usage;
@override Map<String, Object?>? get usage {
  final value = _usage;
  if (value == null) return null;
  if (_usage is EqualUnmodifiableMapView) return _usage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, Object?>? _perf;
@override Map<String, Object?>? get perf {
  final value = _perf;
  if (value == null) return null;
  if (_perf is EqualUnmodifiableMapView) return _perf;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? error;
@override final  int position;

/// Create a copy of OpenRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenRunCopyWith<_OpenRun> get copyWith => __$OpenRunCopyWithImpl<_OpenRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenRunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other._usage, _usage)&&const DeepCollectionEquality().equals(other._perf, _perf)&&(identical(other.error, error) || other.error == error)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,conversationId,status,thinking,origin,queuedAt,startedAt,endedAt,const DeepCollectionEquality().hash(_usage),const DeepCollectionEquality().hash(_perf),error,position);

@override
String toString() {
  return 'OpenRun(runId: $runId, conversationId: $conversationId, status: $status, thinking: $thinking, origin: $origin, queuedAt: $queuedAt, startedAt: $startedAt, endedAt: $endedAt, usage: $usage, perf: $perf, error: $error, position: $position)';
}


}

/// @nodoc
abstract mixin class _$OpenRunCopyWith<$Res> implements $OpenRunCopyWith<$Res> {
  factory _$OpenRunCopyWith(_OpenRun value, $Res Function(_OpenRun) _then) = __$OpenRunCopyWithImpl;
@override @useResult
$Res call({
 String runId, String conversationId, String status, bool thinking, String origin, DateTime queuedAt, DateTime? startedAt, DateTime? endedAt, Map<String, Object?>? usage, Map<String, Object?>? perf, String? error, int position
});




}
/// @nodoc
class __$OpenRunCopyWithImpl<$Res>
    implements _$OpenRunCopyWith<$Res> {
  __$OpenRunCopyWithImpl(this._self, this._then);

  final _OpenRun _self;
  final $Res Function(_OpenRun) _then;

/// Create a copy of OpenRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? conversationId = null,Object? status = null,Object? thinking = null,Object? origin = null,Object? queuedAt = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? usage = freezed,Object? perf = freezed,Object? error = freezed,Object? position = null,}) {
  return _then(_OpenRun(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usage: freezed == usage ? _self._usage : usage // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,perf: freezed == perf ? _self._perf : perf // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
