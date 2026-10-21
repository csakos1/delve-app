import 'package:delve/api/api_error.dart';
import 'package:delve/api/models/models.dart';
import 'package:delve/app/chat_list.dart';
import 'package:delve/app/session.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/l10n/app_localizations_en.dart';
import 'package:delve/sync/connection_status.dart';
import 'package:delve/ui/format.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/ws_fixtures.dart';

final t0 = DateTime.utc(2026, 10, 20, 8);

Conversation conversation(
  String id, {
  String? title = 'Kernel and CPU count',
  DateTime? updated,
  bool archived = false,
  bool thinking = false,
  double? pct = 13.3,
  bool warn = false,
}) => Conversation.fromJson(
  sample('conversation', {
    'id': id,
    'title': title,
    'preview': null,
    'updated_at': (updated ?? t0).toIso8601String(),
    'archived': archived,
    'thinking': thinking,
    'context': {
      'tokens': pct == null ? null : 8728,
      'max': pct == null ? null : 65536,
      'pct': pct,
      'warn': warn,
      'measured_at': pct == null ? null : t0.toIso8601String(),
    },
  }),
);

Map<String, Object?> conversationJson(String id, {bool archived = false}) =>
    conversation(id, archived: archived).toJson();

MessagesCompanion message(
  int id,
  String conversationId,
  String role,
  String content,
) => MessagesCompanion.insert(
  id: Value(id),
  conversationId: conversationId,
  role: role,
  content: content,
  status: 'final',
  createdAt: t0,
);

RunsCompanion run(String id, String conversationId, String status) =>
    RunsCompanion.insert(
      runId: id,
      conversationId: conversationId,
      status: status,
    );

ApprovalsCompanion approval(
  String id,
  String conversationId,
  String command,
  String status, {
  DateTime? created,
}) => ApprovalsCompanion.insert(
  requestId: id,
  runId: 'run_1',
  conversationId: conversationId,
  command: command,
  patternKeys: const [],
  actionClass: 'delete_kill',
  status: status,
  choices: const ['once', 'session', 'deny'],
  createdAt: created ?? t0,
  hermesDeadline: t0.add(const Duration(minutes: 5)),
  expiresAt: t0.add(const Duration(hours: 24)),
);

void main() {
  group('chat list query', () {
    late AppDatabase db;
    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    test('newest first, archived apart, previews and counters', () async {
      await db.putConversation(conversation('c_old', updated: t0));
      await db.putConversation(
        conversation('c_new', updated: t0.add(const Duration(hours: 1))),
      );
      await db.putConversation(conversation('c_arch', archived: true));
      await db.batch(
        (b) => b
          ..insertAll(db.messages, [
            message(1, 'c_old', 'user', 'first question'),
            message(2, 'c_old', 'assistant', 'an answer'),
            message(3, 'c_old', 'system', 'late approval prompt'),
            message(4, 'c_old', 'user', 'second question'),
            message(5, 'c_old', 'assistant', ''), // streaming, no text yet
          ])
          ..insertAll(db.runs, [
            run('run_a', 'c_old', 'waiting_for_approval'),
            run('q_b', 'c_old', 'queued'),
            run('q_c', 'c_old', 'queued'),
            run('run_d', 'c_old', 'completed'),
            run('run_e', 'c_new', 'failed'),
          ])
          ..insertAll(db.approvals, [
            approval('a1', 'c_old', 'rm -r /tmp/old', 'denied'),
            approval(
              'a2',
              'c_old',
              'rm -r /tmp/x',
              'pending',
              created: t0.add(const Duration(minutes: 1)),
            ),
            approval('a3', 'c_new', 'paru -Syu', 'expired'),
          ]),
      );

      final list = await db.watchChatList().first;
      expect([for (final i in list) i.conversation.id], ['c_new', 'c_old']);
      final old = list[1];
      expect(old.lastText, 'second question');
      expect(old.firstUserText, 'first question');
      expect(old.approvalCommand, 'rm -r /tmp/x');
      expect(old.activeRuns, 1);
      expect(old.queuedRuns, 2);
      final fresh = list[0];
      expect(fresh.lastText, isNull);
      expect(fresh.approvalCommand, isNull); // expired cannot be answered
      expect(fresh.activeRuns, 0);
      expect(fresh.queuedRuns, 0);

      final archived = await db.watchChatList(archived: true).first;
      expect([for (final i in archived) i.conversation.id], ['c_arch']);
    });

    test('re-emits when a message or approval arrives', () async {
      await db.putConversation(conversation('c_1'));
      final seen = <String?>[];
      final sub = db.watchChatList().listen(
        (l) => seen.add(l.single.approvalCommand ?? l.single.lastText),
      );
      await pumpEventQueue();
      await db.into(db.messages).insert(message(1, 'c_1', 'user', 'hi'));
      await pumpEventQueue();
      await db
          .into(db.approvals)
          .insert(approval('a1', 'c_1', 'kill 42', 'expired_in_hermes'));
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, 'hi', 'kill 42']);
    });

    test('sync state stream', () async {
      expect((await db.watchSyncState().first).lastSeq, isNull);
      await db.writeSyncState(epoch: 'e1', lastSeq: 7);
      expect((await db.watchSyncState().first).lastSeq, 7);
    });
  });

  group('formatting', () {
    test('list time', () {
      final now = DateTime(2026, 10, 20, 23, 41); // a Tuesday
      expect(listTime(DateTime(2026, 10, 20, 7, 30), now), '07:30');
      expect(listTime(DateTime(2026, 10, 19, 20, 52), now), 'Mon');
      expect(listTime(DateTime(2026, 10, 14, 9), now), 'Wed');
      expect(listTime(DateTime(2026, 10, 13, 9), now), '13 Oct');
      expect(listTime(DateTime(2025, 12, 31, 9), now), '31 Dec 2025');
    });

    test('preview text', () {
      expect(
        previewText('**Done.**\n\n```bash\nuname -r\n```\nok'),
        'Done. uname -r ok',
      );
      expect(previewText('  a \t b  '), 'a b');
    });

    test('api errors read as short reasons', () {
      final l = AppLocalizationsEn();
      expect(
        apiErrorText(l, const ApiUnreachable('h', 'x')),
        l.pairUnreachable,
      );
      expect(
        apiErrorText(
          l,
          const ApiRequestError(409, code: 'busy', message: 'Run active'),
        ),
        'Run active (HTTP 409)',
      );
      expect(
        apiErrorText(l, const ApiRequestError(500)),
        'server error (HTTP 500)',
      );
      expect(
        apiErrorText(l, const ApiRateLimited(Duration(seconds: 7))),
        'too many requests, try again in 7 s',
      );
    });
  });

  group('pager', () {
    /// A container whose session has loaded (the pager needs the API client);
    /// the session's own `/meta` call is forgotten.
    Future<ProviderContainer> paired(TestEnv env) async {
      final c = env.container()..read(sessionProvider);
      await pumpEventQueue(times: 200);
      expect(c.read(apiProvider), isNotNull);
      env.server.requests.clear();
      return c;
    }

    test(
      'refresh stores the first page; loadMore follows the cursor',
      () async {
        final env = TestEnv(credentials: pairedCredentials());
        addTearDown(env.dispose);
        env.server.on('GET', '/api/v1/conversations', (r) {
          final cursor = r.uri.queryParameters['cursor'];
          return cursor == null
              ? FakeReply(200, {
                  'data': [conversationJson('c_1'), conversationJson('c_2')],
                  'next_cursor': 'cur2',
                })
              : FakeReply(200, {
                  'data': [conversationJson('c_3')],
                  'next_cursor': null,
                });
        });
        final c = await paired(env);
        final pager = c.read(chatListPagerProvider(false).notifier);

        await pager.loadMore(); // first page, then the second
        expect(
          env.server.requests.map((r) => r.uri.queryParameters['cursor']),
          [null, 'cur2'],
        );
        expect(env.server.requests.first.uri.queryParameters['limit'], '50');
        final rows = await env.db.select(env.db.conversations).get();
        expect(rows.map((r) => r.id).toSet(), {'c_1', 'c_2', 'c_3'});
        expect(c.read(chatListPagerProvider(false)).exhausted, isTrue);

        await pager.loadMore(); // nothing left
        expect(env.server.requests, hasLength(2));

        await pager.refresh();
        expect(env.server.requests, hasLength(3));
        expect(c.read(chatListPagerProvider(false)).cursor, 'cur2');
      },
    );

    test('a failed page keeps the state and rethrows', () async {
      final env = TestEnv(credentials: pairedCredentials());
      addTearDown(env.dispose);
      env.server.unreachable = true;
      final c = await paired(env);
      await expectLater(
        c.read(chatListPagerProvider(false).notifier).refresh(),
        throwsA(isA<ApiUnreachable>()),
      );
      final s = c.read(chatListPagerProvider(false));
      expect(s.loading, isFalse);
      expect(s.fetched, isFalse);
    });

    test('the archived pager asks for archived conversations', () async {
      final env = TestEnv(credentials: pairedCredentials());
      addTearDown(env.dispose);
      env.server.json('GET', '/api/v1/conversations', {
        'data': [conversationJson('c_9', archived: true)],
        'next_cursor': null,
      });
      final c = await paired(env);
      await c.read(chatListPagerProvider(true).notifier).refresh();
      expect(
        env.server.requests.single.uri.queryParameters['archived'],
        'true',
      );
      final archived = await env.db.watchChatList(archived: true).first;
      expect(archived.single.conversation.id, 'c_9');
      expect(c.read(chatListPagerProvider(true)).exhausted, isTrue);
      expect(c.read(chatListPagerProvider(false)).fetched, isFalse);
    });

    test('archive writes the server answer', () async {
      final env = TestEnv(credentials: pairedCredentials());
      addTearDown(env.dispose);
      await env.db.putConversation(conversation('c_1'));
      env.server.on(
        'PATCH',
        '/api/v1/conversations/c_1',
        (r) => FakeReply(200, conversationJson('c_1', archived: true)),
      );
      final c = await paired(env);
      await c
          .read(chatListPagerProvider(false).notifier)
          .setArchived('c_1', archived: true);
      expect(env.server.requests.single.data, {'archived': true});
      expect(await env.db.watchChatList().first, isEmpty);
    });
  });

  group('Chats screen', () {
    Future<void> seed(TestEnv env) async {
      final db = env.db;
      await db.putConversation(
        conversation(
          'c_run',
          title: 'llama-server memory after update',
          updated: t0.add(const Duration(hours: 2)),
          thinking: true,
          pct: 64,
        ),
      );
      await db.putConversation(
        conversation(
          'c_appr',
          title: null,
          updated: t0.add(const Duration(hours: 1)),
          pct: 82,
          warn: true,
        ),
      );
      await db.putConversation(conversation('c_done', title: 'Balaton water'));
      await db.batch(
        (b) => b
          ..insertAll(db.messages, [
            message(1, 'c_run', 'user', 'Why is llama using more memory?'),
            message(2, 'c_appr', 'user', 'Clean up the LoRA dataset'),
            message(3, 'c_done', 'assistant', 'Siófok 98 cm'),
          ])
          ..insertAll(db.runs, [
            run('run_1', 'c_run', 'running'),
            run('q_2', 'c_run', 'queued'),
          ])
          ..insert(
            db.approvals,
            approval('a1', 'c_appr', 'rm ~/out/tmp_*.png', 'pending'),
          ),
      );
    }

    testWidgets('rows: title, context, markers, no message preview', (t) async {
      await pumpDelve(t, before: seed);
      expect(find.text('llama-server memory after update'), findsOneWidget);
      // the last message is not shown under the title
      expect(find.text('Why is llama using more memory?'), findsNothing);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('running · 1 queued'), findsOneWidget);
      expect(find.byKey(const Key('chats.thinking')), findsOneWidget);

      // untitled: the first user message stands in
      expect(find.text('Clean up the LoRA dataset'), findsOneWidget);
      expect(find.textContaining('rm ~/out/tmp_*.png'), findsNothing);
      expect(find.byKey(const Key('chats.marker.approval')), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);

      expect(find.text('Balaton water'), findsOneWidget);
      expect(find.text('Siófok 98 cm'), findsNothing);
      expect(find.byKey(const Key('chats.banner')), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // the time sits on the right edge whatever the title length
      final edges = {
        for (final e in find.byKey(const Key('chats.time')).evaluate())
          t.getTopRight(find.byWidget(e.widget)).dx,
      };
      expect(edges, {448 - 16.0});
    });

    testWidgets('empty: message and a single New chat button', (t) async {
      await pumpDelve(t);
      expect(find.text('No chats yet'), findsOneWidget);
      expect(find.byKey(const Key('chats.emptyNew')), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('first load while connecting shows the skeleton', (t) async {
      await pumpDelve(
        t,
        status: const ConnectionStatus(phase: ConnectionPhase.connecting),
        settle: false,
      );
      expect(find.byKey(const Key('chats.skeleton')), findsOneWidget);
      expect(find.byKey(const Key('chats.progress')), findsOneWidget);
      expect(find.text('No chats yet'), findsNothing);
    });

    testWidgets('retrying: banner with Details to the connection log', (
      t,
    ) async {
      await pumpDelve(
        t,
        before: seed,
        status: const ConnectionStatus(
          phase: ConnectionPhase.backoff,
          attempt: 3,
          problem: ConnectionProblem.unreachable,
        ),
      );
      expect(find.byKey(const Key('chats.banner')), findsOneWidget);
      expect(find.textContaining('Retrying (attempt 3)'), findsOneWidget);
      expect(find.textContaining('is Tailscale on?'), findsOneWidget);
      expect(find.text('Balaton water'), findsOneWidget); // list stays

      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.text('Connection log'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('swipe archives on the server, Undo restores', (t) async {
      final env = await pumpDelve(t, before: seed);
      env.server.on('PATCH', '/api/v1/conversations/c_done', (r) {
        final archived = (r.data as Map<String, Object?>)['archived']! as bool;
        return FakeReply(200, {
          ...conversation('c_done', title: 'Balaton water').toJson(),
          'archived': archived,
        });
      });

      await t.drag(find.text('Balaton water'), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(env.server.calls, contains('PATCH /api/v1/conversations/c_done'));
      expect(find.text('Balaton water'), findsNothing);
      expect(find.text('Chat archived'), findsOneWidget);

      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect(env.server.requests.last.data, {'archived': false});
      expect(find.text('Balaton water'), findsOneWidget);
    });

    testWidgets('archive failure keeps the row and says why', (t) async {
      final env = await pumpDelve(t, before: seed);
      env.server.unreachable = true;
      await t.drag(find.text('Balaton water'), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(find.text('Balaton water'), findsOneWidget);
      expect(find.textContaining("Couldn't archive"), findsOneWidget);
    });

    testWidgets('search filters titles and messages', (t) async {
      await pumpDelve(t, before: seed);
      await t.tap(find.byKey(const Key('chats.search')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('chats.searchField')), 'siófok');
      await t.pump();
      expect(find.text('Balaton water'), findsOneWidget);
      expect(find.text('llama-server memory after update'), findsNothing);

      await t.enterText(find.byKey(const Key('chats.searchField')), 'zzz');
      await t.pump();
      expect(find.text('No chats match “zzz”'), findsOneWidget);

      await t.tap(find.byKey(const Key('chats.search'))); // close
      await t.pumpAndSettle();
      expect(find.text('llama-server memory after update'), findsOneWidget);
    });

    testWidgets('More → Archived chats loads them; swipe restores', (t) async {
      final env = await pumpDelve(t, before: seed);
      env.server.on('GET', '/api/v1/conversations', (r) {
        final archived = r.uri.queryParameters['archived'] == 'true';
        return FakeReply(200, {
          'data': [
            if (archived)
              conversation(
                'c_old',
                title: 'Old archived chat',
                archived: true,
              ).toJson(),
          ],
          'next_cursor': null,
        });
      });
      env.server.on(
        'PATCH',
        '/api/v1/conversations/c_old',
        (r) => FakeReply(
          200,
          conversation('c_old', title: 'Old archived chat').toJson(),
        ),
      );
      expect(find.text('Old archived chat'), findsNothing);

      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Archived chats'));
      await t.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Old archived chat'), findsOneWidget);
      expect(find.text('Balaton water'), findsNothing); // not archived

      await t.drag(find.text('Old archived chat'), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(env.server.requests.last.data, {'archived': false});
      expect(find.text('Old archived chat'), findsNothing);
      expect(find.text('Chat restored'), findsOneWidget);
      expect(find.textContaining('No archived chats'), findsOneWidget);

      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Chats'));
      await t.pumpAndSettle();
      expect(find.text('Old archived chat'), findsOneWidget);
    });

    testWidgets('a row opens its chat without bottom navigation', (t) async {
      await pumpDelve(t, before: seed);
      await t.tap(find.text('Balaton water'));
      await t.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
