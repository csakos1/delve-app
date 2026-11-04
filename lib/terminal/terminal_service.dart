import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'phone_key.dart';
import 'secrets.dart';
import 'ssh_link.dart';
import 'terminal_connection.dart';
import 'terminal_lock.dart';
import 'terminal_tabs.dart';

export 'terminal_tabs.dart' show kFirstSession;

/// Terminal font size: 13 sp default, 9–20 sp (design 22).
const kTerminalFontSize = 13.0;
const kTerminalFontMin = 9.0;
const kTerminalFontMax = 20.0;

/// A tmux command on the desktop failed (rename, kill).
class TmuxCommandFailed implements Exception {
  const TmuxCommandFailed(this.detail);

  final String detail;

  @override
  String toString() => detail;
}

/// The terminal's state for the app: the phone key, where to connect, the
/// font size, the lock and the tabs – each a tmux session with its own SSH
/// connection (T3). Lives as long as the app.
///
/// Only the active tab and the one left last stay connected: the last one
/// for [TerminalTiming.keepPrevious], so switching back is instant; the
/// others are parked ([OfflineReason.parked]) and connect when they come to
/// the front.
class TerminalService extends ChangeNotifier {
  TerminalService({
    required this.secrets,
    required SshDialer dialer,
    required this.biometrics,
    required this.defaultHost,
    this.timing = const TerminalTiming(),
    DateTime Function()? now,
    Duration lockAfter = kTerminalLockAfter,
  }) : _dialer = dialer,
       _now = now,
       lock = TerminalLock(after: lockAfter, now: now) {
    // before load: the one tab of a terminal set up before T3
    _tabs.add(_makeTab(SavedTabs.first.tabs.single));
    _active = 0;
  }

  final TerminalSecrets secrets;
  final Biometrics biometrics;
  final TerminalTiming timing;
  final SshDialer _dialer;
  final DateTime Function()? _now;

  /// The paired server's host: the default for a new setup.
  final String defaultHost;

  final TerminalLock lock;

  final List<TerminalTab> _tabs = [];
  int _active = -1;
  int _nextId = 0;
  TerminalTab? _previous;
  Timer? _keep;

  /// The open tabs, in the tab bar's order.
  List<TerminalTab> get tabs => List.unmodifiable(_tabs);

  /// The active tab's index; -1 when every tab is closed.
  int get activeIndex => _active;

  /// The tab in front (null: none open).
  TerminalTab? get current => _active < 0 ? null : _tabs[_active];

  /// The active tab's connection. Only while a tab is open ([current]);
  /// setup always has one.
  TerminalConnection get connection => current!.connection;

  bool _ready = false;
  bool get ready => _ready;

  PhoneKey? _key;
  PhoneKey? get key => _key;

  TerminalConfig _config = const TerminalConfig(host: '');
  TerminalConfig get config => _config;

  PinnedHostKey? _pinned;

  /// The trusted key of the current host:port (for Settings).
  PinnedHostKey? get pinned => _pinned;

  /// The extra key row's page (design 22: the row remembers its page).
  int extraKeysPage = 0;

  double _fontSize = kTerminalFontSize;
  double get fontSize => _fontSize;

  Map<String, double> _ime = {};

  /// The keyboard's last settled height in this orientation (`portrait`,
  /// `landscape`).
  double? imeHeight(String slot) => _ime[slot];

  /// A settled keyboard height; kept for the next start (a change below a
  /// pixel is noise).
  void rememberImeHeight(String slot, double height) {
    if (height <= 0) return;
    final old = _ime[slot];
    if (old != null && (old - height).abs() < 1) return;
    _ime = {..._ime, slot: height};
    unawaited(secrets.saveImeHeights(_ime));
  }

  bool _started = false;
  Future<void>? _loading;
  bool _disposed = false;

  /// Reads the key (creating it the first time), the settings, the font
  /// and the tabs.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _key = await secrets.loadOrCreateKey();
    _config = await secrets.loadConfig() ?? TerminalConfig(host: defaultHost);
    _fontSize = (await secrets.loadFontSize() ?? kTerminalFontSize)
        .clamp(kTerminalFontMin, kTerminalFontMax)
        .toDouble();
    _pinned = await secrets.pinned(_config.hostPort);
    _ime = await secrets.loadImeHeights();
    _restore(await secrets.loadTabs());
    if (!_config.verified) _ensureTab();
    _ready = true;
    _notify();
  }

  /// The saved tabs; the first one made before load is kept when it is the
  /// same (nothing has used it yet: start and setup wait for load).
  void _restore(SavedTabs saved) {
    final kept = _tabs.isNotEmpty ? _tabs.first : null;
    _tabs.clear();
    for (final (i, t) in saved.tabs.indexed) {
      if (i == 0 && kept != null && kept.saved == t) {
        _tabs.add(kept);
      } else {
        _tabs.add(_makeTab(t));
      }
    }
    if (kept != null && !_tabs.contains(kept)) kept.connection.dispose();
    _active = saved.active;
  }

  /// Setup needs a tab to connect: the first one again when all were
  /// closed.
  void _ensureTab() {
    if (_tabs.isNotEmpty) return;
    _tabs.add(_makeTab(SavedTabs.first.tabs.single));
    _active = 0;
    _persist();
  }

  TerminalTab _makeTab(SavedTab t) => TerminalTab(
    id: _nextId++,
    session: t.session,
    app: t.app,
    statusRows: t.statusRows,
    connection: TerminalConnection(
      dialer: _dialer,
      secrets: secrets,
      timing: timing,
      now: _now,
      onLive: _onLive,
      onInput: lock.keepAlive,
      statusRows: viewStatusRows(t.statusRows),
      wheelLines: wheelLinesFor(app: t.app),
    ),
  );

  /// The Terminal tab opened: connect the active tab if setup is done
  /// (idempotent).
  Future<void> start() async {
    await load();
    if (_started || !_config.verified || !_config.complete) return;
    _started = true;
    _activateCurrent();
  }

  /// Setup's Connect: saves the settings and connects.
  Future<void> connectWith(TerminalConfig config) async {
    await load();
    _config = config.copyWith(
      verified: _config.verified && _sameTarget(config, _config),
    );
    await secrets.saveConfig(_config);
    _pinned = await secrets.pinned(_config.hostPort);
    _ensureTab();
    _started = true;
    _connect(current!);
    _notify();
  }

  /// Settings: a new host, port or user; the active tab reconnects when
  /// setup was done, the others connect there when they come to the front.
  Future<void> changeTarget(TerminalConfig config) async {
    await load();
    if (_sameTarget(config, _config)) return;
    _config = config.copyWith(verified: _config.verified);
    await secrets.saveConfig(_config);
    _pinned = await secrets.pinned(_config.hostPort);
    if (_started) {
      for (final t in _tabs) {
        if (t != current) _park(t);
      }
      final c = current;
      if (c != null) _connect(c);
    }
    _notify();
  }

  /// Settings: a new key; the old authorized_keys line stops working, so
  /// setup shows again.
  Future<PhoneKey> regenerateKey() async {
    await load();
    for (final t in _tabs) {
      await t.connection.disconnect();
    }
    final key = _key = await secrets.regenerateKey();
    _config = _config.copyWith(verified: false);
    await secrets.saveConfig(_config);
    _started = false;
    _ensureTab();
    _notify();
    return key;
  }

  /// Settings: forget the trusted host key; the next connect asks again.
  Future<void> forgetHostKey() async {
    await load();
    await secrets.forget(_config.hostPort);
    _pinned = null;
    _notify();
    for (final t in _tabs) {
      if (t.connection.live) await t.connection.disconnect();
    }
  }

  Future<void> setFontSize(double size) async {
    final s = size.clamp(kTerminalFontMin, kTerminalFontMax).toDouble();
    if (s == _fontSize) return;
    _fontSize = s;
    _notify();
    await secrets.saveFontSize(s);
  }

  /// The lock screen's Unlock: fingerprint or the phone's credential. A
  /// phone without a screen lock has nothing to check: it opens.
  Future<UnlockOutcome> unlock(String reason) async {
    final out = await biometrics.unlock(reason);
    if (out.result == UnlockResult.ok ||
        out.result == UnlockResult.unavailable) {
      lock.touch();
      _notify();
    }
    return out;
  }

  // ── tabs ──────────────────────────────────────────────────────────────

  /// Brings tab [index] to the front: it connects, the one left stays
  /// connected for [TerminalTiming.keepPrevious], any other is parked.
  void select(int index) {
    if (index < 0 || index >= _tabs.length || index == _active) return;
    final left = current;
    _active = index;
    _keepPrevious(left);
    _persist();
    _activateCurrent();
    _notify();
  }

  /// A new tab with a new app session, `delve-N` with the smallest N not
  /// taken by a tab or a session on the desktop (when the list can be read;
  /// a name that exists would attach that session instead).
  Future<TerminalTab> newTab() async {
    await load();
    final taken = {for (final t in _tabs) t.session};
    try {
      taken.addAll((await listSessions()).map((s) => s.name));
    } on Object {
      // offline: the tabs' names only
    }
    final tab = _makeTab(SavedTab(session: nextSessionName(taken)));
    _tabs.add(tab);
    select(_tabs.length - 1);
    return tab;
  }

  /// A session from the desktop's list: its tab if one is open, else a new
  /// tab for it (an app session stays one; a desktop session keeps its
  /// status line and tmux's wheel step).
  void openSession(TmuxSession s) {
    final i = _tabs.indexWhere((t) => t.session == s.name);
    if (i >= 0) {
      select(i);
      return;
    }
    _tabs.add(
      _makeTab(
        SavedTab(
          session: s.name,
          app: s.app,
          statusRows: s.app ? 0 : s.statusRows,
        ),
      ),
    );
    select(_tabs.length - 1);
  }

  /// Closes a tab: only its connection; the tmux session keeps running on
  /// the desktop (design 22: close tab = detach).
  Future<void> closeTab(TerminalTab tab) async {
    final i = _tabs.indexOf(tab);
    if (i < 0) return;
    final wasActive = i == _active;
    _tabs.removeAt(i);
    if (_previous == tab) {
      _previous = null;
      _keep?.cancel();
    }
    if (_active > i) {
      _active--;
    } else if (wasActive) {
      _active = _tabs.isEmpty ? -1 : math.min(i, _tabs.length - 1);
    }
    _persist();
    if (wasActive) _activateCurrent();
    _notify();
    await tab.connection.disconnect();
    tab.connection.dispose();
  }

  /// Drag in the tab bar: the tab at [from] goes to [to] (its final index).
  void moveTab(int from, int to) {
    if (from == to || from < 0 || from >= _tabs.length) return;
    final active = current;
    final tab = _tabs.removeAt(from);
    _tabs.insert(to.clamp(0, _tabs.length), tab);
    _active = active == null ? -1 : _tabs.indexOf(active);
    _persist();
    _notify();
  }

  /// The tmux sessions on the desktop (22g1), over a connected tab or a
  /// connection of its own.
  Future<List<TmuxSession>> listSessions() async =>
      parseSessions((await _run(listSessionsCommand)).output);

  /// Renames a session on the desktop; its tabs follow ([to] as
  /// [cleanSessionName] gives it).
  Future<void> renameSession(String from, String to) async {
    if (from == to) return;
    final r = await _run(renameSessionCommand(from, to));
    if (!r.ok) throw TmuxCommandFailed(_why(r));
    for (final t in _tabs) {
      if (t.session != from) continue;
      t.session = to;
      t.connection.retarget(_targetFor(t));
    }
    _persist();
    _notify();
  }

  /// Ends a session on the desktop (and whatever runs in it); its tabs
  /// close.
  Future<void> killSession(String name) async {
    final r = await _run(killSessionCommand(name));
    if (!r.ok) throw TmuxCommandFailed(_why(r));
    for (final t in [..._tabs]) {
      if (t.session == name) await closeTab(t);
    }
  }

  static String _why(SshRunResult r) =>
      r.error.isNotEmpty ? r.error : 'tmux exited with ${r.exitCode}';

  /// The app went to the background or came back: every tab.
  void setForeground({required bool foreground}) {
    for (final t in _tabs) {
      t.connection.setForeground(foreground: foreground);
    }
  }

  /// The phone's network changed: every tab checks or retries.
  void networkChanged() {
    for (final t in _tabs) {
      t.connection.networkChanged();
    }
  }

  void _keepPrevious(TerminalTab? left) {
    _keep?.cancel();
    final front = current;
    _previous = left == front ? null : left;
    for (final t in _tabs) {
      if (t != front && t != _previous) _park(t);
    }
    final kept = _previous;
    if (kept == null) return;
    _keep = Timer(timing.keepPrevious, () {
      if (_previous != kept || kept == current) return;
      _previous = null;
      _park(kept);
    });
  }

  /// Disconnects a tab that is not in front (nothing to do when it is not
  /// connected, or stopped for a reason the user should see).
  void _park(TerminalTab t) {
    final c = t.connection;
    final connected = switch (c.phase) {
      TermPhase.live ||
      TermPhase.connecting ||
      TermPhase.verifying ||
      TermPhase.reconnecting => true,
      TermPhase.offline => c.offlineReason == OfflineReason.background,
      _ => false,
    };
    if (connected) unawaited(c.disconnect(reason: OfflineReason.parked));
  }

  /// Connects the tab in front when it is waiting for that: not yet
  /// connected, parked, or failed. A tab the user disconnected, whose
  /// session ended, or whose host key was refused stays as it is (its state
  /// line says why and how to go on).
  void _activateCurrent() {
    final t = current;
    if (t == null || !_started) return;
    final c = t.connection;
    final waiting = switch (c.phase) {
      TermPhase.idle || TermPhase.failed => true,
      TermPhase.offline => c.offlineReason == OfflineReason.parked,
      _ => false,
    };
    if (waiting) _connect(t);
  }

  SshTarget _targetFor(TerminalTab t) => SshTarget(
    host: _config.host,
    port: _config.port,
    user: _config.user,
    session: t.session,
    app: t.app,
  );

  void _connect(TerminalTab t) {
    final key = _key;
    if (key == null) return;
    t.connection.connect(_targetFor(t), key, afterSetup: _config.verified);
  }

  /// A command without a pty: over the tab in front when it is connected,
  /// else any connected tab, else a connection of its own (which only
  /// trusts the pinned host key: no question to ask in a sheet).
  Future<SshRunResult> _run(String command) async {
    await load();
    final front = current;
    for (final t in [?front, ..._tabs.where((t) => t != front)]) {
      final r = await t.connection.run(command);
      if (r != null) return r;
    }
    final key = _key!;
    return _dialer.run(
      SshTarget(
        host: _config.host,
        port: _config.port,
        user: _config.user,
        session: kFirstSession,
      ),
      key: key,
      verify: (type, fingerprint) async =>
          (await secrets.pinned(
            _config.hostPort,
          ))?.matches(type, fingerprint) ??
          false,
      command: command,
    );
  }

  void _persist() {
    unawaited(
      secrets.saveTabs(SavedTabs([for (final t in _tabs) t.saved], _active)),
    );
  }

  static bool _sameTarget(TerminalConfig a, TerminalConfig b) =>
      a.host == b.host && a.port == b.port && a.user == b.user;

  void _onLive() {
    // only the end of setup opens the lock (the user is there and just
    // trusted the key); a connect or reconnect must not unlock the terminal
    if (!_config.verified) lock.touch();
    unawaited(_afterLive());
  }

  Future<void> _afterLive() async {
    _pinned = await secrets.pinned(_config.hostPort);
    if (!_config.verified) {
      _config = _config.copyWith(verified: true);
      await secrets.saveConfig(_config);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _keep?.cancel();
    for (final t in _tabs) {
      t.connection.dispose();
    }
    super.dispose();
  }
}
