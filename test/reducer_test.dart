import 'package:delve/api/events.dart';
import 'package:delve/api/models/models.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/sync/live_runs.dart';
import 'package:delve/sync/reducer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';
import 'support/ws_fixtures.dart';

void main() {
  late AppDatabase db;
  late LiveRunsBuffer live;
  late EventReducer reducer;
  final t0 = DateTime.utc(2026, 10, 20, 9);

  setUp(() {
    db = memoryDb();
    live = LiveRunsBuffer();
    reducer = EventReducer(db, live, now: () => t0);
  });
  tearDown(() => db.close());

  Future<void> replay(
    List<ServerEvent> events, {
    int batch = 7,
    String epoch = 'e',
  }) async {
    for (var i = 0; i < events.length; i += batch) {
      final end = i + batch > events.length ? events.length : i + batch;
      await reducer.apply(events.sublist(i, end), epoch: epoch);
    }
  }

  Future<List<MessageRow>> messages() =>
      (db.select(db.messages)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  group('recorded conversations', () {
    for (final name in recordings) {
      test('$name: the database ends where the server ended', () async {
        final rec = Recording(name);
        final events = rec.events;
        await replay(events, epoch: rec.epoch);

        final sync = await db.readSyncState();
        expect((sync.epoch, sync.lastSeq), (rec.epoch, events.last.seq));

        // every message as its last message.created/updated said
        final lastMessage = <int, Map<String, Object?>>{
          for (final d in [
            ...rec.data('message.created'),
            ...rec.data('message.updated'),
          ])
            (d['message']! as Map<String, Object?>)['id']! as int:
                d['message']! as Map<String, Object?>,
        };
        final rows = await messages();
        expect(rows.map((m) => m.id), unorderedEquals(lastMessage.keys));
        for (final m in rows) {
          final want = lastMessage[m.id]!;
          expect(m.content, want['content'], reason: 'message ${m.id}');
          expect(m.status, want['status'], reason: 'message ${m.id}');
          expect(m.interim, want['interim'], reason: 'message ${m.id}');
          expect(
            m.runId,
            isNot(startsWith('q_')),
            reason: 'renamed to the Hermes id',
          );
          expect(m.status, isNot('streaming'));
        }

        // runs: all ended, none left in the queue, ids renamed
        final runs = await db.select(db.runs).get();
        final finished = {
          for (final d in rec.data('run.finished')) d['run_id']: d['status'],
        };
        expect(runs.map((r) => r.runId), unorderedEquals(finished.keys));
        for (final r in runs) {
          expect(r.status, finished[r.runId]);
          expect(r.position, isNull);
          expect(r.endedAt, isNotNull);
        }

        // tool steps as their last event said
        final lastStep = <int, Map<String, Object?>>{
          for (final d in [
            ...rec.data('tool.started'),
            ...rec.data('tool.completed'),
          ])
            (d['step']! as Map<String, Object?>)['id']! as int:
                d['step']! as Map<String, Object?>,
        };
        final steps = await db.select(db.toolSteps).get();
        expect(steps.map((s) => s.id), unorderedEquals(lastStep.keys));
        for (final s in steps) {
          expect(s.status, lastStep[s.id]!['status']);
        }

        // the conversation as its last event said (title, totals)
        final convEvents = [
          ...rec.data('conversation.created'),
          ...rec.data('conversation.updated'),
        ];
        final lastConv = {for (final c in convEvents) c['id']: c};
        final convs = await db.select(db.conversations).get();
        expect(convs.map((c) => c.id), unorderedEquals(lastConv.keys));
        for (final c in convs) {
          final want = lastConv[c.id]!;
          final totals = want['totals']! as Map<String, Object?>;
          expect(c.title, want['title']);
          expect(c.tokensTotal, totals['total_tokens']);
        }

        expect(live.snapshot(), isEmpty, reason: 'nothing streams any more');
        expect(await db.select(db.outbox).get(), isEmpty);
      });

      test('$name: one batch, small batches and a second pass agree', () async {
        final events = Recording(name).events;
        await reducer.apply(events, epoch: 'e');
        Future<List<Object>> dump() async => [
          for (final m in await messages())
            [m.id, m.content, m.status, m.runId, m.reasoning],
          for (final r in await db.select(db.runs).get())
            [r.runId, r.status, r.position],
          for (final s in await db.select(db.toolSteps).get()) [s.id, s.status],
          for (final a in await db.select(db.approvals).get())
            [a.requestId, a.status, a.stepId],
          for (final c in await db.select(db.conversations).get())
            [c.id, c.title, c.tokensTotal],
        ];
        final once = await dump();
        await replay(events, batch: 3);
        expect(await dump(), once, reason: 'applying again changes nothing');
        await db.wipe();
        await replay(events, batch: 1);
        expect(await dump(), once);
      });
    }
  });

  test(
    'basic: the text streams into the live buffer, not the database',
    () async {
      final rec = Recording('basic');
      final events = rec.events;
      final firstFinal = events.indexWhere((e) => e is MessageUpdated);
      final midway = events.lastIndexWhere(
        (e) => e is MessageDelta,
        firstFinal,
      );
      await replay(events.sublist(0, midway + 1));

      final convId = rec.data('conversation.created').single['id']! as String;
      final run = live[convId]!;
      final deltas = [
        for (final e in events.sublist(0, midway + 1))
          if (e is MessageDelta) e.delta,
      ].join();
      expect(run.text, deltas);
      expect(run.partial, isFalse);
      expect(run.messageId, isNotNull);
      expect(run.firstDeltaAt, isNotNull);
      final stored = (await messages()).firstWhere(
        (m) => m.id == run.messageId,
      );
      expect(stored.status, 'streaming');
      expect(
        stored.content,
        isEmpty,
        reason: 'deltas never reach the database',
      );

      await replay(events.sublist(midway + 1));
      expect(live[convId], isNull);
    },
  );

  test('interim: remarks show live, then land in the final message', () async {
    final rec = Recording('interim');
    final events = rec.events;
    final at = events.indexWhere((e) => e is MessageInterim);
    await replay(events.sublist(0, at + 1));
    final convId = rec.data('conversation.created').single['id']! as String;
    expect(live[convId]!.interim, [rec.data('message.interim').single['text']]);
    await replay(events.sublist(at + 1));
    final assistant = (await messages()).firstWhere(
      (m) => m.role == 'assistant',
    );
    expect(assistant.interim, isNotNull);
  });

  test('deny: approval and tool step are linked and both denied', () async {
    await replay(Recording('deny').events);
    final approval = (await db.select(db.approvals).get()).single;
    final step = (await db.select(db.toolSteps).get()).single;
    expect(approval.status, 'denied');
    expect(approval.choice, 'deny');
    expect(approval.stepId, step.id);
    expect(step.approvalRequestId, approval.requestId);
    expect(step.status, 'denied');
    expect(approval.choices, isNot(contains('always')));
  });

  test('deny: the badge counts the approval while it waits', () async {
    final events = Recording('deny').events;
    final at = events.indexWhere((e) => e is ApprovalRequested);
    await replay(events.sublist(0, at + 1));
    expect(await db.watchAnswerableApprovalCount().first, 1);
    final run = (await db.select(db.runs).get()).single;
    expect(run.status, 'running');
    await replay(events.sublist(at + 1, at + 2)); // run.updated
    expect(
      (await db.select(db.runs).get()).single.status,
      'waiting_for_approval',
    );
    await replay(events.sublist(at + 2));
    expect(await db.watchAnswerableApprovalCount().first, 0);
  });

  test('thinking: reasoning is stored with the answer', () async {
    final rec = Recording('thinking');
    await replay(rec.events);
    final assistant = (await messages()).firstWhere(
      (m) => m.role == 'assistant',
    );
    expect(assistant.reasoning, rec.data('reasoning.final').single['text']);
    expect((await db.select(db.runs).get()).single.thinking, isTrue);
  });

  test('stop: run and message end cancelled', () async {
    await replay(Recording('stop').events);
    expect((await db.select(db.runs).get()).single.status, 'cancelled');
    final assistant = (await messages()).firstWhere(
      (m) => m.role == 'assistant',
    );
    expect(assistant.status, 'cancelled');
  });

  test('queued: the second run waits in place 1, then moves up', () async {
    final rec = Recording('queued');
    final events = rec.events;
    final queued = [
      for (final (i, e) in events.indexed)
        if (e is RunQueued) i,
    ];
    expect(queued, hasLength(2));
    await replay(events.sublist(0, queued[1] + 1));
    final second = (events[queued[1]] as RunQueued).runId;
    Future<RunRow?> run(String id) => (db.select(
      db.runs,
    )..where((t) => t.runId.equals(id))).getSingleOrNull();
    final waiting = await run(second);
    expect(waiting!.status, 'queued');
    expect(waiting.position, (events[queued[1]] as RunQueued).position);
    expect(waiting.position, greaterThan(0));

    final firstEnd = events.indexWhere((e) => e is RunFinished);
    await replay(events.sublist(queued[1] + 1, firstEnd + 1));
    expect((await run(second))!.position, 0, reason: 'next in line');
    await replay(events.sublist(firstEnd + 1));
    expect((await db.select(db.runs).get()).map((r) => r.status), [
      'completed',
      'completed',
    ]);
    final convs = await db.select(db.conversations).get();
    expect(convs, hasLength(1));
  });

  test(
    'reconnect: events of both connections make one consistent stream',
    () async {
      final rec = Recording('reconnect');
      final conns = {for (final l in rec.lines) l['conn']};
      expect(conns, {1, 2});
      final seqs = [for (final e in rec.events) e.seq];
      for (var i = 1; i < seqs.length; i++) {
        expect(seqs[i], seqs[i - 1] + 1, reason: 'no gap across the resume');
      }
      await replay(rec.events);
      final assistant = (await messages()).firstWhere(
        (m) => m.role == 'assistant',
      );
      expect(assistant.status, 'final');
    },
  );

  group('single events', () {
    Map<String, Object?> conv([Map<String, Object?> o = const {}]) =>
        sample('conversation', {'id': 'c_1', ...o});

    test(
      'run.queued after the rename does not bring the queue id back',
      () async {
        await reducer.apply([
          const RunQueued(
            1,
            conversationId: 'c_1',
            runId: 'q_1',
            position: 0,
            thinking: false,
            origin: 'app',
          ),
          const RunStarted(
            2,
            conversationId: 'c_1',
            runId: 'run_1',
            queuedId: 'q_1',
            thinking: false,
          ),
          const RunQueued(
            3,
            conversationId: 'c_1',
            runId: 'q_1',
            position: 0,
            thinking: false,
            origin: 'app',
          ),
        ], epoch: 'e');
        final runs = await db.select(db.runs).get();
        expect(runs.map((r) => (r.runId, r.queuedId, r.status)), [
          ('run_1', 'q_1', 'running'),
        ]);
      },
    );

    test('a run that left the queue moves the ones behind it up', () async {
      await reducer.apply([
        const RunQueued(
          1,
          conversationId: 'c_1',
          runId: 'q_a',
          position: 0,
          thinking: false,
          origin: 'app',
        ),
        const RunStarted(
          2,
          conversationId: 'c_1',
          runId: 'run_a',
          queuedId: 'q_a',
          thinking: false,
        ),
        const RunQueued(
          3,
          conversationId: 'c_2',
          runId: 'q_b',
          position: 1,
          thinking: false,
          origin: 'app',
        ),
        const RunQueued(
          4,
          conversationId: 'c_3',
          runId: 'q_c',
          position: 2,
          thinking: false,
          origin: 'app',
        ),
        // the user stops the middle one while it waits
        const RunFinished(
          5,
          conversationId: 'c_2',
          runId: 'q_b',
          status: 'cancelled',
          usage: null,
          error: null,
        ),
      ], epoch: 'e');
      Future<int?> pos(String id) async => (await (db.select(
        db.runs,
      )..where((t) => t.runId.equals(id))).getSingle()).position;
      expect(
        [await pos('run_a'), await pos('q_b'), await pos('q_c')],
        [0, null, 1],
      );
    });

    test(
      'context samples are live only; the final one is left to the conversation',
      () async {
        await reducer.apply([
          const RunStarted(
            1,
            conversationId: 'c_1',
            runId: 'run_1',
            queuedId: null,
            thinking: true,
          ),
          ContextUpdated(
            2,
            conversationId: 'c_1',
            runId: 'run_1',
            tokens: 9000,
            max: 65536,
            pct: 13.7,
            warn: false,
            source: 'sample',
            measuredAt: t0,
            isFinal: false,
          ),
        ], epoch: 'e');
        final run = live['c_1']!;
        expect(run.context!.tokens, 9000);
        expect(run.isThinking, isTrue, reason: 'no text yet');
        await reducer.apply([
          ContextUpdated(
            3,
            conversationId: 'c_1',
            runId: 'run_1',
            tokens: 9100,
            max: 65536,
            pct: 13.9,
            warn: false,
            source: 'final_read',
            measuredAt: t0,
            isFinal: true,
          ),
        ], epoch: 'e');
        expect(live['c_1']!.context!.tokens, 9000);
      },
    );

    test('joining a stream midway marks the text partial', () async {
      await reducer.apply([
        const MessageDelta(
          1,
          conversationId: 'c_1',
          runId: 'run_1',
          messageId: 7,
          delta: 'lo',
        ),
      ], epoch: 'e');
      expect(live['c_1']!.partial, isTrue);
      expect(live['c_1']!.text, 'lo');
    });

    test('a conversation update replaces the stored one', () async {
      await reducer.apply([
        ConversationCreated(1, Conversation.fromJson(conv({'title': null}))),
        ConversationUpdated(
          2,
          Conversation.fromJson(conv({'title': 'Uptime', 'archived': true})),
        ),
      ], epoch: 'e');
      final c = await (db.select(db.conversations)).getSingle();
      expect((c.title, c.archived), ('Uptime', true));
    });

    test('health, errors and unknown events come back to the caller', () async {
      final outcome = await reducer.apply([
        const HealthStatus(1, hermes: 'down', hermesVersion: '0.22.2'),
        const ServerError(
          2,
          code: 'thinking_route_not_applied',
          message: 'x',
          refId: 'run_1',
        ),
        const UnknownEvent(3, 'card.published', {}),
      ], epoch: 'e');
      expect(outcome.health!.hermes, 'down');
      expect(outcome.errors.single.code, 'thinking_route_not_applied');
      expect(outcome.unknown.single.type, 'card.published');
      expect((await db.readSyncState()).lastSeq, 3);
    });

    test('a message the server created forgets its outbox row', () async {
      await db
          .into(db.outbox)
          .insert(
            OutboxCompanion.insert(
              clientMsgId: '3b2f8a8e-1111-4c1e-9a7b-000000000001',
              body: 'hi',
              createdAt: t0,
            ),
          );
      await reducer.apply([
        MessageCreated(
          1,
          'c_1',
          Message.fromJson(
            sample('message', {
              'id': 1,
              'conversation_id': 'c_1',
              'role': 'user',
              'status': 'final',
              'client_msg_id': '3b2f8a8e-1111-4c1e-9a7b-000000000001',
            }),
          ),
        ),
      ], epoch: 'e');
      expect(await db.select(db.outbox).get(), isEmpty);
    });
  });
}
