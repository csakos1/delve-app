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
        },
      },
    ),
    DeviceInfo.fromJson,
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
          body: {'action': action.name, if (force) 'force': true},
          receiveTimeout: const Duration(seconds: 60),
        ),
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
  });
  final String conversationId;
  final TokenTotals totals;
  final ContextFill context;
  final List<Run> runs;
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
