part of 'files_service.dart';

/// The editor opens text files up to this size (23n: 1 MB).
const kEditMax = 1024 * 1024;

/// Why a text file can't be edited here (23n: Edit is disabled and says
/// so).
enum EditBlock {
  /// Over [kEditMax]: the preview shows its first 1 MB.
  tooBig,

  /// Not valid UTF-8, or it has a NUL byte.
  notText,

  /// The login can't write the file, or its folder (the save writes
  /// `.name.part` next to it).
  readOnly,
}

/// A text file in the preview, as the editor needs it.
class TextFile {
  const TextFile({
    required this.entry,
    required this.path,
    required this.text,
    required this.cut,
    required this.size,
    required this.modified,
    required this.mode,
    this.block,
    this.access,
    this.folderAccess,
  });

  /// The row it was opened from (its name is the title).
  final RemoteEntry entry;

  /// The file itself (a link's target): read and saved there, so a save
  /// keeps the link.
  final String path;
  final String text;

  /// Only the first [kEditMax] bytes are in [text].
  final bool cut;

  /// Size, time and mode when it was read: a save first checks that the
  /// desktop still has this version.
  final int? size;
  final DateTime? modified;
  final int? mode;

  /// Null: it can be edited.
  final EditBlock? block;

  /// The file's and its folder's owner and mode (null: unknown).
  final PathAccess? access;
  final PathAccess? folderAccess;

  bool get editable => block == null;

  /// The owner and mode the read-only banner names (the file's, or the
  /// folder's when only that is not writable).
  PathAccess? get blocking =>
      access != null && !access!.writable ? access : folderAccess ?? access;

  TextFile _saved(String text, RemoteEntry? now) => TextFile(
    entry: entry,
    path: path,
    text: text,
    cut: false,
    size: now?.size,
    modified: now?.modified,
    mode: now?.mode ?? mode,
    access: access,
    folderAccess: folderAccess,
  );
}

/// The desktop's file is not the version that was opened (23n3); [now] is
/// what is there (null: it is gone).
class EditConflict implements Exception {
  const EditConflict(this.now);

  final RemoteEntry? now;

  @override
  String toString() => 'EditConflict: ${now?.path ?? 'deleted'}';
}

/// The folder does not let the login write the `.part` file (23n5b);
/// [folder] is its owner and mode when known.
class EditDenied implements Exception {
  const EditDenied(this.dir, this.folder);

  final String dir;
  final PathAccess? folder;

  @override
  String toString() => 'EditDenied: $dir';
}

/// Whether the listing's owner and mode let [user] write [e] (null: not
/// known, so maybe). Groups are not known here: a file of another user is
/// writable when its group or others may write.
bool listingWritable(RemoteEntry e, String user) {
  final mode = e.mode;
  final owner = e.owner;
  if (mode == null || owner == null || user == 'root') return true;
  return owner == user ? mode & 0x80 != 0 : mode & 0x12 != 0;
}

/// Editing a text file on the desktop (F2b, 23n).
extension FilesEdit on FilesService {
  /// The login's name ("Read-only for csakos").
  String get user => terminal.config.user;

  /// A text file for the preview and the editor: its first [kEditMax]
  /// bytes, whether it can be edited and why not. Null: not text (the
  /// preview's "Not a text file"). Throws [RemoteFsError].
  Future<TextFile?> openText(RemoteEntry e) async {
    final fs = await _need();
    return _write(fs, () async {
      final path = e.isLink ? await fs.realPath(e.path) : e.path;
      final st = await fs.lstat(path);
      if (st == null) throw RemoteFsError(FsFailure.notFound, e.path);
      final bytes = await fs.readHead(path, kEditMax + 1);
      if (!looksLikeText(bytes)) return null;
      final cut = bytes.length > kEditMax;
      final head = cut ? Uint8List.sublistView(bytes, 0, kEditMax) : bytes;
      String? strict;
      if (!cut && !head.contains(0)) {
        try {
          strict = utf8.decode(head);
        } on FormatException {
          strict = null;
        }
      }
      final text =
          strict ?? const Utf8Decoder(allowMalformed: true).convert(head);
      final dir = parentPath(path);
      final acc = await fs.access([path, dir]);
      final file = acc?.first;
      final folder = acc?.last;
      final readOnly =
          (file != null && !file.writable) ||
          (folder != null && !folder.writable);
      return TextFile(
        entry: e,
        path: path,
        text: text,
        cut: cut,
        size: st.size,
        modified: st.modified,
        mode: st.mode,
        access: file,
        folderAccess: folder,
        block: cut
            ? EditBlock.tooBig
            : strict == null
            ? EditBlock.notText
            : readOnly
            ? EditBlock.readOnly
            : null,
      );
    });
  }

  /// Saves [text] over [f] (23n2): `.name.part` next to it with the
  /// original mode, flushed, renamed over the file. A file another user
  /// owns (writable through its group) is written in place, so it stays
  /// theirs. Unless [force], the desktop's file must still be the version
  /// [f] read, else [EditConflict]. Returns the file as saved (the next
  /// save's base). Throws [EditDenied], [RemoteFsError].
  Future<TextFile> saveText(
    TextFile f,
    String text, {
    bool force = false,
  }) async {
    terminal.lock.keepAlive();
    final fs = await _need();
    final saved = await _write(fs, () async {
      final now = await fs.lstat(f.path);
      if (!force &&
          (now == null ||
              now.size != f.size ||
              now.modified?.millisecondsSinceEpoch !=
                  f.modified?.millisecondsSinceEpoch)) {
        throw EditConflict(now);
      }
      final bytes = Uint8List.fromList(utf8.encode(text));
      final dir = parentPath(f.path);
      final owner = f.access?.owner;
      if (now != null && owner != null && owner != user) {
        await _denied(fs, dir, () => fs.writeFile(f.path, bytes));
        await fs.sync(f.path);
      } else {
        final part = joinPath(dir, '.${baseName(f.path)}.part');
        await _denied(fs, dir, () => fs.writeFile(part, bytes));
        try {
          final mode = f.mode;
          if (mode != null) {
            try {
              await fs.setMode(part, mode);
            } on RemoteFsError catch (e) {
              if (e.failure == FsFailure.unreachable) rethrow;
            }
          }
          await fs.sync(part);
          await _denied(fs, dir, () => fs.rename(part, f.path));
        } on Object {
          try {
            await fs.deleteTree(part);
          } on Object {
            // left behind: a hidden .part, the next save overwrites it
          }
          rethrow;
        }
      }
      return f._saved(text, await fs.lstat(f.path));
    });
    unawaited(_refreshIf(parentPath(f.entry.path)));
    return saved;
  }

  /// "Save a copy to ~" (23n5b): [text] as a new file in the home folder,
  /// under the first free name like [f]'s. Returns its path.
  Future<String> saveCopy(TextFile f, String text) async {
    terminal.lock.keepAlive();
    final fs = await _need();
    return _write(fs, () async {
      final home = _home ?? await fs.home();
      final taken = {for (final e in await fs.list(home)) e.name};
      final name = freeName(f.entry.name, taken.contains);
      final path = joinPath(home, name);
      await fs.writeFile(
        path,
        Uint8List.fromList(utf8.encode(text)),
        exclusive: true,
      );
      unawaited(_refreshIf(home));
      return path;
    });
  }

  /// [op], with "permission denied" as [EditDenied] for [dir].
  Future<void> _denied(
    RemoteFs fs,
    String dir,
    Future<void> Function() op,
  ) async {
    try {
      await op();
    } on RemoteFsError catch (e) {
      if (e.failure != FsFailure.denied) rethrow;
      final acc = await fs.access([dir]).catchError((Object _) => null);
      throw EditDenied(dir, acc?.single);
    }
  }
}
