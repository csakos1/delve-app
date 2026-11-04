import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/sticky_keys.dart';
import 'package:delve/terminal/terminal_connection.dart';
import 'package:delve/terminal/terminal_lock.dart';
import 'package:delve/terminal/terminal_providers.dart';
import 'package:delve/terminal/terminal_theme.dart';
import 'package:delve/ui/screens/settings_screen.dart';
import 'package:delve/ui/screens/terminal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';
import 'support/terminal_fakes.dart';

Future<void> frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Scrolls the setup page until [f] is on screen, and lets the list come to
/// rest first (the drag leaves it gliding, so a tap right away can miss).
Future<void> reveal(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(
    f,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('terminal.setup')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await frames(t, 6);
  await t.ensureVisible(f);
  await t.pump();
}

/// Pumps the app (with the terminal set up already when [setupDone]) and
/// opens the Terminal tab.
Future<TestEnv> openTerminal(
  WidgetTester t, {
  bool setupDone = false,
  TerminalFakes? fakes,
}) async {
  final terminal = fakes ?? TerminalFakes();
  final env = await pumpDelve(
    t,
    settle: false,
    terminal: terminal,
    before: setupDone ? (_) => terminal.setUpDone() : null,
  );
  await t.tap(navItem('Terminal'));
  await frames(t);
  return env;
}

void main() {
  testWidgets('the Terminal tab sits between Chats and Dashboard', (t) async {
    await pumpDelve(t, settle: false);
    final labels = [
      for (final e in t.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      ))
        e.label,
    ];
    expect(labels, ['Chats', 'Terminal', 'Dashboard', 'More']);
  });

  testWidgets('setup shows the key line, the paired host and port 2222', (
    t,
  ) async {
    final env = await openTerminal(t);
    expect(find.byKey(const Key('terminal.setup')), findsOneWidget);
    final key = await TerminalSecrets(env.terminal.store).loadOrCreateKey();
    expect(find.text(key.authorizedKeysLine), findsOneWidget);
    final host = t.widget<TextField>(find.byKey(const Key('terminal.host')));
    expect(host.controller!.text, 'archlinux.example.ts.net');
    final port = t.widget<TextField>(find.byKey(const Key('terminal.port')));
    expect(port.controller!.text, '2222');
    final user = t.widget<TextField>(find.byKey(const Key('terminal.user')));
    expect(user.controller!.text, 'csakos');
    expect(env.terminal.dialer.opens, isEmpty);
  });

  testWidgets('connect → fingerprint in groups → trust → the session', (
    t,
  ) async {
    final env = await openTerminal(t);
    await reveal(t, find.byKey(const Key('terminal.connect')));
    await t.tap(find.byKey(const Key('terminal.connect')));
    await frames(t);

    expect(find.byKey(const Key('terminal.fingerprint')), findsOneWidget);
    expect(find.text('lNXK'), findsOneWidget);
    expect(find.text(testHostKey), findsOneWidget);

    await reveal(t, find.byKey(const Key('terminal.trust')));
    await t.tap(find.byKey(const Key('terminal.trust')));
    await frames(t);

    expect(find.byKey(const Key('terminal.setup')), findsNothing);
    expect(find.byKey(const Key('terminal.tab.delve-1')), findsOneWidget);
    expect(find.byKey(const Key('terminal.dot.live')), findsOneWidget);
    expect(find.byKey(const Key('terminal.extraKeys')), findsOneWidget);
    final open = env.terminal.dialer.opens.single;
    expect(open.host, 'archlinux.example.ts.net');
    expect(open.port, 2222);
    expect(open.user, 'csakos');
    expect(open.command, contains('tmux -u new-session -A -s delve-1'));
    final saved = await TerminalSecrets(env.terminal.store).loadConfig();
    expect(saved!.verified, isTrue);
  });

  testWidgets('a refused key shows the checks and Try again', (t) async {
    final fakes = TerminalFakes();
    fakes.dialer.failures.add(const SshAuthDenied('no more methods'));
    await openTerminal(t, fakes: fakes);
    await reveal(t, find.byKey(const Key('terminal.connect')));
    await t.tap(find.byKey(const Key('terminal.connect')));
    await frames(t);
    await reveal(t, find.byKey(const Key('terminal.trust')));
    await t.tap(find.byKey(const Key('terminal.trust')));
    await frames(t);

    expect(find.byKey(const Key('terminal.denied')), findsOneWidget);
    expect(
      find.text('Permission denied – is the line in authorized_keys?'),
      findsOneWidget,
    );
    await reveal(t, find.byKey(const Key('terminal.retry')));
    await t.tap(find.byKey(const Key('terminal.retry')));
    await frames(t);
    expect(find.byKey(const Key('terminal.tab.delve-1')), findsOneWidget);
    expect(fakes.dialer.opens, hasLength(2));
  });

  testWidgets('with setup done the tab unlocks with the fingerprint', (
    t,
  ) async {
    final env = await openTerminal(t, setupDone: true);
    expect(env.terminal.biometrics.calls, 1);
    expect(find.byKey(const Key('terminal.locked')), findsNothing);
    expect(find.byKey(const Key('terminal.dot.live')), findsOneWidget);
    expect(find.byKey(const Key('terminal.state.none')), findsOneWidget);
  });

  testWidgets('a cancelled unlock keeps the session hidden', (t) async {
    final fakes = TerminalFakes(
      biometrics: FakeBiometrics(UnlockResult.canceled),
    );
    await openTerminal(t, setupDone: true, fakes: fakes);
    expect(find.byKey(const Key('terminal.locked')), findsOneWidget);
    expect(find.byKey(const Key('terminal.extraKeys')), findsNothing);

    fakes.biometrics.result = UnlockResult.ok;
    await t.tap(find.byKey(const Key('terminal.unlock')));
    await frames(t);
    expect(find.byKey(const Key('terminal.locked')), findsNothing);
    expect(find.byKey(const Key('terminal.extraKeys')), findsOneWidget);
  });

  testWidgets('tmux asking at attach does not open the lock; a cancelled '
      'fingerprint keeps it shut (T2a phone test)', (t) async {
    final fakes = TerminalFakes(
      biometrics: FakeBiometrics(UnlockResult.canceled),
    );
    await openTerminal(t, setupDone: true, fakes: fakes);
    expect(find.byKey(const Key('terminal.locked')), findsOneWidget);
    final link = fakes.dialer.last; // connected behind the lock
    link.send('\x1b[c\x1b[>c');
    await frames(t, 4);
    expect(link.written, contains('c'), reason: 'xterm answered tmux');

    await t.tap(find.byKey(const Key('terminal.unlock')));
    await frames(t);
    expect(find.byKey(const Key('terminal.locked')), findsOneWidget);
    expect(find.byKey(const Key('terminal.extraKeys')), findsNothing);
  });

  testWidgets('airplane mode: Reconnecting at once, typed keys go nowhere, '
      'back as soon as the network is', (t) async {
    final env = await openTerminal(t, setupDone: true);
    final fakes = env.terminal;
    final first = fakes.dialer.last..alive = false;
    fakes.dialer.failures.addAll(const [
      SshUnreachable('Network is unreachable'),
      SshUnreachable('Network is unreachable'),
    ]);
    fakes.network.add(null); // airplane mode on
    await t.pump();
    await t.tap(find.byKey(const ValueKey('terminal.key.|')));
    await t.pump(const Duration(milliseconds: 70)); // > probeTimeout
    expect(
      find.byKey(const Key('terminal.state.reconnecting')),
      findsOneWidget,
    );
    expect(first.aborted, isTrue);
    expect(first.writes, isEmpty);
    expect(first.lost, isEmpty, reason: 'held, then dropped');

    final opens = fakes.dialer.opens.length;
    fakes.dialer.failures.clear();
    fakes.network.add(null); // airplane mode off
    await t.pump();
    await t.pump(const Duration(milliseconds: 5));
    expect(fakes.dialer.opens.length, opens + 1, reason: 'no backoff wait');
    await frames(t, 2);
    expect(find.byKey(const Key('terminal.state.none')), findsOneWidget);
    expect(fakes.dialer.last.writes, isEmpty);
  });

  testWidgets('a drag scrolls tmux with wheel steps (up and down)', (t) async {
    final env = await openTerminal(t, setupDone: true);
    final link = env.terminal.dialer.last;
    final view = find.byKey(const Key('terminal.scroll'));
    await t.drag(view, const Offset(0, 200));
    await frames(t, 4);
    expect(link.written, isNot(contains('\x1b[<')), reason: 'no mouse yet');

    link.send('\x1b[?1049h\x1b[?1000h\x1b[?1002h\x1b[?1006h');
    await frames(t, 2);
    await t.drag(view, const Offset(0, 200));
    await frames(t, 6);
    final up = RegExp(r'\x1b\[<64;\d+;\d+M').allMatches(link.written);
    expect(up.length, greaterThanOrEqualTo(2));
    expect(link.written, isNot(contains('\x1b[<65;')));

    await t.drag(view, const Offset(0, -200));
    await frames(t, 6);
    expect(link.written, contains('\x1b[<65;'));
  });

  group('keyboard', () {
    double rows(WidgetTester t) =>
        t.getSize(find.byKey(const Key('terminal.scroll'))).height;

    /// The bottom navigation under the body: the keyboard covers it first.
    double gap(WidgetTester t) =>
        t.view.physicalSize.height / t.view.devicePixelRatio -
        t.getBottomLeft(find.byKey(const Key('terminal.body'))).dy;

    Future<void> inset(WidgetTester t, double over) async {
      t.view.viewInsets = FakeViewPadding(
        bottom: (gap(t) + over) * t.view.devicePixelRatio,
      );
      await t.pump();
    }

    Future<void> closed(WidgetTester t) async {
      t.view.viewInsets = FakeViewPadding.zero;
      await t.pump();
    }

    testWidgets('the body is the terminal colour, not the page surface', (
      t,
    ) async {
      await openTerminal(t, setupDone: true);
      final body = t.widget<ColoredBox>(find.byKey(const Key('terminal.body')));
      expect(body.color, delveTerminalTheme.background);
    });

    testWidgets('a known keyboard: the rows jump to its end at the first '
        'frame, and back to full at the first frame of closing', (t) async {
      addTearDown(t.view.resetViewInsets);
      final fakes = TerminalFakes();
      await TerminalSecrets(
        fakes.store,
      ).saveImeHeights({'portrait': 250, 'landscape': 250});
      await openTerminal(t, setupDone: true, fakes: fakes);
      final full = rows(t);

      await inset(t, 20); // the keyboard's first frame
      expect(rows(t), closeTo(full - 250, 0.5));
      await inset(t, 150);
      expect(rows(t), closeTo(full - 250, 0.5));
      await inset(t, 250);
      await t.pump(const Duration(milliseconds: 50)); // settled
      expect(rows(t), closeTo(full - 250, 0.5));

      await inset(t, 200); // closing starts
      expect(rows(t), closeTo(full, 0.5));
      await closed(t);
      await t.pump(const Duration(milliseconds: 50));
      expect(rows(t), closeTo(full, 0.5));
    });

    testWidgets('a short trip to the home screen does not resize: the '
        'layout waits for the keyboard to come back (T2a phone test)', (
      t,
    ) async {
      addTearDown(t.view.resetViewInsets);
      final fakes = TerminalFakes();
      await TerminalSecrets(
        fakes.store,
      ).saveImeHeights({'portrait': 250, 'landscape': 250});
      await openTerminal(t, setupDone: true, fakes: fakes);
      await t.tap(find.byKey(const Key('terminal.scroll'))); // focused
      await t.pump();
      final full = rows(t);
      await inset(t, 250);
      await t.pump(const Duration(milliseconds: 50));
      expect(rows(t), closeTo(full - 250, 0.5));
      final link = fakes.dialer.last;
      final sizes = link.resizes.length;

      void life(AppLifecycleState s) =>
          t.binding.handleAppLifecycleStateChanged(s);
      life(AppLifecycleState.inactive);
      life(AppLifecycleState.hidden);
      await closed(t); // Android hides the keyboard
      await t.pump(const Duration(milliseconds: 50));
      expect(rows(t), closeTo(full - 250, 0.5), reason: 'kept while away');
      life(AppLifecycleState.inactive);
      life(AppLifecycleState.resumed);
      await t.pump();
      await inset(t, 120); // the keyboard on its way back
      await inset(t, 250);
      await t.pump(const Duration(seconds: 1));
      expect(rows(t), closeTo(full - 250, 0.5));
      expect(link.resizes.length, sizes, reason: 'no resize at all');
    });

    testWidgets('back without the keyboard: the layout follows', (t) async {
      addTearDown(t.view.resetViewInsets);
      final fakes = TerminalFakes();
      await TerminalSecrets(
        fakes.store,
      ).saveImeHeights({'portrait': 250, 'landscape': 250});
      await openTerminal(t, setupDone: true, fakes: fakes);
      final full = rows(t);
      await inset(t, 250);
      await t.pump(const Duration(milliseconds: 50));
      void life(AppLifecycleState s) =>
          t.binding.handleAppLifecycleStateChanged(s);
      life(AppLifecycleState.inactive);
      life(AppLifecycleState.hidden);
      await closed(t);
      life(AppLifecycleState.inactive);
      life(AppLifecycleState.resumed);
      await t.pump(const Duration(seconds: 1));
      expect(rows(t), closeTo(full, 0.5));
    });

    testWidgets('a keyboard not seen before is taken when it settles, and '
        'kept', (t) async {
      addTearDown(t.view.resetViewInsets);
      final env = await openTerminal(t, setupDone: true);
      final full = rows(t);
      await inset(t, 120);
      expect(rows(t), closeTo(full, 0.5));
      await t.pump(const Duration(milliseconds: 50));
      await t.pump();
      expect(rows(t), closeTo(full - 120, 0.5));
      final kept = await TerminalSecrets(env.terminal.store).loadImeHeights();
      expect(kept.values.single, closeTo(120, 0.5));
      await closed(t);
      await t.pump(const Duration(milliseconds: 50));
    });
  });

  testWidgets('a changed host key stops with the details, no retry', (t) async {
    final fakes = TerminalFakes();
    fakes.dialer.hostKey = (testHostKeyType, otherHostKey);
    await openTerminal(t, setupDone: true, fakes: fakes);

    expect(find.byKey(const Key('terminal.refused')), findsOneWidget);
    expect(find.byKey(const Key('terminal.state.refused')), findsOneWidget);
    expect(find.byKey(const Key('terminal.dot.refused')), findsOneWidget);
    await frames(t, 20);
    expect(fakes.dialer.opens, hasLength(1));

    await t.tap(find.byKey(const Key('terminal.showDetails')));
    await frames(t);
    expect(find.text(testHostKey), findsOneWidget);
    expect(find.text(otherHostKey), findsOneWidget);
    await t.tap(find.byKey(const Key('terminal.forgetVerify')));
    await frames(t);
    expect(find.byKey(const Key('terminal.fingerprint')), findsOneWidget);
  });

  testWidgets('a dropped connection shows Reconnecting, then comes back', (
    t,
  ) async {
    final env = await openTerminal(t, setupDone: true);
    final fakes = env.terminal;
    fakes.dialer.failures.add(const SshUnreachable('timed out'));
    fakes.dialer.last.end(SshEnd.connectionLost);
    await t.pump();
    await t.pump(const Duration(milliseconds: 5));
    expect(
      find.byKey(const Key('terminal.state.reconnecting')),
      findsOneWidget,
    );
    expect(find.textContaining('Reconnecting · attempt'), findsOneWidget);
    await frames(t);
    expect(find.byKey(const Key('terminal.state.none')), findsOneWidget);
    expect(fakes.dialer.opens, hasLength(3));
  });

  testWidgets('Disconnect from ⋯, then tap the line to reconnect', (t) async {
    final env = await openTerminal(t, setupDone: true);
    await t.tap(find.byKey(const Key('terminal.menu')));
    await frames(t, 8);
    await t.tap(find.text('Disconnect'));
    await frames(t);
    final c = ProviderScope.containerOf(
      t.element(find.byType(TerminalScreen)),
    ).read(terminalServiceProvider).connection;
    expect(c.phase, TermPhase.offline);
    expect(c.offlineReason, OfflineReason.user);
    expect(find.text('Disconnected – tap to reconnect'), findsOneWidget);

    await t.tap(find.byKey(const Key('terminal.state.offline')));
    await frames(t);
    expect(find.byKey(const Key('terminal.state.none')), findsOneWidget);
    expect(env.terminal.dialer.opens, hasLength(2));
  });

  testWidgets('Ctrl on the extra row: armed, then locked', (t) async {
    await openTerminal(t, setupDone: true);
    final container = ProviderScope.containerOf(
      t.element(find.byType(TerminalScreen)),
    );
    final keys = container.read(terminalServiceProvider).connection.keys;
    await t.tap(find.byKey(const ValueKey('terminal.key.Ctrl')));
    await t.pump();
    expect(keys.ctrl, StickyState.armed);
    await t.tap(find.byKey(const ValueKey('terminal.key.Ctrl')));
    await t.pump();
    expect(keys.ctrl, StickyState.locked);
  });

  testWidgets('keystrokes from the extra row reach the desktop', (t) async {
    final env = await openTerminal(t, setupDone: true);
    await t.tap(find.byKey(const ValueKey('terminal.key.Esc')));
    await t.tap(find.byKey(const ValueKey('terminal.key.|')));
    await t.pump();
    expect(env.terminal.dialer.last.written, '\x1b|');
  });

  group('settings', () {
    Future<void> openTerminalSettings(WidgetTester t) async {
      await t.tap(find.byKey(const Key('terminal.menu')));
      await frames(t, 8);
      await t.tap(find.text('Terminal settings'));
      await frames(t);
    }

    testWidgets('from More → Settings, with the port in the summary', (
      t,
    ) async {
      await pumpDelve(t, settle: false);
      await t.tap(navItem('More'));
      await frames(t);
      await t.tap(find.text('Settings'));
      await frames(t);
      final row = find.byKey(const Key('settings.terminal'));
      await t.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.text('Background connection off · port 2222'),
        findsOneWidget,
      );
      await t.ensureVisible(row);
      await t.tap(row);
      await frames(t);
      expect(find.byKey(const Key('terminalSettings.list')), findsOneWidget);
    });

    testWidgets('font size steps and is kept', (t) async {
      final env = await openTerminal(t, setupDone: true);
      await openTerminalSettings(t);
      expect(find.text('13 sp'), findsOneWidget);
      await t.tap(find.byKey(const Key('terminalSettings.fontUp')));
      await frames(t, 4);
      expect(find.text('14 sp'), findsOneWidget);
      expect(await TerminalSecrets(env.terminal.store).loadFontSize(), 14);
    });

    testWidgets('the trusted host key and Forget', (t) async {
      final env = await openTerminal(t, setupDone: true);
      await openTerminalSettings(t);
      expect(find.text('Trusted since 3 Nov 2026'), findsOneWidget);
      expect(find.text(testHostKey), findsOneWidget);
      final forget = find.byKey(const Key('terminalSettings.forget'));
      await t.scrollUntilVisible(
        forget,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('terminalSettings.list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(forget);
      await frames(t, 4);
      await t.tap(find.byKey(const Key('terminalSettings.forget.confirm')));
      await frames(t);
      expect(find.text('Not verified yet'), findsOneWidget);
      final secrets = TerminalSecrets(env.terminal.store);
      expect(await secrets.pinned('archlinux.example.ts.net:2222'), isNull);
    });

    testWidgets('host & port change in a dialog', (t) async {
      final env = await openTerminal(t, setupDone: true);
      await openTerminalSettings(t);
      await t.tap(find.byKey(const Key('terminalSettings.target')));
      await frames(t, 4);
      await t.enterText(
        find.byKey(const Key('terminalSettings.dialog.port')),
        '2200',
      );
      await t.pump();
      await t.tap(find.byKey(const Key('terminalSettings.dialog.save')));
      await frames(t);
      expect(find.byType(AlertDialog), findsNothing, reason: 'dialog closed');
      final svc = ProviderScope.containerOf(
        t.element(find.byKey(const Key('terminalSettings.list'))),
      ).read(terminalServiceProvider);
      expect(svc.config.port, 2200, reason: 'the service took the port');
      expect(find.text('csakos@archlinux.example.ts.net:2200'), findsOneWidget);
      final saved = await TerminalSecrets(env.terminal.store).loadConfig();
      expect(saved!.port, 2200);
    });
  });
}
