import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The phone's own OpenRouter key (a separate key with a monthly limit).
/// Unpairing does not touch it: General does not depend on the desktop.
abstract interface class GeneralKeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> clear();
}

class SecureGeneralKeyStore implements GeneralKeyStore {
  SecureGeneralKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'delve.general.key.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String key) => _storage.write(key: _key, value: key);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// What a pasted key must look like (`sk-or-…`, no spaces).
bool looksLikeOpenRouterKey(String key) =>
    RegExp(r'^sk-or-[A-Za-z0-9_-]{16,}$').hasMatch(key.trim());

/// `sk-or-v1-…4f2a` for the screen.
String maskKey(String key) {
  final k = key.trim();
  if (k.length < 12) return '…';
  final tail = k.substring(k.length - 4);
  final head = k.startsWith('sk-or-v1-') ? 'sk-or-v1-' : k.substring(0, 6);
  return '$head…$tail';
}
