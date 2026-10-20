import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What pairing leaves on the phone. The token is the only secret; it never
/// leaves secure storage except in the Authorization header / `hello` frame.
class Credentials {
  const Credentials({
    required this.server,
    required this.token,
    required this.deviceId,
    required this.deviceName,
    required this.pairedAt,
  });

  factory Credentials.fromJson(Map<String, Object?> j) => Credentials(
    server: Uri.parse(j['server']! as String),
    token: j['token']! as String,
    deviceId: j['device_id']! as String,
    deviceName: j['device_name']! as String,
    pairedAt: DateTime.parse(j['paired_at']! as String),
  );

  final Uri server;
  final String token;
  final String deviceId;
  final String deviceName;
  final DateTime pairedAt;

  Map<String, Object?> toJson() => {
    'server': server.toString(),
    'token': token,
    'device_id': deviceId,
    'device_name': deviceName,
    'paired_at': pairedAt.toUtc().toIso8601String(),
  };

  @override
  String toString() => 'Credentials($server, device $deviceId)'; // no token
}

abstract interface class CredentialStore {
  Future<Credentials?> read();
  Future<void> write(Credentials credentials);
  Future<void> clear();
}

/// Android Keystore-backed storage (flutter_secure_storage).
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'delve.credentials.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<Credentials?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return Credentials.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      await _storage.delete(key: _key); // unreadable: pair again
      return null;
    }
  }

  @override
  Future<void> write(Credentials credentials) =>
      _storage.write(key: _key, value: jsonEncode(credentials.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// For tests and previews.
class MemoryCredentialStore implements CredentialStore {
  MemoryCredentialStore([this._value]);
  Credentials? _value;

  @override
  Future<Credentials?> read() async => _value;

  @override
  Future<void> write(Credentials credentials) async => _value = credentials;

  @override
  Future<void> clear() async => _value = null;
}
