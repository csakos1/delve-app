import 'package:freezed_annotation/freezed_annotation.dart';

import 'tool_step.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// `message` shape. `role`: user | assistant | system;
/// `status`: streaming | final | cancelled | failed.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required int id,
    required String conversationId,
    String? runId,
    required String role,
    required String content,
    String? interim,
    String? reasoning,
    required String status,
    String? clientMsgId,
    required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, Object?> json) =>
      _$MessageFromJson(json);
}

/// A message as REST `messages` and `sync` return it: assistant messages
/// carry their run's `tool_steps` (each with its `approval`, if any).
class HistoryMessage {
  const HistoryMessage(this.message, this.toolSteps);

  factory HistoryMessage.fromJson(Map<String, Object?> json) {
    final raw = json['tool_steps'];
    final steps = raw is List<Object?>
        ? [
            for (final s in raw)
              if (s is Map<String, Object?>) ToolStep.fromJson(s),
          ]
        : const <ToolStep>[];
    return HistoryMessage(Message.fromJson(json), steps);
  }

  final Message message;
  final List<ToolStep> toolSteps;
}
