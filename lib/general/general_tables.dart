import 'package:drift/drift.dart';

import '../data/db/converters.dart';

// General chats (G1) live in their own database file, `delve_general`: the
// agent database is wiped on unpair and on 4401, these chats never are
// (decision G-8). Nothing here comes from the desktop.

@DataClassName('GeneralChatRow')
class GeneralChats extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get title => text().nullable()();

  /// The user renamed the chat; the first message no longer sets the title.
  BoolColumn get titleSet => boolean().withDefault(const Constant(false))();

  /// The latest text, for the Chats list row.
  TextColumn get preview => text().nullable()();

  /// The active model; switchable at any time.
  TextColumn get modelId => text()();

  /// Thinking for the next message (ignored where the model always thinks
  /// or cannot think).
  BoolColumn get reasoning => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get tokensIn => integer().withDefault(const Constant(0))();
  IntColumn get tokensOut => integer().withDefault(const Constant(0))();
  RealColumn get costUsd => real().withDefault(const Constant(0))();

  /// `usage.prompt_tokens` of the last answer and the model's context
  /// length then: the model chip's ring.
  IntColumn get lastPromptTokens => integer().nullable()();
  IntColumn get lastContextLength => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GeneralMessageRow')
@TableIndex(name: 'general_messages_by_chat', columns: {#chatId, #seq})
class GeneralMessages extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get chatId => text()();

  /// Order inside the chat (1, 2, 3 …).
  IntColumn get seq => integer()();

  /// `user`, `assistant`, or `switch` (the “Switched to …” marker; never
  /// sent to the model).
  TextColumn get role => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get reasoning => text().nullable()();

  /// Assistant: the model that answered. Switch: the new model.
  TextColumn get modelId => text().nullable()();

  /// The inference provider OpenRouter routed to (from the stream).
  TextColumn get provider => text().nullable()();

  /// `streaming`, `final`, `stopped`, `failed` (assistant); `final` otherwise.
  TextColumn get status => text()();

  /// [GeneralFailure.code] of a failed answer, and its message.
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  /// Seconds to wait before Retry (429).
  IntColumn get retryAfterS => integer().nullable()();
  TextColumn get finishReason => text().nullable()();
  IntColumn get tokensIn => integer().nullable()();
  IntColumn get tokensOut => integer().nullable()();
  IntColumn get tokensReasoning => integer().nullable()();
  RealColumn get costUsd => real().nullable()();

  /// OpenRouter's generation id (`x-generation-id`): the cost of a stopped
  /// answer is looked up with it.
  TextColumn get generationId => text().nullable()();

  /// The answer came from a provider that is not on the model's
  /// zero-retention list: `pending` until the user acknowledges it,
  /// then `acknowledged`.
  TextColumn get providerWarning => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Images of a user message. The bytes are in the database (JPEG, ≤ 1.5 MiB
/// each), so a chat, its export and its deletion are one unit.
@DataClassName('GeneralAttachmentRow')
@TableIndex(name: 'general_attachments_by_message', columns: {#messageId})
class GeneralAttachments extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get messageId => text()();
  IntColumn get ord => integer()();
  TextColumn get mime => text()();
  BlobColumn get bytes => blob()();
  IntColumn get size => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// OpenRouter's model list, filtered (decision G-13 and the G0 results):
/// text output, no aliases, no `:variants`, no routers.
@DataClassName('OrModelRow')
class OrModels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get contextLength => integer().nullable()();
  TextColumn get inputModalities => text().map(const StringListConverter())();

  /// USD per token.
  RealColumn get pricePrompt => real()();
  RealColumn get priceCompletion => real()();
  RealColumn get priceCacheRead => real().nullable()();
  BoolColumn get reasoningSupported =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get reasoningMandatory =>
      boolean().withDefault(const Constant(false))();
  TextColumn get reasoningEfforts => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get reasoningDefaultEffort => text().nullable()();

  /// Providers with a strict zero-retention endpoint for this model (no
  /// Safety Retention). Empty: the model cannot be chosen.
  TextColumn get zdrProviders => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small settings: favourites, default model, system prompt, cache times.
@DataClassName('GeneralMetaRow')
class GeneralMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
