import 'dart:async';
import 'dart:typed_data';

/// What a directory entry is ([RemoteEntry.kind]).
enum EntryKind { directory, file, other }

/// One entry of a desktop directory, as `csakos` sees it.
class RemoteEntry {
  const RemoteEntry({
    required this.name,
    required this.path,
    required this.kind,
    this.size,
    this.modified,
    this.mode,
    this.owner,
    this.link,
    this.linkBroken = false,
  });

  final String name;

  /// Absolute path on the desktop.
  final String path;

  /// For a symlink: what its target is (a link to a folder is a
  /// [EntryKind.directory]); a broken link is [EntryKind.other].
  final EntryKind kind;

  /// Bytes (the target's for a symlink).
  final int? size;
  final DateTime? modified;

  /// The permission bits and file type (`st_mode`).
  final int? mode;

  /// The owner's name (from the server's `ls -l` line).
  final String? owner;

  /// A symlink's target as written in the link (`readlink`); null: not a
  /// link.
  final String? link;
  final bool linkBroken;

  bool get isDir => kind == EntryKind.directory;
  bool get isLink => link != null;
  bool get hidden => name.startsWith('.');

  /// Executable by someone (a regular file with an x bit).
  bool get executable =>
      kind == EntryKind.file && mode != null && mode! & 0x49 != 0; // 0111

  /// `-rw-r--r--`, `drwxr-xr-x`, `lrwxrwxrwx`.
  String? get modeText => mode == null ? null : modeString(mode!);
}

/// `ls -l`'s mode column for [mode] (`st_mode`).
String modeString(int mode) {
  final type = switch (mode & 0xF000) {
    0x4000 => 'd',
    0xA000 => 'l',
    0x2000 => 'c',
    0x6000 => 'b',
    0x1000 => 'p',
    0xC000 => 's',
    _ => '-',
  };
  final b = StringBuffer(type);
  const letters = 'rwxrwxrwx';
  for (var i = 0; i < 9; i++) {
    final bit = 1 << (8 - i);
    b.write(mode & bit != 0 ? letters[i] : '-');
  }
  var s = b.toString();
  // setuid / setgid / sticky
  String put(String s, int at, String on, String off) =>
      s.replaceRange(at, at + 1, s[at] == 'x' ? on : off);
  if (mode & 0x800 != 0) s = put(s, 3, 's', 'S');
  if (mode & 0x400 != 0) s = put(s, 6, 's', 'S');
  if (mode & 0x200 != 0) s = put(s, 9, 't', 'T');
  return s;
}

/// The owner column of an `ls -l` line from the SFTP server
/// (`drwxr-xr-x    5 csakos   csakos  4096 Nov  4 22:07 Downloads`).
String? ownerFromLongname(String longname) {
  final parts = longname.trim().split(RegExp(r'\s+'));
  if (parts.length < 4) return null;
  final owner = parts[2];
  return owner.isEmpty ? null : owner;
}

/// A mounted filesystem: where, what type, and how full.
class MountInfo {
  const MountInfo({
    required this.target,
    required this.fsType,
    this.size,
    this.used,
  });

  final String target;
  final String fsType;
  final int? size;
  final int? used;

  double? get usedFraction =>
      size == null || used == null || size == 0 ? null : used! / size!;

  MountInfo withUsage(int? size, int? used) =>
      MountInfo(target: target, fsType: fsType, size: size, used: used);
}

/// `findmnt -rn -o TARGET,FSTYPE` output (findmnt escapes a space in a path
/// as `\x20`).
List<MountInfo> parseMounts(String output) => [
  for (final line in output.split('\n'))
    if (line.trim().split(' ') case [final target, final type, ...])
      if (target.startsWith('/'))
        MountInfo(target: _unescapeMount(target), fsType: type),
];

String _unescapeMount(String s) => s.replaceAllMapped(
  RegExp(r'\\x([0-9a-fA-F]{2})'),
  (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
);

/// The desktop's filesystem over one connection.
abstract interface class RemoteFs {
  /// The login's home folder (`/home/<user>`).
  Future<String> home();

  /// A directory's entries, without `.` and `..`; symlinks resolved.
  /// Throws [RemoteFsError].
  Future<List<RemoteEntry>> list(String path);

  /// The number of entries in [path] (null: unreadable).
  Future<int?> count(String path);

  /// The canonical path (symlinks resolved).
  Future<String> realPath(String path);

  /// Up to [max] bytes from the start of [path].
  Future<Uint8List> readHead(String path, int max);

  /// Streams [path] into [sink]; [onProgress] gets the bytes so far. Stops
  /// early (without an error) when [cancelled] says so.
  Future<int> download(
    String path,
    StreamSink<List<int>> sink, {
    void Function(int bytes)? onProgress,
    bool Function()? cancelled,
  });

  /// The mounted filesystems (`findmnt`); empty when it can't tell.
  Future<List<MountInfo>> mounts();

  /// Size and used bytes of the filesystem holding [path].
  Future<(int, int)?> usage(String path);

  /// An answer from the desktop within [timeout].
  Future<bool> probe(Duration timeout);

  /// Completes when the connection ends.
  Future<void> get done;

  Future<void> close();
}

/// Why a file operation failed.
enum FsFailure { notFound, denied, notADirectory, unreachable, other }

class RemoteFsError implements Exception {
  const RemoteFsError(this.failure, this.detail);

  final FsFailure failure;
  final String detail;

  @override
  String toString() => 'RemoteFsError(${failure.name}): $detail';
}

// ---------------------------------------------------------------- paths

/// [name] inside [dir].
String joinPath(String dir, String name) =>
    dir == '/' ? '/$name' : '$dir/$name';

/// The folder holding [path] (`/` for `/` itself).
String parentPath(String path) {
  if (path == '/' || !path.contains('/')) return '/';
  final i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.substring(0, i);
}

/// The last part of [path] (`/` for the root).
String baseName(String path) =>
    path == '/' ? '/' : path.substring(path.lastIndexOf('/') + 1);

/// [path] without `.`, `..`, double or trailing slashes; relative parts are
/// taken from [from].
String normalizePath(String path, {String from = '/'}) {
  final parts = <String>[];
  final full = path.startsWith('/') ? path : '$from/$path';
  for (final p in full.split('/')) {
    if (p.isEmpty || p == '.') continue;
    if (p == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(p);
  }
  return '/${parts.join('/')}';
}

/// The breadcrumb's segments of [path]: `(label, path)` from `/` down.
List<(String, String)> pathSegments(String path) {
  final out = <(String, String)>[('/', '/')];
  var at = '';
  for (final p in path.split('/')) {
    if (p.isEmpty) continue;
    at = '$at/$p';
    out.add((p, at));
  }
  return out;
}

/// [path] with the home folder as `~` (for display).
String tildePath(String path, String? home) {
  if (home == null || home == '/') return path;
  if (path == home) return '~';
  if (path.startsWith('$home/')) return '~${path.substring(home.length)}';
  return path;
}

// ---------------------------------------------------------------- order

enum SortKey { name, size, modified }

/// Folders first, then files; within each by [key] (names naturally and
/// case-insensitively: `file2` before `file10`). [ascending] flips the
/// key's direction (names A→Z, sizes and dates largest / newest first when
/// false… the list header's arrow says which).
List<RemoteEntry> sortEntries(
  Iterable<RemoteEntry> entries,
  SortKey key, {
  bool ascending = true,
}) {
  int byKey(RemoteEntry a, RemoteEntry b) {
    final c = switch (key) {
      SortKey.name => 0,
      SortKey.size => (a.size ?? -1).compareTo(b.size ?? -1),
      SortKey.modified => (a.modified?.millisecondsSinceEpoch ?? 0).compareTo(
        b.modified?.millisecondsSinceEpoch ?? 0,
      ),
    };
    return c;
  }

  final list = entries.toList();
  list.sort((a, b) {
    if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
    var c = byKey(a, b);
    if (c == 0) c = compareNatural(a.name, b.name);
    return ascending ? c : -c;
  });
  return list;
}

/// Natural, case-insensitive order: digit runs compare as numbers.
int compareNatural(String a, String b) {
  final x = a.toLowerCase();
  final y = b.toLowerCase();
  var i = 0;
  var j = 0;
  bool digit(int c) => c >= 0x30 && c <= 0x39;
  while (i < x.length && j < y.length) {
    final cx = x.codeUnitAt(i);
    final cy = y.codeUnitAt(j);
    if (digit(cx) && digit(cy)) {
      var ei = i;
      while (ei < x.length && digit(x.codeUnitAt(ei))) {
        ei++;
      }
      var ej = j;
      while (ej < y.length && digit(y.codeUnitAt(ej))) {
        ej++;
      }
      final nx = x.substring(i, ei).replaceFirst(RegExp('^0+(?=.)'), '');
      final ny = y.substring(j, ej).replaceFirst(RegExp('^0+(?=.)'), '');
      if (nx.length != ny.length) return nx.length.compareTo(ny.length);
      final c = nx.compareTo(ny);
      if (c != 0) return c;
      i = ei;
      j = ej;
      continue;
    }
    if (cx != cy) return cx.compareTo(cy);
    i++;
    j++;
  }
  final c = (x.length - i).compareTo(y.length - j);
  return c != 0 ? c : a.compareTo(b);
}

// ---------------------------------------------------------------- types

/// The design's type families (one icon each, no per-type colours).
enum FileType {
  folder,
  pdf,
  image,
  text,
  code,
  structured,
  archive,
  executable,
  video,
  audio,
  other,
}

final _types = <String, FileType>{
  'pdf': FileType.pdf,
  for (final e in [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'bmp',
    'heic',
    'heif',
    'avif',
    'svg',
    'ico',
    'tif',
    'tiff',
  ])
    e: FileType.image,
  for (final e in [
    'txt',
    'md',
    'log',
    'rst',
    'csv',
    'tsv',
    'ini',
    'conf',
    'cfg',
    'env',
    'srt',
  ])
    e: FileType.text,
  for (final e in [
    'dart',
    'py',
    'sh',
    'zsh',
    'bash',
    'fish',
    'js',
    'mjs',
    'ts',
    'tsx',
    'jsx',
    'c',
    'h',
    'cc',
    'cpp',
    'hpp',
    'rs',
    'go',
    'java',
    'kt',
    'kts',
    'cs',
    'swift',
    'rb',
    'php',
    'lua',
    'sql',
    'html',
    'htm',
    'css',
    'scss',
    'gradle',
    'cmake',
    'mk',
    'patch',
    'diff',
  ])
    e: FileType.code,
  for (final e in ['json', 'toml', 'yaml', 'yml', 'xml', 'jsonl', 'arb'])
    e: FileType.structured,
  for (final e in [
    'zip',
    'tar',
    'gz',
    'tgz',
    'zst',
    'xz',
    'bz2',
    '7z',
    'rar',
    'deb',
    'rpm',
    'apk',
    'iso',
  ])
    e: FileType.archive,
  for (final e in ['mp4', 'mkv', 'webm', 'mov', 'avi', 'm4v'])
    e: FileType.video,
  for (final e in ['mp3', 'flac', 'ogg', 'opus', 'wav', 'm4a', 'aac'])
    e: FileType.audio,
};

/// A file name's extension, lower case (`''` when none).
String extensionOf(String name) {
  final i = name.lastIndexOf('.');
  if (i <= 0 || i == name.length - 1) return '';
  return name.substring(i + 1).toLowerCase();
}

FileType fileTypeOf(RemoteEntry e) {
  if (e.isDir) return FileType.folder;
  final t = _types[extensionOf(e.name)];
  if (t != null) return t;
  if (e.executable) return FileType.executable;
  return FileType.other;
}

/// What the preview can show: text (incl. code and structured) or images
/// the phone decodes.
enum PreviewKind { text, image, pdf, none }

const _imagePreview = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'};

PreviewKind previewKindOf(RemoteEntry e) {
  if (e.kind != EntryKind.file) return PreviewKind.none;
  final ext = extensionOf(e.name);
  if (_imagePreview.contains(ext)) return PreviewKind.image;
  if (ext == 'pdf') return PreviewKind.pdf;
  return switch (fileTypeOf(e)) {
    FileType.text || FileType.code || FileType.structured => PreviewKind.text,
    // a name without an extension (README, Makefile, a dotfile) may be text:
    // the preview checks the bytes
    FileType.other when ext.isEmpty || e.hidden => PreviewKind.text,
    _ => PreviewKind.none,
  };
}

/// A MIME type for Android (the download's entry, Open, Share).
String mimeOf(String name) => switch (extensionOf(name)) {
  'pdf' => 'application/pdf',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'webp' => 'image/webp',
  'gif' => 'image/gif',
  'bmp' => 'image/bmp',
  'svg' => 'image/svg+xml',
  'heic' => 'image/heic',
  'txt' || 'log' || 'md' || 'conf' || 'ini' || 'cfg' => 'text/plain',
  'csv' => 'text/csv',
  'html' || 'htm' => 'text/html',
  'json' => 'application/json',
  'xml' => 'application/xml',
  'zip' => 'application/zip',
  'gz' || 'tgz' => 'application/gzip',
  'tar' => 'application/x-tar',
  '7z' => 'application/x-7z-compressed',
  'apk' => 'application/vnd.android.package-archive',
  'mp4' || 'm4v' => 'video/mp4',
  'mkv' => 'video/x-matroska',
  'webm' => 'video/webm',
  'mov' => 'video/quicktime',
  'mp3' => 'audio/mpeg',
  'flac' => 'audio/flac',
  'ogg' || 'opus' => 'audio/ogg',
  'wav' => 'audio/wav',
  'm4a' || 'aac' => 'audio/mp4',
  'docx' =>
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'pptx' =>
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  _ => 'application/octet-stream',
};

/// Bytes as the design writes them: `412 KB`, `14.2 MB`, `1.2 GB` (1024s,
/// one decimal from MB up below 100).
String sizeText(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = bytes / 1024;
  var u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  if (u == 0 || v >= 100) return '${v.round()} ${units[u]}';
  return '${v.toStringAsFixed(1)} ${units[u]}';
}

/// Is [bytes] text? No NUL byte in the first 8 KB.
bool looksLikeText(Uint8List bytes) {
  final n = bytes.length < 8192 ? bytes.length : 8192;
  for (var i = 0; i < n; i++) {
    if (bytes[i] == 0) return false;
  }
  return true;
}
