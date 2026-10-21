// Client side of the contract: REST routes, client frames, revision.

/// Oldest backend contract this build works with (`/meta` `api_revision`).
/// Raise it together with the models when the app starts relying on a newer
/// contract; a smaller server revision shows the "server too old" screen.
const int kMinApiRevision = 5; // 5: GET /system, POST /system/llama

/// REST routes the app calls (method + path template); checked against the
/// backend contract in `test/contract_test.dart`.
abstract final class ApiRoutes {
  static const String prefix = '/api/v1';

  static const health = ('GET', '/api/v1/health');
  static const meta = ('GET', '/api/v1/meta');
  static const status = ('GET', '/api/v1/status');
  static const register = ('POST', '/api/v1/devices/register');
  static const deviceMe = ('GET', '/api/v1/devices/me');
  static const deviceFcm = ('PUT', '/api/v1/devices/me/fcm');
  static const unpair = ('DELETE', '/api/v1/devices/me');
  static const patchDevice = ('PATCH', '/api/v1/devices/me');
  static const conversations = ('GET', '/api/v1/conversations');
  static const conversation = (
    'GET',
    '/api/v1/conversations/{conversation_id}',
  );
  static const patchConversation = (
    'PATCH',
    '/api/v1/conversations/{conversation_id}',
  );
  static const messages = (
    'GET',
    '/api/v1/conversations/{conversation_id}/messages',
  );
  static const usage = ('GET', '/api/v1/conversations/{conversation_id}/usage');
  static const approvals = ('GET', '/api/v1/approvals');
  static const answerApproval = ('POST', '/api/v1/approvals/{request_id}');
  static const openRuns = ('GET', '/api/v1/runs/open');
  static const cards = ('GET', '/api/v1/cards');
  static const system = ('GET', '/api/v1/system');
  static const llama = ('POST', '/api/v1/system/llama');
  static const ws = ('WS', '/api/v1/ws');

  static const List<(String, String)> all = <(String, String)>[
    health,
    meta,
    status,
    register,
    deviceMe,
    deviceFcm,
    unpair,
    patchDevice,
    conversations,
    conversation,
    patchConversation,
    messages,
    usage,
    approvals,
    answerApproval,
    openRuns,
    cards,
    system,
    llama,
    ws,
  ];

  /// Fills `{name}` placeholders: `path(messages.$2, {'conversation_id': id})`.
  static String path(
    String template, [
    Map<String, String> params = const {},
  ]) => template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final v = params[m[1]!];
    if (v == null) throw ArgumentError('missing path parameter ${m[1]}');
    return Uri.encodeComponent(v);
  });
}

/// Approval answers the app may send (`always` is never offered).
enum ApprovalChoice {
  once,
  session,
  deny;

  String get wire => name;
}

/// Frames the app sends: `{type, id, data}`. Optional keys are left out when
/// null, never sent as null.
abstract final class ClientFrames {
  static Map<String, Object?> _frame(
    String type,
    String id,
    Map<String, Object?> data,
  ) => <String, Object?>{
    'type': type,
    'id': id,
    'data': <String, Object?>{
      for (final e in data.entries)
        if (e.value != null) e.key: e.value,
    },
  };

  /// The first frame; [lastSeq] and [epoch] resume the event stream.
  static Map<String, Object?> hello({
    required String id,
    required String deviceToken,
    int? lastSeq,
    String? epoch,
  }) => _frame('hello', id, {
    'device_token': deviceToken,
    'last_seq': lastSeq,
    'epoch': epoch,
  });

  /// Idempotent on [clientMsgId] (UUIDv4); a new conversation when
  /// [conversationId] is null.
  static Map<String, Object?> chatSend({
    required String id,
    required String text,
    required String clientMsgId,
    String? conversationId,
    bool? thinking,
  }) => _frame('chat.send', id, {
    'text': text,
    'client_msg_id': clientMsgId,
    'conversation_id': conversationId,
    'thinking': thinking,
  });

  static Map<String, Object?> conversationSet({
    required String id,
    required String conversationId,
    bool? thinking,
    bool? archived,
  }) => _frame('conversation.set', id, {
    'conversation_id': conversationId,
    'thinking': thinking,
    'archived': archived,
  });

  /// [runId] may be the queue id (`q_…`) or the Hermes id (`run_…`).
  static Map<String, Object?> runStop({
    required String id,
    required String runId,
  }) => _frame('run.stop', id, {'run_id': runId});

  static Map<String, Object?> approvalRespond({
    required String id,
    required String requestId,
    required ApprovalChoice choice,
  }) => _frame('approval.respond', id, {
    'request_id': requestId,
    'choice': choice.wire,
  });

  static Map<String, Object?> sync({
    required String id,
    required String conversationId,
    int? afterMessageId,
  }) => _frame('sync', id, {
    'conversation_id': conversationId,
    'after_message_id': afterMessageId,
  });

  static Map<String, Object?> ping({required String id}) =>
      _frame('ping', id, const {});
}

/// WebSocket close codes used by the backend.
abstract final class WsClose {
  static const int protocolError = 4400;
  static const int unauthorized = 4401;
  static const int timeoutOrSlow = 4408;
}

/// `POST /system/llama` actions.
enum LlamaAction { start, stop }
