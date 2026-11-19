import 'dart:convert';
import 'dart:io';

import 'package:delve/api/models/models.dart';
import 'package:delve/app/layout.dart';
import 'package:delve/app/platform.dart';
import 'package:delve/app/router.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/general/general_database.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/theme/delve_theme.dart';
import 'package:delve/ui/chat/chat_items.dart' show UserBubble;
import 'package:delve/ui/desktop/areas.dart';
import 'package:delve/ui/desktop/chat_find.dart';
import 'package:delve/ui/desktop/chat_inspector.dart';
import 'package:delve/ui/desktop/chats_area.dart';
import 'package:delve/ui/desktop/desktop_shell.dart';
import 'package:delve/ui/desktop/intake.dart';
import 'package:delve/ui/desktop/panes.dart';
import 'package:delve/ui/desktop/status_bar.dart';
import 'package:delve/ui/screens/archived_chats_screen.dart';
import 'package:delve/ui/screens/chat_screen.dart';
import 'package:delve/ui/screens/chats_screen.dart';
import 'package:delve/ui/screens/dashboard_screen.dart';
import 'package:delve/ui/screens/system_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attachments_test.dart'
    show FakeAttachmentApi, FakePicker, FakePrep, file, photo, png;
import 'chat_screen_test.dart'
    show FakeChatActions, conversation, liveStatus, seedFinished, seedRunning;
import 'support/fake_openrouter.dart' show testOpenRouterKey;
import 'support/fake_server.dart' show FakeReply;
import 'support/harness.dart';

final _linux = PlatformCaps.linux(host: 'archlinux');
const _frame = Size(1440, 900);

Future<void> _ctrl(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pumpAndSettle();
}

/// Ctrl+[key] without settling (a running run's clock never settles).
Future<void> _ctrlNow(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// What the desktop_drop plugin sends while files are dragged.
Future<void> _dropEvent(WidgetTester t, String method, Object? args) async {
  await t.binding.defaultBinaryMessenger.handlePlatformMessage(
    'desktop_drop',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
    (_) {},
  );
  await t.pump();
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

      // Archived is the list's filter (L2b2): the new chat stays open
      await t.tap(find.byKey(const Key('chats.archived')));
      await t.pumpAndSettle();
      expect(find.byType(ArchivedChatsScreen), findsNothing);
      expect(find.byKey(const Key('chats.desktopEmpty')), findsOneWidget);
      expect(find.byType(ChatScreen), findsOneWidget);
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

  testWidgets('archiving from the list: one snackbar, in the list column', (
    t,
  ) async {
    await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
    final row = find.byKey(const Key('chats.row'));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(row));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chats.row.archive')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    final bar = find.byType(SnackBar);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('pane.list')), matching: bar),
      findsOneWidget,
    );
  });

  group('composer and chat on the desktop (L2b2)', () {
    test('what the clipboard offers', () {
      expect(pasteImageType(['image/png']), 'image/png');
      expect(pasteImageType(['text/html', 'image/jpeg']), 'image/jpeg');
      expect(pasteImageType(['image/x-foo']), 'image/x-foo');
      // a spreadsheet's cells come with a picture: the text wins
      expect(pasteImageType(['text/plain;charset=utf-8', 'image/png']), isNull);
      expect(pasteImageType(['UTF8_STRING', 'image/png']), isNull);
      expect(pasteImageType(const <String>[]), isNull);
      expect(
        filePathsOfUriList(
          'file:///home/a/x.png\r\n# copied\nhttps://e.com/y\n'
          'file:///tmp/a%20b.txt\n',
        ),
        ['/home/a/x.png', '/tmp/a b.txt'],
      );
    });

    test('a paste and a path as attachments', () {
      final image = pickedOfPaste(
        PasteImage(png, 'image/png'),
        now: DateTime(2026, 11, 19, 16, 5, 9),
      )!.single;
      expect((image.kind, image.name), ('image', 'pasted-160509.png'));
      expect(pickedOfPaste(const PasteText()), isNull);

      final dir = Directory.systemTemp.createTempSync('delve_drop');
      addTearDown(() => dir.deleteSync(recursive: true));
      final notes = File('${dir.path}/notes.txt')..writeAsStringSync('hi');
      final p = pickedFromPath(notes.path)!;
      expect(
        (p.kind, p.name, p.mime, p.size),
        ('file', 'notes.txt', 'text/plain', 2),
      );
      expect(pickedFromPath('${dir.path}/IMG_2.PNG'), isNull); // not there
      File('${dir.path}/IMG_2.PNG').writeAsBytesSync(png);
      expect(pickedFromPath('${dir.path}/IMG_2.PNG')!.kind, 'image');
      expect(pickedFromPath(dir.path), isNull); // a folder
      expect(
        pickedOfPaste(PasteFiles([notes.path, dir.path]))!.map((p) => p.name),
        ['notes.txt'],
      );
    });

    late FakeChatActions actions;
    late FakeAttachmentApi api;
    late FakePicker picker;
    setUp(() {
      actions = FakeChatActions();
      api = FakeAttachmentApi();
      picker = FakePicker();
    });

    /// The app at 1440 × 900, connected, with the finished chat open.
    Future<TestEnv> start(WidgetTester t) async {
      final env = await pumpDelve(
        t,
        caps: _linux,
        window: _frame,
        actions: actions,
        status: liveStatus,
        attachments: AttachmentFakes(
          api: api,
          picker: picker,
          prep: FakePrep(),
        ),
        before: (env) async {
          actions.db = env.db;
          await seedFinished(env);
        },
      );
      await t.tap(find.byKey(const Key('chats.row')));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('Ctrl+V in the composer attaches an image; text still '
        'pastes', (t) async {
      final env = await start(t);
      await t.tap(find.byKey(const Key('composer.field')));
      await t.pump();
      env.pasteboard.next = PasteImage(png, 'image/png');
      await _ctrl(t, LogicalKeyboardKey.keyV);
      expect(env.pasteboard.reads, 1);
      expect(find.textContaining('pasted-'), findsOneWidget);
      expect(api.uploads.single.$1, 'image');

      // text: the field pastes it as before
      final messenger = t.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => switch (call.method) {
          'Clipboard.getData' => <String, Object?>{
            'text': 'from the clipboard',
          },
          'Clipboard.hasStrings' => <String, Object?>{'value': true},
          _ => null,
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      env.pasteboard.next = const PasteText();
      await _ctrl(t, LogicalKeyboardKey.keyV);
      expect(env.pasteboard.reads, 2);
      expect(find.text('from the clipboard'), findsOneWidget);
      expect(api.uploads, hasLength(1));
    });

    testWidgets('Ctrl+O and + open the file dialog at once (no sheet)', (
      t,
    ) async {
      await start(t);
      picker.next = [file('notes.txt')];
      await _ctrl(t, LogicalKeyboardKey.keyO);
      expect(picker.asked, ['files 4']);
      expect(find.text('notes.txt'), findsOneWidget);

      picker.next = [photo('IMG_3.PNG')];
      await t.tap(find.byKey(const Key('composer.add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('attach.photos')), findsNothing);
      expect(picker.asked, ['files 4', 'files 3']);
      expect(find.text('IMG_3.jpg'), findsOneWidget);
    });

    testWidgets('files dragged over the chat: the frame; dropped: attached, '
        'a folder skipped', (t) async {
      await start(t);
      final dir = Directory.systemTemp.createTempSync('delve_drop');
      addTearDown(() => dir.deleteSync(recursive: true));
      final note = File('${dir.path}/note.txt')..writeAsStringSync('x');
      final at = t.getCenter(find.byKey(const Key('chat.list')));

      await _dropEvent(t, 'entered', [at.dx, at.dy]);
      expect(find.byKey(const Key('chat.drop')), findsOneWidget);
      expect(find.text('Drop to attach'), findsOneWidget);
      await _dropEvent(t, 'exited', null);
      expect(find.byKey(const Key('chat.drop')), findsNothing);

      await _dropEvent(t, 'entered', [at.dx, at.dy]);
      await _dropEvent(t, 'performOperation', [note.path, dir.path]);
      expect(find.byKey(const Key('chat.drop')), findsNothing);
      expect(find.text('note.txt'), findsOneWidget);
      // the file is read for real
      for (var i = 0; i < 20 && api.uploads.isEmpty; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump();
      }
      expect(api.uploads, [('file', 'note.txt', 'text/plain', 1)]);
    });

    testWidgets('right click on a message and a step; Show in inspector pins '
        'the run, Latest run lets go', (t) async {
      await start(t);
      await t.tap(
        find.descendant(
          of: find.byType(UserBubble),
          matching: find.text('Check the kernel'),
        ),
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('msg.menu.copy')), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();

      // the inspector follows the newest run (the failed one: no steps)
      expect(find.byKey(const Key('inspector.run.output')), findsNothing);
      await t.tap(
        find.byKey(const ValueKey('step.1')),
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('step.menu.copyCommand')), findsOneWidget);
      expect(find.byKey(const Key('step.menu.copyOutput')), findsOneWidget);
      await t.tap(find.byKey(const Key('step.menu.inspect')));
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('inspector.run.output')),
          matching: find.textContaining('7.2.11'),
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('inspector.run.latest')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('inspector.run.latest')), findsNothing);
      expect(find.byKey(const Key('inspector.run.output')), findsNothing);
    });

    testWidgets('Ctrl+T switches Thinking, Ctrl+. stops the run', (t) async {
      await pumpDelve(
        t,
        caps: _linux,
        window: _frame,
        actions: actions,
        status: liveStatus,
        settle: false,
        before: (env) async {
          actions.db = env.db;
          await seedRunning(env);
        },
      );
      await t.tap(find.byKey(const Key('chats.row')));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await _ctrlNow(t, LogicalKeyboardKey.keyT);
      expect(actions.calls, contains('thinking c_1 true'));
      await _ctrlNow(t, LogicalKeyboardKey.period);
      expect(actions.calls, contains('stop run_c'));
    });

    testWidgets('the phone: no drop zone, no chat keys', (t) async {
      final env = await pumpDelve(
        t,
        actions: actions,
        status: liveStatus,
        attachments: AttachmentFakes(
          api: api,
          picker: picker,
          prep: FakePrep(),
        ),
        before: (env) async {
          actions.db = env.db;
          await seedFinished(env);
        },
      );
      await t.tap(find.text('Kernel check'));
      await t.pumpAndSettle();
      expect(find.byType(DesktopDropZone), findsOneWidget);
      expect(find.byKey(const Key('chat.drop')), findsNothing);
      // + still asks Photos / Camera / File
      await t.tap(find.byKey(const Key('composer.add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('attach.photos')), findsOneWidget);
      expect(env.pasteboard.reads, 0);
    });
  });

  group('fixes and the list and General on the desktop (L2b2b)', () {
    test('an area opens where it was left; Chats keeps its chat', () {
      final places = DesktopPlaces();
      expect(places.target(DesktopArea.chats, Routes.dashboard), Routes.chats);
      places
        ..remember(Routes.chat('c_1'))
        ..remember(Routes.connectionLog)
        ..remember(Routes.dashboard);
      expect(
        places.target(DesktopArea.chats, Routes.dashboard),
        Routes.chat('c_1'),
      );
      expect(
        places.target(DesktopArea.settings, Routes.dashboard),
        Routes.connectionLog,
      );
      // from inside an area: its first page; Chats stays where it is
      expect(
        places.target(DesktopArea.settings, Routes.connectionLog),
        Routes.settings,
      );
      expect(
        places.target(DesktopArea.chats, Routes.chat('c_1')),
        Routes.chat('c_1'),
      );
    });

    test('find: the matches newest first, Enter older, Shift+Enter newer', () {
      expect(findMatches('kernel', ['Check the Kernel', 'ok', 'kernel 7']), [
        2,
        0,
      ]);
      expect(findMatches('  ', ['x']), isEmpty);
      final f = ChatFind()..search('k');
      addTearDown(f.dispose);
      expect(f.position(3), 0);
      f.older(3);
      expect(f.position(3), 1);
      f
        ..newer(3)
        ..newer(3);
      expect(f.position(3), 2); // wraps
    });

    testWidgets('back on Chats, the chat left open is open again', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
      await t.tap(find.byKey(const Key('chats.row')));
      await t.pumpAndSettle();
      await _ctrl(t, LogicalKeyboardKey.digit4);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await t.tap(find.byKey(const Key('rail.chats')));
      await t.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(ChatsPlaceholder), findsNothing);
      await _ctrl(t, LogicalKeyboardKey.digit4);
      await _ctrl(t, LogicalKeyboardKey.digit2);
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('the rail mark has air above and below; the composer is as '
        'high as its content, its buttons on the bottom line', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
      final mark = t.getRect(find.byKey(const Key('rail.mark')));
      final first = t.getRect(find.byKey(const Key('rail.chats')));
      expect(mark.top, DelveDesktop.railMarkTop);
      expect(first.top - mark.bottom, greaterThanOrEqualTo(12));

      await t.tap(find.byKey(const Key('chats.row')));
      await t.pumpAndSettle();
      final add = t.getRect(find.byKey(const Key('composer.add')));
      final send = t.getRect(find.byKey(const Key('composer.send')));
      final field = t.getRect(find.byKey(const Key('composer.field')));
      expect(add.bottom, moreOrLessEquals(send.bottom, epsilon: 0.5));
      // field, buttons and a little padding: no empty half any more
      expect(send.bottom - field.top, lessThan(DelveTokens.composerMin - 10));
    });

    testWidgets('J / K open the next / previous chat, E archives the open '
        'one, Ctrl+Z brings it back', (t) async {
      final env = await pumpDelve(
        t,
        caps: _linux,
        window: _frame,
        before: (env) async {
          await seedFinished(env);
          await env.db.putConversation(
            Conversation.fromJson({
              ...conversation('c_2', title: 'Older chat').toJson(),
              'updated_at': DateTime.utc(2020).toIso8601String(),
            }),
          );
        },
      );
      env.server.on(
        'PATCH',
        '/api/v1/conversations/c_1',
        (r) => FakeReply(200, {
          ...conversation('c_1').toJson(),
          'archived': (r.data as Map<String, Object?>)['archived'],
        }),
      );
      List<Object?> patches() => [
        for (final r in env.server.requests)
          if (r.method == 'PATCH') r.data,
      ];
      String? open() => find.byType(ChatScreen).evaluate().isEmpty
          ? null
          : t.widget<ChatScreen>(find.byType(ChatScreen)).conversationId;
      Future<void> key(LogicalKeyboardKey k) async {
        await t.sendKeyEvent(k);
        await t.pumpAndSettle();
      }

      await key(LogicalKeyboardKey.keyJ);
      expect(open(), 'c_1');
      await key(LogicalKeyboardKey.arrowDown);
      expect(open(), 'c_2');
      await key(LogicalKeyboardKey.keyK);
      expect(open(), 'c_1');

      await key(LogicalKeyboardKey.keyE);
      expect(patches(), [
        {'archived': true},
      ]);
      expect(open(), 'c_2'); // the next row took its place
      expect(find.text('Kernel check'), findsNothing);

      await _ctrl(t, LogicalKeyboardKey.keyZ);
      expect(patches(), [
        {'archived': true},
        {'archived': false},
      ]);
      expect(find.text('Kernel check'), findsWidgets);
    });

    testWidgets('Archived is the list filter: Unarchive on hover; a General '
        'chat is deleted after the dialog', (t) async {
      final now = DateTime.now().toUtc();
      await pumpDelve(
        t,
        caps: _linux,
        window: _frame,
        generalKey: testOpenRouterKey,
        before: (env) async {
          final db = env.general;
          await db
              .into(db.generalChats)
              .insert(
                GeneralChatsCompanion.insert(
                  id: 'g_1',
                  modelId: 'z-ai/glm-5.3',
                  createdAt: now,
                  updatedAt: now,
                  title: const Value('Dog names'),
                  archived: const Value(true),
                ),
              );
        },
      );
      expect(find.text('Dog names'), findsNothing);
      await t.tap(find.byKey(const Key('chats.archived')));
      await t.pumpAndSettle();
      expect(find.text('Archived chats'), findsWidgets);
      final row = find.byKey(const Key('chats.row.general'));
      expect(row, findsOneWidget);

      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(row));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chats.row.unarchive')), findsOneWidget);
      await t.tap(find.byKey(const Key('chats.row.delete')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('desktop.confirm')), findsOneWidget);
      await t.tap(find.byKey(const Key('desktop.confirm.cancel')));
      await t.pumpAndSettle();
      expect(row, findsOneWidget);

      // the dialog covered the row: a move brings the hover back
      await mouse.moveTo(t.getCenter(row) + const Offset(2, 0));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('chats.row.delete')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('desktop.confirm.ok')));
      await t.pumpAndSettle();
      expect(row, findsNothing);
      expect(find.byKey(const Key('chats.desktopEmpty')), findsOneWidget);

      // back to the list, once the “Chat deleted” snackbar (over the foot
      // row) has gone
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await t.tap(find.byKey(const Key('chats.archived')));
      await t.pumpAndSettle();
      expect(find.text('Chats'), findsWidgets);
    });

    testWidgets('Ctrl+F in an open chat: the bar, the count, Enter to the '
        'older match, Esc closes', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
      await t.tap(find.byKey(const Key('chats.row')));
      await t.pumpAndSettle();
      await _ctrl(t, LogicalKeyboardKey.keyF);
      expect(find.byKey(const Key('chat.findBar')), findsOneWidget);
      // the list's search stays closed: the chat searches itself
      expect(find.byKey(const Key('chats.searchField')), findsNothing);

      await t.enterText(find.byKey(const Key('chat.findField')), 'kernel');
      await t.pumpAndSettle();
      // “Check the kernel” and “**Kernel** 7.2.11 …”
      expect(find.text('1 / 2'), findsOneWidget);
      final current = find.byWidgetPredicate((w) => w is FindMark && w.current);
      expect(current, findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(
        find.descendant(of: current, matching: find.byType(UserBubble)),
        findsOneWidget,
      );

      await t.enterText(find.byKey(const Key('chat.findField')), 'nothing');
      await t.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chat.findBar')), findsNothing);
    });

    testWidgets('a General chat has the Usage inspector; its model picker is '
        'a popover', (t) async {
      final now = DateTime.now().toUtc();
      await pumpDelve(
        t,
        caps: _linux,
        window: _frame,
        generalKey: testOpenRouterKey,
        before: (env) async {
          final db = env.general;
          await db
              .into(db.generalChats)
              .insert(
                GeneralChatsCompanion.insert(
                  id: 'g_1',
                  modelId: 'z-ai/glm-5.3',
                  createdAt: now,
                  updatedAt: now,
                  title: const Value('Dog names'),
                ),
              );
        },
      );
      await t.tap(find.byKey(const Key('chats.row.general')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('inspector.general')), findsOneWidget);
      expect(find.byKey(const Key('generalUsage.inspector')), findsOneWidget);
      expect(find.byKey(const Key('pane.inspector.toggle')), findsOneWidget);

      await t.tap(find.byKey(const Key('general.modelChip')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('desktop.popover')), findsOneWidget);
      expect(find.byKey(const Key('picker')), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('desktop.popover')), findsNothing);
    });

    testWidgets('a new chat: a draft row on top, two kind cells, the '
        'composer has the focus', (t) async {
      await pumpDelve(t, caps: _linux, window: _frame, before: seedFinished);
      await _ctrl(t, LogicalKeyboardKey.keyN);
      expect(find.byKey(const Key('chats.row.draft')), findsOneWidget);
      expect(find.byKey(const Key('newChat.kind.agent')), findsOneWidget);
      expect(find.byKey(const Key('newChat.kind.general')), findsOneWidget);
      final field = t.widget<TextField>(
        find.byKey(const Key('composer.field')),
      );
      expect(field.focusNode!.hasFocus, isTrue);
    });
  });
}
