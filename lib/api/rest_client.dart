import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_error.dart';
import 'models/models.dart';
import 'protocol.dart';

/// REST client for one server. Every failure is an [ApiError]; a 401 on an
/// authenticated call also triggers [onUnauthorized] (the session drops the
/// token and goes back to pairing).
class DelveApi {
  DelveApi({
    required this.server,
    this.token,
    this.onUnauthorized,
    HttpClientAdapter? adapter,
    Duration connectTimeout = const Duration(seconds: 8),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: server.toString(),
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           sendTimeout: receiveTimeout,
           responseType: ResponseType.json,
           headers: {if (token != null) 'Authorization': 'Bearer $token'},
           validateStatus: (s) => s != null && s >= 200 && s < 300,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  /// Server origin, e.g. `https://archlinux.example.ts.net`.
  final Uri server;
  final String? token;
  final void Function()? onUnauthorized;
  final Dio _dio;

  void close() => _dio.close(force: true);

  Future<Map<String, Object?>> _json(
    (String, String) route, {
    Map<String, String> params = const {},
    Map<String, Object?> query = const {},
    Object? body,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? contentType,
  }) async {
    try {
      final res = await _dio.request<Object?>(
        ApiRoutes.path(route.$2, params),
        data: body,
        queryParameters: {
          for (final e in query.entries)
            if (e.value != null) e.key: e.value.toString(),
        },
        options: Options(
          method: route.$1,
          receiveTimeout: receiveTimeout,
          sendTimeout: sendTimeout,
          contentType: contentType,
        ),
      );
      final data = res.data;
      if (res.statusCode == 204 || data == null || data == '') {
        return const <String, Object?>{};
      }
      if (data is Map<String, Object?>) return data;
      if (data is Map<Object?, Object?>) {
        return Map<String, Object?>.from(data);
      }
      throw const ApiBadResponse('expected a JSON object');
    } on DioException catch (e) {
      final err = ApiError.fromDio(e);
      if (err is ApiUnauthorized && token != null) {
        onUnauthorized?.call();
      }
      throw err;
    }
  }

  T _parse<T>(Map<String, Object?> json, T Function(Map<String, Object?>) f) {
    try {
      return f(json);
    } on Object catch (e) {
      throw ApiBadResponse('unexpected response: ${e.runtimeType}');
    }
  }

  /// No auth: version and contract revision. Also the reachability probe.
  Future<ServerMeta> meta() async =>
      _parse(await _json(ApiRoutes.meta), ServerMeta.fromJson);

  /// No auth: trades a one-time code for a device token.
  Future<RegisteredDevice> register(
    String code, {
    String? name,
    String? appVersion,
  }) async => _parse(
    await _json(
      ApiRoutes.register,
      body: {'code': code, 'name': ?name, 'app_version': ?appVersion},
    ),
    RegisteredDevice.fromJson,
  );

  Future<ServerStatus> status() async =>
      _parse(await _json(ApiRoutes.status), ServerStatus.fromJson);

  Future<DeviceInfo> deviceMe() async =>
      _parse(await _json(ApiRoutes.deviceMe), DeviceInfo.fromJson);

  /// This device's notification settings; only the given keys change.
  Future<DeviceInfo> patchDevice({
    bool? approvals,
    bool? runDone,
    bool? water,
    bool? brief,
    bool? watches,
    bool? system,
    bool? news,
  }) async => _parse(
    await _json(
      ApiRoutes.patchDevice,
      body: {
        'notify': {
          'approvals': ?approvals,
          'run_done': ?runDone,
          'water': ?water,
          'brief': ?brief,
          'watches': ?watches,
          'system': ?system,
          'news': ?news,
        },
      },
    ),
    DeviceInfo.fromJson,
  );

  /// Whether the desktop agent is there for mirrored notifications.
  Future<MirrorStatus> mirror() async =>
      _parse(await _json(ApiRoutes.mirror), MirrorStatus.fromJson);

  // --- the personal profile (P1) -------------------------------------------

  /// What the agent knows about its user, as it is on the desktop now.
  Future<Persona> persona() async =>
      _parse(await _json(ApiRoutes.persona), Persona.fromJson);

  /// Replaces the core with [sections], in this order (a section without a
  /// text is dropped). 503 `persona_no_store` / `persona_not_writable`.
  Future<Persona> putPersonaProfile(List<PersonaSection> sections) async =>
      _parse(
        await _json(
          ApiRoutes.putPersonaProfile,
          body: {
            'sections': [for (final s in sections) s.toJson()],
          },
        ),
        Persona.fromJson,
      );

  /// Creates or replaces the topic file [topic] (by its name). 409
  /// `too_many_topics`, 422 for a name the server does not take.
  Future<Persona> putPersonaTopic(PersonaTopic topic) async => _parse(
    await _json(
      ApiRoutes.putPersonaTopic,
      params: {'name': topic.name},
      body: {
        'title': topic.title,
        'summary': topic.summary,
        'text': topic.text,
        'general': topic.general,
      },
    ),
    Persona.fromJson,
  );

  /// Removes a topic file; 404 `topic_not_found`.
  Future<Persona> deletePersonaTopic(String name) async => _parse(
    await _json(ApiRoutes.deletePersonaTopic, params: {'name': name}),
    Persona.fromJson,
  );

  /// Stores this phone's FCM token on the server (`null` clears it).
  Future<void> putFcmToken(String? fcmToken) async {
    await _json(ApiRoutes.deviceFcm, body: {'token': fcmToken});
  }

  /// Revokes this device's token on the server.
  Future<void> unpair() async {
    await _json(ApiRoutes.unpair);
  }

  // --- conversations, runs, approvals (A3) ---------------------------------

  /// One page of the conversation list, newest first.
  Future<ConversationPage> conversations({
    int limit = 50,
    String? cursor,
    bool archived = false,
  }) async {
    final json = await _json(
      ApiRoutes.conversations,
      query: {'limit': limit, 'cursor': cursor, 'archived': archived},
    );
    return _parse(
      json,
      (j) => ConversationPage([
        for (final c in _list(j, 'data')) Conversation.fromJson(c),
      ], j['next_cursor'] as String?),
    );
  }

  Future<Conversation> conversation(String id) async => _parse(
    await _json(ApiRoutes.conversation, params: {'conversation_id': id}),
    Conversation.fromJson,
  );

  /// The newest [limit] messages before message id [before], oldest first;
  /// assistant messages carry their tool steps.
  Future<MessagePage> messages(
    String conversationId, {
    int? before,
    int limit = 100,
  }) async {
    final json = await _json(
      ApiRoutes.messages,
      params: {'conversation_id': conversationId},
      query: {'before': before, 'limit': limit},
    );
    return _parse(
      json,
      (j) => MessagePage([
        for (final m in _list(j, 'data')) HistoryMessage.fromJson(m),
      ], hasMore: j['has_more']! as bool),
    );
  }

  /// Totals, context fill and the newest [limit] runs (oldest first).
  Future<ConversationUsage> usage(
    String conversationId, {
    int limit = 50,
  }) async {
    final json = await _json(
      ApiRoutes.usage,
      params: {'conversation_id': conversationId},
      query: {'limit': limit},
    );
    return _parse(
      json,
      (j) => ConversationUsage(
        conversationId: j['conversation_id']! as String,
        totals: TokenTotals.fromJson(j['totals']! as Map<String, Object?>),
        context: ContextFill.fromJson(j['context']! as Map<String, Object?>),
        runs: [for (final r in _list(j, 'runs')) Run.fromJson(r)],
        lastModel: j['last_model'] as String?,
      ),
    );
  }

  Future<Conversation> patchConversation(
    String id, {
    bool? thinking,
    bool? archived,
  }) async => _parse(
    await _json(
      ApiRoutes.patchConversation,
      params: {'conversation_id': id},
      body: {'thinking': ?thinking, 'archived': ?archived},
    ),
    Conversation.fromJson,
  );

  /// The global queue: the active run first, then queued runs.
  Future<List<OpenRun>> openRuns() async {
    final json = await _json(ApiRoutes.openRuns);
    return _parse(
      json,
      (j) => [for (final r in _list(j, 'data')) OpenRun.fromJson(r)],
    );
  }

  /// Approvals with one of [statuses], newest first.
  Future<List<Approval>> approvals({
    Iterable<String> statuses = answerableApprovalStatuses,
    int limit = 100,
  }) async {
    final json = await _json(
      ApiRoutes.approvals,
      query: {'status': statuses.join(','), 'limit': limit},
    );
    return _parse(
      json,
      (j) => [for (final a in _list(j, 'data')) Approval.fromJson(a)],
    );
  }

  /// Answers an approval (also a late one); the answer is never queued.
  Future<Approval> answerApproval(
    String requestId,
    ApprovalChoice choice,
  ) async => _parse(
    await _json(
      ApiRoutes.answerApproval,
      params: {'request_id': requestId},
      body: {'choice': choice.wire},
    ),
    Approval.fromJson,
  );

  /// Dashboard cards newest first, optionally of one [type] and from [since].
  Future<List<AgentCard>> cards({
    String? type,
    DateTime? since,
    int limit = 100,
  }) async {
    final json = await _json(
      ApiRoutes.cards,
      query: {
        'type': type,
        'since': since?.toUtc().toIso8601String(),
        'limit': limit,
      },
    );
    return _parse(
      json,
      (j) => [for (final c in _list(j, 'data')) AgentCard.fromJson(c)],
    );
  }

  /// The system view: Hermes, llama-server, the queue, the GPUs (B3).
  Future<SystemInfo> system() async =>
      _parse(await _json(ApiRoutes.system), SystemInfo.fromJson);

  /// Starts or stops llama-server; answers with the new system view. A stop
  /// while a run is active needs [force] (else 409 `run_active`). The server
  /// waits for systemctl, so this may take longer than other calls.
  Future<SystemInfo> llama(LlamaAction action, {bool force = false}) async =>
      _parse(
        await _json(
          ApiRoutes.llama,
          body: {
            'action': action == LlamaAction.stop ? 'stop' : 'start',
            if (force) 'force': true,
          },
          receiveTimeout: const Duration(seconds: 60),
        ),
        SystemInfo.fromJson,
      );

  /// Loads the model preset [name] (M); answers with the new system view.
  /// While llama-server runs this starts the switch (the view says
  /// `switching`); while it is stopped only the selection changes. 409:
  /// `run_active` (needs [force]), `already_active`, `model_not_usable`,
  /// `switch_in_progress`; 404 `unknown_model`.
  Future<SystemInfo> switchModel(String name, {bool force = false}) async =>
      _parse(
        await _json(
          ApiRoutes.llama,
          body: {'action': 'switch', 'model': name, if (force) 'force': true},
          receiveTimeout: const Duration(seconds: 60),
        ),
        SystemInfo.fromJson,
      );

  /// Forgets a failed switch (the previous model is back).
  Future<SystemInfo> dismissSwitch() async => _parse(
    await _json(ApiRoutes.llama, body: {'action': 'dismiss'}),
    SystemInfo.fromJson,
  );

  /// The Observability view for [range] (`24h`, `7d`, `30d`; B5).
  Future<Stats> stats(String range) async => _parse(
    await _json(ApiRoutes.stats, query: {'range': range}),
    Stats.fromJson,
  );

  /// Every schedule, the morning brief first (B4).
  Future<List<Schedule>> schedules() async {
    final json = await _json(ApiRoutes.schedules);
    return _parse(
      json,
      (j) => [for (final s in _list(j, 'data')) Schedule.fromJson(s)],
    );
  }

  /// A new prompt schedule; 422 with a code (`invalid_cron`, `too_frequent`,
  /// `conversation_not_found`, …) when the server does not take it.
  Future<Schedule> createSchedule(ScheduleDraft draft) async => _parse(
    await _json(ApiRoutes.createSchedule, body: draft.toJson()),
    Schedule.fromJson,
  );

  /// Changes the given [fields] (`name`, `cron`, `prompt`,
  /// `conversation_mode`, `conversation_id`, `thinking`, `enabled`); the
  /// brief takes only `cron` and `enabled`.
  Future<Schedule> patchSchedule(
    String id,
    Map<String, Object?> fields,
  ) async => _parse(
    await _json(
      ApiRoutes.patchSchedule,
      params: {'schedule_id': id},
      body: fields,
    ),
    Schedule.fromJson,
  );

  Future<void> deleteSchedule(String id) async {
    await _json(ApiRoutes.deleteSchedule, params: {'schedule_id': id});
  }

  /// Fires a schedule once now; the brief may take a while (the server asks
  /// the desktop for its incidents).
  Future<ScheduleRun> runSchedule(String id) async => _parse(
    await _json(
      ApiRoutes.runSchedule,
      params: {'schedule_id': id},
      receiveTimeout: const Duration(seconds: 60),
    ),
    ScheduleRun.fromJson,
  );

  // --- watches (W2) --------------------------------------------------------

  /// The watches (deleted ones left out), by name.
  Future<List<Watch>> watches() async {
    final json = await _json(ApiRoutes.watches);
    return _parse(
      json,
      (j) => [for (final w in _list(j, 'data')) Watch.fromJson(w)],
    );
  }

  /// One watch; 404 `watch_not_found`.
  Future<Watch> watch(String slug) async => _parse(
    await _json(ApiRoutes.watch, params: {'slug': slug}),
    Watch.fromJson,
  );

  /// A watch's items newest first: [verdicts] (`hits` = match + mechanical,
  /// or `reject`, `error`, …), older than [before] (an item id).
  Future<WatchItemPage> watchItems(
    String slug, {
    List<String> verdicts = const ['hits'],
    int? before,
    int limit = 30,
  }) async {
    final json = await _json(
      ApiRoutes.watchItems,
      params: {'slug': slug},
      query: {'verdict': verdicts.join(','), 'before': before, 'limit': limit},
    );
    return _parse(
      json,
      (j) => WatchItemPage([
        for (final i in _list(j, 'data')) WatchItem.fromJson(i),
      ], j['next_before'] as int?),
    );
  }

  /// Pause, resume or run a watch now (the desktop's cron, through the
  /// helper); 409 `watch_job_missing`, 503 `helper_unavailable`.
  Future<Watch> watchAction(String slug, WatchAction action) async => _parse(
    await _json(
      ApiRoutes.watchAction,
      params: {'slug': slug, 'verb': action.name},
      receiveTimeout: const Duration(seconds: 60),
    ),
    Watch.fromJson,
  );

  /// A schedule's runs, newest first (API 22); [before] the `queued_at` the
  /// page ends at (a page's `nextBefore`). 404 `schedule_not_found`.
  Future<ScheduleRunPage> scheduleRuns(
    String id, {
    DateTime? before,
    int limit = 20,
  }) async {
    final json = await _json(
      ApiRoutes.scheduleRuns,
      params: {'schedule_id': id},
      query: {'before': before?.toUtc().toIso8601String(), 'limit': limit},
    );
    return _parse(
      json,
      (j) => ScheduleRunPage([
        for (final r in _list(j, 'data')) ScheduleRunEntry.fromJson(r),
      ], DateTime.tryParse(j['next_before'] as String? ?? '')),
    );
  }

  // --- news (N2) -----------------------------------------------------------

  /// The Dashboard block.
  Future<NewsDigest> newsDigest() async =>
      _parse(await _json(ApiRoutes.news), NewsDigest.fromJson);

  /// The News page's All view: each topic that is on, in its order.
  Future<List<NewsSection>> newsSections() async {
    final json = await _json(ApiRoutes.newsSections);
    return _parse(
      json,
      (j) => [for (final s in _list(j, 'data')) NewsSection.fromJson(s)],
    );
  }

  /// Stories newest first: of one [topic], or the [saved] ones, or the
  /// [weekly] list (one page, best first); [minScore] leaves out the lower
  /// and the unscored ones; [before] continues from an item id.
  Future<NewsItemPage> newsItems({
    String? topic,
    bool saved = false,
    bool weekly = false,
    int? minScore,
    int? before,
    int limit = 20,
  }) async {
    final json = await _json(
      ApiRoutes.newsItems,
      query: {
        'topic': topic,
        'saved': saved ? 'true' : null,
        'weekly': weekly ? 'true' : null,
        'min_score': minScore,
        'before': before,
        'limit': limit,
      },
    );
    return _parse(
      json,
      (j) => NewsItemPage([
        for (final i in _list(j, 'data')) NewsItem.fromJson(i),
      ], j['next_before'] as int?),
    );
  }

  /// One story with its other sources and its text; 404
  /// `news_item_not_found`. A merged item's id opens its story.
  Future<NewsStory> newsStory(int id) async => _parse(
    await _json(ApiRoutes.newsItem, params: {'item_id': '$id'}),
    NewsStory.fromJson,
  );

  /// Read / saved / feedback (`more` | `less`; [clearFeedback] sends null).
  Future<NewsStory> markNews(
    int id, {
    bool? read,
    bool? saved,
    String? feedback,
    bool clearFeedback = false,
  }) async => _parse(
    await _json(
      ApiRoutes.markNewsItem,
      params: {'item_id': '$id'},
      body: {
        'read': ?read,
        'saved': ?saved,
        if (feedback != null || clearFeedback) 'feedback': feedback,
      },
    ),
    NewsStory.fromJson,
  );

  /// "Fetch text": the collector's next hourly round fetches the article
  /// (a failed one is tried again); 409 `news_no_text` for releases.
  Future<NewsStory> fetchNewsText(int id) async => _parse(
    await _json(ApiRoutes.fetchNewsText, params: {'item_id': '$id'}),
    NewsStory.fromJson,
  );

  /// A feed on or off ("Hide this source" = off).
  Future<NewsSource> setNewsSource(String id, {required bool enabled}) async =>
      _parse(
        await _json(
          ApiRoutes.patchNewsSource,
          params: {'source_id': id},
          body: {'enabled': enabled},
        ),
        NewsSource.fromJson,
      );

  /// The topics in their order, with their feeds and stories of the day.
  Future<List<NewsTopic>> newsTopics() async {
    final json = await _json(ApiRoutes.newsTopics);
    return _parse(
      json,
      (j) => [for (final t in _list(j, 'data')) NewsTopic.fromJson(t)],
    );
  }

  /// A topic's [description], place ([position]) or switch ([enabled]); 404
  /// `news_topic_not_found`.
  Future<NewsTopic> patchNewsTopic(
    String id, {
    String? description,
    int? position,
    bool? enabled,
  }) async => _parse(
    await _json(
      ApiRoutes.patchNewsTopic,
      params: {'topic_id': id},
      body: {
        'description': ?description,
        'position': ?position,
        'enabled': ?enabled,
      },
    ),
    NewsTopic.fromJson,
  );

  /// The feeds and what each answered last.
  Future<List<NewsSource>> newsSources() async {
    final json = await _json(ApiRoutes.newsSources);
    return _parse(
      json,
      (j) => [for (final s in _list(j, 'data')) NewsSource.fromJson(s)],
    );
  }

  /// Removes a feed from the desktop (its stories stay until they age out).
  Future<void> deleteNewsSource(String id) async {
    await _json(ApiRoutes.deleteNewsSource, params: {'source_id': id});
  }

  Future<NewsSettings> newsSettings() async =>
      _parse(await _json(ApiRoutes.newsSettings), NewsSettings.fromJson);

  /// The digest time (`HH:MM`), the must-read push and its daily limit (0-5).
  Future<NewsSettings> patchNewsSettings({
    String? digestAt,
    bool? push,
    int? pushMax,
  }) async => _parse(
    await _json(
      ApiRoutes.patchNewsSettings,
      body: {'digest_at': ?digestAt, 'push': ?push, 'push_max': ?pushMax},
    ),
    NewsSettings.fromJson,
  );

  // --- inbox (I0, API 23) -------------------------------------------------

  /// The Inbox: what needs the reader, newest first, and what was cleared
  /// today.
  Future<Inbox> inbox() async =>
      _parse(await _json(ApiRoutes.inbox), Inbox.fromJson);

  /// Clears the open item [id] (`<kind>:<ref>`); answers with the view after
  /// it. 404 `inbox_item_not_found` (it left by itself), 409 `not_doneable`
  /// (an approval is answered, not cleared).
  Future<Inbox> inboxDone(String id) async => _parse(
    await _json(ApiRoutes.inboxDone, body: {'id': id}),
    Inbox.fromJson,
  );

  /// Takes a clearing back: the item shows again if it is still the case.
  /// 404 `inbox_item_not_found` (it was not cleared).
  Future<Inbox> inboxUndo(String id) async => _parse(
    await _json(ApiRoutes.inboxUndo, body: {'id': id}),
    Inbox.fromJson,
  );

  // --- attachments (B6) ---------------------------------------------------

  /// Uploads one photo or file (the raw bytes, the type in `Content-Type`);
  /// unbound until `chat.send` lists its id. 413 `too_large`, 415
  /// `unsupported_image`.
  Future<Attachment> uploadAttachment({
    required String kind,
    required String filename,
    required String mime,
    required Uint8List bytes,
  }) async => _parse(
    await _json(
      ApiRoutes.uploadAttachment,
      query: {'kind': kind, 'filename': filename},
      body: bytes,
      contentType: mime,
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 60),
    ),
    Attachment.fromJson,
  );

  /// The bytes of an attachment; 410 `attachment_gone` once deleted.
  Future<Uint8List> attachmentBytes(String id) async {
    try {
      final res = await _dio.request<List<int>>(
        ApiRoutes.path(ApiRoutes.attachment.$2, {'attachment_id': id}),
        options: Options(
          method: ApiRoutes.attachment.$1,
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = res.data ?? const <int>[];
      return data is Uint8List ? data : Uint8List.fromList(data);
    } on DioException catch (e) {
      final err = ApiError.fromDio(e);
      if (err is ApiUnauthorized && token != null) onUnauthorized?.call();
      throw err;
    }
  }

  /// A new, unsent upload with the same content ("Send again").
  Future<Attachment> copyAttachment(String id) async => _parse(
    await _json(ApiRoutes.copyAttachment, params: {'attachment_id': id}),
    Attachment.fromJson,
  );

  static List<Map<String, Object?>> _list(
    Map<String, Object?> json,
    String key,
  ) => [
    for (final item in json[key]! as List<Object?>)
      item! as Map<String, Object?>,
  ];
}

/// `GET /conversations`: one page and the cursor of the next (null = last).
class ConversationPage {
  const ConversationPage(this.conversations, this.nextCursor);
  final List<Conversation> conversations;
  final String? nextCursor;
}

/// `GET /watches/{slug}/items`: one page and the id to continue from (null =
/// last page).
class WatchItemPage {
  const WatchItemPage(this.items, this.nextBefore);
  final List<WatchItem> items;
  final int? nextBefore;
}

/// `GET /schedules/{id}/runs`: one page and where the next ends (null = last).
class ScheduleRunPage {
  const ScheduleRunPage(this.items, this.nextBefore);
  final List<ScheduleRunEntry> items;
  final DateTime? nextBefore;
}

/// `GET /news/items`: one page and the id to continue from (null = last).
class NewsItemPage {
  const NewsItemPage(this.items, this.nextBefore);
  final List<NewsItem> items;
  final int? nextBefore;
}

/// `GET /conversations/{id}/messages`.
class MessagePage {
  const MessagePage(this.messages, {required this.hasMore});
  final List<HistoryMessage> messages;
  final bool hasMore;
}

/// `GET /conversations/{id}/usage`.
class ConversationUsage {
  const ConversationUsage({
    required this.conversationId,
    required this.totals,
    required this.context,
    required this.runs,
    this.lastModel,
  });
  final String conversationId;
  final TokenTotals totals;
  final ContextFill context;
  final List<Run> runs;

  /// The model that wrote the newest answer (null before the first one).
  final String? lastModel;
}

/// What `POST /schedules` takes.
class ScheduleDraft {
  const ScheduleDraft({
    required this.name,
    required this.cron,
    required this.prompt,
    this.conversationId,
    this.thinking = false,
    this.enabled = true,
  });

  final String name;
  final String cron;
  final String prompt;

  /// null: a new chat for each run (`conversation_mode: new`).
  final String? conversationId;
  final bool thinking;
  final bool enabled;

  Map<String, Object?> toJson() => {
    'name': name,
    'cron': cron,
    'prompt': prompt,
    'conversation_mode': conversationId == null ? 'new' : 'fixed',
    'conversation_id': ?conversationId,
    'thinking': thinking,
    'enabled': enabled,
  };
}

/// `POST /schedules/{id}/run`: the schedule after firing, and what it made
/// (a run for a prompt, a card for the brief).
class ScheduleRun {
  const ScheduleRun({required this.schedule, this.runId, this.cardId});

  factory ScheduleRun.fromJson(Map<String, Object?> json) => ScheduleRun(
    schedule: Schedule.fromJson(json['schedule']! as Map<String, Object?>),
    runId: json['run_id'] as String?,
    cardId: json['card_id'] as String?,
  );

  final Schedule schedule;
  final String? runId;
  final String? cardId;
}
