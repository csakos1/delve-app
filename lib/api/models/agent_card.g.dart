// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentCard _$AgentCardFromJson(Map<String, dynamic> json) => _AgentCard(
  id: json['id'] as String,
  type: json['type'] as String,
  severity: json['severity'] as String,
  ts: DateTime.parse(json['ts'] as String),
  origin: json['origin'] as String,
  sessionId: json['session_id'] as String?,
  payload: json['payload'] as Map<String, dynamic>,
  receivedAt: DateTime.parse(json['received_at'] as String),
);

Map<String, dynamic> _$AgentCardToJson(_AgentCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'severity': instance.severity,
      'ts': instance.ts.toIso8601String(),
      'origin': instance.origin,
      'session_id': instance.sessionId,
      'payload': instance.payload,
      'received_at': instance.receivedAt.toIso8601String(),
    };
