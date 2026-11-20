import 'package:delve/app/platform.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/theme/delve_theme.dart';
import 'package:delve/ui/desktop/desktop_shell.dart';
import 'package:delve/ui/desktop/intake.dart' show focusInTextField;
import 'package:delve/ui/desktop/palette.dart';
import 'package:delve/ui/desktop/shortcut_sheet.dart';
import 'package:delve/ui/screens/approvals_screen.dart' show ApprovalDetail;
import 'package:delve/ui/screens/chat_screen.dart';
import 'package:delve/ui/screens/chats_screen.dart';
import 'package:delve/ui/screens/system_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'approvals_screen_test.dart' show approval, seedChats;
import 'news_test.dart' show newsJson;
import 'support/fake_server.dart' show FakeServer;
import 'support/harness.dart';
import 'support/terminal_fakes.dart';

/// The desktop's layers (L2d): the command palette, the shortcut sheet and
/// the rail's tooltip (L2d1).
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
  await _frames(t, 4);
}

/// ? as Shift+/ types it on a US layout: the slash key with the
/// character "?" (the shell matches the character).
Future<void> _question(WidgetTester t) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyDownEvent(
    LogicalKeyboardKey.slash,
    character: '?',
    physicalKey: PhysicalKeyboardKey.slash,
  );
  await t.sendKeyUpEvent(
    LogicalKeyboardKey.slash,
    physicalKey: PhysicalKeyboardKey.slash,
  );
  await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await _frames(t);
}

Finder _row(String id) => find.byKey(ValueKey('palette.$id'));

/// The desktop on Chats: two chats, an approval waiting ([approvals]), the
/// tools on with [tools] (Terminal set up).
Future<TestEnv> _desktop(
  WidgetTester t, {
  bool approvals = false,
  bool tools = false,
  void Function(FakeServer server)? serve,
}) async {
  final fakes = TerminalFakes();
  final env = await pumpDelve(
    t,
    caps: _linux,
    window: _frame,
    settle: false,
    terminal: fakes,
    before: (env) async {
      await seedChats(env);
      if (approvals) await env.db.putApproval(approval('apr_1', 'pending'));
      if (tools) {
        await fakes.setUpDone();
        await fakes.store.write(kDesktopToolsKey, '1');
      }
      serve?.call(env.server);
    },
  );
  await _frames(t);
  return env;
}

void main() {
  group('the command palette (L2d1)', () {
    test('folding keeps the places: accents off, one for one', () {
      expect(foldForSearch('Vízállás Siófok'), 'vizallas siofok');
      expect(foldForSearch('Ő'), 'o');
      expect(paletteWords('  Comfy  UI '), ['comfy', 'ui']);
      expect(paletteMarks('ComfyUI cleanup', ['clean', 'comfy']), [
        (0, 5),
        (8, 13),
      ]);
      expect(paletteMarks('aaa', ['aa', 'a']), [(0, 2)]);
    });

    testWidgets('Ctrl+K opens it: Now, Go to, Recent chats, Actions; Esc '
        'closes it', (t) async {
      await _desktop(t, approvals: true);
      expect(find.byKey(const Key('palette')), findsNothing);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      expect(find.byKey(const Key('palette')), findsOneWidget);
      expect(
        t.getTopLeft(find.byKey(const Key('palette'))).dy,
        DelveDesktop.paletteTop,
      );
      expect(
        t.getSize(find.byKey(const Key('palette'))).width,
        DelveDesktop.paletteWidth,
      );
      for (final group in ['NOW', 'GO TO', 'RECENT CHATS', 'ACTIONS']) {
        expect(find.text(group), findsOneWidget, reason: group);
      }
      expect(_row('approval.apr_1'), findsOneWidget);
      expect(_row('area.chats'), findsOneWidget);
      expect(_row('area.observability'), findsOneWidget);
      // the tools are off: no Terminal, no Files, no dock
      expect(_row('area.terminal'), findsNothing);
      expect(_row('area.files'), findsNothing);
      expect(_row('action.dock'), findsNothing);
      expect(_row('chat.c.c_1'), findsOneWidget);
      expect(_row('action.newAgent'), findsOneWidget);
      // the field has the focus
      expect(focusInTextField(), isTrue);

      await _key(t, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('palette')), findsNothing);
    });

    testWidgets('an approval is opened from Now, never answered', (t) async {
      final env = await _desktop(t, approvals: true);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      // the first row is selected: Enter opens it
      await _key(t, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('palette')), findsNothing);
      expect(find.byType(ApprovalDetail), findsOneWidget);
      expect(env.server.calls.where((c) => c.startsWith('POST')), isEmpty);
    });

    testWidgets('typing: chats matched and marked, accents ignored; ↓ and '
        'Enter open the row', (t) async {
      await _desktop(t);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      await t.enterText(find.byKey(const Key('palette.field')), 'cömfy');
      await _frames(t, 4);
      expect(find.text('CHATS'), findsOneWidget);
      expect(find.text('GO TO'), findsNothing);
      expect(_row('chat.c.c_2'), findsOneWidget);
      expect(_row('chat.c.c_1'), findsNothing);

      // another word: only the other chat
      await t.enterText(find.byKey(const Key('palette.field')), 'memory');
      await _frames(t, 4);
      expect(_row('chat.c.c_1'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.enter);
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(t.widget<ChatsScreen>(find.byType(ChatsScreen)).selected, 'c:c_1');
    });

    testWidgets('↓ moves the selection; Pages reach an area', (t) async {
      await _desktop(t);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      await t.enterText(find.byKey(const Key('palette.field')), 'syst');
      await _frames(t, 4);
      expect(find.text('PAGES'), findsOneWidget);
      expect(_row('area.system'), findsOneWidget);
      await _key(t, LogicalKeyboardKey.arrowDown);
      await _key(t, LogicalKeyboardKey.arrowUp);
      await _key(t, LogicalKeyboardKey.enter);
      expect(find.byType(SystemScreen), findsOneWidget);
    });

    testWidgets('nothing matches', (t) async {
      await _desktop(t);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      await t.enterText(find.byKey(const Key('palette.field')), 'qqqzzz');
      await _frames(t, 4);
      expect(find.byKey(const Key('palette.empty')), findsOneWidget);
      // Enter with nothing to run keeps it open
      await _key(t, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('palette')), findsOneWidget);
    });

    testWidgets('a story the app holds is found under News', (t) async {
      await _desktop(
        t,
        serve: (server) => server.json('GET', '/api/v1/news/sections', {
          'data': [
            {
              ...FakeServer.sample('news_section'),
              'top': [newsJson()],
            },
          ],
        }),
      );
      await _ctrl(t, LogicalKeyboardKey.keyK);
      await t.enterText(find.byKey(const Key('palette.field')), 'ac75');
      await _frames(t, 6);
      expect(find.text('NEWS'), findsOneWidget);
      expect(_row('news.8121'), findsOneWidget);
    });

    testWidgets('with the tools on: Terminal, Files and the dock', (t) async {
      await _desktop(t, tools: true);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      expect(_row('area.terminal'), findsOneWidget);
      expect(_row('area.files'), findsOneWidget);
      // the actions are below the fold: filter to the dock
      await t.enterText(find.byKey(const Key('palette.field')), 'dock');
      await _frames(t, 4);
      expect(_row('action.dock'), findsOneWidget);
    });

    testWidgets('the rail\'s Search opens it; Ctrl+K inside closes it', (
      t,
    ) async {
      await _desktop(t);
      await t.tap(find.byKey(const Key('rail.search')));
      await _frames(t);
      expect(find.byKey(const Key('palette')), findsOneWidget);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      expect(find.byKey(const Key('palette')), findsNothing);
    });
  });

  group('the shortcut sheet (L2d1)', () {
    testWidgets('? opens it outside text fields; Esc closes it', (t) async {
      await _desktop(t);
      await _question(t);
      expect(find.byKey(const Key('shortcuts')), findsOneWidget);
      expect(
        t.getSize(find.byKey(const Key('shortcuts.box'))).width,
        DelveDesktop.shortcutSheetWidth,
      );
      expect(find.text('Ctrl+K'), findsWidgets);
      // the tools are off: no dock, no Files keys
      expect(find.text(DesktopKeys.dock), findsNothing);
      expect(find.text(DesktopKeys.rename), findsNothing);
      await _key(t, LogicalKeyboardKey.escape);
      await _frames(t, 12);
      expect(find.byKey(const Key('shortcuts')), findsNothing);
      // and ? opens it again, ? closes it
      await _question(t);
      expect(find.byKey(const Key('shortcuts')), findsOneWidget);
      await _question(t);
      await _frames(t, 12);
      expect(find.byKey(const Key('shortcuts')), findsNothing);
    });

    testWidgets('? in a text field is typed, not the sheet', (t) async {
      await _desktop(t);
      await _ctrl(t, LogicalKeyboardKey.keyF);
      await t.tap(find.byKey(const Key('chats.searchField')));
      await _frames(t, 4);
      await _question(t);
      expect(find.byKey(const Key('shortcuts')), findsNothing);
    });

    testWidgets('with the tools on: the dock and the Files keys; the '
        'palette\'s action opens it', (t) async {
      await _desktop(t, tools: true);
      await _ctrl(t, LogicalKeyboardKey.keyK);
      await t.enterText(find.byKey(const Key('palette.field')), 'keyboard');
      await _frames(t, 4);
      await t.tap(_row('action.shortcuts'));
      await _frames(t);
      expect(find.byKey(const Key('palette')), findsNothing);
      expect(find.byKey(const Key('shortcuts')), findsOneWidget);
      expect(find.text(DesktopKeys.dock), findsOneWidget);
      expect(find.text(DesktopKeys.rename), findsOneWidget);
    });
  });

  group('the rail\'s tooltip (L2d1, N437)', () {
    testWidgets('after 500 ms of hover, right of the rail with the key; '
        'gone when the pointer leaves', (t) async {
      await _desktop(t);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 450));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(find.byKey(const Key('rail.system'))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('rail.tooltip')), findsNothing);
      await t.pump(const Duration(milliseconds: 300));
      await t.pump();
      final tip = find.byKey(const Key('rail.tooltip'));
      expect(tip, findsOneWidget);
      final rail = t.getRect(find.byKey(const Key('desktop.rail')));
      final box = t.getRect(tip);
      final item = t.getRect(find.byKey(const Key('rail.system')));
      // the item sits in the middle of the rail: 8 px right of the rail
      expect(
        box.left,
        closeTo(
          item.right +
              (DelveDesktop.railWidth - DelveDesktop.railItemWidth) / 2 +
              DelveDesktop.railTooltipGap,
          0.5,
        ),
      );
      expect(box.left, greaterThan(rail.right));
      expect(box.center.dy, closeTo(item.center.dy, 0.5));
      expect(
        find.descendant(of: tip, matching: find.text('Ctrl+8')),
        findsOneWidget,
      );

      await mouse.moveTo(const Offset(700, 450));
      await t.pump();
      expect(find.byKey(const Key('rail.tooltip')), findsNothing);
    });

    testWidgets('Search sits above About me and Settings', (t) async {
      await _desktop(t);
      final search = t.getRect(find.byKey(const Key('rail.search')));
      final about = t.getRect(find.byKey(const Key('rail.about')));
      expect(search.bottom, lessThanOrEqualTo(about.top));
      expect(find.byType(DesktopShell), findsOneWidget);
    });
  });
}
