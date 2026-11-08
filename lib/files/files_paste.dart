part of 'files_service.dart';

/// Copy or Move waiting for Paste (23e): survives folder and tab changes,
/// cleared by Paste, Cancel or after [FilesTiming.clipLife].
class FilesClip {
  const FilesClip({
    required this.items,
    required this.cut,
    required this.from,
    required this.at,
  });

  final List<RemoteEntry> items;

  /// Move rather than Copy.
  final bool cut;

  /// The folder the items are in.
  final String from;
  final DateTime at;
}

/// Why Paste can't go into a folder.
enum PasteProblem {
  /// Move into the folder the items are in: nothing would change.
  sameFolder,

  /// A folder into itself, or into a folder inside it.
  intoItself,
}

/// What a Paste did: moved at once (one filesystem), queued (copies, and
/// moves across filesystems), skipped, failed (the name and why).
class PasteResult {
  const PasteResult({
    this.moved = 0,
    this.queued = const [],
    this.skipped = 0,
    this.failed = const [],
  });

  final int moved;
  final List<Transfer> queued;
  final int skipped;
  final List<(String, RemoteFsError)> failed;
}

/// What a multi-item trash did: the items (for Undo), the entries with no
/// trash (they can only be deleted for good), the ones that failed.
class TrashResult {
  const TrashResult({
    this.items = const [],
    this.noTrash = const [],
    this.failed = const [],
  });

  final List<TrashItem> items;
  final List<RemoteEntry> noTrash;
  final List<(String, Object)> failed;
}

/// F3: several items at once, Copy / Move → Paste, copies on the desktop
/// and folder downloads.
extension FilesPaste on FilesService {
  // ---------------------------------------------------------------- clip

  FilesClip? get clip => _clip;

  /// Copy ([cut] false) or Move [items] (all from one folder).
  void setClip(List<RemoteEntry> items, {required bool cut}) {
    if (items.isEmpty) return;
    terminal.lock.keepAlive();
    _clip = FilesClip(
      items: List.unmodifiable(items),
      cut: cut,
      from: parentPath(items.first.path),
      at: _now(),
    );
    _clipTimer?.cancel();
    _clipTimer = Timer(timing.clipLife, clearClip);
    _notify();
  }

  void clearClip() {
    _clipTimer?.cancel();
    _clipTimer = null;
    if (_clip == null) return;
    _clip = null;
    _notify();
  }

  /// Why the clip can't be pasted into [dir] (null: it can).
  PasteProblem? pasteProblem(String dir) {
    final c = _clip;
    if (c == null) return null;
    if (c.cut && dir == c.from) return PasteProblem.sameFolder;
    for (final e in c.items) {
      // a link is copied as a link: no loop
      if (e.isDir && !e.isLink && (dir == e.path || isInside(dir, e.path))) {
        return PasteProblem.intoItself;
      }
    }
    return null;
  }

  /// The clip's items whose name is taken in [here] (the entries of
  /// [dir]). A copy into its own folder has none: each gets the next free
  /// name.
  List<RemoteEntry> pasteConflicts(String dir, Map<String, RemoteEntry> here) {
    final c = _clip;
    if (c == null || (!c.cut && c.from == dir)) return const [];
    return [
      for (final e in c.items)
        if (here.containsKey(e.name)) e,
    ];
  }

  /// Pastes the clip into [dir] (its entries: [here]) and clears it.
  /// Copies are queued; a move on one filesystem is a rename now, across
  /// filesystems it is queued (copy, then the source is deleted). Taken
  /// names follow [choices] by name (Keep both when missing; a folder here
  /// is never replaced).
  Future<PasteResult> paste(
    String dir, {
    required Map<String, RemoteEntry> here,
    Map<String, ConflictChoice> choices = const {},
  }) async {
    final c = _clip;
    if (c == null || pasteProblem(dir) != null) return const PasteResult();
    final fs = await _need();
    clearClip();
    final copyHere = !c.cut && c.from == dir;
    final taken = {...here.keys};
    final queued = <Transfer>[];
    final failed = <(String, RemoteFsError)>[];
    var moved = 0;
    var skipped = 0;
    for (final e in c.items) {
      var name = e.name;
      var replace = false;
      if (copyHere) {
        name = freeName(name, taken.contains);
      } else if (taken.contains(name)) {
        switch (choices[name] ?? ConflictChoice.keepBoth) {
          case ConflictChoice.skip:
            skipped++;
            continue;
          case ConflictChoice.replace:
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
      final target = joinPath(dir, name);
      if (c.cut) {
        try {
          if (await _write(
            fs,
            () => _moveNow(fs, e, target, replace: replace),
          )) {
            moved++;
            continue;
          }
        } on RemoteFsError catch (err) {
          failed.add((e.name, err));
          continue;
        }
      }
      queued.add(
        _enqueue(
          Transfer._(
            _nextTransfer++,
            e,
            kind: c.cut ? TransferKind.move : TransferKind.copy,
            replace: replace,
            target: target,
          ),
        ),
      );
    }
    if (moved > 0) {
      await _refreshIf(dir);
      // the folder they left, when it is the one on screen
      await _refreshIf(c.from);
    }
    return PasteResult(
      moved: moved,
      queued: queued,
      skipped: skipped,
      failed: failed,
    );
  }

  /// A move on one filesystem: true when [e] is at [target] now; false
  /// when it is on another filesystem (the move is a copy then).
  Future<bool> _moveNow(
    RemoteFs fs,
    RemoteEntry e,
    String target, {
    required bool replace,
  }) async {
    final dir = parentPath(target);
    final there = await fs.lstat(target);
    if (there != null && !replace) {
      // something got the name meanwhile: the next free one
      final names = {for (final x in await fs.list(dir)) x.name};
      return _moveNow(
        fs,
        e,
        joinPath(dir, freeName(baseName(target), names.contains)),
        replace: false,
      );
    }
    // with a file to replace: under a hidden name first, so the one here
    // stays when the move turns out to cross filesystems
    final to = there == null
        ? target
        : joinPath(dir, partName(baseName(target), _nextTransfer++));
    try {
      await fs.rename(e.path, to);
    } on RemoteFsError catch (err) {
      if (err.failure == FsFailure.crossDevice) return false;
      rethrow;
    }
    if (there != null) {
      await _putAway(fs, there, target);
      await fs.rename(to, target);
    }
    return true;
  }

  /// The file at [path] makes room for a new one: to the trash (inside
  /// home), else deleted.
  Future<void> _putAway(RemoteFs fs, RemoteEntry there, String path) async {
    if (canTrash(there)) {
      try {
        await _trash(fs, path, there);
        return;
      } on NoTrash {
        // another filesystem inside home: deleted below
      }
    }
    await fs.deleteTree(path);
  }

  // ------------------------------------------------------- desktop copy

  void _progress() {
    final now = _now();
    if (now.difference(_progressAt).inMilliseconds < 200) return;
    _progressAt = now;
    _notify();
  }

  /// A copy (or a move across filesystems) on the desktop: `cp -a` into a
  /// hidden `.name.<id>.part` next to the target, measured with `du`; then
  /// the rename, and for a move the source deleted.
  Future<void> _runCopy(RemoteFs fs, Transfer t) async {
    t.state = TransferState.running;
    t.startedAt = _now();
    t.bytes = 0;
    _notify();
    final dir = parentPath(t.remotePath);
    final part = joinPath(dir, partName(t.entry.name, t.id));
    var made = false;
    try {
      t._size = await fs.diskUsage(t.entry.path);
      if (!t._cancel) {
        // a leftover of an earlier try
        if (await fs.lstat(part) != null) await fs.deleteTree(part);
        final job = fs.copy(t.entry.path, part);
        made = true;
        var over = false;
        final watch = job.done.whenComplete(() {
          over = true;
        });
        unawaited(watch.catchError((Object _) {}));
        while (!over) {
          await Future.any([
            watch.catchError((Object _) {}),
            Future<void>.delayed(timing.copyPoll),
          ]);
          if (over) break;
          if (t._cancel) {
            await job.cancel();
            break;
          }
          final n = await fs.diskUsage(part);
          if (n != null) {
            t.bytes = n;
            _progress();
          }
        }
        // throws when it failed (not after a cancel)
        await job.done;
      }
      if (t._cancel) {
        t.state = TransferState.cancelled;
      } else {
        final there = await fs.lstat(t.remotePath);
        if (there != null) {
          if (t.replace && !there.isDir) {
            await _putAway(fs, there, t.remotePath);
          } else {
            final names = {for (final e in await fs.list(dir)) e.name};
            t.remotePath = joinPath(
              dir,
              freeName(baseName(t.remotePath), names.contains),
            );
          }
        }
        await fs.rename(part, t.remotePath);
        made = false;
        if (t._size case final n?) t.bytes = n;
        if (t.kind == TransferKind.move) {
          try {
            await fs.deleteTree(t.entry.path);
          } on RemoteFsError catch (e) {
            if (e.failure == FsFailure.unreachable) rethrow;
            t.warning = FilesOps._errorText(e);
          }
        }
        t.state = TransferState.done;
      }
    } on RemoteFsError catch (e) {
      t.state = TransferState.failed;
      t.error = FilesOps._errorText(e);
      if (e.failure == FsFailure.unreachable && identical(_fs, fs)) {
        unawaited(_lost(e.detail));
      }
    } on Object catch (e) {
      t.state = TransferState.failed;
      t.error = '$e';
    } finally {
      t.endedAt = _now();
      if (made) unawaited(fs.deleteTree(part).catchError((Object _) {}));
    }
    _notify();
    if (t.state == TransferState.done) {
      unawaited(_refreshIf(dir));
      if (t.kind == TransferKind.move) {
        unawaited(_refreshIf(parentPath(t.entry.path)));
      }
    }
    if (t.state == TransferState.done || t.state == TransferState.failed) {
      _finished.add(t);
    }
  }

  // ----------------------------------------------------- folder download

  /// A folder to Downloads/Delve/‹name›/… with its folders: first read
  /// (links and special files left out, never followed), then each file.
  Future<void> _runFolder(RemoteFs fs, Transfer t) async {
    t.state = TransferState.running;
    t.startedAt = _now();
    t
      ..bytes = 0
      ..files = null
      ..found = 0
      ..filesDone = 0
      ..unreadable = 0
      ..leftOut = 0
      ..warning = null;
    t._size = null;
    _notify();
    Directory? scratch;
    try {
      // (folder below the top, the file)
      final files = <(String, RemoteEntry)>[];
      var total = 0;
      final dirs = Queue<(String, String)>()..add(('', t.entry.path));
      while (dirs.isNotEmpty && !t._cancel) {
        final (rel, path) = dirs.removeFirst();
        final List<RemoteEntry> list;
        try {
          list = await fs.list(path);
        } on RemoteFsError catch (e) {
          if (rel.isEmpty || e.failure == FsFailure.unreachable) rethrow;
          t.unreadable++;
          continue;
        }
        for (final e in sortEntries(list, SortKey.name)) {
          if (e.isLink || e.kind == EntryKind.other) {
            t.leftOut++;
          } else if (e.isDir) {
            final name = phoneName(e.name);
            dirs.add((rel.isEmpty ? name : '$rel/$name', e.path));
          } else {
            files.add((rel, e));
            total += e.size ?? 0;
          }
        }
        t.found = files.length;
        _progress();
      }
      if (!t._cancel) {
        t.files = files.length;
        t._size = total;
        _notify();
        final top = await device.freeFolder(phoneName(t.entry.name));
        t.phoneFolder = top;
        scratch = Directory('${await device.scratchDir()}/dl/${t.id}')
          ..createSync(recursive: true);
        var before = 0;
        for (final (rel, e) in files) {
          if (t._cancel) break;
          final file = File('${scratch.path}/${t.filesDone + t.unreadable}');
          final sink = file.openWrite();
          var got = 0;
          var ok = true;
          try {
            got = await fs.download(
              e.path,
              sink,
              onProgress: (n) {
                t.bytes = before + n;
                _progress();
              },
              cancelled: () => t._cancel,
            );
          } on RemoteFsError catch (err) {
            if (err.failure == FsFailure.unreachable) rethrow;
            ok = false;
          } finally {
            await sink.close();
          }
          if (t._cancel) break;
          if (ok) {
            await device.publish(
              file.path,
              phoneName(e.name),
              mimeOf(e.name),
              folder: rel.isEmpty ? top : '$top/$rel',
            );
            t.filesDone++;
          } else {
            t.unreadable++;
            if (file.existsSync()) file.deleteSync();
          }
          before += ok ? got : e.size ?? 0;
          t.bytes = before;
          _progress();
        }
      }
      t.state = t._cancel ? TransferState.cancelled : TransferState.done;
    } on RemoteFsError catch (e) {
      t.state = TransferState.failed;
      t.error = FilesOps._errorText(e);
      if (e.failure == FsFailure.unreachable && identical(_fs, fs)) {
        unawaited(_lost(e.detail));
      }
    } on Object catch (e) {
      t.state = TransferState.failed;
      t.error = '$e';
    } finally {
      t.endedAt = _now();
      try {
        if (scratch != null && scratch.existsSync()) {
          scratch.deleteSync(recursive: true);
        }
      } on Object {
        // the cache is cleaned by Android
      }
    }
    _notify();
    if (t.state == TransferState.done || t.state == TransferState.failed) {
      _finished.add(t);
    }
  }

  // ------------------------------------------------------- several items

  /// Queues each file and folder of [entries] for Downloads/Delve (broken
  /// links and special files are left out); returns the transfers.
  List<Transfer> downloadAll(List<RemoteEntry> entries) => [
    for (final e in entries)
      if (e.kind != EntryKind.other) download(e),
  ];

  /// Moves [entries] to the trash, one by one.
  Future<TrashResult> moveAllToTrash(List<RemoteEntry> entries) async {
    final fs = await _need();
    final items = <TrashItem>[];
    final noTrash = <RemoteEntry>[];
    final failed = <(String, Object)>[];
    for (final e in entries) {
      if (!canTrash(e)) {
        noTrash.add(e);
        continue;
      }
      try {
        items.add(await _write(fs, () => _trash(fs, e.path, e)));
      } on NoTrash {
        noTrash.add(e);
      } on RemoteFsError catch (err) {
        failed.add((e.name, err));
        if (err.failure == FsFailure.unreachable) break;
      }
    }
    for (final dir in {for (final e in entries) parentPath(e.path)}) {
      await _refreshIf(dir);
    }
    return TrashResult(items: items, noTrash: noTrash, failed: failed);
  }

  /// Puts [items] back (a taken name: Keep both); returns the failures.
  Future<List<(String, Object)>> restoreAll(List<TrashItem> items) async {
    final failed = <(String, Object)>[];
    for (final i in items) {
      try {
        await restore(i, onConflict: ConflictChoice.keepBoth);
      } on RemoteFsError catch (e) {
        failed.add((i.name, e));
        if (e.failure == FsFailure.unreachable) break;
      }
    }
    return failed;
  }

  /// Deletes [entries] for good; returns the failures.
  Future<List<(String, Object)>> deleteAllPermanently(
    List<RemoteEntry> entries,
  ) async {
    final fs = await _need();
    final failed = <(String, Object)>[];
    for (final e in entries) {
      try {
        await _write(fs, () => fs.deleteTree(e.path));
      } on RemoteFsError catch (err) {
        failed.add((e.name, err));
        if (err.failure == FsFailure.unreachable) break;
      }
    }
    for (final dir in {for (final e in entries) parentPath(e.path)}) {
      await _refreshIf(dir);
    }
    return failed;
  }
}
