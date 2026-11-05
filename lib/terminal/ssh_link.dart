import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'phone_key.dart';
import 'terminal_trace.dart';

/// Where one terminal session goes: the account on the desktop and the tmux
/// session it attaches.
class SshTarget {
  const SshTarget({
    required this.host,
    required this.port,
    required this.user,
    required this.session,
    this.app = true,
  });

  final String host;
  final int port;
  final String user;

  /// The tmux session name.
  final String session;

  /// The app's own session (made by the app, or marked `@delve` before):
  /// made when it is missing, with a 10 000-line history, no status line
  /// and one line per wheel step. False: a session started on the desktop,
  /// attached as it is (T3).
  final bool app;

  String get hostPort => '$host:$port';

  SshTarget copyWith({String? session, bool? app}) => SshTarget(
    host: host,
    port: port,
    user: user,
    session: session ?? this.session,
    app: app ?? this.app,
  );

  /// The pty command. An exec channel starts a non-login shell without
  /// `LANG`, so tmux gets a UTF-8 locale and `-u` (T0). `=name` matches the
  /// session name exactly (a bare name would also match a prefix).
  ///
  /// An app session that is missing is made detached first: tmux gives a
  /// pane the history limit its session has when the pane is made, so the
  /// session's first window is replaced (`new-window -k`) after the option
  /// is set – `set-option` after `new-session`, or `respawn-pane`, leaves
  /// the first pane at the server's 2000 lines (T3-0, on a real tmux). The
  /// session is then marked as the app's (`@delve`), its status line is
  /// off (the tab bar names it, T2b) and the wheel bindings are set; a
  /// desktop session is attached unchanged (the bindings belong to the
  /// server and keep tmux's steps there). A desktop session that is gone
  /// ends the command at once ("can't find session").
  ///
  /// The app's windows do not scroll a cleared screen into the history
  /// ([tmuxNoScrollOnClear]): set on the first window before its shell
  /// prints anything, on the current one at every attach (sessions made
  /// before), and by a session hook on windows opened later.
  String get command {
    final exact = shellQuote('=$session');
    final attach = [
      'exec tmux -u attach-session -t $exact',
      if (app) ...[
        'set-option @delve 1',
        'set-option status off',
        tmuxNoScrollOnClear,
        "set-hook after-new-window '$tmuxNoScrollOnClear'",
      ],
      ...tmuxWheelBindings,
    ].join(r' \; ');
    return [
      'export LANG=en_US.UTF-8',
      if (app)
        'tmux -u has-session -t $exact 2>/dev/null || '
            'tmux -u new-session -d -s ${shellQuote(session)} '
            r'\; set-option history-limit '
            '$kAppHistoryLimit '
            r"\; new-window -k -t ':^' \; "
            '$tmuxNoScrollOnClear',
      attach,
    ].join('; ');
  }

  /// tmux (3.3+) moves the screen into the history when a program clears
  /// all of it (`scroll-on-clear`, on by default). zsh redraws its prompt on
  /// every pty resize with `\r…\e[J` – on the first row that clears the
  /// whole screen, so each resize (the first size, the keyboard opening and
  /// closing) left one more empty prompt in the history, and a bigger pane
  /// pulled them back onto the screen (T3 phone test: 8 prompts above a new
  /// session). Measured on a real tmux 3.4 with zsh 5.9: 7 history lines
  /// after five resizes, none with this option off; bash does not clear.
  static const tmuxNoScrollOnClear = 'set-option -w scroll-on-clear off';

  /// Asks tmux where the shell's cursor is on this session's pane, with the
  /// pane's history size ([parseShellCursor]); the session's name comes
  /// last, to check the answer: a session that is gone would be matched by
  /// another one starting with its name.
  String get shellCursorCommand =>
      'LANG=en_US.UTF-8 tmux -u display-message -p '
      '-t ${shellQuote('$session:')} '
      "'#{cursor_x}|#{cursor_y}|#{history_size}|#{session_name}'";

  /// tmux's wheel bindings, one line per step in the app's sessions.
  ///
  /// tmux scrolls 5 lines per wheel step in copy mode and the first step
  /// only enters copy mode: on a phone the text jumped 5 lines at a time and
  /// the start of a drag did nothing (T2b phone test). A key binding belongs
  /// to the whole tmux server, so the app's sessions are told apart by a
  /// session option (`@delve`): the desktop's other sessions keep tmux's
  /// defaults (`select-pane; send -X -N 5 scroll-…`, `copy-mode -e`). The
  /// root binding keeps tmux's test for a program that wants the mouse
  /// (htop, vim: `send -M`), with a nested two-way `||` (tmux 3.4 reads a
  /// three-way one as true). Tried on a real tmux: one line per step, the
  /// first step scrolls too, other sessions 0 then 5.
  static const tmuxWheelBindings = [
    "bind-key -T root WheelUpPane if-shell -F '#{||:#{alternate_on},"
        "#{||:#{pane_in_mode},#{mouse_any_flag}}}' 'send-keys -M' "
        "'copy-mode -e; if-shell -F \"#{@delve}\" \"send-keys -X -N 1 scroll-up\"'",
    "bind-key -T copy-mode WheelUpPane if-shell -F '#{@delve}' "
        "'select-pane; send-keys -X -N 1 scroll-up' "
        "'select-pane; send-keys -X -N 5 scroll-up'",
    "bind-key -T copy-mode WheelDownPane if-shell -F '#{@delve}' "
        "'select-pane; send-keys -X -N 1 scroll-down' "
        "'select-pane; send-keys -X -N 5 scroll-down'",
    "bind-key -T copy-mode-vi WheelUpPane if-shell -F '#{@delve}' "
        "'select-pane; send-keys -X -N 1 scroll-up' "
        "'select-pane; send-keys -X -N 5 scroll-up'",
    "bind-key -T copy-mode-vi WheelDownPane if-shell -F '#{@delve}' "
        "'select-pane; send-keys -X -N 1 scroll-down' "
        "'select-pane; send-keys -X -N 5 scroll-down'",
  ];
}

/// tmux's answer to [SshTarget.shellCursorCommand]: (column, row, history
/// size) – null when it is not about [session].
(int, int, int)? parseShellCursor(String output, String session) {
  final parts = output.trim().split('|');
  if (parts.length < 4 || parts.sublist(3).join('|') != session) return null;
  final x = int.tryParse(parts[0]);
  final y = int.tryParse(parts[1]);
  final history = int.tryParse(parts[2]);
  if (x == null || y == null || history == null) return null;
  return (x, y, history);
}

/// The history limit of the app's tmux sessions (T3: tmux's 2000 lines run
/// out after one `pacman -Syu`).
const kAppHistoryLimit = 10000;

/// [s] as one word for a POSIX shell (and zsh: a quoted `=` at the start of
/// a word is not a path expansion).
String shellQuote(String s) => "'${s.replaceAll("'", r"'\''")}'";

/// What an exec command printed, and how it ended.
class SshRunResult {
  const SshRunResult(this.output, this.exitCode, {this.error = ''});

  /// Its stdout, as text.
  final String output;

  /// Its stderr, as text (tmux's complaint when it failed).
  final String error;

  /// null: the desktop did not say.
  final int? exitCode;

  bool get ok => exitCode == null || exitCode == 0;
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

  /// Runs [command] on the same connection, without a pty (a second
  /// channel: the tmux session list, rename, kill – T3).
  Future<SshRunResult> run(String command, {Duration timeout = kRunTimeout});

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

  /// Connects, runs [command] without a pty and closes again (when no tab
  /// is connected; [SshTarget.session] is not used).
  Future<SshRunResult> run(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required String command,
    Duration timeout = kRunTimeout,
  });
}

/// How long a [SshLink.run] / [SshDialer.run] command may take.
const kRunTimeout = Duration(seconds: 8);

Future<SshRunResult> _runOn(
  SSHClient client,
  String command,
  Duration timeout,
) async {
  final r = await client.runWithResult(command).timeout(timeout);
  const text = Utf8Decoder(allowMalformed: true);
  return SshRunResult(
    text.convert(r.stdout),
    r.exitCode,
    error: text.convert(r.stderr).trim(),
  );
}

/// dartssh2 4.1: TCP, key auth, an `xterm-256color` pty running tmux.
class Dartssh2Dialer implements SshDialer {
  const Dartssh2Dialer({
    this.connectTimeout = const Duration(seconds: 20),
    this.connectEvery = const Duration(milliseconds: 500),
  });

  /// How long one attempt keeps trying to reach the desktop.
  final Duration connectTimeout;

  /// A new TCP connection every this long within an attempt, the first one
  /// that gets through wins ([staggered]).
  final Duration connectEvery;

  @override
  Future<SshLink> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required int columns,
    required int rows,
  }) async {
    final watch = Stopwatch()..start();
    void step(String what) => terminalTrace.add(
      target.session,
      '$what at ${watch.elapsedMilliseconds} ms',
    );
    final (client, socket, declined) = await _connect(
      target,
      key,
      verify,
      step: step,
    );
    try {
      await client.authenticated;
      step('authenticated');
      final session = await client.execute(
        target.command,
        pty: SSHPtyConfig(width: columns, height: rows),
      );
      step('session opened');
      return _Dartssh2Link(client, session, socket);
    } on Object catch (e) {
      unawaited(client.close());
      throw _failure(e, declined());
    }
  }

  @override
  Future<SshRunResult> run(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required String command,
    Duration timeout = kRunTimeout,
  }) async {
    final (client, _, declined) = await _connect(target, key, verify);
    try {
      await client.authenticated;
      return await _runOn(client, command, timeout);
    } on Object catch (e) {
      throw _failure(e, declined());
    } finally {
      unawaited(client.close().catchError((Object _) {}));
    }
  }

  /// An authenticated connection with no channel open yet (the Files tab's
  /// SFTP, F1); the same name lookup, staggered TCP and host-key check as a
  /// terminal tab. [abort] drops it at once (see [SshLink.abort]).
  Future<(SSHClient, void Function() abort)> connectClient(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
  }) async {
    final (client, socket, declined) = await _connect(target, key, verify);
    try {
      await client.authenticated;
      return (client, socket.abort);
    } on Object catch (e) {
      unawaited(client.close().catchError((Object _) {}));
      throw _failure(e, declined());
    }
  }

  Future<(SSHClient, _TcpSocket, bool Function())> _connect(
    SshTarget target,
    PhoneKey key,
    HostKeyCheck verify, {
    void Function(String what)? step,
  }) async {
    // the name is looked up on its own, so a trace shows whether the name
    // (Tailscale's DNS) or the connection is slow after a long background
    final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(
        target.host,
      ).timeout(connectTimeout);
    } on Object catch (e) {
      step?.call('name lookup failed (${_short(e)})');
      throw SshUnreachable('name lookup: ${_short(e)}');
    }
    final address = addresses.firstWhere(
      (a) => a.type == InternetAddressType.IPv4,
      orElse: () => addresses.first,
    );
    step?.call('name looked up');
    final _TcpSocket socket;
    try {
      final (raw, tries) = await staggered<Socket>(
        start: (left) => Socket.connect(address, target.port, timeout: left),
        discard: (s) => s.destroy(),
        every: connectEvery,
        within: connectTimeout,
      );
      socket = _TcpSocket(raw);
      step?.call('tcp connected (try $tries)');
    } on Object catch (e) {
      step?.call('tcp failed (${_short(e)})');
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
        step?.call('host key received');
        final ok = await verify(type, String.fromCharCodes(fingerprint));
        declined = !ok;
        return ok;
      },
    );
    return (client, socket, () => declined);
  }

  static SshFailure _failure(Object e, bool declined) {
    if (e is SshFailure) return e;
    if (declined || e is SSHHostkeyError) return SshHostKeyRejected(_short(e));
    if (e is SSHAuthError) return SshAuthDenied(_short(e));
    return SshUnreachable(_short(e));
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
  Future<SshRunResult> run(
    String command, {
    Duration timeout = kRunTimeout,
  }) async {
    try {
      return await _runOn(_client, command, timeout);
    } on Object catch (e) {
      throw SshUnreachable(Dartssh2Dialer._short(e));
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

/// Starts a try every [every] (the first at once) until one succeeds or
/// [within] has passed; each try gets the time left. The first success
/// wins, later ones are [discard]ed. Fails with the last try's error when
/// none got through.
///
/// T4: after a long sleep the phone's Tailscale tunnel needs several seconds
/// to come back, and the SYNs sent meanwhile are lost; one socket would
/// then wait out the kernel's SYN backoff (1, 2, 4 s …) and its timeout.
/// A fresh try every half second gets through soon after the tunnel is up.
Future<(T, int)> staggered<T>({
  required Future<T> Function(Duration left) start,
  required void Function(T value) discard,
  required Duration every,
  required Duration within,
}) {
  final done = Completer<(T, int)>();
  final watch = Stopwatch()..start();
  var tries = 0;
  var open = 0;
  var expired = false;
  Object? lastError;
  StackTrace? lastStack;
  Timer? next;

  void failIfOver() {
    if (done.isCompleted || open > 0 || !expired) return;
    done.completeError(
      lastError ?? TimeoutException('no answer', within),
      lastStack,
    );
  }

  late final Timer deadline;
  void launch() {
    if (done.isCompleted) return;
    final left = within - watch.elapsed;
    if (left <= Duration.zero) return;
    tries++;
    open++;
    final n = tries;
    start(left).then(
      (value) {
        open--;
        if (done.isCompleted) {
          discard(value);
          return;
        }
        next?.cancel();
        deadline.cancel();
        done.complete((value, n));
      },
      onError: (Object e, StackTrace st) {
        open--;
        lastError = e;
        lastStack = st;
        failIfOver();
      },
    );
    if (left > every) next = Timer(every, launch);
  }

  deadline = Timer(within, () {
    expired = true;
    next?.cancel();
    failIfOver();
  });
  launch();
  return done.future;
}
