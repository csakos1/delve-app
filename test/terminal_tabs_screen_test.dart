import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/terminal_connection.dart';
import 'package:delve/terminal/terminal_providers.dart';
import 'package:delve/terminal/terminal_service.dart';
import 'package:delve/terminal/terminal_tabs.dart';
import 'package:delve/ui/screens/terminal_screen.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/terminal_fakes.dart';
import 'terminal_screen_test.dart' show frames, openTerminal;

TerminalService service(WidgetTester t) => ProviderScope.containerOf(
  t.element(find.byType(TerminalScreen)),
).read(terminalServiceProvider);

Finder tab(String name) => find.byKey(ValueKey('terminal.tab.$name'));

/// Setup done, these tabs saved, the Terminal tab open.
Future<TerminalFakes> openWithTabs(
  WidgetTester t, {
  SavedTabs? tabs,
  List<FakeSession> sessions = const [],
}) async {
  final fakes = TerminalFakes();
  fakes.dialer.tmux.sessions.addAll(sessions);
  if (tabs != null) await TerminalSecrets(fakes.store).saveTabs(tabs);
  await openTerminal(t, setupDone: true, fakes: fakes);
  return fakes;
}

void main() {
  testWidgets('the saved tabs show; a tap brings one to the front and '
      'connects it', (t) async {
    final fakes = await openWithTabs(
      t,
      tabs: const SavedTabs([
        SavedTab(session: 'delve-1'),
        SavedTab(session: 'journal', app: false, statusRows: 1),
      ], 0),
    );
    expect(tab('delve-1'), findsOneWidget);
    expect(tab('journal'), findsOneWidget);
    expect(fakes.dialer.opens.map((o) => o.session), ['delve-1']);
    expect(
      find.descendant(
        of: tab('delve-1'),
        matching: find.byKey(const Key('terminal.tab.underline')),
      ),
      findsOneWidget,
    );

    await t.tap(tab('journal'));
    await t.pump();
    // the one left stays live for a while (fast timings: 150 ms), then parks
    expect(service(t).tabs.first.connection.live, isTrue);
    await frames(t);
    expect(fakes.dialer.opens.map((o) => o.session), ['delve-1', 'journal']);
    expect(fakes.dialer.opens.last.app, isFalse);
    expect(service(t).current!.session, 'journal');
    expect(
      find.descendant(
        of: tab('journal'),
        matching: find.byKey(const Key('terminal.tab.underline')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('terminal.extraKeys')), findsOneWidget);
    expect(
      service(t).tabs.first.connection.offlineReason,
      OfflineReason.parked,
    );
  });

  testWidgets('+ opens a new app session in a new tab, skipping the names '
      'on the desktop', (t) async {
    final fakes = await openWithTabs(
      t,
      sessions: [FakeSession('delve-2', app: true, status: 'off')],
    );
    await t.tap(find.byKey(const Key('terminal.newTab')));
    await frames(t);
    expect(tab('delve-3'), findsOneWidget);
    expect(service(t).current!.session, 'delve-3');
    expect(fakes.dialer.opens.last.session, 'delve-3');
    expect(fakes.dialer.opens.last.command, contains('history-limit 10000'));
  });

  testWidgets('⋯ → sessions: the tab tag, where each is attached, Open as '
      'tab', (t) async {
    final fakes = await openWithTabs(
      t,
      sessions: [
        FakeSession('delve-1', app: true, attached: 1, status: 'off'),
        FakeSession('main', attached: 1, windows: 4),
        FakeSession('music'),
      ],
    );
    await t.tap(find.byKey(const Key('terminal.menu')));
    await frames(t, 6);
    await t.tap(find.byKey(const Key('terminal.menu.sessions')));
    await frames(t);

    expect(find.byKey(const Key('terminal.sessions')), findsOneWidget);
    expect(find.text('Sessions on archlinux'), findsOneWidget);
    expect(find.text('tmux · 3 sessions · 1 open here'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('terminal.session.delve-1.tag')),
      findsOneWidget,
    );
    expect(find.text('Attached here'), findsOneWidget);
    expect(find.text('Attached on the desktop'), findsOneWidget);
    expect(find.text('Detached'), findsOneWidget);
    expect(find.textContaining('4 windows · created'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('terminal.session.delve-1.open')),
      findsNothing,
    );

    await t.tap(find.byKey(const ValueKey('terminal.session.main.open')));
    await frames(t);
    expect(find.byKey(const Key('terminal.sessions')), findsNothing);
    expect(tab('main'), findsOneWidget);
    expect(service(t).current!.session, 'main');
    expect(fakes.dialer.opens.last.app, isFalse);
    expect(service(t).connection.terminal.statusRows, 1);
  });

  testWidgets('a kill from the sessions sheet asks first, then the session '
      'is gone', (t) async {
    final fakes = await openWithTabs(
      t,
      sessions: [
        FakeSession('delve-1', app: true, attached: 1, status: 'off'),
        FakeSession('music'),
      ],
    );
    await t.tap(find.byKey(const Key('terminal.menu')));
    await frames(t, 6);
    await t.tap(find.byKey(const Key('terminal.menu.sessions')));
    await frames(t);
    await t.tap(find.byKey(const ValueKey('terminal.session.music.menu')));
    await frames(t, 6);
    await t.tap(find.byKey(const Key('terminal.sessionMenu.kill')));
    await frames(t, 6);
    expect(find.byKey(const Key('terminal.kill.dialog')), findsOneWidget);
    expect(find.text('Kill “music”?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await frames(t, 6);
    expect(fakes.dialer.tmux.byName('music'), isNotNull);

    await t.tap(find.byKey(const ValueKey('terminal.session.music.menu')));
    await frames(t, 6);
    await t.tap(find.byKey(const Key('terminal.sessionMenu.kill')));
    await frames(t, 6);
    await t.tap(find.byKey(const Key('terminal.kill.confirm')));
    await frames(t);
    expect(fakes.dialer.tmux.byName('music'), isNull);
    expect(find.byKey(const ValueKey('terminal.session.music')), findsNothing);
    expect(find.text('tmux · 1 session · 1 open here'), findsOneWidget);
  });

  testWidgets('a long press on a tab: its menu; Rename checks the name, '
      'the tab follows', (t) async {
    final fakes = await openWithTabs(
      t,
      sessions: [FakeSession('delve-1', app: true, attached: 1)],
    );
    await t.longPress(tab('delve-1'));
    await frames(t);
    // the tooltip line heads the menu
    expect(find.textContaining('delve-1 · connected · '), findsOneWidget);
    expect(find.byKey(const Key('terminal.tabMenu.rename')), findsOneWidget);
    await t.tap(find.byKey(const Key('terminal.tabMenu.rename')));
    await frames(t, 6);
    expect(find.byKey(const Key('terminal.rename.dialog')), findsOneWidget);

    await t.enterText(find.byKey(const Key('terminal.rename.field')), 'a.b');
    await t.pump();
    expect(
      find.text('Only letters, digits, - and _ (up to 32)'),
      findsOneWidget,
    );
    final save = find.byKey(const Key('terminal.rename.save'));
    expect(t.widget<FilledButton>(save).onPressed, isNull);

    await t.enterText(find.byKey(const Key('terminal.rename.field')), 'build');
    await t.pump();
    await t.tap(save);
    await frames(t);
    expect(tab('build'), findsOneWidget);
    expect(tab('delve-1'), findsNothing);
    expect(fakes.dialer.tmux.byName('build'), isNotNull);
  });

  testWidgets('Close tab only detaches; after the last one the empty state '
      'offers a new session', (t) async {
    final fakes = await openWithTabs(t);
    await t.longPress(tab('delve-1'));
    await frames(t);
    await t.tap(find.byKey(const Key('terminal.tabMenu.close')));
    await frames(t);
    expect(tab('delve-1'), findsNothing);
    expect(find.byKey(const Key('terminal.noTabs')), findsOneWidget);
    expect(fakes.dialer.links.single.closed, isTrue);
    expect(
      fakes.dialer.tmux.commands.where((c) => c.contains('kill')),
      isEmpty,
    );

    await t.tap(find.byKey(const Key('terminal.noTabs.new')));
    await frames(t);
    expect(tab('delve-1'), findsOneWidget);
    expect(find.byKey(const Key('terminal.noTabs')), findsNothing);
    expect(fakes.dialer.opens.last.session, 'delve-1');
    expect(service(t).connection.live, isTrue);
  });

  testWidgets('a long press and a drag moves the tab', (t) async {
    await openWithTabs(
      t,
      tabs: const SavedTabs([
        SavedTab(session: 'delve-1'),
        SavedTab(session: 'delve-2'),
        SavedTab(session: 'delve-3'),
      ], 0),
    );
    // The list moves a dragged item past the next one when the item's far
    // edge is in that one's second half: held at its centre, the tab ends
    // a quarter of a tab left of delve-3's centre, its edge past it.
    final from = t.getCenter(tab('delve-1'));
    final last = t.getRect(tab('delve-3'));
    final to = last.center - Offset(last.width / 4, 0);
    final g = await t.startGesture(from);
    await t.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset((to.dx - from.dx) / steps, 0));
      await t.pump();
    }
    await t.pump(const Duration(milliseconds: 300));
    await g.up();
    await frames(t);
    expect(service(t).tabs.map((x) => x.session), [
      'delve-2',
      'delve-3',
      'delve-1',
    ]);
    expect(service(t).current!.session, 'delve-1');
    expect(find.byKey(const Key('terminal.tabMenu.close')), findsNothing);
  });
}
