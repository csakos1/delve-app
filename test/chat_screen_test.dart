import 'package:delve/api/models/models.dart';
import 'package:delve/app/chat.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/l10n/app_localizations_en.dart';
import 'package:delve/sync/live_runs.dart';
import 'package:delve/sync/sync_engine.dart';
import 'package:delve/sync/sync_providers.dart';
import 'package:delve/ui/chat/chat_items.dart';
import 'package:delve/ui/chat/tool_step_card.dart';
import 'package:delve/ui/screens/chat_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';
import 'support/ws_fixtures.dart';

final t0 = DateTime.utc(2026, 10, 20, 8);

/// Records what the chat asks for; sending writes the outbox like the
/// engine does.
class FakeChatActions implements ChatActions {
  late AppDatabase db;
  final calls = <String>[];
  Object? stopError;
  int _n = 0;

  @override
  Future<String> send(String text, {String? conversationId}) async {
    calls.add('send $text $conversationId');
    final id = 'cm_${++_n}';
    await db
        .into(db.outbox)
        .insert(
          OutboxCompanion.insert(
            clientMsgId: id,
            conversationId: Value(conversationId),
            body: text,
            createdAt: t0,
          ),
        );
    return id;
  }

  @override
  Future<void> retry(String clientMsgId) async =>
      calls.add('retry $clientMsgId');

  @override
  Future<void> discard(String clientMsgId) async {
    calls.add('discard $clientMsgId');
    await db.forgetOutbox(clientMsgId);
  }

  @override
  Future<String> stop(String runId) async {
    calls.add('stop $runId');
    final e = stopError;
    if (e != null) throw e;
    return 'stopping';
  }

  @override
  Future<void> open(String conversationId) async =>
      calls.add('open $conversationId');

  @override
  void close() => calls.add('close');
}

Conversation conversation(
  String id, {
  String? title = 'Kernel check',
  double pct = 13.3,
  bool warn = false,
}) => Conversation.fromJson(
  sample('conversation', {
    'id': id,
    'title': title,
    'updated_at': t0.toIso8601String(),
    'thinking': false,
    'context': {
      'tokens': 8728,
      'max': 65536,
      'pct': pct,
      'warn': warn,
      'measured_at': t0.toIso8601String(),
    },
  }),
);

MessagesCompanion message(
  int id,
  String role,
  String content, {
  String conversationId = 'c_1',
  String? runId,
  String status = 'final',
  String? interim,
  String? clientMsgId,
}) => MessagesCompanion.insert(
  id: Value(id),
  conversationId: conversationId,
  runId: Value(runId),
  role: role,
  content: content,
  interim: Value(interim),
  status: status,
  clientMsgId: Value(clientMsgId),
  createdAt: t0.add(Duration(seconds: id)),
);

RunsCompanion run(String id, String status, {String? error, int? minute}) =>
    RunsCompanion.insert(
      runId: id,
      conversationId: 'c_1',
      status: status,
      error: Value(error),
      queuedAt: Value(t0.add(Duration(minutes: minute ?? 0))),
      startedAt: Value(status == 'queued' ? null : DateTime.now().toUtc()),
    );

ToolStepsCompanion step(
  int id,
  String runId,
  String status,
  String command,
  Map<String, Object?>? result, {
  double? duration,
}) => ToolStepsCompanion.insert(
  id: Value(id),
  runId: runId,
  tool: 'terminal',
  status: status,
  preview: Value(command),
  result: Value(result),
  durationS: Value(duration),
);

/// A finished exchange with three tool steps, then a run that failed.
Future<void> seedFinished(TestEnv env) async {
  final db = env.db;
  await db.putConversation(conversation('c_1'));
  await db.batch(
    (b) => b
      ..insertAll(db.messages, [
        message(1, 'user', 'Check the kernel', runId: 'run_a'),
        message(
          2,
          'assistant',
          '**Kernel** 7.2.11, `24` CPUs.',
          runId: 'run_a',
          interim: "I'll check uname.",
        ),
        message(3, 'user', 'Now fail', runId: 'run_b'),
        message(4, 'assistant', '', runId: 'run_b', status: 'failed'),
      ])
      ..insertAll(db.runs, [
        run('run_a', 'completed'),
        run('run_b', 'failed', error: 'run_lost'),
      ])
      ..insertAll(db.toolSteps, [
        step(1, 'run_a', 'ok', 'uname -r && nproc', {
          'exit_code': 0,
          'output': '7.2.11\n24',
        }, duration: 0.41),
        step(2, 'run_a', 'denied', 'rm -r /tmp/x', {
          'exit_code': -1,
          'output': '',
          'error': 'BLOCKED: Command denied by user.',
        }),
        step(3, 'run_a', 'error', 'false', {
          'exit_code': 1,
          'output': 'boom',
        }, duration: 2.3),
      ]),
  );
}

/// A run streaming now, a second message queued behind it.
Future<void> seedRunning(TestEnv env) async {
  final db = env.db;
  await db.putConversation(conversation('c_1'));
  await db.batch(
    (b) => b
      ..insertAll(db.messages, [
        message(1, 'user', 'Run uptime', runId: 'run_c'),
        message(2, 'assistant', '', runId: 'run_c', status: 'streaming'),
        message(3, 'user', 'And then free -h', runId: 'q_d'),
      ])
      ..insertAll(db.runs, [run('run_c', 'running'), run('q_d', 'queued')]),
  );
}

Future<void> openChat(WidgetTester t, {bool settle = true}) async {
  await t.tap(find.text('Kernel check'));
  if (settle) {
    await t.pumpAndSettle();
  } else {
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
}

Finder inStep(int id, Finder f) =>
    find.descendant(of: find.byKey(ValueKey('step.$id')), matching: f);

void main() {
  late FakeChatActions fake;
  setUp(() => fake = FakeChatActions());

  Future<TestEnv> start(WidgetTester t, Future<void> Function(TestEnv) seed) =>
      pumpDelve(
        t,
        actions: fake,
        before: (env) async {
          fake.db = env.db;
          await seed(env);
        },
      );

  group('finished chat', () {
    testWidgets('messages, run rail, tool steps, failed run', (t) async {
      await start(t, seedFinished);
      await openChat(t);

      expect(fake.calls, ['open c_1']);
      expect(find.byKey(const Key('chat.title')), findsOneWidget);
      expect(find.text('Kernel check'), findsOneWidget);
      expect(find.text('Check the kernel'), findsOneWidget);
      expect(find.text("I'll check uname."), findsOneWidget);
      expect(find.byType(MarkdownBody), findsWidgets);

      expect(inStep(1, find.text('OK')), findsOneWidget);
      expect(
        inStep(1, find.text(displayCommand('uname -r && nproc'))),
        findsOneWidget,
      );
      expect(inStep(1, find.text('0.4 s')), findsOneWidget);
      expect(inStep(2, find.text('Denied')), findsOneWidget);
      expect(
        inStep(2, find.text('Not run. The agent was told it was denied.')),
        findsOneWidget,
      );
      expect(inStep(2, find.byKey(const Key('step.result'))), findsNothing);
      expect(inStep(3, find.text('Error')), findsOneWidget);
      expect(inStep(3, find.text('exit 1 · boom')), findsOneWidget);

      expect(find.text('Run failed'), findsOneWidget);
      expect(
        find.text('The agent restarted and lost this run.'),
        findsOneWidget,
      );
      // no run is open: Send (disabled), no Stop, no queue note
      expect(find.byKey(const Key('composer.stop')), findsNothing);
      expect(find.byKey(const Key('composer.queued')), findsNothing);
    });

    testWidgets('Retry sends the message of the failed run again', (t) async {
      await start(t, seedFinished);
      await openChat(t);
      await t.ensureVisible(find.text('Retry'));
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(fake.calls, contains('send Now fail c_1'));
      expect(find.text('Waiting for the connection'), findsOneWidget);
    });

    testWidgets('a result expands with a copy button', (t) async {
      await start(t, seedFinished);
      await openChat(t);
      expect(inStep(1, find.byTooltip('Copy')), findsNothing);
      await t.tap(inStep(1, find.text('terminal')));
      await t.pumpAndSettle();
      expect(inStep(1, find.byTooltip('Copy')), findsOneWidget);
      await t.tap(inStep(1, find.byTooltip('Copy')));
      await t.pump();
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('composer sends into this chat and clears', (t) async {
      await start(t, seedFinished);
      await openChat(t);
      final send = find.byKey(const Key('composer.send'));
      await t.enterText(find.byKey(const Key('composer.field')), ' hello ');
      await t.pump();
      await t.tap(send);
      await t.pumpAndSettle();
      expect(fake.calls, contains('send hello c_1'));
      final field = t.widget<TextField>(
        find.byKey(const Key('composer.field')),
      );
      expect(field.controller!.text, isEmpty);
      expect(find.text('hello'), findsOneWidget); // the outbox bubble
    });

    testWidgets('failed outbox row: Retry and Discard', (t) async {
      await start(t, (env) async {
        await seedFinished(env);
        await env.db
            .into(env.db.outbox)
            .insert(
              OutboxCompanion.insert(
                clientMsgId: 'cm_x',
                conversationId: const Value('c_1'),
                body: 'stuck message',
                createdAt: t0,
                state: const Value('failed'),
                lastError: const Value('busy'),
              ),
            );
      });
      await openChat(t);
      expect(find.text('Not sent: busy'), findsOneWidget);
      await t.tap(
        find.descendant(
          of: find.byKey(const ValueKey('outbox.cm_x')),
          matching: find.text('Retry'),
        ),
      );
      await t.pump();
      expect(fake.calls, contains('retry cm_x'));
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(fake.calls, contains('discard cm_x'));
      expect(find.text('stuck message'), findsNothing);
    });

    testWidgets('context above 75 % shows the warning', (t) async {
      await start(t, (env) async {
        await seedFinished(env);
        await env.db.putConversation(conversation('c_1', pct: 82, warn: true));
      });
      await openChat(t);
      expect(
        find.text('Context 82% full — consider a new chat'),
        findsOneWidget,
      );
    });

    testWidgets('leaving the chat closes it', (t) async {
      await start(t, seedFinished);
      await openChat(t);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(fake.calls, ['open c_1', 'close']);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('running chat', () {
    testWidgets('live text overlays the message; Stop and queue note', (
      t,
    ) async {
      await start(t, seedRunning);
      await openChat(t, settle: false);
      expect(find.byKey(const Key('run.footer')), findsOneWidget);
      expect(find.text('Working…'), findsOneWidget);
      expect(find.text('1 more message queued'), findsOneWidget);

      final container = ProviderScope.containerOf(
        t.element(find.byType(ChatScreen)),
      );
      container.read(liveRunsProvider.notifier).set({
        'c_1': LiveRun(
          conversationId: 'c_1',
          runId: 'run_c',
          thinking: false,
          startedAt: DateTime.now(),
          messageId: 2,
          text: 'Load average is low.',
          firstDeltaAt: DateTime.now(),
        ),
      });
      await t.pump();
      expect(find.text('Working…'), findsNothing);
      expect(find.byType(MarkdownBody), findsOneWidget);

      await t.tap(find.byKey(const Key('composer.stop')));
      await t.pump();
      expect(fake.calls, contains('stop run_c'));

      // typing turns Stop into Send (the message would be queued)
      await t.enterText(find.byKey(const Key('composer.field')), 'more');
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('composer.stop')), findsNothing);
      expect(find.byKey(const Key('composer.send')), findsOneWidget);
    });

    testWidgets('a refused Stop says why', (t) async {
      fake.stopError = const NotConnected();
      await start(t, seedRunning);
      await openChat(t, settle: false);
      await t.tap(find.byKey(const Key('composer.stop')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(
        find.text("Couldn't stop: not connected to the server"),
        findsOneWidget,
      );
    });
  });

  group('new chat', () {
    testWidgets('first message, then the screen moves to the new chat', (
      t,
    ) async {
      final env = await start(t, (_) async {});
      await t.tap(find.byKey(const Key('chats.emptyNew')));
      await t.pumpAndSettle();
      expect(
        find.text('Your agent on archlinux · over Tailscale'),
        findsOneWidget,
      );

      await t.enterText(find.byKey(const Key('composer.field')), 'hi there');
      await t.pump();
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(fake.calls, ['send hi there null']);
      expect(find.text('hi there'), findsOneWidget);
      expect(find.text('Waiting for the connection'), findsOneWidget);

      // the server answers: a conversation and the message made of cm_1
      await env.db.putConversation(conversation('c_new', title: null));
      await env.db
          .into(env.db.messages)
          .insert(
            message(
              9,
              'user',
              'hi there',
              conversationId: 'c_new',
              clientMsgId: 'cm_1',
            ),
          );
      await env.db.forgetOutbox('cm_1');
      await t.pumpAndSettle();
      expect(fake.calls, contains('open c_new'));
      expect(
        t.widget<Text>(find.byKey(const Key('chat.title'))).data,
        'hi there',
      );
    });
  });

  group('pieces', () {
    test('result text, durations, commands, failure reasons', () {
      ToolStepRow row(String status, Map<String, Object?>? result) =>
          ToolStepRow(
            id: 1,
            runId: 'r',
            tool: 'terminal',
            status: status,
            result: result,
          );
      expect(
        stepResultText(row('ok', {'exit_code': 0, 'output': 'a\nb\n'})),
        'a\nb',
      );
      expect(
        stepResultText(row('error', {'exit_code': 2, 'output': ''})),
        'exit 2',
      );
      expect(
        stepResultText(
          row('error', {
            'success': false,
            'error': 'validation_failed',
            'details': ['severity: bad'],
          }),
        ),
        'validation_failed\nseverity: bad',
      );
      expect(stepResultText(row('ok', {'card_id': 'x1'})), '{"card_id":"x1"}');
      expect(stepResultText(row('running', null)), isNull);

      expect(formatDuration(0.41), '0.4 s');
      expect(formatDuration(12.4), '12 s');
      expect(formatDuration(65), '1:05');
      expect(displayCommand('rm -rf x'), 'rm -⁠rf x');

      final l = AppLocalizationsEn();
      expect(FailedRunCard.reason(l, 'stream_unstable'), l.runFailedUnstable);
      expect(
        FailedRunCard.reason(l, 'hermes_400_bad'),
        'The agent refused the run (hermes_400_bad).',
      );
      expect(FailedRunCard.reason(l, null), l.runFailedUnknown);
    });

    test('step look follows the approval', () {
      final s = ToolStepRow(
        id: 1,
        runId: 'r',
        tool: 'terminal',
        status: 'running',
        approvalRequestId: 'a1',
      );
      ApprovalRow approval(String status) => ApprovalRow(
        requestId: 'a1',
        runId: 'r',
        conversationId: 'c',
        command: 'x',
        patternKeys: const [],
        actionClass: 'other',
        status: status,
        choices: const ['once', 'deny'],
        createdAt: t0,
        hermesDeadline: t0,
        expiresAt: t0,
      );
      expect(stepLook(s, null), StepLook.running);
      expect(stepLook(s, approval('pending')), StepLook.waiting);
      expect(stepLook(s, approval('denied')), StepLook.running);
    });

    test('open runs: the active one first, then the queue in order', () async {
      final db = memoryDb();
      addTearDown(db.close);
      await db.putConversation(conversation('c_1'));
      await db.batch(
        (b) => b.insertAll(db.runs, [
          run('q_2', 'queued', minute: 3),
          run('q_1', 'queued', minute: 2),
          run('run_x', 'completed', minute: 0),
          run('run_y', 'waiting_for_approval', minute: 1),
        ]),
      );
      final data = await db.loadChat('c_1');
      expect([for (final r in data.openRuns) r.runId], ['run_y', 'q_1', 'q_2']);
      expect(data.queuedCount, 2);
    });
  });

  testWidgets('composer stays above the system navigation bar', (t) async {
    t.view.padding = const FakeViewPadding(bottom: 48 * 3); // 48 dp at 3x
    addTearDown(t.view.resetPadding);
    await start(t, seedFinished);
    await openChat(t);
    final send = t.getRect(find.byKey(const Key('composer.send')));
    expect(send.bottom, lessThanOrEqualTo(998 - 48 - 8));
  });
}
