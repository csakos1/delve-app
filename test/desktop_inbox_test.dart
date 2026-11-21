import 'package:delve/api/models/models.dart';
import 'package:delve/app/inbox.dart';
import 'package:delve/app/platform.dart';
import 'package:delve/app/router.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/ui/desktop/chats_area.dart';
import 'package:delve/ui/desktop/inbox_area.dart';
import 'package:delve/ui/desktop/inbox_detail.dart';
import 'package:delve/ui/desktop/rail.dart';
import 'package:delve/ui/desktop/shortcut_sheet.dart';
import 'package:delve/ui/screens/approvals_screen.dart' show ApprovalDetail;
import 'package:delve/ui/screens/news_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'approvals_screen_test.dart' show approval, seedChats;
import 'news_test.dart' show newsJson, storyJson;
import 'support/fake_server.dart';
import 'support/harness.dart';
import 'watches_test.dart' show itemJson;

/// The desktop's Inbox (L2e, backend API 23): the rail item and its badge,
/// the list column with its keys, the open item in the content.
final _linux = PlatformCaps.linux(host: 'archlinux');
const _frame = Size(1440, 900);

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Ctrl+[key], then a few frames (a countdown never settles).
Future<void> _ctrl(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await _frames(t);
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await _frames(t);
}

String _ago(Duration d) => DateTime.now().toUtc().subtract(d).toIso8601String();

/// A waiting approval as the Inbox lists it.
Map<String, Object?> approvalItem(
  Approval a, {
  String chat = 'llama-server memory',
}) => {
  ...FakeServer.sample('inbox_item'),
  'id': 'approval:${a.requestId}',
  'kind': a.status == 'pending' ? 'approval' : 'late_approval',
  'at': a.createdAt.toIso8601String(),
  'title': a.command,
  'source': chat,
  'approval': a.toJson(),
};

/// A watcher's hit ([minutes] ago).
Map<String, Object?> hitItem(int id, {String? title, int minutes = 20}) {
  final at = _ago(Duration(minutes: minutes));
  final hit = itemJson(id, {'title': ?title, 'seen_at': at, 'judged_at': at});
  return {
    ...FakeServer.sample('inbox_item_hit'),
    'id': 'watch_hit:$id',
    'at': at,
    'title': hit['title'],
    'hit': hit,
  };
}

/// The must-read of the samples (story 8121), an hour old.
Map<String, Object?> storyItem() => {
  ...FakeServer.sample('inbox_item_story'),
  'at': _ago(const Duration(hours: 1)),
  'story': newsJson(),
};

/// A notice: the failing feed, the failed switch or the missed schedule.
Map<String, Object?> noticeItem(String sample, {int hours = 2}) => {
  ...FakeServer.sample('inbox_item_$sample'),
  'at': _ago(Duration(hours: hours)),
};

/// The server's side of the Inbox: what is open, what was cleared today.
class FakeInbox {
  FakeInbox(this.open);

  final List<Map<String, Object?>> open;
  final List<Map<String, Object?>> done = [];

  Map<String, Object?> view() => {
    'data': [...open],
    'done': [...done],
    'open': open.length,
    'approvals': open.where((i) => i['approval'] != null).length,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  static String _id(Object? body) =>
      (body! as Map<String, Object?>)['id']! as String;

  /// An API 23 server with this Inbox.
  void serve(FakeServer server) {
    server
      ..json('GET', '/api/v1/meta', {...FakeServer.meta, 'api_revision': 23})
      ..on('GET', '/api/v1/inbox', (_) => FakeReply(200, view()))
      ..on('POST', '/api/v1/inbox/done', (r) {
        final at = open.indexWhere((i) => i['id'] == _id(r.data));
        if (at < 0) {
          return FakeReply(404, FakeServer.detail('inbox_item_not_found'));
        }
        if (open[at]['doneable'] != true) {
          return FakeReply(409, FakeServer.detail('not_doneable'));
        }
        done.insert(0, {
          ...open.removeAt(at),
          'done_at': DateTime.now().toUtc().toIso8601String(),
        });
        return FakeReply(200, view());
      })
      ..on('POST', '/api/v1/inbox/undo', (r) {
        final at = done.indexWhere((i) => i['id'] == _id(r.data));
        if (at < 0) {
          return FakeReply(404, FakeServer.detail('inbox_item_not_found'));
        }
        open.insert(0, {...done.removeAt(at)}..remove('done_at'));
        return FakeReply(200, view());
      });
  }
}

/// The desktop on Chats with an API 23 server that has [inbox]; the
/// [approvals] are in the database, as the socket would have put them.
Future<TestEnv> _desktop(
  WidgetTester t,
  FakeInbox inbox, {
  List<Approval> approvals = const [],
  void Function(FakeServer server)? serve,
}) async {
  final env = await pumpDelve(
    t,
    caps: _linux,
    window: _frame,
    settle: false,
    before: (env) async {
      await seedChats(env);
      for (final a in approvals) {
        await env.db.putApproval(a);
      }
      inbox.serve(env.server);
      serve?.call(env.server);
    },
  );
  await _frames(t);
  return env;
}

Finder _rowOf(String id) => find.byKey(ValueKey('inbox.row.$id'));

/// The item open in the content (null: none).
String? _open(WidgetTester t) => find.byType(InboxDetail).evaluate().isEmpty
    ? null
    : t.widget<InboxDetail>(find.byType(InboxDetail)).id;

int _calls(TestEnv env, String call) =>
    env.server.calls.where((c) => c == call).length;

void main() {
  group('the Inbox (L2e)', () {
    test('items, places and what comes after a cleared one', () {
      expect(selectedInboxItem(Routes.inbox), isNull);
      expect(
        selectedInboxItem(Routes.inboxItem('watch_hit:17')),
        'watch_hit:17',
      );
      expect(
        selectedInboxItem(Routes.inboxItem('feed_failing:a b/c')),
        'feed_failing:a b/c',
      );
      expect(selectedInboxItem(Routes.chats), isNull);

      final inbox = Inbox.fromJson({
        'data': [hitItem(17), hitItem(12), noticeItem('feed')],
        'done': <Object?>[],
        'open': 3,
        'approvals': 0,
        'updated_at': _ago(Duration.zero),
      });
      final view = InboxState(inbox: inbox);
      expect(view.placeOf('watch_hit:12'), InboxPlace.open);
      expect(view.placeOf('watch_hit:99'), InboxPlace.gone);
      // the row that takes its place; the last one's place is the row before
      expect(
        inboxRouteAfter(view, 'watch_hit:17'),
        Routes.inboxItem('watch_hit:12'),
      );
      expect(
        inboxRouteAfter(view, 'feed_failing:sail-world.com'),
        Routes.inboxItem('watch_hit:12'),
      );
      expect(inboxRouteAfter(view, 'watch_hit:99'), Routes.inbox);
      expect(
        inboxRouteAfter(
          InboxState(inbox: Inbox(items: [inbox.items.first], open: 1)),
          'watch_hit:17',
        ),
        Routes.inbox,
      );
    });

    test('the shortcut sheet lists it only with a server that has it', () {
      final l = lookupAppLocalizations(const Locale('en'));
      List<String> labels({required bool inbox}) => [
        for (final column in shortcutColumns(l, tools: false, inbox: inbox))
          for (final group in column)
            for (final line in group.lines) line.label,
      ];
      expect(labels(inbox: true), contains('Inbox'));
      expect(labels(inbox: true), contains(l.shortcutsDoneOrArchive));
      expect(labels(inbox: false), isNot(contains('Inbox')));
      expect(labels(inbox: false), contains(l.shortcutsArchive));
    });

    testWidgets('an older server: no rail item, Ctrl+1 does nothing, the '
        'palette does not name it', (t) async {
      final env = await pumpDelve(
        t,
        caps: _linux,
        window: _frame,
        settle: false,
        before: seedChats,
      );
      await _frames(t);
      expect(find.byKey(const Key('rail.chats')), findsOneWidget);
      expect(find.byKey(const Key('rail.inbox')), findsNothing);
      await _ctrl(t, LogicalKeyboardKey.digit1);
      expect(find.byType(InboxList), findsNothing);
      expect(find.byType(ChatsPlaceholder), findsOneWidget);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      expect(find.byKey(const Key('palette')), findsOneWidget);
      expect(find.byKey(const ValueKey('palette.area.inbox')), findsNothing);
      expect(env.server.calls, isNot(contains('GET /api/v1/inbox')));
    });

    testWidgets('the rail: first, with the count of what is open – warn '
        'while an approval can be answered', (t) async {
      final a = approval('apr_1', 'pending');
      final inbox = FakeInbox([approvalItem(a), hitItem(17), storyItem()]);
      await _desktop(t, inbox, approvals: [a]);
      final item = find.byKey(const Key('rail.inbox'));
      expect(item, findsOneWidget);
      expect(
        t.getTopLeft(item).dy,
        lessThan(t.getTopLeft(find.byKey(const Key('rail.chats'))).dy),
      );
      final badge = find.byKey(const Key('rail.inbox.badge'));
      expect(
        find.descendant(of: badge, matching: find.text('3')),
        findsOneWidget,
      );
      expect(t.widget<RailBadge>(badge).warn, isTrue);
      expect(t.getSize(badge).height, 16);
      // top 0 / right −1 of the 40 × 34 item
      expect(t.getTopRight(badge).dx, t.getTopRight(item).dx + 1);
      expect(t.getTopRight(badge).dy, t.getTopRight(item).dy);

      // the palette goes there too
      await _ctrl(t, LogicalKeyboardKey.keyK);
      expect(find.byKey(const ValueKey('palette.area.inbox')), findsOneWidget);
    });

    testWidgets('without an approval the badge is neutral; an empty Inbox '
        'has none and says so', (t) async {
      final inbox = FakeInbox([hitItem(17)]);
      await _desktop(t, inbox);
      final badge = find.byKey(const Key('rail.inbox.badge'));
      expect(t.widget<RailBadge>(badge).warn, isFalse);

      await _ctrl(t, LogicalKeyboardKey.digit1);
      expect(find.byType(InboxList), findsOneWidget);
      expect(find.byKey(const Key('inbox.placeholder')), findsOneWidget);
      expect(find.text('1 open'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.keyJ);
      await _key(t, LogicalKeyboardKey.keyE);
      expect(badge, findsNothing);
      expect(find.byKey(const Key('inbox.empty')), findsOneWidget);
      expect(find.byKey(const Key('inbox.placeholder.empty')), findsOneWidget);
      expect(find.text('Nothing needs you'), findsNWidgets(2));
      expect(find.byKey(const Key('inbox.count')), findsNothing);
    });

    testWidgets('Ctrl+1 opens the list: every kind as a row, newest first; '
        'J / K step through them', (t) async {
      final a = approval('apr_1', 'pending');
      final inbox = FakeInbox([
        approvalItem(a),
        noticeItem('switch', hours: 1),
        hitItem(17, minutes: 90),
        noticeItem('feed'),
        noticeItem('schedule', hours: 3),
      ]);
      await _desktop(t, inbox, approvals: [a]);
      await _ctrl(t, LogicalKeyboardKey.digit1);
      expect(find.byType(InboxArea), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('pane.list')),
          matching: find.byType(InboxList),
        ),
        findsOneWidget,
      );
      final ids = [for (final i in inbox.open) i['id']! as String];
      final tops = [for (final id in ids) t.getTopLeft(_rowOf(id)).dy];
      expect(tops, [...tops]..sort());
      for (final word in [
        'Approval',
        'Model switch failed',
        'Watch hit',
        'Feed failing',
        'Schedule failed',
      ]) {
        expect(find.text(word), findsOneWidget, reason: word);
      }
      // the approval's last line starts with the agent's countdown
      expect(find.textContaining('Agent waits'), findsOneWidget);
      expect(find.text('missed its time'), findsOneWidget);
      expect(find.byKey(const Key('inbox.hints')), findsOneWidget);
      expect(_open(t), isNull);

      await _key(t, LogicalKeyboardKey.keyJ);
      expect(_open(t), ids[0]);
      expect(find.byType(ApprovalDetail), findsOneWidget);
      expect(find.text('Inbox · 1 of 5'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.arrowDown);
      expect(_open(t), ids[1]);
      expect(find.byKey(const Key('inbox.notice')), findsOneWidget);
      expect(find.text('Inbox · 2 of 5'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.keyK);
      expect(_open(t), ids[0]);
      // next and previous in the header do the same
      await t.tap(find.byKey(const Key('inbox.next')));
      await _frames(t);
      expect(_open(t), ids[1]);
      await t.tap(find.byKey(const Key('inbox.previous')));
      await _frames(t);
      expect(_open(t), ids[0]);
    });

    testWidgets('an approval is answered in the content, never cleared', (
      t,
    ) async {
      final a = approval('apr_1', 'pending');
      final inbox = FakeInbox([approvalItem(a), hitItem(17)]);
      final env = await _desktop(t, inbox, approvals: [a]);
      await _ctrl(t, LogicalKeyboardKey.digit1);
      await t.tap(_rowOf('approval:apr_1'));
      await _frames(t);
      expect(find.byType(ApprovalDetail), findsOneWidget);
      expect(find.byKey(const Key('approval.detail.once')), findsOneWidget);
      expect(find.byKey(const Key('approval.detail.deny')), findsOneWidget);
      expect(find.byKey(const Key('inbox.done')), findsNothing);
      await _key(t, LogicalKeyboardKey.keyE);
      expect(_calls(env, 'POST /api/v1/inbox/done'), 0);
      expect(_open(t), 'approval:apr_1');
      // a hit has Done
      await _key(t, LogicalKeyboardKey.keyJ);
      expect(_open(t), 'watch_hit:17');
      expect(find.byKey(const Key('inbox.done')), findsOneWidget);
    });

    testWidgets('E clears the open item and moves on; “Done today” holds it '
        'with Undo, Ctrl+Z brings it back', (t) async {
      final inbox = FakeInbox([
        hitItem(17),
        hitItem(12, title: 'ASUS Dual RTX 4070 Super', minutes: 40),
        noticeItem('feed'),
      ]);
      final env = await _desktop(t, inbox);
      await _ctrl(t, LogicalKeyboardKey.digit1);
      await _key(t, LogicalKeyboardKey.keyJ);
      expect(_open(t), 'watch_hit:17');

      await _key(t, LogicalKeyboardKey.keyE);
      expect(_calls(env, 'POST /api/v1/inbox/done'), 1);
      expect(_open(t), 'watch_hit:12'); // the row that took its place
      expect(_rowOf('watch_hit:17'), findsNothing);
      expect(find.text('Cleared'), findsOneWidget);
      expect(find.text('DONE TODAY  1'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('rail.inbox.badge')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // Done today opens: the cleared row, muted, with when
      await t.tap(find.byKey(const Key('inbox.doneToday')));
      await _frames(t);
      expect(_rowOf('watch_hit:17'), findsOneWidget);
      expect(find.textContaining('Cleared '), findsOneWidget);

      await _ctrl(t, LogicalKeyboardKey.keyZ);
      expect(_calls(env, 'POST /api/v1/inbox/undo'), 1);
      expect(find.byKey(const Key('inbox.doneToday')), findsNothing);
      expect(_rowOf('watch_hit:17'), findsOneWidget);
      expect(find.text('3 open'), findsOneWidget);

      // the header's Done does what E does: on to the row in its place
      expect(_open(t), 'watch_hit:12');
      await t.tap(find.byKey(const Key('inbox.done')));
      await _frames(t);
      expect(_calls(env, 'POST /api/v1/inbox/done'), 2);
      expect(_open(t), 'feed_failing:sail-world.com');
      expect(find.text('DONE TODAY  1'), findsOneWidget);
      expect(find.text('2 open'), findsOneWidget);
    });

    testWidgets('a hit: the listing; Open link opens it and clears it, the '
        'item stays on screen with Undo; its watch in the inspector', (
      t,
    ) async {
      final inbox = FakeInbox([hitItem(17), noticeItem('feed')]);
      final env = await _desktop(
        t,
        inbox,
        serve: (server) => server
          ..json('GET', '/api/v1/watches', {
            'data': [FakeServer.sample('watch')],
          })
          ..json('GET', '/api/v1/watches/rtx-4070-super-180k/items', {
            'data': <Object?>[],
            'next_before': null,
          }),
      );
      await _ctrl(t, LogicalKeyboardKey.digit1);
      await t.tap(_rowOf('watch_hit:17'));
      await _frames(t);
      expect(find.byKey(const Key('inbox.hit')), findsOneWidget);
      expect(find.byKey(const Key('inbox.hit.price')), findsOneWidget);
      expect(find.text('Inbox · 1 of 2'), findsOneWidget);
      expect(find.byKey(const Key('inspector.inbox.watch')), findsOneWidget);
      expect(
        find.byKey(const Key('inspector.inbox.watch.name')),
        findsOneWidget,
      );

      await t.tap(find.byKey(const Key('inbox.hit.open')));
      await _frames(t);
      expect(env.links.opened.single.path, '/apro/x17/friss.html');
      expect(_calls(env, 'POST /api/v1/inbox/done'), 1);
      expect(_open(t), 'watch_hit:17');
      expect(find.byKey(const Key('inbox.hit')), findsOneWidget);
      expect(find.text('Inbox · done today'), findsOneWidget);
      expect(find.byKey(const Key('inbox.done')), findsNothing);

      await t.tap(find.byKey(const Key('inbox.undo')));
      await _frames(t);
      expect(_calls(env, 'POST /api/v1/inbox/undo'), 1);
      expect(find.text('Inbox · 1 of 2'), findsOneWidget);
    });

    testWidgets('a must-read is the reading view; it is cleared, then read, '
        'only once it was on screen for 2 s', (t) async {
      final inbox = FakeInbox([storyItem(), noticeItem('feed')]);
      final env = await _desktop(
        t,
        inbox,
        serve: (server) => server
          ..json('GET', '/api/v1/news/items/8121', storyJson())
          ..on(
            'PATCH',
            '/api/v1/news/items/8121',
            (_) => FakeReply(200, storyJson({'read': true})),
          ),
      );
      await _ctrl(t, LogicalKeyboardKey.digit1);
      expect(find.text('Must read'), findsOneWidget);
      await t.tap(_rowOf('must_read:8121'));
      await _frames(t);
      expect(find.byType(NewsStoryScreen), findsOneWidget);
      expect(find.text('Inbox · 1 of 2'), findsOneWidget);
      expect(find.byKey(const Key('inspector.story')), findsOneWidget);
      expect(_calls(env, 'PATCH /api/v1/news/items/8121'), 0);
      expect(_calls(env, 'POST /api/v1/inbox/done'), 0);

      await t.pump(const Duration(seconds: 2));
      await _frames(t);
      final calls = env.server.calls;
      final cleared = calls.indexOf('POST /api/v1/inbox/done');
      expect(cleared, greaterThan(-1));
      expect(
        calls.indexOf('PATCH /api/v1/news/items/8121'),
        greaterThan(cleared),
      );
      // it stays on screen, now under Done today
      expect(find.byType(NewsStoryScreen), findsOneWidget);
      expect(find.text('Inbox · done today'), findsOneWidget);
      expect(find.byKey(const Key('inbox.undo')), findsOneWidget);
      expect(find.text('DONE TODAY  1'), findsOneWidget);
      expect(_rowOf('must_read:8121'), findsOneWidget);
    });

    testWidgets('a notice says what failed and leads into its area', (t) async {
      final inbox = FakeInbox([noticeItem('schedule'), noticeItem('feed')]);
      await _desktop(t, inbox);
      await _ctrl(t, LogicalKeyboardKey.digit1);
      await t.tap(
        _rowOf('schedule_failed:9a3c5e7b-2d4f-4b6a-8c1e-0f2a4b6c8d1e'),
      );
      await _frames(t);
      expect(find.byKey(const Key('inbox.notice')), findsOneWidget);
      expect(
        t
            .widget<SelectableText>(find.byKey(const Key('inbox.notice.title')))
            .data,
        'Weekly disk report',
      );
      expect(find.text('Open the schedule'), findsOneWidget);
      // a notice has nothing to inspect
      expect(find.byKey(const Key('pane.inspector')), findsNothing);
      expect(find.byKey(const Key('pane.inspector.toggle')), findsNothing);

      await _key(t, LogicalKeyboardKey.keyJ);
      expect(_open(t), 'feed_failing:sail-world.com');
      expect(
        find.text('This feed has failed 3 rounds in a row'),
        findsOneWidget,
      );
      expect(find.text('Open the feed'), findsOneWidget);
    });
  });
}
