import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// `conversation` shape (REST, `conversation.created/updated`, `ack` of `sync`).
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    String? title,

    /// The latest user/assistant text, ≤ 200 characters (API 3).
    String? preview,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool archived,
    required bool thinking,
    required String origin,
    String? lastRunId,
    required ContextFill context,
    required TokenTotals totals,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, Object?> json) =>
      _$ConversationFromJson(json);
}

/// How full the context window is (`warn` = pct ≥ 75).
@freezed
abstract class ContextFill with _$ContextFill {
  const factory ContextFill({
    int? tokens,
    int? max,
    double? pct,
    required bool warn,
    DateTime? measuredAt,
  }) = _ContextFill;

  factory ContextFill.fromJson(Map<String, Object?> json) =>
      _$ContextFillFromJson(json);
}

/// Token spend summed over a conversation's runs.
@freezed
abstract class TokenTotals with _$TokenTotals {
  const factory TokenTotals({
    required int inputTokens,
    required int outputTokens,
    required int cacheReadTokens,
    required int totalTokens,
  }) = _TokenTotals;

  factory TokenTotals.fromJson(Map<String, Object?> json) =>
      _$TokenTotalsFromJson(json);
}
