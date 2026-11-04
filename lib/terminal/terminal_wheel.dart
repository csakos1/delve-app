import 'package:xterm/xterm.dart';

/// A mouse-wheel report in the encoding the program asked for (tmux with
/// `mouse on`: SGR), or null when it did not ask for the mouse.
///
/// xterm 4.0.0's own wheel report sends button 68/69 (64 + 4, which is the
/// Shift bit): tmux reads that as Shift+wheel, which it does not bind, so
/// nothing scrolled (T1, T2a). The wheel is button 64 (up) and 65 (down).
String? wheelReport(
  Terminal terminal, {
  required bool up,
  required int column,
  required int row,
}) {
  if (!terminal.mouseMode.reportScroll) return null;
  final code = up ? 64 : 65;
  final mode = terminal.mouseReportMode;
  final limit = mode == MouseReportMode.normal ? 223 : 2015;
  final x = (column + 1).clamp(
    1,
    mode == MouseReportMode.sgr ? 1 << 20 : limit,
  );
  final y = (row + 1).clamp(1, mode == MouseReportMode.sgr ? 1 << 20 : limit);
  return switch (mode) {
    MouseReportMode.sgr => '\x1b[<$code;$x;${y}M',
    MouseReportMode.urxvt => '\x1b[${32 + code};$x;${y}M',
    MouseReportMode.normal || MouseReportMode.utf =>
      '\x1b[M${String.fromCharCode(32 + code)}'
          '${String.fromCharCode(32 + x)}${String.fromCharCode(32 + y)}',
  };
}

/// Lines a finger has to move for one wheel step. In the app's tmux
/// sessions a wheel step scrolls one line (`SshTarget.tmuxWheelBindings`),
/// so the text follows the finger line by line; with tmux's own 5 lines and
/// 3 lines of drag it jumped 5 lines at a time (T2b phone test).
const kWheelStepLines = 1.0;

/// A fling stops below this speed: its slow end would otherwise creep on in
/// single steps for seconds (lines per second).
const kFlingStopLinesPerSecond = 4.0;

/// Turns finger movement into whole wheel steps; the remainder carries over.
class WheelSteps {
  WheelSteps(this.stepPx) : assert(stepPx > 0);

  /// Pixels per step.
  double stepPx;
  double _rest = 0;

  /// [dy]: the finger's movement, down positive. The result is the number
  /// of steps: positive = wheel up (towards older output), negative = down.
  int add(double dy) {
    _rest += dy;
    final n = (_rest / stepPx).truncate();
    _rest -= n * stepPx;
    return n;
  }

  void reset() => _rest = 0;
}
