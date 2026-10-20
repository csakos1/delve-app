import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import '../api/rest_client.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_providers.dart';
import 'providers.dart';
import 'session.dart';

/// Everything one chat shows, as the database has it (decision 168).
class ChatData {
  const ChatData({
    required this.conversation,
    required this.messages,
    required this.runs,
    required this.steps,
    required this.approvals,
    required this.outbox,
  });

  final ConversationRow? conversation;

  /// Oldest first.
  final List<MessageRow> messages;

  /// By run id.
  final Map<String, RunRow> runs;

  /// Tool steps by run id, in the order they started.
  final Map<String, List<ToolStepRow>> steps;

  /// By request id.
  final Map<String, ApprovalRow> approvals;

  /// Messages of this chat the server has not acknowledged yet.
  final List<OutboxRow> outbox;

  /// Runs of this chat that are queued or running, the active one first.
  List<RunRow> get openRuns {
    final open = [
      for (final r in runs.values)
        if (openRunStatuses.contains(r.status)) r,
    ];
    int rank(RunRow r) => r.status == 'queued' ? 1 : 0;
    open.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final at = a.queuedAt, bt = b.queuedAt;
      if (at == null || bt == null) return a.runId.compareTo(b.runId);
      return at.compareTo(bt);
    });
    return open;
  }

  int get queuedCount => runs.values.where((r) => r.status == 'queued').length;
}

extension ChatQueries on AppDatabase {
  Future<ChatData> loadChat(String conversationId) async {
    final conversation = await (select(
      conversations,
    )..where((t) => t.id.equals(conversationId))).getSingleOrNull();
    final msgs =
        await (select(messages)
              ..where((t) => t.conversationId.equals(conversationId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    final runRows = await (select(
      runs,
    )..where((t) => t.conversationId.equals(conversationId))).get();
    final runIds = {
      for (final m in msgs) ?m.runId,
      for (final r in runRows) r.runId,
    };
    final stepRows = runIds.isEmpty
        ? const <ToolStepRow>[]
        : await (select(toolSteps)
                ..where((t) => t.runId.isIn(runIds))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
    final approvalRows = await (select(
      approvals,
    )..where((t) => t.conversationId.equals(conversationId))).get();
    final outboxRows =
        await (select(outbox)
              ..where((t) => t.conversationId.equals(conversationId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    final steps = <String, List<ToolStepRow>>{};
    for (final s in stepRows) {
      (steps[s.runId] ??= []).add(s);
    }
    return ChatData(
      conversation: conversation,
      messages: msgs,
      runs: {for (final r in runRows) r.runId: r},
      steps: steps,
      approvals: {for (final a in approvalRows) a.requestId: a},
      outbox: outboxRows,
    );
  }

  /// [loadChat] again whenever one of the tables it reads changes.
  Stream<ChatData> watchChat(String conversationId) async* {
    final updates = tableUpdates(
      TableUpdateQuery.onAllTables([
        conversations,
        messages,
        runs,
        toolSteps,
        approvals,
        outbox,
      ]),
    );
    yield await loadChat(conversationId);
    await for (final _ in updates) {
      yield await loadChat(conversationId);
    }
  }

  /// The message the server made of an outbox entry (a new chat learns its
  /// conversation id from it).
  Stream<MessageRow?> watchMessageByClientId(String clientMsgId) =>
      (select(messages)
            ..where((t) => t.clientMsgId.equals(clientMsgId))
            ..limit(1))
          .watchSingleOrNull();

  Stream<OutboxRow?> watchOutboxRow(String clientMsgId) => (select(
    outbox,
  )..where((t) => t.clientMsgId.equals(clientMsgId))).watchSingleOrNull();

  Future<int?> lastMessageId(String conversationId) async {
    final max = messages.id.max();
    final row =
        await (selectOnly(messages)
              ..addColumns([max])
              ..where(messages.conversationId.equals(conversationId)))
            .getSingle();
    return row.read(max);
  }
}

final chatProvider = StreamProvider.autoDispose.family<ChatData, String>(
  (ref, id) => ref.watch(databaseProvider).watchChat(id),
);

/// What the chat screen asks of the server. Tests replace it with a fake.
abstract class ChatActions {
  /// Queues [text] (outbox) and returns its `client_msg_id`.
  Future<String> send(String text, {String? conversationId});

  Future<void> retry(String clientMsgId);

  Future<void> discard(String clientMsgId);

  /// Throws [SyncError] when not connected or refused.
  Future<String> stop(String runId);

  /// The chat opened: loads what is missing locally (messages over the
  /// socket, or REST when it is down; the runs of the chat over REST).
  /// Failures are left out: the chat shows what the database has.
  Future<void> open(String conversationId);

  /// The chat closed (the resync no longer reloads it on purpose).
  void close();
}

class EngineChatActions implements ChatActions {
  EngineChatActions({
    required this.engine,
    required this.api,
    required this.db,
  });

  final SyncEngine? engine;
  final DelveApi api;
  final AppDatabase db;

  /// Pages of [SyncEngine.syncConversation] fetched on open at most.
  static const int maxSyncPages = 10;

  SyncEngine get _engine => engine ?? (throw const NotConnected());

  @override
  Future<String> send(String text, {String? conversationId}) =>
      _engine.sendMessage(text, conversationId: conversationId);

  @override
  Future<void> retry(String clientMsgId) => _engine.retryMessage(clientMsgId);

  @override
  Future<void> discard(String clientMsgId) =>
      _engine.discardMessage(clientMsgId);

  @override
  Future<String> stop(String runId) => _engine.stopRun(runId);

  @override
  Future<void> open(String conversationId) async {
    engine?.focusConversation(conversationId);
    try {
      await _syncMessages(conversationId);
    } on Exception {
      // offline: the local copy stays on screen
    }
    try {
      final usage = await api.usage(conversationId, limit: 200);
      await db.transaction(() async {
        for (final r in usage.runs) {
          // open runs keep their queue position from the event stream
          if (!openRunStatuses.contains(r.status)) await db.putRun(r);
        }
      });
    } on Exception {
      // as above
    }
  }

  Future<void> _syncMessages(String conversationId) async {
    final e = engine;
    if (e != null) {
      try {
        for (var i = 0; i < maxSyncPages; i++) {
          final after = await db.lastMessageId(conversationId);
          final more = await e.syncConversation(
            conversationId,
            afterMessageId: after,
          );
          if (!more) return;
        }
        return;
      } on SyncError {
        // not live: REST below
      }
    }
    final conv = await api.conversation(conversationId);
    final page = await api.messages(conversationId, limit: 100);
    await db.transaction(() async {
      await db.putConversation(conv);
      for (final m in page.messages) {
        await db.putHistoryMessage(m);
      }
    });
  }

  @override
  void close() => engine?.focusConversation(null);
}

final chatActionsProvider = Provider<ChatActions?>((ref) {
  final api = ref.watch(apiProvider);
  if (api == null) return null;
  return EngineChatActions(
    engine: ref.watch(syncEngineProvider),
    api: api,
    db: ref.watch(databaseProvider),
  );
});
