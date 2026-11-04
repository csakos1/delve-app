import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import 'phone_key.dart';
import 'secrets.dart';
import 'ssh_link.dart';
import 'sticky_keys.dart';
import 'terminal_wheel.dart';
import 'tmux_terminal.dart';

/// Where the terminal connection is (design 22c).
enum TermPhase {
  /// Not started.
  idle,

  /// The first try (from setup, or when the tab opens).
  connecting,

  /// A host key nobody trusted yet: waiting for the user (22e1).
  verifying,

  live,

  /// Dropped (or not reachable) after setup: trying again with backoff.
  reconnecting,

  /// Not trying: the user disconnected, the tmux session ended, or the app
  /// is in the background. A tap reconnects.
  offline,

  /// sshd refused the phone's key (22e2).
  denied,

  /// The host key differs from the pinned one: no retry (22c2).
  refused,

  /// The first try during setup could not reach the desktop.
  failed,
}

/// Why the connection is [TermPhase.offline].
enum OfflineReason { user, sessionEnded, background }

/// A host key waiting for the user's yes or no.
class HostKeyQuestion {
  const HostKeyQuestion(this.type, this.fingerprint);

  final String type;
  final String fingerprint;
}

/// Timings of the terminal connection (tests shorten them).
class TerminalTiming {
  const TerminalTiming({
    this.backoff = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
      Duration(seconds: 30),
    ],
    this.resizeSettle = const Duration(milliseconds: 100),
    this.staleAfter = const Duration(seconds: 8),
    this.probeEvery = const Duration(seconds: 5),
    this.probeTimeout = const Duration(seconds: 3),
    this.echoWait = const Duration(seconds: 1),
  });

  /// Waits before reconnect attempt 1, 2, …; the last one repeats.
  final List<Duration> backoff;

  /// The first new size goes to the pty at once; more changes within this
  /// window are sent as one at its end. The screen also waits this long for
  /// a keyboard height it has not seen before.
  final Duration resizeSettle;

  /// After this long in the background the connection is considered dead:
  /// Android cuts a background app's network within ~10 s (#18, 216.), and
  /// the keep-alive would notice it only later.
  final Duration staleAfter;

  /// A quiet live connection is probed this often ([SshLink.probe]).
  final Duration probeEvery;

  /// No answer within this long: the connection is dead (T2a: airplane mode
  /// left it "live" for minutes, and the keystrokes arrived afterwards).
  final Duration probeTimeout;

  /// Typed, and nothing came back for this long (tmux echoes every key):
  /// probe at once, and hold further keystrokes until the answer.
  final Duration echoWait;

  Duration delay(int attempt) =>
      backoff[(attempt - 1).clamp(0, backoff.length - 1)];
}

/// One terminal: an xterm [Terminal] that outlives connections, and the SSH
/// connection to one tmux session with automatic reconnects. While not live
/// the last screen stays and keystrokes are dropped (design 22c).
///
/// A live connection is checked: a quiet one every [TerminalTiming.probeEvery],
/// and at once after a network change, after coming back to the foreground,
/// and when typed keys get no echo. Keystrokes typed while a check is open
/// are held, sent when the answer comes and dropped when it does not.
class TerminalConnection extends ChangeNotifier {
  TerminalConnection({
    required this.dialer,
    required this.secrets,
    this.timing = const TerminalTiming(),
    this.onLive,
    this.onInput,
    DateTime Function()? now,
    int maxLines = 10000,
  }) : keys = StickyModifiers(),
       _now = now ?? DateTime.now {
    terminal = TmuxTerminal(maxLines: maxLines, inputHandler: keys)
      ..onOutput = _input
      ..onResize = _resized;
    selection.addListener(_selectionSet);
  }

  final SshDialer dialer;
  final TerminalSecrets secrets;
  final TerminalTiming timing;

  /// Called after each successful connect (setup is done).
  final void Function()? onLive;

  /// Called on every keystroke the user sends (the lock's activity clock).
  final void Function()? onInput;

  final DateTime Function() _now;
  final StickyModifiers keys;
  late final TmuxTerminal terminal;

  /// The selection on the screen (T2b): the view and the selection layer
  /// paint it, the gesture layer sets it. A key the user sends to the
  /// desktop ends it; scrolling does not.
  ///
  /// It is kept by its lines (the first and the last, which tmux's view
  /// keeps when they scroll out): partly scrolled out, the rest still shows,
  /// cut at the pane's edge; scrolled out entirely it waits, and shows again
  /// when its lines come back (T2b phone test: it vanished for good once its
  /// last line went under the bottom).
  final selection = TerminalController();

  BufferLine? _selFirst;
  int _selFirstX = 0;
  BufferLine? _selLast;
  int _selEndX = 0; // exclusive
  bool _syncing = false;
  bool _startHidden = false;
  bool _endHidden = false;

  /// Something is selected (perhaps scrolled out, not drawn now).
  bool get hasSelection => _selFirst != null || selection.selection != null;

  /// The selection's first / last line is scrolled out: its handle is not
  /// drawn.
  bool get selectionStartHidden => _startHidden;
  bool get selectionEndHidden => _endHidden;

  /// Ends the selection (a tap, Copy, Send to chat).
  void clearSelection() {
    _forget();
    if (selection.selection != null) selection.clearSelection();
  }

  void _forget() {
    _selFirst = null;
    _selLast = null;
    _startHidden = false;
    _endHidden = false;
  }

  /// The gestures set (or cleared) the selection on screen: kept by lines.
  void _selectionSet() {
    if (_syncing) return;
    final range = selection.selection?.normalized;
    if (range == null) {
      _forget();
      return;
    }
    final lines = terminal.buffer.lines;
    _selFirst = lines[range.begin.y];
    _selFirstX = range.begin.x;
    _selLast = lines[range.end.y];
    _selEndX = range.end.x;
    _startHidden = false;
    _endHidden = false;
  }

  /// After tmux moved the lines: the selection on screen follows its lines,
  /// cut at the pane's edges.
  void _syncSelection() {
    final first = _selFirst;
    final last = _selLast;
    final t = terminal;
    if (_disposed || first == null || last == null || !t.isUsingAltBuffer) {
      return;
    }
    final doc = t.documentLines();
    final a = doc.indexWhere((l) => identical(l, first));
    final b = doc.indexWhere((l) => identical(l, last));
    if (a < 0 || b < 0) {
      clearSelection(); // its lines are gone (cleared, or kept no longer)
      return;
    }
    final top = t.historyLength;
    final bottom = top + t.paneRows - 1;
    _startHidden = a < top;
    _endHidden = b > bottom;
    final buffer = t.buffer;
    final want = (b < top || a > bottom)
        ? null
        : (
            _startHidden
                ? const CellOffset(0, 0)
                : CellOffset(_selFirstX, a - top),
            _endHidden
                ? CellOffset(t.viewWidth, t.paneRows - 1)
                : CellOffset(_selEndX, b - top),
          );
    final now = selection.selection?.normalized;
    final from = want == null
        ? null
        : CellOffset(want.$1.x, want.$1.y + buffer.scrollBack);
    final to = want == null
        ? null
        : CellOffset(want.$2.x, want.$2.y + buffer.scrollBack);
    if (now == null && from == null) return;
    if (now != null &&
        from != null &&
        to != null &&
        now.begin.x == from.x &&
        now.begin.y == from.y &&
        now.end.x == to.x &&
        now.end.y == to.y) {
      return;
    }
    _syncing = true;
    try {
      if (from == null || to == null) {
        selection.clearSelection();
      } else {
        selection.setSelection(
          buffer.createAnchorFromOffset(from),
          buffer.createAnchorFromOffset(to),
          mode: SelectionMode.line,
        );
      }
    } finally {
      _syncing = false;
    }
  }

  /// The selected text (null: nothing selected), scrolled-out parts
  /// included, without the blanks tmux pads each line with.
  String? selectedText() {
    final first = _selFirst;
    final last = _selLast;
    String text;
    final doc = terminal.isUsingAltBuffer ? terminal.documentLines() : null;
    final a = doc?.indexWhere((l) => identical(l, first)) ?? -1;
    final b = doc?.indexWhere((l) => identical(l, last)) ?? -1;
    if (doc != null && first != null && a >= 0 && b >= a) {
      text = [
        for (var i = a; i <= b; i++)
          doc[i]
              .getText(i == a ? _selFirstX : 0, i == b ? _selEndX : null)
              .trimRight(),
      ].join('\n');
    } else {
      final range = selection.selection;
      if (range == null) return null;
      text = terminal.buffer
          .getText(range)
          .split('\n')
          .map((line) => line.trimRight())
          .join('\n');
    }
    return text.trim().isEmpty ? null : text;
  }

  TermPhase _phase = TermPhase.idle;
  TermPhase get phase => _phase;

  /// Reconnect attempt (1 = first retry); 0 when not retrying.
  int attempt = 0;

  /// When the next reconnect attempt starts.
  DateTime? retryAt;

  OfflineReason? offlineReason;

  /// The last failure's text (failed, denied, reconnecting).
  String? detail;

  /// A new host key to confirm ([TermPhase.verifying]).
  HostKeyQuestion? question;

  /// The key the desktop showed when it differed from [refusedPinned].
  HostKeyQuestion? refusedKey;
  PinnedHostKey? refusedPinned;

  SshTarget? _target;
  PhoneKey? _key;
  SshLink? _link;
  StreamSubscription<String>? _out;
  Completer<bool>? _answer;
  Timer? _retry;
  Timer? _resize;
  (int, int)? _pendingSize;
  Timer? _probeTick;
  Timer? _echo;
  DateTime _rxAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _typedAt;
  bool _probing = false;
  bool _holding = false;
  final List<String> _held = [];
  int _gen = 0;
  bool _foreground = true;
  bool _wasLive = false;
  DateTime? _backgroundSince;
  bool _disposed = false;

  SshTarget? get target => _target;
  bool get live => _phase == TermPhase.live;

  /// Connects to [target] with [key] from scratch (setup, settings change,
  /// "Try again").
  void connect(SshTarget target, PhoneKey key, {bool afterSetup = false}) {
    _target = target;
    _key = key;
    _wasLive = _wasLive || afterSetup;
    attempt = 0;
    unawaited(_open());
  }

  /// Tries again now (the Disconnected line, the Retry button).
  void retryNow() {
    if (_target == null || _key == null) return;
    if (_phase == TermPhase.live || _phase == TermPhase.verifying) return;
    attempt = 0;
    unawaited(_open());
  }

  /// The user's answer to [question].
  void answerHostKey({required bool trust}) {
    final a = _answer;
    _answer = null;
    if (a != null && !a.isCompleted) a.complete(trust);
  }

  /// Forget the pinned key of the current target and verify it again.
  Future<void> forgetAndVerify() async {
    final t = _target;
    if (t == null) return;
    await secrets.forget(t.hostPort);
    refusedKey = null;
    refusedPinned = null;
    attempt = 0;
    // not awaited: it waits for the user's answer to the new key
    unawaited(_open());
  }

  /// Closes the connection; tmux keeps running.
  Future<void> disconnect({OfflineReason reason = OfflineReason.user}) async {
    _gen++;
    _retry?.cancel();
    answerHostKey(trust: false);
    _drop();
    offlineReason = reason;
    _set(TermPhase.offline);
  }

  /// The app went to the background or came back.
  void setForeground({required bool foreground}) {
    if (foreground == _foreground) return;
    _foreground = foreground;
    final now = _now();
    if (!foreground) {
      _backgroundSince = now;
      if (_phase == TermPhase.reconnecting) {
        _retry?.cancel();
        offlineReason = OfflineReason.background;
        _set(TermPhase.offline);
      }
      return;
    }
    final since = _backgroundSince;
    _backgroundSince = null;
    final stale = since != null && now.difference(since) >= timing.staleAfter;
    switch (_phase) {
      case TermPhase.live when stale:
        // the socket is most likely dead already: a fresh one, same session
        _gen++;
        _drop(abort: true);
        _reconnect(immediately: true);
      case TermPhase.live:
        // short enough to keep, but the network may have changed meanwhile
        unawaited(_probe(hold: true));
      case TermPhase.offline when offlineReason == OfflineReason.background:
        _reconnect(immediately: true);
      default:
        break;
    }
  }

  /// The phone's network changed (Wi-Fi, mobile data, airplane mode, VPN):
  /// a live connection is checked now, a waiting reconnect tries now.
  void networkChanged() {
    if (_disposed || !_foreground) return;
    switch (_phase) {
      case TermPhase.live:
        unawaited(_probe(hold: true));
      case TermPhase.reconnecting:
        _retry?.cancel();
        attempt = 0;
        unawaited(_open());
      default:
        break;
    }
  }

  /// One mouse-wheel step at a cell (touch scrolling): false when the
  /// program did not ask for the mouse (nothing sent).
  bool wheel({required bool up, required int column, required int row}) {
    final report = wheelReport(terminal, up: up, column: column, row: row);
    if (report == null) return false;
    _input(report, keepSelection: true);
    return true;
  }

  /// Whether keystrokes are being held for an open check.
  @visibleForTesting
  bool get holding => _holding;

  /// Asks the desktop for an answer; none → the connection is dropped at
  /// once (with what was still queued) and a fresh one is opened. [hold]:
  /// the link is suspect, keystrokes wait for the answer.
  Future<void> _probe({bool hold = false}) async {
    final link = _link;
    if (link == null || _phase != TermPhase.live) return;
    if (hold) _holding = true;
    if (_probing) return;
    final gen = _gen;
    _probing = true;
    final ok = await link.probe(timing.probeTimeout);
    _probing = false;
    if (gen != _gen || _disposed) return;
    if (ok) {
      _rxAt = _now();
      _release();
    } else {
      _lost('no answer from the desktop');
    }
  }

  /// The check answered: the held keystrokes go out in order.
  void _release() {
    _holding = false;
    final link = _link;
    if (link == null || _held.isEmpty) return;
    final data = _held.join();
    _held.clear();
    link.write(Uint8List.fromList(utf8.encode(data)));
    _watchEcho();
  }

  void _lost(String why) {
    _gen++;
    _drop(abort: true);
    detail = why;
    _reconnect(immediately: true);
  }

  /// After a keystroke: if nothing at all comes back within
  /// [TerminalTiming.echoWait], hold the next ones and check.
  void _watchEcho() {
    _typedAt ??= _now();
    if (_echo != null) return;
    final gen = _gen;
    _echo = Timer(timing.echoWait, () {
      _echo = null;
      final typed = _typedAt;
      _typedAt = null;
      if (gen != _gen || typed == null || !_rxAt.isBefore(typed)) return;
      unawaited(_probe(hold: true));
    });
  }

  void _received(String data) {
    _rxAt = _now();
    _typedAt = null;
    _echo?.cancel();
    _echo = null;
    terminal.write(data);
    _syncSelection();
  }

  void _tick() {
    if (!_foreground || _phase != TermPhase.live) return;
    if (_now().difference(_rxAt) >= timing.probeEvery) unawaited(_probe());
  }

  Future<void> _open() async {
    final target = _target;
    final key = _key;
    if (target == null || key == null || _disposed) return;
    final gen = ++_gen;
    _retry?.cancel();
    answerHostKey(trust: false);
    _drop();
    if (gen != _gen) return;
    detail = null;
    question = null;
    refusedKey = null;
    refusedPinned = null;
    _set(attempt > 0 ? TermPhase.reconnecting : TermPhase.connecting);

    Future<bool> verify(String type, String fingerprint) async {
      final pinned = await secrets.pinned(target.hostPort);
      if (pinned != null) {
        if (pinned.matches(type, fingerprint)) return true;
        refusedKey = HostKeyQuestion(type, fingerprint);
        refusedPinned = pinned;
        return false;
      }
      if (gen != _gen) return false;
      final answer = _answer = Completer<bool>();
      question = HostKeyQuestion(type, fingerprint);
      _set(TermPhase.verifying);
      final ok = await answer.future;
      if (ok && gen == _gen) {
        await secrets.pin(
          target.hostPort,
          PinnedHostKey(
            type: type,
            fingerprint: fingerprint,
            trustedAt: _now(),
          ),
        );
      }
      return ok && gen == _gen;
    }

    try {
      final link = await dialer.open(
        target,
        key: key,
        verify: verify,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
      );
      if (gen != _gen) {
        unawaited(link.close());
        return;
      }
      _attach(link, gen);
    } on SshHostKeyRejected catch (e) {
      if (gen != _gen) return;
      question = null;
      if (refusedKey != null) {
        _set(TermPhase.refused);
      } else {
        // the user did not trust a new key: back to setup
        detail = e.detail;
        _set(TermPhase.idle);
      }
    } on SshAuthDenied catch (e) {
      if (gen != _gen) return;
      detail = e.detail;
      _set(TermPhase.denied);
    } on Object catch (e) {
      if (gen != _gen) return;
      detail = e is SshFailure ? e.detail : '$e';
      if (_wasLive) {
        _reconnect();
      } else {
        _set(TermPhase.failed);
      }
    }
  }

  void _attach(SshLink link, int gen) {
    _link = link;
    _wasLive = true;
    attempt = 0;
    retryAt = null;
    offlineReason = null;
    refusedKey = null;
    refusedPinned = null;
    _rxAt = _now();
    _out = const Utf8Decoder(
      allowMalformed: true,
    ).bind(link.output).listen(_received);
    _probeTick = Timer.periodic(timing.probeEvery, (_) => _tick());
    // a size that changed while we were away
    final size = _pendingSize;
    if (size != null) link.resize(size.$1, size.$2);
    _pendingSize = null;
    unawaited(link.done.then((end) => _ended(end, gen)));
    _set(TermPhase.live);
    onLive?.call();
  }

  void _ended(SshEnd end, int gen) {
    if (gen != _gen) return;
    _gen++;
    _drop();
    if (end == SshEnd.sessionEnded) {
      offlineReason = OfflineReason.sessionEnded;
      _set(TermPhase.offline);
    } else {
      _reconnect(immediately: true);
    }
  }

  /// The next attempt after a backoff (or right away the first time after a
  /// drop); in the background it waits for the app to come back.
  void _reconnect({bool immediately = false}) {
    if (_disposed) return;
    if (!_foreground) {
      offlineReason = OfflineReason.background;
      _set(TermPhase.offline);
      return;
    }
    attempt++;
    final wait = immediately && attempt == 1
        ? Duration.zero
        : timing.delay(attempt);
    retryAt = _now().add(wait);
    _set(TermPhase.reconnecting);
    _retry?.cancel();
    _retry = Timer(wait, () => unawaited(_open()));
  }

  /// Lets go of the current link at once; closing it goes on in the
  /// background (state changes must not wait for a slow socket). [abort]:
  /// a dead link, dropped with whatever it still had queued.
  void _drop({bool abort = false}) {
    final link = _link;
    _link = null;
    unawaited(_out?.cancel());
    _out = null;
    _probeTick?.cancel();
    _probeTick = null;
    _echo?.cancel();
    _echo = null;
    _typedAt = null;
    _probing = false;
    _holding = false;
    _held.clear();
    if (link == null) return;
    if (abort) {
      link.abort();
    } else {
      unawaited(link.close());
    }
  }

  void _input(String data, {bool keepSelection = false}) {
    final reply = isTerminalReply(data);
    if (!reply && !keepSelection && hasSelection) clearSelection();
    final link = _link;
    if (link == null || _phase != TermPhase.live) return; // not queued
    if (!reply &&
        !keepSelection &&
        !isMouseReport(data) &&
        terminal.inCopyMode) {
      // a keystroke after a scroll is for the shell, not a copy-mode
      // command (T2b phone test: typing opened tmux's "goto line"); `q`
      // leaves copy mode in both of tmux's key tables
      data = 'q$data';
      terminal.leftCopyMode();
    }
    if (!reply) onInput?.call();
    if (_holding) {
      // a check is open: sent after its answer, dropped without one
      _held.add(data);
      return;
    }
    link.write(Uint8List.fromList(utf8.encode(data)));
    _watchEcho();
  }

  /// xterm resizes on every layout. The first new size goes to the pty at
  /// once (tmux redraws within a round trip); further changes within
  /// [TerminalTiming.resizeSettle] are sent once, at the end of the window.
  void _resized(int columns, int rows, int pixelWidth, int pixelHeight) {
    // from layout, where the view may not be told to lay out again; and the
    // tmux view adopts its lines after this call
    if (_selFirst != null) scheduleMicrotask(_syncSelection);
    _pendingSize = (columns, rows);
    if (_resize != null) return;
    _sendSize();
    _resize = Timer(timing.resizeSettle, _resizeWindowEnd);
  }

  void _resizeWindowEnd() {
    _resize = null;
    if (_pendingSize == null || _link == null) return;
    _sendSize();
    _resize = Timer(timing.resizeSettle, _resizeWindowEnd);
  }

  void _sendSize() {
    final size = _pendingSize;
    final link = _link;
    if (size == null || link == null) return; // sent on the next connect
    _pendingSize = null;
    link.resize(size.$1, size.$2);
  }

  static final _reply = RegExp(
    // DA1/DA2/DA3, cursor position, status, focus; OSC and DCS answers
    r'^(\x1b\[[?>=]?[0-9;]*[cRnIO]|\x1b\][^\x07\x1b]*(\x07|\x1b\\)|\x1bP[^\x1b]*\x1b\\)+$',
  );

  static final _mouse = RegExp(r'^(\x1b\[<\d+;\d+;\d+[mM]|\x1b\[M[\s\S]{3})+$');

  /// A mouse report (a tap, a wheel step): tmux's copy mode takes it as
  /// it is.
  @visibleForTesting
  static bool isMouseReport(String data) => _mouse.hasMatch(data);

  /// What xterm sends by itself when tmux asks (not a keystroke): it must
  /// not count as the user's activity for the lock.
  @visibleForTesting
  static bool isTerminalReply(String data) => _reply.hasMatch(data);

  void _set(TermPhase p) {
    if (_disposed) return;
    _phase = p;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _gen++;
    _retry?.cancel();
    _resize?.cancel();
    answerHostKey(trust: false);
    _drop();
    keys.dispose();
    selection
      ..removeListener(_selectionSet)
      ..dispose();
    super.dispose();
  }
}
