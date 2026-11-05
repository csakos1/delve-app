import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A short, timed trace of what the terminal connections do: the app going
/// away and coming back, network changes, each connect attempt and its
/// steps, probes and drops (T4: why a reconnect after a long background is
/// slow). Kept in memory (the last [max] lines); the terminal menu's "Copy
/// connection trace" puts it on the clipboard, and every line also goes to
/// the log (`adb logcat -s flutter`). It holds no keystrokes, output or
/// keys.
class TerminalTrace {
  TerminalTrace({this.max = 400, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final int max;
  final DateTime Function() _now;
  final _lines = ListQueue<String>();
  DateTime? _last;

  /// One line: the wall clock to the millisecond, the time since the line
  /// before, who ([tag]: a session name, `app`, `net`), and [message].
  void add(String tag, String message) {
    final now = _now();
    final last = _last;
    _last = now;
    final gap = last == null ? '' : '+${now.difference(last).inMilliseconds}';
    final line = '${clock(now)} ${gap.padLeft(7)} [$tag] $message';
    _lines.addLast(line);
    while (_lines.length > max) {
      _lines.removeFirst();
    }
    debugPrint('delve.term $line');
  }

  List<String> get lines => List.unmodifiable(_lines);

  String get text => _lines.join('\n');

  void clear() {
    _lines.clear();
    _last = null;
  }

  /// `HH:mm:ss.SSS` in local time.
  static String clock(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}.'
        '${l.millisecond.toString().padLeft(3, '0')}';
  }
}

/// The app's one trace (all tabs, the dialer and the screen write here).
final terminalTrace = TerminalTrace();
