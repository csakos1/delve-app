import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
