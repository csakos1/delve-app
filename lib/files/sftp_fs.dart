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
