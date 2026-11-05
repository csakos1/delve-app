import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Tab inserts this many spaces (23n: `files.editor.limits.tabSpaces`).
const kEditTabSpaces = 4;

/// The changed-line count stops being exact above this many cells in the
/// middle part's table (lines × lines): the middle is then all "changed".
const kDiffMaxCells = 1000000;

/// Where each line of [text] starts (the first is 0).
List<int> lineStarts(String text) {
  final out = <int>[0];
  for (var i = text.indexOf('\n'); i >= 0; i = text.indexOf('\n', i + 1)) {
    out.add(i + 1);
  }
  return out;
}

/// The line (0-based) [offset] is on, by binary search in [starts].
int lineAt(List<int> starts, int offset) {
  var lo = 0;
  var hi = starts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (starts[mid] <= offset) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo;
}

/// Line and column (both 0-based) of [offset] in [text].
(int, int) lineCol(String text, int offset) {
  final o = offset.clamp(0, text.length);
  final starts = lineStarts(text);
  final line = lineAt(starts, o);
  return (line, o - starts[line]);
}

/// The lines a reader counts: a newline at the very end starts no line
/// (`a\nb\n` has 2).
int countedLines(String text) {
  if (text.isEmpty) return 0;
  var n = 1;
  for (var i = text.indexOf('\n'); i >= 0; i = text.indexOf('\n', i + 1)) {
    if (i < text.length - 1) n++;
  }
  return n;
}

/// The longest line in characters (a wide character counts as two, a tab
/// as eight): the no-wrap editor's width.
int widestLine(String text) {
  var best = 0;
  var cur = 0;
  for (final r in text.runes) {
    if (r == 0x0A) {
      best = math.max(best, cur);
      cur = 0;
    } else if (r == 0x09) {
      cur += 8;
    } else {
      cur += _wide(r) ? 2 : 1;
    }
  }
  return math.max(best, cur);
}

bool _wide(int r) =>
    (r >= 0x1100 && r <= 0x115F) ||
    (r >= 0x2E80 && r <= 0xA4CF) ||
    (r >= 0xAC00 && r <= 0xD7A3) ||
    (r >= 0xF900 && r <= 0xFAFF) ||
    (r >= 0xFE30 && r <= 0xFE4F) ||
    (r >= 0xFF00 && r <= 0xFF60) ||
    (r >= 0xFFE0 && r <= 0xFFE6) ||
    (r >= 0x1F300 && r <= 0x1FAFF) ||
    (r >= 0x20000 && r <= 0x3FFFD);

/// The edit against the opened text: which lines of the edited text are
/// new or changed (the gutter's bars) and how many lines differ (the
/// status row's "N lines changed").
class LineDiff {
  const LineDiff(this.changed, this.count);

  static const none = LineDiff(<int>{}, 0);

  /// Lines of the edited text (0-based) that are not in the opened one.
  final Set<int> changed;

  /// max(lines only in the opened text, lines only in the edited one).
  final int count;
}

/// [LineDiff] of [after] against [before]: the common start and end are
/// skipped, the middle is matched line by line (the longest common
/// subsequence); a middle too large for that is all changed.
LineDiff diffLines(String before, String after) {
  if (before == after) return LineDiff.none;
  final a = before.split('\n');
  final b = after.split('\n');
  var p = 0;
  while (p < a.length && p < b.length && a[p] == b[p]) {
    p++;
  }
  var s = 0;
  while (s < a.length - p &&
      s < b.length - p &&
      a[a.length - 1 - s] == b[b.length - 1 - s]) {
    s++;
  }
  final n = a.length - p - s;
  final m = b.length - p - s;
  if (n == 0) {
    return LineDiff({for (var j = 0; j < m; j++) p + j}, m);
  }
  if (m == 0) return LineDiff(const <int>{}, n);
  if (n * m > kDiffMaxCells) {
    return LineDiff({for (var j = 0; j < m; j++) p + j}, math.max(n, m));
  }
  // lengths of the common subsequence of the suffixes, one row at a time
  final table = List.generate(n + 1, (_) => Int32List(m + 1));
  for (var i = n - 1; i >= 0; i--) {
    final row = table[i];
    final next = table[i + 1];
    final ai = a[p + i];
    for (var j = m - 1; j >= 0; j--) {
      row[j] = ai == b[p + j] ? next[j + 1] + 1 : math.max(next[j], row[j + 1]);
    }
  }
  final changed = <int>{};
  var i = 0;
  var j = 0;
  var common = 0;
  while (i < n && j < m) {
    if (a[p + i] == b[p + j]) {
      i++;
      j++;
      common++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      changed.add(p + j);
      j++;
    }
  }
  for (; j < m; j++) {
    changed.add(p + j);
  }
  return LineDiff(changed, math.max(n - common, m - common));
}

// --------------------------------------------------------- the key row

/// Tab: [kEditTabSpaces] spaces in place of the selection.
TextEditingValue insertTab(TextEditingValue v) {
  const spaces = '    ';
  final sel = v.selection.isValid
      ? v.selection
      : TextSelection.collapsed(offset: v.text.length);
  final text = v.text.replaceRange(sel.start, sel.end, spaces);
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: sel.start + spaces.length),
  );
}

enum CaretMove { left, right, up, down, home, end }

/// The caret after a key of the row (a selection collapses: ← to its
/// start, → to its end, like a hardware keyboard). ↑ ↓ keep the column
/// (shorter lines clamp it); Home / End go to the line's start / end.
TextEditingValue moveCaret(TextEditingValue v, CaretMove move) {
  final text = v.text;
  final sel = v.selection.isValid
      ? v.selection
      : TextSelection.collapsed(offset: text.length);
  if (!sel.isCollapsed && (move == CaretMove.left || move == CaretMove.right)) {
    return v.copyWith(
      selection: TextSelection.collapsed(
        offset: move == CaretMove.left ? sel.start : sel.end,
      ),
      composing: TextRange.empty,
    );
  }
  final at = sel.extentOffset.clamp(0, text.length);
  final starts = lineStarts(text);
  final line = lineAt(starts, at);
  int endOf(int l) => l + 1 < starts.length ? starts[l + 1] - 1 : text.length;
  final col = at - starts[line];
  final to = switch (move) {
    CaretMove.left => math.max(0, at - _back(text, at)),
    CaretMove.right => math.min(text.length, at + _forward(text, at)),
    CaretMove.home => starts[line],
    CaretMove.end => endOf(line),
    CaretMove.up =>
      line == 0 ? 0 : math.min(starts[line - 1] + col, endOf(line - 1)),
    CaretMove.down =>
      line + 1 >= starts.length
          ? text.length
          : math.min(starts[line + 1] + col, endOf(line + 1)),
  };
  return v.copyWith(
    selection: TextSelection.collapsed(offset: to),
    composing: TextRange.empty,
  );
}

/// One character back: a surrogate pair is one.
int _back(String t, int at) =>
    at >= 2 && _low(t.codeUnitAt(at - 1)) && _high(t.codeUnitAt(at - 2))
    ? 2
    : 1;

int _forward(String t, int at) =>
    at + 1 < t.length && _high(t.codeUnitAt(at)) && _low(t.codeUnitAt(at + 1))
    ? 2
    : 1;

bool _high(int c) => c >= 0xD800 && c <= 0xDBFF;
bool _low(int c) => c >= 0xDC00 && c <= 0xDFFF;
