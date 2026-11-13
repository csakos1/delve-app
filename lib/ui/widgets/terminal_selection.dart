import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../l10n/app_localizations.dart';
import '../../terminal/terminal_connection.dart';
import '../../terminal/terminal_theme.dart';
import '../../theme/delve_theme.dart';
import 'page_scaffolds.dart';

/// Selects the word under [global] (a long press), or from it to [to] while
/// the finger moves; on a blank cell, the cells themselves. False when the
/// view is not there.
bool selectWordAt(
  TerminalViewState? view,
  TerminalController selection,
  Offset global, [
  Offset? to,
]) {
  if (view == null) return false;
  final render = view.renderTerminal;
  final from = render.globalToLocal(global);
  final end = to == null ? null : render.globalToLocal(to);
  selection.clearSelection();
  render.selectWord(from, end);
  if (selection.selection == null) render.selectCharacters(from, end);
  return selection.selection != null;
}

/// The last selected cell of [range] (its end is exclusive).
CellOffset _lastCell(BufferRange range, int width) {
  final end = range.end;
  if (end.x > 0) return CellOffset(end.x - 1, end.y);
  return end.y > range.begin.y ? CellOffset(width - 1, end.y - 1) : range.begin;
}

/// The selection's handles and its toolbar (22j3, 22-0): 22 dp accent
/// teardrops under the first and the last selected cell, with 48 dp targets;
/// the toolbar 8 dp above the first selected row (below the last one when
/// there is no room). Lies over the terminal view, in the same box; draws
/// nothing (and takes no touch) while nothing is selected.
///
/// A handle dragged up onto the pane's first row, or down onto its last,
/// scrolls the pane that way (as a finger would, a step at a time), so text
/// that is not on the screen can be taken in; the other end stays on its
/// line, scrolled out.
///
/// It also draws the cursor (xterm's is transparent: [delveTerminalViewTheme]),
/// as high as [terminalCursorHeight]; while tmux's copy mode is on, the
/// shell's cursor ([TmuxTerminal.promptCursor]) instead of tmux's own.
class TerminalSelectionLayer extends StatefulWidget {
  const TerminalSelectionLayer({
    super.key,
    required this.connection,
    required this.viewKey,
    required this.scrollController,
    required this.onCopy,
    required this.onSendToChat,
    required this.onPaste,
    required this.textStyle,
    this.focusNode,
  });

  final TerminalConnection connection;
  final GlobalKey<TerminalViewState> viewKey;
  final ScrollController scrollController;
  final VoidCallback onCopy;
  final VoidCallback onSendToChat;
  final VoidCallback onPaste;

  /// The view's text style: the reversed cells are drawn with it.
  final TerminalStyle textStyle;

  /// The view's focus: the cursor is hollow without it, as xterm draws it.
  final FocusNode? focusNode;

  @override
  State<TerminalSelectionLayer> createState() => _TerminalSelectionLayerState();
}

class _TerminalSelectionLayerState extends State<TerminalSelectionLayer> {
  late Listenable _changes;
  late Terminal _terminal;

  /// While a handle is dragged: how far the finger is from the middle of
  /// the cell the handle stands for, and where the finger is.
  bool _dragging = false;
  Offset _grab = Offset.zero;
  Offset _finger = Offset.zero;

  /// Where the finger was when the drag began.
  Offset _from = Offset.zero;

  /// Scrolls the pane while the dragged handle is at its edge.
  Timer? _auto;
  bool _autoUp = false;

  /// One step of the scroll a handle at the edge keeps up.
  static const _autoEvery = Duration(milliseconds: 60);

  /// A build found no layout to measure and asked for one more frame.
  bool _waiting = false;

  /// A rebuild after the terminal's change is already asked for.
  bool _outputPending = false;

  /// The last build drew the handles.
  bool _shown = false;

  /// Ticks when the terminal changed: the reversed cells are painted again
  /// in the same frame as the view.
  final _painted = _Tick();
  final _cells = _ReversedCells();

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(TerminalSelectionLayer old) {
    super.didUpdateWidget(old);
    if (old.connection != widget.connection ||
        old.scrollController != widget.scrollController) {
      _unlisten();
      _listen();
    }
  }

  void _listen() {
    final c = widget.connection;
    _changes = Listenable.merge([c.selection, widget.scrollController])
      ..addListener(_changed);
    _terminal = c.terminal..addListener(_output);
  }

  void _unlisten() {
    _changes.removeListener(_changed);
    _terminal.removeListener(_output);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _unlisten();
    _painted.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  /// The terminal changed (output, or a resize – which comes from layout,
  /// where no rebuild may be asked for): the handles follow after the frame.
  void _output() {
    _painted.tick();
    if (_outputPending ||
        (!_shown && widget.connection.selection.selection == null)) {
      return;
    }
    _outputPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _outputPending = false;
      // the pane scrolled under a handle held at its edge: the handle's
      // end is the cell under the finger now
      if (mounted && _dragging && _auto != null) _dragTo();
      _changed();
    });
  }

  /// [cell]'s bottom-left corner in this layer (null: not laid out yet).
  Offset? _corner(CellOffset cell) {
    final view = widget.viewKey.currentState;
    final box = context.findRenderObject();
    if (view == null || box is! RenderBox || !box.hasSize) return null;
    final render = view.renderTerminal;
    if (!render.attached || !box.attached) return null;
    final top = render.getOffset(cell);
    return box.globalToLocal(
      render.localToGlobal(top + Offset(0, render.lineHeight)),
    );
  }

  void _dragStart(
    DragStartDetails d, {
    required bool start,
    required Offset tip,
  }) {
    final view = widget.viewKey.currentState;
    if (widget.connection.selection.selection == null || view == null) return;
    widget.connection.beginSelectionDrag(start: start);
    final box = context.findRenderObject()! as RenderBox;
    // the tip is the cell's bottom corner (left for the start, right for
    // the end): aim at the middle of that cell, not at its neighbour
    final cell = view.renderTerminal.cellSize;
    final middle =
        tip +
        Offset(start ? cell.width / 2 : -cell.width / 2, -cell.height / 2);
    _grab = middle - box.globalToLocal(d.globalPosition);
    _finger = d.globalPosition;
    _from = d.globalPosition;
    _dragging = true;
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _finger = d.globalPosition;
    _dragTo();
    _edge();
  }

  /// The dragged end goes to the cell the finger aims at (kept on the pane).
  void _dragTo() {
    final view = widget.viewKey.currentState;
    if (!_dragging || view == null) return;
    final render = view.renderTerminal;
    if (!render.attached) return;
    final aim = render.globalToLocal(_finger + _grab);
    final height = render.size.height;
    final cell = render.getCellOffset(
      Offset(aim.dx, aim.dy.clamp(0.0, math.max(0.0, height - 1))),
    );
    widget.connection.dragSelectionTo(cell);
  }

  /// The handle dragged onto the pane's first or last row, towards that
  /// edge (at least half a row from where the drag began – a handle that
  /// only moves along the first row scrolls nothing): the pane scrolls that
  /// way until the handle leaves the row.
  void _edge() {
    final box = context.findRenderObject();
    final view = widget.viewKey.currentState;
    if (box is! RenderBox || !box.hasSize || view == null) return;
    final y = box.globalToLocal(_finger + _grab).dy;
    final row = view.renderTerminal.cellSize.height;
    final moved = _finger.dy - _from.dy;
    final up = y < row && moved < -row / 2;
    final down = y > box.size.height - row && moved > row / 2;
    if (!up && !down) {
      _auto?.cancel();
      _auto = null;
      return;
    }
    _autoUp = up;
    _auto ??= Timer.periodic(_autoEvery, (_) => _autoStep());
  }

  void _autoStep() {
    if (!mounted || !_dragging) return;
    final c = widget.connection;
    final t = c.terminal;
    final view = widget.viewKey.currentState;
    if (view == null) return;
    if (t.mouseMode.reportScroll) {
      // tmux: nothing older than the top of its history, nothing newer
      // than the live pane
      if (_autoUp ? t.copyAtTop : !t.inCopyMode) return;
      c.wheel(up: _autoUp, column: 0, row: 0);
      return;
    }
    final sc = widget.scrollController;
    if (!sc.hasClients) return;
    final p = sc.position;
    final line = view.renderTerminal.lineHeight;
    final to = (p.pixels + (_autoUp ? -line : line)).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    if (to == p.pixels) return;
    sc.jumpTo(to);
    _dragTo();
  }

  void _dragEnd() {
    _auto?.cancel();
    _auto = null;
    if (!_dragging) return;
    _dragging = false;
    widget.connection.endSelectionDrag();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.connection;
    final paint = Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ReversedPainter(
            connection: c,
            viewKey: widget.viewKey,
            layer: () => context.findRenderObject(),
            style: widget.textStyle,
            scaler: MediaQuery.textScalerOf(context),
            cells: _cells,
            focused: () => widget.focusNode?.hasFocus ?? true,
            repaint: Listenable.merge([
              c.selection,
              widget.scrollController,
              _painted,
              widget.focusNode,
            ]),
          ),
        ),
      ),
    );
    _shown = false;
    final range = c.selection.selection?.normalized;
    if (range == null) return Stack(children: [paint]);
    final last = _lastCell(range, c.terminal.viewWidth);
    final startTip = _corner(range.begin);
    final endBottom = _corner(last);
    final view = widget.viewKey.currentState;
    if (startTip == null || endBottom == null || view == null) {
      // laid out by the next frame: measure then (once)
      if (!_waiting) {
        _waiting = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
      }
      return Stack(children: [paint]);
    }
    _waiting = false;
    final cell = view.renderTerminal.cellSize;
    final size = (context.findRenderObject()! as RenderBox).size;
    final width = size.width;
    // scrolled out entirely: the selection stays (it comes back with its
    // lines), its handles and toolbar wait off screen
    final onScreen =
        endBottom.dy > 0 && startTip.dy - cell.height < size.height;
    final endTip = endBottom + Offset(cell.width, 0);
    final l = AppLocalizations.of(context);
    const h = DelveTokens.terminalHandle;
    const target = DelveTokens.touchTarget;

    Widget handle({required bool start, required Offset tip}) {
      // the drop hangs from the tip: left of it for the start, right of it
      // for the end (kept on the screen at the edges); its 48 dp target is
      // centred on the drop
      final left = start ? tip.dx - h : tip.dx;
      final drop = Rect.fromLTWH(
        left.clamp(0.0, math.max<double>(0.0, width - h)),
        tip.dy,
        h,
        h,
      );
      return Positioned(
        left: drop.center.dx - target / 2,
        top: drop.center.dy - target / 2,
        width: target,
        height: target,
        child: Semantics(
          label: start ? l.termSelStart : l.termSelEnd,
          child: GestureDetector(
            key: Key(start ? 'terminal.select.start' : 'terminal.select.end'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _dragStart(d, start: start, tip: tip),
            onPanUpdate: _dragUpdate,
            onPanEnd: (_) => _dragEnd(),
            onPanCancel: _dragEnd,
            child: Center(
              child: CustomPaint(
                size: const Size.square(h),
                painter: _HandlePainter(
                  color: context.colors.primary,
                  start: start,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!onScreen) return Stack(children: [paint]);
    _shown = true;
    return Stack(
      children: [
        paint,
        // a scrolled-out end has no handle (it is cut at the pane's edge)
        if (!c.selectionStartHidden) handle(start: true, tip: startTip),
        if (!c.selectionEndHidden) handle(start: false, tip: endTip),
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _ToolbarPlace(
              above: startTip.dy - cell.height,
              below: endBottom.dy + h,
              centre: (startTip.dx + endTip.dx) / 2,
            ),
            child: _Toolbar(
              onCopy: widget.onCopy,
              onSendToChat: widget.onSendToChat,
              onPaste: widget.onPaste,
            ),
          ),
        ),
      ],
    );
  }
}

/// 22 dp teardrop: round, with the corner at the tip square.
class _HandlePainter extends CustomPainter {
  const _HandlePainter({required this.color, required this.start});

  final Color color;
  final bool start;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.width / 2);
    final rect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: start ? r : Radius.zero,
      topRight: start ? Radius.zero : r,
      bottomLeft: r,
      bottomRight: r,
    );
    canvas.drawRRect(rect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.color != color || old.start != start;
}

/// The toolbar 8 dp above [above] (the first selected row's top), or 8 dp
/// below [below] (under the last row's handles) when it does not fit;
/// centred on [centre], kept 8 dp inside the edges.
class _ToolbarPlace extends SingleChildLayoutDelegate {
  const _ToolbarPlace({
    required this.above,
    required this.below,
    required this.centre,
  });

  final double above;
  final double below;
  final double centre;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    const gap = DelveTokens.space2;
    var y = above - gap - child.height;
    if (y < gap) y = below + gap;
    y = y.clamp(0.0, math.max<double>(0.0, size.height - child.height));
    final x = (centre - child.width / 2).clamp(
      gap,
      math.max<double>(gap, size.width - child.width - gap),
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ToolbarPlace old) =>
      old.above != above || old.below != below || old.centre != centre;
}

/// h 40 · surface-4 · radius 12 · elevation-2 · labelMedium + icon 16:
/// Copy, Chat (the selection to a chat) and Paste (the clipboard to the
/// shell). Smaller than the design's 48 dp bar (22-0), which hid too much
/// of a small screen with three buttons on it.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onCopy,
    required this.onSendToChat,
    required this.onPaste,
  });

  final VoidCallback onCopy;
  final VoidCallback onSendToChat;
  final VoidCallback onPaste;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final style = TextButton.styleFrom(
      foregroundColor: cs.onSurface,
      textStyle: context.text.labelMedium,
      minimumSize: const Size(0, _height),
      padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space3),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const RoundedRectangleBorder(),
    );
    Widget button(String key, IconData icon, String label, VoidCallback on) =>
        TextButton.icon(
          key: Key(key),
          style: style,
          onPressed: on,
          icon: SymbolIcon(icon, size: 16),
          label: Text(label),
        );
    return Container(
      key: const Key('terminal.select.toolbar'),
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
        boxShadow: DelveTokens.elevation2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            'terminal.select.copy',
            DelveIcons.copy,
            l.termSelCopy,
            onCopy,
          ),
          button(
            'terminal.select.send',
            DelveIcons.forum,
            l.termSelSendToChat,
            onSendToChat,
          ),
          button(
            'terminal.select.paste',
            DelveIcons.paste,
            l.termSelPaste,
            onPaste,
          ),
        ],
      ),
    );
  }
}

/// A repaint signal (the terminal changed).
class _Tick extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// Paragraphs for reversed cells, by character, colour and style; cleared
/// when the text size or scale changes.
class _ReversedCells {
  final _paragraphs = <int, ui.Paragraph>{};
  double? _fontSize;
  TextScaler? _scaler;
  List<Color>? _palette;

  List<Color> get palette => _palette ??= terminalPalette(delveTerminalTheme);

  (double, TextScaler, double)? _cursorFor;
  double _cursorHeight = 0;

  /// [terminalCursorHeight] for the text style, from a laid-out capital's
  /// baseline (the same line box xterm draws the rows in).
  double cursorHeight(TerminalStyle style, TextScaler scaler, double line) {
    final key = (style.fontSize, scaler, line);
    if (_cursorFor == key) return _cursorHeight;
    final m = paragraph(0x4D, delveTerminalTheme.foreground, 0, style, scaler);
    _cursorFor = key;
    return _cursorHeight = terminalCursorHeight(
      lineHeight: line,
      baseline: m.alphabeticBaseline,
      fontSize: scaler.scale(style.fontSize),
    );
  }

  ui.Paragraph paragraph(
    int code,
    Color color,
    int flags,
    TerminalStyle style,
    TextScaler scaler,
  ) {
    if (style.fontSize != _fontSize ||
        scaler != _scaler ||
        _paragraphs.length > 4096) {
      _paragraphs.clear();
      _fontSize = style.fontSize;
      _scaler = scaler;
    }
    final key = Object.hash(code, color.toARGB32(), flags);
    return _paragraphs[key] ??= () {
      final text = style.toTextStyle(
        color: color,
        bold: flags & CellFlags.bold != 0,
        italic: flags & CellFlags.italic != 0,
        underline: flags & CellFlags.underline != 0,
      );
      final builder = ui.ParagraphBuilder(text.getParagraphStyle())
        ..pushStyle(text.getTextStyle(textScaler: scaler))
        ..addText(String.fromCharCode(code));
      return builder.build()
        ..layout(const ui.ParagraphConstraints(width: double.infinity));
    }();
  }
}

/// The selection, reversed (T2b, as in Termux): each selected cell filled
/// with the colour its text shows in, its character drawn in the cell's
/// background colour – over the view, which paints no selection of its own
/// ([delveTerminalViewTheme]). Painted from the buffer in the same frame as
/// the view, so it moves with the text.
class _ReversedPainter extends CustomPainter {
  _ReversedPainter({
    required this.connection,
    required this.viewKey,
    required this.layer,
    required this.style,
    required this.scaler,
    required this.cells,
    required this.focused,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final TerminalConnection connection;
  final GlobalKey<TerminalViewState> viewKey;
  final RenderObject? Function() layer;
  final TerminalStyle style;
  final TextScaler scaler;
  final _ReversedCells cells;
  final bool Function() focused;

  @override
  void paint(Canvas canvas, Size size) {
    final range = connection.selection.selection?.normalized;
    final terminal = connection.terminal;
    final cursor =
        terminal.promptCursor ??
        (terminal.cursorVisibleMode
            ? CellOffset(
                terminal.buffer.cursorX,
                terminal.buffer.absoluteCursorY,
              )
            : null);
    final view = viewKey.currentState;
    final box = layer();
    if (view == null || box is! RenderBox) return;
    final render = view.renderTerminal;
    if (!render.attached || !box.attached) return;
    final origin =
        render.localToGlobal(Offset.zero) - box.localToGlobal(Offset.zero);
    final cell = render.cellSize;
    final theme = delveTerminalTheme;
    final palette = cells.palette;
    final data = CellData.empty();

    // Coloured rows reach the edges (htop's bars, a status line): the screen
    // is whole cells, so the grid ends a few pixels short of the right edge
    // and the bottom, and the colour stopped there (T2b phone test). The
    // first and the last row on screen reach up and down too.
    Color? shown(BufferLine line, int x) {
      if (x < 0 || x >= line.length) return null;
      line.getCellData(x, data);
      final inverse = data.flags & CellFlags.inverse != 0;
      if (!inverse &&
          data.background & CellColor.typeMask == CellColor.normal) {
        return null;
      }
      return inverse
          ? terminalColor(data.foreground, palette, theme.foreground)
          : terminalColor(data.background, palette, theme.background);
    }

    final lines = terminal.buffer.lines;
    final columns = terminal.viewWidth;
    final first = render.getCellOffset(Offset.zero).y;
    final last = math.min(first + terminal.viewHeight - 1, lines.length - 1);
    final edge = Paint();
    for (var y = first; y <= last; y++) {
      final line = lines[y];
      final at = render.getOffset(CellOffset(0, y));
      // xterm draws its rows at whole pixels
      final top = at.dy.truncateToDouble() + origin.dy;
      final bottom = top + cell.height;
      final left = at.dx + origin.dx;
      final right = left + columns * cell.width;
      final start = shown(line, 0);
      if (start != null && left > 0) {
        canvas.drawRect(
          Rect.fromLTRB(0, top, left, bottom),
          edge..color = start,
        );
      }
      final end = shown(line, columns - 1);
      if (end != null && right < size.width) {
        canvas.drawRect(
          Rect.fromLTRB(right, top, size.width, bottom),
          edge..color = end,
        );
      }
      final up = y == first && top > 0;
      final down = y == last && bottom < size.height;
      if (!up && !down) continue;
      for (var x = 0; x < columns; x++) {
        final colour = shown(line, x);
        if (colour == null) continue;
        final l = x == 0 ? 0.0 : left + x * cell.width;
        final r = x == columns - 1 ? size.width : left + (x + 1) * cell.width;
        if (up) {
          canvas.drawRect(Rect.fromLTRB(l, 0, r, top), edge..color = colour);
        }
        if (down) {
          canvas.drawRect(
            Rect.fromLTRB(l, bottom, r, size.height),
            edge..color = colour,
          );
        }
      }
    }

    if (cursor != null) {
      // a block, hollow without focus (as xterm's), centred on the text
      final hollow = !focused();
      final height = cells.cursorHeight(style, scaler, cell.height);
      canvas.drawRect(
        (render.getOffset(cursor) + origin) & Size(cell.width, height),
        Paint()
          ..color = delveTerminalTheme.cursor
          ..strokeWidth = 1
          ..style = hollow ? PaintingStyle.stroke : PaintingStyle.fill,
      );
    }
    if (range == null) return;
    final buffer = terminal.buffer;
    final fill = Paint();
    for (final segment in range.toSegments()) {
      if (segment.line < 0 || segment.line >= buffer.lines.length) continue;
      final rowTop = render.getOffset(CellOffset(0, segment.line)) + origin;
      if (rowTop.dy > size.height || rowTop.dy + cell.height < 0) continue;
      final line = buffer.lines[segment.line];
      final from = segment.start ?? 0;
      final to = math.min(segment.end ?? terminal.viewWidth, line.length);
      for (var x = from; x < to; x++) {
        line.getCellData(x, data);
        final flags = data.flags;
        final fg = terminalColor(data.foreground, palette, theme.foreground);
        final bg = terminalColor(data.background, palette, theme.background);
        final inverse = flags & CellFlags.inverse != 0;
        // what the cell shows, swapped
        final back = inverse ? bg : fg;
        var text = inverse ? fg : bg;
        if (flags & CellFlags.faint != 0) {
          text = text.withValues(alpha: text.a * 0.5);
        }
        final wide = data.content >> CellContent.widthShift == 2;
        final at = rowTop + Offset(x * cell.width, 0);
        canvas.drawRect(
          at & Size(cell.width * (wide ? 2 : 1) + 1, cell.height),
          fill..color = back,
        );
        final code = data.content & CellContent.codepointMask;
        if (code != 0 && code != 0x20) {
          canvas.drawParagraph(
            cells.paragraph(code, text, flags, style, scaler),
            at,
          );
        }
        if (wide) x++;
      }
    }
  }

  @override
  bool shouldRepaint(_ReversedPainter old) =>
      old.style.fontSize != style.fontSize || old.scaler != scaler;
}
