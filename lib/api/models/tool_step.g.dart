// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ToolStep _$ToolStepFromJson(Map<String, dynamic> json) => _ToolStep(
  id: (json['id'] as num).toInt(),
  runId: json['run_id'] as String,
  tool: json['tool'] as String,
  status: json['status'] as String,
  preview: json['preview'] as String?,
  result: json['result'] as Map<String, dynamic>?,
  resultRaw: json['result_raw'] as String?,
  userSummary: json['user_summary'] as String?,
  durationS: (json['duration_s'] as num?)?.toDouble(),
  seqStarted: (json['seq_started'] as num?)?.toInt(),
  seqCompleted: (json['seq_completed'] as num?)?.toInt(),
  approvalRequestId: json['approval_request_id'] as String?,
  approval: json['approval'] == null
      ? null
      : Approval.fromJson(json['approval'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ToolStepToJson(_ToolStep instance) => <String, dynamic>{
  'id': instance.id,
  'run_id': instance.runId,
  'tool': instance.tool,
  'status': instance.status,
  'preview': instance.preview,
  'result': instance.result,
  'result_raw': instance.resultRaw,
  'user_summary': instance.userSummary,
  'duration_s': instance.durationS,
  'seq_started': instance.seqStarted,
  'seq_completed': instance.seqCompleted,
  'approval_request_id': instance.approvalRequestId,
  'approval': instance.approval?.toJson(),
};
