import 'dart:convert';

import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_connection.dart';
import 'package:delve/terminal/terminal_service.dart';
import 'package:delve/terminal/terminal_tabs.dart';
import 'package:delve/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/terminal_fakes.dart';
import 'terminal_test.dart' show settle, until;

/// A desktop with setup done, and the terminal service on the phone.
class Desk {
  Desk() : dialer = FakeSshDialer();

  final FakeSshDialer dialer;
  final store = MemorySecretStore();
  late final secrets = TerminalSecrets(store);
  final _services = <TerminalService>[];

  TerminalService service() {
    final s = TerminalService(
      secrets: secrets,
      dialer: dialer,
      biometrics: FakeBiometrics(),
      defaultHost: 'archlinux.example.ts.net',
      timing: fastTerminalTiming,
    );
    _services.add(s);
    return s;
  }

  /// Setup done, [tabs] saved (none: as before T3), the tab bar opened.
  Future<TerminalService> start({SavedTabs? tabs}) async {
    await TerminalFakes(store: store).setUpDone();
    if (tabs != null) await secrets.saveTabs(tabs);
    final s = service();
    await s.start();
    return s;
  }

  void dispose() {
    for (final s in _services) {
      s.dispose();
    }
  }
}

void main() {
  group('tab helpers', () {
    test('the session list: the name last, after `|`; the status as rows; '
        'nothing without a server', () {
      final s = parseSessions(
        '1|2|1793800000|0|on|main\n'
        '0|1|1793800060|1|off|delve-2\n'
        '0|1|1793800120|0|2|a|b\n'
        '\n',
      );
      expect(s.map((x) => x.name), ['main', 'delve-2', 'a|b']);
      expect(s[0].attached, 1);
      expect(s[0].windows, 2);
      expect(s[0].app, isFalse);
      expect(s[0].statusRows, 1);
      expect(
        s[0].created,
        DateTime.fromMillisecondsSinceEpoch(1793800000 * 1000),
      );
      expect(s[1].app, isTrue);
      expect(s[1].statusRows, 0);
      expect(s[2].statusRows, 2);
      expect(parseSessions(''), isEmpty);
      // no server: tmux says so on stderr and exits 1; the list is empty
      expect(listSessionsCommand, endsWith('2>/dev/null; true'));
      expect(listSessionsCommand, contains('#{session_name}'));
    });

    test('a new tab is delve-N with the smallest free N', () {
      expect(nextSessionName(const []), 'delve-1');
      expect(nextSessionName(const ['delve-1', 'delve-3', 'work']), 'delve-2');
    });

    test('names tmux keeps as they are (T3-0: `.`, `:` and, without a UTF-8 '
        'server, `ő` became `_`)', () {
      expect(cleanSessionName('  build '), 'build');
      expect(cleanSessionName('my-logs_2'), 'my-logs_2');
      for (final bad in [
        '',
        '   ',
        'a.b',
        'a:b',
        'a b',
        'kettő',
        '-x',
        'x' * 33,
      ]) {
        expect(cleanSessionName(bad), isNull, reason: bad);
      }
    });

    test('rename and kill name the session exactly, quoted', () {
      expect(
        renameSessionCommand("a'b", 'c'),
        "LANG=en_US.UTF-8 tmux -u rename-session -t '=a'\\''b' 'c'",
      );
      expect(
        killSessionCommand('work'),
        "LANG=en_US.UTF-8 tmux -u kill-session -t '=work'",
      );
    });

    test('saved tabs: one tab before T3; a desktop tab keeps its status '
        'line; no tabs, no active one', () {
      expect(SavedTabs.first.tabs.single, const SavedTab(session: 'delve-1'));
      const tabs = SavedTabs([
        SavedTab(session: 'delve-1'),
        SavedTab(session: 'work', app: false, statusRows: 1),
      ], 1);
      final back = SavedTabs.fromJson(
        jsonDecode(jsonEncode(tabs.toJson())) as Map<String, Object?>,
      );
      expect(back.tabs, tabs.tabs);
      expect(back.active, 1);
      expect(SavedTabs.fromJson(const {'tabs': <Object?>[]}).active, -1);
      expect(
        SavedTabs.fromJson(const {
          'tabs': [
            {'session': 'a'},
          ],
          'active': 7,
        }).active,
        0,
      );
    });

    test('wheel step, status rows and ages', () {
      expect(wheelLinesFor(app: true), 1);
      expect(wheelLinesFor(app: false), 5);
      expect(viewStatusRows(0), 0);
      expect(viewStatusRows(2), 1);
      expect(statusRowsOf('off'), 0);
      expect(statusRowsOf('on'), 1);
      expect(statusRowsOf('3'), 3);
      expect(agoText(const Duration(seconds: 30)), '< 1 min');
      expect(agoText(const Duration(minutes: 12)), '12 min');
      expect(agoText(const Duration(hours: 3, minutes: 59)), '3 h');
      expect(agoText(const Duration(days: 5, hours: 2)), '5 d');
    });
  });

  group('tabs', () {
    late Desk desk;

    setUp(() => desk = Desk());
    tearDown(() => desk.dispose());

    test('a terminal from before T3 opens its one tab, delve-1, as an app '
        'session', () async {
      final svc = await desk.start();
      await until(() => svc.connection.live);
      expect(svc.tabs.map((t) => t.session), ['delve-1']);
      expect(desk.dialer.opens.single.session, 'delve-1');
      expect(desk.dialer.opens.single.app, isTrue);
      expect(svc.connection.wheelLines, 1);
      expect(svc.connection.terminal.statusRows, 0);
    });

    test('saved tabs come back; only the active one connects', () async {
      final svc = await desk.start(
        tabs: const SavedTabs([
          SavedTab(session: 'delve-1'),
          SavedTab(session: 'work', app: false, statusRows: 1),
        ], 1),
      );
      await until(() => svc.connection.live);
      expect(svc.activeIndex, 1);
      expect(desk.dialer.opens.map((t) => t.session), ['work']);
      expect(desk.dialer.opens.single.app, isFalse);
      final work = svc.current!;
      expect(work.connection.terminal.statusRows, 1);
      expect(work.connection.wheelLines, 5);
      expect(svc.tabs.first.connection.phase, TermPhase.idle);
    });

    test('a new tab skips the names on the desktop and comes to the front; '
        'the one left stays connected for a while, then parks', () async {
      desk.dialer.tmux.sessions.add(
        FakeSession('delve-2', app: true, status: 'off'),
      );
      final svc = await desk.start();
      await until(() => svc.connection.live);
      final first = svc.current!;
      final tab = await svc.newTab();
      expect(tab.session, 'delve-3');
      expect(svc.current, tab);
      // the list went over the live tab, not a connection of its own
      expect(desk.dialer.runs, isEmpty);
      expect(desk.dialer.links.first.runs.single, contains('list-sessions'));
      await until(() => tab.connection.live);
      expect(first.connection.live, isTrue, reason: 'the previous tab');
      await until(
        () => first.connection.phase == TermPhase.offline,
        reason: 'parked after keepPrevious',
      );
      expect(first.connection.offlineReason, OfflineReason.parked);
      expect(desk.dialer.links.first.closed, isTrue);
      expect(desk.dialer.links.first.aborted, isFalse);
      final saved = await desk.secrets.loadTabs();
      expect(saved.tabs.map((t) => t.session), ['delve-1', 'delve-3']);
      expect(saved.active, 1);
    });

    test('a third tab parks the first at once; coming back connects it '
        'again', () async {
      final svc = await desk.start();
      await until(() => svc.connection.live);
      final a = svc.current!;
      final b = await svc.newTab();
      await until(() => b.connection.live);
      final c = await svc.newTab();
      await until(() => c.connection.live);
      expect(
        [a.session, b.session, c.session],
        ['delve-1', 'delve-2', 'delve-3'],
      );
      expect(a.connection.offlineReason, OfflineReason.parked);
      expect(b.connection.live, isTrue);
      final opens = desk.dialer.opens.length;
      svc.select(0);
      await until(() => a.connection.live);
      expect(desk.dialer.opens.length, opens + 1);
      expect(desk.dialer.opens.last.session, 'delve-1');
      expect(b.connection.offlineReason, OfflineReason.parked);
      expect(c.connection.live, isTrue, reason: 'the one just left');
    });

    test('a desktop session opens as it is; an open one switches to its '
        'tab', () async {
      desk.dialer.tmux.sessions.add(
        FakeSession('work', attached: 1, windows: 4),
      );
      final svc = await desk.start();
      await until(() => svc.connection.live);
      final list = await svc.listSessions();
      expect(list.single.name, 'work');
      expect(list.single.app, isFalse);
      svc.openSession(list.single);
      await until(() => svc.current!.session == 'work' && svc.connection.live);
      expect(desk.dialer.opens.last.app, isFalse);
      expect(desk.dialer.opens.last.command, isNot(contains('@delve 1')));
      expect(svc.connection.terminal.statusRows, 1);
      expect(svc.connection.wheelLines, 5);
      svc
        ..select(0)
        ..openSession(list.single);
      expect(svc.tabs.length, 2);
      expect(svc.current!.session, 'work');
    });

    test(
      'closing a tab only detaches: no kill; the next tab comes to the '
      'front; after the last one none is open, also after a restart',
      () async {
        final svc = await desk.start();
        await until(() => svc.connection.live);
        final a = svc.current!;
        final b = await svc.newTab();
        await until(() => b.connection.live);
        await svc.closeTab(b);
        expect(svc.tabs, [a]);
        expect(svc.current, a);
        expect(desk.dialer.links[1].closed, isTrue);
        expect(desk.dialer.links[1].aborted, isFalse);
        expect(
          desk.dialer.tmux.commands.where((c) => c.contains('kill')),
          isEmpty,
        );
        await until(() => a.connection.live);
        await svc.closeTab(a);
        expect(svc.current, isNull);
        expect(svc.activeIndex, -1);
        expect((await desk.secrets.loadTabs()).tabs, isEmpty);
        final again = desk.service();
        await again.start();
        expect(again.tabs, isEmpty);
        expect(again.current, isNull);
      },
    );

    test('a drag moves a tab; the active one stays active', () async {
      final svc = await desk.start();
      await until(() => svc.connection.live);
      await svc.newTab();
      await svc.newTab();
      svc.moveTab(2, 0);
      expect(svc.tabs.map((t) => t.session), ['delve-3', 'delve-1', 'delve-2']);
      expect(svc.current!.session, 'delve-3');
      expect(svc.activeIndex, 0);
      await settle(20);
      final saved = await desk.secrets.loadTabs();
      expect(saved.tabs.map((t) => t.session), [
        'delve-3',
        'delve-1',
        'delve-2',
      ]);
      expect(saved.active, 0);
    });

    test('a rename runs on the live connection; the tab and its next '
        'connect follow', () async {
      desk.dialer.tmux.sessions.add(
        FakeSession('delve-1', app: true, attached: 1),
      );
      final svc = await desk.start();
      await until(() => svc.connection.live);
      await svc.renameSession('delve-1', 'build');
      expect(
        desk.dialer.last.runs.single,
        contains("rename-session -t '=delve-1' 'build'"),
      );
      expect(svc.current!.session, 'build');
      expect(desk.dialer.tmux.byName('build'), isNotNull);
      desk.dialer.last.end(SshEnd.connectionLost);
      await until(
        () => desk.dialer.opens.length == 2 && svc.connection.live,
        reason: 'reconnected',
      );
      expect(desk.dialer.opens.last.session, 'build');
      expect((await desk.secrets.loadTabs()).tabs.single.session, 'build');
    });

    test("a kill closes the session's tab; tmux's complaint comes back as "
        'it is', () async {
      desk.dialer.tmux.sessions.addAll([
        FakeSession('delve-1', app: true),
        FakeSession('work'),
      ]);
      final svc = await desk.start();
      await until(() => svc.connection.live);
      final work = (await svc.listSessions()).firstWhere(
        (s) => s.name == 'work',
      );
      svc.openSession(work);
      await until(() => svc.current!.session == 'work' && svc.connection.live);
      await svc.killSession('work');
      expect(svc.tabs.map((t) => t.session), ['delve-1']);
      expect(desk.dialer.tmux.byName('work'), isNull);
      desk.dialer.tmux.failures.add("can't find session: gone");
      await expectLater(
        svc.killSession('gone'),
        throwsA(
          isA<TmuxCommandFailed>().having(
            (e) => e.detail,
            'detail',
            "can't find session: gone",
          ),
        ),
      );
    });

    test('with no tab connected the list uses a connection of its own that '
        'trusts only the pinned key', () async {
      final svc = await desk.start();
      await until(() => svc.connection.live);
      await svc.closeTab(svc.current!);
      desk.dialer.tmux.sessions.add(FakeSession('delve-1', app: true));
      expect((await svc.listSessions()).single.name, 'delve-1');
      expect(desk.dialer.runs.single, contains('list-sessions'));
      desk.dialer.hostKey = (testHostKeyType, otherHostKey);
      await expectLater(svc.listSessions(), throwsA(isA<SshHostKeyRejected>()));
    });

    test('the background and the network reach every connected tab', () async {
      final svc = await desk.start();
      await until(() => svc.connection.live);
      final a = svc.current!;
      final b = await svc.newTab();
      await until(() => b.connection.live);
      svc.setForeground(foreground: false);
      desk.dialer.links[0].end(SshEnd.connectionLost);
      desk.dialer.links[1].end(SshEnd.connectionLost);
      await until(
        () =>
            a.connection.phase == TermPhase.offline &&
            b.connection.phase == TermPhase.offline,
      );
      expect(b.connection.offlineReason, OfflineReason.background);
      svc.setForeground(foreground: true);
      await until(() => b.connection.live);
      final probes = desk.dialer.last.probes;
      svc.networkChanged();
      await until(() => desk.dialer.last.probes > probes);
    });
  });
}
