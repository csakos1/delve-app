import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'openrouter_errors.dart';
import 'sse.dart';

/// Every chat request carries this, whatever else changes (decision G-4 and
/// the privacy rules of the G plan): only zero-retention endpoints, no
/// provider that stores or trains on the data.
const Map<String, Object?> kPrivacyProvider = {
  'zdr': true,
  'data_collection': 'deny',
};

/// One turn of the history sent to the model.
class GeneralTurn {
  const GeneralTurn.user(this.text, {this.images = const []}) : role = 'user';
  const GeneralTurn.assistant(this.text)
    : role = 'assistant',
      images = const [];

  final String role;
  final String text;

  /// `(mime, bytes)`; sent only to models that read images.
  final List<(String, Uint8List)> images;
}

/// What a model says about thinking (`/models` → `reasoning`).
class ReasoningSpec {
  const ReasoningSpec({
    required this.supported,
    this.mandatory = false,
    this.efforts = const [],
    this.defaultEffort,
  });

  static const none = ReasoningSpec(supported: false);

  final bool supported;

  /// The endpoint refuses `enabled: false` / `effort: none` with a 400.
  final bool mandatory;
  final List<String> efforts;
  final String? defaultEffort;

  /// The `reasoning` request parameter for the pill state [on], or null
  /// (leave it out). A model that always thinks never gets an “off”; a model
  /// without thinking gets nothing.
  Map<String, Object?>? param({required bool on}) {
    if (!supported) return null;
    if (on || mandatory) return const {'enabled': true};
    if (efforts.contains('none')) return const {'effort': 'none'};
    return const {'enabled': false};
  }
}

/// The request body for `POST /chat/completions` (streamed). Pure, so the
/// privacy rules are tested on every branch: the [kPrivacyProvider] block is
/// always there, nothing identifies the app or the user, and no plugin, web
/// search or `:online` variant can be asked for (zero retention does not
/// cover those).
Map<String, Object?> buildChatBody({
  required String model,
  required List<GeneralTurn> turns,
  String? systemPrompt,
  Map<String, Object?>? reasoning,
  bool sendImages = true,
  int? maxTokens,
}) {
  checkModelId(model);
  final messages = <Map<String, Object?>>[
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
      {'role': 'system', 'content': systemPrompt},
    for (final t in turns)
      if (t.role == 'user' && sendImages && t.images.isNotEmpty)
        {
          'role': 'user',
          'content': [
            if (t.text.isNotEmpty) {'type': 'text', 'text': t.text},
            for (final (mime, bytes) in t.images)
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mime;base64,${base64Encode(bytes)}',
                },
              },
          ],
        }
      else
        {'role': t.role, 'content': t.text},
  ];
  return {
    'model': model,
    'stream': true,
    'messages': messages,
    'reasoning': ?reasoning,
    'max_tokens': ?maxTokens,
    'provider': kPrivacyProvider,
  };
}

/// Model ids the General chat refuses to send: aliases (`~…`), routers
/// (`openrouter/…`) and `:online` (web search, outside zero retention).
void checkModelId(String id) {
  if (id.isEmpty ||
      id.startsWith('~') ||
      id.startsWith('openrouter/') ||
      id.contains(':online')) {
    throw ArgumentError.value(id, 'model', 'not allowed in General');
  }
}

/// The user stopped the answer (the connection was closed on purpose).
class GeneralCancelled implements Exception {
  const GeneralCancelled();
}

/// What a streamed answer is made of, in order.
sealed class ChatEvent {
  const ChatEvent();
}

/// The response arrived; [generationId] is `x-generation-id`.
class ChatStarted extends ChatEvent {
  const ChatStarted(this.generationId);
  final String? generationId;
}

/// The provider OpenRouter routed to, and the model that answers.
class ChatRoute extends ChatEvent {
  const ChatRoute({required this.provider, required this.model});
  final String? provider;
  final String? model;
}

class ChatDelta extends ChatEvent {
  const ChatDelta({this.content = '', this.reasoning = ''});
  final String content;
  final String reasoning;
}

class ChatFinish extends ChatEvent {
  const ChatFinish(this.reason);
  final String reason;
}

/// `usage` of the last chunk (it carries the cost, G0).
class ChatUsage extends ChatEvent {
  const ChatUsage({
    this.promptTokens,
    this.completionTokens,
    this.reasoningTokens,
    this.cost,
  });

  factory ChatUsage.fromJson(Map<String, Object?> u) {
    final details = u['completion_tokens_details'];
    return ChatUsage(
      promptTokens: _int(u['prompt_tokens']),
      completionTokens: _int(u['completion_tokens']),
      reasoningTokens: details is Map<String, Object?>
          ? _int(details['reasoning_tokens'])
          : null,
      cost: _double(u['cost']),
    );
  }

  final int? promptTokens;
  final int? completionTokens;
  final int? reasoningTokens;
  final double? cost;
}

/// `GET /key`.
class KeyInfo {
  const KeyInfo({
    this.label,
    this.limit,
    this.limitRemaining,
    this.limitReset,
    this.usage,
    this.usageMonthly,
    this.resetsAt,
  });

  factory KeyInfo.fromJson(Map<String, Object?> j) {
    final d = j['data'] is Map<String, Object?>
        ? j['data']! as Map<String, Object?>
        : j;
    final budget = d['effective_budget'];
    final resets = budget is Map<String, Object?> ? budget['resets_at'] : null;
    return KeyInfo(
      label: d['label'] is String ? d['label']! as String : null,
      limit: _double(d['limit']),
      limitRemaining: _double(d['limit_remaining']),
      limitReset: d['limit_reset'] is String
          ? d['limit_reset']! as String
          : null,
      usage: _double(d['usage']),
      usageMonthly: _double(d['usage_monthly']),
      resetsAt: resets is String ? DateTime.tryParse(resets) : null,
    );
  }

  /// OpenRouter's masked form (`sk-or-v1-abc...123`).
  final String? label;
  final double? limit;
  final double? limitRemaining;

  /// `daily`, `weekly`, `monthly` or null (the limit never resets).
  final String? limitReset;
  final double? usage;
  final double? usageMonthly;
  final DateTime? resetsAt;
}

/// `GET /generation?id=` – how a (stopped) answer was billed.
class GenerationInfo {
  const GenerationInfo({
    this.totalCost,
    this.tokensPrompt,
    this.tokensCompletion,
    this.tokensReasoning,
    this.cancelled = false,
    this.provider,
  });

  factory GenerationInfo.fromJson(Map<String, Object?> j) {
    final d = j['data'] is Map<String, Object?>
        ? j['data']! as Map<String, Object?>
        : j;
    return GenerationInfo(
      totalCost: _double(d['total_cost']),
      tokensPrompt: _int(d['native_tokens_prompt'] ?? d['tokens_prompt']),
      tokensCompletion: _int(
        d['native_tokens_completion'] ?? d['tokens_completion'],
      ),
      tokensReasoning: _int(d['native_tokens_reasoning']),
      cancelled: d['cancelled'] == true,
      provider: d['provider_name'] is String
          ? d['provider_name']! as String
          : null,
    );
  }

  final double? totalCost;
  final int? tokensPrompt;
  final int? tokensCompletion;
  final int? tokensReasoning;
  final bool cancelled;
  final String? provider;
}

int? _int(Object? v) => v is num ? v.toInt() : null;
double? _double(Object? v) => switch (v) {
  num() => v.toDouble(),
  String() => double.tryParse(v),
  _ => null,
};

/// The phone's own OpenRouter client (G1: no desktop in between). The only
/// header besides the content type is the key; no `HTTP-Referer`, no
/// `X-Title`, no user id.
class OpenRouterClient {
  OpenRouterClient({
    required String key,
    HttpClientAdapter? adapter,
    Uri? base,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
    this.streamIdleTimeout = const Duration(seconds: 150),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: (base ?? defaultBase).toString(),
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           sendTimeout: const Duration(seconds: 60),
           headers: {'Authorization': 'Bearer $key'},
           validateStatus: (_) => true,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  static final Uri defaultBase = Uri.parse('https://openrouter.ai/api/v1/');

  /// Longest wait between two pieces of a streamed answer (OpenRouter sends
  /// keep-alive comments while a model thinks).
  final Duration streamIdleTimeout;
  final Dio _dio;

  void close() => _dio.close(force: true);

  Future<Map<String, Object?>> _get(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final Response<Object?> res;
    try {
      res = await _dio.get<Object?>(path, queryParameters: query);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
    final status = res.statusCode ?? 0;
    final data = _jsonOf(res.data);
    if (status < 200 || status >= 300) {
      throw GeneralFailure.fromStatus(
        status,
        data,
        retryAfter: res.headers.value('retry-after'),
      );
    }
    if (data is Map<String, Object?>) return data;
    throw const GeneralUpstream('expected a JSON object');
  }

  static Object? _jsonOf(Object? data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return null;
      }
    }
    if (data is Map<Object?, Object?>) return Map<String, Object?>.from(data);
    return data;
  }

  static List<Map<String, Object?>> _list(Map<String, Object?> j) => [
    for (final e in (j['data'] as List<Object?>?) ?? const <Object?>[])
      if (e is Map<String, Object?>) e,
  ];

  /// `GET /models` (only what this account may use; G0b).
  Future<List<Map<String, Object?>>> models() async =>
      _list(await _get('models'));

  /// `GET /endpoints/zdr`.
  Future<List<Map<String, Object?>>> zdrEndpoints() async =>
      _list(await _get('endpoints/zdr'));

  Future<KeyInfo> keyInfo() async => KeyInfo.fromJson(await _get('key'));

  /// Null while OpenRouter has no stats yet (404).
  Future<GenerationInfo?> generation(String id) async {
    try {
      return GenerationInfo.fromJson(
        await _get('generation', query: {'id': id}),
      );
    } on GeneralNoProvider {
      return null;
    }
  }

  /// Streams one answer. Throws a [GeneralFailure], or [GeneralCancelled]
  /// after [cancel].
  Stream<ChatEvent> chat(
    Map<String, Object?> body, {
    CancelToken? cancel,
  }) async* {
    final Response<ResponseBody> res;
    try {
      res = await _dio.post<ResponseBody>(
        'chat/completions',
        data: body,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: streamIdleTimeout,
          contentType: Headers.jsonContentType,
        ),
      );
    } on DioException catch (e) {
      throw _fromDio(e);
    }
    final status = res.statusCode ?? 0;
    final stream = res.data!.stream;
    if (status < 200 || status >= 300) {
      final bytes = await _drain(stream);
      throw GeneralFailure.fromStatus(
        status,
        _jsonOf(utf8.decode(bytes, allowMalformed: true)),
        retryAfter: res.headers.value('retry-after'),
      );
    }
    yield ChatStarted(res.headers.value('x-generation-id'));
    var routed = false;
    var finished = false;
    try {
      await for (final data in sseData(stream)) {
        if (data == '[DONE]') break;
        final Object? chunk;
        try {
          chunk = jsonDecode(data);
        } on FormatException {
          continue;
        }
        if (chunk is! Map<String, Object?>) continue;
        if (chunk['error'] != null) {
          throw GeneralUpstream(
            GeneralFailure.errorMessage(chunk) ?? 'error in the stream',
          );
        }
        if (!routed && (chunk['provider'] != null || chunk['model'] != null)) {
          routed = true;
          yield ChatRoute(
            provider: chunk['provider'] is String
                ? chunk['provider']! as String
                : null,
            model: chunk['model'] is String ? chunk['model']! as String : null,
          );
        }
        final choices = chunk['choices'];
        if (choices is List<Object?> && choices.isNotEmpty) {
          final c = choices.first;
          if (c is Map<String, Object?>) {
            final delta = c['delta'];
            if (delta is Map<String, Object?>) {
              final content = delta['content'];
              final reasoning = delta['reasoning'];
              final text = content is String ? content : '';
              final thought = reasoning is String ? reasoning : '';
              if (text.isNotEmpty || thought.isNotEmpty) {
                yield ChatDelta(content: text, reasoning: thought);
              }
            }
            final reason = c['finish_reason'];
            if (reason is String && !finished) {
              finished = true;
              yield ChatFinish(reason);
            }
          }
        }
        final usage = chunk['usage'];
        if (usage is Map<String, Object?>) yield ChatUsage.fromJson(usage);
      }
    } on DioException catch (e) {
      throw _fromDio(e);
    } on GeneralFailure {
      rethrow;
    } on Exception catch (e) {
      if (cancel?.isCancelled ?? false) throw const GeneralCancelled();
      throw GeneralFailure.network(e);
    }
    if (cancel?.isCancelled ?? false) throw const GeneralCancelled();
  }

  static Future<Uint8List> _drain(Stream<Uint8List> s) async {
    final b = BytesBuilder(copy: false);
    try {
      await for (final part in s) {
        b.add(part);
      }
    } on DioException catch (e) {
      throw _fromDio(e);
    }
    return b.takeBytes();
  }

  static Exception _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return const GeneralCancelled();
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const GeneralNetwork('timeout');
      case DioExceptionType.badCertificate:
        return const GeneralNetwork('the certificate was rejected');
      case DioExceptionType.badResponse:
        final res = e.response;
        return GeneralFailure.fromStatus(
          res?.statusCode ?? 0,
          _jsonOf(res?.data),
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        final err = e.error;
        if (err is SocketException ||
            err is HandshakeException ||
            err is HttpException) {
          return GeneralFailure.network(err!);
        }
        if (err is GeneralFailure) return err;
        return GeneralNetwork(
          err?.toString() ?? e.message ?? 'connection error',
        );
    }
  }
}
