// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Approval _$ApprovalFromJson(Map<String, dynamic> json) => _Approval(
  requestId: json['request_id'] as String,
  runId: json['run_id'] as String,
  conversationId: json['conversation_id'] as String,
  command: json['command'] as String,
  description: json['description'] as String?,
  patternKeys: (json['pattern_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  actionClass: json['action_class'] as String,
  status: json['status'] as String,
  choice: json['choice'] as String?,
  choices: (json['choices'] as List<dynamic>).map((e) => e as String).toList(),
  decidedBy: json['decided_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  hermesDeadline: DateTime.parse(json['hermes_deadline'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  respondedAt: json['responded_at'] == null
      ? null
      : DateTime.parse(json['responded_at'] as String),
);

Map<String, dynamic> _$ApprovalToJson(_Approval instance) => <String, dynamic>{
  'request_id': instance.requestId,
  'run_id': instance.runId,
  'conversation_id': instance.conversationId,
  'command': instance.command,
  'description': instance.description,
  'pattern_keys': instance.patternKeys,
  'action_class': instance.actionClass,
  'status': instance.status,
  'choice': instance.choice,
  'choices': instance.choices,
  'decided_by': instance.decidedBy,
  'created_at': instance.createdAt.toIso8601String(),
  'hermes_deadline': instance.hermesDeadline.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'responded_at': instance.respondedAt?.toIso8601String(),
};
