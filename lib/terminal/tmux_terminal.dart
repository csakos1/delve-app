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
/// The indicator is not the pane's text: a line that leaves the top with it
/// is kept without it (T3 phone test: closing the keyboard brought back a
/// column of old indicators for a round trip).
///
/// tmux does not always scroll copy mode with scroll sequences: a client it
/// has fallen behind, or a pane that is not as wide as the client, gets the
/// rows drawn again in place, and only the indicator tells how far the text
/// moved. While [followRedraws] is set, such a redraw moves the lines the
/// way the scroll would have ([_followRedraw]), so a selection stays on its
/// text (phone, 2026-11: it stayed on the screen rows instead, now and then).
///
/// tmux's status line, when it has one, is the last row ([statusRows]: 1,
/// tmux's default); the app's sessions have none (0).
class TmuxTerminal extends Terminal {
  TmuxTerminal({super.maxLines, super.inputHandler, this.statusRows = 1})
    : assert(statusRows == 0 || statusRows == 1);

  /// Rows tmux's status line takes at the bottom of the screen: 1 (tmux's
  /// default) or 0 (`status off`, the app's sessions).
  final int statusRows;

  /// How many lines left the top are kept (a keyboard is ~20 rows).
  static const historyMax = 200;

  final _history = <BufferLine>[];

  /// Lines that left the bottom of the pane, the nearest one last.
  final _below = <BufferLine>[];

  /// Lines that left the top of the pane, newest last.
  int get historyLength => _history.length;

  /// How many of tmux's history lines a bigger pane takes back: tmux counts
  /// the lines its pane scrolled out at the top (output, a smaller pane) and
  /// pulls only those back when the pane grows (`hscrolled`,
  /// screen_resize_y); a clear's lines and lines seen while scrolling in
  /// copy mode are history it keeps there. Taking back every kept line
  /// showed two old prompts above the screen for a round trip when the
  /// keyboard closed (T3 phone test).
  int _hscrolled = 0;

  /// The lines a bigger pane takes back now ([_hscrolled]).
  @visibleForTesting
  int get scrolledOut => _hscrolled;

  /// Lines that left the bottom of the pane.
  @visibleForTesting
  int get belowLength => _below.length;

  /// Copy mode's redraws in place are followed (see the class doc). Set by
  /// the connection while something is selected: each write then copies the
  /// pane's rows first.
  bool followRedraws = false;

  /// How many redraws in place were followed.
  int get redrawsFollowed => _redraws;
  int _redraws = 0;

  /// The pane's rows before the write going on (null: not followed).
  List<BufferLine>? _before;

  /// Rows the pane's lines moved by scroll sequences in the write going on:
  /// down (older lines in at the top) positive.
  int _moved = 0;

  /// The write before this one ended without the indicator, and without a
  /// `q`: tmux's update cut in two (the scroll in one write, the first row
  /// in the next), not copy mode beginning.
  bool _cut = false;
  bool _afterCut = false;

  /// tmux's copy mode is on the pane (its position indicator shows).
  bool get inCopyMode => _copyMode;
  bool _copyMode = false;

  /// Copy mode shows the oldest line of tmux's history: a wheel step up
  /// moves nothing ("[0/0]" in a new session).
  bool get copyAtTop => _copyMode && _copyUp >= _copyHistory;

  /// How far copy mode is scrolled up, and tmux's history size.
  int _copyUp = 0;
  int _copyHistory = 0;

  /// The column where the indicator (and the time before it) begins.
  int _indicatorAt = 0;

  /// Where the shell's cursor is outside copy mode (column, pane row).
  (int, int)? _prompt;

  /// Where the shell's cursor is in copy mode's copy of the pane: (column,
  /// line counted from the top of tmux's history), set when copy mode
  /// begins.
  ///
  /// tmux copies the pane with its history when copy mode begins and
  /// resizes that copy by itself: a smaller pane moves its top rows into the
  /// copy's history, blank rows too, and the indicator's history size grows
  /// by as many; a bigger one takes them back. The line stays the same, so
  /// its row is `line − history + up` from the indicator (measured on a real
  /// tmux 3.4: [5/55] → row 8, keyboard [22/75] → 5, closed [2/55] → 5). The
  /// old guess moved the row the way the live pane moves on a resize and put
  /// the cursor up to a keyboard's height below the prompt (T3 phone test).
  (int, int)? _promptLine;

  /// A resize in copy mode: the indicator on screen is the old one until
  /// tmux redraws the pane.
  bool _promptStale = false;

  /// Copy mode began ([copyModeEntry] counts the times): the connection asks
  /// tmux where the shell's cursor is and answers with [shellCursorFromTmux].
  /// The screen does not show it – copy mode hides it, and a copy mode that
  /// was on before the connection (the phone locked while scrolled up) is
  /// drawn without the shell's screen at all: the cursor was guessed from a
  /// screen half redrawn (T3 phone test: two rows above the prompt and one
  /// column short). Unset (no connection): the guess from the last screen.
  void Function(int entry)? onCopyMode;

  /// The pane is about to change size while copy mode is on (the keyboard,
  /// a pinch, a rotation): the connection leaves copy mode first.
  ///
  /// tmux puts copy mode's cursor line at the top after a resize, or shows
  /// the bottom at "[0/N]" (window_copy_resize): the view jumped by a
  /// keyboard's height and the numbers changed at every keyboard (T3 phone
  /// test: [2/2] → [19/22] → [0/2]). Out of copy mode the pane keeps its
  /// lines in place, as it does without a scroll.
  void Function()? onResizeInCopyMode;

  int _entry = 0;

  /// The times copy mode began (the answer to [onCopyMode] belongs to one).
  int get copyModeEntry => _entry;

  /// Asked and not answered yet: no shell cursor meanwhile.
  bool _promptAsked = false;

  /// tmux's answer for copy mode [entry]: the pane's cursor and history
  /// size (null: no answer – the guess stays). The line is
  /// `history + row`; it does not change when the pane changes size.
  void shellCursorFromTmux(int entry, [(int, int, int)? at]) {
    if (entry != _entry || !_copyMode) return;
    _promptAsked = false;
    if (at != null) _promptLine = (at.$1, at.$3 + at.$2);
    notifyListeners();
  }

  /// Where the shell's cursor shows while copy mode is on; null outside copy
  /// mode, when scrolled off the pane, while tmux is asked, and from a
  /// resize until tmux's redraw.
  CellOffset? get promptCursor {
    final at = _promptLine;
    if (!_copyMode || at == null || _promptStale || _promptAsked) return null;
    final row = at.$2 - _copyHistory + _copyUp;
    if (row < 0 || row >= paneRows) return null;
    return CellOffset(math.min(at.$1, viewWidth - 1), buffer.scrollBack + row);
  }

  /// A keystroke takes tmux out of copy mode (the connection sends `q`
  /// before it): no second `q` before tmux's redraw shows it.
  ///
  /// tmux's redraw puts the live pane back over these rows in place. The
  /// lines scrolled back onto the pane are still in tmux's history, so they
  /// are kept again – copies of those on screen – and what is kept below is
  /// what tmux redraws (N110: after a `q` from a scroll, closing the keyboard
  /// brought back older lines than tmux's for a round trip).
  void leftCopyMode() {
    if (!_copyMode) return;
    _copyMode = false;
    _leaving = true;
    if (!isUsingAltBuffer) return;
    // the live pane is the last rows of the document while the lines kept
    // below are exactly the scroll (else only the stale ones are dropped)
    if (_copyUp > 0 && _below.length == _copyUp) {
      final doc = documentLines();
      final first = _history.length; // the pane's first row in [doc]
      final rows = paneRows;
      final kept = [
        for (var i = 0; i < doc.length - rows; i++)
          i >= first && i < first + rows ? _copyOf(doc[i]) : doc[i],
      ];
      // the pane's first row without tmux's indicator, as tmux keeps it
      if (first < kept.length) {
        final top = kept[first];
        top.eraseRange(
          math.min(_indicatorAt, top.length),
          top.length,
          CursorStyle.empty,
        );
      }
      _history
        ..clear()
        ..addAll(kept);
      final over = _history.length - historyMax;
      if (over > 0) _history.removeRange(0, over);
    }
    _below.clear();
  }

  /// A detached copy of [line]: tmux overwrites the original in place.
  static BufferLine _copyOf(BufferLine line) =>
      BufferLine(line.length)..copyFrom(line, 0, 0, line.length);

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
    final was = _copyMode;
    _copyMode = false;
    if (!_found()) {
      _leaving = false;
    } else {
      // still the old screen until tmux's redraw after the `q`
      _copyMode = !_leaving;
    }
    if (!was && _copyMode) {
      final p = _prompt;
      _promptLine = p == null ? null : (p.$1, _copyHistory + p.$2);
      _promptStale = false;
      _entry++;
      final ask = onCopyMode;
      _promptAsked = ask != null;
      if (!_followEntry()) _enteredCopyMode();
      ask?.call(_entry);
    }
    // out of copy mode the pane is live: nothing is below it
    if (was && !_copyMode) _below.clear();
    if (!_copyMode) {
      _promptLine = null;
      _promptStale = false;
      _promptAsked = false;
    }
  }

  /// tmux draws the pane whole when copy mode begins, already scrolled up
  /// by [_copyUp]: the lines on top are the newest of tmux's history (no
  /// longer kept here), the live lines that went under the bottom are not
  /// kept – blank ones stand in for them, redrawn by tmux when they come
  /// back (N110: the kept lines matched tmux's again).
  void _enteredCopyMode() {
    if (!isUsingAltBuffer) return;
    final k = math.min(_copyUp, paneRows);
    if (k <= 0) return;
    _history.removeRange(math.max(0, _history.length - k), _history.length);
    _below.clear();
    for (var i = 0; i < k; i++) {
      _below.add(BufferLine(viewWidth));
    }
  }

  /// Copy mode began with the pane drawn again in place, scrolled up by
  /// [_copyUp]: the lines move as that scroll would have moved them (true),
  /// so what is selected on the live pane stays on its text.
  bool _followEntry() {
    if (_before == null || _moved != 0 || _afterCut) return false;
    if (_copyUp <= 0 || _copyUp >= paneRows) return false;
    return _followRedraw(_copyUp);
  }

  /// tmux drew the pane again in place, its text [r] rows further down (up
  /// when negative) than in [_before]: the lines move with their text, as a
  /// scroll would have moved them. Those that leave the pane are kept with
  /// the text they had, those that come back get what tmux drew.
  bool _followRedraw(int r) {
    final before = _before;
    final rows = paneRows;
    if (before == null || r == 0 || before.length != rows) return false;
    final b = buffer;
    final base = b.scrollBack;
    final n = math.min(r.abs(), rows);
    final lines = [for (var i = 0; i < rows; i++) b.lines[base + i]];
    final drawn = [for (final line in lines) _copyOf(line)];
    for (var i = 0; i < rows; i++) {
      lines[i].copyFrom(before[i], 0, 0, before[i].length);
    }
    final List<BufferLine> placed;
    if (r > 0) {
      // older lines came in at the top: the last n rows left at the bottom
      for (var i = 0; i < n; i++) {
        _below.add(lines[rows - 1 - i]);
      }
      final over = _below.length - historyMax;
      if (over > 0) _below.removeRange(0, over);
      final m = math.min(n, _history.length);
      final back = _history.sublist(_history.length - m);
      _history.removeRange(_history.length - m, _history.length);
      placed = [
        for (var i = 0; i < n - m; i++) BufferLine(viewWidth),
        ...back,
        ...lines.take(rows - n),
      ];
    } else {
      // newer lines came in at the bottom: the first n rows left at the top
      _keepWithoutIndicator(lines[0]);
      _history.addAll(lines.take(n));
      final over = _history.length - historyMax;
      if (over > 0) _history.removeRange(0, over);
      final m = math.min(n, _below.length);
      final back = [for (var i = 0; i < m; i++) _below.removeLast()];
      placed = [
        ...lines.skip(n),
        ...back,
        for (var i = 0; i < n - m; i++) BufferLine(viewWidth),
      ];
    }
    for (var i = 0; i < rows; i++) {
      placed[i].copyFrom(drawn[i], 0, 0, drawn[i].length);
      b.lines[base + i] = placed[i];
    }
    _reattach();
    _redraws++;
    return true;
  }

  bool _found() {
    final b = buffer;
    if (!isUsingAltBuffer || viewHeight < 3) return false;
    final found = _indicatorOn(b.lines[b.scrollBack]);
    if (found == null) return false;
    _indicatorAt = found.$1;
    _copyUp = found.$2;
    _copyHistory = found.$3;
    return true;
  }

  /// Copy mode's indicator at the end of [line]: (its first column, the
  /// time before it included; how far up; tmux's history size), or null.
  (int, int, int)? _indicatorOn(BufferLine line) {
    final w = math.min(viewWidth, line.length);
    if (w < 5) return null;
    final last = w - 1;
    final end = line.getCodePoint(last);
    if (end != 0x5D /* ] */ && end != 0x29 /* ) */ ) return null;
    if (line.getBackground(last) & CellColor.typeMask == CellColor.normal) {
      return null;
    }
    final text = StringBuffer();
    for (var x = math.max(0, w - 48); x < w; x++) {
      final code = line.getCodePoint(x);
      text.writeCharCode(code == 0 ? 0x20 : code);
    }
    final m = _indicator.firstMatch(text.toString());
    if (m == null) return null;
    // the time before it ("22:53 [8/8]") is in the same colours
    final colour = line.getBackground(last);
    var start = math.max(0, w - 48) + m.start;
    while (start > 0 && line.getBackground(start - 1) == colour) {
      start--;
    }
    return (start, int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// The pane's first row leaves the top: kept without copy mode's
  /// indicator, which tmux draws on whatever row is first (T3 phone test:
  /// scrolling down in copy mode kept one indicator per step, and closing
  /// the keyboard brought them all back for a round trip).
  void _keepWithoutIndicator(BufferLine line) {
    final found = _indicatorOn(line);
    if (found == null) return;
    line.eraseRange(
      math.min(found.$1, line.length),
      line.length,
      CursorStyle.empty,
    );
  }

  /// Rows of the pane: all but tmux's status line on the alternate screen.
  int get paneRows =>
      isUsingAltBuffer ? math.max(1, viewHeight - statusRows) : viewHeight;

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
      final line = b.lines[b.scrollBack + i];
      if (i == 0) _keepWithoutIndicator(line);
      _history.add(line);
    }
    final over = _history.length - historyMax;
    if (over > 0) _history.removeRange(0, over);
  }

  /// [n] lines scroll out at the top: kept; outside copy mode they are lines
  /// tmux's pane scrolled into its history ([_hscrolled]); in copy mode they
  /// are tmux's history going by.
  void _scrolledOut(int n) {
    _keepTop(n);
    if (!_copyMode) _hscrolled += n;
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

  /// The indicator's text in tmux's output (a redraw of the first row).
  static final _drawsIndicator = RegExp(r'\[\d+/\d+\]');

  @override
  void write(String data) {
    final follow = followRedraws && isUsingAltBuffer && viewHeight >= 3;
    final wasCopy = _copyMode;
    final wasStale = _promptStale;
    final up = _copyUp;
    final history = _copyHistory;
    final b = buffer;
    _before = follow
        ? [
            for (var i = 0; i < paneRows; i++)
              _copyOf(b.lines[b.scrollBack + i]),
          ]
        : null;
    _moved = 0;
    _afterCut = _cut;
    final leaving = _leaving;
    super.write(data);
    _reattach();
    _seeCopyMode();
    _cut = wasCopy && !_copyMode && !leaving;
    // the indicator moved further than the scroll sequences moved the lines
    // (a resize changes the numbers by itself: not then)
    if (follow &&
        wasCopy &&
        _copyMode &&
        !wasStale &&
        _copyHistory == history) {
      _followRedraw(_copyUp - up - _moved);
    }
    _before = null;
    // tmux's redraw after a resize draws the indicator with the new numbers
    if (_promptStale && _drawsIndicator.hasMatch(data)) _promptStale = false;
    // the shell's cursor: where tmux leaves it outside copy mode (not
    // tmux's copy-mode cursor on the old screen while leaving it)
    if (!_copyMode && !_leaving && super.cursorVisibleMode) {
      _prompt = (buffer.cursorX, buffer.cursorY);
    }
  }

  @override
  void lineFeed() {
    final up = _scrollsTop;
    if (up) _scrolledOut(1);
    super.lineFeed();
    if (up) _restoreBottom(1);
    if (up) _moved--;
  }

  @override
  void index() {
    final up = _scrollsTop;
    if (up) _scrolledOut(1);
    super.index();
    if (up) _restoreBottom(1);
    if (up) _moved--;
  }

  @override
  void nextLine() {
    final up = _scrollsTop;
    if (up) _scrolledOut(1);
    super.nextLine();
    if (up) _restoreBottom(1);
    if (up) _moved--;
  }

  @override
  void scrollUp(int amount) {
    final up = isUsingAltBuffer && buffer.marginTop == 0;
    if (up) _scrolledOut(math.min(amount, buffer.marginBottom + 1));
    super.scrollUp(amount);
    if (up) _restoreBottom(amount);
    if (up) _moved -= math.min(amount, buffer.marginBottom + 1);
  }

  @override
  void deleteLines(int amount) {
    final up = _atRegionTop;
    if (up) _keepTop(math.min(amount, buffer.marginBottom + 1));
    super.deleteLines(amount);
    if (up) _restoreBottom(amount);
    if (up) _moved -= math.min(amount, buffer.marginBottom + 1);
  }

  @override
  void scrollDown(int amount) {
    final back = isUsingAltBuffer && buffer.marginTop == 0;
    if (back) _keepBottom(math.min(amount, buffer.marginBottom + 1));
    super.scrollDown(amount);
    if (back) _restoreTop(amount);
    if (back) _moved += math.min(amount, buffer.marginBottom + 1);
  }

  @override
  void reverseIndex() {
    final back = _atRegionTop;
    if (back) _keepBottom(1);
    super.reverseIndex();
    if (back) _restoreTop(1);
    if (back) _moved++;
  }

  @override
  void insertLines(int amount) {
    final back = _atRegionTop;
    if (back) _keepBottom(math.min(amount, buffer.marginBottom + 1));
    super.insertLines(amount);
    if (back) _restoreTop(amount);
    if (back) _moved += math.min(amount, buffer.marginBottom + 1);
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
    final changes = height != oldHeight || newWidth != viewWidth;
    // out of copy mode first: tmux's own copy-mode resize jumps
    if (_copyMode && changes) onResizeInCopyMode?.call();
    if (_copyMode && changes) {
      // no connection: the numbers on screen are the old ones until tmux's
      // redraw
      _promptStale = true;
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

  /// Before xterm's shrink: the pane loses its lines below the cursor, then
  /// lines at the top; the status line stays last. The freed rows end up at
  /// the bottom, where xterm's own shrink removes them.
  void _shrinkLikeTmux(int k) {
    final b = buffer;
    final (x, y) = _paneCursor;
    final paneBottom = viewHeight - 1 - statusRows;
    final below = math.min(k, math.max(0, paneBottom - y));
    final top = k - below;
    b.resetVerticalMargins();
    if (below > 0) {
      b.setCursor(0, paneBottom - below + 1);
      b.deleteLines(below);
    }
    if (top > 0) {
      _keepTop(top); // tmux moves them into its history too
      _hscrolled += top;
      b.setCursor(0, 0);
      b.deleteLines(top);
    }
    _setPaneCursor(x, math.max(0, y - top));
  }

  /// The shell's cursor on the pane. Just after a `q` the screen is still
  /// copy mode's, with tmux's copy-mode cursor on it; tmux resizes the live
  /// pane around the shell's.
  (int, int) get _paneCursor {
    final b = buffer;
    final p = _prompt;
    if (_leaving && p != null) return p;
    return (b.cursorX, b.cursorY);
  }

  void _setPaneCursor(int x, int y) {
    buffer.setCursor(x, y);
    if (_leaving && _prompt != null) _prompt = (x, y);
  }

  /// After xterm's grow (k blank rows under the status line): like tmux,
  /// the lines kept from history come back at the top, any rows still
  /// missing are blank at the bottom of the pane; the status line is last.
  void _growLikeTmux(int k) {
    final b = buffer;
    final (x, y) = _paneCursor;
    // tmux takes back only lines its pane scrolled out ([_hscrolled]); the
    // rows for any it has that are not kept here stay blank until its redraw
    final m = math.min(k, _hscrolled);
    _hscrolled -= m;
    final n = math.min(m, _history.length);
    final status = viewHeight - statusRows - k; // where xterm left it
    b.resetVerticalMargins();
    if (m > 0) {
      b.setCursor(0, 0);
      b.insertLines(m);
      final back = _history.sublist(_history.length - n);
      _history.removeRange(_history.length - n, _history.length);
      for (var i = 0; i < n; i++) {
        b.lines[b.scrollBack + m - n + i] = back[i]..resize(viewWidth);
      }
    }
    // without a status line the rows still missing are xterm's blank ones,
    // already at the bottom
    if (k > m && statusRows > 0) {
      b.setCursor(0, status + m);
      b.insertLines(k - m);
    }
    _setPaneCursor(x, y + m);
  }
}
