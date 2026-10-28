import 'package:delve/api/models/models.dart';
import 'package:delve/api/protocol.dart';
import 'package:delve/app/chat.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/l10n/app_localizations_en.dart';
import 'package:delve/sync/connection_status.dart';
import 'package:delve/sync/live_runs.dart';
import 'package:delve/sync/sync_engine.dart';
import 'package:delve/sync/sync_providers.dart';
import 'package:delve/ui/chat/approval_card.dart';
import 'package:delve/ui/chat/chat_items.dart';
import 'package:delve/ui/chat/tool_step_card.dart';
import 'package:delve/ui/chat/usage.dart';
import 'package:delve/ui/format.dart';
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
  Object? answerError;
  int _n = 0;

  @override
  Future<String> send(
    String text, {
    String? conversationId,
    bool? thinking,
    List<Attachment> attachments = const [],
  }) async {
    final files = attachments.isEmpty
        ? ''
        : ' [${attachments.map((a) => a.id).join(',')}]';
    calls.add(
      'send $text $conversationId${thinking ?? false ? ' thinking' : ''}'
      '$files',
    );
    final id = 'cm_${++_n}';
    await db
        .into(db.outbox)
        .insert(
          OutboxCompanion.insert(
            clientMsgId: id,
            conversationId: Value(conversationId),
            body: text,
            createdAt: t0,
            attachments: Value(attachments),
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
  Future<void> setThinking(
    String conversationId, {
    required bool thinking,
  }) async {
    calls.add('thinking $conversationId $thinking');
    await (db.update(db.conversations)
          ..where((c) => c.id.equals(conversationId)))
        .write(ConversationsCompanion(thinking: Value(thinking)));
  }

  @override
  Future<void> answer(String requestId, ApprovalChoice choice) async {
    calls.add('answer $requestId ${choice.wire}');
    final e = answerError;
    if (e != null) throw e;
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

const restartCommand = 'systemctl --user restart llama-server';

/// A run whose step asked for approval: [status] of the approval, the
/// agent's deadline [left] from now.
Future<void> seedApproval(
  TestEnv env, {
  String status = 'pending',
  Duration left = const Duration(seconds: 250),
  String stepStatus = 'running',
  String? decidedBy,
  String? choice,
}) async {
  final db = env.db;
  final now = DateTime.now().toUtc();
  final waiting = status == 'pending';
  await db.putConversation(conversation('c_1'));
  await db.batch(
    (b) => b
      ..insertAll(db.messages, [
        message(1, 'user', 'Restart it', runId: 'run_e'),
        message(
          2,
          'assistant',
          waiting ? '' : 'Done.',
          runId: 'run_e',
          status: waiting ? 'streaming' : 'final',
        ),
      ])
      ..insertAll(db.runs, [
        run('run_e', waiting ? 'waiting_for_approval' : 'completed'),
      ])
      ..insertAll(db.toolSteps, [
        step(
          5,
          'run_e',
          stepStatus,
          restartCommand,
          null,
        ).copyWith(approvalRequestId: const Value('apr_1')),
      ]),
  );
  await db.putApproval(
    Approval.fromJson(
      sample('approval', {
        'request_id': 'apr_1',
        'run_id': 'run_e',
        'conversation_id': 'c_1',
        'command': restartCommand,
        'description': 'restart a user service',
        'action_class': 'service_restart',
        'status': status,
        'choice': choice,
        'decided_by': decidedBy,
        'created_at': now
            .subtract(Duration(seconds: 300 - left.inSeconds))
            .toIso8601String(),
        'hermes_deadline': now.add(left).toIso8601String(),
        'expires_at': now.add(const Duration(minutes: 30)).toIso8601String(),
        'responded_at': decidedBy == null ? null : now.toIso8601String(),
      }),
    ),
    stepId: 5,
  );
}

const liveStatus = ConnectionStatus(phase: ConnectionPhase.live);

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

  group('top bar', () {
    testWidgets('page colour, a fade under it, the chip on the right edge', (
      t,
    ) async {
      await start(t, seedFinished);
      await openChat(t);
      final bar = t.widget<AppBar>(find.byKey(const Key('chat.topBar')));
      expect(bar.backgroundColor, const Color(0xFF111213));
      expect(find.byKey(const Key('chat.menu')), findsNothing);
      expect(find.byTooltip('Chat options'), findsNothing);
      // the chip ends on the 16 dp gutter (the screen is 448 dp wide)
      expect(t.getTopRight(find.byKey(const Key('chat.contextChip'))).dx, 432);
      // the fade sits right under the bar, page colour to transparent
      final fade = find.byKey(const Key('chat.fade'));
      expect(
        t.getTopLeft(fade).dy,
        t.getBottomLeft(find.byKey(const Key('chat.topBar'))).dy,
      );
      expect(t.getSize(fade).height, 24);
      final gradient =
          (t.widget<DecoratedBox>(fade).decoration as BoxDecoration).gradient!
              as LinearGradient;
      expect(gradient.colors.first, const Color(0xFF111213));
      expect(gradient.colors.last.a, 0);
    });

    testWidgets('closing the Usage sheet does not open a closed keyboard', (
      t,
    ) async {
      await start(t, seedFinished);
      await openChat(t);
      final field = find.byKey(const Key('composer.field'));
      FocusNode focus() => t
          .state<EditableTextState>(
            find.descendant(of: field, matching: find.byType(EditableText)),
          )
          .widget
          .focusNode;
      await t.tap(field);
      await t.pump();
      expect(focus().hasFocus, isTrue);
      // Back hides the keyboard, the field keeps the focus
      t.testTextInput.hide();
      await t.pump();

      await t.tap(find.byKey(const Key('chat.contextChip')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('usage.sheet')), findsOneWidget);
      await t.tap(find.byKey(const Key('usage.close')));
      await t.pumpAndSettle();
      expect(focus().hasFocus, isFalse);
      expect(t.testTextInput.isVisible, isFalse);
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
      // every frame until the move is done shows the message: no empty
      // intro, no empty chat in between
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 16));
        expect(
          find.text('Your agent on archlinux · over Tailscale'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('msg.9')).evaluate().isNotEmpty ||
              find.byKey(const ValueKey('outbox.cm_1')).evaluate().isNotEmpty,
          isTrue,
          reason: 'frame $i',
        );
      }
      await t.pumpAndSettle();
      expect(fake.calls, contains('open c_new'));
      expect(find.byKey(const ValueKey('msg.9')), findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(const Key('chat.title'))).data,
        'hi there',
      );
    });
  });

  group('approvals', () {
    Future<void> startApproval(
      WidgetTester t, {
      bool live = true,
      String status = 'pending',
      Duration left = const Duration(seconds: 250),
      String stepStatus = 'running',
      String? decidedBy,
      String? choice,
    }) async {
      await pumpDelve(
        t,
        actions: fake,
        status: live ? liveStatus : null,
        settle: false,
        before: (env) async {
          fake.db = env.db;
          await seedApproval(
            env,
            status: status,
            left: left,
            stepStatus: stepStatus,
            decidedBy: decidedBy,
            choice: choice,
          );
        },
      );
      await openChat(t, settle: false);
    }

    Future<void> tapKey(WidgetTester t, String key) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f);
      await t.pump();
      await t.pump();
    }

    FilledButton button(WidgetTester t, String key) =>
        t.widget<FilledButton>(find.byKey(Key(key)));

    testWidgets('waiting: class, command, countdown and three answers', (
      t,
    ) async {
      await startApproval(t);
      expect(find.byKey(const Key('approval.apr_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('step.5')), findsNothing);
      expect(find.text('Approval needed'), findsOneWidget);
      expect(find.text('service restart'), findsOneWidget);
      expect(find.text('restart a user service'), findsOneWidget);
      expect(find.textContaining('Agent waits 4:'), findsOneWidget);
      expect(find.byKey(const Key('approval.offline')), findsNothing);

      await tapKey(t, 'approval.once');
      await tapKey(t, 'approval.session');
      await tapKey(t, 'approval.deny');
      expect(fake.calls, [
        'open c_1',
        'answer apr_1 once',
        'answer apr_1 session',
        'answer apr_1 deny',
      ]);
    });

    testWidgets('not connected: the buttons are off, never queued', (t) async {
      await startApproval(t, live: false);
      expect(find.byKey(const Key('approval.offline')), findsOneWidget);
      expect(button(t, 'approval.once').onPressed, isNull);
      expect(button(t, 'approval.deny').onPressed, isNull);
      expect(
        t
            .widget<TextButton>(find.byKey(const Key('approval.session')))
            .onPressed,
        isNull,
      );
      await tapKey(t, 'approval.once');
      expect(fake.calls.where((c) => c.startsWith('answer')), isEmpty);
    });

    testWidgets('under a minute the countdown is urgent', (t) async {
      await startApproval(t, left: const Duration(seconds: 45));
      expect(find.textContaining('Agent waits 0:4'), findsOneWidget);
    });

    testWidgets('expired in the agent: late approval, no session', (t) async {
      await startApproval(
        t,
        status: 'expired_in_hermes',
        stepStatus: 'timeout',
      );
      expect(find.text('Agent stopped waiting'), findsOneWidget);
      expect(find.byKey(const Key('approval.late')), findsOneWidget);
      expect(find.byKey(const Key('approval.session')), findsNothing);
      expect(find.byKey(const Key('approval.countdown')), findsNothing);
      await tapKey(t, 'approval.once');
      expect(fake.calls.last, 'answer apr_1 once');
    });

    testWidgets('answered: the step card says who and how', (t) async {
      await startApproval(
        t,
        status: 'approved_once',
        stepStatus: 'ok',
        decidedBy: 'pixel',
        choice: 'once',
      );
      expect(find.byKey(const Key('approval.apr_1')), findsNothing);
      expect(find.byKey(const ValueKey('step.5')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('approval.outcome.apr_1')),
        findsOneWidget,
      );
      expect(find.text('Approved'), findsOneWidget);
      expect(find.textContaining('by you · Allow once'), findsOneWidget);
    });

    testWidgets('a refused answer says why', (t) async {
      fake.answerError = const RequestRejected(
        'approval_not_pending',
        'approval is no longer pending',
      );
      await startApproval(t);
      await tapKey(t, 'approval.deny');
      await t.pump(const Duration(milliseconds: 100));
      expect(
        find.text("Couldn't answer: approval is no longer pending"),
        findsOneWidget,
      );
      // the buttons work again after a failure
      expect(button(t, 'approval.deny').onPressed, isNotNull);
    });

    testWidgets('a follow-up run after a late approval reads as one', (
      t,
    ) async {
      await pumpDelve(
        t,
        actions: fake,
        settle: false,
        before: (env) async {
          fake.db = env.db;
          final db = env.db;
          await db.putConversation(conversation('c_1'));
          await db.batch(
            (b) => b
              ..insertAll(db.messages, [
                message(
                  1,
                  'system',
                  'A felhasználó utólag jóváhagyta …:\n\n$restartCommand',
                  runId: 'run_f',
                ),
                message(2, 'assistant', 'Restarted.', runId: 'run_f'),
              ])
              ..insertAll(db.runs, [
                run(
                  'run_f',
                  'completed',
                ).copyWith(origin: const Value('late_approval')),
              ]),
          );
        },
      );
      await openChat(t, settle: false);
      expect(find.text('Follow-up run: approved'), findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(const Key('followUp.command'))).data,
        displayCommand(restartCommand),
      );
      expect(find.textContaining('utólag'), findsNothing);
    });

    test('countdown, clock time and class labels', () {
      expect(countdownText(const Duration(seconds: 252)), '4:12');
      expect(countdownText(const Duration(seconds: 45)), '0:45');
      expect(countdownText(const Duration(seconds: -3)), '0:00');
      final at = DateTime(2026, 10, 20, 1, 30);
      expect(clockTime(at, DateTime(2026, 10, 20, 0, 5)), '01:30');
      expect(clockTime(at, DateTime(2026, 10, 19, 23)), 'Tue 01:30');
      final l = AppLocalizationsEn();
      expect(approvalClassLabel(l, 'pkg_upgrade'), 'package upgrade');
      expect(approvalClassLabel(l, 'delete_kill'), 'delete / kill');
      expect(approvalClassLabel(l, 'whatever'), 'command');
      expect(followUpCommand('Prompt:\n\nrm -r /tmp/x'), 'rm -r /tmp/x');
      expect(followUpCommand('only text'), 'only text');
    });
  });

  group('thinking and usage', () {
    /// A finished Thinking run with its reasoning.
    Future<void> seedThought(TestEnv env) async {
      final db = env.db;
      await db.putConversation(conversation('c_1'));
      await db.batch(
        (b) => b
          ..insertAll(db.messages, [
            message(1, 'user', 'Why did it restart?', runId: 'run_t'),
            message(
              2,
              'assistant',
              'Out of memory.',
              runId: 'run_t',
            ).copyWith(reasoning: const Value('Plan: read the journal.')),
          ])
          ..insertAll(db.runs, [
            run('run_t', 'completed').copyWith(
              thinking: const Value(true),
              perf: const Value({'first_delta_s': 23.4}),
            ),
          ]),
      );
    }

    /// A Thinking run that has not written anything yet.
    Future<void> seedThinking(TestEnv env) async {
      final db = env.db;
      await db.putConversation(conversation('c_1'));
      await db.batch(
        (b) => b
          ..insertAll(db.messages, [
            message(1, 'user', 'Think hard', runId: 'run_k'),
            message(2, 'assistant', '', runId: 'run_k', status: 'streaming'),
          ])
          ..insertAll(db.runs, [
            run('run_k', 'running').copyWith(thinking: const Value(true)),
          ]),
      );
    }

    testWidgets('the pill saves Thinking for this chat; caption for 2 s', (
      t,
    ) async {
      final env = await start(t, seedFinished);
      await openChat(t);
      expect(find.byKey(const Key('composer.caption')), findsNothing);
      await t.tap(find.byKey(const Key('composer.thinking')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(fake.calls, contains('thinking c_1 true'));
      expect(find.byKey(const Key('composer.caption')), findsOneWidget);
      final stored = await env.db.select(env.db.conversations).getSingle();
      expect(stored.thinking, isTrue);
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('composer.caption')), findsNothing);
    });

    testWidgets('a new chat sends its first message with Thinking', (t) async {
      await start(t, (_) async {});
      await t.tap(find.byKey(const Key('chats.emptyNew')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('composer.thinking')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('composer.field')), 'hi');
      await t.pump();
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(fake.calls, ['send hi null thinking']);
    });

    testWidgets('a finished Thinking run: "Thought for 23 s" opens it', (
      t,
    ) async {
      await start(t, seedThought);
      await openChat(t);
      expect(find.text('Thought for 23 s'), findsOneWidget);
      expect(find.text('Plan: read the journal.'), findsNothing);
      await t.tap(find.byKey(const Key('thinking.toggle')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Plan: read the journal.'), findsOneWidget);
    });

    testWidgets('live thinking: clock and tokens, then "Thought for"', (
      t,
    ) async {
      await start(t, seedThinking);
      await openChat(t, settle: false);
      expect(find.byKey(const Key('thinking.live')), findsOneWidget);
      expect(find.text('Working…'), findsNothing);

      final container = ProviderScope.containerOf(
        t.element(find.byType(ChatScreen)),
      );
      final started = DateTime.now();
      LiveContext sample(int tokens) => LiveContext(
        tokens: tokens,
        max: 65536,
        pct: tokens / 655.36,
        warn: false,
        source: 'sample',
        measuredAt: DateTime.now(),
      );
      container.read(liveRunsProvider.notifier).set({
        'c_1': LiveRun(
          conversationId: 'c_1',
          runId: 'run_k',
          thinking: true,
          startedAt: started,
          messageId: 2,
          context: sample(9100),
          contextStart: 8600,
        ),
      });
      await t.pump();
      expect(find.textContaining('500 tok'), findsOneWidget);
      // the chip follows the live sample (9,100 / 65,536)
      expect(
        t.widget<Text>(find.byKey(const Key('contextChip.label'))).data,
        '14%',
      );

      container.read(liveRunsProvider.notifier).set({
        'c_1': LiveRun(
          conversationId: 'c_1',
          runId: 'run_k',
          thinking: true,
          startedAt: started,
          messageId: 2,
          text: 'Done.',
          firstDeltaAt: started.add(const Duration(seconds: 12)),
        ),
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('thinking.live')), findsNothing);
      expect(find.text('Thought for 12 s'), findsOneWidget);
    });

    testWidgets('the context chip opens the Usage sheet', (t) async {
      final env = await start(t, seedFinished);
      Map<String, Object?> runJson(
        String id,
        String status,
        Map<String, Object?> perf,
      ) => sample('run', {
        'run_id': id,
        'conversation_id': 'c_1',
        'status': status,
        'perf': perf,
      });
      env.server.json('GET', '/api/v1/conversations/c_1/usage', {
        'conversation_id': 'c_1',
        'totals': sample('conversation')['totals'],
        'context': sample('conversation')['context'],
        'runs': [
          runJson('run_a', 'completed', {
            'prompt_tokens': 122,
            'prefill_tps': 210.4,
            'gen_tps': 20.6,
            'first_delta_s': 2.96,
          }),
          runJson('run_b', 'running', {
            'prompt_tokens': 900,
            'prefill_tps': 642.3,
            'gen_tps': 21.4,
            'first_delta_s': 6.8,
          }),
        ],
      });
      await openChat(t);
      expect(
        t.widget<Text>(find.byKey(const Key('contextChip.label'))).data,
        '13%',
      );
      expect(find.byKey(const Key('contextChip.warn')), findsNothing);
      await t.tap(find.byKey(const Key('chat.contextChip')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('usage.sheet')), findsOneWidget);
      expect(find.text('Usage'), findsOneWidget);
      expect(find.text('Kernel check · 2 runs'), findsOneWidget);
      expect(find.text('25,954'), findsOneWidget);
      expect(find.text('Run 1'), findsOneWidget);
      expect(find.text('Run 2 · running'), findsOneWidget);
      expect(find.text('642 tok/s'), findsOneWidget);
      expect(find.text('21.4 tok/s'), findsOneWidget);
      // run 1 prefilled only 122 tokens: no prefill speed
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('usage.run.run_a')),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('usage.close')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('usage.sheet')), findsNothing);
    });

    testWidgets('the sheet says when usage cannot be loaded', (t) async {
      final env = await start(t, seedFinished);
      await openChat(t);
      env.server.unreachable = true;
      await t.tap(find.byKey(const Key('chat.contextChip')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('usage.error')), findsOneWidget);
    });

    testWidgets('the chip warns above 75 % and is empty before a measure', (
      t,
    ) async {
      await start(t, (env) async {
        await env.db.putConversation(conversation('c_1', pct: 81, warn: true));
        await env.db.putConversation(
          Conversation.fromJson(
            sample('conversation', {
              'id': 'c_2',
              'title': 'Fresh chat',
              'updated_at': t0
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
              'context': {
                'tokens': null,
                'max': null,
                'pct': null,
                'warn': false,
                'measured_at': null,
              },
            }),
          ),
        );
      });
      await openChat(t);
      expect(find.byKey(const Key('contextChip.warn')), findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(const Key('contextChip.label'))).data,
        '81%',
      );
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Fresh chat'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('contextChip.empty')), findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(const Key('contextChip.label'))).data,
        '—',
      );
    });

    test('numbers: counts, context text, speeds, live context', () {
      expect(tokenCount(48210), '48,210');
      expect(contextText(41980, 65536, 64.1), '41,980 / 65,536 · 64%');
      expect(contextText(null, 65536, null), isNull);

      final speeds = runSpeeds(
        Run.fromJson(
          sample('run', {
            'perf': {'prompt_tokens': 499, 'prefill_tps': 210.0},
          }),
        ),
      );
      expect(speeds.prefill, '—');
      expect(speeds.generation, '—');
      expect(speeds.firstToken, '—');

      final buffer = LiveRunsBuffer()
        ..started(
          conversationId: 'c',
          runId: 'r',
          thinking: true,
          at: DateTime.now(),
        );
      LiveContext ctx(int n) => LiveContext(
        tokens: n,
        max: 100,
        pct: n.toDouble(),
        warn: n >= 75,
        source: 'sample',
        measuredAt: DateTime.now(),
      );
      buffer
        ..context('c', 'r', ctx(40))
        ..context('c', 'r', ctx(80));
      final live = buffer['c']!;
      expect(live.contextStart, 40);
      expect(live.contextGrowth, 40);
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
