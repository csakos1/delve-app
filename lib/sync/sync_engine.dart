import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../api/api_error.dart';
import '../api/events.dart';
import '../api/models/models.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import '../data/credentials.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';
import 'backoff.dart';
import 'connection_status.dart';
import 'live_runs.dart';
import 'reducer.dart';
import 'resync.dart';
import 'transport.dart';

/// Timings of the connection (decision 169); tests shrink them.
class SyncTiming {
  const SyncTiming({
    this.helloTimeout = const Duration(seconds: 10),
    this.silence = const Duration(seconds: 45),
    this.backoffMin = const Duration(seconds: 1),
    this.backoffMax = const Duration(seconds: 30),
    this.pauseGrace = const Duration(seconds: 3),
    this.batchWindow = const Duration(milliseconds: 80),
    this.ackTimeout = const Duration(seconds: 15),
    this.pingInterval = const Duration(seconds: 20),
    this.sentSettle = const Duration(seconds: 10),
  });

  final Duration helloTimeout;

  /// The server sends a keepalive every 20 s; nothing for this long = dead.
  final Duration silence;
  final Duration backoffMin;
  final Duration backoffMax;

  /// How long the socket stays open after the app went to the background.
  /// Short: the socket is closed cleanly before Android cuts the network
  /// (~10 s), so the server knows at once to push "run finished".
  final Duration pauseGrace;

  /// Events are written in batches collected over this window.
  final Duration batchWindow;
  final Duration ackTimeout;

  /// A `ping` this often while live: the server counts a socket as live only
  /// while frames arrive (push presence, decision 261).
  final Duration pingInterval;

  /// An acknowledged message stays in the outbox (state `sent`) until its
  /// `message.created` is written, so the chat never shows a gap between
  /// the two; if the event does not come within this time, the row goes.
  final Duration sentSettle;
}

/// Why a request over the socket did not get an answer.
sealed class SyncError implements Exception {
  const SyncError();
}

/// Not live: the request was not sent.
final class NotConnected extends SyncError {
  const NotConnected();

  @override
  String toString() => 'NotConnected';
}

/// Sent, but the connection ended or no answer came in time; the server
/// may or may not have acted on it.
final class NoAnswer extends SyncError {
  const NoAnswer();

  @override
  String toString() => 'NoAnswer';
}

/// The server answered with `error {code, message}`.
final class RequestRejected extends SyncError {
  const RequestRejected(this.code, this.message);
  final String code;
  final String? message;

  @override
  String toString() => 'RequestRejected($code)';
}

/// The app's end of the WebSocket (decisions 168–170): connects while the
/// app is in the foreground, resumes the event stream with `last_seq` and
/// `epoch`, reloads over REST when it cannot, writes events to the database
/// in batches, resends the outbox, and keeps a connection log.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.credentials,
    required this.api,
    required this.transport,
    required this.onUnauthorized,
    this.onLiveRuns,
    this.timing = const SyncTiming(),
    Stream<void>? networkChanges,
    Random? random,
    DateTime Function()? now,
  }) : _random = random ?? Random(),
       _now = now ?? DateTime.now {
    _reducer = EventReducer(db, live, now: _now);
    _networkSub = networkChanges?.listen((_) => _onNetworkChange());
  }

  final AppDatabase db;
  final Credentials credentials;
  final DelveApi api;
  final WsTransport transport;

  /// The server refused the token (close 4401).
  final void Function() onUnauthorized;

  /// Called after every batch that changed the streaming state.
  final void Function(Map<String, LiveRun> runs)? onLiveRuns;
  final SyncTiming timing;

  final Random _random;
  final DateTime Function() _now;
  final LiveRunsBuffer live = LiveRunsBuffer();
  late final EventReducer _reducer;
  StreamSubscription<void>? _networkSub;

  final _statusController = StreamController<ConnectionStatus>.broadcast(
    sync: true,
  );
  ConnectionStatus _status = ConnectionStatus.initial;

  ConnectionStatus get status => _status;
  Stream<ConnectionStatus> get statusChanges => _statusController.stream;

  final _systemController = StreamController<SystemInfo>.broadcast();

  /// `system.updated` events (B3): the system view after a llama-server
  /// stop or start, or when the held queue is let go.
  Stream<SystemInfo> get systemUpdates => _systemController.stream;

  final _scheduleController = StreamController<ScheduleChange>.broadcast();

  /// `schedule.updated` / `schedule.deleted` events (B4).
  Stream<ScheduleChange> get scheduleChanges => _scheduleController.stream;

  Uri get webSocketUrl => webSocketUri(credentials.server, ApiRoutes.ws.$2);

  bool _started = false;
  bool _disposed = false;
  bool _foreground = true;

  WsLink? _link;
  int _generation = 0; // ignores callbacks of sockets that are gone
  StreamSubscription<Object?>? _linkSub;
  Timer? _helloTimer;
  Timer? _silenceTimer;
  Timer? _retryTimer;
  Timer? _pauseTimer;
  Timer? _flushTimer;
  Timer? _pingTimer;

  /// Why we closed the socket ourselves (null: the server or network did).
  (ConnectionProblem?, String)? _ourClose;

  String? _epoch;
  int _appliedSeq = -1;

  /// Events are collected but not applied: between `hello.ok` and the
  /// decision how to resume, and while a resync reloads over REST.
  bool _holding = false;
  final List<ServerEvent> _pending = [];
  Future<void> _applying = Future<void>.value();

  int _requestCounter = 0;
  final Map<String, Completer<Map<String, Object?>>> _requests = {};
  bool _outboxRunning = false;
  final Set<Timer> _settleTimers = {};
  String? _focus;

  // ---------------------------------------------------------------------------
  // lifecycle

  /// Starts connecting (once). Outbox rows left `sending` by a previous run of
  /// the app go back to `pending`; `sent` ones (acknowledged) are dropped.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    await (db.update(db.outbox)..where((t) => t.state.equals('sending'))).write(
      const OutboxCompanion(state: Value('pending')),
    );
    await (db.delete(db.outbox)..where((t) => t.state.equals('sent'))).go();
    if (_foreground) _connect();
  }

  /// App lifecycle: in the background the socket closes after
  /// [SyncTiming.pauseGrace]; back in the foreground it reconnects at once.
  void setForeground(bool foreground) {
    if (_disposed || foreground == _foreground) return;
    _foreground = foreground;
    if (!foreground) {
      _pauseTimer?.cancel();
      _pauseTimer = Timer(timing.pauseGrace, _pause);
      return;
    }
    final wasPaused = _status.phase == ConnectionPhase.offline;
    _pauseTimer?.cancel();
    _pauseTimer = null;
    if (!_started) return;
    if (wasPaused) _log(LogKind.resumed, null);
    if (_status.phase == ConnectionPhase.offline ||
        _status.phase == ConnectionPhase.backoff) {
      _retryTimer?.cancel();
      _setStatus(_status.copyWith(attempt: 0));
      _connect();
    }
  }

  void _pause() {
    _pauseTimer = null;
    if (_disposed || _foreground) return;
    _log(LogKind.paused, 'app in the background');
    _retryTimer?.cancel();
    _closeLink(1000, 'paused', null);
    _setPhase(ConnectionPhase.offline, clearRetry: true);
  }

  /// "Reconnect now" (connection log screen) and network changes.
  void reconnectNow() {
    if (_disposed || !_started) return;
    if (_status.phase == ConnectionPhase.backoff ||
        _status.phase == ConnectionPhase.offline) {
      _retryTimer?.cancel();
      _connect();
    }
  }

  void _onNetworkChange() {
    if (_status.phase == ConnectionPhase.backoff && _foreground) {
      _log(LogKind.resumed, 'network changed');
      reconnectNow();
    }
  }

  /// The chat on screen; a resync reloads its messages too.
  void focusConversation(String? conversationId) => _focus = conversationId;

  /// The chat on screen (push: its approvals need no notification).
  String? get focus => _focus;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final t in [
      _helloTimer,
      _silenceTimer,
      _retryTimer,
      _pauseTimer,
      _flushTimer,
      _pingTimer,
      ..._settleTimers,
    ]) {
      t?.cancel();
    }
    _settleTimers.clear();
    await _networkSub?.cancel();
    _closeLink(1000, 'bye', null);
    _failRequests(const NoAnswer());
    await _applying;
    await _statusController.close();
    await _systemController.close();
    await _scheduleController.close();
  }

  // ---------------------------------------------------------------------------
  // connecting

  void _connect() {
    if (_disposed || !_foreground) return;
    final gen = ++_generation;
    // first attempt only: retries are logged with their failure
    if (_status.attempt == 0) {
      _log(LogKind.connecting, webSocketUrl.host);
    }
    _setPhase(ConnectionPhase.connecting, clearRetry: true);
    unawaited(_open(gen));
  }

  Future<void> _open(int gen) async {
    final WsLink link;
    try {
      link = await transport.connect(webSocketUrl);
    } on WsConnectError catch (e) {
      if (gen != _generation || _disposed) return;
      final problem = switch (e.problem) {
        WsConnectProblem.unreachable => ConnectionProblem.unreachable,
        WsConnectProblem.rejected => ConnectionProblem.rejected,
      };
      _scheduleRetry(problem, e.cause, logAs: '${problem.name}: ${e.cause}');
      return;
    }
    if (gen != _generation || _disposed || !_foreground) {
      unawaited(link.close(1000, 'not needed'));
      return;
    }
    _link = link;
    _ourClose = null;
    _setPhase(ConnectionPhase.awaitingHello);
    _linkSub = link.messages.listen(
      (raw) => _onRaw(gen, raw),
      onError: (Object _) {}, // the close below tells what happened
      onDone: () => _onClosed(gen, link),
    );
    final sync = await db.readSyncState();
    if (gen != _generation) return;
    link.send(
      jsonEncode(
        ClientFrames.hello(
          id: 'hello',
          deviceToken: credentials.token,
          lastSeq: sync.lastSeq,
          epoch: sync.epoch,
        ),
      ),
    );
    _helloTimer = Timer(timing.helloTimeout, () {
      if (gen != _generation) return;
      _closeLink(4000, 'hello timeout', ConnectionProblem.helloTimeout);
    });
    _armSilence(gen);
  }

  void _startPing(int gen) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(timing.pingInterval, (t) {
      final link = _link;
      if (gen != _generation || link == null) {
        t.cancel();
        return;
      }
      link.send(jsonEncode(ClientFrames.ping(id: 'ping')));
    });
  }

  void _armSilence(int gen) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(timing.silence, () {
      if (gen != _generation) return;
      _closeLink(4000, 'silent', ConnectionProblem.silent);
    });
  }

  void _closeLink(int code, String reason, ConnectionProblem? problem) {
    final link = _link;
    if (link == null) return;
    _ourClose = (problem, reason);
    unawaited(link.close(code, reason));
    // the channel does not report a close it started itself: handle it here
    // (a late onDone belongs to an older generation and is ignored)
    _onClosed(_generation, link);
  }

  void _onClosed(int gen, WsLink link) {
    if (gen != _generation) return;
    _generation++; // late callbacks of this socket (hello, resync) are void
    _helloTimer?.cancel();
    _silenceTimer?.cancel();
    _pingTimer?.cancel();
    _pingTimer = null;
    unawaited(_linkSub?.cancel());
    _linkSub = null;
    _link = null;
    _holding = false;
    _pending.clear(); // not applied: they come again (replay or resync)
    _failRequests(const NoAnswer());
    if (_disposed) return;
    unawaited(_requeueSending());

    final ours = _ourClose;
    _ourClose = null;
    final code = link.closeCode;
    final reason = link.closeReason;
    final detail =
        '${code ?? '-'}${reason == null || reason.isEmpty ? '' : ' $reason'}';

    if (ours != null && ours.$1 == null) {
      // paused (logged there) or disposed
      return;
    }
    if (!_foreground && ours == null && code != WsClose.unauthorized) {
      // Android cuts the network of a background app within seconds: a pause,
      // not a failure (the grace period cannot outlive it)
      _pauseTimer?.cancel();
      _pauseTimer = null;
      _retryTimer?.cancel();
      _log(LogKind.paused, 'closed in the background ($detail)');
      _setPhase(ConnectionPhase.offline, clearRetry: true);
      return;
    }
    if (code == WsClose.unauthorized) {
      _log(LogKind.authFailed, detail);
      _setPhase(
        ConnectionPhase.authFailed,
        problem: ConnectionProblem.closed,
        detail: detail,
      );
      onUnauthorized();
      return;
    }
    final problem = ours?.$1 ?? ConnectionProblem.closed;
    _log(LogKind.closed, ours == null ? detail : '${problem.name}: ${ours.$2}');
    // 4408 (slow consumer): resume right away, once
    _scheduleRetry(
      problem,
      ours == null ? detail : ours.$2,
      immediate: code == WsClose.timeoutOrSlow && _status.attempt == 0,
    );
  }

  /// Backoff before the next attempt; one log line per attempt.
  void _scheduleRetry(
    ConnectionProblem problem,
    String detail, {
    bool immediate = false,
    String? logAs,
  }) {
    _retryTimer?.cancel();
    if (!_foreground) {
      _setPhase(
        ConnectionPhase.offline,
        problem: problem,
        detail: detail,
        clearRetry: true,
      );
      return;
    }
    final attempt = _status.attempt + 1;
    final delay = immediate
        ? Duration.zero
        : backoffDelay(
            attempt,
            random: _random,
            min: timing.backoffMin,
            max: timing.backoffMax,
          );
    final at = _now().add(delay);
    _setStatus(
      ConnectionStatus(
        phase: ConnectionPhase.backoff,
        since: _now(),
        attempt: attempt,
        retryAt: at,
        problem: problem,
        detail: detail,
        hermes: _status.hermes,
      ),
    );
    final retry =
        'retry ${attempt > 1 ? '#$attempt ' : ''}in ${_seconds(delay)}';
    _log(
      logAs == null ? LogKind.backoff : LogKind.failed,
      logAs == null ? retry : '$logAs — $retry',
    );
    _retryTimer = Timer(delay, _connect);
  }

  // ---------------------------------------------------------------------------
  // frames

  void _onRaw(int gen, Object? raw) {
    if (gen != _generation) return;
    _armSilence(gen);
    final IncomingFrame frame;
    try {
      final decoded = jsonDecode(
        raw is String ? raw : utf8.decode(raw! as List<int>),
      );
      frame = IncomingFrame.parse(decoded as Map<String, Object?>);
    } on Object catch (e) {
      _log(LogKind.protocol, 'unreadable frame: $e');
      return;
    }
    switch (frame) {
      case HelloOkFrame(:final hello):
        if (_status.phase == ConnectionPhase.awaitingHello && !_holding) {
          _holding = true; // until _onHello knows where the stream resumes
          unawaited(_onHello(gen, hello));
        }
      case AckFrame(:final id, :final data):
        _answer(id, data);
      case ErrorReply(:final id, :final code, :final message):
        if (id == null) {
          _log(LogKind.serverError, message == null ? code : '$code: $message');
        } else {
          _reject(id, RequestRejected(code, message));
        }
      case PongFrame(:final id):
        _answer(id, const {});
      case KeepaliveFrame():
        break;
      case UnknownFrame(:final type):
        _log(LogKind.protocol, 'unknown frame $type');
      case final ServerEvent event:
        _pending.add(event);
        if (!_holding) _scheduleFlush();
    }
  }

  Future<void> _onHello(int gen, HelloOk hello) async {
    _helloTimer?.cancel();
    final stored = await db.readSyncState();
    if (gen != _generation) return;
    final needResync =
        hello.resyncRequired ||
        stored.lastSeq == null ||
        stored.epoch != hello.epoch;
    _epoch = hello.epoch;
    _setStatus(
      ConnectionStatus(
        phase: ConnectionPhase.live,
        since: _now(),
        hermes: hello.hermes,
        resyncing: needResync,
      ),
    );
    _startPing(gen);
    _log(
      LogKind.connected,
      'seq ${hello.seq}, epoch ${_short(hello.epoch)}'
      '${needResync ? ', reload' : ', resume from ${stored.lastSeq}'}',
    );
    if (needResync) {
      live.clear();
      _publishLive();
      final started = _now();
      try {
        final report = await resync(
          api: api,
          db: db,
          epoch: hello.epoch,
          seq: hello.seq,
          focus: _focus,
        );
        if (gen != _generation) return;
        _appliedSeq = hello.seq;
        _log(
          LogKind.resync,
          '$report in ${_now().difference(started).inMilliseconds} ms',
        );
      } on Object catch (e) {
        if (gen != _generation) return;
        _log(LogKind.failed, 'reload: $e');
        if (e is ApiUnauthorized) return; // the session handles it
        _closeLink(4000, 'reload failed', ConnectionProblem.resyncFailed);
        return;
      }
      _setStatus(_status.copyWith(resyncing: false));
    } else {
      _appliedSeq = stored.lastSeq!;
    }
    _holding = false;
    _scheduleFlush(now: true);
    unawaited(_flushOutbox());
  }

  void _scheduleFlush({bool now = false}) {
    if (now) {
      _flushTimer?.cancel();
      _flushTimer = null;
      _flush();
      return;
    }
    _flushTimer ??= Timer(timing.batchWindow, () {
      _flushTimer = null;
      _flush();
    });
  }

  void _flush() {
    final epoch = _epoch;
    if (_pending.isEmpty || epoch == null) return;
    final batch = [
      for (final e in _pending)
        if (e.seq > _appliedSeq) e,
    ];
    _pending.clear();
    if (batch.isEmpty) return;
    _appliedSeq = batch.last.seq;
    final gen = _generation;
    _applying = _applying.then((_) async {
      try {
        final outcome = await _reducer.apply(batch, epoch: epoch);
        _publishLive();
        final health = outcome.health;
        if (health != null && health.hermes != _status.hermes) {
          _log(
            LogKind.hermes,
            '${health.hermes ?? 'unknown'} ${health.hermesVersion ?? ''}'
                .trim(),
          );
          if (!_disposed) {
            _setStatus(_status.copyWith(hermes: health.hermes));
          }
        }
        if (outcome.system case final system? when !_disposed) {
          _systemController.add(system);
        }
        if (!_disposed) {
          for (final change in outcome.schedules) {
            _scheduleController.add(change);
          }
        }
        for (final err in outcome.errors) {
          _log(
            LogKind.serverError,
            err.message == null ? err.code : '${err.code}: ${err.message}',
          );
        }
        for (final u in outcome.unknown) {
          _log(LogKind.protocol, 'unknown event ${u.type}');
        }
      } on Object catch (e) {
        // not stored: reconnecting resumes from the last stored seq
        _log(LogKind.protocol, 'apply failed: $e');
        if (gen == _generation) {
          _closeLink(4000, 'apply failed', ConnectionProblem.closed);
        }
      }
    });
  }

  void _publishLive() {
    if (live.takeChanged() && !_disposed) {
      onLiveRuns?.call(live.snapshot());
    }
  }

  /// Waits until every received event is in the database (tests, resync).
  Future<void> settle() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (!_holding) _flush();
    await _applying;
  }

  // ---------------------------------------------------------------------------
  // requests

  Future<Map<String, Object?>> _request(
    Map<String, Object?> Function(String id) frame,
  ) {
    final link = _link;
    if (link == null || _status.phase != ConnectionPhase.live) {
      return Future.error(const NotConnected());
    }
    final id = 'r${++_requestCounter}';
    final completer = Completer<Map<String, Object?>>();
    _requests[id] = completer;
    link.send(jsonEncode(frame(id)));
    return completer.future.timeout(
      timing.ackTimeout,
      onTimeout: () {
        _requests.remove(id);
        throw const NoAnswer();
      },
    );
  }

  void _answer(String? id, Map<String, Object?> data) {
    final c = id == null ? null : _requests.remove(id);
    if (c != null && !c.isCompleted) c.complete(data);
  }

  void _reject(String id, SyncError error) {
    final c = _requests.remove(id);
    if (c != null && !c.isCompleted) c.completeError(error);
  }

  void _failRequests(SyncError error) {
    final pending = Map.of(_requests);
    _requests.clear();
    for (final c in pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
  }

  /// Stops a queued or running run ([runId] may be the queue id). Returns the
  /// status the server reports (`cancelled`, `stopping`, …).
  Future<String> stopRun(String runId) async {
    final ack = await _request(
      (id) => ClientFrames.runStop(id: id, runId: runId),
    );
    return ack['status']! as String;
  }

  /// Thinking on/off or archive; the change comes back as an event too.
  Future<void> setConversation(
    String conversationId, {
    bool? thinking,
    bool? archived,
  }) async {
    final ack = await _request(
      (id) => ClientFrames.conversationSet(
        id: id,
        conversationId: conversationId,
        thinking: thinking,
        archived: archived,
      ),
    );
    final conv = ack['conversation'];
    if (conv is Map<String, Object?>) {
      await db.putConversation(Conversation.fromJson(conv));
    }
  }

  /// Answers an approval over the socket. Never queued (decision 170): when
  /// not live this throws [NotConnected] and the button stays disabled.
  Future<Approval> respondApproval(
    String requestId,
    ApprovalChoice choice,
  ) async {
    final ack = await _request(
      (id) => ClientFrames.approvalRespond(
        id: id,
        requestId: requestId,
        choice: choice,
      ),
    );
    final approval = Approval.fromJson(
      ack['approval']! as Map<String, Object?>,
    );
    await db.putApproval(approval);
    return approval;
  }

  /// Messages of [conversationId] after [afterMessageId] (max 200 a call).
  /// Returns whether more are waiting.
  Future<bool> syncConversation(
    String conversationId, {
    int? afterMessageId,
  }) async {
    final ack = await _request(
      (id) => ClientFrames.sync(
        id: id,
        conversationId: conversationId,
        afterMessageId: afterMessageId,
      ),
    );
    final conv = Conversation.fromJson(
      ack['conversation']! as Map<String, Object?>,
    );
    final messages = [
      for (final m in ack['messages']! as List<Object?>)
        HistoryMessage.fromJson(m! as Map<String, Object?>),
    ];
    await db.transaction(() async {
      await db.putConversation(conv);
      for (final m in messages) {
        await db.putHistoryMessage(m);
      }
    });
    return ack['has_more'] == true;
  }

  // ---------------------------------------------------------------------------
  // outbox (decision 170)

  /// Queues a message and sends it as soon as the socket is live. Returns the
  /// `client_msg_id`; the message itself arrives as `message.created`.
  /// [attachments] are already uploaded (the server keeps an unsent upload
  /// for an hour, so a short wait in the outbox is fine).
  Future<String> sendMessage(
    String text, {
    String? conversationId,
    bool? thinking,
    List<Attachment> attachments = const [],
  }) async {
    final clientMsgId = const Uuid().v4();
    await db
        .into(db.outbox)
        .insert(
          OutboxCompanion.insert(
            clientMsgId: clientMsgId,
            conversationId: Value(conversationId),
            body: text,
            thinking: Value(thinking),
            createdAt: _now().toUtc(),
            attachments: Value(attachments),
          ),
        );
    unawaited(_flushOutbox());
    return clientMsgId;
  }

  /// A failed message, back in the queue.
  Future<void> retryMessage(String clientMsgId) async {
    await (db.update(
      db.outbox,
    )..where((t) => t.clientMsgId.equals(clientMsgId))).write(
      const OutboxCompanion(state: Value('pending'), lastError: Value(null)),
    );
    unawaited(_flushOutbox());
  }

  Future<void> discardMessage(String clientMsgId) =>
      db.forgetOutbox(clientMsgId);

  /// The server has the message. Its `message.created` may still wait in
  /// the event batch (it travels apart from the ack): until it is written,
  /// the outbox row stays as `sent`, which the chat shows like a sent message.
  /// The reducer drops the row in the transaction that writes the message.
  Future<void> _acknowledged(String clientMsgId) async {
    final arrived = await db.transaction(() async {
      final message =
          await (db.select(db.messages)
                ..where((t) => t.clientMsgId.equals(clientMsgId))
                ..limit(1))
              .getSingleOrNull();
      if (message != null) {
        await db.forgetOutbox(clientMsgId);
        return true;
      }
      await (db.update(db.outbox)
            ..where((t) => t.clientMsgId.equals(clientMsgId)))
          .write(const OutboxCompanion(state: Value('sent')));
      return false;
    });
    if (arrived || _disposed) return;
    late final Timer timer;
    timer = Timer(timing.sentSettle, () {
      _settleTimers.remove(timer);
      if (_disposed) return;
      unawaited(
        (db.delete(db.outbox)
              ..where((t) => t.clientMsgId.equals(clientMsgId))
              ..where((t) => t.state.equals('sent')))
            .go(),
      );
    });
    _settleTimers.add(timer);
  }

  Future<void> _requeueSending() =>
      (db.update(db.outbox)..where((t) => t.state.equals('sending'))).write(
        const OutboxCompanion(state: Value('pending')),
      );

  Future<void> _flushOutbox() async {
    if (_outboxRunning || _disposed) return;
    _outboxRunning = true;
    var sent = 0;
    try {
      while (_status.phase == ConnectionPhase.live && !_disposed) {
        final rows = await db.pendingOutbox();
        if (rows.isEmpty) break;
        final row = rows.first;
        await (db.update(
          db.outbox,
        )..where((t) => t.clientMsgId.equals(row.clientMsgId))).write(
          OutboxCompanion(
            state: const Value('sending'),
            attempts: Value(row.attempts + 1),
          ),
        );
        try {
          await _request(
            (id) => ClientFrames.chatSend(
              id: id,
              text: row.body,
              clientMsgId: row.clientMsgId,
              conversationId: row.conversationId,
              thinking: row.thinking,
              attachmentIds: [for (final a in row.attachments) a.id],
            ),
          );
          await _acknowledged(row.clientMsgId);
          sent++;
        } on RequestRejected catch (e) {
          await (db.update(
            db.outbox,
          )..where((t) => t.clientMsgId.equals(row.clientMsgId))).write(
            OutboxCompanion(
              state: const Value('failed'),
              lastError: Value(e.code),
            ),
          );
          _log(LogKind.outbox, 'rejected: ${e.code}');
        } on SyncError {
          // the connection ended: stays pending, resent after the next hello
          await (db.update(db.outbox)
                ..where((t) => t.clientMsgId.equals(row.clientMsgId)))
              .write(const OutboxCompanion(state: Value('pending')));
          break;
        }
      }
    } finally {
      _outboxRunning = false;
    }
    if (sent > 1) _log(LogKind.outbox, 'sent $sent queued messages');
  }

  // ---------------------------------------------------------------------------
  // status and log

  void _setPhase(
    ConnectionPhase phase, {
    ConnectionProblem? problem,
    String? detail,
    bool clearRetry = false,
  }) {
    _setStatus(
      _status.copyWith(
        phase: phase,
        since: _now(),
        problem: problem,
        detail: detail,
        clearRetry: clearRetry,
      ),
    );
  }

  void _setStatus(ConnectionStatus s) {
    if (_disposed) return;
    _status = s;
    _statusController.add(s);
  }

  void _log(LogKind kind, String? detail) {
    unawaited(
      db
          .addLogEntry(kind.name, detail, at: _now())
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  static String _short(String s) => s.length > 8 ? s.substring(0, 8) : s;

  static String _seconds(Duration d) => d.inMilliseconds < 1000
      ? '${d.inMilliseconds} ms'
      : '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';
}
