import 'package:delve/api/models/models.dart';
import 'package:delve/app/approvals.dart';
import 'package:delve/data/db/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/ws_fixtures.dart';

const restart = 'systemctl --user restart llama-server';
const cleanup = 'rm ~/ComfyUI/output/tmp_*.png';

/// An approval of chat [conv]; [left] is the agent's deadline from now.
Approval approval(
  String id,
  String status, {
  String conv = 'c_1',
  String command = restart,
  String actionClass = 'service_restart',
  Duration left = const Duration(seconds: 250),
  Duration expiresIn = const Duration(minutes: 30),
  String? decidedBy,
  String? choice,
  Duration? answeredAgo,
}) {
  final now = DateTime.now().toUtc();
  return Approval.fromJson(
    sample('approval', {
      'request_id': id,
      'run_id': 'run_$id',
      'conversation_id': conv,
      'command': command,
      'action_class': actionClass,
      'status': status,
      'choice': choice,
      'decided_by': decidedBy,
      'created_at': now
          .subtract(Duration(seconds: 300 - left.inSeconds))
          .toIso8601String(),
      'hermes_deadline': now.add(left).toIso8601String(),
      'expires_at': now.add(expiresIn).toIso8601String(),
      'responded_at': answeredAgo == null
          ? null
          : now.subtract(answeredAgo).toIso8601String(),
    }),
  );
}

Conversation chat(String id, String title) => Conversation.fromJson(
  sample('conversation', {
    'id': id,
    'title': title,
    'archived': false,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  }),
);

Future<void> seedChats(TestEnv env) async {
  await env.db.putConversation(chat('c_1', 'llama-server memory'));
  await env.db.putConversation(chat('c_2', 'ComfyUI cleanup'));
}

Future<void> frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps the app with [approvals] stored and opens the Approvals tab.
Future<TestEnv> openInbox(
  WidgetTester t, {
  List<Approval> approvals = const [],
}) async {
  final env = await pumpDelve(
    t,
    settle: false,
    before: (env) async {
      await seedChats(env);
      for (final a in approvals) {
        await env.db.putApproval(a);
      }
    },
  );
  await t.tap(find.text('Approvals'));
  await frames(t, 20);
  return env;
}

Finder inCard(String id, Finder f) =>
    find.descendant(of: find.byKey(ValueKey('inbox.$id')), matching: f);

void main() {
  testWidgets('pending first, the nearest deadline on top, with its chat', (
    t,
  ) async {
    await openInbox(
      t,
      approvals: [
        approval('apr_p1', 'pending'),
        approval(
          'apr_p2',
          'pending',
          conv: 'c_2',
          command: cleanup,
          actionClass: 'delete_kill',
          left: const Duration(seconds: 100),
        ),
      ],
    );
    expect(find.text('PENDING'), findsOneWidget);
    final p1 = t.getTopLeft(find.byKey(const ValueKey('inbox.apr_p1')));
    final p2 = t.getTopLeft(find.byKey(const ValueKey('inbox.apr_p2')));
    expect(p2.dy, lessThan(p1.dy));
    expect(inCard('apr_p1', find.text('llama-server memory')), findsOneWidget);
    expect(inCard('apr_p2', find.text('ComfyUI cleanup')), findsOneWidget);
    expect(inCard('apr_p2', find.text('delete / kill')), findsOneWidget);
    expect(
      inCard('apr_p2', find.textContaining('Agent waits 1:')),
      findsOneWidget,
    );
  });

  testWidgets('Allow once goes over REST; the card moves to Recent', (t) async {
    final env = await openInbox(t, approvals: [approval('apr_p1', 'pending')]);
    env.server.on(
      'POST',
      '/api/v1/approvals/apr_p1',
      (r) => FakeReply(
        200,
        approval(
          'apr_p1',
          'approved_once',
          decidedBy: 'pixel',
          choice: 'once',
          answeredAgo: Duration.zero,
        ).toJson(),
      ),
    );
    await t.tap(inCard('apr_p1', find.byKey(const Key('inbox.once'))));
    await frames(t);
    expect(env.server.requests.last.data, {'choice': 'once'});
    expect(find.byKey(const ValueKey('inbox.apr_p1')), findsNothing);
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.byKey(const Key('approvals.nothingWaiting')), findsOneWidget);
  });

  testWidgets('⋯ → Allow for session', (t) async {
    final env = await openInbox(t, approvals: [approval('apr_p1', 'pending')]);
    env.server.on(
      'POST',
      '/api/v1/approvals/apr_p1',
      (r) => FakeReply(
        200,
        approval(
          'apr_p1',
          'approved_session',
          decidedBy: 'pixel',
          choice: 'session',
          answeredAgo: Duration.zero,
        ).toJson(),
      ),
    );
    await t.tap(inCard('apr_p1', find.byKey(const Key('inbox.more'))));
    await frames(t);
    expect(find.text('Open chat'), findsOneWidget);
    await t.tap(find.text('Allow for session'));
    await frames(t);
    expect(env.server.requests.last.data, {'choice': 'session'});
    expect(find.byKey(const ValueKey('inbox.apr_p1')), findsNothing);
  });

  testWidgets('the chat line opens the chat', (t) async {
    await openInbox(t, approvals: [approval('apr_p1', 'pending')]);
    await t.tap(find.byKey(const ValueKey('inbox.chat.apr_p1')));
    await frames(t, 20);
    expect(find.byKey(const Key('chat.title')), findsOneWidget);
    expect(find.text('llama-server memory'), findsWidgets);
  });

  testWidgets('expired in the agent: late Allow once starts a follow-up', (
    t,
  ) async {
    final env = await openInbox(
      t,
      approvals: [approval('apr_e1', 'expired_in_hermes')],
    );
    expect(find.text('EXPIRED IN AGENT — STILL APPROVABLE'), findsOneWidget);
    expect(
      inCard(
        'apr_e1',
        find.textContaining('Expired in agent · approvable until'),
      ),
      findsOneWidget,
    );
    expect(
      inCard('apr_e1', find.byKey(const Key('approval.countdown'))),
      findsNothing,
    );

    await t.tap(inCard('apr_e1', find.byKey(const Key('inbox.more'))));
    await frames(t);
    expect(find.text('Allow for session'), findsNothing);
    await t.tapAt(const Offset(10, 10)); // close the menu
    await frames(t);

    env.server.on(
      'POST',
      '/api/v1/approvals/apr_e1',
      (r) => FakeReply(
        200,
        approval(
          'apr_e1',
          'late_approved',
          decidedBy: 'pixel',
          choice: 'once',
          answeredAgo: Duration.zero,
        ).toJson(),
      ),
    );
    await t.tap(inCard('apr_e1', find.byKey(const Key('inbox.once'))));
    await frames(t);
    expect(
      find.text('Approved — Delve runs it in a follow-up.'),
      findsOneWidget,
    );
    expect(find.text('Approved late'), findsOneWidget);
  });

  testWidgets('a late approval past its deadline cannot be answered', (
    t,
  ) async {
    await openInbox(
      t,
      approvals: [
        approval(
          'apr_e2',
          'expired_in_hermes',
          expiresIn: const Duration(minutes: -1),
        ),
      ],
    );
    expect(inCard('apr_e2', find.textContaining('closed at')), findsOneWidget);
    final once = t.widget<FilledButton>(
      inCard('apr_e2', find.byKey(const Key('inbox.once'))),
    );
    expect(once.onPressed, isNull);
  });

  testWidgets('a refused answer says why', (t) async {
    final env = await openInbox(t, approvals: [approval('apr_p1', 'pending')]);
    env.server.json(
      'POST',
      '/api/v1/approvals/apr_p1',
      FakeServer.detail(
        'approval_not_pending',
        'approval is no longer pending',
      ),
      status: 409,
    );
    await t.tap(inCard('apr_p1', find.byKey(const Key('inbox.deny'))));
    await frames(t);
    expect(
      find.text("Couldn't answer: approval is no longer pending (HTTP 409)"),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('inbox.apr_p1')), findsOneWidget);
  });

  testWidgets('empty; then only recent ones under "nothing waiting"', (
    t,
  ) async {
    final env = await openInbox(t);
    expect(find.byKey(const Key('approvals.empty')), findsOneWidget);

    await env.db.putApproval(
      approval(
        'apr_r1',
        'approved_once',
        decidedBy: 'pixel',
        choice: 'once',
        answeredAgo: const Duration(minutes: 1),
      ),
    );
    await env.db.putApproval(
      approval(
        'apr_r2',
        'denied',
        command: cleanup,
        decidedBy: 'tablet',
        choice: 'deny',
        answeredAgo: const Duration(minutes: 5),
      ),
    );
    await frames(t);
    expect(find.byKey(const Key('approvals.empty')), findsNothing);
    expect(find.byKey(const Key('approvals.nothingWaiting')), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('tablet'), findsOneWidget);
    final r1 = t.getTopLeft(find.byKey(const ValueKey('inbox.recent.apr_r1')));
    final r2 = t.getTopLeft(find.byKey(const ValueKey('inbox.recent.apr_r2')));
    expect(r1.dy, lessThan(r2.dy));
  });

  testWidgets('opening the tab reloads every status from the server', (
    t,
  ) async {
    final env = await pumpDelve(t, settle: false, before: seedChats);
    env.server.json('GET', '/api/v1/approvals', {
      'data': [approval('apr_p9', 'pending').toJson()],
    });
    await t.tap(find.text('Approvals'));
    await frames(t, 20);
    expect(find.byKey(const ValueKey('inbox.apr_p9')), findsOneWidget);
    final query = env.server.requests
        .lastWhere((r) => r.uri.path == '/api/v1/approvals')
        .uri
        .queryParameters;
    expect(query['limit'], '200');
    expect(query['status'], contains('executed'));
  });

  test('inbox query: sections and order', () async {
    final db = memoryDb();
    addTearDown(db.close);
    await db.putConversation(chat('c_1', 'llama-server memory'));
    for (final a in [
      approval('a', 'pending', left: const Duration(seconds: 200)),
      approval('b', 'pending', left: const Duration(seconds: 20)),
      approval('c', 'expired_in_hermes', conv: 'c_missing'),
      approval('d', 'executed', answeredAgo: const Duration(minutes: 9)),
      approval('e', 'denied', answeredAgo: const Duration(minutes: 1)),
    ]) {
      await db.putApproval(a);
    }
    final inbox = await db.watchApprovalInbox().first;
    expect([for (final i in inbox.pending) i.approval.requestId], ['b', 'a']);
    expect([for (final i in inbox.expired) i.approval.requestId], ['c']);
    expect(inbox.expired.single.chatTitle, isNull);
    expect([for (final i in inbox.recent) i.approval.requestId], ['e', 'd']);
    expect(inbox.pending.first.chatTitle, 'llama-server memory');
  });
}
