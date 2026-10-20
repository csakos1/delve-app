import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A canned answer.
class FakeReply {
  const FakeReply(this.status, [this.json, this.headers = const {}]);
  final int status;
  final Object? json;
  final Map<String, String> headers;
}

typedef FakeHandler = FakeReply Function(RequestOptions request);

/// In-process stand-in for the backend: a dio adapter that answers from
/// registered routes (`'GET /api/v1/meta'`), records every request, and can
/// pretend the server is unreachable.
class FakeServer implements HttpClientAdapter {
  FakeServer() {
    reset();
  }

  final Map<String, FakeHandler> routes = {};
  final List<RequestOptions> requests = [];

  /// Throw a DNS failure for every request (Tailscale off).
  bool unreachable = false;

  /// The backend's error body.
  static Map<String, Object?> detail(String code, [String message = '']) => {
    'detail': {'code': code, 'message': message},
  };

  static const meta = {
    'server_version': '0.1.0',
    'api_revision': 3,
    'revision': 'eb4045ed6a94',
    'python': '3.14.8',
    'hermes_expected_version': '0.22.2',
    'approval_timeout_s': 300,
  };

  static const status = {
    'server_version': '0.1.0',
    'api_revision': 3,
    'revision': 'eb4045ed6a94',
    'hermes': 'ok',
    'hermes_version': '0.22.2',
    'thinking_route': {
      'ok': true,
      'run_id': 'run_8e4b1c2d3a4f5e6b',
      'at': '2026-10-19T21:39:00.123456+00:00',
    },
  };

  static const device = {
    'id': '0f5e2c3a-1b2d-4e6f-8a9b-0c1d2e3f4a5b',
    'name': 'pixel',
    'created_at': '2026-10-12T18:00:00+00:00',
    'last_seen_at': null,
    'fcm': false,
    'push': true,
    'notify': {
      'approvals': true,
      'run_done': true,
      'water': false,
      'brief': false,
    },
  };

  /// A healthy, paired server.
  void reset() {
    routes.clear();
    unreachable = false;
    json('GET', '/api/v1/meta', meta);
    json('GET', '/api/v1/status', status);
    json('GET', '/api/v1/devices/me', device);
    routes['DELETE /api/v1/devices/me'] = (_) => const FakeReply(204);
    routes['PUT /api/v1/devices/me/fcm'] = (_) => const FakeReply(204);
    json('GET', '/api/v1/conversations', {
      'data': <Object?>[],
      'next_cursor': null,
    });
    json('GET', '/api/v1/runs/open', {'data': <Object?>[]});
    json('GET', '/api/v1/approvals', {'data': <Object?>[]});
  }

  void on(String method, String path, FakeHandler handler) =>
      routes['$method $path'] = handler;

  void json(String method, String path, Object? body, {int status = 200}) =>
      on(method, path, (_) => FakeReply(status, body));

  List<String> get calls => [
    for (final r in requests) '${r.method} ${r.uri.path}',
  ];

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
    final handler = routes['${options.method} ${options.uri.path}'];
    final reply =
        handler?.call(options) ?? FakeReply(404, {'detail': 'Not Found'});
    final headers = <String, List<String>>{
      for (final e in reply.headers.entries) e.key: [e.value],
    };
    if (reply.json == null) {
      return ResponseBody.fromString('', reply.status, headers: headers);
    }
    headers[Headers.contentTypeHeader] = [Headers.jsonContentType];
    return ResponseBody.fromString(
      jsonEncode(reply.json),
      reply.status,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}
