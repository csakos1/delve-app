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
/// Assumes tmux's status line is the last row (tmux's default).
class TmuxTerminal extends Terminal {
  TmuxTerminal({super.maxLines, super.inputHandler});

  /// How many lines left the top are kept (a keyboard is ~20 rows).
  static const historyMax = 200;

  final _history = <BufferLine>[];

  /// Lines that left the top of the pane, newest last.
  @visibleForTesting
  int get historyLength => _history.length;

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

  @override
  void lineFeed() {
    if (_scrollsTop) _keepTop(1);
    super.lineFeed();
  }

  @override
  void index() {
    if (_scrollsTop) _keepTop(1);
    super.index();
  }

  @override
  void nextLine() {
    if (_scrollsTop) _keepTop(1);
    super.nextLine();
  }

  @override
  void scrollUp(int amount) {
    if (isUsingAltBuffer && buffer.marginTop == 0) _keepTop(amount);
    super.scrollUp(amount);
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
    if (!isUsingAltBuffer || height == oldHeight || oldHeight < 3) {
      super.resize(newWidth, newHeight, pixelWidth, pixelHeight);
      return;
    }
    if (height < oldHeight) {
      _shrinkLikeTmux(oldHeight - height);
      super.resize(newWidth, newHeight, pixelWidth, pixelHeight);
    } else {
      super.resize(newWidth, newHeight, pixelWidth, pixelHeight);
      _growLikeTmux(height - oldHeight);
    }
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
