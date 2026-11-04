import 'dart:async';

import 'package:flutter/foundation.dart';

import 'phone_key.dart';
import 'secrets.dart';
import 'ssh_link.dart';
import 'terminal_connection.dart';
import 'terminal_lock.dart';

/// The tmux session of the first (and in T2a only) tab.
const kFirstSession = 'delve-1';

/// Terminal font size: 13 sp default, 9–20 sp (design 22).
const kTerminalFontSize = 13.0;
const kTerminalFontMin = 9.0;
const kTerminalFontMax = 20.0;

/// The terminal's state for the app: the phone key, where to connect, the
/// font size, the lock and the one connection. Lives as long as the app.
class TerminalService extends ChangeNotifier {
  TerminalService({
    required this.secrets,
    required SshDialer dialer,
    required this.biometrics,
    required this.defaultHost,
    TerminalTiming timing = const TerminalTiming(),
    DateTime Function()? now,
    Duration lockAfter = kTerminalLockAfter,
  }) : lock = TerminalLock(after: lockAfter, now: now) {
    connection = TerminalConnection(
      dialer: dialer,
      secrets: secrets,
      timing: timing,
      now: now,
      onLive: _onLive,
      onInput: lock.keepAlive,
    );
  }

  final TerminalSecrets secrets;
  final Biometrics biometrics;

  /// The paired server's host: the default for a new setup.
  final String defaultHost;

  final TerminalLock lock;
  late final TerminalConnection connection;

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

  /// Reads the key (creating it the first time), the settings and the font.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _key = await secrets.loadOrCreateKey();
    _config = await secrets.loadConfig() ?? TerminalConfig(host: defaultHost);
    _fontSize = (await secrets.loadFontSize() ?? kTerminalFontSize)
        .clamp(kTerminalFontMin, kTerminalFontMax)
        .toDouble();
    _pinned = await secrets.pinned(_config.hostPort);
    _ime = await secrets.loadImeHeights();
    _ready = true;
    _notify();
  }

  /// The Terminal tab opened: connect if setup is done (idempotent).
  Future<void> start() async {
    await load();
    if (_started || !_config.verified || !_config.complete) return;
    _started = true;
    _connect();
  }

  /// Setup's Connect: saves the settings and connects.
  Future<void> connectWith(TerminalConfig config) async {
    await load();
    _config = config.copyWith(
      verified: _config.verified && _sameTarget(config, _config),
    );
    await secrets.saveConfig(_config);
    _pinned = await secrets.pinned(_config.hostPort);
    _started = true;
    _connect();
    _notify();
  }

  /// Settings: a new host, port or user; reconnects when setup was done.
  Future<void> changeTarget(TerminalConfig config) async {
    await load();
    if (_sameTarget(config, _config)) return;
    _config = config.copyWith(verified: _config.verified);
    await secrets.saveConfig(_config);
    _pinned = await secrets.pinned(_config.hostPort);
    if (_started) _connect();
    _notify();
  }

  /// Settings: a new key; the old authorized_keys line stops working, so
  /// setup shows again.
  Future<PhoneKey> regenerateKey() async {
    await load();
    await connection.disconnect();
    final key = _key = await secrets.regenerateKey();
    _config = _config.copyWith(verified: false);
    await secrets.saveConfig(_config);
    _started = false;
    _notify();
    return key;
  }

  /// Settings: forget the trusted host key; the next connect asks again.
  Future<void> forgetHostKey() async {
    await load();
    await secrets.forget(_config.hostPort);
    _pinned = null;
    _notify();
    if (connection.live) await connection.disconnect();
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

  static bool _sameTarget(TerminalConfig a, TerminalConfig b) =>
      a.host == b.host && a.port == b.port && a.user == b.user;

  void _connect() {
    final key = _key;
    if (key == null) return;
    connection.connect(
      SshTarget(
        host: _config.host,
        port: _config.port,
        user: _config.user,
        session: kFirstSession,
      ),
      key,
      afterSetup: _config.verified,
    );
  }

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
    connection.dispose();
    super.dispose();
  }
}
