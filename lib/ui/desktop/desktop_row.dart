import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

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
    ],
  );
  picked?.onSelected();
}

/// A row of a desktop list column (design 27): radius 8, padding 8 / 10,
/// min height 52 (two lines), 1 px apart; hover one surface step up
/// (`surface-2` on the list's `surface-1`), selected `surface-3`. On hover
/// [actions] cover the row's top right; right-click opens [menu].
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
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final List<DesktopRowAction> actions;
  final List<DesktopMenuItem> menu;
  final double minHeight;

  /// The hover `more_horiz` button's tooltip (it opens [menu]).
  final String? moreTooltip;

  @override
  State<DesktopRowFrame> createState() => _DesktopRowFrameState();
}

class _DesktopRowFrameState extends State<DesktopRowFrame> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final background = widget.selected
        ? cs.surfaceContainerHigh
        : _hover
        ? cs.surfaceContainer
        : cs.surfaceContainerLow;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0.5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
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
