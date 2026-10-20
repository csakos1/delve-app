// WebSocket frames from the server (delve-backend README, "WebSocket").
//
// Broadcast events arrive as `{type, seq, data}` and become a [ServerEvent];
// replies on one socket (`hello.ok`, `ack`, `error`, `pong`, `keepalive`)
// arrive without `seq` and become a [ConnectionFrame]. An event type this
// build does not know is kept as [UnknownEvent] (additive server changes must
// not break an older app); a known type with a malformed payload throws
// [FormatException].

import 'models/models.dart';

typedef Json = Map<String, Object?>;

/// Any frame the server sends.
sealed class IncomingFrame {
  const IncomingFrame();

  static IncomingFrame parse(Json frame) {
    final type = frame['type'];
    if (type is! String) throw const FormatException('frame without type');
    final raw = frame['data'];
    final Json data = switch (raw) {
      null => const <String, Object?>{},
      final Map<String, Object?> m => m,
      final Map<Object?, Object?> m => Map<String, Object?>.from(m),
      _ => throw FormatException('frame $type: data is not an object'),
    };
    final seq = frame['seq'];
    if (seq is int) return ServerEvent.fromData(type, seq, data);
    final id = frame['id'];
    final ref = id is String ? id : null;
    return switch (type) {
      'hello.ok' => HelloOkFrame(HelloOk.fromJson(data)),
      'ack' => AckFrame(ref, data),
      'error' => ErrorReply(
        ref,
        _str(data, 'code'),
        _strOrNull(data, 'message'),
      ),
      'pong' => PongFrame(ref),
      'keepalive' => const KeepaliveFrame(),
      _ => UnknownFrame(type, data),
    };
  }
}

// ---------------------------------------------------------------------------
// connection frames (no seq, never replayed)

sealed class ConnectionFrame extends IncomingFrame {
  const ConnectionFrame();
}

final class HelloOkFrame extends ConnectionFrame {
  const HelloOkFrame(this.hello);
  final HelloOk hello;
}

/// Reply to a client frame; [data] depends on the request (see README table).
final class AckFrame extends ConnectionFrame {
  const AckFrame(this.id, this.data);
  final String? id;
  final Json data;
}

final class ErrorReply extends ConnectionFrame {
  const ErrorReply(this.id, this.code, this.message);
  final String? id;
  final String code;
  final String? message;
}

final class PongFrame extends ConnectionFrame {
  const PongFrame(this.id);
  final String? id;
}

final class KeepaliveFrame extends ConnectionFrame {
  const KeepaliveFrame();
}

final class UnknownFrame extends ConnectionFrame {
  const UnknownFrame(this.type, this.data);
  final String type;
  final Json data;
}

// ---------------------------------------------------------------------------
// server events (global seq)

sealed class ServerEvent extends IncomingFrame {
  const ServerEvent(this.seq);

  final int seq;

  /// Event types this build understands; `test/contract_test.dart` checks it
  /// against the backend contract.
  static const Set<String> knownTypes = <String>{
    'conversation.created',
    'conversation.updated',
    'message.created',
    'message.updated',
    'message.delta',
    'message.interim',
    'run.queued',
    'run.started',
    'run.updated',
    'run.finished',
    'tool.started',
    'tool.completed',
    'approval.request',
    'approval.updated',
    'reasoning.final',
    'context.updated',
    'health.status',
    'card.new',
    'error',
  };

  static ServerEvent fromData(String type, int seq, Json d) => switch (type) {
    'conversation.created' => ConversationCreated(
      seq,
      Conversation.fromJson(d),
    ),
    'conversation.updated' => ConversationUpdated(
      seq,
      Conversation.fromJson(d),
    ),
    'message.created' => MessageCreated(
      seq,
      _str(d, 'conversation_id'),
      Message.fromJson(_obj(d, 'message')),
    ),
    'message.updated' => MessageUpdated(
      seq,
      _str(d, 'conversation_id'),
      Message.fromJson(_obj(d, 'message')),
    ),
    'message.delta' => MessageDelta(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      messageId: _int(d, 'message_id'),
      delta: _str(d, 'delta'),
    ),
    'message.interim' => MessageInterim(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      messageId: _int(d, 'message_id'),
      text: _str(d, 'text'),
    ),
    'run.queued' => RunQueued(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      position: _int(d, 'position'),
      thinking: _bool(d, 'thinking'),
      origin: _str(d, 'origin'),
    ),
    'run.started' => RunStarted(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      queuedId: _strOrNull(d, 'queued_id'),
      thinking: _bool(d, 'thinking'),
    ),
    'run.updated' => RunUpdated(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      status: _str(d, 'status'),
    ),
    'run.finished' => RunFinished(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      status: _str(d, 'status'),
      usage: _objOrNull(d, 'usage'),
      error: _strOrNull(d, 'error'),
    ),
    'tool.started' => ToolStarted(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      step: ToolStep.fromJson(_obj(d, 'step')),
    ),
    'tool.completed' => ToolCompleted(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      step: ToolStep.fromJson(_obj(d, 'step')),
    ),
    'approval.request' => ApprovalRequested(
      seq,
      Approval.fromJson(d),
      stepId: _intOrNull(d, 'step_id'),
    ),
    'approval.updated' => ApprovalUpdated(seq, Approval.fromJson(d)),
    'reasoning.final' => ReasoningFinal(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      messageId: _int(d, 'message_id'),
      text: _str(d, 'text'),
    ),
    'context.updated' => ContextUpdated(
      seq,
      conversationId: _str(d, 'conversation_id'),
      runId: _str(d, 'run_id'),
      tokens: _intOrNull(d, 'tokens'),
      max: _intOrNull(d, 'max'),
      pct: _doubleOrNull(d, 'pct'),
      warn: _bool(d, 'warn'),
      source: _str(d, 'source'),
      measuredAt: _date(d, 'measured_at'),
      isFinal: _bool(d, 'final'),
    ),
    'health.status' => HealthStatus(
      seq,
      hermes: _strOrNull(d, 'hermes'),
      hermesVersion: _strOrNull(d, 'hermes_version'),
    ),
    'card.new' => CardNew(seq, AgentCard.fromJson(d)),
    'error' => ServerError(
      seq,
      code: _str(d, 'code'),
      message: _strOrNull(d, 'message'),
      refId: _strOrNull(d, 'ref_id'),
    ),
    _ => UnknownEvent(seq, type, d),
  };
}

final class ConversationCreated extends ServerEvent {
  const ConversationCreated(super.seq, this.conversation);
  final Conversation conversation;
}

final class ConversationUpdated extends ServerEvent {
  const ConversationUpdated(super.seq, this.conversation);
  final Conversation conversation;
}

final class MessageCreated extends ServerEvent {
  const MessageCreated(super.seq, this.conversationId, this.message);
  final String conversationId;
  final Message message;
}

final class MessageUpdated extends ServerEvent {
  const MessageUpdated(super.seq, this.conversationId, this.message);
  final String conversationId;
  final Message message;
}

final class MessageDelta extends ServerEvent {
  const MessageDelta(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.messageId,
    required this.delta,
  });
  final String conversationId;
  final String runId;
  final int messageId;
  final String delta;
}

final class MessageInterim extends ServerEvent {
  const MessageInterim(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.messageId,
    required this.text,
  });
  final String conversationId;
  final String runId;
  final int messageId;
  final String text;
}

final class RunQueued extends ServerEvent {
  const RunQueued(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.position,
    required this.thinking,
    required this.origin,
  });
  final String conversationId;
  final String runId;
  final int position;
  final bool thinking;
  final String origin;
}

/// The queue id (`q_…`) becomes the Hermes id (`run_…`).
final class RunStarted extends ServerEvent {
  const RunStarted(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.queuedId,
    required this.thinking,
  });
  final String conversationId;
  final String runId;
  final String? queuedId;
  final bool thinking;
}

final class RunUpdated extends ServerEvent {
  const RunUpdated(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.status,
  });
  final String conversationId;
  final String runId;
  final String status;
}

final class RunFinished extends ServerEvent {
  const RunFinished(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.status,
    required this.usage,
    required this.error,
  });
  final String conversationId;
  final String runId;
  final String status;
  final Json? usage;
  final String? error;
}

final class ToolStarted extends ServerEvent {
  const ToolStarted(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.step,
  });
  final String conversationId;
  final String runId;
  final ToolStep step;
}

final class ToolCompleted extends ServerEvent {
  const ToolCompleted(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.step,
  });
  final String conversationId;
  final String runId;
  final ToolStep step;
}

final class ApprovalRequested extends ServerEvent {
  const ApprovalRequested(super.seq, this.approval, {required this.stepId});
  final Approval approval;
  final int? stepId;
}

final class ApprovalUpdated extends ServerEvent {
  const ApprovalUpdated(super.seq, this.approval);
  final Approval approval;
}

final class ReasoningFinal extends ServerEvent {
  const ReasoningFinal(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.messageId,
    required this.text,
  });
  final String conversationId;
  final String runId;
  final int messageId;
  final String text;
}

/// `source`: sample | final_read | usage.
final class ContextUpdated extends ServerEvent {
  const ContextUpdated(
    super.seq, {
    required this.conversationId,
    required this.runId,
    required this.tokens,
    required this.max,
    required this.pct,
    required this.warn,
    required this.source,
    required this.measuredAt,
    required this.isFinal,
  });
  final String conversationId;
  final String runId;
  final int? tokens;
  final int? max;
  final double? pct;
  final bool warn;
  final String source;
  final DateTime measuredAt;
  final bool isFinal;
}

/// `hermes`: ok | down.
final class HealthStatus extends ServerEvent {
  const HealthStatus(
    super.seq, {
    required this.hermes,
    required this.hermesVersion,
  });
  final String? hermes;
  final String? hermesVersion;
}

/// Broadcast error, e.g. `thinking_route_not_applied` (ref_id = run id).
final class ServerError extends ServerEvent {
  const ServerError(
    super.seq, {
    required this.code,
    required this.message,
    required this.refId,
  });
  final String code;
  final String? message;
  final String? refId;
}

/// A new dashboard card.
final class CardNew extends ServerEvent {
  const CardNew(super.seq, this.card);
  final AgentCard card;
}

final class UnknownEvent extends ServerEvent {
  const UnknownEvent(super.seq, this.type, this.data);
  final String type;
  final Json data;
}

// ---------------------------------------------------------------------------
// strict field readers

Never _bad(Json d, String key, String want) =>
    throw FormatException('field "$key": expected $want, got ${d[key]}');

String _str(Json d, String key) {
  final v = d[key];
  return v is String ? v : _bad(d, key, 'string');
}

String? _strOrNull(Json d, String key) {
  final v = d[key];
  return v == null || v is String ? v as String? : _bad(d, key, 'string?');
}

int _int(Json d, String key) {
  final v = d[key];
  return v is int ? v : _bad(d, key, 'int');
}

int? _intOrNull(Json d, String key) {
  final v = d[key];
  return v == null || v is int ? v as int? : _bad(d, key, 'int?');
}

double? _doubleOrNull(Json d, String key) {
  final v = d[key];
  if (v == null) return null;
  return v is num ? v.toDouble() : _bad(d, key, 'num?');
}

bool _bool(Json d, String key) {
  final v = d[key];
  return v is bool ? v : _bad(d, key, 'bool');
}

Json _obj(Json d, String key) {
  final v = d[key];
  return v is Map<String, Object?> ? v : _bad(d, key, 'object');
}

Json? _objOrNull(Json d, String key) {
  final v = d[key];
  return v == null || v is Map<String, Object?>
      ? v as Json?
      : _bad(d, key, 'object?');
}

DateTime _date(Json d, String key) {
  final v = d[key];
  final parsed = v is String ? DateTime.tryParse(v) : null;
  return parsed ?? _bad(d, key, 'ISO-8601 date');
}
