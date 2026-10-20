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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'delve'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(syncState).insert(const SyncStateCompanion(id: Value(1)));
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
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
      if (table.actualTableName == syncState.actualTableName) continue;
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
}
