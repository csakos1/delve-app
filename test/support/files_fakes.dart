import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:delve/files/device_files.dart';
import 'package:delve/files/files_service.dart';
import 'package:delve/files/remote_fs.dart';
import 'package:delve/files/sftp_fs.dart';
import 'package:delve/terminal/phone_key.dart';
import 'package:delve/terminal/ssh_link.dart';

import 'terminal_fakes.dart';

const fastFilesTiming = FilesTiming(
  backoff: [Duration(milliseconds: 20), Duration(milliseconds: 40)],
  probeTimeout: Duration(milliseconds: 50),
  closeAfterBackground: Duration(milliseconds: 200),
  countBatch: Duration(milliseconds: 10),
);

final _t0 = DateTime.utc(2026, 11, 4, 21, 7);

RemoteEntry dirEntry(
  String path, {
  String owner = 'csakos',
  int mode = 0x41ED,
}) => RemoteEntry(
  name: baseName(path),
  path: path,
  kind: EntryKind.directory,
  size: 4096,
  modified: _t0,
  mode: mode,
  owner: owner,
);

RemoteEntry fileEntry(String path, int size, {int mode = 0x81A4}) =>
    RemoteEntry(
      name: baseName(path),
      path: path,
      kind: EntryKind.file,
      size: size,
      modified: _t0,
      mode: mode,
      owner: 'csakos',
    );

/// The desktop's filesystem in memory: folders, files with content, folders
/// `csakos` can't read.
class FakeRemoteFs implements RemoteFs {
  FakeRemoteFs(this.tree);

  /// A folder's path → its entries.
  final Map<String, List<RemoteEntry>> tree;
  final Map<String, Uint8List> contents = {};
  final Set<String> denied = {};
  final List<String> listed = [];
  final _done = Completer<void>();
  bool closed = false;

  /// Downloads wait for this when set (to see them running / queued).
  Completer<void>? holdDownloads;

  void drop() {
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<String> home() async => '/home/user';

  @override
  Future<String> realPath(String path) async => switch (path) {
    '/home/user/.steam' => '/home/user/.local/share/Steam',
    _ => path,
  };

  @override
  Future<List<RemoteEntry>> list(String path) async {
    if (_done.isCompleted) {
      throw const RemoteFsError(FsFailure.unreachable, 'closed');
    }
    listed.add(path);
    if (denied.contains(path)) {
      throw RemoteFsError(FsFailure.denied, 'Permission denied: $path');
    }
    final l = tree[path];
    if (l == null) throw RemoteFsError(FsFailure.notFound, path);
    return List.of(l);
  }

  @override
  Future<int?> count(String path) async =>
      denied.contains(path) ? null : tree[path]?.length ?? 0;

  @override
  Future<Uint8List> readHead(String path, int max) async {
    final b = contents[path] ?? Uint8List(0);
    return b.length > max ? Uint8List.sublistView(b, 0, max) : b;
  }

  @override
  Future<int> download(
    String path,
    StreamSink<List<int>> sink, {
    void Function(int bytes)? onProgress,
    bool Function()? cancelled,
  }) async {
    final b = contents[path];
    if (b == null) throw RemoteFsError(FsFailure.notFound, path);
    if (holdDownloads case final h?) await h.future;
    var n = 0;
    const chunk = 4;
    for (var i = 0; i < b.length; i += chunk) {
      if (cancelled?.call() ?? false) break;
      final end = i + chunk > b.length ? b.length : i + chunk;
      sink.add(b.sublist(i, end));
      n = end;
      onProgress?.call(n);
    }
    return n;
  }

  @override
  Future<List<MountInfo>> mounts() async => const [
    MountInfo(target: '/', fsType: 'btrfs'),
    MountInfo(target: '/home', fsType: 'btrfs'),
    MountInfo(target: '/boot', fsType: 'vfat'),
  ];

  @override
  Future<(int, int)?> usage(String path) async => path == '/boot'
      ? (1024 * 1024 * 1024, 248 * 1024 * 1024)
      : (931 * 1024 * 1024 * 1024, 622 * 1024 * 1024 * 1024);

  @override
  Future<bool> probe(Duration timeout) async => !_done.isCompleted;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    closed = true;
    drop();
  }
}

/// Opens [fs] (a new one per connection when [make] is set); [fail] makes
/// the next opens throw.
class FakeFilesDialer implements FilesDialer {
  FakeFilesDialer(this.make);

  final FakeRemoteFs Function() make;
  final List<FakeRemoteFs> opened = [];
  final List<SshFailure> fail = [];
  int attempts = 0;

  FakeRemoteFs? get last => opened.isEmpty ? null : opened.last;

  @override
  Future<RemoteFs> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
  }) async {
    attempts++;
    if (fail.isNotEmpty) throw fail.removeAt(0);
    if (!await verify(testHostKeyType, testHostKey)) {
      throw const SshHostKeyRejected('pin mismatch');
    }
    final fs = make();
    opened.add(fs);
    return fs;
  }
}

/// Downloads/Delve: records what was published (and keeps the bytes).
class FakeDeviceFiles implements DeviceFiles {
  FakeDeviceFiles();

  Directory? _dir;
  final List<(String, String, Uint8List)> published = [];
  final List<String> openedUris = [];
  bool canOpen = true;

  @override
  Future<String> scratchDir() async =>
      (_dir ??= Directory.systemTemp.createTempSync('delve-files-')).path;

  @override
  Future<String> publish(String path, String name, String mime) async {
    final f = File(path);
    published.add((name, mime, f.readAsBytesSync()));
    f.deleteSync();
    return 'content://media/external/downloads/${published.length}';
  }

  @override
  Future<bool> open(String uri, String mime) async {
    openedUris.add(uri);
    return canOpen;
  }
}

/// A small desktop like the F0 fixtures: home with folders, hidden files,
/// a deep folder of PDFs, a symlink, /root denied.
Map<String, List<RemoteEntry>> sampleTree() => {
  '/': [
    dirEntry('/home', owner: 'root'),
    dirEntry('/root', owner: 'root', mode: 0x41C0),
    dirEntry('/usr', owner: 'root'),
    dirEntry('/boot', owner: 'root'),
    dirEntry('/tmp', owner: 'root'),
  ],
  '/home': [dirEntry('/home/user')],
  '/home/user': [
    dirEntry('/home/user/Documents'),
    dirEntry('/home/user/Downloads'),
    dirEntry('/home/user/delve-app'),
    dirEntry('/home/user/.config'),
    dirEntry('/home/user/.cache'),
    fileEntry('/home/user/.zshrc', 3200),
    fileEntry('/home/user/notes.txt', 18),
    fileEntry('/home/user/file10.log', 10),
    fileEntry('/home/user/file2.log', 2000),
    const RemoteEntry(
      name: '.steam',
      path: '/home/user/.steam',
      kind: EntryKind.directory,
      link: '/home/user/.local/share/Steam',
    ),
  ],
  '/home/user/Documents': [dirEntry('/home/user/Documents/hajos')],
  '/home/user/Documents/hajos': [
    dirEntry('/home/user/Documents/hajos/evkonyv'),
  ],
  '/home/user/Documents/hajos/evkonyv': [
    fileEntry(
      '/home/user/Documents/hajos/evkonyv/beszedes_evkonyv.pdf',
      14889779,
    ),
    fileEntry('/home/user/Documents/hajos/evkonyv/borito.png', 412000),
  ],
  '/home/user/Downloads': [],
  '/home/user/delve-app': [fileEntry('/home/user/delve-app/pubspec.yaml', 900)],
  '/home/user/.config': [],
  '/home/user/.cache': [],
  '/home/user/.local/share/Steam': [
    fileEntry('/home/user/.local/share/Steam/steam.sh', 50, mode: 0x81ED),
  ],
  '/usr': [dirEntry('/usr/bin', owner: 'root')],
  '/usr/bin': [
    for (var i = 0; i < 60; i++)
      fileEntry('/usr/bin/tool$i', 1000 + i, mode: 0x81ED),
  ],
  '/boot': [],
  '/tmp': [],
};

FakeRemoteFs sampleFs() => FakeRemoteFs(sampleTree())
  ..contents['/home/user/notes.txt'] = Uint8List.fromList(
    utf8.encode('line one\nline two\n'),
  )
  ..contents['/home/user/file2.log'] = Uint8List.fromList(
    List.filled(2000, 0x61),
  )
  ..contents['/home/user/.zshrc'] = Uint8List.fromList([1, 0, 2, 3])
  ..denied.add('/root');
