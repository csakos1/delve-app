import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'phone_key.dart';

/// Where one terminal session goes: the account on the desktop and the tmux
/// session it attaches.
class SshTarget {
  const SshTarget({
    required this.host,
    required this.port,
    required this.user,
    required this.session,
  });

  final String host;
  final int port;
  final String user;

  /// The tmux session name.
  final String session;

  String get hostPort => '$host:$port';

  /// The pty command: an exec channel starts a non-login shell without
  /// `LANG`, so tmux gets a UTF-8 locale and `-u` (T0); `-A` attaches the
  /// session if it exists.
  String get command =>
      'env LANG=en_US.UTF-8 tmux -u new-session -A -s ${quoteSession(session)}';

  /// A tmux session name as one shell word.
  static String quoteSession(String s) =>
      RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(s)
      ? s
      : "'${s.replaceAll("'", '')}'";
}

/// Why opening a session failed.
sealed class SshFailure implements Exception {
  const SshFailure(this.detail);

  final String detail;

  @override
  String toString() => '$runtimeType: $detail';
}

/// The desktop could not be reached (DNS, refused, timeout, dropped).
class SshUnreachable extends SshFailure {
  const SshUnreachable(super.detail);
}

/// sshd refused the phone's key.
class SshAuthDenied extends SshFailure {
  const SshAuthDenied(super.detail);
}

/// The host key was not accepted (a changed pin, or the user said no).
class SshHostKeyRejected extends SshFailure {
  const SshHostKeyRejected(super.detail);
}

/// How a live session ended.
enum SshEnd {
  /// The tmux session itself ended (`exit` in its last window).
  sessionEnded,

  /// The connection went away.
  connectionLost,
}

/// Asked once per connection when the host key is shown; true = go on.
typedef HostKeyCheck = Future<bool> Function(String type, String fingerprint);

/// One live SSH connection with one pty channel.
abstract interface class SshLink {
  /// The pty's output (stdout and stderr together).
  Stream<Uint8List> get output;

  void write(Uint8List data);

  void resize(int columns, int rows);

  /// Completes once, when the session or the connection ends.
  Future<SshEnd> get done;

  /// Asks the desktop for an answer (an SSH keep-alive with a reply): true
  /// when one came within [timeout]. A dead network does not end a TCP
  /// connection for minutes, so only an answer tells it is still there.
  Future<bool> probe(Duration timeout);

  /// Closes it the polite way (the session's end goes to sshd).
  Future<void> close();

  /// Drops it at once: what was written but not sent yet is thrown away (a
  /// keystroke must not arrive minutes later, after the network is back).
  void abort();
}

/// Opens [SshLink]s.
abstract interface class SshDialer {
  Future<SshLink> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required int columns,
    required int rows,
  });
}

/// dartssh2 4.1: TCP, key auth, an `xterm-256color` pty running tmux.
class Dartssh2Dialer implements SshDialer {
  const Dartssh2Dialer({this.connectTimeout = const Duration(seconds: 8)});

  final Duration connectTimeout;

  @override
  Future<SshLink> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required int columns,
    required int rows,
  }) async {
    final _TcpSocket socket;
    try {
      socket = _TcpSocket(
        await Socket.connect(target.host, target.port, timeout: connectTimeout),
      );
    } on Object catch (e) {
      throw SshUnreachable(_short(e));
    }
    var declined = false;
    final client = SSHClient(
      socket,
      username: target.user,
      identities: [key.keyPair],
      // dartssh2's keep-alive waits for the answer forever and ignores a
      // missing one; TerminalConnection probes with a timeout instead
      keepAliveInterval: null,
      onVerifyHostKey: (type, fingerprint) async {
        final ok = await verify(type, String.fromCharCodes(fingerprint));
        declined = !ok;
        return ok;
      },
    );
    try {
      await client.authenticated;
      final session = await client.execute(
        target.command,
        pty: SSHPtyConfig(width: columns, height: rows),
      );
      return _Dartssh2Link(client, session, socket);
    } on Object catch (e) {
      unawaited(client.close());
      if (declined || e is SSHHostkeyError) {
        throw SshHostKeyRejected(_short(e));
      }
      if (e is SSHAuthError) throw SshAuthDenied(_short(e));
      throw SshUnreachable(_short(e));
    }
  }

  static String _short(Object e) => switch (e) {
    SocketException(:final message, :final osError) =>
      osError == null ? message : '$message (${osError.message})',
    TimeoutException() => 'timed out',
    _ => '$e',
  };
}

/// A TCP socket for dartssh2 that can be dropped without sending what is
/// still queued (SO_LINGER 0: the kernel discards the send buffer and resets
/// the connection instead of retransmitting it for minutes).
class _TcpSocket implements SSHSocket {
  _TcpSocket(this._socket) {
    try {
      _socket.setOption(SocketOption.tcpNoDelay, true);
    } on Object {
      // best effort
    }
  }

  final Socket _socket;
  bool _aborted = false;

  // Linux / Android: SOL_SOCKET = 1, SO_LINGER = 13; struct linger is two
  // ints {l_onoff = 1, l_linger = 0}
  static const _soLinger = 13;

  void abort() {
    if (_aborted) return;
    _aborted = true;
    try {
      _socket.setRawOption(
        RawSocketOption(
          RawSocketOption.levelSocket,
          _soLinger,
          Uint8List.fromList(const [1, 0, 0, 0, 0, 0, 0, 0]),
        ),
      );
    } on Object {
      // not Linux: a plain destroy
    }
    _socket.destroy();
  }

  @override
  Stream<Uint8List> get stream => _socket;

  @override
  StreamSink<List<int>> get sink => _socket;

  @override
  Future<void> get done => _socket.done;

  @override
  Future<void> close() async {
    if (_aborted) return;
    await _socket.close();
  }

  @override
  void destroy() => _socket.destroy();

  @override
  Future<void> flush() async {
    if (!_aborted) await _socket.flush();
  }
}

class _Dartssh2Link implements SshLink {
  _Dartssh2Link(this._client, this._session, this._socket) {
    var open = 2;
    void closed() {
      if (--open == 0) unawaited(_output.close());
    }

    _session.stdout.listen(_output.add, onDone: closed, onError: (_) {});
    _session.stderr.listen(_output.add, onDone: closed, onError: (_) {});
    _done = Future.any<SshEnd>([
      _session.done.then(
        (_) => _client.isClosed ? SshEnd.connectionLost : SshEnd.sessionEnded,
        onError: (_) => SshEnd.connectionLost,
      ),
      _client.done.then(
        (_) => SshEnd.connectionLost,
        onError: (_) => SshEnd.connectionLost,
      ),
    ]);
  }

  final SSHClient _client;
  final SSHSession _session;
  final _TcpSocket _socket;
  final _output = StreamController<Uint8List>();
  late final Future<SshEnd> _done;

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  void write(Uint8List data) => _session.write(data);

  @override
  void resize(int columns, int rows) {
    if (columns > 0 && rows > 0) _session.resizeTerminal(columns, rows);
  }

  @override
  Future<SshEnd> get done => _done;

  @override
  Future<bool> probe(Duration timeout) async {
    if (_client.isClosed) return false;
    try {
      await _client.ping().timeout(timeout);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> close() async {
    try {
      _session.close();
      await _client.close();
    } on Object {
      // already gone
    }
  }

  @override
  void abort() {
    _socket.abort();
    unawaited(_client.close().catchError((Object _) {}));
  }
}
