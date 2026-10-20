// The part of a run that is not in the database yet (decision 168): the
// streamed text, interim remarks, the latest context sample and the thinking
// clock. The chat shows the stored message with this overlaid; the stored
// message gets the final text from `message.updated` when the run ends.

/// Latest `context.updated` of a running run.
class LiveContext {
  const LiveContext({
    required this.tokens,
    required this.max,
    required this.pct,
    required this.warn,
    required this.source,
    required this.measuredAt,
  });

  final int? tokens;
  final int? max;
  final double? pct;
  final bool warn;

  /// sample | final_read | usage
  final String source;
  final DateTime measuredAt;
}

/// One run that is streaming (at most one per conversation).
class LiveRun {
  const LiveRun({
    required this.conversationId,
    required this.runId,
    required this.thinking,
    required this.startedAt,
    this.messageId,
    this.text = '',
    this.partial = false,
    this.firstDeltaAt,
    this.interim = const [],
    this.context,
    this.contextStart,
  });

  final String conversationId;
  final String runId;
  final bool thinking;

  /// When this app saw the run start (the thinking clock counts from here).
  final DateTime startedAt;

  /// The assistant message the text belongs to (from `message.created`).
  final int? messageId;

  /// Deltas received so far.
  final String text;

  /// True when the app joined the stream midway (cold start, resync): [text]
  /// misses the beginning, which arrives with the final message.
  final bool partial;

  /// First text delta; for a thinking run the reasoning ended here.
  final DateTime? firstDeltaAt;
  final List<String> interim;
  final LiveContext? context;

  /// Tokens of the first context sample of this run: the context grows from
  /// here while the model thinks (the "N tok" of the thinking block).
  final int? contextStart;

  /// Tokens the run added since its first context sample (0 before two).
  int get contextGrowth {
    final now = context?.tokens, start = contextStart;
    if (now == null || start == null || now < start) return 0;
    return now - start;
  }

  bool get isThinking => thinking && firstDeltaAt == null;

  LiveRun copyWith({
    int? messageId,
    String? text,
    DateTime? firstDeltaAt,
    List<String>? interim,
    LiveContext? context,
    int? contextStart,
  }) => LiveRun(
    conversationId: conversationId,
    runId: runId,
    thinking: thinking,
    startedAt: startedAt,
    messageId: messageId ?? this.messageId,
    text: text ?? this.text,
    partial: partial,
    firstDeltaAt: firstDeltaAt ?? this.firstDeltaAt,
    interim: interim ?? this.interim,
    context: context ?? this.context,
    contextStart: contextStart ?? this.contextStart,
  );
}

/// Mutable working copy the reducer edits; [snapshot] is what the UI gets.
class LiveRunsBuffer {
  final Map<String, LiveRun> _byConversation = {};
  bool _changed = false;

  /// Whether anything changed since the last [takeChanged].
  bool takeChanged() {
    final c = _changed;
    _changed = false;
    return c;
  }

  Map<String, LiveRun> snapshot() => Map.unmodifiable(_byConversation);

  LiveRun? operator [](String conversationId) =>
      _byConversation[conversationId];

  void _put(LiveRun run) {
    _byConversation[run.conversationId] = run;
    _changed = true;
  }

  void started({
    required String conversationId,
    required String runId,
    required bool thinking,
    required DateTime at,
  }) {
    final current = _byConversation[conversationId];
    if (current != null && current.runId == runId) return; // replayed
    _put(
      LiveRun(
        conversationId: conversationId,
        runId: runId,
        thinking: thinking,
        startedAt: at,
      ),
    );
  }

  /// The streaming assistant message of [runId] was created.
  void messageCreated(String conversationId, String runId, int messageId) {
    final current = _byConversation[conversationId];
    if (current == null || current.runId != runId) return;
    _put(current.copyWith(messageId: messageId));
  }

  void delta({
    required String conversationId,
    required String runId,
    required int messageId,
    required String text,
    required DateTime at,
  }) {
    final current = _byConversation[conversationId];
    if (current == null || current.runId != runId) {
      // joined midway: the start of the text is missing
      _put(
        LiveRun(
          conversationId: conversationId,
          runId: runId,
          thinking: false,
          startedAt: at,
          messageId: messageId,
          text: text,
          partial: true,
          firstDeltaAt: at,
        ),
      );
      return;
    }
    _put(
      current.copyWith(
        messageId: messageId,
        text: current.text + text,
        firstDeltaAt: current.firstDeltaAt ?? at,
      ),
    );
  }

  void interim(String conversationId, String runId, String text) {
    final current = _byConversation[conversationId];
    if (current == null || current.runId != runId) return;
    _put(current.copyWith(interim: [...current.interim, text]));
  }

  void context(String conversationId, String runId, LiveContext context) {
    final current = _byConversation[conversationId];
    if (current == null || current.runId != runId) return;
    _put(
      current.copyWith(
        context: context,
        contextStart: current.contextStart ?? context.tokens,
      ),
    );
  }

  /// The run ended (or its final message arrived): the database has it now.
  void finished(String conversationId, String runId) {
    final current = _byConversation[conversationId];
    if (current == null || current.runId != runId) return;
    _byConversation.remove(conversationId);
    _changed = true;
  }

  /// Resync: whatever was streaming is reloaded from the server.
  void clear() {
    if (_byConversation.isEmpty) return;
    _byConversation.clear();
    _changed = true;
  }
}
