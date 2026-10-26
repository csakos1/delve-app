import 'dart:io';

import 'package:delve/api/models/models.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/data/db/store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';

AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// What a database before schema 5 lacks.
Future<void> dropAttachments(AppDatabase db) async {
  await db.customStatement('ALTER TABLE messages DROP COLUMN attachments');
  await db.customStatement('ALTER TABLE outbox DROP COLUMN attachments');
}

void main() {
  // the upgrade tests reopen a closed file on purpose
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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

  test('the chat list falls back to the server preview', () async {
    await db
        .into(db.conversations)
        .insert(
          conv('c_1', t0).copyWith(preview: const Value('from the server')),
        );
    expect((await db.watchChatList().first).single.lastText, 'from the server');
    await db
        .into(db.messages)
        .insert(
          MessagesCompanion.insert(
            id: const Value(7),
            conversationId: 'c_1',
            role: 'assistant',
            content: 'loaded here',
            status: 'final',
            createdAt: t0,
          ),
        );
    expect((await db.watchChatList().first).single.lastText, 'loaded here');
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

  group('connection log', () {
    test('keeps the newest entries only', () async {
      for (var i = 0; i < AppDatabase.connectionLogLimit + 10; i++) {
        await db.addLogEntry(
          'connecting',
          '$i',
          at: t0.add(Duration(seconds: i)),
        );
      }
      final rows = await db.watchConnectionLog().first;
      expect(rows, hasLength(AppDatabase.connectionLogLimit));
      expect(
        rows.first.detail,
        '${AppDatabase.connectionLogLimit + 9}',
        reason: 'newest first',
      );
      expect(rows.last.detail, '10');
    });

    test('survives unpairing (it explains why the token went)', () async {
      await db.addLogEntry('authFailed', '4401 unauthorized');
      await db.wipe();
      expect(await db.select(db.connectionLog).get(), hasLength(1));
    });

    test('a version 1 database gets the table on upgrade', () async {
      final dir = await Directory.systemTemp.createTemp('delve-db');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/delve.sqlite');
      final v1 = AppDatabase(NativeDatabase(file));
      await v1.customStatement('DROP TABLE connection_log');
      await v1.customStatement('ALTER TABLE conversations DROP COLUMN preview');
      await v1.customStatement('DROP TABLE cards');
      await dropAttachments(v1);
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final v2 = AppDatabase(NativeDatabase(file));
      addTearDown(v2.close);
      await v2.addLogEntry('connected', null);
      expect(await v2.select(v2.connectionLog).get(), hasLength(1));
      expect((await v2.readSyncState()).id, 1, reason: 'existing data kept');
    });
  });

  test('a version 2 database gets the preview column on upgrade', () async {
    final dir = await Directory.systemTemp.createTemp('delve-db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/delve.sqlite');
    final v2 = AppDatabase(NativeDatabase(file));
    await v2.customStatement('ALTER TABLE conversations DROP COLUMN preview');
    await v2.customStatement('DROP TABLE cards');
    await dropAttachments(v2);
    await v2.customStatement(
      "INSERT INTO conversations (id, created_at, updated_at) VALUES ('c_old', 0, 0)",
    );
    await v2.customStatement('PRAGMA user_version = 2');
    await v2.close();

    final v3 = AppDatabase(NativeDatabase(file));
    addTearDown(v3.close);
    final row = await v3.select(v3.conversations).getSingle();
    expect((row.id, row.preview), ('c_old', null));
  });

  test('a version 3 database gets the cards table on upgrade', () async {
    final dir = await Directory.systemTemp.createTemp('delve-db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/delve.sqlite');
    final v3 = AppDatabase(NativeDatabase(file));
    await v3.customStatement('DROP TABLE cards');
    await dropAttachments(v3);
    await v3.customStatement('PRAGMA user_version = 3');
    await v3.close();

    final v4 = AppDatabase(NativeDatabase(file));
    addTearDown(v4.close);
    expect(await v4.select(v4.cards).get(), isEmpty);
  });

  test('a version 4 database gets the attachment columns on upgrade', () async {
    final dir = await Directory.systemTemp.createTemp('delve-db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/delve.sqlite');
    final v4 = AppDatabase(NativeDatabase(file));
    await dropAttachments(v4);
    await v4.customStatement(
      'INSERT INTO messages (id, conversation_id, role, content, status, created_at) '
      "VALUES (7, 'c_old', 'user', 'hi', 'final', 0)",
    );
    await v4.customStatement('PRAGMA user_version = 4');
    await v4.close();

    final v5 = AppDatabase(NativeDatabase(file));
    addTearDown(v5.close);
    final row = await v5.select(v5.messages).getSingle();
    expect(row.content, 'hi');
    expect(row.attachments, isEmpty);
    await v5.putMessage(
      Message.fromJson(
        FakeServer.sample('message_user')
          ..['conversation_id'] = 'c_old'
          ..['id'] = 7,
      ),
    );
    final updated = await v5.select(v5.messages).getSingle();
    expect(updated.attachments.single.filename, 'screen.jpg');
  });

  test('an event without attachments keeps the stored ones', () async {
    final user = Message.fromJson(FakeServer.sample('message_user'));
    await db.putMessage(user);
    await db.putMessage(user.copyWith(content: 'edited', attachments: []));
    final row = await db.select(db.messages).getSingle();
    expect(
      (row.content, row.attachments.single.id),
      ('edited', user.attachments.single.id),
    );
  });

  test('pending outbox rows come oldest first', () async {
    for (final (id, at) in [('b', 2), ('a', 1), ('c', 3)]) {
      await db
          .into(db.outbox)
          .insert(
            OutboxCompanion.insert(
              clientMsgId: id,
              body: id,
              createdAt: t0.add(Duration(seconds: at)),
              state: Value(id == 'c' ? 'failed' : 'pending'),
            ),
          );
    }
    expect((await db.pendingOutbox()).map((r) => r.clientMsgId), ['a', 'b']);
  });
}
