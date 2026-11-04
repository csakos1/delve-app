import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

/// An xterm [Terminal] whose alternate screen (where tmux draws) changes
/// height the way tmux will redraw it, so the redraw that follows one round
/// trip later lands on the same rows.
///
/// xterm keeps the cursor's line on screen: shrinking by k drops k − 1 lines
/// at the top and tmux's status line at the bottom; tmux then draws the
/// status line back and everything moves up by one – a one-line jump on
/// every keyboard opening (T2a phone test). tmux itself (screen_resize_y):
/// shrinking removes the lines below the cursor first, then lines at the
/// top; growing pulls lines back from history at the top.
///
/// Growing needs the lines tmux will pull back from its history; xterm's
/// alternate screen keeps none, so the rows stayed blank for a round trip
/// (T2a phone test: the top lines vanished when the keyboard closed). The
/// lines that leave the top of the pane – scrolled out by output, or taken
/// by a shrink – are kept here, newest last.
///
/// Lines scrolled back in at the top (tmux's copy mode going up) are the
/// kept ones again, blank until tmux draws them: the same line objects, so a
/// selection on them shows again (T2b: the selection stays while scrolling).
/// The same at the bottom: lines that leave it when tmux scrolls down are
/// kept, and come back when it scrolls up (T2b phone test: a selection whose
/// last line went under the bottom was gone for good).
///
/// xterm 4.0.0 moves a line inside a scroll region by assigning it to its new
/// slot, and the assignment that later overwrites the old slot detaches the
/// very same line: after a scroll, an insert or a delete the lines on screen
/// were all detached – a selection anchored to one of them was null, so
/// nothing showed (T2b phone test: no selection after a scroll, nor with the
/// keyboard open, where the shrink deletes lines). After every write and
/// resize, the lines on screen are adopted again at their slots.
///
/// tmux's copy mode (touch scrolling goes up into it) moves the cursor to
/// its own place and takes keys as commands – typing after a scroll went to
/// a "goto line" prompt (T2b phone test). It is seen by its position
/// indicator, right-aligned on the pane's first row: [inCopyMode] hides the
/// cursor, and [promptCursor] is where the shell's cursor shows meanwhile.
///
/// Assumes tmux's status line is the last row (tmux's default).
class TmuxTerminal extends Terminal {
  TmuxTerminal({super.maxLines, super.inputHandler});

  /// How many lines left the top are kept (a keyboard is ~20 rows).
  static const historyMax = 200;

  final _history = <BufferLine>[];

  /// Lines that left the bottom of the pane, the nearest one last.
  final _below = <BufferLine>[];

  /// Lines that left the top of the pane, newest last.
  int get historyLength => _history.length;

  /// Lines that left the bottom of the pane.
  @visibleForTesting
  int get belowLength => _below.length;

  /// tmux's copy mode is on the pane (its position indicator shows).
  bool get inCopyMode => _copyMode;
  bool _copyMode = false;

  /// How far copy mode is scrolled up, and tmux's history size.
  int _copyUp = 0;
  int _copyHistory = 0;

  /// Where the shell's cursor was (column, pane row) when copy mode began.
  (int, int)? _prompt;

  /// Where the shell's cursor shows while copy mode is on: the row it was on,
  /// moved down by the scroll; null outside copy mode, and when scrolled off
  /// the pane.
  CellOffset? get promptCursor {
    final at = _prompt;
    if (!_copyMode || at == null) return null;
    final row = at.$2 + _copyUp;
    if (row >= paneRows) return null;
    return CellOffset(math.min(at.$1, viewWidth - 1), buffer.scrollBack + row);
  }

  /// A keystroke takes tmux out of copy mode (the connection sends `q`
  /// before it): no second `q` before tmux's redraw shows it.
  void leftCopyMode() {
    if (!_copyMode) return;
    _copyMode = false;
    _leaving = true;
  }

  /// A `q` went out; the indicator still on screen is the old one.
  bool _leaving = false;

  /// The cursor xterm draws: tmux's copy-mode cursor is not shown.
  @override
  bool get cursorVisibleMode => super.cursorVisibleMode && !_copyMode;

  static final _indicator = RegExp(r'\[(\d+)/(\d+)\](?: \([^)]*\))?$');

  /// Copy mode's position indicator ("[up/history]", after an optional
  /// time and before an optional search count) is right-aligned on the
  /// pane's first row, in mode-style colours.
  void _seeCopyMode() {
    _copyMode = false;
    if (!_found()) {
      _leaving = false;
      return;
    }
    // still the old screen until tmux's redraw after the `q`
    _copyMode = !_leaving;
  }

  bool _found() {
    final b = buffer;
    if (!isUsingAltBuffer || viewHeight < 3) return false;
    final line = b.lines[b.scrollBack];
    final w = math.min(viewWidth, line.length);
    if (w < 5) return false;
    final last = w - 1;
    final end = line.getCodePoint(last);
    if (end != 0x5D /* ] */ && end != 0x29 /* ) */ ) return false;
    if (line.getBackground(last) & CellColor.typeMask == CellColor.normal) {
      return false;
    }
    final text = StringBuffer();
    for (var x = math.max(0, w - 48); x < w; x++) {
      final code = line.getCodePoint(x);
      text.writeCharCode(code == 0 ? 0x20 : code);
    }
    final m = _indicator.firstMatch(text.toString());
    if (m == null) return false;
    _copyUp = int.parse(m.group(1)!);
    _copyHistory = int.parse(m.group(2)!);
    return true;
  }

  /// Rows of the pane: all but tmux's status line on the alternate screen.
  int get paneRows =>
      isUsingAltBuffer ? math.max(1, viewHeight - 1) : viewHeight;

  /// The pane as one document, top to bottom: the lines kept above it, the
  /// pane's rows, the lines kept below it. Row [historyLength] is the pane's
  /// first row.
  List<BufferLine> documentLines() {
    final b = buffer;
    return [
      ..._history,
      for (var i = 0; i < paneRows; i++) b.lines[b.scrollBack + i],
      ..._below.reversed,
    ];
  }

  /// [n] lines leave the bottom of the scroll region: kept, the farthest
  /// first.
  void _keepBottom(int n) {
    final b = buffer;
    final bottom = b.marginBottom;
    for (var i = 0; i < n && bottom - i >= 0; i++) {
      _below.add(b.lines[b.scrollBack + bottom - i]);
    }
    final over = _below.length - historyMax;
    if (over > 0) _below.removeRange(0, over);
  }

  /// [amount] rows were opened at the bottom of the scroll region: the lines
  /// that left it come back into them (the nearest first), blank.
  void _restoreBottom(int amount) {
    final b = buffer;
    _below.removeWhere((line) => line.attached);
    final n = math.min(math.min(amount, b.marginBottom + 1), _below.length);
    final first =
        b.marginBottom - math.min<int>(amount, b.marginBottom + 1) + 1;
    for (var i = 0; i < n; i++) {
      final line = _below.removeLast()
        ..resize(viewWidth)
        ..eraseRange(0, viewWidth, cursor);
      b.lines[b.scrollBack + first + i] = line;
    }
  }

  void _keepTop(int n) {
    final b = buffer;
    for (var i = 0; i < n && i < viewHeight; i++) {
      _history.add(b.lines[b.scrollBack + i]);
    }
    final over = _history.length - historyMax;
    if (over > 0) _history.removeRange(0, over);
  }

  /// A line feed (or index) at the bottom of a scroll region that starts at
  /// the top: the top line leaves the screen.
  bool get _scrollsTop {
    final b = buffer;
    return isUsingAltBuffer &&
        b.marginTop == 0 &&
        b.isInVerticalMargin &&
        b.cursorY == b.marginBottom;
  }

  /// The cursor on the top row of a scroll region that starts at the top.
  bool get _atRegionTop {
    final b = buffer;
    return isUsingAltBuffer &&
        b.marginTop == 0 &&
        b.isInVerticalMargin &&
        b.cursorY == 0;
  }

  /// Every line on screen attached, at its own slot (see the class doc).
  void _reattach() {
    final lines = buffer.lines;
    for (var i = buffer.scrollBack; i < lines.length; i++) {
      final line = lines[i];
      if (!line.attached || line.index != i) lines[i] = line;
    }
  }

  /// [amount] rows were opened at the top of the pane: the lines that left
  /// the top last come back into them (oldest first), blank.
  void _restoreTop(int amount) {
    final b = buffer;
    // a line still on screen must not get a second slot
    _history.removeWhere((line) => line.attached);
    final n = math.min(math.min(amount, b.marginBottom + 1), _history.length);
    if (n <= 0) return;
    final back = _history.sublist(_history.length - n);
    _history.removeRange(_history.length - n, _history.length);
    for (var i = 0; i < n; i++) {
      final line = back[i]
        ..resize(viewWidth)
        ..eraseRange(0, viewWidth, cursor);
      b.lines[b.scrollBack + i] = line;
    }
  }

  @override
  void write(String data) {
    super.write(data);
    _reattach();
    _seeCopyMode();
    // the shell's cursor: where tmux leaves it outside copy mode (not
    // tmux's copy-mode cursor on the old screen while leaving it)
    if (!_copyMode && !_leaving && super.cursorVisibleMode) {
      _prompt = (buffer.cursorX, buffer.cursorY);
    }
  }

  @override
  void lineFeed() {
    final up = _scrollsTop;
    if (up) _keepTop(1);
    super.lineFeed();
    if (up) _restoreBottom(1);
  }

  @override
  void index() {
    final up = _scrollsTop;
    if (up) _keepTop(1);
    super.index();
    if (up) _restoreBottom(1);
  }

  @override
  void nextLine() {
    final up = _scrollsTop;
    if (up) _keepTop(1);
    super.nextLine();
    if (up) _restoreBottom(1);
  }

  @override
  void scrollUp(int amount) {
    final up = isUsingAltBuffer && buffer.marginTop == 0;
    if (up) _keepTop(math.min(amount, buffer.marginBottom + 1));
    super.scrollUp(amount);
    if (up) _restoreBottom(amount);
  }

  @override
  void deleteLines(int amount) {
    final up = _atRegionTop;
    if (up) _keepTop(math.min(amount, buffer.marginBottom + 1));
    super.deleteLines(amount);
    if (up) _restoreBottom(amount);
  }

  @override
  void scrollDown(int amount) {
    final back = isUsingAltBuffer && buffer.marginTop == 0;
    if (back) _keepBottom(math.min(amount, buffer.marginBottom + 1));
    super.scrollDown(amount);
    if (back) _restoreTop(amount);
  }

  @override
  void reverseIndex() {
    final back = _atRegionTop;
    if (back) _keepBottom(1);
    super.reverseIndex();
    if (back) _restoreTop(1);
  }

  @override
  void insertLines(int amount) {
    final back = _atRegionTop;
    if (back) _keepBottom(math.min(amount, buffer.marginBottom + 1));
    super.insertLines(amount);
    if (back) _restoreTop(amount);
  }

  @override
  void resize(
    int newWidth,
    int newHeight, [
    int? pixelWidth,
    int? pixelHeight,
  ]) {
    final oldHeight = viewHeight;
    final height = math.max(newHeight, 1);
    if (_copyMode && isUsingAltBuffer && height != oldHeight) {
      _movePrompt(oldHeight, height);
    }
    if (!isUsingAltBuffer || height == oldHeight || oldHeight < 3) {
      super.resize(newWidth, newHeight, pixelWidth, pixelHeight);
    } else if (height < oldHeight) {
      _shrinkLikeTmux(oldHeight - height);
      super.resize(newWidth, newHeight, pixelWidth, pixelHeight);
    } else {
      super.resize(newWidth, newHeight, pixelWidth, pixelHeight);
      _growLikeTmux(height - oldHeight);
    }
    _reattach();
  }

  /// tmux resizes the pane under copy mode as always (see the class doc):
  /// the shell's cursor row follows.
  void _movePrompt(int oldHeight, int height) {
    final at = _prompt;
    if (at == null || oldHeight < 3) return;
    final oldRows = oldHeight - 1;
    final rows = math.max(1, height - 1);
    var y = at.$2;
    if (rows < oldRows) {
      final below = math.max(0, oldRows - 1 - y);
      y -= math.max(0, oldRows - rows - below);
    } else {
      y += math.min(rows - oldRows, _copyHistory);
    }
    _prompt = (at.$1, math.min<int>(math.max<int>(y, 0), rows - 1));
  }

  /// Before xterm's shrink: the pane loses its lines below the cursor, then
  /// lines at the top; the status line stays last. The freed rows end up at
  /// the bottom, where xterm's own shrink removes them.
  void _shrinkLikeTmux(int k) {
    final b = buffer;
    final x = b.cursorX;
    final y = b.cursorY;
    final paneBottom = viewHeight - 2;
    final below = math.min(k, math.max(0, paneBottom - y));
    final top = k - below;
    b.resetVerticalMargins();
    if (below > 0) {
      b.setCursor(0, paneBottom - below + 1);
      b.deleteLines(below);
    }
    if (top > 0) {
      _keepTop(top); // tmux moves them into its history too
      b.setCursor(0, 0);
      b.deleteLines(top);
    }
    b.setCursor(x, math.max(0, y - top));
  }

  /// After xterm's grow (k blank rows under the status line): like tmux,
  /// the lines kept from history come back at the top, any rows still
  /// missing are blank at the bottom of the pane; the status line is last.
  void _growLikeTmux(int k) {
    final b = buffer;
    final x = b.cursorX;
    final y = b.cursorY;
    final n = math.min(k, _history.length);
    final status = viewHeight - 1 - k; // where xterm left it
    b.resetVerticalMargins();
    if (n > 0) {
      b.setCursor(0, 0);
      b.insertLines(n);
      final back = _history.sublist(_history.length - n);
      _history.removeRange(_history.length - n, _history.length);
      for (var i = 0; i < n; i++) {
        b.lines[b.scrollBack + i] = back[i]..resize(viewWidth);
      }
    }
    if (k > n) {
      b.setCursor(0, status + n);
      b.insertLines(k - n);
    }
    b.setCursor(x, y + n);
  }
}
