import 'dart:async';

import 'package:flutter/gestures.dart' show kSecondaryMouseButton, kTouchSlop;
import 'package:flutter/material.dart';

import '../../app/layout.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import 'layers.dart' show LayerMark;
import 'pane_focus.dart';

/// A row's hover action (up to two, 22 px, at the row's top right).
@immutable
class DesktopRowAction {
  const DesktopRowAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.key,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final Key? key;
}

/// One entry of a context menu (rows 30, icon 17, `bodyMedium` 13).
@immutable
class DesktopMenuItem {
  const DesktopMenuItem({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  /// In `alert-fg` (Delete).
  final bool destructive;
  final Key? key;
}

/// Opens [items] as the desktop's context menu at [position] (global):
/// `surface-3`, radius 10, elevation-2, min width 200, rows 30.
Future<void> showDesktopMenu(
  BuildContext context,
  Offset position,
  List<DesktopMenuItem> items,
) async {
  if (items.isEmpty) return;
  // the focus goes back where it was (a pane: Enter, Shift+F10 again)
  final before = FocusManager.instance.primaryFocus;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final cs = context.colors;
  final picked = await showMenu<DesktopMenuItem>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    constraints: const BoxConstraints(minWidth: 200),
    items: [
      for (final item in items)
        PopupMenuItem<DesktopMenuItem>(
          key: item.key,
          value: item,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LayerMark(
            child: Row(
              children: [
                SymbolIcon(
                  item.icon,
                  size: 17,
                  color: item.destructive
                      ? context.delve.alertFg
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: context.text.bodyMedium!.copyWith(
                    fontSize: 13,
                    color: item.destructive ? context.delve.alertFg : null,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  if (picked != null) {
    picked.onSelected();
    return;
  }
  // dismissed (Esc, a click outside): back where it was, now and once the
  // route is gone
  void back() {
    final c = before?.context;
    if (before != null && c != null && c.mounted && !before.hasPrimaryFocus) {
      before.requestFocus();
    }
  }

  back();
  WidgetsBinding.instance.addPostFrameCallback((_) => back());
}

/// Right-click opens [items] as the context menu (design 27W-14d) – on the
/// raw pointer, so the chat's selection area around it does not take the
/// click (L2d2). On the phone it is [child] (long press copies there).
class DesktopMenuRegion extends StatefulWidget {
  const DesktopMenuRegion({
    super.key,
    required this.items,
    required this.child,
  });

  final List<DesktopMenuItem> Function() items;
  final Widget child;

  @override
  State<DesktopMenuRegion> createState() => _DesktopMenuRegionState();
}

class _DesktopMenuRegionState extends State<DesktopMenuRegion> {
  /// Where the secondary button went down (null: it did not).
  Offset? _down;

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.of(context)) return widget.child;
    return Listener(
      onPointerDown: (e) =>
          _down = e.buttons == kSecondaryMouseButton ? e.position : null,
      onPointerCancel: (_) => _down = null,
      onPointerUp: (e) {
        final down = _down;
        _down = null;
        if (down == null || (e.position - down).distance > kTouchSlop) return;
        unawaited(showDesktopMenu(context, e.position, widget.items()));
      },
      child: widget.child,
    );
  }
}

/// The desktop's right click on a message or a step (design 27W-14d):
/// [items] as a context menu; on the phone nothing (long press copies).
GestureTapUpCallback? desktopMenuOn(
  BuildContext context,
  List<DesktopMenuItem> Function() items,
) => DesktopLayout.of(context)
    ? (d) => unawaited(showDesktopMenu(context, d.globalPosition, items()))
    : null;

/// A row of a desktop list column (design 27): radius 8, padding 8 / 10,
/// min height 52 (two lines), 1 px apart; hover one surface step up
/// (`surface-2` on the list's `surface-1`), selected `surface-3`. On hover
/// [actions] cover the row's top right; right-click opens [menu]. In the
/// content pane ([onContent]: a watch's hits) the rest is `background` and
/// the hover `surface-1`. A selected row answers the keys of its pane
/// (L2d2): Shift+F10 opens its [menu], Enter runs [onOpen]; a click gives
/// its pane the focus.
class DesktopRowFrame extends StatefulWidget {
  const DesktopRowFrame({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.actions = const [],
    this.menu = const [],
    this.minHeight = DelveDesktop.rowTwoLine,
    this.moreTooltip,
    this.onContent = false,
    this.onOpen,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final List<DesktopRowAction> actions;
  final List<DesktopMenuItem> menu;
  final double minHeight;

  /// The hover `more_horiz` button's tooltip (it opens [menu]).
  final String? moreTooltip;

  /// The row sits in the content pane, not in the list column.
  final bool onContent;

  /// Enter on the selected row (a watch's hit: its link); null: Enter goes
  /// into the content.
  final VoidCallback? onOpen;

  @override
  State<DesktopRowFrame> createState() => _DesktopRowFrameState();
}

/// The selected rows that answer keys (L2d2): Shift+F10 opens the menu of
/// the one in the focused pane, Enter runs its [DesktopRowFrame.onOpen].
abstract final class SelectedRows {
  static final List<_DesktopRowFrameState> _rows = [];

  static _DesktopRowFrameState? _in(PaneRole role) {
    for (final r in _rows.reversed) {
      if (r.mounted && PaneFocus.roleOf(r.context) == role) return r;
    }
    return null;
  }

  /// What Enter does on the selected row of [role]'s pane.
  static VoidCallback? openIn(PaneRole role) => _in(role)?.widget.onOpen;

  /// The selected row of [role]'s pane has a menu.
  static bool hasMenuIn(PaneRole role) =>
      _in(role)?.widget.menu.isNotEmpty ?? false;

  /// Opens that menu under the row's start.
  static void showMenuIn(PaneRole role) => _in(role)?._showMenu();
}

class _DesktopRowFrameState extends State<DesktopRowFrame> {
  bool _hover = false;

  void _keep() {
    final wanted =
        widget.selected && (widget.menu.isNotEmpty || widget.onOpen != null);
    final has = SelectedRows._rows.contains(this);
    if (wanted && !has) SelectedRows._rows.add(this);
    if (!wanted && has) SelectedRows._rows.remove(this);
  }

  void _showMenu() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || widget.menu.isEmpty) return;
    unawaited(
      showDesktopMenu(
        context,
        box.localToGlobal(Offset(12, box.size.height)),
        widget.menu,
      ),
    );
  }

  @override
  void dispose() {
    SelectedRows._rows.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _keep();
    final cs = context.colors;
    final background = widget.selected
        ? cs.surfaceContainerHigh
        : _hover
        ? (widget.onContent ? cs.surfaceContainerLow : cs.surfaceContainer)
        : (widget.onContent ? cs.surface : cs.surfaceContainerLow);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0.5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // its pane takes the focus: Enter and Shift+F10 act on it
            PaneFocus.focusAround(context);
            widget.onTap();
          },
          onSecondaryTapUp: widget.menu.isEmpty
              ? null
              : (d) => unawaited(
                  showDesktopMenu(context, d.globalPosition, widget.menu),
                ),
          child: AnimatedContainer(
            duration: DelveDesktop.hover,
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
            ),
            child: Stack(
              children: [
                widget.child,
                if (_hover &&
                    (widget.actions.isNotEmpty || widget.menu.isNotEmpty))
                  Positioned(
                    top: -2,
                    right: -4,
                    child: ColoredBox(
                      color: background,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final a in widget.actions) _RowButton(action: a),
                          if (widget.menu.isNotEmpty)
                            Builder(
                              builder: (button) => _RowButton(
                                action: DesktopRowAction(
                                  key: const Key('row.more'),
                                  icon: DelveIcons.more,
                                  tooltip: widget.moreTooltip,
                                  onPressed: () {
                                    final box =
                                        button.findRenderObject()! as RenderBox;
                                    unawaited(
                                      showDesktopMenu(
                                        button,
                                        box.localToGlobal(
                                          box.size.bottomLeft(Offset.zero),
                                        ),
                                        widget.menu,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowButton extends StatelessWidget {
  const _RowButton({required this.action});

  final DesktopRowAction action;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: IconButton(
      key: action.key,
      tooltip: action.tooltip,
      padding: EdgeInsets.zero,
      iconSize: 16,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(22),
        fixedSize: const Size.square(22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveDesktop.iconButtonRadius),
        ),
      ),
      onPressed: action.onPressed,
      icon: SymbolIcon(
        action.icon,
        size: 16,
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}
