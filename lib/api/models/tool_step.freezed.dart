// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ToolStep {

 int get id; String get runId; String get tool; String get status; String? get preview; Map<String, Object?>? get result; String? get resultRaw; String? get userSummary; double? get durationS; int? get seqStarted; int? get seqCompleted; String? get approvalRequestId; Approval? get approval;
/// Create a copy of ToolStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolStepCopyWith<ToolStep> get copyWith => _$ToolStepCopyWithImpl<ToolStep>(this as ToolStep, _$identity);

  /// Serializes this ToolStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolStep&&(identical(other.id, id) || other.id == id)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.status, status) || other.status == status)&&(identical(other.preview, preview) || other.preview == preview)&&const DeepCollectionEquality().equals(other.result, result)&&(identical(other.resultRaw, resultRaw) || other.resultRaw == resultRaw)&&(identical(other.userSummary, userSummary) || other.userSummary == userSummary)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.seqStarted, seqStarted) || other.seqStarted == seqStarted)&&(identical(other.seqCompleted, seqCompleted) || other.seqCompleted == seqCompleted)&&(identical(other.approvalRequestId, approvalRequestId) || other.approvalRequestId == approvalRequestId)&&(identical(other.approval, approval) || other.approval == approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runId,tool,status,preview,const DeepCollectionEquality().hash(result),resultRaw,userSummary,durationS,seqStarted,seqCompleted,approvalRequestId,approval);

@override
String toString() {
  return 'ToolStep(id: $id, runId: $runId, tool: $tool, status: $status, preview: $preview, result: $result, resultRaw: $resultRaw, userSummary: $userSummary, durationS: $durationS, seqStarted: $seqStarted, seqCompleted: $seqCompleted, approvalRequestId: $approvalRequestId, approval: $approval)';
}


}

/// @nodoc
abstract mixin class $ToolStepCopyWith<$Res>  {
  factory $ToolStepCopyWith(ToolStep value, $Res Function(ToolStep) _then) = _$ToolStepCopyWithImpl;
@useResult
$Res call({
 int id, String runId, String tool, String status, String? preview, Map<String, Object?>? result, String? resultRaw, String? userSummary, double? durationS, int? seqStarted, int? seqCompleted, String? approvalRequestId, Approval? approval
});


$ApprovalCopyWith<$Res>? get approval;

}
/// @nodoc
class _$ToolStepCopyWithImpl<$Res>
    implements $ToolStepCopyWith<$Res> {
  _$ToolStepCopyWithImpl(this._self, this._then);

  final ToolStep _self;
  final $Res Function(ToolStep) _then;

/// Create a copy of ToolStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? runId = null,Object? tool = null,Object? status = null,Object? preview = freezed,Object? result = freezed,Object? resultRaw = freezed,Object? userSummary = freezed,Object? durationS = freezed,Object? seqStarted = freezed,Object? seqCompleted = freezed,Object? approvalRequestId = freezed,Object? approval = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,resultRaw: freezed == resultRaw ? _self.resultRaw : resultRaw // ignore: cast_nullable_to_non_nullable
as String?,userSummary: freezed == userSummary ? _self.userSummary : userSummary // ignore: cast_nullable_to_non_nullable
as String?,durationS: freezed == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as double?,seqStarted: freezed == seqStarted ? _self.seqStarted : seqStarted // ignore: cast_nullable_to_non_nullable
as int?,seqCompleted: freezed == seqCompleted ? _self.seqCompleted : seqCompleted // ignore: cast_nullable_to_non_nullable
as int?,approvalRequestId: freezed == approvalRequestId ? _self.approvalRequestId : approvalRequestId // ignore: cast_nullable_to_non_nullable
as String?,approval: freezed == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as Approval?,
  ));
}
/// Create a copy of ToolStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApprovalCopyWith<$Res>? get approval {
    if (_self.approval == null) {
    return null;
  }

  return $ApprovalCopyWith<$Res>(_self.approval!, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// Adds pattern-matching-related methods to [ToolStep].
extension ToolStepPatterns on ToolStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolStep value)  $default,){
final _that = this;
switch (_that) {
case _ToolStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolStep value)?  $default,){
final _that = this;
switch (_that) {
case _ToolStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String runId,  String tool,  String status,  String? preview,  Map<String, Object?>? result,  String? resultRaw,  String? userSummary,  double? durationS,  int? seqStarted,  int? seqCompleted,  String? approvalRequestId,  Approval? approval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolStep() when $default != null:
return $default(_that.id,_that.runId,_that.tool,_that.status,_that.preview,_that.result,_that.resultRaw,_that.userSummary,_that.durationS,_that.seqStarted,_that.seqCompleted,_that.approvalRequestId,_that.approval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String runId,  String tool,  String status,  String? preview,  Map<String, Object?>? result,  String? resultRaw,  String? userSummary,  double? durationS,  int? seqStarted,  int? seqCompleted,  String? approvalRequestId,  Approval? approval)  $default,) {final _that = this;
switch (_that) {
case _ToolStep():
return $default(_that.id,_that.runId,_that.tool,_that.status,_that.preview,_that.result,_that.resultRaw,_that.userSummary,_that.durationS,_that.seqStarted,_that.seqCompleted,_that.approvalRequestId,_that.approval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String runId,  String tool,  String status,  String? preview,  Map<String, Object?>? result,  String? resultRaw,  String? userSummary,  double? durationS,  int? seqStarted,  int? seqCompleted,  String? approvalRequestId,  Approval? approval)?  $default,) {final _that = this;
switch (_that) {
case _ToolStep() when $default != null:
return $default(_that.id,_that.runId,_that.tool,_that.status,_that.preview,_that.result,_that.resultRaw,_that.userSummary,_that.durationS,_that.seqStarted,_that.seqCompleted,_that.approvalRequestId,_that.approval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ToolStep implements ToolStep {
  const _ToolStep({required this.id, required this.runId, required this.tool, required this.status, this.preview, final  Map<String, Object?>? result, this.resultRaw, this.userSummary, this.durationS, this.seqStarted, this.seqCompleted, this.approvalRequestId, this.approval}): _result = result;
  factory _ToolStep.fromJson(Map<String, dynamic> json) => _$ToolStepFromJson(json);

@override final  int id;
@override final  String runId;
@override final  String tool;
@override final  String status;
@override final  String? preview;
 final  Map<String, Object?>? _result;
@override Map<String, Object?>? get result {
  final value = _result;
  if (value == null) return null;
  if (_result is EqualUnmodifiableMapView) return _result;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? resultRaw;
@override final  String? userSummary;
@override final  double? durationS;
@override final  int? seqStarted;
@override final  int? seqCompleted;
@override final  String? approvalRequestId;
@override final  Approval? approval;

/// Create a copy of ToolStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolStepCopyWith<_ToolStep> get copyWith => __$ToolStepCopyWithImpl<_ToolStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ToolStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolStep&&(identical(other.id, id) || other.id == id)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.status, status) || other.status == status)&&(identical(other.preview, preview) || other.preview == preview)&&const DeepCollectionEquality().equals(other._result, _result)&&(identical(other.resultRaw, resultRaw) || other.resultRaw == resultRaw)&&(identical(other.userSummary, userSummary) || other.userSummary == userSummary)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.seqStarted, seqStarted) || other.seqStarted == seqStarted)&&(identical(other.seqCompleted, seqCompleted) || other.seqCompleted == seqCompleted)&&(identical(other.approvalRequestId, approvalRequestId) || other.approvalRequestId == approvalRequestId)&&(identical(other.approval, approval) || other.approval == approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runId,tool,status,preview,const DeepCollectionEquality().hash(_result),resultRaw,userSummary,durationS,seqStarted,seqCompleted,approvalRequestId,approval);

@override
String toString() {
  return 'ToolStep(id: $id, runId: $runId, tool: $tool, status: $status, preview: $preview, result: $result, resultRaw: $resultRaw, userSummary: $userSummary, durationS: $durationS, seqStarted: $seqStarted, seqCompleted: $seqCompleted, approvalRequestId: $approvalRequestId, approval: $approval)';
}


}

/// @nodoc
abstract mixin class _$ToolStepCopyWith<$Res> implements $ToolStepCopyWith<$Res> {
  factory _$ToolStepCopyWith(_ToolStep value, $Res Function(_ToolStep) _then) = __$ToolStepCopyWithImpl;
@override @useResult
$Res call({
 int id, String runId, String tool, String status, String? preview, Map<String, Object?>? result, String? resultRaw, String? userSummary, double? durationS, int? seqStarted, int? seqCompleted, String? approvalRequestId, Approval? approval
});


@override $ApprovalCopyWith<$Res>? get approval;

}
/// @nodoc
class __$ToolStepCopyWithImpl<$Res>
    implements _$ToolStepCopyWith<$Res> {
  __$ToolStepCopyWithImpl(this._self, this._then);

  final _ToolStep _self;
  final $Res Function(_ToolStep) _then;

/// Create a copy of ToolStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? runId = null,Object? tool = null,Object? status = null,Object? preview = freezed,Object? result = freezed,Object? resultRaw = freezed,Object? userSummary = freezed,Object? durationS = freezed,Object? seqStarted = freezed,Object? seqCompleted = freezed,Object? approvalRequestId = freezed,Object? approval = freezed,}) {
  return _then(_ToolStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self._result : result // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,resultRaw: freezed == resultRaw ? _self.resultRaw : resultRaw // ignore: cast_nullable_to_non_nullable
as String?,userSummary: freezed == userSummary ? _self.userSummary : userSummary // ignore: cast_nullable_to_non_nullable
as String?,durationS: freezed == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as double?,seqStarted: freezed == seqStarted ? _self.seqStarted : seqStarted // ignore: cast_nullable_to_non_nullable
as int?,seqCompleted: freezed == seqCompleted ? _self.seqCompleted : seqCompleted // ignore: cast_nullable_to_non_nullable
as int?,approvalRequestId: freezed == approvalRequestId ? _self.approvalRequestId : approvalRequestId // ignore: cast_nullable_to_non_nullable
as String?,approval: freezed == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as Approval?,
  ));
}

/// Create a copy of ToolStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApprovalCopyWith<$Res>? get approval {
    if (_self.approval == null) {
    return null;
  }

  return $ApprovalCopyWith<$Res>(_self.approval!, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}

// dart format on
