import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_card.freezed.dart';
part 'agent_card.g.dart';

/// `card` shape (`GET /cards`, `card.new`): an event the agent or one of its
/// scripts published for the dashboard (plan 5). `payload` depends on `type`
/// (`water`: station, level_cm, measured_at, trend_cm_24h, lake_avg_cm, …).
@freezed
abstract class AgentCard with _$AgentCard {
  const factory AgentCard({
    required String id,
    required String type,

    /// `info` | `warn` | `alert`.
    required String severity,
    required DateTime ts,

    /// `agent` | `script` | `backend`.
    required String origin,
    String? sessionId,
    required Map<String, Object?> payload,
    required DateTime receivedAt,
  }) = _AgentCard;

  factory AgentCard.fromJson(Map<String, Object?> json) =>
      _$AgentCardFromJson(json);
}
