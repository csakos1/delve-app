import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'general_database.dart';
import 'model_catalog.dart';
import 'openrouter_client.dart';
import 'openrouter_errors.dart';

/// The longest automatic chat title (from the first message, no model call).
const int kGeneralTitleMax = 45;

/// The title made from the first message: whitespace collapsed, cut at a
/// word boundary near [kGeneralTitleMax], with an ellipsis.
String generalTitleFrom(String text, {bool hasImages = false}) {
  final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return hasImages ? 'Image' : 'New chat';
  if (t.length <= kGeneralTitleMax) return t;
  var cut = t.lastIndexOf(' ', kGeneralTitleMax);
  if (cut < kGeneralTitleMax ~/ 2) cut = kGeneralTitleMax;
  return '${t.substring(0, cut).trimRight()}…';
}

/// Sends General messages and keeps their answers in [GeneralDatabase]. The
/// UI only watches the database; one answer streams per chat at a time.
class GeneralChatService {
  GeneralChatService({
    required this.db,
    required OpenRouterClient? Function() client,
    ModelCatalog? catalog,
    DateTime Function()? now,
    this.flushEvery = const Duration(milliseconds: 120),
    this.costLookupDelays = const [
      Duration(seconds: 3),
      Duration(seconds: 8),
      Duration(seconds: 20),
    ],
  }) : _client = client,
       catalog = catalog ?? ModelCatalog(db, now: now),
       _now = now ?? DateTime.now;

  final GeneralDatabase db;
  final ModelCatalog catalog;
  final OpenRouterClient? Function() _client;
  final DateTime Function() _now;

  /// How often a streaming answer is written to the database.
  final Duration flushEvery;

  /// Waits before asking OpenRouter what a stopped answer cost.
  final List<Duration> costLookupDelays;

  static const _uuid = Uuid();
  final Map<String, CancelToken> _running = {};
  final Set<Future<void>> _background = {};
  bool _disposed = false;

  bool isStreaming(String chatId) => _running.containsKey(chatId);

  /// Answers a killed app left `streaming` are `stopped`.
  Future<void> settleInterrupted() => db.settleInterrupted();

  Future<void>? _settled;

  /// [settleInterrupted] once per app run, before the first answer of this
  /// run starts (so it never stops a live one).
  Future<void> settleOnce() => _settled ??= settleInterrupted();

  /// Waits for background work (cost lookups); for tests.
  Future<void> idle() async {
    while (_background.isNotEmpty) {
      await Future.wait(_background.toList());
    }
  }

  void dispose() {
    _disposed = true;
    for (final c in _running.values) {
      c.cancel();
    }
    _running.clear();
  }

  // ---- chats

  /// A new, empty chat with [modelId] or the default model, and the
  /// thinking state chosen before its first message.
  Future<String> createChat({
    String? modelId,
    bool reasoning = true,
    String? effort,
  }) async {
    final model = modelId ?? await catalog.defaultModel();
    checkModelId(model);
    final id = _uuid.v4();
    final now = _now().toUtc();
    await db
        .into(db.generalChats)
        .insert(
          GeneralChatsCompanion.insert(
            id: id,
            modelId: model,
            createdAt: now,
            updatedAt: now,
            reasoning: Value(reasoning),
            reasoningEffort: Value(effort),
          ),
        );
    return id;
  }

  Future<void> rename(String chatId, String title) {
    final t = title.trim();
    return db.updateChat(
      chatId,
      GeneralChatsCompanion(
        title: Value(t.isEmpty ? null : t),
        titleSet: Value(t.isNotEmpty),
      ),
    );
  }

  Future<void> archive(String chatId, {bool archived = true}) =>
      db.updateChat(chatId, GeneralChatsCompanion(archived: Value(archived)));

  Future<void> deleteChat(String chatId) async {
    _running.remove(chatId)?.cancel();
    await db.deleteChat(chatId);
  }

  Future<void> setReasoning(String chatId, {required bool on}) =>
      db.updateChat(chatId, GeneralChatsCompanion(reasoning: Value(on)));

  /// The thinking effort for the next message; null: the model's default.
  /// Choosing an effort turns thinking on.
  Future<void> setEffort(String chatId, String? effort) => db.updateChat(
    chatId,
    GeneralChatsCompanion(
      reasoningEffort: Value(effort == 'none' ? null : effort),
      reasoning: effort == null ? const Value.absent() : const Value(true),
    ),
  );

  /// Switches the chat's model; a chat with messages gets a “Switched to”
  /// marker (one marker, however often the model changes in between).
  Future<void> setModel(String chatId, String modelId) async {
    checkModelId(modelId);
    final model = await db.model(modelId);
    if (model == null || !model.selectable) {
      throw GeneralModelUnavailable('$modelId has no zero-retention provider');
    }
    final chat = await _chat(chatId);
    if (chat.modelId == modelId) return;
    final msgs = await db.messages(chatId);
    await db.transaction(() async {
      await db.updateChat(
        chatId,
        GeneralChatsCompanion(modelId: Value(modelId)),
      );
      if (msgs.isEmpty) return;
      final last = msgs.last;
      if (last.role == 'switch') {
        if (_previousModel(msgs) == modelId) {
          await (db.delete(
            db.generalMessages,
          )..where((t) => t.id.equals(last.id))).go();
        } else {
          await db.updateMessage(
            last.id,
            GeneralMessagesCompanion(modelId: Value(modelId)),
          );
        }
        return;
      }
      await db
          .into(db.generalMessages)
          .insert(
            GeneralMessagesCompanion.insert(
              id: _uuid.v4(),
              chatId: chatId,
              seq: last.seq + 1,
              role: 'switch',
              status: 'final',
              modelId: Value(modelId),
              createdAt: _now().toUtc(),
            ),
          );
    });
  }

  /// The model before the trailing switch marker.
  static String? _previousModel(List<GeneralMessageRow> msgs) {
    for (final m in msgs.reversed.skip(1)) {
      if (m.modelId != null) return m.modelId;
    }
    return null;
  }

  Future<void> acknowledgeWarning(String messageId) => db.updateMessage(
    messageId,
    const GeneralMessagesCompanion(providerWarning: Value('acknowledged')),
  );

  // ---- sending

  /// Sends [text] (and JPEG [images], already prepared) and streams the
  /// answer; completes when the answer is final, stopped or failed. Throws
  /// a [GeneralFailure] when nothing could be sent (no key, a model without
  /// a zero-retention provider, an unacknowledged provider warning).
  Future<void> send(
    String chatId,
    String text, {
    List<(String, Uint8List)> images = const [],
  }) async {
    final client = _client();
    if (client == null) throw const GeneralNoKey();
    final cancel = _claim(chatId);
    try {
      await settleOnce();
      await _send(client, chatId, text, images, cancel);
    } finally {
      _release(chatId, cancel);
    }
  }

  Future<void> _send(
    OpenRouterClient client,
    String chatId,
    String text,
    List<(String, Uint8List)> images,
    CancelToken cancel,
  ) async {
    final chat = await _chat(chatId);
    final model = await _usableModel(chat.modelId);
    final msgs = await db.messages(chatId);
    _checkWarnings(msgs);
    final now = _now().toUtc();
    final userId = _uuid.v4();
    final seq = (msgs.isEmpty ? 0 : msgs.last.seq) + 1;
    await db.transaction(() async {
      await db
          .into(db.generalMessages)
          .insert(
            GeneralMessagesCompanion.insert(
              id: userId,
              chatId: chatId,
              seq: seq,
              role: 'user',
              status: 'final',
              content: Value(text),
              createdAt: now,
            ),
          );
      for (final (i, (mime, bytes)) in images.indexed) {
        await db
            .into(db.generalAttachments)
            .insert(
              GeneralAttachmentsCompanion.insert(
                id: _uuid.v4(),
                messageId: userId,
                ord: i,
                mime: mime,
                bytes: bytes,
                size: bytes.length,
              ),
            );
      }
      await db.updateChat(
        chatId,
        GeneralChatsCompanion(
          title: chat.titleSet || chat.title != null
              ? const Value.absent()
              : Value(generalTitleFrom(text, hasImages: images.isNotEmpty)),
          preview: Value(_preview(text)),
          updatedAt: Value(now),
        ),
      );
    });
    await _answer(client, chat, model, cancel);
  }

  /// One answer at a time per chat: the token that [stop] cancels.
  CancelToken _claim(String chatId) {
    if (isStreaming(chatId)) throw StateError('an answer is streaming');
    return _running[chatId] = CancelToken();
  }

  void _release(String chatId, CancelToken cancel) {
    if (identical(_running[chatId], cancel)) _running.remove(chatId);
  }

  /// Answers the last user message again after a failed or stopped answer
  /// (the old answer is replaced).
  Future<void> retry(String chatId) async {
    final client = _client();
    if (client == null) throw const GeneralNoKey();
    final cancel = _claim(chatId);
    try {
      await settleOnce();
      await _retry(client, chatId, cancel);
    } finally {
      _release(chatId, cancel);
    }
  }

  Future<void> _retry(
    OpenRouterClient client,
    String chatId,
    CancelToken cancel,
  ) async {
    final chat = await _chat(chatId);
    final model = await _usableModel(chat.modelId);
    final msgs = await db.messages(chatId);
    final last = msgs.isEmpty ? null : msgs.last;
    if (last != null && last.role == 'assistant' && last.status == 'failed') {
      await (db.delete(
        db.generalMessages,
      )..where((t) => t.id.equals(last.id))).go();
    }
    final rest = await db.messages(chatId);
    _checkWarnings(rest);
    if (!rest.any((m) => m.role == 'user')) return;
    await _answer(client, chat, model, cancel);
  }

  /// Closes the connection; the answer so far stays as `stopped`.
  void stop(String chatId) => _running[chatId]?.cancel();

  void _checkWarnings(List<GeneralMessageRow> msgs) {
    if (msgs.any((m) => m.providerWarning == 'pending')) {
      throw const GeneralWarningPending();
    }
  }

  Future<GeneralChatRow> _chat(String id) async {
    final chat = await db.chat(id);
    if (chat == null) throw StateError('no chat $id');
    return chat;
  }

  Future<OrModelRow> _usableModel(String id) async {
    final model = await db.model(id);
    if (model == null) {
      throw GeneralModelUnavailable('$id is not in the model list');
    }
    if (!model.selectable) {
      throw GeneralModelUnavailable('$id has no zero-retention provider');
    }
    return model;
  }

  static String _preview(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= 140 ? t : t.substring(0, 140);
  }

  /// The history for the model: user messages (with their images when the
  /// model reads images) and the final or stopped answers; failed answers
  /// and switch markers stay out.
  Future<List<GeneralTurn>> history(
    String chatId, {
    required bool images,
  }) async {
    final msgs = await db.messages(chatId);
    final userIds = [
      for (final m in msgs)
        if (m.role == 'user') m.id,
    ];
    final atts = images
        ? await db.attachmentsOf(userIds)
        : const <GeneralAttachmentRow>[];
    final byMessage = <String, List<(String, Uint8List)>>{};
    for (final a in atts) {
      byMessage.putIfAbsent(a.messageId, () => []).add((a.mime, a.bytes));
    }
    return [
      for (final m in msgs)
        if (m.role == 'user')
          GeneralTurn.user(m.content, images: byMessage[m.id] ?? const [])
        else if (m.role == 'assistant' &&
            (m.status == 'final' || m.status == 'stopped') &&
            m.content.isNotEmpty)
          GeneralTurn.assistant(m.content),
    ];
  }

  Future<void> _answer(
    OpenRouterClient client,
    GeneralChatRow chat,
    OrModelRow model,
    CancelToken cancel,
  ) async {
    final chatId = chat.id;
    final turns = await history(chatId, images: model.readsImages);
    final system = await db.meta(GeneralMetaKeys.systemPrompt);
    final body = buildChatBody(
      model: model.id,
      turns: turns,
      systemPrompt: system,
      reasoning: model.reasoningSpec.param(
        on: chat.reasoning,
        effort: chat.reasoningEffort,
      ),
      sendImages: model.readsImages,
    );
    final id = _uuid.v4();
    await db
        .into(db.generalMessages)
        .insert(
          GeneralMessagesCompanion.insert(
            id: id,
            chatId: chatId,
            seq: await db.nextSeq(chatId),
            role: 'assistant',
            status: 'streaming',
            modelId: Value(model.id),
            createdAt: _now().toUtc(),
          ),
        );
    final content = StringBuffer();
    final thought = StringBuffer();
    var lastFlush = _now();
    var dirty = false;
    String? provider;
    String? generationId;
    String? finish;
    ChatUsage? usage;

    Future<void> flush() async {
      if (!dirty) return;
      dirty = false;
      lastFlush = _now();
      await db.updateMessage(
        id,
        GeneralMessagesCompanion(
          content: Value(content.toString()),
          reasoning: Value(thought.isEmpty ? null : thought.toString()),
        ),
      );
    }

    // not final: the try block may set them before a catch sets them again
    String status;
    GeneralFailure? failure;
    try {
      await for (final ev in client.chat(body, cancel: cancel)) {
        switch (ev) {
          case ChatStarted(generationId: final gid?):
            generationId = gid;
            await db.updateMessage(
              id,
              GeneralMessagesCompanion(generationId: Value(gid)),
            );
          case ChatStarted():
            break;
          case ChatRoute(provider: final p):
            provider = p;
          case ChatDelta(content: final c, reasoning: final r):
            content.write(c);
            thought.write(r);
            dirty = true;
            if (_now().difference(lastFlush) >= flushEvery) await flush();
          case ChatFinish(:final reason):
            finish = reason;
          case final ChatUsage used:
            usage = used;
        }
      }
      status = 'final';
      failure = null;
    } on GeneralCancelled {
      status = 'stopped';
      failure = null;
    } on GeneralFailure catch (f) {
      status = 'failed';
      failure = f;
    }
    final pendingWarning =
        provider != null &&
        model.zdrProviders.isNotEmpty &&
        !model.zdrProviders.contains(provider);
    final u = usage;
    await db.transaction(() async {
      await db.updateMessage(
        id,
        GeneralMessagesCompanion(
          content: Value(content.toString()),
          reasoning: Value(thought.isEmpty ? null : thought.toString()),
          status: Value(status),
          provider: Value(provider),
          finishReason: Value(finish),
          errorCode: Value(failure?.code),
          errorMessage: Value(failure?.message),
          retryAfterS: Value(switch (failure) {
            GeneralRateLimited(:final retryAfter?) => retryAfter.inSeconds,
            _ => null,
          }),
          tokensIn: Value(u?.promptTokens),
          tokensOut: Value(u?.completionTokens),
          tokensReasoning: Value(u?.reasoningTokens),
          costUsd: Value(u?.cost),
          providerWarning: Value(pendingWarning ? 'pending' : null),
        ),
      );
      if (u != null) {
        await _addToChat(
          chatId,
          u.promptTokens,
          u.completionTokens,
          u.cost,
          model,
        );
      }
      if (status != 'failed' && content.isNotEmpty) {
        await db.updateChat(
          chatId,
          GeneralChatsCompanion(
            preview: Value(_preview(content.toString())),
            updatedAt: Value(_now().toUtc()),
          ),
        );
      }
    });
    final genId = generationId;
    if (status == 'stopped' && u == null && genId != null) {
      _track(_lookUpCost(client, chatId, id, genId, model));
    }
  }

  Future<void> _addToChat(
    String chatId,
    int? tokensIn,
    int? tokensOut,
    double? cost,
    OrModelRow model,
  ) async {
    final chat = await db.chat(chatId);
    if (chat == null) return;
    await db.updateChat(
      chatId,
      GeneralChatsCompanion(
        tokensIn: Value(chat.tokensIn + (tokensIn ?? 0)),
        tokensOut: Value(chat.tokensOut + (tokensOut ?? 0)),
        costUsd: Value(chat.costUsd + (cost ?? 0)),
        lastPromptTokens: tokensIn == null
            ? const Value.absent()
            : Value(tokensIn),
        lastContextLength: tokensIn == null
            ? const Value.absent()
            : Value(model.contextLength),
      ),
    );
  }

  void _track(Future<void> f) {
    _background.add(f);
    unawaited(f.whenComplete(() => _background.remove(f)));
  }

  /// A stopped answer has no `usage`; OpenRouter still bills what was
  /// generated (G0b: `cancelled: true`, `total_cost` > 0).
  Future<void> _lookUpCost(
    OpenRouterClient client,
    String chatId,
    String messageId,
    String generationId,
    OrModelRow model,
  ) async {
    for (final wait in costLookupDelays) {
      await Future<void>.delayed(wait);
      if (_disposed) return;
      final GenerationInfo? info;
      try {
        info = await client.generation(generationId);
      } on Exception {
        continue;
      }
      final got = info;
      final cost = got?.totalCost;
      if (got == null || cost == null) continue;
      if (await db.message(messageId) == null) return; // deleted meanwhile
      await db.transaction(() async {
        await db.updateMessage(
          messageId,
          GeneralMessagesCompanion(
            tokensIn: Value(got.tokensPrompt),
            tokensOut: Value(got.tokensCompletion),
            tokensReasoning: Value(got.tokensReasoning),
            costUsd: Value(cost),
          ),
        );
        await _addToChat(
          chatId,
          got.tokensPrompt,
          got.tokensCompletion,
          cost,
          model,
        );
      });
      return;
    }
  }
}
