import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../api/models/approval.dart' show answerableApprovalStatuses;
import '../../api/models/run.dart' show openRunStatuses;
import 'converters.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Conversations,
    Messages,
    Runs,
    ToolSteps,
    Approvals,
    Outbox,
    SyncState,
    ConnectionLog,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'delve'));

  /// 1: A1 tables. 2: connection log (A3).
  @override
  int get schemaVersion => 2;

  /// Entries the connection log keeps.
  static const int connectionLogLimit = 500;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(syncState).insert(const SyncStateCompanion(id: Value(1)));
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(connectionLog);
    },
  );

  /// Where the event stream stands (`hello {last_seq, epoch}`).
  Future<SyncStateRow> readSyncState() =>
      (select(syncState)..where((t) => t.id.equals(1))).getSingle();

  /// Called inside the transaction that applied events up to [lastSeq].
  Future<void> writeSyncState({
    required String? epoch,
    required int? lastSeq,
  }) => (update(syncState)..where((t) => t.id.equals(1))).write(
    SyncStateCompanion(
      epoch: Value(epoch),
      lastSeq: Value(lastSeq),
      updatedAt: Value(DateTime.now().toUtc()),
    ),
  );

  /// Unpairing: everything from the old server goes, the sync state resets.
  /// The connection log stays (it explains why the token stopped working).
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
      if (table.actualTableName == syncState.actualTableName ||
          table.actualTableName == connectionLog.actualTableName) {
        continue;
      }
      await delete(table).go();
    }
    await writeSyncState(epoch: null, lastSeq: null);
  });

  /// Conversation list, newest first (the Chats screen).
  Stream<List<ConversationRow>> watchConversations({bool archived = false}) =>
      (select(conversations)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([
              (t) => OrderingTerm.desc(t.updatedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  /// Approvals the user can still answer (badge, inbox).
  Stream<int> watchAnswerableApprovalCount() {
    final count = approvals.requestId.count();
    return (selectOnly(approvals)
          ..addColumns([count])
          ..where(
            approvals.status.isIn(const ['pending', 'expired_in_hermes']),
          ))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// The Chats list (02a): each conversation with what its row shows, newest
  /// first. Re-emits when any of the four tables changes.
  Stream<List<ChatListItem>> watchChatList({bool archived = false}) {
    String inList(Iterable<String> values) =>
        values.map((v) => "'$v'").join(', ');
    final active = inList(openRunStatuses.where((s) => s != 'queued'));
    final answerable = inList(answerableApprovalStatuses);
    return customSelect(
      'SELECT c.*, '
      '(SELECT substr(m.content, 1, 300) FROM messages m '
      "WHERE m.conversation_id = c.id AND m.role IN ('user', 'assistant') "
      "AND m.content <> '' ORDER BY m.id DESC LIMIT 1) AS last_text, "
      '(SELECT substr(m.content, 1, 200) FROM messages m '
      "WHERE m.conversation_id = c.id AND m.role = 'user' "
      'ORDER BY m.id ASC LIMIT 1) AS first_user, '
      '(SELECT a.command FROM approvals a '
      'WHERE a.conversation_id = c.id AND a.status IN ($answerable) '
      'ORDER BY a.created_at DESC LIMIT 1) AS approval_command, '
      '(SELECT count(*) FROM runs r '
      'WHERE r.conversation_id = c.id AND r.status IN ($active)) '
      'AS active_runs, '
      '(SELECT count(*) FROM runs r '
      "WHERE r.conversation_id = c.id AND r.status = 'queued') AS queued_runs "
      'FROM conversations c WHERE c.archived = ? '
      'ORDER BY c.updated_at DESC, c.id DESC',
      variables: [Variable.withBool(archived)],
      readsFrom: {conversations, messages, approvals, runs},
    ).watch().map(
      (rows) => [
        for (final row in rows)
          ChatListItem(
            conversation: conversations.map(row.data),
            lastText: row.readNullable<String>('last_text'),
            firstUserText: row.readNullable<String>('first_user'),
            approvalCommand: row.readNullable<String>('approval_command'),
            activeRuns: row.read<int>('active_runs'),
            queuedRuns: row.read<int>('queued_runs'),
          ),
      ],
    );
  }

  /// The stream position (null `lastSeq`: nothing loaded from this server
  /// yet — the Chats skeleton).
  Stream<SyncStateRow> watchSyncState() =>
      (select(syncState)..where((t) => t.id.equals(1))).watchSingle();

  // --- sync (A3) ------------------------------------------------------------

  /// Appends a connection-log entry and drops the oldest beyond the limit.
  Future<void> addLogEntry(String kind, String? detail, {DateTime? at}) =>
      transaction(() async {
        final id = await into(connectionLog).insert(
          ConnectionLogCompanion.insert(
            at: (at ?? DateTime.now()).toUtc(),
            kind: kind,
            detail: Value(detail),
          ),
        );
        await (delete(connectionLog)..where(
              (t) => t.id.isSmallerOrEqualValue(id - connectionLogLimit),
            ))
            .go();
      });

  /// Newest first.
  Stream<List<ConnectionLogRow>> watchConnectionLog({
    int limit = connectionLogLimit,
  }) =>
      (select(connectionLog)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .watch();

  /// Messages not yet acknowledged by the server, oldest first.
  Future<List<OutboxRow>> pendingOutbox() =>
      (select(outbox)
            ..where((t) => t.state.equals('pending'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// The outbox as the chat shows it (pending, sending and failed rows).
  Stream<List<OutboxRow>> watchOutbox({String? conversationId}) {
    final q = select(outbox)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (conversationId != null) {
      q.where((t) => t.conversationId.equals(conversationId));
    }
    return q.watch();
  }
}

/// One row of the Chats list.
class ChatListItem {
  const ChatListItem({
    required this.conversation,
    this.lastText,
    this.firstUserText,
    this.approvalCommand,
    this.activeRuns = 0,
    this.queuedRuns = 0,
  });

  final ConversationRow conversation;

  /// Newest user or assistant text (the preview line).
  final String? lastText;

  /// First user message (the title until the agent names the chat).
  final String? firstUserText;

  /// Command of the newest approval that can still be answered.
  final String? approvalCommand;

  /// Runs of this conversation that have started and not ended.
  final int activeRuns;

  /// Runs of this conversation waiting in the queue.
  final int queuedRuns;
}
