import 'dart:convert';
import 'dart:io';

import 'package:delve/terminal/desktop_clipboard.dart';
import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/terminal_fakes.dart';

/// The desktop's clipboard behind the fake SSH: answers the two commands
/// the way wl-copy and wl-paste do there (DA0).
class FakeDesktop {
  /// null: nothing is copied.
  String? text;

  /// The commands end with this exit code instead.
  int? fail;
  String error = '';

  static final _sent = RegExp(r"printf %s '([A-Za-z0-9+/=]*)' \| base64 -d");

  SshRunResult? answer(String command) {
    final copy = command.contains('| wl-copy');
    if (!copy && !command.contains('wl-paste -n')) return null;
    if (fail case final code?) return SshRunResult('', code, error: error);
    if (copy) {
      text = utf8.decode(base64.decode(_sent.firstMatch(command)![1]!));
      return const SshRunResult('', 0);
    }
    final t = text;
    if (t == null) {
      return const SshRunResult('', 43, error: 'Nothing is copied');
    }
    return SshRunResult(t, 0);
  }
}

/// This phone's clipboard instead of the platform's.
class PhoneClipboard {
  String? text;

  void install(WidgetTester t) {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.getData':
            final now = text;
            return now == null ? null : <String, Object?>{'text': now};
          case 'Clipboard.setData':
            text = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}

Future<void> frames(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<(DesktopClipboard, TerminalFakes, FakeDesktop)> makeClipboard({
  bool setUp = true,
}) async {
  final fakes = TerminalFakes();
  final desktop = FakeDesktop();
  fakes.dialer.tmux.other = desktop.answer;
  if (setUp) await fakes.setUpDone();
  final terminal = TerminalService(
    secrets: TerminalSecrets(fakes.store),
    dialer: fakes.dialer,
    biometrics: fakes.biometrics,
    defaultHost: 'archlinux.example.ts.net',
    timing: fakes.timing,
  );
  addTearDown(terminal.dispose);
  return (DesktopClipboard(terminal), fakes, desktop);
}

Future<(TerminalFakes, FakeDesktop, PhoneClipboard)> openApp(
  WidgetTester t, {
  bool setUp = true,
}) async {
  final terminal = TerminalFakes();
  final desktop = FakeDesktop();
  terminal.dialer.tmux.other = desktop.answer;
  final phone = PhoneClipboard()..install(t);
  await pumpDelve(
    t,
    terminal: terminal,
    before: (env) async {
      env.server.on(
        'GET',
        '/api/v1/cards',
        (r) => const FakeReply(200, {'data': <Object?>[]}),
      );
      if (setUp) await terminal.setUpDone();
    },
  );
  return (terminal, desktop, phone);
}

Matcher fails(ClipboardFailureKind kind, [String? detail]) => throwsA(
  isA<ClipboardFailure>()
      .having((f) => f.kind, 'kind', kind)
      .having((f) => f.detail, 'detail', detail ?? anything),
);

void main() {
  group('the commands, run by a shell (fake wl-copy and wl-paste on PATH)', () {
    late Directory dir;
    late Directory runtime;
    late File copied;
    ServerSocket? socket;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('delve-clip');
      final bin = Directory('${dir.path}/bin')..createSync();
      runtime = Directory('${dir.path}/run')..createSync();
      copied = File('${dir.path}/copied');
      File('${bin.path}/wl-copy').writeAsStringSync(
        '#!/bin/sh\n'
        r'echo "$WAYLAND_DISPLAY|$*" > "$FAKE_DIR/args"; cat > "$FAKE_DIR/copied"'
        '\n',
      );
      File('${bin.path}/wl-paste').writeAsStringSync(
        '#!/bin/sh\n'
        r'case "$FAKE_MODE" in'
        '\n'
        r'  empty) echo "Nothing is copied" >&2; exit 1 ;;'
        '\n'
        r'  broken) echo "Failed to connect to a Wayland server" >&2; exit 1 ;;'
        '\n'
        r'  image) [ "$1" = -l ] && { echo image/png; exit 0; }; printf PNG; exit 0 ;;'
        '\n'
        'esac\n'
        r'[ "$1" = -l ] && { printf "text/plain\nUTF8_STRING\n"; exit 0; }'
        '\n'
        r'cat "$FAKE_DIR/copied"'
        '\n',
      );
      await Process.run('chmod', [
        '+x',
        '${bin.path}/wl-copy',
        '${bin.path}/wl-paste',
      ]);
      // the session's socket, its lock and another program's socket file
      socket = await ServerSocket.bind(
        InternetAddress(
          '${runtime.path}/wayland-7',
          type: InternetAddressType.unix,
        ),
        0,
      );
      File('${runtime.path}/wayland-7.lock').createSync();
      File('${runtime.path}/wayland-7-awww-daemon.sock').createSync();
    });

    tearDown(() async {
      await socket?.close();
      dir.deleteSync(recursive: true);
    });

    Future<ProcessResult> sh(
      String command, {
      String mode = '',
      String? runtimeDir,
    }) => Process.run(
      'sh',
      ['-c', command],
      environment: {
        'PATH': '${dir.path}/bin:/usr/bin:/bin',
        'XDG_RUNTIME_DIR': runtimeDir ?? runtime.path,
        'FAKE_DIR': dir.path,
        'FAKE_MODE': mode,
      },
      includeParentEnvironment: false,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    const text = 'árvíztűrő \'egy\' "kettő" \$HOME `x` 🙂\n  második sor\n';

    test('send: the text arrives byte for byte, as text/plain, on the '
        'session found in the runtime directory', () async {
      final r = await sh(sendCommand(text));
      expect(r.exitCode, 0, reason: '${r.stderr}');
      expect(r.stdout, isEmpty);
      expect(copied.readAsBytesSync(), utf8.encode(text));
      expect(
        File('${dir.path}/args').readAsStringSync().trim(),
        'wayland-7|-t text/plain',
      );
    });

    test('fetch: the text as it is; at most the limit and one byte', () async {
      copied.writeAsStringSync(text);
      final r = await sh(fetchCommand());
      expect(r.exitCode, 0, reason: '${r.stderr}');
      expect(r.stdout, text);
      copied.writeAsStringSync('abcdefgh');
      expect((await sh(fetchCommand(max: 4))).stdout, 'abcde');
    });

    test('fetch: empty, not text, another failure – each its own exit '
        'code', () async {
      expect((await sh(fetchCommand(), mode: 'empty')).exitCode, 43);
      final image = await sh(fetchCommand(), mode: 'image');
      expect((image.exitCode, image.stdout), (45, ''));
      final broken = await sh(fetchCommand(), mode: 'broken');
      expect(broken.exitCode, 44);
      expect(broken.stderr, contains('Failed to connect'));
    });

    test('no graphical session: exit 40, nothing is run', () async {
      final empty = Directory('${dir.path}/none')..createSync();
      expect(
        (await sh(sendCommand(text), runtimeDir: empty.path)).exitCode,
        40,
      );
      expect((await sh(fetchCommand(), runtimeDir: empty.path)).exitCode, 40);
      expect(copied.existsSync(), isFalse);
    });
  });

  group('the desktop clipboard over the terminal connection', () {
    test('send and fetch run over a connection of their own, trusting only '
        'the pinned key', () async {
      final (clipboard, fakes, desktop) = await makeClipboard();
      await clipboard.send('szia 🙂\nsor');
      expect(desktop.text, 'szia 🙂\nsor');
      expect(await clipboard.fetch(), 'szia 🙂\nsor');
      expect(fakes.dialer.runs, hasLength(2));
      expect(fakes.dialer.opens, isEmpty);

      fakes.dialer.hostKey = (testHostKeyType, otherHostKey);
      await expectLater(
        clipboard.fetch(),
        fails(ClipboardFailureKind.unreachable),
      );
    });

    test('without setup nothing is tried', () async {
      final (clipboard, fakes, _) = await makeClipboard(setUp: false);
      await expectLater(
        clipboard.send('x'),
        fails(ClipboardFailureKind.noSetup),
      );
      await expectLater(clipboard.fetch(), fails(ClipboardFailureKind.noSetup));
      expect(fakes.dialer.runs, isEmpty);
    });

    test('what the phone refuses before asking the desktop', () async {
      final (clipboard, fakes, _) = await makeClipboard();
      await expectLater(
        clipboard.send(''),
        fails(ClipboardFailureKind.phoneEmpty),
      );
      await expectLater(
        clipboard.send('ő' * (kClipboardSendMax ~/ 2 + 1)),
        fails(ClipboardFailureKind.tooLarge, '64'),
      );
      expect(fakes.dialer.runs, isEmpty);
      await clipboard.send('ő' * (kClipboardSendMax ~/ 2));
      expect(fakes.dialer.runs, hasLength(1));
    });

    test('the desktop\'s answers: exit codes and its words', () async {
      final (clipboard, fakes, desktop) = await makeClipboard();
      await expectLater(
        clipboard.fetch(),
        fails(ClipboardFailureKind.desktopEmpty),
      );
      for (final (code, kind) in [
        (40, ClipboardFailureKind.noSession),
        (41, ClipboardFailureKind.noTool),
        (45, ClipboardFailureKind.notText),
      ]) {
        desktop.fail = code;
        await expectLater(clipboard.fetch(), fails(kind));
        await expectLater(clipboard.send('x'), fails(kind));
      }
      desktop
        ..fail = 44
        ..error = 'Failed to connect to a Wayland server\nNote: …';
      await expectLater(
        clipboard.fetch(),
        fails(
          ClipboardFailureKind.failed,
          'Failed to connect to a Wayland server',
        ),
      );
      desktop
        ..fail = 1
        ..error = '';
      await expectLater(
        clipboard.send('x'),
        fails(ClipboardFailureKind.failed, 'exit 1'),
      );
      desktop
        ..fail = null
        ..text = 'a' * (kClipboardFetchMax + 1);
      await expectLater(
        clipboard.fetch(),
        fails(ClipboardFailureKind.tooLarge, '256'),
      );
      fakes.dialer.runFailures.add(const SshUnreachable('timed out'));
      await expectLater(
        clipboard.fetch(),
        fails(ClipboardFailureKind.unreachable, 'timed out'),
      );
    });
  });

  group('in the app', () {
    testWidgets('Dashboard: To desktop sends this phone\'s clipboard, From '
        'desktop brings the desktop\'s', (t) async {
      final (_, desktop, phone) = await openApp(t);
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('dashboard.clipboard')), findsOneWidget);

      phone.text = 'árvíz 🙂\nsor';
      await t.tap(find.byKey(const Key('clipboard.toDesktop')));
      await frames(t);
      expect(desktop.text, 'árvíz 🙂\nsor');
      expect(find.text('11 characters sent to the desktop'), findsOneWidget);

      desktop.text = 'x';
      await t.tap(find.byKey(const Key('clipboard.toPhone')));
      await frames(t);
      expect(phone.text, 'x');
      expect(find.text('1 character copied from the desktop'), findsOneWidget);
      final button = t.widget<OutlinedButton>(
        find.byKey(const Key('clipboard.toDesktop')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a failure is told in a snackbar and the buttons work '
        'again', (t) async {
      final (_, desktop, phone) = await openApp(t);
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('clipboard.toDesktop')));
      await frames(t);
      expect(find.text("This phone's clipboard has no text"), findsOneWidget);

      desktop.fail = 40;
      await t.tap(find.byKey(const Key('clipboard.toPhone')));
      await frames(t);
      expect(
        find.text("Nobody is logged in on the desktop's screen"),
        findsOneWidget,
      );
      expect(phone.text, isNull);

      desktop
        ..fail = null
        ..text = 'ok';
      await t.tap(find.byKey(const Key('clipboard.toPhone')));
      await frames(t);
      expect(phone.text, 'ok');
    });

    testWidgets('More → Clipboard: the buttons and the text that went '
        'last', (t) async {
      final (_, desktop, _) = await openApp(t);
      desktop.text = 'git status';
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Clipboard'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('clipboard.noSetup')), findsNothing);
      expect(find.text('Nothing yet'), findsOneWidget);

      await t.tap(find.byKey(const Key('clipboard.toPhone')));
      await frames(t);
      expect(
        t.widget<Text>(find.byKey(const Key('clipboard.last.text'))).data,
        'git status',
      );
      expect(find.textContaining('from desktop · '), findsOneWidget);
      expect(find.text('Nothing yet'), findsNothing);
    });

    testWidgets('before the terminal is set up: no buttons on the Dashboard, '
        'the Clipboard page says why', (t) async {
      final (terminal, _, phone) = await openApp(t, setUp: false);
      phone.text = 'x';
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('dashboard.clipboard')), findsNothing);

      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Clipboard'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('clipboard.noSetup')), findsOneWidget);
      await t.tap(find.byKey(const Key('clipboard.toDesktop')));
      await frames(t);
      // the banner and the snackbar
      expect(
        find.text(
          'Set up the Terminal first: the clipboard uses its connection',
        ),
        findsNWidgets(2),
      );
      expect(terminal.dialer.runs, isEmpty);
    });
  });
}
