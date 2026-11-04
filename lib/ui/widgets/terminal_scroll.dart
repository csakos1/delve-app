import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

import '../../terminal/terminal_connection.dart';
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
class TerminalScrollLayer extends StatefulWidget {
  const TerminalScrollLayer({
    super.key,
    required this.connection,
    required this.viewKey,
    required this.scrollController,
    required this.child,
  });

  final TerminalConnection connection;
  final GlobalKey<TerminalViewState> viewKey;

  /// The [TerminalView]'s scroll controller (main-buffer scrollback).
  final ScrollController scrollController;

  final Widget child;

  @override
  State<TerminalScrollLayer> createState() => _TerminalScrollLayerState();
}

class _TerminalScrollLayerState extends State<TerminalScrollLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fling;
  final _steps = WheelSteps(1);
  double _flingLast = 0;
  Offset _at = Offset.zero;

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

  /// [dy]: finger movement, down positive (older output comes into view).
  void _move(double dy) {
    final c = widget.connection;
    if (c.terminal.mouseMode.reportScroll) {
      _steps.stepPx = _lineHeight * kWheelStepLines;
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
      onPointerDown: (e) {
        _stop();
        _at = e.localPosition;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (d) {
          _stop();
          _steps.reset();
          _at = d.localPosition;
        },
        onVerticalDragUpdate: (d) => _move(d.delta.dy),
        onVerticalDragEnd: (d) {
          final v = d.velocity.pixelsPerSecond.dy;
          if (v.abs() < 300) return;
          _flingLast = 0;
          _fling.value = 0;
          unawaited(_fling.animateWith(FrictionSimulation(0.05, 0, v)));
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
