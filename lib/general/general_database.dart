import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../data/db/converters.dart';
import 'general_tables.dart';

export 'general_tables.dart';

part 'general_database.g.dart';

/// The General chats' own file (decision G-8): [AppDatabase.wipe] cannot
/// reach it, so unpairing and a refused token leave these chats alone.
@DriftDatabase(
  tables: [
    GeneralChats,
    GeneralMessages,
    GeneralAttachments,
    OrModels,
    GeneralMeta,
  ],
)
class GeneralDatabase extends _$GeneralDatabase {
  GeneralDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: fileName));

  static const fileName = 'delve_general';

  /// 1: G1a.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());

  // ---- chats

  /// The Chats list: newest first.
  Stream<List<GeneralChatRow>> watchChats({bool archived = false}) =>
      (select(generalChats)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([
              (t) => OrderingTerm.desc(t.updatedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  Stream<GeneralChatRow?> watchChat(String id) =>
      (select(generalChats)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<GeneralChatRow?> chat(String id) =>
      (select(generalChats)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateChat(String id, GeneralChatsCompanion values) =>
      (update(generalChats)..where((t) => t.id.equals(id))).write(values);

  /// A chat with its messages and their images.
  Future<void> deleteChat(String id) => transaction(() async {
    final ids = (selectOnly(generalMessages)
      ..addColumns([generalMessages.id])
      ..where(generalMessages.chatId.equals(id)));
    await (delete(
      generalAttachments,
    )..where((t) => t.messageId.isInQuery(ids))).go();
    await (delete(generalMessages)..where((t) => t.chatId.equals(id))).go();
    await (delete(generalChats)..where((t) => t.id.equals(id))).go();
  });

  // ---- messages

  Stream<List<GeneralMessageRow>> watchMessages(String chatId) =>
      (select(generalMessages)
            ..where((t) => t.chatId.equals(chatId))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .watch();

  Future<List<GeneralMessageRow>> messages(String chatId) =>
      (select(generalMessages)
            ..where((t) => t.chatId.equals(chatId))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();

  Future<GeneralMessageRow?> message(String id) => (select(
    generalMessages,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateMessage(String id, GeneralMessagesCompanion values) =>
      (update(generalMessages)..where((t) => t.id.equals(id))).write(values);

  /// The next `seq` in a chat.
  Future<int> nextSeq(String chatId) async {
    final max = generalMessages.seq.max();
    final row =
        await (selectOnly(generalMessages)
              ..addColumns([max])
              ..where(generalMessages.chatId.equals(chatId)))
            .getSingle();
    return (row.read(max) ?? 0) + 1;
  }

  /// Answers left `streaming` by a killed app: they stopped.
  Future<int> settleInterrupted() =>
      (update(generalMessages)..where((t) => t.status.equals('streaming')))
          .write(const GeneralMessagesCompanion(status: Value('stopped')));

  // ---- attachments

  /// The images of these messages, in order.
  Future<List<GeneralAttachmentRow>> attachmentsOf(Iterable<String> ids) =>
      (select(generalAttachments)
            ..where((t) => t.messageId.isIn(ids))
            ..orderBy([
              (t) => OrderingTerm.asc(t.messageId),
              (t) => OrderingTerm.asc(t.ord),
            ]))
          .get();

  Future<Uint8List?> attachmentBytes(String id) async {
    final row = await (select(
      generalAttachments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.bytes;
  }

  // ---- models

  Future<List<OrModelRow>> models() =>
      (select(orModels)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Stream<List<OrModelRow>> watchModels() =>
      (select(orModels)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<OrModelRow?> model(String id) =>
      (select(orModels)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The whole list at once (a refresh replaces it).
  Future<void> replaceModels(List<OrModelsCompanion> rows) =>
      transaction(() async {
        await delete(orModels).go();
        await batch((b) => b.insertAll(orModels, rows));
      });

  // ---- meta

  Future<String?> meta(String key) async => (await (select(
    generalMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watchMeta(String key) => (select(
    generalMeta,
  )..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<void> setMeta(String key, String? value) => value == null
      ? (delete(generalMeta)..where((t) => t.key.equals(key))).go()
      : into(generalMeta).insertOnConflictUpdate(
          GeneralMetaCompanion.insert(key: key, value: value),
        );

  Future<List<String>?> metaList(String key) async {
    final raw = await meta(key);
    if (raw == null) return null;
    final v = jsonDecode(raw);
    return v is List<Object?> ? [for (final e in v) '$e'] : null;
  }

  Future<void> setMetaList(String key, List<String> value) =>
      setMeta(key, jsonEncode(value));
}

/// Keys of [GeneralMeta].
abstract final class GeneralMetaKeys {
  static const favourites = 'favourites';
  static const defaultModel = 'default_model';
  static const systemPrompt = 'system_prompt';
  static const modelsFetchedAt = 'models_fetched_at';
}
