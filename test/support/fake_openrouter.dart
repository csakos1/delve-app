import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:delve/general/general_database.dart';
import 'package:delve/general/general_key_store.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';

/// The General database in memory.
GeneralDatabase memoryGeneralDb() => GeneralDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// The phone's OpenRouter key in memory (no secure storage in tests).
class MemoryGeneralKeyStore implements GeneralKeyStore {
  MemoryGeneralKeyStore([this.key]);
  String? key;

  @override
  Future<String?> read() async => key;

  @override
  Future<void> write(String key) async => this.key = key;

  @override
  Future<void> clear() async => key = null;
}

/// A key that passes [looksLikeOpenRouterKey]. Built at run time from
/// zeros: a random-looking literal is a secret to gitleaks.
final testOpenRouterKey = 'sk-or-v1-${'0' * 40}4f2a';

/// A recorded OpenRouter answer (`test/fixtures/openrouter/`, from G0).
String openRouterFixture(String name) =>
    File('test/fixtures/openrouter/$name').readAsStringSync();

Map<String, Object?> openRouterJson(String name) =>
    jsonDecode(openRouterFixture(name)) as Map<String, Object?>;

/// One answer to `POST /chat/completions`.
class FakeChatReply {
  /// A stream body, sent in [chunkSize]-byte pieces (they split lines and
  /// characters on purpose). [holdOpen]: the stream stays open after the
  /// body until the request is cancelled.
  FakeChatReply.sse(
    this.body, {
    this.headers = const {'x-generation-id': 'gen-test-1'},
    this.chunkSize = 37,
    this.holdOpen = false,
  }) : status = 200;

  FakeChatReply.error(this.status, Object json, {this.headers = const {}})
    : body = jsonEncode(json),
      chunkSize = 1 << 20,
      holdOpen = false;

  final int status;
  final String body;
  final Map<String, String> headers;
  final int chunkSize;
  final bool holdOpen;
}

/// In-process OpenRouter: answers `/models`, `/endpoints/zdr`, `/key`,
/// `/generation` from the G0 fixtures and `/chat/completions` from
/// [chatReplies], and records every request.
class FakeOpenRouter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<FakeChatReply> chatReplies = [];
  Map<String, Object?> models = openRouterJson('models.json');
  Map<String, Object?> zdr = openRouterJson('zdr.json');
  Map<String, Object?> key = openRouterJson('key.json');
  final Map<String, Map<String, Object?>> generations = {};
  int keyStatus = 200;
  bool unreachable = false;

  /// Streams that are still open (hold-open replies).
  final List<StreamController<Uint8List>> open = [];

  List<String> get calls => [
    for (final r in requests) '${r.method} ${r.uri.path}',
  ];

  /// The bodies of the chat requests, in order.
  List<Map<String, Object?>> get chatBodies => [
    for (final r in requests)
      if (r.uri.path.endsWith('/chat/completions'))
        r.data! as Map<String, Object?>,
  ];

  List<RequestOptions> get chatRequests => [
    for (final r in requests)
      if (r.uri.path.endsWith('/chat/completions')) r,
  ];

  static ResponseBody _json(int status, Object? body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (unreachable) {
      throw const SocketException(
        'Failed host lookup',
        osError: OSError('No address associated with hostname', 7),
      );
    }
    final path = options.uri.path;
    if (options.method == 'GET') {
      if (path.endsWith('/models')) return _json(200, models);
      if (path.endsWith('/endpoints/zdr')) return _json(200, zdr);
      if (path.endsWith('/key')) {
        return keyStatus == 200
            ? _json(200, key)
            : _json(keyStatus, openRouterJson('err-401.json'));
      }
      if (path.endsWith('/generation')) {
        final g = generations[options.uri.queryParameters['id']];
        return g == null
            ? _json(404, {
                'error': {'message': 'Generation not found', 'code': 404},
              })
            : _json(200, g);
      }
    }
    if (options.method == 'POST' && path.endsWith('/chat/completions')) {
      if (chatReplies.isEmpty) {
        return _json(500, {
          'error': {'message': 'no reply queued', 'code': 500},
        });
      }
      final reply = chatReplies.removeAt(0);
      final bytes = utf8.encode(reply.body);
      final controller = StreamController<Uint8List>();
      unawaited(() async {
        for (var i = 0; i < bytes.length; i += reply.chunkSize) {
          final end = i + reply.chunkSize > bytes.length
              ? bytes.length
              : i + reply.chunkSize;
          controller.add(Uint8List.fromList(bytes.sublist(i, end)));
          await Future<void>.delayed(Duration.zero);
        }
        if (reply.holdOpen) {
          open.add(controller);
        } else {
          await controller.close();
        }
      }());
      return ResponseBody(
        controller.stream,
        reply.status,
        headers: {
          Headers.contentTypeHeader: [
            if (reply.status == 200)
              'text/event-stream'
            else
              Headers.jsonContentType,
          ],
          for (final e in reply.headers.entries) e.key: [e.value],
        },
      );
    }
    return _json(404, {
      'error': {'message': 'Not Found', 'code': 404},
    });
  }

  @override
  void close({bool force = false}) {
    for (final c in open) {
      unawaited(c.close());
    }
    open.clear();
  }
}

/// An SSE body from chunk objects (`data: {...}` + `[DONE]`).
String sseOf(List<Map<String, Object?>> chunks, {bool done = true}) => [
  for (final c in chunks) 'data: ${jsonEncode(c)}\n\n',
  if (done) 'data: [DONE]\n\n',
].join();

/// A content chunk as OpenRouter sends it.
Map<String, Object?> chunk({
  String content = '',
  String? reasoning,
  String? finish,
  String provider = 'Z.AI',
  String model = 'z-ai/glm-5.3',
  Map<String, Object?>? usage,
}) => {
  'id': 'gen-test-1',
  'object': 'chat.completion.chunk',
  'created': 1794175210,
  'model': model,
  'provider': provider,
  'choices': [
    {
      'index': 0,
      'delta': {
        'content': content,
        'role': 'assistant',
        'reasoning': ?reasoning,
      },
      'finish_reason': finish,
      'native_finish_reason': finish,
    },
  ],
  'usage': ?usage,
};
