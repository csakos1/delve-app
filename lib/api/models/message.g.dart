// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: (json['id'] as num).toInt(),
  conversationId: json['conversation_id'] as String,
  runId: json['run_id'] as String?,
  role: json['role'] as String,
  content: json['content'] as String,
  interim: json['interim'] as String?,
  reasoning: json['reasoning'] as String?,
  status: json['status'] as String,
  clientMsgId: json['client_msg_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'conversation_id': instance.conversationId,
  'run_id': instance.runId,
  'role': instance.role,
  'content': instance.content,
  'interim': instance.interim,
  'reasoning': instance.reasoning,
  'status': instance.status,
  'client_msg_id': instance.clientMsgId,
  'created_at': instance.createdAt.toIso8601String(),
};
