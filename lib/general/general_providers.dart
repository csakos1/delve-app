import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'general_database.dart';
import 'general_export.dart';
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

/// Export / import of the General chats (G1c).
final generalExporterProvider = Provider<GeneralExporter>(
  (ref) => GeneralExporter(ref.watch(generalDatabaseProvider)),
);

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
  // answers a killed app left streaming, before anything else runs
  unawaited(service.settleOnce());
  return service;
});

// ---- what the screens watch (they only watch the database)

/// General chats, newest first; the argument picks the archived ones.
final generalChatsProvider = StreamProvider.family<List<GeneralChatRow>, bool>(
  (ref, archived) =>
      ref.watch(generalDatabaseProvider).watchChats(archived: archived),
);

final generalChatProvider = StreamProvider.autoDispose
    .family<GeneralChatRow?, String>(
      (ref, id) => ref.watch(generalDatabaseProvider).watchChat(id),
    );

final generalMessagesProvider = StreamProvider.autoDispose
    .family<List<GeneralMessageRow>, String>(
      (ref, chatId) => ref.watch(generalDatabaseProvider).watchMessages(chatId),
    );

final generalImagesProvider = StreamProvider.autoDispose
    .family<List<GeneralImageRef>, String>(
      (ref, chatId) => ref.watch(generalDatabaseProvider).watchImages(chatId),
    );

/// The bytes of one General image (JPEG, from the database).
final generalImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
      final bytes = await ref
          .watch(generalDatabaseProvider)
          .attachmentBytes(id);
      if (bytes == null) throw StateError('no image $id');
      return bytes;
    });

/// A chat's answers by model (the Usage sheet).
final generalUsageByModelProvider = StreamProvider.autoDispose
    .family<List<GeneralModelUsage>, String>(
      (ref, chatId) =>
          ref.watch(generalDatabaseProvider).watchUsageByModel(chatId),
    );

/// The cached model list, by name.
final generalModelsProvider = StreamProvider<List<OrModelRow>>(
  (ref) => ref.watch(generalDatabaseProvider).watchModels(),
);

/// One small setting of [GeneralMeta] (null: not set).
final generalMetaProvider = StreamProvider.family<String?, String>(
  (ref, key) => ref.watch(generalDatabaseProvider).watchMeta(key),
);

/// The favourites in their order (the defaults until the user edits them).
final generalFavouritesProvider = Provider<List<String>>((ref) {
  final raw = ref.watch(generalMetaProvider(GeneralMetaKeys.favourites)).value;
  if (raw == null) return kDefaultFavourites;
  try {
    final v = jsonDecode(raw);
    if (v is List<Object?>) return [for (final e in v) '$e'];
  } on FormatException {
    // fall through to the defaults
  }
  return kDefaultFavourites;
});

/// The default model of a new General chat.
final generalDefaultModelProvider = Provider<String>(
  (ref) =>
      ref.watch(generalMetaProvider(GeneralMetaKeys.defaultModel)).value ??
      kDefaultModel,
);

/// The key's limits and spend (`GET /key`); null without a key.
final generalKeyInfoProvider = FutureProvider.autoDispose<KeyInfo?>((
  ref,
) async {
  final client = ref.watch(openRouterClientProvider);
  if (client == null) return null;
  return client.keyInfo();
});
