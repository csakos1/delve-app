import 'dart:convert';
import 'dart:io';

import 'package:delve/api/models/models.dart';
import 'package:delve/app/layout.dart';
import 'package:delve/app/platform.dart';
import 'package:delve/app/router.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/theme/delve_theme.dart';
import 'package:delve/ui/desktop/areas.dart';
import 'package:delve/ui/desktop/chat_inspector.dart';
import 'package:delve/ui/desktop/chats_area.dart';
import 'package:delve/ui/desktop/desktop_shell.dart';
import 'package:delve/ui/desktop/panes.dart';
import 'package:delve/ui/desktop/status_bar.dart';
import 'package:delve/ui/screens/archived_chats_screen.dart';
import 'package:delve/ui/screens/chat_screen.dart';
import 'package:delve/ui/screens/chats_screen.dart';
import 'package:delve/ui/screens/dashboard_screen.dart';
import 'package:delve/ui/screens/system_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_screen_test.dart' show seedFinished;
import 'support/harness.dart';

final _linux = PlatformCaps.linux(host: 'archlinux');
const _frame = Size(1440, 900);

Future<void> _ctrl(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pumpAndSettle();
}

/// [DesktopPanes] alone in a window of [width] × 900.
Future<void> _panes(
  WidgetTester t,
  double width, {
  bool inspector = true,
}) async {
  setWindowSize(t, Size(width, 900));
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: delveDesktopTheme(buildDelveTheme()),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DesktopPanes(
            area: 'test',
            list: const Text('list'),
            content: const Column(
              children: [
                PaneHeader(title: 'Content', inspectorToggle: true),
                Expanded(child: Text('content')),
              ],
            ),
            inspector: inspector
                ? const Column(
                    children: [InspectorOverlayClose(), Text('inspector')],
                  )
                : null,
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

double _width(WidgetTester t, String key) =>
    t.getSize(find.byKey(Key(key))).width;

void main() {
  group('desktop tokens (L2a)', () {
    final tokens =
        jsonDecode(
              File(
                'test/fixtures/design/delve_desktop_tokens.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    Map<String, Object?> obj(Object? v) => v! as Map<String, Object?>;
    double n(Object? v) => (v! as num).toDouble();

    test('match the design', () {
      final window = obj(tokens['window']);
      final bp = obj(tokens['breakpoints']);
      final panes = obj(tokens['panes']);
      final list = obj(panes['list']);
      final content = obj(panes['content']);
      final inspector = obj(panes['inspector']);
      final rail = obj(tokens['rail']);
      final item = obj(rail['item']);
      final density = obj(tokens['density']);
      final values = <String, (double, double)>{
        'window.minWidth': (DelveDesktop.windowMinWidth, n(window['minWidth'])),
        'window.minHeight': (
          DelveDesktop.windowMinHeight,
          n(window['minHeight']),
        ),
        'listOverlayBelow': (
          DelveDesktop.listOverlayBelow,
          n(bp['listOverlayBelow']),
        ),
        'inspectorOverlayBelow': (
          DelveDesktop.inspectorOverlayBelow,
          n(bp['inspectorOverlayBelow']),
        ),
        'listNarrowBelow': (
          DelveDesktop.listNarrowBelow,
          n(bp['listNarrowBelow']),
        ),
        'statusBarDropRunBelow': (
          DelveDesktop.statusBarDropRunBelow,
          n(bp['statusBarDropRunBelow']),
        ),
        'wide': (DelveDesktop.wide, n(bp['wide'])),
        'rail': (DelveDesktop.railWidth, n(obj(panes['rail'])['width'])),
        'list.min': (DelveDesktop.listMin, n(list['min'])),
        'list.default': (DelveDesktop.listDefault, n(list['default'])),
        'list.defaultNews': (
          DelveDesktop.listDefaultNews,
          n(list['defaultNews']),
        ),
        'list.max': (DelveDesktop.listMax, n(list['max'])),
        'content.min': (DelveDesktop.contentMin, n(content['min'])),
        'readingColumn': (
          DelveDesktop.readingColumn,
          n(content['readingColumn']),
        ),
        'inspector.min': (DelveDesktop.inspectorMin, n(inspector['min'])),
        'inspector.default': (
          DelveDesktop.inspectorDefault,
          n(inspector['default']),
        ),
        'inspector.max': (DelveDesktop.inspectorMax, n(inspector['max'])),
        'header': (DelveDesktop.paneHeader, n(panes['header'])),
        'dividerGrab': (DelveDesktop.dividerGrab, n(panes['dividerGrab'])),
        'statusBar': (
          DelveDesktop.statusBarHeight,
          n(obj(tokens['statusBar'])['height']),
        ),
        'rail.item.width': (DelveDesktop.railItemWidth, n(item['width'])),
        'rail.item.height': (DelveDesktop.railItemHeight, n(item['height'])),
        'rail.item.radius': (DelveDesktop.railItemRadius, n(item['radius'])),
        'rail.markSlot': (DelveDesktop.railMarkSlot, n(rail['markSlot'])),
        'button.height': (
          DelveDesktop.buttonHeight,
          n(obj(density['button'])['height']),
        ),
        'iconButton.size': (
          DelveDesktop.iconButton,
          n(obj(density['iconButton'])['size']),
        ),
        'rowTwoLine': (DelveDesktop.rowTwoLine, n(density['rowTwoLine'])),
      };
      for (final MapEntry(:key, :value) in values.entries) {
        expect(value.$1, value.$2, reason: key);
      }
      expect(
        DelveDesktop.dividerHoverDelay.inMilliseconds,
        n(panes['dividerHoverDelayMs']),
      );
    });

    test('window classes and the list width', () {
      expect(DelveDesktop.classOf(719), DelveWindowClass.phone);
      expect(DelveDesktop.classOf(800), DelveWindowClass.compact);
      expect(DelveDesktop.classOf(960), DelveWindowClass.medium);
      expect(DelveDesktop.classOf(1270), DelveWindowClass.half);
      expect(DelveDesktop.classOf(1440), DelveWindowClass.regular);
      expect(DelveDesktop.classOf(2560), DelveWindowClass.wide);
      // half a 2560 monitor: 52 + 240 + 638 + 340
      expect(
        DelveDesktop.listWidth(1270, remembered: 300, inspectorDocked: true),
        240,
      );
      expect(
        DelveDesktop.listWidth(1270, remembered: 300, inspectorDocked: false),
        300,
      );
      expect(
        DelveDesktop.listWidth(1440, remembered: 300, inspectorDocked: true),
        300,
      );
      // wider than the room leaves: the content keeps 600
      expect(
        DelveDesktop.listWidth(1400, remembered: 420, inspectorDocked: true),
        1400 - 52 - 340 - 600,
      );
    });
  });

  group('layout and places (L2a)', () {
    test('the desktop layout: a computer from 720 dp', () {
      expect(desktopLayoutFor(_linux, 720), isTrue);
      expect(desktopLayoutFor(_linux, 719), isFalse);
      expect(desktopLayoutFor(PlatformCaps.android, 2000), isFalse);
    });

    test('places across the two routers', () {
      expect(desktopLocation(Routes.more), Routes.dashboard);
      expect(desktopLocation(Routes.mirroring), Routes.dashboard);
      expect(desktopLocation(Routes.share), Routes.chats);
      expect(desktopLocation(Routes.system), Routes.system);
      expect(desktopLocation(Routes.chat('a b')), Routes.chat('a b'));
      expect(phoneLocation(newChatLocation('general')), Routes.newChat);
      expect(phoneLocation(Routes.newsStory(4)), Routes.newsStory(4));
    });

    test('areas of locations', () {
      expect(DesktopArea.of(Routes.chats), DesktopArea.chats);
      expect(DesktopArea.of(Routes.chat('x')), DesktopArea.chats);
      expect(DesktopArea.of(Routes.archived), DesktopArea.chats);
      expect(DesktopArea.of(Routes.approvals), DesktopArea.approvals);
      expect(DesktopArea.of(Routes.newsStory(3)), DesktopArea.news);
      expect(DesktopArea.of(Routes.newsWeekly), DesktopArea.news);
      expect(DesktopArea.of(Routes.connectionLog), DesktopArea.settings);
      expect(DesktopArea.of(Routes.filePreview), DesktopArea.files);
      expect(DesktopArea.of(Routes.clipboard), isNull);
      expect(DesktopArea.ofDigit('4'), DesktopArea.dashboard);
      expect(DesktopArea.ofDigit('1'), isNull); // the Inbox: L2e
    });

    test('the selected chat of a location', () {
      expect(selectedChat(Routes.chats), isNull);
      expect(selectedChat(Routes.chat('a/b')), 'c:a/b');
      expect(selectedChat(Routes.generalChat('g1')), 'g:g1');
      expect(selectedChat(newChatLocation('agent')), 'new');
      expect(selectedChat(Routes.approvals), isNull);
    });

    test('status bar texts', () {
      expect(clockText(const Duration(minutes: 4, seconds: 5)), '4:05');
      expect(clockText(const Duration(seconds: -3)), '0:00');
      const gpus = [
        GpuInfo(
          index: 0,
          name: '4070S',
          tempC: 51.6,
          memUsedMib: 10240,
          memTotalMib: 12288,
        ),
        GpuInfo(
          index: 1,
          name: '3060',
          tempC: 44,
          memUsedMib: 11264,
          memTotalMib: 12288,
        ),
        GpuInfo(index: 2, name: '3050'),
      ];
      expect(vramText(gpus), '21.0 / 24.0 GB');
      expect(hottestText(gpus), '52 °C');
      expect(vramText(null), isNull);
      expect(hottestText(const []), isNull);
    });
  });

  group('panes (L2a)', () {
    testWidgets('1440: list 300, content, inspector 340; one toggle', (
      t,
    ) async {
      await _panes(t, 1440);
      expect(_width(t, 'pane.list'), 300);
      expect(_width(t, 'pane.inspector'), 340);
      expect(_width(t, 'pane.content'), 1440 - 640);
      // a docked inspector has no close button of its own
      expect(find.byKey(const Key('pane.inspector.close')), findsNothing);
      await t.tap(find.byKey(const Key('pane.inspector.toggle')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pane.inspector')), findsNothing);
      expect(_width(t, 'pane.content'), 1440 - 300);
      await t.tap(find.byKey(const Key('pane.inspector.toggle')));
      await t.pumpAndSettle();
      expect(_width(t, 'pane.inspector'), 340);
    });

    testWidgets('1270: the list narrows to 240 while the inspector is open', (
      t,
    ) async {
      await _panes(t, 1270);
      expect(_width(t, 'pane.list'), 240);
      expect(_width(t, 'pane.content'), 1270 - 240 - 340);
    });

    testWidgets('1000: the inspector is an overlay with its own close', (
      t,
    ) async {
      await _panes(t, 1000);
      expect(find.byKey(const Key('pane.inspector')), findsNothing);
      expect(_width(t, 'pane.content'), 700);
      await t.tap(find.byKey(const Key('pane.inspector.toggle')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pane.inspector.overlay')), findsOneWidget);
      await t.tap(find.byKey(const Key('pane.inspector.close')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pane.inspector.overlay')), findsNothing);
    });

    testWidgets('800: the list is an overlay; a click beside it closes it', (
      t,
    ) async {
      await _panes(t, 800);
      expect(find.byKey(const Key('pane.list')), findsNothing);
      expect(find.byKey(const Key('pane.list.overlay')), findsOneWidget);
      await t.tapAt(const Offset(700, 450));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pane.list.overlay')), findsNothing);
      expect(_width(t, 'pane.content'), 800);
    });

    testWidgets('a page without an inspector has no toggle', (t) async {
      await _panes(t, 1440, inspector: false);
      expect(find.byKey(const Key('pane.inspector.toggle')), findsNothing);
      expect(_width(t, 'pane.content'), 1440 - 300);
    });

    testWidgets('the list edge drags and resets on a double click', (t) async {
      await _panes(t, 1440);
      final divider = find.byKey(const Key('pane.list.divider'));
      await t.drag(divider, const Offset(60, 0));
      await t.pumpAndSettle();
      expect(_width(t, 'pane.list'), closeTo(360, 1));
      await t.drag(divider, const Offset(400, 0));
      await t.pumpAndSettle();
      expect(_width(t, 'pane.list'), DelveDesktop.listMax);
      await t.tap(divider);
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(divider);
      await t.pumpAndSettle();
      expect(_width(t, 'pane.list'), 300);
    });
  });

  group('the desktop app (L2a)', () {
    testWidgets('Linux at 1440: rail, status bar, Chats with its list; no '
        'bottom navigation, no Terminal or Files', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame);
      expect(find.byType(DesktopShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byKey(const Key('desktop.rail')), findsOneWidget);
      expect(find.byKey(const Key('desktop.statusBar')), findsOneWidget);
      expect(find.byKey(const Key('rail.chats')), findsOneWidget);
      expect(find.byKey(const Key('rail.terminal')), findsNothing);
      expect(find.byKey(const Key('rail.files')), findsNothing);
      expect(find.byType(ChatsScreen), findsOneWidget);
      expect(find.byType(ChatsPlaceholder), findsOneWidget);
      // the desktop list: New chat in the header, Archived at the foot, no
      // FAB and no Approvals button (the rail has it)
      expect(find.byKey(const Key('chats.new')), findsOneWidget);
      expect(find.byKey(const Key('chats.archived')), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('chats.approvals')), findsNothing);
      expect(find.byKey(const Key('status.connection')), findsOneWidget);
    });

    testWidgets('the phone stays the phone in any window', (t) async {
      await pumpDelve(t, window: _frame);
      expect(find.byType(DesktopShell), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('area keys and the rail; an area page has no back arrow', (
      t,
    ) async {
      await pumpDelve(t, caps: _linux, window: _frame);
      await _ctrl(t, LogicalKeyboardKey.digit4);
      expect(find.byType(DashboardScreen), findsOneWidget);
      // Terminal is off: Ctrl+9 does nothing
      await _ctrl(t, LogicalKeyboardKey.digit9);
      expect(find.byType(DashboardScreen), findsOneWidget);

      await t.tap(find.byKey(const Key('rail.system')));
      await t.pumpAndSettle();
      expect(find.byType(SystemScreen), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      await _ctrl(t, LogicalKeyboardKey.digit2);
      expect(find.byType(ChatsPlaceholder), findsOneWidget);
    });

    testWidgets('Ctrl+N opens a new agent chat in the content; Archived', (
      t,
    ) async {
      await pumpDelve(t, caps: _linux, window: _frame);
      await _ctrl(t, LogicalKeyboardKey.keyN);
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(ChatsScreen), findsOneWidget); // the list stays
      expect(find.byType(BackButton), findsNothing);

      await t.tap(find.byKey(const Key('chats.archived')));
      await t.pumpAndSettle();
      expect(find.byType(ArchivedChatsScreen), findsOneWidget);
      expect(find.byKey(const Key('rail.chats')), findsOneWidget);
    });

    testWidgets('a resize across 720 swaps the layouts and keeps the place', (
      t,
    ) async {
      await pumpDelve(t, caps: _linux, window: _frame);
      await _ctrl(t, LogicalKeyboardKey.digit4);
      expect(find.byType(DashboardScreen), findsOneWidget);

      setWindowSize(t, const Size(600, 900));
      await t.pumpAndSettle();
      expect(find.byType(DesktopShell), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);

      setWindowSize(t, _frame);
      await t.pumpAndSettle();
      expect(find.byType(DesktopShell), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Linux in a narrow window keeps the phone layout', (t) async {
      await pumpDelve(t, caps: _linux);
      expect(find.byType(DesktopShell), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('Chats on the desktop (L2b)', () {
    testWidgets('desktop rows; a chat opens with its inspector: Run, then '
        'Usage from the tab and from Ctrl+U', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
      final row = find.byKey(const Key('chats.row'));
      expect(row, findsOneWidget);
      expect(t.getSize(row).height, greaterThanOrEqualTo(52));

      // hover: Archive and the menu at the row's top right
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(row));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chats.row.archive')), findsOneWidget);
      expect(find.byKey(const Key('row.more')), findsOneWidget);
      await mouse.moveTo(const Offset(1400, 880));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chats.row.archive')), findsNothing);

      // right click: the context menu
      await t.tap(
        row,
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chats.menu.archive')), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();

      await t.tap(row);
      await t.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byKey(const Key('readingColumn')), findsOneWidget);
      expect(
        t.getSize(find.byKey(const Key('chat.topBar'))).height,
        DelveDesktop.paneHeader,
      );
      expect(find.byKey(const Key('inspector.chat')), findsOneWidget);
      expect(find.byKey(const Key('inspector.run.line')), findsOneWidget);
      expect(find.byKey(const Key('pane.inspector.toggle')), findsOneWidget);
      // docked: no close button of its own
      expect(find.byKey(const Key('pane.inspector.close')), findsNothing);

      await t.tap(find.byKey(const Key('inspector.tab.usage')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('usage.inspector')), findsOneWidget);

      await _ctrl(t, LogicalKeyboardKey.bracketRight);
      expect(find.byKey(const Key('inspector.run')), findsOneWidget);
      await _ctrl(t, LogicalKeyboardKey.keyU);
      expect(find.byKey(const Key('usage.inspector')), findsOneWidget);

      // Ctrl+I closes it, the toggle opens it again
      await _ctrl(t, LogicalKeyboardKey.keyI);
      expect(find.byKey(const Key('inspector.chat')), findsNothing);
      await t.tap(find.byKey(const Key('pane.inspector.toggle')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('inspector.chat')), findsOneWidget);
    });

    testWidgets('Ctrl+F opens the list search', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
      expect(find.byKey(const Key('chats.searchField')), findsNothing);
      await _ctrl(t, LogicalKeyboardKey.keyF);
      expect(find.byKey(const Key('chats.searchField')), findsOneWidget);
    });

    testWidgets('the pane header is 48 on the desktop', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame);
      await _ctrl(t, LogicalKeyboardKey.digit4);
      expect(
        t.getSize(find.byKey(const Key('page.header'))).height,
        DelveDesktop.paneHeader,
      );
    });

    test('the inspector\'s tabs cycle', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(chatInspectorTabProvider), ChatInspectorTab.run);
      c.read(chatInspectorTabProvider.notifier).next();
      expect(c.read(chatInspectorTabProvider), ChatInspectorTab.usage);
      c.read(chatInspectorTabProvider.notifier).next();
      expect(c.read(chatInspectorTabProvider), ChatInspectorTab.run);
    });
  });
}
