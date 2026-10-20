// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      preview: json['preview'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      archived: json['archived'] as bool,
      thinking: json['thinking'] as bool,
      origin: json['origin'] as String,
      lastRunId: json['last_run_id'] as String?,
      context: ContextFill.fromJson(json['context'] as Map<String, dynamic>),
      totals: TokenTotals.fromJson(json['totals'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'preview': instance.preview,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'archived': instance.archived,
      'thinking': instance.thinking,
      'origin': instance.origin,
      'last_run_id': instance.lastRunId,
      'context': instance.context.toJson(),
      'totals': instance.totals.toJson(),
    };

_ContextFill _$ContextFillFromJson(Map<String, dynamic> json) => _ContextFill(
  tokens: (json['tokens'] as num?)?.toInt(),
  max: (json['max'] as num?)?.toInt(),
  pct: (json['pct'] as num?)?.toDouble(),
  warn: json['warn'] as bool,
  measuredAt: json['measured_at'] == null
      ? null
      : DateTime.parse(json['measured_at'] as String),
);

Map<String, dynamic> _$ContextFillToJson(_ContextFill instance) =>
    <String, dynamic>{
      'tokens': instance.tokens,
      'max': instance.max,
      'pct': instance.pct,
      'warn': instance.warn,
      'measured_at': instance.measuredAt?.toIso8601String(),
    };

_TokenTotals _$TokenTotalsFromJson(Map<String, dynamic> json) => _TokenTotals(
  inputTokens: (json['input_tokens'] as num).toInt(),
  outputTokens: (json['output_tokens'] as num).toInt(),
  cacheReadTokens: (json['cache_read_tokens'] as num).toInt(),
  totalTokens: (json['total_tokens'] as num).toInt(),
);

Map<String, dynamic> _$TokenTotalsToJson(_TokenTotals instance) =>
    <String, dynamic>{
      'input_tokens': instance.inputTokens,
      'output_tokens': instance.outputTokens,
      'cache_read_tokens': instance.cacheReadTokens,
      'total_tokens': instance.totalTokens,
    };
