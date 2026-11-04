import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

/// Off → armed (next key only) → locked (until tapped again).
enum StickyState { off, armed, locked }

/// Sticky Ctrl and Alt for the extra key row (design 22). Every key event
/// gets the modifiers (the soft keyboard's letters arrive as key events
/// too); an armed modifier clears after one key.
class StickyModifiers extends TerminalInputHandler with ChangeNotifier {
  StickyModifiers([this._inner = defaultInputHandler]);

  final TerminalInputHandler _inner;
  StickyState _ctrl = StickyState.off;
  StickyState _alt = StickyState.off;

  StickyState get ctrl => _ctrl;
  StickyState get alt => _alt;

  void tapCtrl() {
    _ctrl = next(_ctrl);
    notifyListeners();
  }

  void tapAlt() {
    _alt = next(_alt);
    notifyListeners();
  }

  /// One tap arms, a tap on an armed key locks, a tap on a locked key clears.
  @visibleForTesting
  static StickyState next(StickyState s) => switch (s) {
    StickyState.off => StickyState.armed,
    StickyState.armed => StickyState.locked,
    StickyState.locked => StickyState.off,
  };

  /// Called after a key that used the modifiers: armed ones clear.
  void consumed() {
    var changed = false;
    if (_ctrl == StickyState.armed) {
      _ctrl = StickyState.off;
      changed = true;
    }
    if (_alt == StickyState.armed) {
      _alt = StickyState.off;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  @override
  String? call(TerminalKeyboardEvent event) {
    final ctrl = event.ctrl || _ctrl != StickyState.off;
    final alt = event.alt || _alt != StickyState.off;
    final out = _inner.call(event.copyWith(ctrl: ctrl, alt: alt));
    if (ctrl != event.ctrl || alt != event.alt) consumed();
    return out;
  }
}
