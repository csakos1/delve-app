import 'dart:io';

import 'package:delve/app/platform.dart';
import 'package:delve/attachments/image_prep.dart';
import 'package:delve/files/linux_device_files.dart';
import 'package:delve/files/pdf_pages.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/terminal/terminal_lock.dart';
import 'package:delve/theme/delve_theme.dart';
import 'package:delve/ui/chat/attachments.dart';
import 'package:delve/ui/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'support/harness.dart';

final _linux = PlatformCaps.linux(host: 'archlinux');

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder get _settingsList => find
    .descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  group('caps (L1)', () {
    test('widget tests run as the phone unless told otherwise', () {
      expect(PlatformCaps.current().phone, isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final caps = PlatformCaps.current();
      expect(caps.phone, isFalse);
      expect(caps.push, isFalse);
      expect(caps.desktopToolsByDefault, isFalse);
      expect(caps.deviceName, startsWith('linux'));
    });

    test('the Linux device name', () {
      expect(linuxDeviceName('archlinux'), 'linux-archlinux');
      expect(linuxDeviceName(''), 'linux');
      expect(linuxDeviceName(' my box!\n'), 'linux-mybox');
      expect(linuxDeviceName('a' * 100).length, 64);
      expect(PlatformCaps.android.deviceName, 'pixel');
    });

    test('a lock that is off never locks', () {
      final off = TerminalLock(enabled: false);
      expect(off.locked, isFalse);
      final on = TerminalLock();
      expect(on.locked, isTrue); // cold start
    });

    test('no PDF renderer: the preview gets a plain failure', () async {
      await expectLater(
        const NoPdfPages().open('/tmp/x.pdf'),
        throwsA(
          isA<PdfProblem>().having(
            (p) => p.kind,
            'kind',
            PdfProblemKind.failed,
          ),
        ),
      );
    });
  });

  group('the Linux app (L1)', () {
    testWidgets('no Terminal, Files, Clipboard or Mirroring by default', (
      t,
    ) async {
      await pumpDelve(t, caps: _linux);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      for (final label in ['Chats', 'Dashboard', 'More']) {
        expect(_navLabel(label), findsOneWidget, reason: label);
      }
      expect(_navLabel('Terminal'), findsNothing);
      expect(_navLabel('Files'), findsNothing);

      await t.tap(_navLabel('More'));
      await t.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Clipboard'), findsNothing);
      expect(find.text('Mirroring'), findsNothing);
      expect(find.byKey(const Key('dashboard.clipboard')), findsNothing);
    });

    testWidgets('Settings: no notifications; the desktop tools switch shows '
        'Terminal and Files and is remembered', (t) async {
      final env = await pumpDelve(t, caps: _linux);
      await t.tap(_navLabel('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();

      final toggle = find.byKey(const Key('settings.desktopTools'));
      await t.scrollUntilVisible(toggle, 200, scrollable: _settingsList);
      expect(find.text('NOTIFICATIONS'), findsNothing);
      expect(find.text('TERMINAL'), findsNothing);
      expect(t.widget<Switch>(toggle).value, isFalse);

      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(t.widget<Switch>(toggle).value, isTrue);
      expect(await env.terminal.store.read(kDesktopToolsKey), '1');
      await t.scrollUntilVisible(
        find.text('TERMINAL'),
        200,
        scrollable: _settingsList,
      );

      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(_navLabel('Terminal'), findsOneWidget);
      expect(_navLabel('Files'), findsOneWidget);
      expect(find.text('Clipboard'), findsOneWidget);
      expect(find.text('Mirroring'), findsNothing);
    });

    testWidgets('the stored switch shows the tools at start', (t) async {
      await pumpDelve(
        t,
        caps: _linux,
        before: (env) => env.terminal.store.write(kDesktopToolsKey, '1'),
      );
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(_navLabel('Terminal'), findsOneWidget);
    });

    testWidgets('the phone keeps everything and has no switch', (t) async {
      await pumpDelve(t);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await t.tap(_navLabel('More'));
      await t.pumpAndSettle();
      expect(find.text('Clipboard'), findsOneWidget);
      expect(find.text('Mirroring'), findsOneWidget);
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('TERMINAL'),
        200,
        scrollable: _settingsList,
      );
      expect(find.byKey(const Key('settings.desktopTools')), findsNothing);
    });

    testWidgets('pairing says "this computer"', (t) async {
      await pumpDelve(t, paired: false, caps: _linux);
      expect(find.text('Pair this computer'), findsOneWidget);
      expect(find.text('Pair this phone'), findsNothing);
    });

    testWidgets('the "+" sheet has no Camera on the desktop', (t) async {
      Future<void> open(PlatformCaps caps) async {
        await t.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [platformCapsProvider.overrideWithValue(caps)],
            child: MaterialApp(
              theme: buildDelveTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (c) => TextButton(
                    onPressed: () => showAttachSourceSheet(c),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
      }

      await open(_linux);
      expect(find.byKey(const Key('attach.photos')), findsOneWidget);
      expect(find.byKey(const Key('attach.file')), findsOneWidget);
      expect(find.byKey(const Key('attach.camera')), findsNothing);

      await open(PlatformCaps.android);
      expect(find.byKey(const Key('attach.camera')), findsOneWidget);
    });
  });

  group('Linux downloads (L1)', () {
    late Directory home;
    late List<Uri> opened;
    late LinuxDeviceFiles files;

    setUp(() {
      home = Directory.systemTemp.createTempSync('delve-home');
      opened = [];
      files = LinuxDeviceFiles(
        open: (uri) async {
          opened.add(uri);
          return true;
        },
        environment: {'HOME': home.path},
      );
    });
    tearDown(() => home.deleteSync(recursive: true));

    Future<String> scratch(String name, String text) async {
      final f = File('${await files.scratchDir()}/$name');
      await f.writeAsString(text);
      return f.path;
    }

    test(
      'publish moves into ~/Downloads/Delve, a taken name gets a number',
      () async {
        expect(await files.scratchDir(), '${home.path}/.cache/delve/scratch');
        final a = await files.publish(
          await scratch('a.txt', 'one'),
          'notes.txt',
          'text/plain',
        );
        final b = await files.publish(
          await scratch('b.txt', 'two'),
          'notes.txt',
          'text/plain',
        );
        final root = '${home.path}/Downloads/Delve';
        expect(Uri.parse(a).toFilePath(), '$root/notes.txt');
        expect(Uri.parse(b).toFilePath(), '$root/notes (2).txt');
        expect(File('$root/notes (2).txt').readAsStringSync(), 'two');
        expect(
          File('${home.path}/.cache/delve/scratch/a.txt').existsSync(),
          isFalse,
        );

        final c = await files.publish(
          await scratch('c.log', 'three'),
          'c.log',
          'text/plain',
          folder: 'proj/sub',
        );
        expect(Uri.parse(c).toFilePath(), '$root/proj/sub/c.log');
        expect(await files.freeFolder('proj'), 'proj (2)');
        expect(await files.freeFolder('other'), 'other');
      },
    );

    test('open and share go to the desktop; share opens the folder', () async {
      final uri = await files.publish(
        await scratch('x.zip', 'zip'),
        'x.zip',
        'application/zip',
      );
      expect(await files.open(uri, 'application/zip'), isTrue);
      await files.share(uri, 'application/zip');
      expect(opened.first.toFilePath(), endsWith('/Downloads/Delve/x.zip'));
      expect(opened.last.toFilePath(), '${home.path}/Downloads/Delve/');
    });

    test('the XDG download directory', () async {
      expect(linuxDownloadDir('/home/a', null), '/home/a/Downloads');
      expect(
        linuxDownloadDir('/home/a', 'XDG_DOWNLOAD_DIR="\$HOME/Letöltések"\n'),
        '/home/a/Letöltések',
      );
      expect(
        linuxDownloadDir('/home/a', '# x\nXDG_DOWNLOAD_DIR="\$HOME/"\n'),
        '/home/a/Downloads',
      );
      expect(
        linuxDownloadDir('/home/a', 'XDG_DOWNLOAD_DIR="/data/dl/"'),
        '/data/dl',
      );

      Directory('${home.path}/.config').createSync();
      File(
        '${home.path}/.config/user-dirs.dirs',
      ).writeAsStringSync('XDG_DOWNLOAD_DIR="\$HOME/Letöltések"\n');
      final uri = await files.publish(
        await scratch('y.txt', 'y'),
        'y.txt',
        'text/plain',
      );
      expect(
        Uri.parse(uri).toFilePath(),
        '${home.path}/Letöltések/Delve/y.txt',
      );
    });

    test('numbered names', () {
      expect(numberedName('a.txt', 1), 'a.txt');
      expect(numberedName('a.txt', 2), 'a (2).txt');
      expect(numberedName('archive.tar.gz', 3), 'archive.tar (3).gz');
      expect(numberedName('.bashrc', 2), '.bashrc (2)');
      expect(numberedName('README', 2), 'README (2)');
    });
  });

  group('images without the plugin (L1)', () {
    Uint8List jpeg(int w, int h) =>
        img.encodeJpg(img.Image(width: w, height: h), quality: 90);

    test('a large photo: the longer side becomes 1536, JPEG', () {
      final out = dartPrepare(jpeg(4000, 3000));
      expect(out, isA<DartPrepOk>());
      final back = img.decodeJpg((out as DartPrepOk).bytes)!;
      expect((back.width, back.height), (1536, 1152));
    });

    test('a portrait photo scales by its height', () {
      final out = dartPrepare(jpeg(1200, 2400)) as DartPrepOk;
      final back = img.decodeJpg(out.bytes)!;
      expect((back.width, back.height), (768, 1536));
    });

    test('a small PNG keeps its size and becomes a JPEG', () {
      final png = img.encodePng(img.Image(width: 300, height: 200));
      final out = dartPrepare(png) as DartPrepOk;
      expect(out.bytes.sublist(0, 2), [0xFF, 0xD8]);
      final back = img.decodeJpg(out.bytes)!;
      expect((back.width, back.height), (300, 200));
    });

    test('not an image, and too large', () {
      expect(
        dartPrepare(Uint8List.fromList([1, 2, 3, 4])),
        isA<DartPrepUnreadable>(),
      );
      expect(
        dartPrepare(jpeg(2000, 1500), maxBytes: 10),
        isA<DartPrepTooLarge>(),
      );
    });

    test('in an isolate, with the usual errors', () async {
      final bytes = await const DartImagePrep().prepare(jpeg(3000, 2000));
      expect(img.decodeJpg(bytes)!.width, 1536);
      await expectLater(
        const DartImagePrep().prepare(Uint8List.fromList([0, 1])),
        throwsA(isA<ImagePrepFailed>()),
      );
    });
  });
}
