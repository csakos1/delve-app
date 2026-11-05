import 'dart:async';
import 'dart:convert';

import 'package:delve/files/files_service.dart';
import 'package:delve/files/remote_fs.dart';
import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/files_fakes.dart';
import 'support/terminal_fakes.dart';

Future<(FilesService, TerminalFakes)> makeService({
  bool setUp = true,
  FakeFilesDialer? dialer,
}) async {
  final fakes = TerminalFakes(files: dialer);
  if (setUp) await fakes.setUpDone();
  final terminal = TerminalService(
    secrets: TerminalSecrets(fakes.store),
    dialer: fakes.dialer,
    biometrics: fakes.biometrics,
    defaultHost: 'archlinux.example.ts.net',
    timing: fakes.timing,
  );
  addTearDown(terminal.dispose);
  final files = FilesService(
    terminal: terminal,
    dialer: fakes.files,
    device: fakes.device,
    timing: fastFilesTiming,
  );
  addTearDown(files.dispose);
  return (files, fakes);
}

Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('paths', () {
    test('normalize, parent, base, segments, tilde', () {
      expect(normalizePath('/a//b/./c/../d/'), '/a/b/d');
      expect(normalizePath('../x', from: '/home/user'), '/home/x');
      expect(normalizePath('/..'), '/');
      expect(parentPath('/home/user'), '/home');
      expect(parentPath('/home'), '/');
      expect(parentPath('/'), '/');
      expect(baseName('/home/user/a.txt'), 'a.txt');
      expect(joinPath('/', 'boot'), '/boot');
      expect(pathSegments('/home/user'), [
        ('/', '/'),
        ('home', '/home'),
        ('user', '/home/user'),
      ]);
      expect(tildePath('/home/user/Downloads', '/home/user'), '~/Downloads');
      expect(tildePath('/home/user', '/home/user'), '~');
      expect(tildePath('/home/userx', '/home/user'), '/home/userx');
    });

    test('mode strings and ls -l owners', () {
      expect(modeString(0x41ED), 'drwxr-xr-x');
      expect(modeString(0x81A4), '-rw-r--r--');
      expect(modeString(0xA1FF), 'lrwxrwxrwx');
      expect(modeString(0x41C0), 'drwx------');
      expect(modeString(0x89ED), '-rwsr-xr-x'); // setuid
      expect(modeString(0x43FF), 'drwxrwxrwt'); // sticky /tmp
      expect(
        ownerFromLongname(
          'drwxr-xr-x    5 csakos   csakos       4096 Nov  4 22:07 Downloads',
        ),
        'csakos',
      );
      expect(ownerFromLongname('garbage'), isNull);
    });

    test('findmnt output (F0)', () {
      final m = parseMounts(
        '/ btrfs\n/home btrfs\n/var/cache/pacman/pkg btrfs\n'
        '/boot vfat\n/mnt/my\\x20disk ext4\n\n',
      );
      expect(m.map((e) => e.target), [
        '/',
        '/home',
        '/var/cache/pacman/pkg',
        '/boot',
        '/mnt/my disk',
      ]);
      expect(m.last.fsType, 'ext4');
    });
  });

  group('order and types', () {
    test('natural, case-insensitive, folders first', () {
      final list = sortEntries([
        fileEntry('/x/file10.log', 10),
        fileEntry('/x/File2.log', 2000),
        dirEntry('/x/zeta'),
        fileEntry('/x/a.txt', 5),
        dirEntry('/x/Alpha'),
      ], SortKey.name);
      expect(list.map((e) => e.name), [
        'Alpha',
        'zeta',
        'a.txt',
        'File2.log',
        'file10.log',
      ]);
      final bySize = sortEntries(list, SortKey.size, ascending: false);
      expect(bySize.map((e) => e.name).take(3), ['zeta', 'Alpha', 'File2.log']);
      expect(compareNatural('img_009', 'img_10'), lessThan(0));
    });

    test('types, preview kinds, mime', () {
      expect(fileTypeOf(fileEntry('/a.pdf', 1)), FileType.pdf);
      expect(fileTypeOf(fileEntry('/a.PNG', 1)), FileType.image);
      expect(
        fileTypeOf(fileEntry('/usr/bin/ls', 1, mode: 0x81ED)),
        FileType.executable,
      );
      expect(fileTypeOf(fileEntry('/a.bin', 1)), FileType.other);
      expect(previewKindOf(fileEntry('/a.md', 1)), PreviewKind.text);
      expect(previewKindOf(fileEntry('/Makefile', 1)), PreviewKind.text);
      expect(previewKindOf(fileEntry('/a.jpg', 1)), PreviewKind.image);
      expect(previewKindOf(fileEntry('/a.pdf', 1)), PreviewKind.pdf);
      expect(previewKindOf(dirEntry('/a')), PreviewKind.none);
      expect(mimeOf('x.pdf'), 'application/pdf');
      expect(mimeOf('x.unknown'), 'application/octet-stream');
    });

    test('sizes as the design writes them', () {
      expect(sizeText(512), '512 B');
      expect(sizeText(412 * 1024), '412 KB');
      expect(sizeText(14889779), '14.2 MB');
      expect(sizeText(931 * 1024 * 1024 * 1024), '931 GB');
      expect(sizeText((1.2 * 1024 * 1024 * 1024).round()), '1.2 GB');
    });
  });

  group('service', () {
    test('not set up: no connection', () async {
      final (files, fakes) = await makeService(setUp: false);
      files.setVisible(visible: true);
      await settle();
      expect(files.phase, FilesPhase.notSetUp);
      expect(fakes.files.attempts, 0);
    });

    test('lists home, hides dotfiles, counts, mount', () async {
      final (files, _) = await makeService();
      files.setVisible(visible: true);
      await settle();
      expect(files.phase, FilesPhase.live);
      expect(files.path, '/home/user');
      expect(files.entries!.map((e) => e.name), [
        'delve-app',
        'Documents',
        'Downloads',
        'file2.log',
        'file10.log',
        'notes.txt',
      ]);
      expect(files.hiddenCount, 4);
      expect(files.mountHere!.target, '/home');
      expect(files.mountHere!.usedFraction, closeTo(622 / 931, 0.001));
      // a folder's count is asked for when its row is drawn
      final docs = files.entries!.firstWhere((e) => e.name == 'Documents');
      expect(files.countOf(docs), isNull);
      await settle();
      expect(files.countOf(docs), 1);
      files.setShowHidden(show: true);
      expect(files.entries!.length, 10);
    });

    test('folders, symlinks (real path), back, denied', () async {
      final (files, _) = await makeService();
      files.setVisible(visible: true);
      await settle();
      await files.enter(
        files.entries!.firstWhere((e) => e.name == 'Documents'),
      );
      expect(files.path, '/home/user/Documents');
      files.setShowHidden(show: true);
      await files.open('/home/user');
      final steam = files.entries!.firstWhere((e) => e.name == '.steam');
      await files.enter(steam);
      expect(files.path, '/home/user/.local/share/Steam');
      expect(files.back(), isTrue);
      await settle();
      expect(files.path, '/home/user');
      await files.open(
        '/root',
        from: dirEntry('/root', owner: 'root', mode: 0x41C0),
      );
      expect(files.listProblem!.failure, FsFailure.denied);
      expect(files.listProblem!.entry!.owner, 'root');
      await files.open('/nope');
      expect(files.listProblem!.failure, FsFailure.notFound);
    });

    test('sort key and direction; prefs are kept', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await settle();
      files.sortBy(SortKey.size);
      expect(files.ascending, isFalse);
      expect(files.entries!.where((e) => !e.isDir).first.name, 'file2.log');
      files.sortBy(SortKey.size);
      expect(files.ascending, isTrue);
      await settle();
      final raw = await fakes.store.read(FilesService.prefsKey);
      final j = jsonDecode(raw!) as Map<String, Object?>;
      expect(j['sort'], 'size');
      expect(j['path'], '/home/user');
    });

    test('download → Downloads/Delve, one at a time, cancel', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await settle();
      final fs = fakes.files.last!..holdDownloads = Completer<void>();
      final notes = files.entries!.firstWhere((e) => e.name == 'notes.txt');
      final big = files.entries!.firstWhere((e) => e.name == 'file2.log');
      final done = <Transfer>[];
      final sub = files.finished.listen(done.add);
      addTearDown(sub.cancel);
      final a = files.download(notes);
      final b = files.download(big);
      final c = files.download(big);
      await settle();
      expect(a.state, TransferState.running);
      expect(b.state, TransferState.queued);
      expect(files.transferProgress, (1, 3));
      files.cancel(c);
      expect(c.state, TransferState.cancelled);
      fs.holdDownloads!.complete();
      await settle(150);
      expect(a.state, TransferState.done);
      expect(b.state, TransferState.done);
      expect(b.bytes, 2000);
      expect(fakes.device.published.map((p) => p.$1), [
        'notes.txt',
        'file2.log',
      ]);
      expect(
        utf8.decode(fakes.device.published.first.$3),
        'line one\nline two\n',
      );
      expect(fakes.device.published.first.$2, 'text/plain');
      expect(done.map((t) => t.id), [a.id, b.id]);
      expect(await files.openDownload(a), isTrue);
      expect(fakes.device.openedUris.single, a.uri);
      files.clearFinished();
      expect(files.transfers, isEmpty);
    });

    test('text preview: first bytes, binary refused', () async {
      final (files, _) = await makeService();
      files.setVisible(visible: true);
      await settle();
      files.setShowHidden(show: true);
      final notes = files.entries!.firstWhere((e) => e.name == 'notes.txt');
      final (text, cut) = (await files.readText(notes))!;
      expect(text, 'line one\nline two\n');
      expect(cut, isFalse);
      final zshrc = files.entries!.firstWhere((e) => e.name == '.zshrc');
      expect(await files.readText(zshrc), isNull);
    });

    test('image preview: fetched once, a left page stops, cleared', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await settle();
      await files.open('/home/user/Documents/hajos/evkonyv');
      await settle();
      final fs = fakes.files.last!;
      final [_, cover, back] = files.entries!;
      expect((cover.name, back.name), ('borito.png', 'hatlap.png'));
      final seen = <int>[];
      final file = await files.fetchPreview(cover, onProgress: seen.add);
      expect(file.readAsBytesSync(), fs.contents[cover.path]);
      expect(seen.last, 64);
      // the same file again: from the cache, no second transfer
      final again = await files.fetchPreview(cover);
      expect(again.path, file.path);
      expect(fs.downloaded.where((p) => p == cover.path), hasLength(1));
      // a page left while its image comes in: no file, PreviewCancelled
      await expectLater(
        files.fetchPreview(back, cancelled: () => true),
        throwsA(isA<PreviewCancelled>()),
      );
      expect(file.parent.listSync().map((f) => f.path), [file.path]);
      // a new size is a new file
      expect(
        previewFileName(cover),
        isNot(previewFileName(fileEntry(cover.path, 1))),
      );
      await files.clearPreviews();
      expect(file.parent.existsSync(), isFalse);
    });

    test('unreachable → offline with retries, then live', () async {
      final dialer = FakeFilesDialer(sampleFs)
        ..fail.addAll(const [SshUnreachable('timed out'), SshUnreachable('x')]);
      final (files, _) = await makeService(dialer: dialer);
      files.setVisible(visible: true);
      await settle(5);
      expect(files.phase, FilesPhase.offline);
      expect(files.attempt, 1);
      expect(files.nextAttemptAt, isNotNull);
      await settle(200);
      expect(files.phase, FilesPhase.live);
      expect(dialer.attempts, 3);
      expect(files.entries, isNotEmpty);
    });

    test('a dropped connection reconnects and lists again', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await settle();
      fakes.files.last!.drop();
      await settle(5);
      expect(files.phase, FilesPhase.offline);
      await settle(150);
      expect(files.phase, FilesPhase.live);
      expect(fakes.files.opened.length, 2);
      await files.refresh();
      expect(fakes.files.last!.listed, ['/home/user']);
    });

    test('another host key, or a refused key: no retry', () async {
      final dialer = FakeFilesDialer(sampleFs)
        ..fail.add(const SshHostKeyRejected('changed'));
      final (files, _) = await makeService(dialer: dialer);
      files.setVisible(visible: true);
      await settle(100);
      expect(files.phase, FilesPhase.hostKeyChanged);
      expect(dialer.attempts, 1);

      final d2 = FakeFilesDialer(sampleFs)
        ..fail.add(const SshAuthDenied('publickey'));
      final (f2, _) = await makeService(dialer: d2);
      f2.setVisible(visible: true);
      await settle(100);
      expect(f2.phase, FilesPhase.denied);
      await f2.retry();
      expect(f2.phase, FilesPhase.live);
    });

    test('closes in the background, probes on return', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await settle();
      final first = fakes.files.last!;
      files.setForeground(foreground: false);
      await settle(300);
      expect(first.closed, isTrue);
      expect(files.phase, FilesPhase.idle);
      files.setForeground(foreground: true);
      await settle();
      expect(files.phase, FilesPhase.live);
      expect(fakes.files.opened.length, 2);
    });
  });
}
