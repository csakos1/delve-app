import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../terminal/phone_key.dart';
import '../terminal/ssh_link.dart';
import 'remote_fs.dart';

/// Opens a [RemoteFs] on the desktop (tests: a fake).
abstract interface class FilesDialer {
  /// Throws an [SshFailure] when the desktop can't be reached, refuses the
  /// key or shows another host key than the pinned one.
  Future<RemoteFs> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
  });
}

/// dartssh2: its own SSH connection (not a terminal tab's) with the `sftp`
/// subsystem – OpenSSH's sftp-server, protocol 3 (F0).
class SftpFilesDialer implements FilesDialer {
  const SftpFilesDialer([this.dialer = const Dartssh2Dialer()]);

  final Dartssh2Dialer dialer;

  @override
  Future<RemoteFs> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
  }) async {
    final (client, abort) = await dialer.connectClient(
      target,
      key: key,
      verify: verify,
    );
    try {
      final sftp = await client.sftp();
      await sftp.handshake;
      return SftpRemoteFs(client, sftp, abort);
    } on Object catch (e) {
      abort();
      throw SshUnreachable('sftp: $e');
    }
  }
}

class SftpRemoteFs implements RemoteFs {
  SftpRemoteFs(this._client, this._sftp, this._abort);

  final SSHClient _client;
  final SftpClient _sftp;
  final void Function() _abort;
  String? _home;

  /// Symlinks resolved per listing at most (each is a `stat` + `readlink`
  /// round trip, sent together); more stay unresolved links.
  static const maxLinks = 2000;

  @override
  Future<String> home() async {
    final known = _home;
    if (known != null) return known;
    final h = await _guard('.', () => _sftp.absolute('.'));
    _home = h;
    return h;
  }

  @override
  Future<String> realPath(String path) =>
      _guard(path, () => _sftp.absolute(path));

  @override
  Future<List<RemoteEntry>> list(String path) => _guard(path, () async {
    final names = await _sftp.listdir(path);
    final out = <RemoteEntry>[];
    final links = <int>[];
    for (final n in names) {
      if (n.filename == '.' || n.filename == '..') continue;
      final a = n.attr;
      final full = joinPath(path, n.filename);
      final isLink = a.isSymbolicLink;
      if (isLink) links.add(out.length);
      out.add(
        RemoteEntry(
          name: n.filename,
          path: full,
          kind: a.isDirectory
              ? EntryKind.directory
              : a.isFile
              ? EntryKind.file
              : EntryKind.other,
          size: a.size,
          modified: _time(a.modifyTime),
          mode: a.mode?.value,
          owner: ownerFromLongname(n.longname),
          link: isLink ? '' : null,
        ),
      );
    }
    // a link: what it points to (stat follows it) and the target as written
    final resolve = links.take(maxLinks).map((i) async {
      final e = out[i];
      final target = await _sftp.readlink(e.path).catchError((Object _) => '?');
      try {
        final t = await _sftp.stat(e.path);
        out[i] = RemoteEntry(
          name: e.name,
          path: e.path,
          kind: t.isDirectory
              ? EntryKind.directory
              : t.isFile
              ? EntryKind.file
              : EntryKind.other,
          size: t.size,
          modified: _time(t.modifyTime) ?? e.modified,
          mode: e.mode,
          owner: e.owner,
          link: target,
        );
      } on Object {
        out[i] = RemoteEntry(
          name: e.name,
          path: e.path,
          kind: EntryKind.other,
          modified: e.modified,
          mode: e.mode,
          owner: e.owner,
          link: target,
          linkBroken: true,
        );
      }
    });
    await Future.wait(resolve);
    return out;
  });

  @override
  Future<int?> count(String path) async {
    try {
      var n = 0;
      await for (final chunk in _sftp.readdir(path)) {
        for (final e in chunk) {
          if (e.filename != '.' && e.filename != '..') n++;
        }
      }
      return n;
    } on Object {
      return null;
    }
  }

  @override
  Future<Uint8List> readHead(String path, int max) => _guard(path, () async {
    final f = await _sftp.open(path);
    try {
      final b = BytesBuilder(copy: false);
      await for (final chunk in f.read(length: max)) {
        b.add(chunk);
        if (b.length >= max) break;
      }
      return b.takeBytes();
    } finally {
      await f.close();
    }
  });

  @override
  Future<int> download(
    String path,
    StreamSink<List<int>> sink, {
    void Function(int bytes)? onProgress,
    bool Function()? cancelled,
  }) => _guard(path, () async {
    final f = await _sftp.open(path);
    var total = 0;
    try {
      // breaking out of the loop cancels the read (no more requests)
      await for (final chunk in f.read()) {
        if (cancelled?.call() ?? false) break;
        sink.add(chunk);
        total += chunk.length;
        onProgress?.call(total);
      }
      return total;
    } finally {
      await f.close();
    }
  });

  @override
  Future<List<MountInfo>> mounts() async {
    try {
      final r = await _client
          .runWithResult('findmnt -rn -o TARGET,FSTYPE')
          .timeout(kRunTimeout);
      return parseMounts(
        const Utf8Decoder(allowMalformed: true).convert(r.stdout),
      );
    } on Object {
      return const [];
    }
  }

  // ---------------------------------------------------------------- write

  @override
  Future<RemoteEntry?> lstat(String path) async {
    final SftpFileAttrs a;
    try {
      a = await _sftp.stat(path, followLink: false);
    } on SftpStatusError catch (e) {
      if (e.code == SftpStatusCode.noSuchFile) return null;
      return _guard(path, () => throw e);
    } on Object catch (e) {
      return _guard(path, () => throw e);
    }
    final link = a.isSymbolicLink
        ? await _sftp.readlink(path).catchError((Object _) => '?')
        : null;
    return RemoteEntry(
      name: baseName(path),
      path: path,
      kind: a.isDirectory
          ? EntryKind.directory
          : a.isFile
          ? EntryKind.file
          : EntryKind.other,
      size: a.size,
      modified: _time(a.modifyTime),
      mode: a.mode?.value,
      link: link,
    );
  }

  /// A generic SFTP failure that is really "already there".
  Future<Never> _existsOr(String path, SftpStatusError e) async {
    if (e.code == SftpStatusCode.failure && await lstat(path) != null) {
      throw RemoteFsError(FsFailure.exists, path);
    }
    return _guard(path, () => throw e);
  }

  @override
  Future<void> mkdir(String path) async {
    try {
      await _sftp.mkdir(path);
    } on SftpStatusError catch (e) {
      await _existsOr(path, e);
    }
  }

  @override
  Future<void> rename(String from, String to) async {
    try {
      await _sftp.rename(from, to);
    } on SftpStatusError catch (e) {
      // sftp-server answers EXDEV with a generic failure (F0)
      if (e.code == SftpStatusCode.failure) {
        throw RemoteFsError(FsFailure.crossDevice, '$from → $to');
      }
      await _guard(from, () => throw e);
    }
  }

  @override
  Future<void> writeFile(
    String path,
    Uint8List bytes, {
    bool exclusive = false,
  }) async {
    final SftpFile f;
    try {
      f = await _sftp.open(
        path,
        mode: exclusive
            ? SftpFileOpenMode.create |
                  SftpFileOpenMode.exclusive |
                  SftpFileOpenMode.write
            : SftpFileOpenMode.create |
                  SftpFileOpenMode.truncate |
                  SftpFileOpenMode.write,
      );
    } on SftpStatusError catch (e) {
      await _existsOr(path, e);
    }
    await _guard(path, () async {
      try {
        await f.writeBytes(bytes);
      } finally {
        await f.close();
      }
    });
  }

  @override
  Future<int> upload(
    String path,
    Stream<Uint8List> data, {
    void Function(int bytes)? onProgress,
    bool Function()? cancelled,
  }) => _guard(path, () async {
    final f = await _sftp.open(
      path,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write,
    );
    var total = 0;
    try {
      // a cancel ends the stream: what is in flight is still acknowledged
      final source = data.takeWhile((_) => !(cancelled?.call() ?? false));
      await f
          .write(
            source,
            onProgress: (n) {
              total = n;
              onProgress?.call(n);
            },
          )
          .done;
      return total;
    } finally {
      await f.close();
    }
  });

  /// [command] on the desktop; a failure says why (stderr).
  Future<String> _exec(
    String path,
    String command, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final SSHRunResult r;
    try {
      r = await _client.runWithResult(command).timeout(timeout);
    } on Object catch (e) {
      throw RemoteFsError(
        _client.isClosed ? FsFailure.unreachable : FsFailure.other,
        '$e',
      );
    }
    const text = Utf8Decoder(allowMalformed: true);
    if (r.exitCode == 0) return text.convert(r.stdout);
    throw _failure(path, r.exitCode, text.convert(r.stderr));
  }

  @override
  Future<void> deleteTree(String path) async {
    if (path == '/' || path.isEmpty) {
      throw RemoteFsError(FsFailure.denied, path);
    }
    // a big tree (a trash of node_modules) takes a while
    await _exec(
      path,
      'rm -rf -- ${shellQuote(path)}',
      timeout: const Duration(minutes: 5),
    );
  }

  @override
  Future<int?> diskUsage(String path) async {
    try {
      final out = await _exec(path, 'du -sb -- ${shellQuote(path)}');
      return int.tryParse(out.split(RegExp(r'\s')).first);
    } on RemoteFsError {
      return null;
    }
  }

  @override
  Future<(int, int)?> usage(String path) async {
    try {
      final v = await _sftp.statvfs(path);
      final size = v.totalBlocks * v.fundamentalBlockSize;
      final free = v.freeBlocks * v.fundamentalBlockSize;
      return (size, size - free);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> setMode(String path, int mode) => _guard(
    path,
    () => _sftp.setStat(
      path,
      SftpFileAttrs(mode: SftpFileMode.value(mode & 0xFFF)),
    ),
  );

  @override
  Future<List<PathAccess?>?> access(List<String> paths) async {
    try {
      return parseAccess(
        await _exec(paths.join(', '), accessCommand(paths)),
        paths.length,
      );
    } on RemoteFsError catch (e) {
      if (e.failure == FsFailure.unreachable) rethrow;
      return null;
    }
  }

  @override
  Future<void> sync(String path) async {
    try {
      // coreutils `sync FILE` is an fsync of that file (sftp-server's
      // fsync@openssh.com is not in dartssh2)
      await _exec(path, 'sync -- ${shellQuote(path)}');
    } on RemoteFsError {
      // the rename is what makes the save; a missed flush is not an error
    }
  }

  @override
  RemoteJob copy(String from, String to) => _SshJob(
    this,
    from,
    // the shell's pid is cp's after exec: what Cancel kills
    'echo \$\$; exec cp -a -- ${shellQuote(from)} ${shellQuote(to)}',
  );

  @override
  Future<bool> probe(Duration timeout) async {
    if (_client.isClosed) return false;
    try {
      await _client.ping().timeout(timeout);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> get done => _client.done.catchError((Object _) {});

  @override
  Future<void> close() async {
    try {
      await _sftp.close().timeout(const Duration(seconds: 2));
      await _client.close();
    } on Object {
      _abort();
    }
  }

  static RemoteFsError _failure(String path, int? code, String stderr) {
    final err = stderr.trim();
    return RemoteFsError(
      err.contains('Permission denied')
          ? FsFailure.denied
          : err.contains('No such file')
          ? FsFailure.notFound
          : FsFailure.other,
      err.isEmpty ? '$path (exit $code)' : err,
    );
  }

  static DateTime? _time(int? seconds) => seconds == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  Future<T> _guard<T>(String path, Future<T> Function() f) async {
    try {
      return await f();
    } on SftpStatusError catch (e) {
      throw RemoteFsError(switch (e.code) {
        SftpStatusCode.noSuchFile => FsFailure.notFound,
        SftpStatusCode.permissionDenied => FsFailure.denied,
        SftpStatusCode.noConnection ||
        SftpStatusCode.connectionLost => FsFailure.unreachable,
        _ => FsFailure.other,
      }, e.message.isEmpty ? path : '${e.message}: $path');
    } on RemoteFsError {
      rethrow;
    } on Object catch (e) {
      throw RemoteFsError(
        _client.isClosed ? FsFailure.unreachable : FsFailure.other,
        '$e',
      );
    }
  }
}

/// A command on its own exec channel: its first output line is its pid
/// (`echo \$\$; exec …`), which Cancel kills over another channel.
class _SshJob implements RemoteJob {
  _SshJob(this._fs, this._path, String command) {
    _done = _run(command);
  }

  final SftpRemoteFs _fs;
  final String _path;
  late final Future<void> _done;
  final _pid = Completer<int?>();
  SSHSession? _session;
  bool _cancelled = false;

  @override
  Future<void> get done => _done;

  Future<void> _run(String command) async {
    final SSHSession s;
    try {
      s = await _fs._client.execute(command);
    } on Object catch (e) {
      if (!_pid.isCompleted) _pid.complete(null);
      throw RemoteFsError(
        _fs._client.isClosed ? FsFailure.unreachable : FsFailure.other,
        '$e',
      );
    }
    _session = s;
    final head = BytesBuilder(copy: false);
    final out = s.stdout.listen(
      (b) {
        if (_pid.isCompleted) return;
        head.add(b);
        final text = latin1.decode(head.toBytes());
        final nl = text.indexOf('\n');
        if (nl >= 0) _pid.complete(int.tryParse(text.substring(0, nl).trim()));
      },
      onDone: () {
        if (!_pid.isCompleted) _pid.complete(null);
      },
      onError: (Object _) {},
    );
    final err = BytesBuilder(copy: false);
    final errDone = s.stderr
        .listen(err.add, onError: (Object _) {})
        .asFuture<void>()
        .catchError((Object _) {});
    try {
      await s.done;
    } on Object catch (e) {
      if (_cancelled) return;
      throw RemoteFsError(
        _fs._client.isClosed ? FsFailure.unreachable : FsFailure.other,
        '$e',
      );
    } finally {
      await out.cancel();
      if (!_pid.isCompleted) _pid.complete(null);
    }
    await errDone.timeout(const Duration(seconds: 2), onTimeout: () {});
    if (_cancelled) return;
    if (_fs._client.isClosed && s.exitCode == null) {
      throw RemoteFsError(FsFailure.unreachable, 'connection closed: $_path');
    }
    if (s.exitCode == 0) return;
    throw SftpRemoteFs._failure(
      _path,
      s.exitCode,
      const Utf8Decoder(allowMalformed: true).convert(err.takeBytes()),
    );
  }

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    final pid = await _pid.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    if (pid != null && pid > 1) {
      try {
        await _fs._exec(_path, 'kill -TERM $pid 2>/dev/null; true');
      } on RemoteFsError {
        // gone already, or the connection is: the channel closes below
      }
    }
    _session?.close();
    await _done.catchError((Object _) {});
  }
}
