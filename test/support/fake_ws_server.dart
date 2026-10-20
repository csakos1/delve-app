import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A local WebSocket server that plays the backend's part of the protocol,
/// scripted by the test (decision 172): real sockets on 127.0.0.1, so the
/// app's own transport is under test too.
class FakeWsServer {
  FakeWsServer._(this._http) {
    _http.listen(_onRequest);
  }

  static Future<FakeWsServer> start() async =>
      FakeWsServer._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _http;

  /// `http://127.0.0.1:<port>` — the engine turns it into `ws://…/api/v1/ws`.
  Uri get origin => Uri.parse('http://127.0.0.1:${_http.port}');

  final List<FakeWsConnection> connections = [];
  final _connected = StreamController<FakeWsConnection>.broadcast();

  /// Answer upgrades with 502 (the proxy is up, the backend is not).
  bool refuse = false;

  /// Reply to `hello` automatically with [epoch] and the current [seq].
  bool autoHello = true;
  String epoch = 'epoch-1';
  int seq = 0;
  bool resyncRequired = false;

  /// Acknowledge `chat.send` automatically.
  bool autoAck = true;
  int _messageIds = 100;

  /// The next connection (or the one already waiting).
  Future<FakeWsConnection> nextConnection({int index = -1}) {
    final want = index < 0 ? connections.length : index;
    if (connections.length > want) {
      return Future.value(connections[want]);
    }
    return _connected.stream
        .firstWhere((_) => connections.length > want)
        .then((_) => connections[want])
        .timeout(const Duration(seconds: 5));
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (refuse || !WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = refuse
          ? HttpStatus.badGateway
          : HttpStatus.notFound;
      await req.response.close();
      return;
    }
    // closed by FakeWsConnection.close() (FakeWsServer.close() closes all)
    // ignore: close_sinks
    final ws = await WebSocketTransformer.upgrade(req);
    final conn = FakeWsConnection._(this, ws, req.uri.path);
    connections.add(conn);
    _connected.add(conn);
  }

  /// A broadcast event with the next seq, on every open connection.
  int broadcast(String type, Map<String, Object?> data) {
    seq++;
    for (final c in connections) {
      if (c.isOpen && c.helloAnswered) {
        c.sendRaw({'type': type, 'seq': seq, 'data': data});
      }
    }
    return seq;
  }

  Map<String, Object?> helloOk() => {
    'type': 'hello.ok',
    'data': {
      'server_version': '0.1.0',
      'api_revision': 4,
      'revision': null,
      'hermes': 'ok',
      'hermes_version': '0.22.2',
      'thinking_route': null,
      'epoch': epoch,
      'seq': seq,
      'resync_required': resyncRequired,
    },
  };

  Future<void> close() async {
    for (final c in connections) {
      await c.close(1001);
    }
    await _http.close(force: true);
    await _connected.close();
  }
}

class FakeWsConnection {
  FakeWsConnection._(this.server, this._ws, this.path) {
    _ws.listen(
      (raw) {
        final frame = jsonDecode(raw as String) as Map<String, Object?>;
        received.add(frame);
        _frames.add(frame);
        _auto(frame);
      },
      onDone: () {
        isOpen = false;
        _closed.complete();
        unawaited(_frames.close());
      },
    );
  }

  final FakeWsServer server;
  final WebSocket _ws;
  final String path;
  final List<Map<String, Object?>> received = [];
  final _frames = StreamController<Map<String, Object?>>.broadcast();
  final _closed = Completer<void>();
  bool isOpen = true;
  bool helloAnswered = false;

  Future<void> get done => _closed.future;

  /// The first client frame of [type] (already received or still to come).
  Future<Map<String, Object?>> next(String type) {
    for (final f in received) {
      if (f['type'] == type) return Future.value(f);
    }
    return _frames.stream
        .firstWhere((f) => f['type'] == type)
        .timeout(const Duration(seconds: 5));
  }

  /// Every client frame of [type] so far.
  List<Map<String, Object?>> all(String type) => [
    for (final f in received)
      if (f['type'] == type) f,
  ];

  void _auto(Map<String, Object?> frame) {
    final data = frame['data']! as Map<String, Object?>;
    switch (frame['type']) {
      case 'hello' when server.autoHello:
        answerHello();
      case 'chat.send' when server.autoAck:
        final convId = data['conversation_id'] as String? ?? 'c_new';
        reply(frame, {
          'conversation_id': convId,
          'message_id': server._messageIds++,
          'run_id': 'q_${server._messageIds}',
          'replayed': false,
        });
      case 'ping':
        sendRaw({
          'type': 'pong',
          'id': frame['id'],
          'data': <String, Object?>{},
        });
    }
  }

  void answerHello() {
    helloAnswered = true;
    sendRaw(server.helloOk());
  }

  void reply(Map<String, Object?> request, Map<String, Object?> data) =>
      sendRaw({'type': 'ack', 'id': request['id'], 'data': data});

  void replyError(Map<String, Object?> request, String code) => sendRaw({
    'type': 'error',
    'id': request['id'],
    'data': {'code': code, 'message': code},
  });

  /// An event on this connection only (e.g. a replay after `hello.ok`).
  void event(int seq, String type, Map<String, Object?> data) =>
      sendRaw({'type': type, 'seq': seq, 'data': data});

  void sendRaw(Map<String, Object?> frame) {
    if (isOpen) _ws.add(jsonEncode(frame));
  }

  Future<void> close(int code, [String reason = '']) async {
    if (!isOpen) return;
    await _ws.close(code, reason);
  }
}
