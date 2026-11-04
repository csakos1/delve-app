import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'phone_key.dart';
import 'terminal_tabs.dart';

/// A small key-value store for the terminal: the phone key, the pinned host
/// keys and the connection settings. In the app it is the Android keystore.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android Keystore-backed storage (flutter_secure_storage).
class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory store for tests.
class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Where the terminal connects. [verified] = a session was live with these
/// settings once (setup is done).
class TerminalConfig {
  const TerminalConfig({
    required this.host,
    this.port = kTerminalPort,
    this.user = kTerminalUser,
    this.verified = false,
  });

  factory TerminalConfig.fromJson(Map<String, Object?> j) => TerminalConfig(
    host: j['host']! as String,
    port: j['port']! as int,
    user: j['user']! as String,
    verified: j['verified'] == true,
  );

  final String host;
  final int port;
  final String user;
  final bool verified;

  /// The key the host key is pinned under.
  String get hostPort => '$host:$port';

  bool get complete => host.isNotEmpty && user.isNotEmpty && port > 0;

  TerminalConfig copyWith({
    String? host,
    int? port,
    String? user,
    bool? verified,
  }) => TerminalConfig(
    host: host ?? this.host,
    port: port ?? this.port,
    user: user ?? this.user,
    verified: verified ?? this.verified,
  );

  Map<String, Object?> toJson() => {
    'host': host,
    'port': port,
    'user': user,
    'verified': verified,
  };

  @override
  bool operator ==(Object other) =>
      other is TerminalConfig &&
      other.host == host &&
      other.port == port &&
      other.user == user &&
      other.verified == verified;

  @override
  int get hashCode => Object.hash(host, port, user, verified);
}

/// The port sshd listens on for the app (22 on the tailnet address is
/// Tailscale SSH; infra D-48).
const kTerminalPort = 2222;

/// The desktop account the terminal logs in to.
const kTerminalUser = 'csakos';

/// The phone key, pinned host keys, connection settings and the font size,
/// all in one [SecretStore].
class TerminalSecrets {
  TerminalSecrets(this._store);

  static const keyKey = 'delve.terminal.key.v1';
  static const hostsKey = 'delve.terminal.hostkeys.v1';
  static const configKey = 'delve.terminal.config.v1';
  static const fontKey = 'delve.terminal.font.v1';
  static const imeKey = 'delve.terminal.ime.v1';
  static const tabsKey = 'delve.terminal.tabs.v1';

  final SecretStore _store;

  /// The stored key, or a new one (stored before it is returned).
  Future<PhoneKey> loadOrCreateKey() async {
    final raw = await _store.read(keyKey);
    if (raw != null) {
      try {
        final seed = base64.decode(raw);
        if (seed.length == 32) return PhoneKey.fromSeed(seed);
      } on FormatException {
        // unreadable value: a new key
      }
    }
    return regenerateKey();
  }

  /// A new key replaces the old one; the old line stops working.
  Future<PhoneKey> regenerateKey() async {
    final key = PhoneKey.generate();
    await _store.write(keyKey, base64.encode(key.seed));
    return key;
  }

  Future<PinnedHostKey?> pinned(String hostPort) async =>
      (await _hosts())[hostPort];

  Future<void> pin(String hostPort, PinnedHostKey key) async {
    final hosts = await _hosts();
    hosts[hostPort] = key;
    await _writeHosts(hosts);
  }

  Future<void> forget(String hostPort) async {
    final hosts = await _hosts();
    if (hosts.remove(hostPort) != null) await _writeHosts(hosts);
  }

  Future<TerminalConfig?> loadConfig() async {
    final raw = await _store.read(configKey);
    if (raw == null) return null;
    try {
      return TerminalConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  Future<void> saveConfig(TerminalConfig config) =>
      _store.write(configKey, jsonEncode(config.toJson()));

  Future<double?> loadFontSize() async =>
      double.tryParse(await _store.read(fontKey) ?? '');

  Future<void> saveFontSize(double size) =>
      _store.write(fontKey, size.toString());

  /// The keyboard heights seen, by orientation (`portrait`, `landscape`):
  /// the terminal lays itself out for the end of a keyboard animation at its
  /// start.
  Future<Map<String, double>> loadImeHeights() async {
    final raw = await _store.read(imeKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      return {
        for (final e in map.entries)
          if (e.value case final num v when v > 0) e.key: v.toDouble(),
      };
    } on Object {
      return {};
    }
  }

  Future<void> saveImeHeights(Map<String, double> heights) =>
      _store.write(imeKey, jsonEncode(heights));

  /// The open tabs (T3). Nothing saved yet: the one tab before T3.
  Future<SavedTabs> loadTabs() async {
    final raw = await _store.read(tabsKey);
    if (raw == null) return SavedTabs.first;
    try {
      return SavedTabs.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return SavedTabs.first;
    }
  }

  Future<void> saveTabs(SavedTabs tabs) =>
      _store.write(tabsKey, jsonEncode(tabs.toJson()));

  Future<Map<String, PinnedHostKey>> _hosts() async {
    final raw = await _store.read(hostsKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      return {
        for (final e in map.entries)
          e.key: PinnedHostKey.fromJson(e.value! as Map<String, Object?>),
      };
    } on Object {
      return {};
    }
  }

  Future<void> _writeHosts(Map<String, PinnedHostKey> hosts) => _store.write(
    hostsKey,
    jsonEncode({for (final e in hosts.entries) e.key: e.value.toJson()}),
  );
}
