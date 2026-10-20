import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// One open WebSocket. [messages] ends when the socket closes; [closeCode]
/// and [closeReason] are set by then.
abstract interface class WsLink {
  Stream<Object?> get messages;
  void send(String text);
  Future<void> close(int code, [String? reason]);
  int? get closeCode;
  String? get closeReason;
}

/// Opens WebSockets; tests can swap it out.
abstract interface class WsTransport {
  /// Throws [WsConnectError].
  Future<WsLink> connect(Uri uri);
}

/// Why a socket could not be opened.
enum WsConnectProblem {
  /// No answer: DNS, refused, timeout, TLS. Over a tailnet: Tailscale is off
  /// on the phone, or the desktop is down or asleep.
  unreachable,

  /// Something answered but did not accept a WebSocket (e.g. the
  /// `tailscale serve` proxy is up and the backend is not: 502).
  rejected,
}

class WsConnectError implements Exception {
  const WsConnectError(this.problem, this.cause);

  final WsConnectProblem problem;

  /// Short technical reason for the connection log.
  final String cause;

  static WsConnectError from(Object error) {
    final inner = error is WebSocketChannelException
        ? error.inner ?? error
        : error;
    return switch (inner) {
      SocketException(:final osError?, :final message) => WsConnectError(
        WsConnectProblem.unreachable,
        osError.message.isEmpty ? message : osError.message,
      ),
      SocketException(:final message) => WsConnectError(
        WsConnectProblem.unreachable,
        message,
      ),
      TimeoutException() => const WsConnectError(
        WsConnectProblem.unreachable,
        'timeout',
      ),
      HandshakeException() => const WsConnectError(
        WsConnectProblem.unreachable,
        'TLS handshake failed',
      ),
      WebSocketException(:final message) => WsConnectError(
        WsConnectProblem.rejected,
        message,
      ),
      HttpException(:final message) => WsConnectError(
        WsConnectProblem.rejected,
        message,
      ),
      _ => WsConnectError(
        WsConnectProblem.unreachable,
        inner.runtimeType.toString(),
      ),
    };
  }

  @override
  String toString() => 'WsConnectError(${problem.name}: $cause)';
}

/// `dart:io` sockets through `web_socket_channel` (no protocol-level ping:
/// the app watches the server's keepalive itself).
class IoWsTransport implements WsTransport {
  const IoWsTransport({this.connectTimeout = const Duration(seconds: 10)});

  final Duration connectTimeout;

  @override
  Future<WsLink> connect(Uri uri) async {
    final channel = IOWebSocketChannel.connect(
      uri,
      connectTimeout: connectTimeout,
    );
    try {
      await channel.ready;
    } on Object catch (e) {
      // the failed channel reports the same error on its stream and sink
      channel.sink.done.ignore();
      unawaited(
        channel.stream.drain<void>().then<void>((_) {}, onError: (Object _) {}),
      );
      throw WsConnectError.from(e);
    }
    return _ChannelLink(channel);
  }
}

class _ChannelLink implements WsLink {
  _ChannelLink(this._channel);

  final IOWebSocketChannel _channel;

  @override
  Stream<Object?> get messages => _channel.stream;

  @override
  void send(String text) => _channel.sink.add(text);

  @override
  Future<void> close(int code, [String? reason]) async {
    try {
      await _channel.sink.close(code, reason);
    } on Object {
      // already closed
    }
  }

  @override
  int? get closeCode => _channel.closeCode;

  @override
  String? get closeReason => _channel.closeReason;
}

/// `https://host` → `wss://host/api/v1/ws` (`http` → `ws` for local tests).
Uri webSocketUri(Uri server, String path) =>
    server.replace(scheme: server.scheme == 'http' ? 'ws' : 'wss', path: path);
