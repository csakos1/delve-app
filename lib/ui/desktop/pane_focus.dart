import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';

/// The panes the focus moves between (F6 / Shift+F6, L2d2) – the dock sits
/// between the content and the inspector when it is open.
enum PaneRole { list, content, inspector }

/// One pane's own focus point (L2d2): F6 / Shift+F6 move between the panes,
/// Enter from the list goes into the content, Esc from the content back to
/// the list. While the pane itself holds the focus after a key, it shows the
/// keyboard focus ring: 2 px accent, inside the pane's edge. A click on one
/// of its rows gives it the focus too, without the ring.
class PaneFocus extends StatefulWidget {
  const PaneFocus({super.key, required this.role, required this.child});

  final PaneRole role;
  final Widget child;

  static final List<_PaneFocusState> _mounted = [];

  static PaneRole? _last;

  /// The pane that had the focus last (the keys' pane while the focus sits
  /// on the shell – after a menu, say).
  static PaneRole? get last => _last;

  static _PaneFocusState? _of(PaneRole role) {
    for (final s in _mounted.reversed) {
      if (s.widget.role == role) return s;
    }
    return null;
  }

  /// The pane is on screen.
  static bool has(PaneRole role) => _of(role) != null;

  /// The pane the focus is in (null: none – the rail, the shell, a layer).
  static PaneRole? focused() {
    for (final s in _mounted.reversed) {
      if (s._node.hasFocus) return s.widget.role;
    }
    return null;
  }

  /// A pane itself holds the focus (not a field or a button in it).
  static bool onPane() => _mounted.any((s) => s._node.hasPrimaryFocus);

  /// Moves the focus to [role]'s pane; [ring]: with the focus ring (a key
  /// did it). False: no such pane.
  static bool focus(PaneRole role, {bool ring = true}) {
    final s = _of(role);
    if (s == null) return false;
    s._ring = ring;
    s._node.requestFocus();
    return true;
  }

  /// The pane [context] is in.
  static PaneRole? roleOf(BuildContext context) =>
      context.findAncestorStateOfType<_PaneFocusState>()?.widget.role;

  /// A click in a pane (a row): the pane takes the focus, unless it is in
  /// it already (a field there keeps it).
  static void focusAround(BuildContext context) {
    final s = context.findAncestorStateOfType<_PaneFocusState>();
    if (s == null || s._node.hasFocus) return;
    s._ring = false;
    s._node.requestFocus();
  }

  @override
  State<PaneFocus> createState() => _PaneFocusState();
}

class _PaneFocusState extends State<PaneFocus> {
  final FocusNode _node = FocusNode(skipTraversal: true);

  /// The next focus came from a key: draw the ring.
  bool _ring = false;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    PaneFocus._mounted.add(this);
    _node.addListener(_changed);
  }

  void _changed() {
    if (_node.hasFocus) PaneFocus._last = widget.role;
    final mine = _node.hasPrimaryFocus;
    final show = _ring && mine;
    if (!mine) _ring = false;
    if (show != _shown && mounted) setState(() => _shown = show);
  }

  @override
  void dispose() {
    PaneFocus._mounted.remove(this);
    _node
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    child: FocusTraversalGroup(
      child: Container(
        key: _shown ? Key('pane.focus.${widget.role.name}') : null,
        foregroundDecoration: _shown
            ? BoxDecoration(
                border: Border.all(
                  color: context.colors.primary,
                  width: DelveTokens.focusRing,
                ),
              )
            : null,
        child: widget.child,
      ),
    ),
  );
}

/// The input a pane is entered at (the chat's composer): Enter from the list
/// puts the focus there, not on the content pane itself. The last one built
/// wins.
abstract final class PaneEntry {
  static Object? _owner;
  static FocusNode? _node;

  static void register(Object owner, FocusNode node) {
    _owner = owner;
    _node = node;
  }

  static void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _node = null;
  }

  /// The entry of the content pane, if one is on screen.
  static FocusNode? get content {
    final node = _node;
    final context = node?.context;
    if (node == null || context == null || !context.mounted) return null;
    return PaneFocus.roleOf(context) == PaneRole.content ? node : null;
  }
}

/// Enter from the list: into the content – at its entry (the composer) if it
/// has one, else onto the pane. False: there is no content pane.
bool enterContent() {
  final entry = PaneEntry.content;
  if (entry != null) {
    entry.requestFocus();
    return true;
  }
  return PaneFocus.focus(PaneRole.content);
}
