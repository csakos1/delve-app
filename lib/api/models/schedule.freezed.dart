// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Schedule {

 String get id;/// `prompt` | `brief`.
 String get kind; String get name; String get cron;/// The server's English reading of [cron] ("At 07:30 every day").
 String get description;/// null for the brief.
 String? get prompt;/// `new` (a new chat each run) | `fixed` ([conversationId]).
 String get conversationMode; String? get conversationId; String? get conversationTitle; bool get thinking; bool get enabled;/// null while disabled.
 DateTime? get nextRunAt; DateTime? get lastRunAt;/// A prompt's last run status (`queued` … `completed`, `failed`,
/// `cancelled`); the brief's `ok` | `failed`.
 String? get lastStatus; String? get lastError; String? get lastRunId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleCopyWith<Schedule> get copyWith => _$ScheduleCopyWithImpl<Schedule>(this as Schedule, _$identity);

  /// Serializes this Schedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Schedule&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.cron, cron) || other.cron == cron)&&(identical(other.description, description) || other.description == description)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.conversationMode, conversationMode) || other.conversationMode == conversationMode)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.nextRunAt, nextRunAt) || other.nextRunAt == nextRunAt)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastRunId, lastRunId) || other.lastRunId == lastRunId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,cron,description,prompt,conversationMode,conversationId,conversationTitle,thinking,enabled,nextRunAt,lastRunAt,lastStatus,lastError,lastRunId,createdAt,updatedAt);

@override
String toString() {
  return 'Schedule(id: $id, kind: $kind, name: $name, cron: $cron, description: $description, prompt: $prompt, conversationMode: $conversationMode, conversationId: $conversationId, conversationTitle: $conversationTitle, thinking: $thinking, enabled: $enabled, nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, lastStatus: $lastStatus, lastError: $lastError, lastRunId: $lastRunId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ScheduleCopyWith<$Res>  {
  factory $ScheduleCopyWith(Schedule value, $Res Function(Schedule) _then) = _$ScheduleCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String name, String cron, String description, String? prompt, String conversationMode, String? conversationId, String? conversationTitle, bool thinking, bool enabled, DateTime? nextRunAt, DateTime? lastRunAt, String? lastStatus, String? lastError, String? lastRunId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ScheduleCopyWithImpl<$Res>
    implements $ScheduleCopyWith<$Res> {
  _$ScheduleCopyWithImpl(this._self, this._then);

  final Schedule _self;
  final $Res Function(Schedule) _then;

/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? cron = null,Object? description = null,Object? prompt = freezed,Object? conversationMode = null,Object? conversationId = freezed,Object? conversationTitle = freezed,Object? thinking = null,Object? enabled = null,Object? nextRunAt = freezed,Object? lastRunAt = freezed,Object? lastStatus = freezed,Object? lastError = freezed,Object? lastRunId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cron: null == cron ? _self.cron : cron // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prompt: freezed == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String?,conversationMode: null == conversationMode ? _self.conversationMode : conversationMode // ignore: cast_nullable_to_non_nullable
as String,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,conversationTitle: freezed == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String?,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,nextRunAt: freezed == nextRunAt ? _self.nextRunAt : nextRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastRunId: freezed == lastRunId ? _self.lastRunId : lastRunId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Schedule].
extension SchedulePatterns on Schedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Schedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Schedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Schedule value)  $default,){
final _that = this;
switch (_that) {
case _Schedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Schedule value)?  $default,){
final _that = this;
switch (_that) {
case _Schedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String name,  String cron,  String description,  String? prompt,  String conversationMode,  String? conversationId,  String? conversationTitle,  bool thinking,  bool enabled,  DateTime? nextRunAt,  DateTime? lastRunAt,  String? lastStatus,  String? lastError,  String? lastRunId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Schedule() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.cron,_that.description,_that.prompt,_that.conversationMode,_that.conversationId,_that.conversationTitle,_that.thinking,_that.enabled,_that.nextRunAt,_that.lastRunAt,_that.lastStatus,_that.lastError,_that.lastRunId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String name,  String cron,  String description,  String? prompt,  String conversationMode,  String? conversationId,  String? conversationTitle,  bool thinking,  bool enabled,  DateTime? nextRunAt,  DateTime? lastRunAt,  String? lastStatus,  String? lastError,  String? lastRunId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Schedule():
return $default(_that.id,_that.kind,_that.name,_that.cron,_that.description,_that.prompt,_that.conversationMode,_that.conversationId,_that.conversationTitle,_that.thinking,_that.enabled,_that.nextRunAt,_that.lastRunAt,_that.lastStatus,_that.lastError,_that.lastRunId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String name,  String cron,  String description,  String? prompt,  String conversationMode,  String? conversationId,  String? conversationTitle,  bool thinking,  bool enabled,  DateTime? nextRunAt,  DateTime? lastRunAt,  String? lastStatus,  String? lastError,  String? lastRunId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Schedule() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.cron,_that.description,_that.prompt,_that.conversationMode,_that.conversationId,_that.conversationTitle,_that.thinking,_that.enabled,_that.nextRunAt,_that.lastRunAt,_that.lastStatus,_that.lastError,_that.lastRunId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Schedule implements Schedule {
  const _Schedule({required this.id, required this.kind, required this.name, required this.cron, required this.description, this.prompt, required this.conversationMode, this.conversationId, this.conversationTitle, required this.thinking, required this.enabled, this.nextRunAt, this.lastRunAt, this.lastStatus, this.lastError, this.lastRunId, required this.createdAt, required this.updatedAt});
  factory _Schedule.fromJson(Map<String, dynamic> json) => _$ScheduleFromJson(json);

@override final  String id;
/// `prompt` | `brief`.
@override final  String kind;
@override final  String name;
@override final  String cron;
/// The server's English reading of [cron] ("At 07:30 every day").
@override final  String description;
/// null for the brief.
@override final  String? prompt;
/// `new` (a new chat each run) | `fixed` ([conversationId]).
@override final  String conversationMode;
@override final  String? conversationId;
@override final  String? conversationTitle;
@override final  bool thinking;
@override final  bool enabled;
/// null while disabled.
@override final  DateTime? nextRunAt;
@override final  DateTime? lastRunAt;
/// A prompt's last run status (`queued` … `completed`, `failed`,
/// `cancelled`); the brief's `ok` | `failed`.
@override final  String? lastStatus;
@override final  String? lastError;
@override final  String? lastRunId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleCopyWith<_Schedule> get copyWith => __$ScheduleCopyWithImpl<_Schedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Schedule&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.cron, cron) || other.cron == cron)&&(identical(other.description, description) || other.description == description)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.conversationMode, conversationMode) || other.conversationMode == conversationMode)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.nextRunAt, nextRunAt) || other.nextRunAt == nextRunAt)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastRunId, lastRunId) || other.lastRunId == lastRunId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,cron,description,prompt,conversationMode,conversationId,conversationTitle,thinking,enabled,nextRunAt,lastRunAt,lastStatus,lastError,lastRunId,createdAt,updatedAt);

@override
String toString() {
  return 'Schedule(id: $id, kind: $kind, name: $name, cron: $cron, description: $description, prompt: $prompt, conversationMode: $conversationMode, conversationId: $conversationId, conversationTitle: $conversationTitle, thinking: $thinking, enabled: $enabled, nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, lastStatus: $lastStatus, lastError: $lastError, lastRunId: $lastRunId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ScheduleCopyWith<$Res> implements $ScheduleCopyWith<$Res> {
  factory _$ScheduleCopyWith(_Schedule value, $Res Function(_Schedule) _then) = __$ScheduleCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String name, String cron, String description, String? prompt, String conversationMode, String? conversationId, String? conversationTitle, bool thinking, bool enabled, DateTime? nextRunAt, DateTime? lastRunAt, String? lastStatus, String? lastError, String? lastRunId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ScheduleCopyWithImpl<$Res>
    implements _$ScheduleCopyWith<$Res> {
  __$ScheduleCopyWithImpl(this._self, this._then);

  final _Schedule _self;
  final $Res Function(_Schedule) _then;

/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? cron = null,Object? description = null,Object? prompt = freezed,Object? conversationMode = null,Object? conversationId = freezed,Object? conversationTitle = freezed,Object? thinking = null,Object? enabled = null,Object? nextRunAt = freezed,Object? lastRunAt = freezed,Object? lastStatus = freezed,Object? lastError = freezed,Object? lastRunId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Schedule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cron: null == cron ? _self.cron : cron // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prompt: freezed == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String?,conversationMode: null == conversationMode ? _self.conversationMode : conversationMode // ignore: cast_nullable_to_non_nullable
as String,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,conversationTitle: freezed == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String?,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,nextRunAt: freezed == nextRunAt ? _self.nextRunAt : nextRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastRunId: freezed == lastRunId ? _self.lastRunId : lastRunId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
