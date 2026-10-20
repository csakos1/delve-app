// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Approval {

 String get requestId; String get runId; String get conversationId; String get command; String? get description; List<String> get patternKeys; String get actionClass; String get status; String? get choice; List<String> get choices; String? get decidedBy; DateTime get createdAt; DateTime get hermesDeadline; DateTime get expiresAt; DateTime? get respondedAt;
/// Create a copy of Approval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalCopyWith<Approval> get copyWith => _$ApprovalCopyWithImpl<Approval>(this as Approval, _$identity);

  /// Serializes this Approval to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Approval&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.command, command) || other.command == command)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.patternKeys, patternKeys)&&(identical(other.actionClass, actionClass) || other.actionClass == actionClass)&&(identical(other.status, status) || other.status == status)&&(identical(other.choice, choice) || other.choice == choice)&&const DeepCollectionEquality().equals(other.choices, choices)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.hermesDeadline, hermesDeadline) || other.hermesDeadline == hermesDeadline)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,runId,conversationId,command,description,const DeepCollectionEquality().hash(patternKeys),actionClass,status,choice,const DeepCollectionEquality().hash(choices),decidedBy,createdAt,hermesDeadline,expiresAt,respondedAt);

@override
String toString() {
  return 'Approval(requestId: $requestId, runId: $runId, conversationId: $conversationId, command: $command, description: $description, patternKeys: $patternKeys, actionClass: $actionClass, status: $status, choice: $choice, choices: $choices, decidedBy: $decidedBy, createdAt: $createdAt, hermesDeadline: $hermesDeadline, expiresAt: $expiresAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class $ApprovalCopyWith<$Res>  {
  factory $ApprovalCopyWith(Approval value, $Res Function(Approval) _then) = _$ApprovalCopyWithImpl;
@useResult
$Res call({
 String requestId, String runId, String conversationId, String command, String? description, List<String> patternKeys, String actionClass, String status, String? choice, List<String> choices, String? decidedBy, DateTime createdAt, DateTime hermesDeadline, DateTime expiresAt, DateTime? respondedAt
});




}
/// @nodoc
class _$ApprovalCopyWithImpl<$Res>
    implements $ApprovalCopyWith<$Res> {
  _$ApprovalCopyWithImpl(this._self, this._then);

  final Approval _self;
  final $Res Function(Approval) _then;

/// Create a copy of Approval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? runId = null,Object? conversationId = null,Object? command = null,Object? description = freezed,Object? patternKeys = null,Object? actionClass = null,Object? status = null,Object? choice = freezed,Object? choices = null,Object? decidedBy = freezed,Object? createdAt = null,Object? hermesDeadline = null,Object? expiresAt = null,Object? respondedAt = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,patternKeys: null == patternKeys ? _self.patternKeys : patternKeys // ignore: cast_nullable_to_non_nullable
as List<String>,actionClass: null == actionClass ? _self.actionClass : actionClass // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,choice: freezed == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as String?,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,hermesDeadline: null == hermesDeadline ? _self.hermesDeadline : hermesDeadline // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Approval].
extension ApprovalPatterns on Approval {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Approval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Approval() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Approval value)  $default,){
final _that = this;
switch (_that) {
case _Approval():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Approval value)?  $default,){
final _that = this;
switch (_that) {
case _Approval() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  String runId,  String conversationId,  String command,  String? description,  List<String> patternKeys,  String actionClass,  String status,  String? choice,  List<String> choices,  String? decidedBy,  DateTime createdAt,  DateTime hermesDeadline,  DateTime expiresAt,  DateTime? respondedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Approval() when $default != null:
return $default(_that.requestId,_that.runId,_that.conversationId,_that.command,_that.description,_that.patternKeys,_that.actionClass,_that.status,_that.choice,_that.choices,_that.decidedBy,_that.createdAt,_that.hermesDeadline,_that.expiresAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  String runId,  String conversationId,  String command,  String? description,  List<String> patternKeys,  String actionClass,  String status,  String? choice,  List<String> choices,  String? decidedBy,  DateTime createdAt,  DateTime hermesDeadline,  DateTime expiresAt,  DateTime? respondedAt)  $default,) {final _that = this;
switch (_that) {
case _Approval():
return $default(_that.requestId,_that.runId,_that.conversationId,_that.command,_that.description,_that.patternKeys,_that.actionClass,_that.status,_that.choice,_that.choices,_that.decidedBy,_that.createdAt,_that.hermesDeadline,_that.expiresAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  String runId,  String conversationId,  String command,  String? description,  List<String> patternKeys,  String actionClass,  String status,  String? choice,  List<String> choices,  String? decidedBy,  DateTime createdAt,  DateTime hermesDeadline,  DateTime expiresAt,  DateTime? respondedAt)?  $default,) {final _that = this;
switch (_that) {
case _Approval() when $default != null:
return $default(_that.requestId,_that.runId,_that.conversationId,_that.command,_that.description,_that.patternKeys,_that.actionClass,_that.status,_that.choice,_that.choices,_that.decidedBy,_that.createdAt,_that.hermesDeadline,_that.expiresAt,_that.respondedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Approval implements Approval {
  const _Approval({required this.requestId, required this.runId, required this.conversationId, required this.command, this.description, required final  List<String> patternKeys, required this.actionClass, required this.status, this.choice, required final  List<String> choices, this.decidedBy, required this.createdAt, required this.hermesDeadline, required this.expiresAt, this.respondedAt}): _patternKeys = patternKeys,_choices = choices;
  factory _Approval.fromJson(Map<String, dynamic> json) => _$ApprovalFromJson(json);

@override final  String requestId;
@override final  String runId;
@override final  String conversationId;
@override final  String command;
@override final  String? description;
 final  List<String> _patternKeys;
@override List<String> get patternKeys {
  if (_patternKeys is EqualUnmodifiableListView) return _patternKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patternKeys);
}

@override final  String actionClass;
@override final  String status;
@override final  String? choice;
 final  List<String> _choices;
@override List<String> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}

@override final  String? decidedBy;
@override final  DateTime createdAt;
@override final  DateTime hermesDeadline;
@override final  DateTime expiresAt;
@override final  DateTime? respondedAt;

/// Create a copy of Approval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalCopyWith<_Approval> get copyWith => __$ApprovalCopyWithImpl<_Approval>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Approval&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.command, command) || other.command == command)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._patternKeys, _patternKeys)&&(identical(other.actionClass, actionClass) || other.actionClass == actionClass)&&(identical(other.status, status) || other.status == status)&&(identical(other.choice, choice) || other.choice == choice)&&const DeepCollectionEquality().equals(other._choices, _choices)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.hermesDeadline, hermesDeadline) || other.hermesDeadline == hermesDeadline)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,runId,conversationId,command,description,const DeepCollectionEquality().hash(_patternKeys),actionClass,status,choice,const DeepCollectionEquality().hash(_choices),decidedBy,createdAt,hermesDeadline,expiresAt,respondedAt);

@override
String toString() {
  return 'Approval(requestId: $requestId, runId: $runId, conversationId: $conversationId, command: $command, description: $description, patternKeys: $patternKeys, actionClass: $actionClass, status: $status, choice: $choice, choices: $choices, decidedBy: $decidedBy, createdAt: $createdAt, hermesDeadline: $hermesDeadline, expiresAt: $expiresAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class _$ApprovalCopyWith<$Res> implements $ApprovalCopyWith<$Res> {
  factory _$ApprovalCopyWith(_Approval value, $Res Function(_Approval) _then) = __$ApprovalCopyWithImpl;
@override @useResult
$Res call({
 String requestId, String runId, String conversationId, String command, String? description, List<String> patternKeys, String actionClass, String status, String? choice, List<String> choices, String? decidedBy, DateTime createdAt, DateTime hermesDeadline, DateTime expiresAt, DateTime? respondedAt
});




}
/// @nodoc
class __$ApprovalCopyWithImpl<$Res>
    implements _$ApprovalCopyWith<$Res> {
  __$ApprovalCopyWithImpl(this._self, this._then);

  final _Approval _self;
  final $Res Function(_Approval) _then;

/// Create a copy of Approval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? runId = null,Object? conversationId = null,Object? command = null,Object? description = freezed,Object? patternKeys = null,Object? actionClass = null,Object? status = null,Object? choice = freezed,Object? choices = null,Object? decidedBy = freezed,Object? createdAt = null,Object? hermesDeadline = null,Object? expiresAt = null,Object? respondedAt = freezed,}) {
  return _then(_Approval(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,patternKeys: null == patternKeys ? _self._patternKeys : patternKeys // ignore: cast_nullable_to_non_nullable
as List<String>,actionClass: null == actionClass ? _self.actionClass : actionClass // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,choice: freezed == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as String?,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,hermesDeadline: null == hermesDeadline ? _self.hermesDeadline : hermesDeadline // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
