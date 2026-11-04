import 'dart:convert';
import 'dart:typed_data';

import 'package:delve/terminal/phone_key.dart';
import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/sticky_keys.dart';
import 'package:delve/terminal/terminal_connection.dart';
import 'package:delve/terminal/terminal_lock.dart';
import 'package:delve/terminal/terminal_service.dart';
import 'package:delve/terminal/terminal_theme.dart';
import 'package:delve/terminal/terminal_wheel.dart';
import 'package:delve/terminal/tmux_terminal.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

import 'support/terminal_fakes.dart';

/// Seed 0x00…0x1f; the line comes from Python's `cryptography` (OpenSSH
/// encoding of the same ed25519 key).
final seed = Uint8List.fromList(List.generate(32, (i) => i));
const seedLine =
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOhB7/zzhC+HXDdGOdLwJln5NYwm6UNXx3chmQSVTG4';

const target = SshTarget(
  host: 'archlinux.example.ts.net',
  port: 2222,
  user: 'csakos',
  session: 'delve-1',
);

Future<void> until(bool Function() ok, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!ok()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting${reason == null ? '' : ': $reason'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

Future<void> settle([int ms = 120]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

class Rig {
  Rig({FakeSshDialer? dialer, TerminalTiming timing = fastTerminalTiming})
    : dialer = dialer ?? FakeSshDialer(),
      store = MemorySecretStore() {
    secrets = TerminalSecrets(store);
    connection = TerminalConnection(
      dialer: this.dialer,
      secrets: secrets,
      timing: timing,
      onLive: () => lives++,
      onInput: () => inputs++,
    );
  }

  final FakeSshDialer dialer;
  final MemorySecretStore store;
  late final TerminalSecrets secrets;
  late final TerminalConnection connection;
  final key = PhoneKey.fromSeed(seed);
  int lives = 0;
  int inputs = 0;

  Future<void> pinTestKey([String fp = testHostKey]) => secrets.pin(
    target.hostPort,
    PinnedHostKey(type: testHostKeyType, fingerprint: fp),
  );

  /// Pinned and connected once: a live session.
  Future<FakeSshLink> live() async {
    await pinTestKey();
    connection.connect(target, key, afterSetup: true);
    await until(() => connection.phase == TermPhase.live, reason: 'live');
    return dialer.last;
  }

  void dispose() => connection.dispose();
}

void main() {
  group('phone key', () {
    test('the public line matches OpenSSH for a known seed', () {
      final key = PhoneKey.fromSeed(seed);
      expect(key.publicLine, '$seedLine delve-phone');
      expect(
        key.authorizedKeysLine,
        'from="100.64.0.0/10",no-agent-forwarding,no-X11-forwarding,'
        'no-port-forwarding $seedLine delve-phone',
      );
      expect(key.installCommand, contains("'${key.authorizedKeysLine}'"));
      expect(key.installCommand, startsWith('mkdir -p ~/.ssh && chmod 700'));
      expect(key.installCommand, endsWith('chmod 600 ~/.ssh/authorized_keys'));
    });

    test('a seed must be 32 bytes', () {
      expect(() => PhoneKey.fromSeed(Uint8List(31)), throwsArgumentError);
    });

    test('fingerprint groups of four, the last one shorter', () {
      final groups = fingerprintGroups(testHostKey);
      expect(groups.length, 11);
      expect(groups.first, 'lNXK');
      expect(groups.last, 'n0g');
      expect(groups.join(), testHostKey.substring('SHA256:'.length));
      expect(hostKeyTypeLabel('ssh-ed25519'), 'ED25519');
    });

    test('the tmux command attaches with a UTF-8 locale', () {
      expect(
        target.command,
        'env LANG=en_US.UTF-8 tmux -u new-session -A -s delve-1',
      );
      expect(SshTarget.quoteSession("a b'c"), "'a bc'");
    });
  });

  group('secrets', () {
    test('the key is made once and kept', () async {
      final store = MemorySecretStore();
      final a = await TerminalSecrets(store).loadOrCreateKey();
      final b = await TerminalSecrets(store).loadOrCreateKey();
      expect(b.publicLine, a.publicLine);
      expect(base64.decode(store.values[TerminalSecrets.keyKey]!), a.seed);
    });

    test('an unreadable key is replaced; regenerate makes a new one', () async {
      final store = MemorySecretStore({TerminalSecrets.keyKey: 'not base64!'});
      final secrets = TerminalSecrets(store);
      final a = await secrets.loadOrCreateKey();
      final b = await secrets.regenerateKey();
      expect(b.publicLine, isNot(a.publicLine));
      expect((await secrets.loadOrCreateKey()).publicLine, b.publicLine);
    });

    test('pins, settings and the font size survive a restart', () async {
      final store = MemorySecretStore();
      final s1 = TerminalSecrets(store);
      await s1.pin(
        'h:2222',
        PinnedHostKey(
          type: testHostKeyType,
          fingerprint: testHostKey,
          trustedAt: DateTime.utc(2026, 11, 3),
        ),
      );
      await s1.saveConfig(const TerminalConfig(host: 'h', verified: true));
      await s1.saveFontSize(15);

      final s2 = TerminalSecrets(store);
      final pin = await s2.pinned('h:2222');
      expect(pin!.matches(testHostKeyType, testHostKey), isTrue);
      expect(pin.trustedAt, DateTime.utc(2026, 11, 3));
      expect(await s2.pinned('h:22'), isNull);
      final config = await s2.loadConfig();
      expect(config, const TerminalConfig(host: 'h', verified: true));
      expect(config!.port, kTerminalPort);
      expect(config.user, kTerminalUser);
      expect(await s2.loadFontSize(), 15);

      await s2.forget('h:2222');
      expect(await s2.pinned('h:2222'), isNull);
    });
  });

  group('sticky modifiers', () {
    late List<String> out;
    late StickyModifiers keys;
    late Terminal term;

    setUp(() {
      out = [];
      keys = StickyModifiers();
      term = Terminal(inputHandler: keys)..onOutput = out.add;
    });

    tearDown(() => keys.dispose());

    test('off → armed → locked → off', () {
      expect(StickyModifiers.next(StickyState.off), StickyState.armed);
      expect(StickyModifiers.next(StickyState.armed), StickyState.locked);
      expect(StickyModifiers.next(StickyState.locked), StickyState.off);
    });

    test('armed Ctrl applies to one key, then clears', () {
      keys.tapCtrl();
      expect(keys.ctrl, StickyState.armed);
      term.keyInput(TerminalKey.keyC);
      expect(out, ['\x03']);
      expect(keys.ctrl, StickyState.off);
      term.keyInput(TerminalKey.keyC);
      expect(out.skip(1), isNot(contains('\x03')));
    });

    test('locked Ctrl stays until tapped again', () {
      keys
        ..tapCtrl()
        ..tapCtrl();
      expect(keys.ctrl, StickyState.locked);
      term
        ..keyInput(TerminalKey.keyA)
        ..keyInput(TerminalKey.keyE);
      expect(out, ['\x01', '\x05']);
      expect(keys.ctrl, StickyState.locked);
      keys.tapCtrl();
      expect(keys.ctrl, StickyState.off);
    });

    test('a key of the row clears an armed Alt', () {
      keys.tapAlt();
      keys.consumed();
      expect(keys.alt, StickyState.off);
    });
  });

  test('the terminal palette is the design token block', () {
    const t = delveTerminalTheme;
    expect(t.background, const Color(0xFF0C0D0E));
    expect(t.foreground, const Color(0xFFD9DCE0));
    expect(t.cursor, const Color(0xFF5FD4EA));
    expect(t.selection, const Color(0x405FD4EA));
    expect(t.brightYellow, const Color(0xFFE9DC94));
    expect(delveTerminalStyle(13).height, kTerminalLineHeight);
  });

  group('connection', () {
    late Rig rig;
    setUp(() => rig = Rig());
    tearDown(() => rig.dispose());

    test('a new host key waits for the user, then is pinned', () async {
      final c = rig.connection;
      c.connect(target, rig.key);
      await until(() => c.phase == TermPhase.verifying);
      expect(c.question!.fingerprint, testHostKey);
      expect(rig.dialer.links, isEmpty);

      c.answerHostKey(trust: true);
      await until(() => c.phase == TermPhase.live);
      expect(rig.lives, 1);
      final pin = await rig.secrets.pinned(target.hostPort);
      expect(pin!.fingerprint, testHostKey);
      expect(pin.trustedAt, isNotNull);
      expect(rig.dialer.opens.single.session, 'delve-1');
    });

    test('a declined key goes back to setup, nothing pinned', () async {
      final c = rig.connection;
      c.connect(target, rig.key);
      await until(() => c.phase == TermPhase.verifying);
      c.answerHostKey(trust: false);
      await until(() => c.phase == TermPhase.idle);
      expect(c.detail, isNotNull);
      expect(await rig.secrets.pinned(target.hostPort), isNull);
    });

    test('output reaches the screen, keystrokes reach the desktop', () async {
      final link = await rig.live();
      link.send('hello from tmux\r\n');
      await until(
        () => rig.connection.terminal.buffer.getText().contains('hello'),
      );
      rig.connection.terminal.textInput('ls');
      expect(link.written, 'ls');
      expect(rig.inputs, 1);
    });

    test('keystrokes while not connected are dropped', () async {
      final link = await rig.live();
      await rig.connection.disconnect();
      expect(rig.connection.phase, TermPhase.offline);
      expect(rig.connection.offlineReason, OfflineReason.user);
      rig.connection.terminal.textInput('x');
      expect(link.writes, isEmpty);
      expect(link.closed, isTrue);
    });

    test('a changed host key is refused, without retrying', () async {
      await rig.pinTestKey(otherHostKey);
      final c = rig.connection..connect(target, rig.key, afterSetup: true);
      await until(() => c.phase == TermPhase.refused);
      expect(c.refusedKey!.fingerprint, testHostKey);
      expect(c.refusedPinned!.fingerprint, otherHostKey);
      await settle();
      expect(rig.dialer.opens, hasLength(1));

      await c.forgetAndVerify();
      await until(() => c.phase == TermPhase.verifying);
      expect(c.refusedKey, isNull);
    });

    test('a refused key is denied, without retrying', () async {
      await rig.pinTestKey();
      rig.dialer.failures.add(const SshAuthDenied('no more methods'));
      final c = rig.connection..connect(target, rig.key, afterSetup: true);
      await until(() => c.phase == TermPhase.denied);
      await settle();
      expect(rig.dialer.opens, hasLength(1));
    });

    test(
      'during setup an unreachable desktop fails without retrying',
      () async {
        await rig.pinTestKey();
        rig.dialer.failures.add(const SshUnreachable('Connection refused'));
        final c = rig.connection..connect(target, rig.key);
        await until(() => c.phase == TermPhase.failed);
        expect(c.detail, 'Connection refused');
        await settle();
        expect(rig.dialer.opens, hasLength(1));
      },
    );

    test('a dropped connection comes back to the same session', () async {
      final first = await rig.live();
      first.end(SshEnd.connectionLost);
      await until(() => rig.dialer.links.length == 2);
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.connection.attempt, 0);
      expect(rig.dialer.opens.map((t) => t.session), ['delve-1', 'delve-1']);
      expect(rig.lives, 2);
    });

    test('reconnects back off while the desktop is unreachable', () async {
      final first = await rig.live();
      rig.dialer.failures.addAll(const [
        SshUnreachable('timed out'),
        SshUnreachable('timed out'),
      ]);
      first.end(SshEnd.connectionLost);
      await until(() => rig.connection.attempt >= 2);
      expect(rig.connection.phase, TermPhase.reconnecting);
      expect(rig.connection.retryAt, isNotNull);
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.opens, hasLength(4));
    });

    test('a session that ended is not reopened by itself', () async {
      final link = await rig.live();
      link.end(SshEnd.sessionEnded);
      await until(() => rig.connection.phase == TermPhase.offline);
      expect(rig.connection.offlineReason, OfflineReason.sessionEnded);
      await settle();
      expect(rig.dialer.opens, hasLength(1));

      rig.connection.retryNow();
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.opens, hasLength(2));
    });

    test('in the background a drop waits for the app to come back', () async {
      final link = await rig.live();
      rig.connection.setForeground(foreground: false);
      link.end(SshEnd.connectionLost);
      await until(() => rig.connection.phase == TermPhase.offline);
      expect(rig.connection.offlineReason, OfflineReason.background);
      await settle();
      expect(rig.dialer.opens, hasLength(1));

      rig.connection.setForeground(foreground: true);
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.opens, hasLength(2));
    });

    test('after a long background the session is opened fresh', () async {
      final first = await rig.live();
      rig.connection.setForeground(foreground: false);
      await settle(250); // longer than staleAfter
      rig.connection.setForeground(foreground: true);
      await until(() => rig.dialer.links.length == 2);
      await until(() => rig.connection.phase == TermPhase.live);
      expect(first.closed, isTrue);
    });

    test('a short background keeps the connection', () async {
      final first = await rig.live();
      rig.connection
        ..setForeground(foreground: false)
        ..setForeground(foreground: true);
      await settle();
      expect(rig.dialer.links, [first]);
      expect(rig.connection.phase, TermPhase.live);
    });

    test('the first new size goes to the pty at once, the last one too, '
        'not every one between', () async {
      final link = await rig.live();
      final t = rig.connection.terminal;
      t.resize(56, 40);
      expect(link.resizes, [(56, 40)], reason: 'at once, not after a wait');
      for (var rows = 39; rows > 30; rows--) {
        t.resize(56, rows);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await settle(100);
      expect(link.resizes.first, (56, 40));
      expect(link.resizes.last, (56, 31));
      expect(link.resizes.length, lessThan(5));
    });

    test('a size changed while away is sent on the next connect', () async {
      final first = await rig.live();
      rig.connection.setForeground(foreground: false);
      first.end(SshEnd.connectionLost);
      await until(() => rig.connection.phase == TermPhase.offline);
      rig.connection.terminal.resize(56, 49);
      await settle(60);
      rig.connection.setForeground(foreground: true);
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.last.resizes, [(56, 49)]);
    });
  });

  group('a dead network (airplane mode)', () {
    late Rig rig;

    setUp(() => rig = Rig());
    tearDown(() => rig.dispose());

    test('a network change checks the connection; no answer → it is '
        'dropped and a new one opened', () async {
      final first = await rig.live();
      first.alive = false;
      rig.connection.networkChanged();
      expect(rig.connection.holding, isTrue);
      // typed while the check is open: held, and dropped with the link
      rig.connection.terminal.textInput('rm -rf build\r');
      await until(() => first.aborted, reason: 'aborted');
      expect(first.writes, isEmpty);
      expect(first.lost, isEmpty, reason: 'never even written');
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.links, hasLength(2));
      expect(rig.dialer.last.writes, isEmpty, reason: 'not replayed later');
    });

    test('typed keys without an echo trigger the check at once', () async {
      final first = await rig.live();
      first.alive = false;
      rig.connection.terminal.textInput('l');
      await settle(70); // > echoWait: holding, checking
      expect(rig.connection.holding, isTrue);
      rig.connection.terminal.textInput('s\r');
      await until(() => first.aborted, reason: 'aborted');
      expect(first.lost, ['l'], reason: 'only the key before the check');
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.last.writes, isEmpty);
    });

    test('a silent but alive desktop gets the held keys after the '
        'answer', () async {
      final link = await rig.live(); // no echo, like a password prompt
      link.answerAfter = const Duration(milliseconds: 40);
      rig.connection.terminal.textInput('a');
      await settle(70); // echoWait 50 → checking until ~90
      expect(rig.connection.holding, isTrue);
      rig.connection.terminal.textInput('b');
      expect(link.written, 'a', reason: 'b is held');
      await until(() => link.written == 'ab', reason: 'b released');
      expect(rig.connection.phase, TermPhase.live);
      expect(rig.connection.holding, isFalse);
      expect(rig.dialer.links, [link]);
    });

    test('an echoing desktop is not checked on every key', () async {
      final link = await rig.live();
      link.echo = true;
      rig.connection.terminal.textInput('ls');
      await settle(70);
      expect(link.probes, 0);
      expect(rig.connection.holding, isFalse);
    });

    test('a quiet live connection is checked regularly', () async {
      final first = await rig.live();
      first.alive = false;
      await until(() => first.aborted, reason: 'periodic probe');
      await until(() => rig.connection.phase == TermPhase.live);
      expect(rig.dialer.links, hasLength(2));
    });

    test('the network coming back retries at once, not after the '
        'backoff', () async {
      final slow = Rig(
        timing: const TerminalTiming(
          backoff: [Duration(seconds: 20)],
          resizeSettle: Duration(milliseconds: 30),
          probeEvery: Duration(seconds: 20),
          probeTimeout: Duration(milliseconds: 60),
          echoWait: Duration(milliseconds: 50),
        ),
      );
      addTearDown(slow.dispose);
      final first = await slow.live();
      slow.dialer.failures.add(const SshUnreachable('Network is unreachable'));
      first.end(SshEnd.connectionLost);
      await until(() => slow.connection.attempt == 2, reason: 'backing off');
      expect(slow.connection.phase, TermPhase.reconnecting);
      expect(slow.dialer.opens, hasLength(2));
      slow.connection.networkChanged();
      await until(() => slow.connection.phase == TermPhase.live);
      expect(slow.dialer.opens, hasLength(3));
    });

    test('back from a short background: checked, dropped when dead', () async {
      final first = await rig.live();
      rig.connection.setForeground(foreground: false);
      first.alive = false;
      rig.connection.setForeground(foreground: true);
      await until(() => first.aborted);
      await until(() => rig.connection.phase == TermPhase.live);
    });
  });

  group('resizing like tmux', () {
    /// A 20×10 alternate screen: pane lines 0–8, tmux's status line last,
    /// the cursor on the given pane row.
    TmuxTerminal screen({int cursorRow = 8, int lines = 9}) {
      final t = TmuxTerminal()..resize(20, 10);
      t.write('\x1b[?1049h');
      for (var i = 0; i < lines; i++) {
        t.write('\x1b[${i + 1};1Hline$i');
      }
      t.write('\x1b[10;1Hstatus\x1b[${cursorRow + 1};7H');
      return t;
    }

    String row(Terminal t, int i) =>
        t.buffer.lines[t.buffer.scrollBack + i].getText().trim();

    test('a smaller screen keeps the status line and drops lines at the '
        'top (T2a: one-line jump when the keyboard opened)', () {
      final t = screen()..resize(20, 7);
      expect(
        [for (var i = 0; i < 7; i++) row(t, i)],
        ['line3', 'line4', 'line5', 'line6', 'line7', 'line8', 'status'],
      );
      expect(t.buffer.cursorY, 5);
      expect(t.buffer.cursorX, 6);
    });

    test('keyboard open and closed again: the same screen comes back at '
        'once (T2a: the top lines vanished for a moment)', () {
      final t = screen()..resize(20, 7);
      t.resize(20, 10);
      expect(
        [for (var i = 0; i < 10; i++) row(t, i)],
        [for (var i = 0; i < 9; i++) 'line$i', 'status'],
      );
      expect(t.buffer.cursorY, 8);
      expect(t.historyLength, 0);
    });

    test('lines scrolled out by output come back at the top; rows tmux has '
        'no history for are blank above the status line', () {
      final t = screen();
      // tmux scrolls the pane in a region above the status line
      t.write('\x1b[1;9r\x1b[9;1H\nline9');
      expect(row(t, 0), 'line1');
      expect(t.historyLength, 1);
      t.resize(20, 12);
      expect(row(t, 0), 'line0');
      expect(row(t, 1), 'line1');
      expect(row(t, 9), 'line9');
      expect(row(t, 10), '');
      expect(row(t, 11), 'status');
      expect(t.buffer.cursorY, 9);
    });

    test('lines below the cursor go first', () {
      final t = screen(cursorRow: 2, lines: 3)..resize(20, 7);
      expect(row(t, 0), 'line0');
      expect(row(t, 2), 'line2');
      expect(row(t, 6), 'status');
      expect(t.buffer.cursorY, 2);
    });

    test('the main screen is left to xterm', () {
      final t = TmuxTerminal()..resize(20, 10);
      for (var i = 0; i < 10; i++) {
        t.write('\x1b[${i + 1};1Hline$i');
      }
      t.write('\x1b[5;1H');
      final plain = Terminal()..resize(20, 10);
      for (var i = 0; i < 10; i++) {
        plain.write('\x1b[${i + 1};1Hline$i');
      }
      plain.write('\x1b[5;1H');
      t.resize(20, 6);
      plain.resize(20, 6);
      expect(
        [for (var i = 0; i < 6; i++) row(t, i)],
        [for (var i = 0; i < 6; i++) row(plain, i)],
      );
    });
  });

  group('touch scrolling', () {
    test('wheel reports: SGR with buttons 64/65, nothing without mouse', () {
      final t = Terminal();
      expect(wheelReport(t, up: true, column: 0, row: 0), isNull);
      t.write('\x1b[?1000h');
      expect(
        wheelReport(t, up: true, column: 2, row: 3),
        '\x1b[M${String.fromCharCode(96)}${String.fromCharCode(35)}'
        '${String.fromCharCode(36)}',
      );
      t.write('\x1b[?1006h');
      expect(wheelReport(t, up: true, column: 2, row: 3), '\x1b[<64;3;4M');
      expect(wheelReport(t, up: false, column: 0, row: 0), '\x1b[<65;1;1M');
    });

    test('finger movement becomes whole steps, the rest carries over', () {
      final steps = WheelSteps(10);
      expect(steps.add(4), 0);
      expect(steps.add(7), 1);
      expect(steps.add(25), 2);
      expect(steps.add(-6), 0);
      expect(steps.add(-20), -2);
    });

    test(
      'a wheel step reaches tmux only when it asked for the mouse',
      () async {
        final rig = Rig();
        addTearDown(rig.dispose);
        final link = await rig.live();
        expect(rig.connection.wheel(up: true, column: 1, row: 1), isFalse);
        link.send('\x1b[?1049h\x1b[?1000h\x1b[?1006h');
        await until(() => rig.connection.terminal.mouseMode.reportScroll);
        expect(rig.connection.wheel(up: true, column: 1, row: 1), isTrue);
        expect(link.written, '\x1b[<64;2;2M');
      },
    );
  });

  group('lock', () {
    test('input keeps an open terminal open but never opens a locked one', () {
      var now = DateTime.utc(2026, 11, 3, 20);
      final lock = TerminalLock(now: () => now)..keepAlive();
      expect(lock.locked, isTrue);
      lock.touch();
      now = now.add(const Duration(minutes: 10));
      lock.keepAlive();
      now = now.add(const Duration(minutes: 10));
      expect(lock.locked, isFalse, reason: 'kept alive at 10 min');
      now = now.add(const Duration(minutes: 6));
      expect(lock.locked, isTrue);
      lock.keepAlive();
      expect(lock.locked, isTrue);
    });

    test("xterm's answers to tmux are not the user's input", () {
      for (final r in [
        '\x1b[?1;2c',
        '\x1b[>0;276;0c',
        '\x1b[12;5R',
        '\x1b[0n',
        '\x1b[I',
        '\x1b]11;rgb:0c0c/0d0d/0e0e\x1b\\',
        '\x1b[?1;2c\x1b[>0;276;0c',
      ]) {
        expect(TerminalConnection.isTerminalReply(r), isTrue, reason: r);
      }
      for (final k in ['ls', '\x1b', '\x1b[A', '\x03', '\r', '\x1b[<64;1;1M']) {
        expect(TerminalConnection.isTerminalReply(k), isFalse, reason: k);
      }
    });

    test('locked on a cold start and after the idle time', () {
      var now = DateTime.utc(2026, 11, 3, 20);
      final lock = TerminalLock(now: () => now);
      expect(lock.locked, isTrue);
      lock.touch();
      expect(lock.locked, isFalse);
      now = now.add(const Duration(minutes: 14, seconds: 59));
      expect(lock.locked, isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(lock.locked, isTrue);
    });
  });

  group('service', () {
    late TerminalFakes fakes;
    late TerminalService service;

    setUp(() {
      fakes = TerminalFakes();
      service = TerminalService(
        secrets: TerminalSecrets(fakes.store),
        dialer: fakes.dialer,
        biometrics: fakes.biometrics,
        defaultHost: 'archlinux.example.ts.net',
        timing: fastTerminalTiming,
      );
    });

    tearDown(() => service.dispose());

    test(
      'a new setup starts from the paired host and does not connect',
      () async {
        await service.start();
        expect(service.config.host, 'archlinux.example.ts.net');
        expect(service.config.port, 2222);
        expect(service.config.user, 'csakos');
        expect(service.config.verified, isFalse);
        expect(fakes.dialer.opens, isEmpty);
      },
    );

    test('setup: connect, trust, live → saved as verified', () async {
      await service.connectWith(
        const TerminalConfig(host: 'archlinux.example.ts.net'),
      );
      await until(() => service.connection.phase == TermPhase.verifying);
      service.connection.answerHostKey(trust: true);
      await until(() => service.config.verified);
      expect(service.pinned!.fingerprint, testHostKey);
      expect(service.lock.locked, isFalse);
      final saved = await TerminalSecrets(fakes.store).loadConfig();
      expect(saved!.verified, isTrue);
    });

    test('with setup done, opening the tab connects', () async {
      await fakes.setUpDone();
      await service.start();
      await until(() => service.connection.phase == TermPhase.live);
      await service.start();
      expect(fakes.dialer.opens, hasLength(1));
    });

    test('a new key makes setup show again', () async {
      await fakes.setUpDone();
      await service.start();
      await until(() => service.connection.phase == TermPhase.live);
      final old = service.key!.publicLine;
      await service.regenerateKey();
      expect(service.key!.publicLine, isNot(old));
      expect(service.config.verified, isFalse);
      expect(service.connection.phase, TermPhase.offline);
    });

    test('forgetting the host key disconnects and asks next time', () async {
      await fakes.setUpDone();
      await service.start();
      await until(() => service.connection.phase == TermPhase.live);
      await service.forgetHostKey();
      expect(service.pinned, isNull);
      service.connection.retryNow();
      await until(() => service.connection.phase == TermPhase.verifying);
    });

    test('the font size is kept within 9–20 sp', () async {
      await service.load();
      await service.setFontSize(40);
      expect(service.fontSize, kTerminalFontMax);
      await service.setFontSize(3);
      expect(service.fontSize, kTerminalFontMin);
      expect(await TerminalSecrets(fakes.store).loadFontSize(), 9);
    });

    test('tmux asking for device attributes behind the lock does not open '
        'it (T2a phone test: cancelling the fingerprint let you in)', () async {
      await fakes.setUpDone();
      await service.start();
      await until(() => service.connection.phase == TermPhase.live);
      expect(service.lock.locked, isTrue);
      final link = fakes.dialer.last;
      link.send('\x1b[c\x1b[>c'); // what tmux sends on attach
      await until(() => link.written.contains('c'), reason: 'xterm answered');
      expect(service.lock.locked, isTrue);
      fakes.biometrics.result = UnlockResult.canceled;
      await service.unlock('r');
      expect(service.lock.locked, isTrue);
    });

    test('keyboard heights are kept per orientation', () async {
      await service.load();
      expect(service.imeHeight('portrait'), isNull);
      service
        ..rememberImeHeight('portrait', 301.5)
        ..rememberImeHeight('landscape', 0);
      await settle(10);
      final again = TerminalService(
        secrets: TerminalSecrets(fakes.store),
        dialer: fakes.dialer,
        biometrics: fakes.biometrics,
        defaultHost: 'archlinux.example.ts.net',
        timing: fastTerminalTiming,
      );
      addTearDown(again.dispose);
      await again.load();
      expect(again.imeHeight('portrait'), 301.5);
      expect(again.imeHeight('landscape'), isNull);
    });

    test('unlock: ok and "no screen lock" open, cancel does not', () async {
      fakes.biometrics.result = UnlockResult.canceled;
      await service.unlock('r');
      expect(service.lock.locked, isTrue);
      fakes.biometrics.result = UnlockResult.unavailable;
      await service.unlock('r');
      expect(service.lock.locked, isFalse);
    });
  });
}
