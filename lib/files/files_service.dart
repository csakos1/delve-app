import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../terminal/ssh_link.dart';
import '../terminal/terminal_service.dart';
import 'device_files.dart';
import 'remote_fs.dart';
import 'sftp_fs.dart';

/// Where the Files tab's connection is.
enum FilesPhase {
  /// The terminal is not set up yet (its key, host and pinned host key are
  /// what Files uses).
  notSetUp,
  idle,
  connecting,
  live,

  /// Lost, or could not connect; [FilesService.nextAttemptAt] says when it
  /// tries again.
  offline,

  /// sshd showed another host key than the pinned one: no retry (22c).
  hostKeyChanged,

  /// sshd refused the phone's key.
  denied,
}

/// Why the folder on screen could not be listed.
class ListProblem {
  const ListProblem(this.failure, this.path, {this.entry, this.detail = ''});

  final FsFailure failure;
  final String path;

  /// The row it was opened from (its owner and mode for the message).
  final RemoteEntry? entry;
  final String detail;
}

enum TransferState { queued, running, done, failed, cancelled }

/// One download to the phone.
class Transfer {
  Transfer._(this.id, this.entry);

  final int id;
  final RemoteEntry entry;
  TransferState state = TransferState.queued;
  int bytes = 0;
  int? get total => entry.size;
  String? error;

  /// The Downloads/Delve entry once done.
  String? uri;
  DateTime? startedAt;
  DateTime? endedAt;
  bool _cancel = false;

  String get name => entry.name;
  bool get active =>
      state == TransferState.queued || state == TransferState.running;

  /// Bytes per second so far (null: not running long enough).
  double? speed(DateTime now) {
    final s = startedAt;
    if (s == null || state != TransferState.running) return null;
    final ms = now.difference(s).inMilliseconds;
    return ms < 1000 ? null : bytes * 1000 / ms;
  }

  double? get fraction {
    final t = total;
    if (t == null || t <= 0) return null;
    return (bytes / t).clamp(0, 1).toDouble();
  }
}

/// Retry waits and limits for the Files connection.
class FilesTiming {
  const FilesTiming({
    this.backoff = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
    ],
    this.probeTimeout = const Duration(seconds: 3),
    this.closeAfterBackground = const Duration(seconds: 60),
    this.countBatch = const Duration(milliseconds: 120),
  });

  final List<Duration> backoff;
  final Duration probeTimeout;

  /// The connection closes this long after the app left the screen (unless
  /// a download runs).
  final Duration closeAfterBackground;

  /// Folder item counts that arrive within this long redraw once.
  final Duration countBatch;
}

/// The text preview reads at most this much (design: "files over 1 MB
/// open the first 1 MB").
const kPreviewTextMax = 1024 * 1024;

/// Images larger than this are not previewed (download them instead).
const kPreviewImageMax = 40 * 1024 * 1024;

/// The Files tab: the desktop's filesystem as `csakos` sees it, over SFTP
/// on its own SSH connection with the terminal's key, host and pinned host
/// key, behind the terminal's lock (F1). Lives as long as the app.
class FilesService extends ChangeNotifier {
  FilesService({
    required this.terminal,
    required FilesDialer dialer,
    required this.device,
    this.timing = const FilesTiming(),
    DateTime Function()? now,
  }) : _dialer = dialer,
       _now = now ?? DateTime.now;

  final TerminalService terminal;
  final DeviceFiles device;
  final FilesTiming timing;
  final FilesDialer _dialer;
  final DateTime Function() _now;

  static const prefsKey = 'delve.files.prefs.v1';

  // ------------------------------------------------------------ connection

  RemoteFs? _fs;
  FilesPhase _phase = FilesPhase.idle;
  FilesPhase get phase => _phase;
  int _attempt = 0;

  /// Reconnect attempt number while offline (1, 2, …).
  int get attempt => _attempt;
  DateTime? _nextAt;
  DateTime? get nextAttemptAt => _nextAt;
  String? _problem;

  /// Why the last connect failed (the trace's words).
  String? get problem => _problem;
  Timer? _retry;
  Timer? _idleClose;
  Future<RemoteFs?>? _connecting;
  bool _visible = false;
  bool _foreground = true;
  bool _disposed = false;

  // --------------------------------------------------------------- folder

  String? _home;
  String? get home => _home;
  String? _path;

  /// The folder on screen (null: not known yet – the home folder once
  /// connected).
  String? get path => _path;
  List<RemoteEntry>? _all;
  List<RemoteEntry>? _shown;

  /// The folder's entries in the chosen order, hidden ones only when shown
  /// (null: not listed yet).
  List<RemoteEntry>? get entries => _shown;
  int get hiddenCount => _all?.where((e) => e.hidden).length ?? 0;
  int get totalCount => _all?.length ?? 0;
  bool _loading = false;
  bool get loading => _loading;
  ListProblem? _listProblem;
  ListProblem? get listProblem => _listProblem;
  int _listToken = 0;
  final List<String> _back = [];

  /// Folders to go back to (Android back).
  bool get canGoBack => _back.isNotEmpty;

  bool _showHidden = false;
  bool get showHidden => _showHidden;
  SortKey _sort = SortKey.name;
  SortKey get sort => _sort;
  bool _ascending = true;
  bool get ascending => _ascending;

  List<MountInfo> _mounts = const [];
  final Map<String, (int, int)?> _usage = {};

  /// The filesystem that holds the folder on screen (longest mount prefix),
  /// with its size and use once known.
  MountInfo? get mountHere {
    final p = _path;
    if (p == null) return null;
    MountInfo? best;
    for (final m in _mounts) {
      final under =
          m.target == '/' || p == m.target || p.startsWith('${m.target}/');
      if (under && (best == null || m.target.length > best.target.length)) {
        best = m;
      }
    }
    if (best == null) return null;
    final u = _usage[best.target];
    return u == null ? best : best.withUsage(u.$1, u.$2);
  }

  /// True at a mount point itself (the header names it).
  bool get atMountPoint => _mounts.any((m) => m.target == _path);

  final Map<String, int?> _counts = {};
  final Queue<String> _countQueue = Queue();
  final Set<String> _countAsked = {};
  int _countRunning = 0;
  Timer? _countNotify;

  // ------------------------------------------------------------ transfers

  final List<Transfer> _transfers = [];
  List<Transfer> get transfers => List.unmodifiable(_transfers);
  int _nextTransfer = 0;
  bool _transferRunning = false;
  final _finished = StreamController<Transfer>.broadcast();

  /// A download that ended (done, failed): the screen's snackbar.
  Stream<Transfer> get finished => _finished.stream;

  Transfer? get runningTransfer =>
      _transfers.where((t) => t.state == TransferState.running).firstOrNull;

  /// "1 of 2": the running transfer's place among the active ones.
  (int, int)? get transferProgress {
    final active = _transfers.where((t) => t.active).toList();
    if (active.isEmpty) return null;
    final done = _transfers.where(
      (t) => !t.active && t.endedAt != null && _batch.contains(t.id),
    );
    return (done.length + 1, done.length + active.length);
  }

  /// Transfers since the queue was last empty (for "1 of 2").
  final Set<int> _batch = {};

  // ---------------------------------------------------------------- start

  bool _loaded = false;

  Future<void> _loadPrefs() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await terminal.secrets.store.read(prefsKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, Object?>;
      _showHidden = j['hidden'] == true;
      _sort = SortKey.values.asNameMap()[j['sort']] ?? SortKey.name;
      _ascending = j['ascending'] != false;
      if (j['path'] case final String p when p.startsWith('/')) _path = p;
    } on Object {
      // defaults
    }
  }

  void _savePrefs() {
    unawaited(
      terminal.secrets.store
          .write(
            prefsKey,
            jsonEncode({
              'hidden': _showHidden,
              'sort': _sort.name,
              'ascending': _ascending,
              'path': ?_path,
            }),
          )
          .catchError((Object _) {}),
    );
  }

  /// The tab came to the front (or left it).
  void setVisible({required bool visible}) {
    _visible = visible;
    if (visible) unawaited(start());
  }

  /// The app came to the front (or went away).
  void setForeground({required bool foreground}) {
    _foreground = foreground;
    _idleClose?.cancel();
    if (!foreground) {
      _idleClose = Timer(timing.closeAfterBackground, () {
        if (!_foreground && !_transferRunning) unawaited(_drop());
      });
      return;
    }
    if (!_visible) return;
    final fs = _fs;
    if (fs == null) {
      unawaited(start());
      return;
    }
    // Android cut the network while away: check before the next listing
    unawaited(() async {
      if (await fs.probe(timing.probeTimeout)) return;
      if (identical(_fs, fs)) {
        await _drop();
        await start();
      }
    }());
  }

  /// Connects (when set up) and lists the folder on screen.
  Future<void> start() async {
    await terminal.load();
    await _loadPrefs();
    if (_disposed) return;
    if (!terminal.config.verified) {
      _setPhase(FilesPhase.notSetUp);
      return;
    }
    if (_phase == FilesPhase.notSetUp) _setPhase(FilesPhase.idle);
    if (_phase == FilesPhase.hostKeyChanged || _phase == FilesPhase.denied) {
      return;
    }
    final fs = await _ensure();
    if (fs == null) return;
    if (_shown == null && !_loading) await open(_path ?? _home!, push: false);
  }

  /// Tries again now (the state line's Retry, or after setup changed).
  Future<void> retry() async {
    _retry?.cancel();
    _nextAt = null;
    if (_phase == FilesPhase.hostKeyChanged || _phase == FilesPhase.denied) {
      _setPhase(FilesPhase.idle);
    }
    await start();
  }

  Future<RemoteFs?> _ensure() {
    final fs = _fs;
    if (fs != null) return Future.value(fs);
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<RemoteFs?> _connect() async {
    final key = terminal.key;
    if (key == null) return null;
    final config = terminal.config;
    _retry?.cancel();
    _nextAt = null;
    _setPhase(FilesPhase.connecting);
    try {
      final fs = await _dialer.open(
        SshTarget(
          host: config.host,
          port: config.port,
          user: config.user,
          session: 'files',
        ),
        key: key,
        // only the pinned key: the terminal's setup is where a key is trusted
        verify: (type, fingerprint) async =>
            (await terminal.secrets.pinned(
              config.hostPort,
            ))?.matches(type, fingerprint) ??
            false,
      );
      if (_disposed) {
        unawaited(fs.close());
        return null;
      }
      _fs = fs;
      _attempt = 0;
      _problem = null;
      _setPhase(FilesPhase.live);
      unawaited(
        fs.done.then((_) {
          if (identical(_fs, fs)) unawaited(_lost('connection closed'));
        }),
      );
      _home ??= await fs.home().catchError((Object _) => '/');
      _mounts = await fs.mounts();
      _usage.clear();
      unawaited(_fetchUsage());
      return fs;
    } on SshHostKeyRejected catch (e) {
      _problem = e.detail;
      _setPhase(FilesPhase.hostKeyChanged);
    } on SshAuthDenied catch (e) {
      _problem = e.detail;
      _setPhase(FilesPhase.denied);
    } on Object catch (e) {
      _problem = e is SshFailure ? e.detail : '$e';
      _scheduleRetry();
    }
    return null;
  }

  Future<void> _fetchUsage() async {
    final m = mountHere;
    final fs = _fs;
    if (m == null || fs == null || _usage.containsKey(m.target)) return;
    _usage[m.target] = null;
    final u = await fs.usage(m.target);
    if (u != null) {
      _usage[m.target] = u;
      _notify();
    }
  }

  void _scheduleRetry() {
    _attempt++;
    _setPhase(FilesPhase.offline);
    if (!_visible && !_transferRunning) return;
    final waits = timing.backoff;
    final wait = waits[(_attempt - 1).clamp(0, waits.length - 1)];
    _nextAt = _now().add(wait);
    _retry?.cancel();
    _retry = Timer(wait, () {
      _nextAt = null;
      unawaited(start().then((_) => _resumeTransfers()));
    });
    _notify();
  }

  Future<void> _lost(String why) async {
    _problem = why;
    final fs = _fs;
    _fs = null;
    if (fs != null) unawaited(fs.close());
    _scheduleRetry();
  }

  Future<void> _drop() async {
    final fs = _fs;
    _fs = null;
    _retry?.cancel();
    _nextAt = null;
    if (fs != null) await fs.close();
    if (_phase == FilesPhase.live) _setPhase(FilesPhase.idle);
  }

  void _setPhase(FilesPhase p) {
    if (_phase == p) return;
    _phase = p;
    _notify();
  }

  // ------------------------------------------------------------ browsing

  /// Shows the folder at [path]; [push] remembers the folder left for
  /// Android back. [from] is the row it was opened from.
  Future<void> open(String path, {bool push = true, RemoteEntry? from}) async {
    terminal.lock.keepAlive();
    final target = normalizePath(path);
    if (push && _path != null && _path != target) _back.add(_path!);
    _path = target;
    _all = null;
    _shown = null;
    _listProblem = null;
    _loading = true;
    _counts.clear();
    _countQueue.clear();
    _countAsked.clear();
    final token = ++_listToken;
    _savePrefs();
    _notify();
    unawaited(_fetchUsage());
    final fs = await _ensure();
    if (token != _listToken) return;
    if (fs == null) {
      _loading = false;
      _notify();
      return;
    }
    try {
      final list = await fs.list(target);
      if (token != _listToken) return;
      _all = list;
      _resort();
    } on RemoteFsError catch (e) {
      if (token != _listToken) return;
      if (e.failure == FsFailure.unreachable) {
        _loading = false;
        await _lost(e.detail);
        return;
      }
      _listProblem = ListProblem(
        e.failure,
        target,
        entry: from,
        detail: e.detail,
      );
    }
    _loading = false;
    _notify();
  }

  /// A row: a folder (or a link to one) opens, at its real path.
  Future<void> enter(RemoteEntry e) async {
    if (!e.isDir) return;
    var target = e.path;
    if (e.isLink) {
      final fs = await _ensure();
      if (fs != null) {
        target = await fs.realPath(e.path).catchError((Object _) => e.path);
      }
    }
    await open(target, from: e);
  }

  Future<void> refresh() async {
    final p = _path;
    if (p != null) await open(p, push: false);
  }

  /// The folder above (not remembered for back).
  Future<void> up() async {
    final p = _path;
    if (p == null || p == '/') return;
    await open(parentPath(p));
  }

  /// Android back: the folder shown before; false when there is none.
  bool back() {
    if (_back.isEmpty) return false;
    unawaited(open(_back.removeLast(), push: false));
    return true;
  }

  void setShowHidden({required bool show}) {
    _showHidden = show;
    _resort();
    _savePrefs();
    _notify();
  }

  /// Sorts by [key]; the same key again flips the direction. Names start
  /// A→Z, sizes and dates largest / newest first.
  void sortBy(SortKey key) {
    if (key == _sort) {
      _ascending = !_ascending;
    } else {
      _sort = key;
      _ascending = key == SortKey.name;
    }
    _resort();
    _savePrefs();
    _notify();
  }

  void _resort() {
    final all = _all;
    if (all == null) return;
    _shown = sortEntries(
      _showHidden ? all : all.where((e) => !e.hidden),
      _sort,
      ascending: _ascending,
    );
  }

  /// How many entries [dir] holds (null: not known yet, or unreadable) –
  /// asked for when its row is drawn, a few at a time.
  int? countOf(RemoteEntry dir) {
    if (_counts.containsKey(dir.path)) return _counts[dir.path];
    if (_countAsked.add(dir.path)) {
      _countQueue.add(dir.path);
      _pumpCounts();
    }
    return null;
  }

  /// Whether [countOf] has an answer (null may mean unreadable).
  bool countKnown(RemoteEntry dir) => _counts.containsKey(dir.path);

  void _pumpCounts() {
    final fs = _fs;
    if (fs == null) return;
    final token = _listToken;
    while (_countRunning < 4 && _countQueue.isNotEmpty) {
      // the rows drawn last are the ones on screen now
      final p = _countQueue.removeLast();
      _countRunning++;
      unawaited(
        fs.count(p).then((n) {
          _countRunning--;
          if (token != _listToken) return;
          _counts[p] = n;
          _countNotify ??= Timer(timing.countBatch, () {
            _countNotify = null;
            _notify();
          });
          _pumpCounts();
        }),
      );
    }
  }

  // ------------------------------------------------------------- preview

  /// The start of a text file (up to [kPreviewTextMax]); null: not text.
  Future<(String, bool)?> readText(RemoteEntry e) async {
    terminal.lock.keepAlive();
    final fs = await _ensure();
    if (fs == null) {
      throw const RemoteFsError(FsFailure.unreachable, 'not connected');
    }
    final bytes = await fs.readHead(e.path, kPreviewTextMax);
    if (!looksLikeText(bytes)) return null;
    final cut = (e.size ?? 0) > bytes.length;
    return (const Utf8Decoder(allowMalformed: true).convert(bytes), cut);
  }

  /// An image fetched into the scratch folder for the preview.
  Future<File> fetchImage(RemoteEntry e) async {
    terminal.lock.keepAlive();
    final fs = await _ensure();
    if (fs == null) {
      throw const RemoteFsError(FsFailure.unreachable, 'not connected');
    }
    final dir = Directory('${await device.scratchDir()}/preview');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/p.${extensionOf(e.name)}');
    final sink = file.openWrite();
    try {
      await fs.download(e.path, sink);
    } finally {
      await sink.close();
    }
    return file;
  }

  // ------------------------------------------------------------ download

  /// Queues [e] for Downloads/Delve.
  Transfer download(RemoteEntry e) {
    terminal.lock.keepAlive();
    if (!_transfers.any((t) => t.active)) _batch.clear();
    final t = Transfer._(_nextTransfer++, e);
    _transfers.add(t);
    _batch.add(t.id);
    _notify();
    unawaited(_runQueue());
    return t;
  }

  void cancel(Transfer t) {
    if (!t.active) return;
    t._cancel = true;
    if (t.state == TransferState.queued) {
      t.state = TransferState.cancelled;
      t.endedAt = _now();
    }
    _notify();
  }

  void retryTransfer(Transfer t) {
    if (t.active) return;
    _transfers.remove(t);
    download(t.entry);
  }

  void clearFinished() {
    _transfers.removeWhere((t) => !t.active);
    _notify();
  }

  Future<bool> openDownload(Transfer t) async {
    final uri = t.uri;
    if (uri == null) return false;
    return device.open(uri, mimeOf(t.name));
  }

  void _resumeTransfers() {
    if (_transfers.any((t) => t.state == TransferState.queued)) {
      unawaited(_runQueue());
    }
  }

  Future<void> _runQueue() async {
    if (_transferRunning) return;
    _transferRunning = true;
    try {
      while (true) {
        final t = _transfers
            .where((t) => t.state == TransferState.queued)
            .firstOrNull;
        if (t == null) break;
        final fs = await _ensure();
        if (fs == null) break; // offline: the retry resumes the queue
        await _runOne(fs, t);
      }
    } finally {
      _transferRunning = false;
      if (!_foreground) setForeground(foreground: false);
    }
  }

  Future<void> _runOne(RemoteFs fs, Transfer t) async {
    t.state = TransferState.running;
    t.startedAt = _now();
    t.bytes = 0;
    _notify();
    Directory? dir;
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      dir = Directory('${await device.scratchDir()}/dl/${t.id}');
      dir.createSync(recursive: true);
      final file = File('${dir.path}/${t.name}');
      final sink = file.openWrite();
      try {
        await fs.download(
          t.entry.path,
          sink,
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
      } finally {
        await sink.close();
      }
      if (t._cancel) {
        t.state = TransferState.cancelled;
      } else {
        t.uri = await device.publish(file.path, t.name, mimeOf(t.name));
        t.state = TransferState.done;
      }
    } on RemoteFsError catch (e) {
      t.state = TransferState.failed;
      t.error = e.failure == FsFailure.unreachable
          ? 'Connection lost'
          : e.failure == FsFailure.denied
          ? 'Permission denied'
          : e.detail;
      if (e.failure == FsFailure.unreachable && identical(_fs, fs)) {
        unawaited(_lost(e.detail));
      }
    } on Object catch (e) {
      t.state = TransferState.failed;
      t.error = '$e';
    } finally {
      t.endedAt = _now();
      try {
        if (dir != null && dir.existsSync()) dir.deleteSync(recursive: true);
      } on Object {
        // the cache is cleaned by Android
      }
    }
    _notify();
    if (t.state == TransferState.done || t.state == TransferState.failed) {
      _finished.add(t);
    }
  }

  // ---------------------------------------------------------------- misc

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _idleClose?.cancel();
    _countNotify?.cancel();
    for (final t in _transfers) {
      t._cancel = true;
    }
    final fs = _fs;
    _fs = null;
    if (fs != null) unawaited(fs.close());
    unawaited(_finished.close());
    super.dispose();
  }
}
