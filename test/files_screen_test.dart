import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/files_fakes.dart';
import 'support/harness.dart';
import 'support/terminal_fakes.dart';

Future<void> frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<TerminalFakes> openFiles(
  WidgetTester t, {
  bool setupDone = true,
  TerminalFakes? fakes,
}) async {
  final terminal = fakes ?? TerminalFakes();
  await pumpDelve(
    t,
    settle: false,
    terminal: terminal,
    before: setupDone ? (_) => terminal.setUpDone() : null,
  );
  await t.tap(navItem('Files'));
  await frames(t);
  return terminal;
}

String header(WidgetTester t) =>
    t.widget<Text>(find.byKey(const Key('files.header'))).data!;

void main() {
  testWidgets('before the terminal is set up: a pointer to it', (t) async {
    await openFiles(t, setupDone: false);
    expect(find.byKey(const Key('files.notSetUp')), findsOneWidget);
    await t.tap(find.byKey(const Key('files.openTerminal')));
    await frames(t);
    expect(find.byKey(const Key('terminal.setup')), findsOneWidget);
  });

  testWidgets('unlocks, then the home folder: folders first, dotfiles hidden', (
    t,
  ) async {
    final fakes = await openFiles(t);
    expect(fakes.biometrics.calls, 1);
    expect(find.byKey(const Key('files.list')), findsOneWidget);
    for (final n in ['delve-app', 'Documents', 'Downloads', 'notes.txt']) {
      expect(find.byKey(Key('files.row.$n')), findsOneWidget, reason: n);
    }
    expect(find.byKey(const Key('files.row..config')), findsNothing);
    expect(header(t), startsWith('6 shown · 4 hidden · btrfs · 931 GB'));
    expect(header(t), endsWith('67 % used'));
    // the breadcrumb and the Home chip
    expect(find.byKey(const Key('files.crumb./home/user')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    // folder counts arrive
    expect(find.textContaining('1 item · 4 Nov'), findsWidgets);
  });

  testWidgets('into a deep folder, the collapsed breadcrumb, back', (t) async {
    await openFiles(t);
    await t.tap(find.byKey(const Key('files.row.Documents')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.row.hajos')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.row.evkonyv')));
    await frames(t);
    expect(
      find.byKey(const Key('files.row.beszedes_evkonyv.pdf')),
      findsOneWidget,
    );
    expect(find.textContaining('14.2 MB'), findsOneWidget);
    expect(find.byKey(const Key('files.crumb.more')), findsOneWidget);
    expect(find.byKey(const Key('files.crumb./home/user')), findsNothing);
    // Android back: the folder before
    await t.binding.handlePopRoute();
    await frames(t);
    expect(find.byKey(const Key('files.row.evkonyv')), findsOneWidget);
    // a breadcrumb segment
    await t.tap(find.byKey(const Key('files.crumb./home/user/Documents')));
    await frames(t);
    expect(find.byKey(const Key('files.row.hajos')), findsOneWidget);
  });

  testWidgets('/root: permission denied with owner and mode, no sudo', (
    t,
  ) async {
    await openFiles(t);
    await t.tap(find.byKey(const Key('files.quick./')));
    await frames(t);
    expect(header(t), contains('btrfs'));
    await t.tap(find.byKey(const Key('files.row.root')));
    await frames(t);
    expect(find.byKey(const Key('files.denied')), findsOneWidget);
    expect(
      find.textContaining('belongs to root (drwx------)', findRichText: true),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('files.goRoot')));
    await frames(t);
    expect(find.byKey(const Key('files.row.usr')), findsOneWidget);
  });

  testWidgets('the menu: hidden files, sort by size', (t) async {
    await openFiles(t);
    await t.tap(find.byKey(const Key('files.menu')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.menu.hidden')));
    await frames(t);
    expect(find.byKey(const Key('files.row..config')), findsOneWidget);
    expect(header(t), startsWith('10 items'));
    await t.tap(find.byKey(const Key('files.menu')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.sort.size')));
    await frames(t);
    expect(find.text('Size'), findsOneWidget);
    // the header's arrow flips the direction
    await t.tap(find.byKey(const Key('files.sortKey')));
    await frames(t);
  });

  testWidgets('a symlink shows its target; a text file opens in the preview', (
    t,
  ) async {
    await openFiles(t);
    await t.tap(find.byKey(const Key('files.menu')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.menu.hidden')));
    await frames(t);
    expect(find.text('link → ~/.local/share/Steam'), findsOneWidget);
    await t.tap(find.byKey(const Key('files.row.notes.txt')));
    await frames(t);
    expect(find.byKey(const Key('preview.text')), findsOneWidget);
    expect(find.text('line one'), findsOneWidget);
    expect(find.text('Read-only · 2 lines · UTF-8'), findsOneWidget);
    // the route below goes offstage once the transition (800 ms) ends
    await frames(t, 20);
    expect(find.byType(NavigationBar), findsNothing);
    await t.tap(find.byType(BackButton));
    await frames(t, 20);
    expect(find.byKey(const Key('files.list')), findsOneWidget);
  });

  testWidgets('the actions sheet: copy path, preview, download', (t) async {
    await openFiles(t);
    await t.tap(find.byKey(const Key('files.menu.notes.txt')));
    await frames(t);
    expect(find.byKey(const Key('files.act.download')), findsOneWidget);
    expect(find.byKey(const Key('files.act.preview')), findsOneWidget);
    expect(find.text('-rw-r--r-- csakos · ~/notes.txt'), findsOneWidget);
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
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
    await t.tap(find.byKey(const Key('files.act.copyPath')));
    await frames(t);
    expect(copied, '/home/user/notes.txt');
    expect(find.text('Path copied'), findsOneWidget);
  });

  testWidgets('a cancelled fingerprint keeps it locked', (t) async {
    final fakes = TerminalFakes(
      biometrics: FakeBiometrics(UnlockResult.canceled),
    );
    await openFiles(t, fakes: fakes);
    expect(find.byKey(const Key('files.locked')), findsOneWidget);
    expect(find.byKey(const Key('files.list')), findsNothing);
    fakes.biometrics.result = UnlockResult.ok;
    await t.tap(find.byKey(const Key('files.unlock')));
    await frames(t);
    expect(find.byKey(const Key('files.list')), findsOneWidget);
  });

  testWidgets('another host key: stops, points to the terminal', (t) async {
    final fakes = TerminalFakes(
      files: FakeFilesDialer(sampleFs)
        ..fail.add(const SshHostKeyRejected('changed')),
    );
    await openFiles(t, fakes: fakes);
    expect(find.byKey(const Key('files.hostKeyChanged')), findsOneWidget);
    await t.tap(find.byKey(const Key('files.retry')));
    await frames(t);
    expect(find.byKey(const Key('files.list')), findsOneWidget);
  });

  testWidgets('offline: the state line, then the list again', (t) async {
    final fakes = TerminalFakes(
      files: FakeFilesDialer(sampleFs)
        ..fail.addAll(const [
          SshUnreachable('timed out'),
          SshUnreachable('timed out'),
        ]),
    );
    await pumpDelve(
      t,
      settle: false,
      terminal: fakes,
      before: (_) => fakes.setUpDone(),
    );
    await t.tap(navItem('Files'));
    await t.pump();
    // the lock screen first; the unlock is drawn a frame later
    for (var i = 0; i < 12; i++) {
      if (find.byKey(const Key('files.offline')).evaluate().isNotEmpty) {
        break;
      }
      await t.pump(const Duration(milliseconds: 2));
    }
    expect(find.byKey(const Key('files.offline')), findsOneWidget);
    await frames(t);
    expect(find.byKey(const Key('files.offline')), findsNothing);
    expect(find.byKey(const Key('files.list')), findsOneWidget);
  });
}
