import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:delve/attachments/picker.dart';
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
  DateTime Function()? now,
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
    now: now,
  );
  addTearDown(files.dispose);
  return (files, fakes);
}

Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Waits (real time) until [done] holds – a slow machine (the CI) may need
/// longer than a fixed pause; after [timeout] the next expect tells why.
Future<void> until(
  bool Function() done, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(end)) {
    await settle(10);
  }
}

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
      await until(() => files.entries != null);
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
      await until(() => files.entries != null);
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
      await until(() => files.entries != null);
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
      await until(() => files.entries != null);
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
      await until(() => a.state == TransferState.running);
      expect(a.state, TransferState.running);
      expect(b.state, TransferState.queued);
      expect(files.transferProgress, (1, 3));
      files.cancel(c);
      expect(c.state, TransferState.cancelled);
      fs.holdDownloads!.complete();
      await until(() => b.state == TransferState.done && done.length == 2);
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
      await until(() => files.entries != null);
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
      await until(() => files.entries != null);
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
      await until(() => files.phase == FilesPhase.live);
      expect(files.phase, FilesPhase.live);
      expect(dialer.attempts, 3);
      expect(files.entries, isNotEmpty);
    });

    test('a dropped connection reconnects and lists again', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await until(() => files.entries != null);
      await settle();
      fakes.files.last!.drop();
      await settle(5);
      expect(files.phase, FilesPhase.offline);
      await until(() => files.phase == FilesPhase.live);
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
      await until(() => files.entries != null);
      await settle();
      final first = fakes.files.last!;
      files.setForeground(foreground: false);
      await until(() => first.closed && files.phase == FilesPhase.idle);
      expect(first.closed, isTrue);
      expect(files.phase, FilesPhase.idle);
      files.setForeground(foreground: true);
      await settle();
      expect(files.phase, FilesPhase.live);
      expect(fakes.files.opened.length, 2);
    });
  });

  group('writing (F2a)', () {
    Future<(FilesService, FakeRemoteFs)> live({
      DateTime Function()? now,
    }) async {
      final (files, fakes) = await makeService(now: now);
      files.setVisible(visible: true);
      await until(() => files.entries != null);
      await settle();
      return (files, fakes.files.last!);
    }

    List<String> names(FilesService f) => [for (final e in f.entries!) e.name];

    Matcher fails(FsFailure f) =>
        throwsA(isA<RemoteFsError>().having((e) => e.failure, 'failure', f));

    PickedAttachment picked(String name, List<int> bytes) => PickedAttachment(
      kind: 'file',
      name: name,
      size: bytes.length,
      read: () async => Uint8List.fromList(bytes),
    );

    test('a new folder; a rename; taken and bad names are refused', () async {
      final (files, fs) = await live();
      expect(await files.makeFolder(' Projects '), '/home/user/Projects');
      expect(names(files), contains('Projects'));
      expect(fs.tree['/home/user/Projects'], isEmpty);
      await expectLater(files.makeFolder('Projects'), fails(FsFailure.exists));
      await expectLater(
        files.makeFolder('a/b'),
        throwsA(
          isA<BadName>().having((e) => e.problem, 'p', NameProblem.slash),
        ),
      );
      await expectLater(files.makeFolder('..'), throwsA(isA<BadName>()));
      final notes = files.entries!.firstWhere((e) => e.name == 'notes.txt');
      await files.renameEntry(notes, 'todo.txt');
      expect(names(files), contains('todo.txt'));
      expect(names(files), isNot(contains('notes.txt')));
      expect(
        utf8.decode(fs.contents['/home/user/todo.txt']!),
        startsWith('line'),
      );
      // the SFTP rename would replace file2.log: refused before it
      final todo = files.entries!.firstWhere((e) => e.name == 'todo.txt');
      await expectLater(
        files.renameEntry(todo, 'file2.log'),
        fails(FsFailure.exists),
      );
      expect(fs.contents['/home/user/file2.log'], hasLength(2000));
    });

    test('trash: the info first, a second item of the same name, restore, '
        'none outside home or across filesystems', () async {
      final at = DateTime(2026, 11, 5, 21, 7, 3);
      final (files, fs) = await live(now: () => at);
      const t = '/home/user/.local/share/Trash';
      RemoteEntry entry(String name) =>
          files.entries!.firstWhere((e) => e.name == name);
      expect(files.canTrash(entry('notes.txt')), isTrue);
      await files.moveToTrash(entry('notes.txt'));
      expect(names(files), isNot(contains('notes.txt')));
      expect(fs.contents['$t/files/notes.txt'], isNotNull);
      final info = utf8.decode(fs.contents['$t/info/notes.txt.trashinfo']!);
      expect(
        info,
        '[Trash Info]\nPath=/home/user/notes.txt\n'
        'DeletionDate=2026-11-05T21:07:03\n',
      );
      // another notes.txt: notes.2.txt in the trash
      await fs.writeFile(
        '/home/user/notes.txt',
        Uint8List.fromList(utf8.encode('second')),
      );
      await files.refresh();
      await files.moveToTrash(entry('notes.txt'));
      expect(fs.contents['$t/files/notes.2.txt'], isNotNull);
      expect(fs.contents['$t/info/notes.2.txt.trashinfo'], isNotNull);
      final items = await files.trashItems();
      expect(items, hasLength(2));
      expect(items.map((i) => i.original).toSet(), {'/home/user/notes.txt'});
      expect(items.first.deleted, at);
      expect(await files.trashSize(), 18 + 6);
      expect(await files.trashCount(), 2);
      // back where it was; the second finds the name taken
      final first = items.firstWhere((i) => i.entry.name == 'notes.txt');
      final second = items.firstWhere((i) => i.entry.name == 'notes.2.txt');
      expect(await files.restore(first), '/home/user/notes.txt');
      expect(
        utf8.decode(fs.contents['/home/user/notes.txt']!),
        startsWith('line'),
      );
      expect(fs.contents['$t/info/notes.txt.trashinfo'], isNull);
      await expectLater(files.restore(second), fails(FsFailure.exists));
      expect(
        await files.restore(second, onConflict: ConflictChoice.keepBoth),
        '/home/user/notes (2).txt',
      );
      expect(await files.trashItems(), isEmpty);
      // a folder deleted from a folder that is gone: made again
      await files.open('/home/user/Documents/hajos');
      await files.moveToTrash(entry('evkonyv'));
      await files.open('/home/user/Documents');
      await files.moveToTrash(entry('hajos'));
      final evkonyv = (await files.trashItems()).firstWhere(
        (i) => i.name == 'evkonyv',
      );
      await files.restore(evkonyv);
      expect(
        fs.contents['/home/user/Documents/hajos/evkonyv/borito.png'],
        hasLength(64),
      );
      // outside home: no trash; deleted for good
      await files.open('/usr/bin');
      final tool = entry('tool1');
      expect(files.canTrash(tool), isFalse);
      await expectLater(files.moveToTrash(tool), throwsA(isA<NoTrash>()));
      await files.deletePermanently(tool);
      expect(names(files), isNot(contains('tool1')));
      // another filesystem inside home: no trash, and no info left behind
      fs.otherDevices.add('/home/user/delve-app');
      await files.open('/home/user/delve-app');
      await expectLater(
        files.moveToTrash(entry('pubspec.yaml')),
        throwsA(isA<NoTrash>()),
      );
      expect(fs.tree['$t/info']!.map((e) => e.name), ['hajos.trashinfo']);
    });

    test('trash: delete one for good, empty it', () async {
      final (files, fs) = await live();
      const t = '/home/user/.local/share/Trash';
      for (final n in ['notes.txt', 'file2.log', 'file10.log']) {
        await files.moveToTrash(files.entries!.firstWhere((e) => e.name == n));
      }
      final items = await files.trashItems();
      await files.deleteFromTrash(
        items.firstWhere((i) => i.name == 'file2.log'),
      );
      expect((await files.trashItems()).map((i) => i.name).toSet(), {
        'notes.txt',
        'file10.log',
      });
      await files.emptyTrash();
      expect(await files.trashItems(), isEmpty);
      expect(fs.tree['$t/files'], isEmpty);
      expect(fs.tree['$t/info'], isEmpty);
    });

    test('upload: skip, replace (the old one to the trash), keep both; '
        'a .part file renamed at the end; cancel', () async {
      final (files, fs) = await live();
      final done = <Transfer>[];
      final sub = files.finished.listen(done.add);
      addTearDown(sub.cancel);
      final here = await files.entriesIn('/home/user');
      final transfers = files.upload(
        '/home/user',
        [
          picked('notes.txt', utf8.encode('new notes')),
          picked('file2.log', utf8.encode('new log')),
          picked('file10.log', utf8.encode('skipped')),
          picked('photo.jpg', List.filled(600 * 1024, 3)),
          picked('photo.jpg', [1, 2]),
        ],
        here: here,
        choices: const {
          'notes.txt': ConflictChoice.keepBoth,
          'file2.log': ConflictChoice.replace,
          'file10.log': ConflictChoice.skip,
        },
      );
      expect(transfers.map((t) => t.name), [
        'notes (2).txt',
        'file2.log',
        'photo.jpg',
        'photo (2).jpg',
      ]);
      await until(() => done.length == 4);
      expect(transfers.map((t) => t.state).toSet(), {TransferState.done});
      expect(
        utf8.decode(fs.contents['/home/user/notes (2).txt']!),
        'new notes',
      );
      expect(
        utf8.decode(fs.contents['/home/user/notes.txt']!),
        startsWith('line'),
      );
      expect(utf8.decode(fs.contents['/home/user/file2.log']!), 'new log');
      expect(
        fs.contents['/home/user/.local/share/Trash/files/file2.log'],
        hasLength(2000),
      );
      expect(fs.contents['/home/user/file10.log'], isNull);
      expect(fs.contents['/home/user/photo.jpg'], hasLength(600 * 1024));
      expect(transfers[2].bytes, 600 * 1024);
      expect(fs.contents['/home/user/photo (2).jpg'], [1, 2]);
      expect(fs.contents.keys.where((k) => k.endsWith('.part')), isEmpty);
      await until(() => names(files).contains('photo (2).jpg'));
      // cancel: no file, no .part
      fs.holdUploads = Completer<void>();
      final [c] = files.upload('/home/user', [
        picked('big.bin', [1, 2, 3]),
      ]);
      await until(() => c.state == TransferState.running);
      files.cancel(c);
      fs.holdUploads!.complete();
      await until(() => c.state == TransferState.cancelled);
      await settle();
      expect(fs.contents.keys.where((k) => k.contains('big.bin')), isEmpty);
      // a denied folder: failed, retried later
      fs.denied.add('/tmp');
      final [d] = files.upload('/tmp', [
        picked('x.txt', [1]),
      ]);
      await until(() => d.state == TransferState.failed);
      await settle();
      expect(d.error, 'Permission denied');
      expect(done.last.id, d.id);
    });

    test('save-to folder: Downloads first, then the last one used', () async {
      final (files, fakes) = await makeService();
      files.setVisible(visible: true);
      await until(() => files.entries != null);
      expect(files.saveFolder, '/home/user/Downloads');
      files.rememberSaveFolder('/home/user/Documents');
      await settle();
      final raw = await fakes.store.read(FilesService.prefsKey);
      expect(raw, contains('"saveTo":"/home/user/Documents"'));
      expect(files.saveFolder, '/home/user/Documents');
    });

    test('names: free names, extensions, trash info round trip', () {
      expect(keepBothName('a.tar.gz', 2), 'a.tar (2).gz');
      expect(keepBothName('.zshrc', 3), '.zshrc (3)');
      expect(trashName('photo.jpg', 2), 'photo.2.jpg');
      expect(trashName('photo.jpg', 1), 'photo.jpg');
      expect(freeName('x.txt', {'x.txt', 'x (2).txt'}.contains), 'x (3).txt');
      expect(checkName(''), NameProblem.empty);
      expect(checkName('a' * 256), NameProblem.tooLong);
      expect(checkName('é' * 128), NameProblem.tooLong);
      expect(checkName('ok name.txt'), isNull);
      expect(
        encodeTrashPath('/home/u/Árvíz tűrő!.txt'),
        '/home/u/%C3%81rv%C3%ADz%20t%C5%B1r%C5%91%21.txt',
      );
      final info = parseTrashInfo(
        trashInfo('/home/u/a b/ő.txt', DateTime(2026, 1, 2, 3, 4, 5)),
      )!;
      expect(info.path, '/home/u/a b/ő.txt');
      expect(info.deleted, DateTime(2026, 1, 2, 3, 4, 5));
      expect(parseTrashInfo('[Other]\nPath=/x\n'), isNull);
      expect(isInside('/home/user/x', '/home/user'), isTrue);
      expect(isInside('/home/user', '/home/user'), isFalse);
      expect(isInside('/home/username', '/home/user'), isFalse);
    });
  });
}
