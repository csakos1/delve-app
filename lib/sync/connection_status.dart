/// Connection state machine (decision 169):
/// `offline → connecting → awaitingHello → live ⇄ backoff`, plus `authFailed`.
enum ConnectionPhase {
  /// Not connected and not trying: not started yet, or the app has been in
  /// the background longer than the grace period.
  offline,
  connecting,
  awaitingHello,
  live,

  /// Waiting before the next attempt ([ConnectionStatus.retryAt]).
  backoff,

  /// The server refused the token (4401); the session goes back to pairing.
  authFailed,
}

/// Why the last attempt or connection ended.
enum ConnectionProblem {
  /// No answer from the server: Tailscale off, desktop down or asleep.
  unreachable,

  /// The server answered but would not open a WebSocket (backend down
  /// behind `tailscale serve`).
  rejected,

  /// No `hello.ok` in time.
  helloTimeout,

  /// Nothing (not even a keepalive) for the silence window.
  silent,

  /// The server closed the socket (4400, 4408 or anything unexpected).
  closed,

  /// The reload after a restart of the server failed.
  resyncFailed,
}

class ConnectionStatus {
  const ConnectionStatus({
    required this.phase,
    this.since,
    this.attempt = 0,
    this.retryAt,
    this.problem,
    this.detail,
    this.hermes,
    this.resyncing = false,
  });

  static const ConnectionStatus initial = ConnectionStatus(
    phase: ConnectionPhase.offline,
  );

  final ConnectionPhase phase;

  /// When [phase] began.
  final DateTime? since;

  /// Failed attempts in a row (0 once live).
  final int attempt;

  /// Next attempt, in [ConnectionPhase.backoff].
  final DateTime? retryAt;

  /// Why the last connection ended; kept while retrying, cleared once live.
  final ConnectionProblem? problem;

  /// Technical detail of [problem] (close code, OS error).
  final String? detail;

  /// Hermes as the backend sees it: ok | down | null (not known yet).
  final String? hermes;

  /// Live, but reloading after a server restart.
  final bool resyncing;

  bool get isLive => phase == ConnectionPhase.live;

  ConnectionStatus copyWith({
    ConnectionPhase? phase,
    DateTime? since,
    int? attempt,
    DateTime? retryAt,
    ConnectionProblem? problem,
    String? detail,
    String? hermes,
    bool? resyncing,
    bool clearRetry = false,
    bool clearProblem = false,
  }) => ConnectionStatus(
    phase: phase ?? this.phase,
    since: since ?? this.since,
    attempt: attempt ?? this.attempt,
    retryAt: clearRetry ? null : retryAt ?? this.retryAt,
    problem: clearProblem ? null : problem ?? this.problem,
    detail: clearProblem ? null : detail ?? this.detail,
    hermes: hermes ?? this.hermes,
    resyncing: resyncing ?? this.resyncing,
  );

  @override
  String toString() =>
      'ConnectionStatus(${phase.name}, attempt $attempt'
      '${problem == null ? '' : ', ${problem!.name}'}${resyncing ? ', resyncing' : ''})';
}

/// Connection-log entry kinds (stored by name).
enum LogKind {
  connecting,
  connected,
  resync,
  closed,
  failed,
  backoff,
  paused,
  resumed,
  authFailed,
  outbox,
  hermes,
  serverError,
  protocol;

  static LogKind? parse(String name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}
