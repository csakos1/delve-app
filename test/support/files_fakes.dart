import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:delve/files/device_files.dart';
import 'package:delve/files/files_service.dart';
import 'package:delve/files/pdf_pages.dart';
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

  /// The paths downloads (and preview fetches) read, in order.
  final List<String> downloaded = [];
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
    downloaded.add(path);
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

  // ---------------------------------------------------------------- write

  /// Folders where a move from or to elsewhere fails like across btrfs
  /// subvolumes.
  final Set<String> otherDevices = {};

  /// Uploads wait for this when set.
  Completer<void>? holdUploads;

  /// The paths [deleteTree] removed, in order.
  final List<String> deletedTrees = [];

  void _alive() {
    if (_done.isCompleted) {
      throw const RemoteFsError(FsFailure.unreachable, 'closed');
    }
  }

  RemoteEntry? _find(String path) {
    for (final e in tree[parentPath(path)] ?? const <RemoteEntry>[]) {
      if (e.name == baseName(path)) return e;
    }
    if (tree.containsKey(path)) return dirEntry(path);
    return null;
  }

  void _put(RemoteEntry e) {
    final dir = tree[parentPath(e.path)];
    if (dir == null) throw RemoteFsError(FsFailure.notFound, e.path);
    dir
      ..removeWhere((x) => x.name == e.name)
      ..add(e);
  }

  void _drop(String path) {
    tree[parentPath(path)]?.removeWhere((x) => x.name == baseName(path));
    tree.removeWhere((k, _) => k == path || isInside(k, path));
    contents.removeWhere((k, _) => k == path || isInside(k, path));
  }

  void _writable(String path) {
    if (denied.contains(parentPath(path))) {
      throw RemoteFsError(FsFailure.denied, 'Permission denied: $path');
    }
  }

  String _device(String path) =>
      otherDevices.where((d) => path == d || isInside(path, d)).firstOrNull ??
      '';

  @override
  Future<RemoteEntry?> lstat(String path) async {
    _alive();
    return _find(path);
  }

  @override
  Future<void> mkdir(String path) async {
    _alive();
    _writable(path);
    if (_find(path) != null) throw RemoteFsError(FsFailure.exists, path);
    _put(dirEntry(path));
    tree[path] = [];
  }

  @override
  Future<void> rename(String from, String to) async {
    _alive();
    _writable(from);
    _writable(to);
    final e = _find(from);
    if (e == null) throw RemoteFsError(FsFailure.notFound, from);
    if (_device(from) != _device(to)) {
      throw RemoteFsError(FsFailure.crossDevice, '$from → $to');
    }
    if (_find(to) != null) _drop(to);
    tree[parentPath(from)]!.removeWhere((x) => x.name == e.name);
    String moved(String p) => p == from ? to : '$to${p.substring(from.length)}';
    _put(
      RemoteEntry(
        name: baseName(to),
        path: to,
        kind: e.kind,
        size: e.size,
        modified: e.modified,
        mode: e.mode,
        owner: e.owner,
        link: e.link,
      ),
    );
    for (final k in tree.keys.toList()) {
      if (k == from || isInside(k, from)) {
        tree[moved(k)] = [
          for (final c in tree.remove(k)!)
            RemoteEntry(
              name: c.name,
              path: moved(c.path),
              kind: c.kind,
              size: c.size,
              modified: c.modified,
              mode: c.mode,
              owner: c.owner,
              link: c.link,
            ),
        ];
      }
    }
    for (final k in contents.keys.toList()) {
      if (k == from || isInside(k, from)) {
        contents[moved(k)] = contents.remove(k)!;
      }
    }
  }

  void _file(String path, Uint8List bytes) {
    _put(fileEntry(path, bytes.length));
    contents[path] = bytes;
  }

  @override
  Future<void> writeFile(
    String path,
    Uint8List bytes, {
    bool exclusive = false,
  }) async {
    _alive();
    _writable(path);
    if (exclusive && _find(path) != null) {
      throw RemoteFsError(FsFailure.exists, path);
    }
    _file(path, bytes);
  }

  @override
  Future<int> upload(
    String path,
    Stream<Uint8List> data, {
    void Function(int bytes)? onProgress,
    bool Function()? cancelled,
  }) async {
    _alive();
    _writable(path);
    final b = BytesBuilder(copy: false);
    await for (final chunk in data) {
      if (holdUploads case final h?) await h.future;
      if (cancelled?.call() ?? false) break;
      _alive();
      b.add(chunk);
      onProgress?.call(b.length);
    }
    _file(path, b.takeBytes());
    return contents[path]!.length;
  }

  @override
  Future<void> deleteTree(String path) async {
    _alive();
    _writable(path);
    deletedTrees.add(path);
    _drop(path);
  }

  @override
  Future<int?> diskUsage(String path) async {
    var n = 0;
    for (final MapEntry(:key, :value) in contents.entries) {
      if (key == path || isInside(key, path)) n += value.length;
    }
    return n;
  }

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

/// A white 1 × 1 PNG: what the fake PDF renderer draws.
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC',
);

/// The phone's PDF renderer: a fetched preview file `%PDF pages=N` has N
/// A4 pages; [fail] makes the next open throw. Records renders and closes.
class FakePdfPages implements PdfPages {
  final List<(int, int, int)> rendered = [];
  final List<int> closed = [];
  PdfProblem? fail;
  int _next = 1;

  @override
  Future<PdfInfo> open(String path) async {
    if (fail case final f?) {
      fail = null;
      throw f;
    }
    final head = utf8.decode(
      File(path).readAsBytesSync(),
      allowMalformed: true,
    );
    final n = RegExp(r'^%PDF pages=(\d+)').firstMatch(head)?.group(1);
    if (n == null) throw const PdfProblem(PdfProblemKind.broken, 'not a PDF');
    return PdfInfo(_next++, List.filled(int.parse(n), const Size(595, 842)));
  }

  @override
  Future<Uint8List> render(int doc, int page, int width) async {
    rendered.add((doc, page, width));
    return tinyPng;
  }

  @override
  Future<void> close(int doc) async => closed.add(doc);
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
    fileEntry('/home/user/Documents/hajos/evkonyv/hatlap.png', 380000),
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
  ..contents['/home/user/Documents/hajos/evkonyv/borito.png'] =
      Uint8List.fromList(List.filled(64, 7))
  ..contents['/home/user/Documents/hajos/evkonyv/hatlap.png'] =
      Uint8List.fromList(List.filled(48, 9))
  ..contents['/home/user/Documents/hajos/evkonyv/beszedes_evkonyv.pdf'] =
      Uint8List.fromList(utf8.encode('%PDF pages=12\n'))
  ..denied.add('/root');
