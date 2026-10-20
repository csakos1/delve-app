// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Run _$RunFromJson(Map<String, dynamic> json) => _Run(
  runId: json['run_id'] as String,
  conversationId: json['conversation_id'] as String,
  status: json['status'] as String,
  thinking: json['thinking'] as bool,
  origin: json['origin'] as String,
  queuedAt: DateTime.parse(json['queued_at'] as String),
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  usage: json['usage'] as Map<String, dynamic>?,
  perf: json['perf'] as Map<String, dynamic>?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$RunToJson(_Run instance) => <String, dynamic>{
  'run_id': instance.runId,
  'conversation_id': instance.conversationId,
  'status': instance.status,
  'thinking': instance.thinking,
  'origin': instance.origin,
  'queued_at': instance.queuedAt.toIso8601String(),
  'started_at': instance.startedAt?.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'usage': instance.usage,
  'perf': instance.perf,
  'error': instance.error,
};

_OpenRun _$OpenRunFromJson(Map<String, dynamic> json) => _OpenRun(
  runId: json['run_id'] as String,
  conversationId: json['conversation_id'] as String,
  status: json['status'] as String,
  thinking: json['thinking'] as bool,
  origin: json['origin'] as String,
  queuedAt: DateTime.parse(json['queued_at'] as String),
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  usage: json['usage'] as Map<String, dynamic>?,
  perf: json['perf'] as Map<String, dynamic>?,
  error: json['error'] as String?,
  position: (json['position'] as num).toInt(),
);

Map<String, dynamic> _$OpenRunToJson(_OpenRun instance) => <String, dynamic>{
  'run_id': instance.runId,
  'conversation_id': instance.conversationId,
  'status': instance.status,
  'thinking': instance.thinking,
  'origin': instance.origin,
  'queued_at': instance.queuedAt.toIso8601String(),
  'started_at': instance.startedAt?.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'usage': instance.usage,
  'perf': instance.perf,
  'error': instance.error,
  'position': instance.position,
};
