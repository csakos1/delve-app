import 'package:delve/data/db/database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final t0 = DateTime.utc(2026, 10, 20, 8);

  ConversationsCompanion conv(
    String id,
    DateTime updated, {
    bool archived = false,
  }) => ConversationsCompanion.insert(
    id: id,
    createdAt: t0,
    updatedAt: updated,
    archived: Value(archived),
  );

  ApprovalsCompanion approval(String id, String status) =>
      ApprovalsCompanion.insert(
        requestId: id,
        runId: 'run_1',
        conversationId: 'c_1',
        command: 'rm -r /tmp/x',
        patternKeys: const ['rm'],
        actionClass: 'delete_kill',
        status: status,
        choices: const ['once', 'session', 'deny'],
        createdAt: t0,
        hermesDeadline: t0.add(const Duration(minutes: 5)),
        expiresAt: t0.add(const Duration(minutes: 30)),
      );

  test('sync state starts empty and is updated in place', () async {
    final s0 = await db.readSyncState();
    expect(s0.epoch, isNull);
    expect(s0.lastSeq, isNull);
    await db.transaction(() => db.writeSyncState(epoch: 'e1', lastSeq: 42));
    final s1 = await db.readSyncState();
    expect((s1.epoch, s1.lastSeq), ('e1', 42));
    expect(await db.select(db.syncState).get(), hasLength(1));
  });

  test('only one sync state row can exist', () async {
    await expectLater(
      db.into(db.syncState).insert(const SyncStateCompanion(id: Value(2))),
      throwsA(isA<SqliteException>()),
    );
  });

  test('conversations: newest first, archived apart, upsert by id', () async {
    await db.batch((b) {
      b.insertAll(db.conversations, [
        conv('c_old', t0),
        conv('c_new', t0.add(const Duration(minutes: 1))),
        conv('c_arch', t0.add(const Duration(minutes: 2)), archived: true),
      ]);
    });
    expect((await db.watchConversations().first).map((c) => c.id), [
      'c_new',
      'c_old',
    ]);
    await db
        .into(db.conversations)
        .insertOnConflictUpdate(
          conv('c_old', t0.add(const Duration(minutes: 5))),
        );
    expect((await db.watchConversations().first).map((c) => c.id), [
      'c_old',
      'c_new',
    ]);
    expect(
      (await db.watchConversations(archived: true).first).map((c) => c.id),
      ['c_arch'],
    );
  });

  test('answerable approvals are counted live', () async {
    final counts = db.watchAnswerableApprovalCount();
    expect(await counts.first, 0);
    await db.batch((b) {
      b.insertAll(db.approvals, [
        approval('a1', 'pending'),
        approval('a2', 'expired_in_hermes'),
        approval('a3', 'denied'),
      ]);
    });
    expect(await counts.first, 2);
  });

  test('JSON columns round-trip', () async {
    await db
        .into(db.runs)
        .insert(
          RunsCompanion.insert(
            runId: 'run_1',
            conversationId: 'c_1',
            status: 'completed',
            usage: const Value({'input_tokens': 8572, 'output_tokens': 4}),
          ),
        );
    await db.into(db.approvals).insert(approval('a1', 'pending'));
    final run = await db.select(db.runs).getSingle();
    expect(run.usage, {'input_tokens': 8572, 'output_tokens': 4});
    expect(run.perf, isNull);
    final a = await db.select(db.approvals).getSingle();
    expect(a.choices, ['once', 'session', 'deny']);
  });

  test('wipe empties every table and resets the stream position', () async {
    await db.into(db.conversations).insert(conv('c_1', t0));
    await db.into(db.approvals).insert(approval('a1', 'pending'));
    await db.writeSyncState(epoch: 'e1', lastSeq: 9);
    await db.wipe();
    expect(await db.select(db.conversations).get(), isEmpty);
    expect(await db.select(db.approvals).get(), isEmpty);
    final s = await db.readSyncState();
    expect((s.epoch, s.lastSeq), (null, null));
  });
}
