import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

import '../../terminal/terminal_connection.dart';
import '../../terminal/terminal_service.dart';
import '../../terminal/terminal_wheel.dart';

/// Touch scrolling for the terminal (T2a phone test: there was none).
///
/// tmux runs with `mouse on`: a vertical drag becomes mouse-wheel steps,
/// which tmux turns into copy-mode scrolling (or hands to the program in the
/// pane when it wants the mouse – htop, vim); a fling keeps going and slows
/// down. Without mouse reporting xterm's own scrollback moves instead.
///
/// xterm's inner scroll views get no touch drags (their drag devices are
/// switched off below), so the drag is ours and is not split between them.
///
/// Taps and long presses are reported here too (T2b): the terminal view
/// itself takes no pointer at all, because its own long press opened the
/// keyboard and clicked into tmux before it selected anything. A tap that
/// only stops a fling is not a tap; a selection stays while scrolling.
///
/// Two fingers pinch the font size (design 22-0: 9–20 sp in 1 sp steps); a
/// touch that had two fingers is no tap, long press or scroll.
class TerminalScrollLayer extends StatefulWidget {
  const TerminalScrollLayer({
    super.key,
    required this.connection,
    required this.viewKey,
    required this.scrollController,
    required this.child,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressMove,
    this.fontSize = kTerminalFontSize,
    this.onFontSize,
  });

  final TerminalConnection connection;
  final GlobalKey<TerminalViewState> viewKey;

  /// The [TerminalView]'s scroll controller (main-buffer scrollback).
  final ScrollController scrollController;

  final Widget child;

  /// A confirmed tap (not the start of a long press), global position.
  final void Function(Offset global)? onTap;

  /// A long press, and the finger moving while it is held.
  final void Function(Offset global)? onLongPressStart;
  final void Function(Offset global)? onLongPressMove;

  /// The font size now, and a new one from a pinch (whole sp, in range).
  final double fontSize;
  final ValueChanged<double>? onFontSize;

  @override
  State<TerminalScrollLayer> createState() => _TerminalScrollLayerState();
}

class _TerminalScrollLayerState extends State<TerminalScrollLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fling;
  final _steps = WheelSteps(1);
  double _flingLast = 0;
  Offset _at = Offset.zero;

  /// The pointer that went down stopped a fling: its tap is not a tap.
  bool _stoppedFling = false;

  /// The fingers down now (local positions).
  final _pointers = <int, Offset>{};

  /// The fingers' distance when the pinch began, and the size then.
  double? _pinchFrom;
  double _pinchSize = kTerminalFontSize;

  /// This touch had two fingers: no tap, long press, scroll or fling.
  bool _pinched = false;

  @override
  void initState() {
    super.initState();
    // created here, not lazily: touched first in dispose() it would look up
    // TickerMode on an unmounted element
    _fling = AnimationController.unbounded(vsync: this)..addListener(_onFling);
  }

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  double get _lineHeight {
    final h = widget.viewKey.currentState?.renderTerminal.lineHeight;
    return h == null || h <= 0 ? 16 : h;
  }

  CellOffset _cell() {
    final render = widget.viewKey.currentState?.renderTerminal;
    if (render == null) return const CellOffset(0, 0);
    return render.getCellOffset(_at);
  }

  double get _spread {
    final p = _pointers.values.take(2).toList();
    return (p[0] - p[1]).distance;
  }

  void _pinchStart() {
    _pinched = true;
    _stop();
    _pinchFrom = _spread;
    _pinchSize = widget.fontSize;
  }

  void _pinchMove() {
    final from = _pinchFrom;
    final on = widget.onFontSize;
    if (from == null || from <= 0 || on == null) return;
    final size = (_pinchSize * _spread / from)
        .roundToDouble()
        .clamp(kTerminalFontMin, kTerminalFontMax)
        .toDouble();
    if (size != widget.fontSize) on(size);
  }

  void _up(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchFrom = null;
  }

  /// [dy]: finger movement, down positive (older output comes into view).
  void _move(double dy) {
    if (_pinched) return;
    final c = widget.connection;
    if (c.terminal.mouseMode.reportScroll) {
      _steps.stepPx = _lineHeight * c.wheelLines;
      final n = _steps.add(dy);
      if (n == 0) return;
      final cell = _cell();
      for (var i = 0; i < n.abs(); i++) {
        c.wheel(up: n > 0, column: cell.x, row: cell.y);
      }
      return;
    }
    final sc = widget.scrollController;
    if (!sc.hasClients) return;
    final p = sc.position;
    sc.jumpTo((p.pixels - dy).clamp(p.minScrollExtent, p.maxScrollExtent));
  }

  void _onFling() {
    final v = _fling.value;
    final d = v - _flingLast;
    _flingLast = v;
    if (d != 0) _move(d);
  }

  void _stop() {
    if (_fling.isAnimating) _fling.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // the child (a translucent detector over a view that takes no touch)
      // does not count as hit, so a deferring listener never saw a pointer:
      // no pinch, and a touch did not stop a fling
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (_pointers.isEmpty) _pinched = false;
        _pointers[e.pointer] = e.localPosition;
        if (_pointers.length == 2 && widget.onFontSize != null) {
          _pinchStart();
          return;
        }
        if (_pointers.length > 1) return;
        _stoppedFling = _fling.isAnimating;
        _stop();
        _at = e.localPosition;
      },
      onPointerMove: (e) {
        if (!_pointers.containsKey(e.pointer)) return;
        _pointers[e.pointer] = e.localPosition;
        if (_pinchFrom != null) _pinchMove();
      },
      onPointerUp: _up,
      onPointerCancel: _up,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (d) {
          if (_stoppedFling || _pinched) return;
          widget.onTap?.call(d.globalPosition);
        },
        onLongPressStart: (d) {
          if (_pinched) return;
          widget.onLongPressStart?.call(d.globalPosition);
        },
        onLongPressMoveUpdate: (d) {
          if (_pinched) return;
          widget.onLongPressMove?.call(d.globalPosition);
        },
        onVerticalDragStart: (d) {
          _stop();
          _steps.reset();
          _at = d.localPosition;
        },
        onVerticalDragUpdate: (d) => _move(d.delta.dy),
        onVerticalDragEnd: (d) {
          if (_pinched) return;
          final v = d.velocity.pixelsPerSecond.dy;
          if (v.abs() < 300) return;
          _flingLast = 0;
          _fling.value = 0;
          unawaited(
            _fling.animateWith(
              FrictionSimulation(
                0.05,
                0,
                v,
                tolerance: Tolerance(
                  velocity: _lineHeight * kFlingStopLinesPerSecond,
                ),
              ),
            ),
          );
        },
        child: ScrollConfiguration(
          behavior: const _NoDragScroll(),
          child: widget.child,
        ),
      ),
    );
  }
}

/// xterm's scroll views: no drag from touch (the layer above handles it);
/// a mouse wheel still works.
class _NoDragScroll extends ScrollBehavior {
  const _NoDragScroll();

  @override
  Set<PointerDeviceKind> get dragDevices => const {};

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
