// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Schedule _$ScheduleFromJson(Map<String, dynamic> json) => _Schedule(
  id: json['id'] as String,
  kind: json['kind'] as String,
  name: json['name'] as String,
  cron: json['cron'] as String,
  description: json['description'] as String,
  prompt: json['prompt'] as String?,
  conversationMode: json['conversation_mode'] as String,
  conversationId: json['conversation_id'] as String?,
  conversationTitle: json['conversation_title'] as String?,
  thinking: json['thinking'] as bool,
  enabled: json['enabled'] as bool,
  nextRunAt: json['next_run_at'] == null
      ? null
      : DateTime.parse(json['next_run_at'] as String),
  lastRunAt: json['last_run_at'] == null
      ? null
      : DateTime.parse(json['last_run_at'] as String),
  lastStatus: json['last_status'] as String?,
  lastError: json['last_error'] as String?,
  lastRunId: json['last_run_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ScheduleToJson(_Schedule instance) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'name': instance.name,
  'cron': instance.cron,
  'description': instance.description,
  'prompt': instance.prompt,
  'conversation_mode': instance.conversationMode,
  'conversation_id': instance.conversationId,
  'conversation_title': instance.conversationTitle,
  'thinking': instance.thinking,
  'enabled': instance.enabled,
  'next_run_at': instance.nextRunAt?.toIso8601String(),
  'last_run_at': instance.lastRunAt?.toIso8601String(),
  'last_status': instance.lastStatus,
  'last_error': instance.lastError,
  'last_run_id': instance.lastRunId,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
