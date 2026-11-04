import 'dart:convert';
import 'dart:io' show Process;
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
  Rig({
    FakeSshDialer? dialer,
    TerminalTiming timing = fastTerminalTiming,
    int statusRows = 0,
  }) : dialer = dialer ?? FakeSshDialer(),
       store = MemorySecretStore() {
    secrets = TerminalSecrets(store);
    connection = TerminalConnection(
      dialer: this.dialer,
      secrets: secrets,
      timing: timing,
      onLive: () => lives++,
      onInput: () => inputs++,
      statusRows: statusRows,
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

    test('the tmux command attaches with a UTF-8 locale, marks the session '
        "as the app's, turns its status line off and binds the wheel to one "
        'line there', () {
      expect(
        target.command,
        startsWith(
          r'env LANG=en_US.UTF-8 tmux -u new-session -A -s delve-1 \; '
          r'set-option @delve 1 \; set-option status off \; '
          r'bind-key -T root WheelUpPane ',
        ),
      );
      expect(SshTarget.quoteSession("a b'c"), "'a bc'");
    });

    test('the shell hands tmux the command as separate words: each binding '
        'whole, `;` between commands (T2b: one line per wheel step)', () async {
      final printed = await Process.run('sh', [
        '-c',
        target.command.replaceFirst(
          'env LANG=en_US.UTF-8 tmux',
          r"printf '%s\n'",
        ),
      ]);
      final words = (printed.stdout as String).trim().split('\n');
      // commands, split at the `;` words
      final commands = <List<String>>[[]];
      for (final w in words) {
        if (w == ';') {
          commands.add([]);
        } else {
          commands.last.add(w);
        }
      }
      expect(commands.first, ['-u', 'new-session', '-A', '-s', 'delve-1']);
      expect(commands[1], ['set-option', '@delve', '1']);
      expect(commands[2], ['set-option', 'status', 'off']);
      expect(commands.length, 3 + SshTarget.tmuxWheelBindings.length);
      expect(commands[3], [
        'bind-key',
        '-T',
        'root',
        'WheelUpPane',
        'if-shell',
        '-F',
        '#{||:#{alternate_on},#{||:#{pane_in_mode},#{mouse_any_flag}}}',
        'send-keys -M',
        'copy-mode -e; if-shell -F "#{@delve}" "send-keys -X -N 1 scroll-up"',
      ]);
      for (final (i, table, dir) in [
        (4, 'copy-mode', 'up'),
        (5, 'copy-mode', 'down'),
        (6, 'copy-mode-vi', 'up'),
        (7, 'copy-mode-vi', 'down'),
      ]) {
        final key = dir == 'up' ? 'WheelUpPane' : 'WheelDownPane';
        expect(commands[i], [
          'bind-key',
          '-T',
          table,
          key,
          'if-shell',
          '-F',
          '#{@delve}',
          'select-pane; send-keys -X -N 1 scroll-$dir',
          'select-pane; send-keys -X -N 5 scroll-$dir',
        ]);
      }
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

    void expectAttached(Terminal t) {
      final lines = t.buffer.lines;
      for (var i = t.buffer.scrollBack; i < lines.length; i++) {
        expect(lines[i].attached, isTrue, reason: 'row $i');
        expect(lines[i].index, i, reason: 'row $i');
      }
    }

    test('lines moved by a scroll or a shrink stay attached (xterm 4.0.0 '
        'detached them: no selection after a scroll or with the keyboard '
        'open, T2b phone test)', () {
      final t = screen();
      final anchor = t.buffer.lines[5].createAnchor(2);
      t.write('\x1b[1;9r\x1b[2S'); // tmux scrolls the pane up by two
      expectAttached(t);
      expect(row(t, 3), 'line5');
      expect(anchor.attached, isTrue);
      expect((anchor.x, anchor.y), (2, 3));
      t.write('\x1b[2T'); // and down again
      expectAttached(t);
      expect(anchor.y, 5);
      t.resize(20, 7); // the keyboard opens
      expectAttached(t);
      t.resize(20, 10); // and closes
      expectAttached(t);
      expect(anchor.attached, isTrue);
    });

    test('a line that left the top comes back as the same line when tmux '
        'scrolls down (copy mode going up), blank until tmux draws it', () {
      final t = screen();
      final top = t.buffer.lines[0];
      t.write('\x1b[1;9r\x1b[S');
      expect(top.attached, isFalse);
      expect(t.historyLength, 1);
      t.write('\x1b[T');
      expect(identical(t.buffer.lines[0], top), isTrue);
      expect(top.attached, isTrue);
      expect(row(t, 0), '');
      expect(row(t, 1), 'line1');
      expect(t.historyLength, 0);
      // reverse index at the top, and delete / insert line there, the same
      t.write('\x1b[S\x1b[H\x1bM');
      expect(identical(t.buffer.lines[0], top), isTrue);
      t.write('\x1b[H\x1b[M');
      expect(t.historyLength, 1);
      t.write('\x1b[H\x1b[L');
      expect(identical(t.buffer.lines[0], top), isTrue);
      expect(t.historyLength, 0);
    });

    test("tmux's one-line copy-mode steps, in its own bytes (T2b: one line "
        'per wheel step): the pane moves a line at a time, the lines that '
        'leave the bottom come back as the same lines', () {
      final t = screen();
      final kept = [for (var i = 6; i <= 8; i++) t.buffer.lines[i]];
      // as tmux 3.4 draws a step up: region, insert a line at the top, the
      // top row redrawn, the region back to the whole screen
      String up(int n) =>
          '\x1b[1;9r\x1b[1;1H\x1b[1L\x1b[1;1Hold$n\x1b[1;10r\x1b[9;5H';
      for (var n = 1; n <= 3; n++) {
        t.write(up(n));
        expect(row(t, 0), 'old$n');
        expect(row(t, n), 'line0');
        expect(row(t, 8), 'line${8 - n}');
        expect(row(t, 9), 'status');
        expect(t.belowLength, n);
        expectAttached(t);
      }
      // a step down: delete the top line, draw the bottom one
      t.write('\x1b[1;9r\x1b[1;1H\x1b[1M\x1b[9;1Hline6\x1b[1;10r');
      expect(identical(t.buffer.lines[8], kept[0]), isTrue);
      expect(row(t, 8), 'line6');
      expect(row(t, 0), 'old2');
      expect(t.belowLength, 2);
      expectAttached(t);
    });

    test('a line that left the bottom comes back when tmux scrolls up '
        'again (T2b phone test: a selection on it was gone for good)', () {
      final t = screen();
      final bottom = t.buffer.lines[8];
      t.write('\x1b[1;9r\x1b[T'); // copy mode goes up: line8 leaves below
      expect(bottom.attached, isFalse);
      expect(t.belowLength, 1);
      expect(row(t, 8), 'line7');
      t.write('\x1b[S'); // and down again
      expect(identical(t.buffer.lines[8], bottom), isTrue);
      expect(t.belowLength, 0);
      expect(row(t, 7), 'line7');
      expect(row(t, 8), '', reason: 'blank until tmux draws it');
      // a line feed at the bottom and a delete at the top do the same
      t.write('\x1b[T\x1b[9;1H\n');
      expect(identical(t.buffer.lines[8], bottom), isTrue);
      t.write('\x1b[T\x1b[H\x1b[M');
      expect(identical(t.buffer.lines[8], bottom), isTrue);
    });

    test('the pane as one document: kept above, the pane, kept below', () {
      final t = screen();
      t.write('\x1b[1;9r\x1b[2S'); // line0, line1 above
      final doc = t.documentLines();
      expect(doc.length, 2 + 9);
      expect(doc[0].getText().trim(), 'line0');
      expect(doc[2].getText().trim(), 'line2');
      t.write('\x1b[5T'); // two back from above, five go below
      final down = t.documentLines();
      expect(down.length, 9 + 5);
      expect(t.belowLength, 5);
      expect(down[11].getText().trim(), 'line8');
    });

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

    test("without tmux's status line (the app's sessions, T2b): the pane "
        'is every row; it shrinks and grows like tmux all the same', () {
      final t = TmuxTerminal(statusRows: 0)..resize(20, 10);
      t.write('\x1b[?1049h');
      for (var i = 0; i < 10; i++) {
        t.write('\x1b[${i + 1};1Hline$i');
      }
      t.write('\x1b[10;7H'); // the prompt on the last row
      expect(t.paneRows, 10);
      t.resize(20, 7); // the keyboard opens: lines leave at the top
      expect(
        [for (var i = 0; i < 7; i++) row(t, i)],
        [for (var i = 3; i < 10; i++) 'line$i'],
      );
      expect(t.buffer.cursorY, 6);
      expect(t.historyLength, 3);
      t.resize(20, 10); // and closes: they come back
      expect(
        [for (var i = 0; i < 10; i++) row(t, i)],
        [for (var i = 0; i < 10; i++) 'line$i'],
      );
      expect(t.buffer.cursorY, 9);
      // a line below the cursor goes first, and comes back blank
      t.write('\x1b[5;1H');
      t.resize(20, 9);
      expect(row(t, 0), 'line0');
      expect(row(t, 8), 'line8');
      t.resize(20, 10);
      expect(row(t, 9), '');
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

  group('selection', () {
    void select(TerminalConnection c, CellOffset from, CellOffset to) {
      final buffer = c.terminal.buffer;
      c.selection.setSelection(
        buffer.createAnchorFromOffset(from),
        buffer.createAnchorFromOffset(to),
      );
    }

    test('the selected text, without the blanks tmux pads lines with; '
        'blanks only is nothing', () async {
      final rig = Rig();
      addTearDown(rig.dispose);
      final link = await rig.live();
      final c = rig.connection;
      link.send('hello world   \r\nsecond line   ');
      await until(
        () => c.terminal.buffer.lines[1].getText().startsWith('second'),
      );
      expect(c.selectedText(), isNull);
      select(c, const CellOffset(6, 0), const CellOffset(6, 1));
      expect(c.selectedText(), 'world\nsecond');
      select(c, const CellOffset(11, 0), const CellOffset(14, 0));
      expect(c.selectedText(), isNull);
    });

    test('a key ends it; what xterm answers to tmux does not', () async {
      final rig = Rig();
      addTearDown(rig.dispose);
      final link = await rig.live();
      final c = rig.connection;
      link.send('hello');
      await until(() => c.terminal.buffer.lines[0].getText() == 'hello');
      select(c, const CellOffset(0, 0), const CellOffset(5, 0));
      link.send('\x1b[c');
      await until(() => link.written.isNotEmpty, reason: 'DA answer');
      expect(c.selection.selection, isNotNull);
      c.terminal.textInput('x');
      expect(c.selection.selection, isNull);
      expect(link.written, endsWith('x'));
    });

    test('a wheel step keeps it (T2b phone test: it should stay while '
        'scrolling)', () async {
      final rig = Rig();
      addTearDown(rig.dispose);
      final link = await rig.live();
      final c = rig.connection;
      link.send('\x1b[?1049h\x1b[?1000h\x1b[?1006hhello');
      await until(() => c.terminal.mouseMode.reportScroll);
      select(c, const CellOffset(0, 0), const CellOffset(5, 0));
      expect(c.wheel(up: true, column: 0, row: 0), isTrue);
      expect(c.selectedText(), 'hello');
    });
  });

  group('selection over a scrolling tmux', () {
    /// tmux on a 24-row screen: pane rows 0–22 with `line0`…, status last.
    Future<(Rig, FakeSshLink)> tmux() async {
      final rig = Rig(statusRows: 1);
      addTearDown(rig.dispose);
      final link = await rig.live();
      final buf = StringBuffer('\x1b[?1049h');
      for (var i = 0; i < 23; i++) {
        buf.write('\x1b[${i + 1};1Hline$i');
      }
      buf.write('\x1b[24;1Hstatus\x1b[1;23r');
      link.send(buf.toString());
      final c = rig.connection;
      await until(() => c.terminal.buffer.lines[22].getText() == 'line22');
      return (rig, link);
    }

    test('partly scrolled out: the rest stays, cut at the edge, its handle '
        'hidden, Copy takes all of it; scrolled out entirely it waits; '
        'scrolled back it is all there (T2b phone test)', () async {
      final (rig, link) = await tmux();
      final c = rig.connection;
      final buffer = c.terminal.buffer;
      c.selection.setSelection(
        buffer.createAnchorFromOffset(const CellOffset(0, 20)),
        buffer.createAnchorFromOffset(const CellOffset(6, 22)),
      );
      expect(c.selectedText(), 'line20\nline21\nline22');

      link.send('\x1b[2T'); // copy mode up two: 21 and 22 go below
      await until(() => c.terminal.belowLength == 2);
      var range = c.selection.selection!.normalized;
      expect((range.begin.x, range.begin.y), (0, 22));
      expect((range.end.x, range.end.y), (80, 22));
      expect(c.selectionEndHidden, isTrue);
      expect(c.selectionStartHidden, isFalse);
      expect(c.selectedText(), 'line20\nline21\nline22');

      link.send('\x1b[3T'); // line20 goes below too
      await until(() => c.terminal.belowLength == 5);
      expect(c.selection.selection, isNull);
      expect(c.hasSelection, isTrue);

      // back down five; tmux draws the lines that come back
      link.send(
        '\x1b[5S\x1b[19;1Hline18\x1b[20;1Hline19\x1b[21;1Hline20'
        '\x1b[22;1Hline21\x1b[23;1Hline22',
      );
      await until(() => c.terminal.buffer.lines[22].getText() == 'line22');
      range = c.selection.selection!.normalized;
      expect((range.begin.x, range.begin.y), (0, 20));
      expect((range.end.x, range.end.y), (6, 22));
      expect(c.selectionEndHidden, isFalse);
      expect(c.selectedText(), 'line20\nline21\nline22');
      // and a key still ends it
      c.terminal.textInput('x');
      expect(c.hasSelection, isFalse);
      expect(c.selection.selection, isNull);
    });
  });

  group("tmux's copy mode (T2b phone test: typing after a scroll went to "
      '"goto line")', () {
    /// tmux on 80×24: pane rows 0–22, status last, the shell's cursor at
    /// column 2 of row [prompt].
    String screen({int prompt = 4}) {
      final buf = StringBuffer('\x1b[?1049h\x1b[?1000h\x1b[?1006h');
      for (var i = 0; i < 23; i++) {
        buf.write('\x1b[${i + 1};1Hline$i');
      }
      buf.write('\x1b[24;1Hstatus\x1b[1;23r\x1b[${prompt + 1};3H');
      return buf.toString();
    }

    /// tmux's position indicator, right-aligned on the first row in
    /// mode-style colours; its own cursor left on row 20.
    String indicator(int up, {String colours = '30;43', int end = 80}) {
      final text = '[$up/120]';
      return '\x1b[1;${end - text.length + 1}H\x1b[${colours}m$text\x1b[0m'
          '\x1b[20;1H';
    }

    /// tmux's redraw after copy mode: the first row without the indicator.
    const left = '\x1b[1;1Hline0\x1b[K\x1b[5;3H';

    TmuxTerminal tmux({int prompt = 4}) => TmuxTerminal()
      ..resize(80, 24)
      ..write(screen(prompt: prompt));

    test("seen by its indicator: no cursor of its own; the shell's cursor "
        'shows moved down by the scroll; gone after the redraw', () {
      final t = tmux();
      expect(t.inCopyMode, isFalse);
      expect(t.cursorVisibleMode, isTrue);
      expect(t.promptCursor, isNull);
      t.write(indicator(3));
      expect(t.inCopyMode, isTrue);
      expect(t.cursorVisibleMode, isFalse);
      expect(t.promptCursor, const CellOffset(2, 7));
      t.write(indicator(5));
      expect(t.promptCursor, const CellOffset(2, 9));
      t.write(left);
      expect(t.inCopyMode, isFalse);
      expect(t.cursorVisibleMode, isTrue);
      expect(t.promptCursor, isNull);
    });

    test('scrolled further than the pane: no shell cursor', () {
      final t = tmux()..write(indicator(19));
      expect(t.promptCursor, isNull);
      expect(t.cursorVisibleMode, isFalse);
    });

    test('the same text without the colours, or not at the edge, is not '
        'copy mode', () {
      expect((tmux()..write(indicator(3, colours: '0'))).inCopyMode, isFalse);
      expect((tmux()..write(indicator(3, end: 70))).inCopyMode, isFalse);
    });

    test('a resize moves the shell cursor the way tmux moves its line', () {
      final t = tmux(prompt: 20)..write(indicator(0));
      expect(t.promptCursor, const CellOffset(2, 20));
      // keyboard: 10 rows less, 2 below the cursor go first, then 8 at top
      t.resize(80, 14);
      expect(t.promptCursor, CellOffset(2, t.buffer.scrollBack + 12));
      // back: 10 lines come from tmux's history at the top
      t.resize(80, 24);
      expect(t.promptCursor, CellOffset(2, t.buffer.scrollBack + 22));
    });

    test('a key goes to the shell: `q` first, once until the redraw; a tap '
        'and a wheel step stay in copy mode', () async {
      final rig = Rig();
      addTearDown(rig.dispose);
      final link = await rig.live();
      final c = rig.connection;
      link.send(screen() + indicator(3));
      await until(() => c.terminal.inCopyMode, reason: 'copy mode');

      expect(c.wheel(up: true, column: 0, row: 0), isTrue);
      expect(link.written, isNot(contains('q')));
      c.terminal.mouseInput(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        const CellOffset(1, 1),
      );
      expect(link.written, isNot(contains('q')));
      expect(c.terminal.inCopyMode, isTrue);

      c.terminal.textInput('l');
      c.terminal.textInput('s');
      expect(link.written, endsWith('qls'));
      expect(c.terminal.inCopyMode, isFalse);

      // the old screen again (tmux has not redrawn yet): still no `q`
      link.send('${indicator(3)}\x1b[11;1Hmark');
      await until(
        () => c.terminal.buffer.lines[10].getText().startsWith('mark'),
      );
      expect(c.terminal.inCopyMode, isFalse);
      c.terminal.textInput('x');
      expect(link.written, endsWith('qlsx'));

      // redrawn, then scrolled up again
      link.send(left);
      await until(() => c.terminal.buffer.lines[0].getText() == 'line0');
      link.send(indicator(1));
      await until(() => c.terminal.inCopyMode, reason: 'copy mode again');
      c.terminal.textInput('y');
      expect(link.written, endsWith('xqy'));
    });

    test('mouse reports are told apart from keys', () {
      expect(
        TerminalConnection.isMouseReport('\x1b[<0;3;4M\x1b[<0;3;4m'),
        isTrue,
      );
      expect(TerminalConnection.isMouseReport('\x1b[<64;1;1M'), isTrue);
      expect(TerminalConnection.isMouseReport('\x1b[M !!'), isTrue);
      expect(TerminalConnection.isMouseReport('\x1b[A'), isFalse);
      expect(TerminalConnection.isMouseReport('q'), isFalse);
    });
  });

  group('reversed selection colours', () {
    test('the palette is the one xterm 4.0.0 uses', () {
      final p = terminalPalette(delveTerminalTheme);
      expect(p[1], delveTerminalTheme.red);
      expect(p[15], delveTerminalTheme.white);
      expect(p[16], const Color(0xFF000000));
      expect(p[21], const Color(0xFF0000FF));
      expect(p[196], const Color(0xFFFF0000));
      expect(p[110], const Color(0xFF87AFD7));
      expect(p[232], const Color(0xFF080808));
      expect(p[255], const Color(0xFFEEEEEE));
    });

    test('cell colours: default, palette, RGB', () {
      final p = terminalPalette(delveTerminalTheme);
      const fallback = Color(0xFF123456);
      expect(terminalColor(0, p, fallback), fallback);
      expect(terminalColor(CellColor.named | 2, p, fallback), p[2]);
      expect(terminalColor(CellColor.palette | 200, p, fallback), p[200]);
      expect(
        terminalColor(CellColor.rgb | 0xABCDEF, p, fallback),
        const Color(0xFFABCDEF),
      );
    });

    test('the view paints no selection of its own', () {
      expect(delveTerminalViewTheme.selection.a, 0);
      expect(delveTerminalViewTheme.cursor.a, 0, reason: 'nor a cursor');
      expect(delveTerminalViewTheme.foreground, delveTerminalTheme.foreground);
      expect(delveTerminalViewTheme.green, delveTerminalTheme.green);
    });

    test('the cursor ends as far below the middle of the capitals as the '
        "cell's top is above it (T2b phone test: it reached further down "
        'than up, onto the row below)', () {
      // JetBrains Mono at 13 with a 1.2 line height, as the phone draws it
      final h = terminalCursorHeight(
        lineHeight: 15.6,
        baseline: 11.76,
        fontSize: 13,
      );
      final middle = 11.76 - kTerminalCapHeight * 13 / 2;
      expect(h, closeTo(2 * middle, 1e-9));
      expect(h, lessThan(15.6));
      expect(15.6 - h, closeTo(1.57, 0.01), reason: 'a little shorter');
      // never taller than the cell, and the whole cell when it can't tell
      expect(
        terminalCursorHeight(lineHeight: 15.6, baseline: 15, fontSize: 13),
        15.6,
      );
      expect(
        terminalCursorHeight(lineHeight: 15.6, baseline: 2, fontSize: 13),
        15.6,
      );
    });
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
