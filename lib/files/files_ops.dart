part of 'files_service.dart';

/// What an upload does with a name that is taken in its folder (23f).
enum ConflictChoice {
  skip,

  /// The file there goes to the trash once the new one is in place.
  replace,

  /// The new one gets the first free `name (2).ext`.
  keepBoth,
}

/// One item of the desktop's trash (23i).
class TrashItem {
  const TrashItem({
    required this.entry,
    required this.original,
    required this.infoPath,
    this.deleted,
  });

  /// The item in `Trash/files`.
  final RemoteEntry entry;

  /// Where it was deleted from.
  final String original;

  /// Its `Trash/info/*.trashinfo`.
  final String infoPath;

  /// When (the desktop's local time).
  final DateTime? deleted;

  /// The name it had (and gets back).
  String get name => baseName(original);
}

/// The item has no trash (outside the home folder, or another filesystem):
/// it can only be deleted for good (23j).
class NoTrash implements Exception {
  const NoTrash(this.path);

  final String path;

  @override
  String toString() => 'NoTrash: $path';
}

/// The name can't be a file name (empty, `.`, a slash, too long).
class BadName implements Exception {
  const BadName(this.problem);

  final NameProblem problem;
}

/// Writing on the desktop (F2a): new folder, rename, trash and its view,
/// delete for good, uploads.
extension FilesOps on FilesService {
  /// The folder "Save to desktop folder" starts in (the last one used, or
  /// Downloads).
  String? get saveFolder =>
      _saveFolder ?? (_home == null ? null : joinPath(_home!, 'Downloads'));

  /// Is the terminal set up (Files uses its key, host and host key)?
  Future<bool> isSetUp() async {
    await terminal.load();
    return terminal.config.verified;
  }

  /// Where the folder picker opens: [saveFolder], connecting for the home
  /// folder when needed (throws [RemoteFsError] when it can't).
  Future<String> saveStart() async {
    await terminal.load();
    await _loadPrefs();
    if (_saveFolder case final f?) return f;
    final home = _home ?? await (await _need()).home();
    return joinPath(home, 'Downloads');
  }

  /// [saveFolder] without connecting (null: not known yet).
  Future<String?> lastSaveFolder() async {
    await terminal.load();
    await _loadPrefs();
    return saveFolder;
  }

  /// The desktop's home (connecting when needed).
  Future<String> homeFolder() async => _home ?? await (await _need()).home();

  void rememberSaveFolder(String path) {
    _saveFolder = path;
    _savePrefs();
  }

  Future<RemoteFs> _need() async {
    terminal.lock.keepAlive();
    final fs = await _ensure();
    if (fs == null) {
      throw RemoteFsError(FsFailure.unreachable, _problem ?? 'offline');
    }
    return fs;
  }

  /// Runs [op]; a lost connection shows as lost (the state line).
  Future<T> _write<T>(RemoteFs fs, Future<T> Function() op) async {
    try {
      return await op();
    } on RemoteFsError catch (e) {
      if (e.failure == FsFailure.unreachable && identical(_fs, fs)) {
        unawaited(_lost(e.detail));
      }
      rethrow;
    }
  }

  Future<void> _refreshIf(String dir) async {
    if (_path == dir) await refresh();
  }

  static void _check(String name) {
    if (checkName(name) case final p?) throw BadName(p);
  }

  // ---------------------------------------------------------- folders

  /// A new folder [name] in [dir] (the folder on screen when null);
  /// returns its path. Throws [BadName], [RemoteFsError] (`exists`, …).
  Future<String> makeFolder(String name, {String? dir}) async {
    final n = name.trim();
    _check(n);
    final where = dir ?? _path!;
    final fs = await _need();
    final path = joinPath(where, n);
    await _write(fs, () => fs.mkdir(path));
    await _refreshIf(where);
    return path;
  }

  /// [e] gets [name] in its folder; a taken name is refused
  /// ([FsFailure.exists]) – the SFTP rename would replace it.
  Future<void> renameEntry(RemoteEntry e, String name) async {
    final n = name.trim();
    _check(n);
    if (n == e.name) return;
    final fs = await _need();
    final dir = parentPath(e.path);
    final target = joinPath(dir, n);
    await _write(fs, () async {
      if (await fs.lstat(target) != null) {
        throw RemoteFsError(FsFailure.exists, target);
      }
      await fs.rename(e.path, target);
    });
    await _refreshIf(dir);
  }

  // ------------------------------------------------------------ trash

  /// Can [e] go to the trash? Only what is inside the home folder (F0: the
  /// trash is on the home's filesystem; there is no other).
  bool canTrash(RemoteEntry e) {
    final home = _home;
    if (home == null || !isInside(e.path, home)) return false;
    final t = trashDir(home);
    return e.path != t && !isInside(e.path, t);
  }

  Future<void> _ensureDir(RemoteFs fs, String path) async {
    final there = await fs.lstat(path);
    if (there != null) {
      if (!there.isDir) throw RemoteFsError(FsFailure.notADirectory, path);
      return;
    }
    await _ensureDir(fs, parentPath(path));
    try {
      await fs.mkdir(path);
    } on RemoteFsError catch (e) {
      if (e.failure != FsFailure.exists) rethrow;
    }
  }

  /// Moves [e] to the desktop's trash (freedesktop: the `.trashinfo` first,
  /// exclusively, then the rename – a taken name gets `name.2.ext`).
  /// Returns the item (for Undo). Throws [NoTrash] when it can only be
  /// deleted for good.
  Future<TrashItem> moveToTrash(RemoteEntry e) async {
    if (!canTrash(e)) throw NoTrash(e.path);
    final fs = await _need();
    final item = await _write(fs, () => _trash(fs, e.path, e));
    await _refreshIf(parentPath(e.path));
    return item;
  }

  Future<TrashItem> _trash(RemoteFs fs, String path, [RemoteEntry? e]) async {
    final t = trashDir(_home!);
    await _ensureDir(fs, '$t/files');
    await _ensureDir(fs, '$t/info');
    final at = _now();
    final info = utf8.encode(trashInfo(path, at));
    for (var n = 1; n < 1000; n++) {
      final name = trashName(baseName(path), n);
      final infoPath = '$t/info/$name.trashinfo';
      try {
        await fs.writeFile(infoPath, info, exclusive: true);
      } on RemoteFsError catch (e) {
        if (e.failure == FsFailure.exists) continue;
        rethrow;
      }
      final into = '$t/files/$name';
      try {
        // the rename would replace a file left there without its info
        if (await fs.lstat(into) != null) {
          await fs.deleteTree(infoPath);
          continue;
        }
        await fs.rename(path, into);
        final was = e ?? await fs.lstat(into).catchError((Object _) => null);
        return TrashItem(
          entry: RemoteEntry(
            name: name,
            path: into,
            kind: was?.kind ?? EntryKind.file,
            size: was?.size,
            modified: was?.modified,
            mode: was?.mode,
            owner: was?.owner,
          ),
          original: path,
          infoPath: infoPath,
          deleted: DateTime(
            at.year,
            at.month,
            at.day,
            at.hour,
            at.minute,
            at.second,
          ),
        );
      } on RemoteFsError catch (err) {
        await fs.deleteTree(infoPath).catchError((Object _) {});
        // another filesystem (a btrfs subvolume inside the home)
        if (err.failure == FsFailure.crossDevice) throw NoTrash(path);
        rethrow;
      }
    }
    throw RemoteFsError(FsFailure.other, 'no free name in the trash');
  }

  /// Deletes [e] for good (a folder with everything in it).
  Future<void> deletePermanently(RemoteEntry e) async {
    final fs = await _need();
    await _write(fs, () => fs.deleteTree(e.path));
    await _refreshIf(parentPath(e.path));
  }

  /// The trash's items, the last deleted first (an item without its info
  /// file, or an info without its item, is left out).
  Future<List<TrashItem>> trashItems() async {
    final fs = await _need();
    final home = _home ?? await fs.home();
    final t = trashDir(home);
    return _write(fs, () async {
      Future<List<RemoteEntry>> listed(String dir) async {
        try {
          return await fs.list(dir);
        } on RemoteFsError catch (e) {
          if (e.failure == FsFailure.notFound) return const [];
          rethrow;
        }
      }

      final infos = await listed('$t/info');
      final files = {for (final f in await listed('$t/files')) f.name: f};
      const suffix = '.trashinfo';
      final items = await Future.wait(
        infos.where((i) => i.name.endsWith(suffix)).map((i) async {
          final name = i.name.substring(0, i.name.length - suffix.length);
          final f = files[name];
          if (f == null) return null;
          final head = await fs.readHead(i.path, 64 * 1024);
          final info = parseTrashInfo(
            const Utf8Decoder(allowMalformed: true).convert(head),
          );
          if (info == null) return null;
          return TrashItem(
            entry: f,
            original: info.path,
            infoPath: i.path,
            deleted: info.deleted,
          );
        }),
      );
      final out = items.nonNulls.toList()
        ..sort(
          (a, b) =>
              (b.deleted ?? DateTime(0)).compareTo(a.deleted ?? DateTime(0)),
        );
      return out;
    });
  }

  /// The trash's items without reading them (the ⋮ menu's count).
  Future<int?> trashCount() async {
    final fs = _fs;
    final home = _home;
    if (fs == null || home == null) return null;
    return fs.count('${trashDir(home)}/info');
  }

  /// The bytes in the trash (`du`; null when it can't tell).
  Future<int?> trashSize() async {
    final fs = await _need();
    return fs.diskUsage('${trashDir(_home ?? await fs.home())}/files');
  }

  /// Puts [item] back where it was deleted from (the folder made again
  /// if it is gone). A taken name: [onConflict] decides (null: throws
  /// [FsFailure.exists]); returns where it went (null: skipped).
  Future<String?> restore(TrashItem item, {ConflictChoice? onConflict}) async {
    final fs = await _need();
    return _write(fs, () async {
      var target = item.original;
      final dir = parentPath(target);
      final there = await fs.lstat(target);
      if (there != null) {
        switch (onConflict) {
          case null:
            throw RemoteFsError(FsFailure.exists, target);
          case ConflictChoice.skip:
            return null;
          case ConflictChoice.keepBoth:
            final names = {for (final e in await fs.list(dir)) e.name};
            target = joinPath(dir, freeName(item.name, names.contains));
          case ConflictChoice.replace:
            if (canTrash(there)) {
              await _trash(fs, target);
            } else {
              await fs.deleteTree(target);
            }
        }
      }
      await _ensureDir(fs, dir);
      await fs.rename(item.entry.path, target);
      await fs.deleteTree(item.infoPath).catchError((Object _) {});
      await _refreshIf(dir);
      return target;
    });
  }

  /// Deletes one item of the trash for good.
  Future<void> deleteFromTrash(TrashItem item) async {
    final fs = await _need();
    await _write(fs, () async {
      await fs.deleteTree(item.entry.path);
      await fs.deleteTree(item.infoPath).catchError((Object _) {});
    });
  }

  /// Deletes everything in the trash for good.
  Future<void> emptyTrash() async {
    final fs = await _need();
    final t = trashDir(_home ?? await fs.home());
    await _write(fs, () async {
      await fs.deleteTree('$t/files');
      await fs.deleteTree('$t/info');
      await fs.mkdir('$t/files');
      await fs.mkdir('$t/info');
    });
  }

  // ---------------------------------------------------------- uploads

  /// The entries in [dir] by name (an upload's conflicts, its free names).
  Future<Map<String, RemoteEntry>> entriesIn(String dir) async {
    final fs = await _need();
    return _write(
      fs,
      () async => {for (final e in await fs.list(dir)) e.name: e},
    );
  }

  /// The name a phone file gets on the desktop (a slash or a bad name
  /// replaced).
  static String uploadName(String name) {
    final n = name.replaceAll('/', '_').replaceAll('\u0000', '');
    return checkName(n) == null ? n : 'upload';
  }

  /// Queues [files] for [dir]. Names taken there (in [here]) follow
  /// [choices] by name (Keep both when missing); returns the transfers.
  List<Transfer> upload(
    String dir,
    List<PickedAttachment> files, {
    Map<String, RemoteEntry> here = const {},
    Map<String, ConflictChoice> choices = const {},
  }) {
    final taken = {...here.keys};
    final out = <Transfer>[];
    for (final f in files) {
      var name = uploadName(f.name);
      var replace = false;
      if (taken.contains(name)) {
        switch (choices[name] ?? ConflictChoice.keepBoth) {
          case ConflictChoice.skip:
            continue;
          case ConflictChoice.replace:
            // a folder of that name is never replaced
            if (here[name]?.isDir ?? false) {
              name = freeName(name, taken.contains);
            } else {
              replace = true;
            }
          case ConflictChoice.keepBoth:
            name = freeName(name, taken.contains);
        }
      }
      taken.add(name);
      out.add(
        _enqueue(
          Transfer._(
            _nextTransfer++,
            RemoteEntry(
              name: name,
              path: joinPath(dir, name),
              kind: EntryKind.file,
              size: f.size,
            ),
            kind: TransferKind.upload,
            source: f,
            replace: replace,
          ),
        ),
      );
    }
    return out;
  }

  Future<void> _runUpload(RemoteFs fs, Transfer t) async {
    t.state = TransferState.running;
    t.startedAt = _now();
    t.bytes = 0;
    _notify();
    final dir = parentPath(t.remotePath);
    final part = joinPath(dir, '.${t.entry.name}.part');
    var wrote = false;
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      final source = t.source!;
      final bytes = await source.read();
      t._size = bytes.length;
      Stream<Uint8List> chunks() async* {
        const size = 256 * 1024;
        for (var i = 0; i < bytes.length; i += size) {
          yield Uint8List.sublistView(
            bytes,
            i,
            math.min(i + size, bytes.length),
          );
        }
      }

      wrote = true;
      await fs.upload(
        part,
        chunks(),
        onProgress: (n) {
          t.bytes = n;
          final now = _now();
          if (now.difference(lastNotify).inMilliseconds >= 200) {
            lastNotify = now;
            _notify();
          }
        },
        cancelled: () => t._cancel,
      );
      if (t._cancel) {
        t.state = TransferState.cancelled;
      } else {
        final there = await fs.lstat(t.remotePath);
        if (there != null) {
          if (t.replace && !there.isDir) {
            // the old file to the trash (outside home the rename replaces it)
            if (canTrash(there)) await _trash(fs, t.remotePath);
          } else {
            // a file of that name appeared meanwhile: the next free name
            final names = {for (final e in await fs.list(dir)) e.name};
            t.remotePath = joinPath(
              dir,
              freeName(t.entry.name, names.contains),
            );
          }
        }
        await fs.rename(part, t.remotePath);
        wrote = false;
        t.bytes = bytes.length;
        t.state = TransferState.done;
      }
    } on RemoteFsError catch (e) {
      t.state = TransferState.failed;
      t.error = _errorText(e);
      if (e.failure == FsFailure.unreachable && identical(_fs, fs)) {
        unawaited(_lost(e.detail));
      }
    } on Object catch (e) {
      t.state = TransferState.failed;
      t.error = '$e';
    } finally {
      t.endedAt = _now();
      if (wrote) unawaited(fs.deleteTree(part).catchError((Object _) {}));
    }
    _notify();
    if (t.state == TransferState.done) unawaited(_refreshIf(dir));
    if (t.state == TransferState.done || t.state == TransferState.failed) {
      _finished.add(t);
    }
  }

  static String _errorText(RemoteFsError e) => switch (e.failure) {
    FsFailure.unreachable => 'Connection lost',
    FsFailure.denied => 'Permission denied',
    _ => e.detail,
  };
}
