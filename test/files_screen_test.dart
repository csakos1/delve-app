import 'package:delve/files/pdf_pages.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_lock.dart';
import 'package:delve/theme/delve_colors.dart';
import 'package:delve/ui/screens/files_screen.dart';
import 'package:delve/ui/widgets/zoom.dart';
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

/// Frames with real time in between, until [done]: the preview's fetch
/// writes a real file, and file IO does not run on the test's fake clock.
Future<void> untilIo(WidgetTester t, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue, reason: 'timed out');
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
    await t.tap(find.byKey(const Key('files.crumb./')));
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

  testWidgets('quick locations: Home, Downloads, Documents', (t) async {
    await openFiles(t);
    for (final p in ['', '/Downloads', '/Documents']) {
      expect(
        find.byKey(Key('files.quick./home/user$p')),
        findsOneWidget,
        reason: p,
      );
    }
    expect(find.byKey(const Key('files.quick./')), findsNothing);
    expect(find.byKey(const Key('files.quick./boot')), findsNothing);
    await t.tap(find.byKey(const Key('files.quick./home/user/Documents')));
    await frames(t);
    expect(find.byKey(const Key('files.row.hajos')), findsOneWidget);
  });

  testWidgets('images: swipe through the folder; back after the preview '
      'still goes up a folder', (t) async {
    // what the app tells Android about the back gesture
    final handlesBack = <bool>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments as bool);
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
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await openFiles(t);
    for (final row in ['Documents', 'hajos', 'evkonyv']) {
      await t.tap(find.byKey(Key('files.row.$row')));
      await frames(t);
    }
    await t.tap(find.byKey(const Key('files.row.borito.png')));
    await frames(t, 20);
    String title() =>
        t.widget<Text>(find.byKey(const Key('preview.title'))).data!;
    String subtitle() =>
        t.widget<Text>(find.byKey(const Key('preview.subtitle'))).data!;
    expect(title(), 'borito.png');
    expect(subtitle(), startsWith('1 / 2 · ~/Documents/hajos/evkonyv'));
    await t.fling(
      find.byKey(const Key('preview.pages')),
      const Offset(-400, 0),
      1500,
    );
    await frames(t, 20);
    expect(title(), 'hatlap.png');
    expect(subtitle(), startsWith('2 / 2'));
    // two fingers down: a pinch, the pages stand still until both are up
    PageView pager() =>
        t.widget<PageView>(find.byKey(const Key('preview.pages')));
    final mid = t.getCenter(find.byKey(const Key('preview.pages')));
    final one = await t.startGesture(mid - const Offset(40, 0), pointer: 7);
    await t.pump();
    expect(pager().physics, isNull);
    final two = await t.startGesture(mid + const Offset(40, 0), pointer: 8);
    await t.pump();
    expect(pager().physics, isA<NeverScrollableScrollPhysics>());
    await one.up();
    await t.pump();
    expect(pager().physics, isA<NeverScrollableScrollPhysics>());
    await two.up();
    await t.pump();
    expect(pager().physics, isNull);
    await frames(t);
    // back to the folder; Android still lets the app take the back gesture
    await t.tap(find.byType(BackButton));
    await frames(t, 20);
    expect(find.byKey(const Key('files.row.borito.png')), findsOneWidget);
    expect(handlesBack, isNotEmpty);
    expect(handlesBack, everyElement(isTrue));
    // and back goes to the folder before, not out of the app
    await t.binding.handlePopRoute();
    await frames(t);
    expect(find.byKey(const Key('files.row.evkonyv')), findsOneWidget);
  });

  testWidgets('a PDF: its pages rendered as they come into view, the page '
      'in the title, two fingers hold the list, closed after', (t) async {
    final fakes = await openFiles(t);
    for (final row in ['Documents', 'hajos', 'evkonyv']) {
      await t.tap(find.byKey(Key('files.row.$row')));
      await frames(t);
    }
    await t.tap(find.byKey(const Key('files.row.beszedes_evkonyv.pdf')));
    await frames(t, 20);
    final pdf = find.byKey(const Key('preview.pdf'));
    await untilIo(
      t,
      () => pdf.evaluate().isNotEmpty && fakes.pdf.rendered.isNotEmpty,
    );
    await frames(t);
    String subtitle() =>
        t.widget<Text>(find.byKey(const Key('preview.subtitle'))).data!;
    expect(subtitle(), startsWith('Page 1 / 12 · ~/Documents/hajos/evkonyv'));
    // the page in view first, at 1.5× the screen's pixels: (448 - 16) × 3 × 1.5
    expect(fakes.pdf.rendered.first, (1, 0, 1944));
    expect(
      find.descendant(
        of: find.byKey(const Key('preview.pdf.page.0')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    // pages further down: rendered when they come, the title follows
    await t.drag(pdf, const Offset(0, -2500));
    await frames(t);
    expect(subtitle(), matches(RegExp(r'^Page ([2-9]|1[0-2]) / 12 · ')));
    expect(fakes.pdf.rendered.map((r) => r.$2), contains(greaterThan(1)));
    // two fingers down: a pinch, the list stands still until both are up
    ListView list() => t.widget<ListView>(pdf);
    final mid = t.getCenter(pdf);
    final one = await t.startGesture(mid - const Offset(40, 0), pointer: 7);
    await t.pump();
    expect(list().physics, isNull);
    final two = await t.startGesture(mid + const Offset(40, 0), pointer: 8);
    await t.pump();
    expect(list().physics, isA<NeverScrollableScrollPhysics>());
    await one.up();
    await two.up();
    await t.pump();
    expect(list().physics, isNull);
    await frames(t);
    // back: the document is closed
    await t.tap(find.byType(BackButton));
    await frames(t, 20);
    expect(fakes.pdf.closed, [1]);
    expect(
      find.byKey(const Key('files.row.beszedes_evkonyv.pdf')),
      findsOneWidget,
    );
    // (the preview folder's removal finishes)
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    // a PDF with a password: says so, offers Download
    fakes.pdf.fail = const PdfProblem(PdfProblemKind.locked, 'password');
    await t.tap(find.byKey(const Key('files.row.beszedes_evkonyv.pdf')));
    await frames(t, 20);
    final locked = find.byKey(const Key('preview.pdfLocked'));
    await untilIo(t, () => locked.evaluate().isNotEmpty);
    expect(find.text('Password-protected PDF'), findsOneWidget);
    expect(
      find.descendant(of: locked, matching: find.text('Download')),
      findsOneWidget,
    );
    expect(subtitle(), startsWith('~/Documents/hajos/evkonyv'));
    await t.tap(find.byType(BackButton));
    await frames(t, 20);
  });

  testWidgets('the Files header keeps its colour while the list scrolls', (
    t,
  ) async {
    await openFiles(t);
    await t.tap(find.byKey(const Key('files.crumb./')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.row.usr')));
    await frames(t);
    await t.tap(find.byKey(const Key('files.row.bin')));
    await frames(t);
    Color? color() =>
        (t
                    .widget<AnimatedContainer>(
                      find.descendant(
                        of: find.byType(FilesScreen),
                        matching: find.byKey(const Key('page.header')),
                      ),
                    )
                    .decoration!
                as BoxDecoration)
            .color;
    expect(color(), delveColorScheme.surface);
    await t.drag(find.byKey(const Key('files.list')), const Offset(0, -400));
    await frames(t);
    expect(color(), delveColorScheme.surface);
  });

  test('a double tap zooms where it was tapped, without black bands', () {
    // a landscape photo, 400 × 300, in the middle of a 400 × 800 viewer
    const image = Rect.fromLTRB(0, 250, 400, 550);
    const view = Size(400, 800);
    double top(Matrix4 m) => m.getTranslation().y + image.top * 2.5;
    // 2.5×: 1000 × 750, wider than the view, lower than it
    var m = zoomInto(
      point: const Offset(100, 400),
      image: image,
      view: view,
      scale: 2.5,
    );
    expect(m.getMaxScaleOnAxis(), 2.5);
    // the tapped x stays under the finger; vertically it is centred
    expect(m.getTranslation().x, 100 - 2.5 * 100);
    expect(top(m), 25);
    // a tap on the black band above, at the right edge: the picture's
    // right edge on the view's right edge, never beyond it
    m = zoomInto(
      point: const Offset(400, 100),
      image: image,
      view: view,
      scale: 2.5,
    );
    expect(m.getTranslation().x, 400 - 1000);
    expect(top(m), 25);
    // 3×: 900 high, taller than the view: the tapped bottom edge stays
    // on the view's bottom edge
    m = zoomInto(
      point: const Offset(200, 550),
      image: image,
      view: view,
      scale: 3,
    );
    expect(m.getTranslation().y + image.bottom * 3, 800);
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
