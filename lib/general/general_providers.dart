import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'general_database.dart';
import 'general_key_store.dart';
import 'general_service.dart';
import 'model_catalog.dart';
import 'openrouter_client.dart';
import 'openrouter_errors.dart';

/// The General chats' own database. Tests override it with an in-memory one.
final generalDatabaseProvider = Provider<GeneralDatabase>((ref) {
  final db = GeneralDatabase();
  ref.onDispose(db.close);
  return db;
});

final generalKeyStoreProvider = Provider<GeneralKeyStore>(
  (ref) => SecureGeneralKeyStore(),
);

/// Tests answer OpenRouter with a fake adapter.
final openRouterAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

/// The saved OpenRouter key (null: none yet).
class GeneralKeyController extends AsyncNotifier<String?> {
  GeneralKeyStore get _store => ref.read(generalKeyStoreProvider);

  @override
  Future<String?> build() => _store.read();

  /// Checks [key] with `GET /key` and saves it. A rejected key
  /// ([GeneralUnauthorized]) is not saved; without a connection it is saved
  /// unchecked. Returns the key's limits when they could be read.
  Future<KeyInfo?> save(String key) async {
    final k = key.trim();
    if (!looksLikeOpenRouterKey(k)) {
      throw const GeneralUnauthorized('This is not an OpenRouter key');
    }
    final client = OpenRouterClient(
      key: k,
      adapter: ref.read(openRouterAdapterProvider),
    );
    KeyInfo? info;
    try {
      info = await client.keyInfo();
    } on GeneralNetwork {
      info = null;
    } finally {
      client.close();
    }
    await _store.write(k);
    state = AsyncData(k);
    return info;
  }

  Future<void> remove() async {
    await _store.clear();
    state = const AsyncData(null);
  }
}

final generalKeyProvider = AsyncNotifierProvider<GeneralKeyController, String?>(
  GeneralKeyController.new,
);

/// The OpenRouter client for the saved key; null without a key.
final openRouterClientProvider = Provider<OpenRouterClient?>((ref) {
  final key = ref.watch(generalKeyProvider).value;
  if (key == null) return null;
  final client = OpenRouterClient(
    key: key,
    adapter: ref.watch(openRouterAdapterProvider),
  );
  ref.onDispose(client.close);
  return client;
});

final modelCatalogProvider = Provider<ModelCatalog>(
  (ref) => ModelCatalog(ref.watch(generalDatabaseProvider)),
);

final generalChatServiceProvider = Provider<GeneralChatService>((ref) {
  final service = GeneralChatService(
    db: ref.watch(generalDatabaseProvider),
    catalog: ref.watch(modelCatalogProvider),
    client: () => ref.read(openRouterClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
