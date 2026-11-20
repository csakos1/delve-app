import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/delve_mark.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'palette.dart';
import 'panes.dart';
import 'shortcut_sheet.dart' show DesktopKeys;

/// The desktop's navigation (design 27): a 52 px `surface-2` column with
/// the Delve mark, the areas in their groups and, after a spacer, Search
/// (the palette), About me and Settings. Terminal and Files only with the
/// desktop tools; Approvals carries the phone's warn dot while an approval
/// can still be answered.
class DesktopRail extends ConsumerWidget {
  const DesktopRail({super.key, required this.location});

  /// The router's location: its area is selected.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final tools = ref.watch(desktopToolsProvider);
    final pending = ref.watch(answerableApprovalCountProvider).value ?? 0;
    final selected = DesktopArea.of(location);
    final groups = [
      for (final g in DesktopArea.groups)
        [
          for (final a in g)
            if (!a.tool || tools) a,
        ],
    ].where((g) => g.isNotEmpty).toList();

    final places = ref.read(desktopPlacesProvider);
    Widget item(DesktopArea a) => _RailItem(
      name: a.name,
      icon: a.icon,
      title: a.title(l),
      keys: a.keys(l),
      selected: a == selected,
      dot: a == DesktopArea.approvals && pending > 0,
      pending: pending,
      // the area as it was left (L2b2)
      onTap: () => context.go(places.target(a, location)),
    );

    return ColoredBox(
      key: const Key('desktop.rail'),
      color: cs.surfaceContainer,
      child: SizedBox(
        width: DelveDesktop.railWidth,
        child: Column(
          children: [
            // air above and below the mark; 1.5 px right of the box centre:
            // the D's round side carries its weight (L2b2)
            const Padding(
              padding: EdgeInsets.only(
                top: DelveDesktop.railMarkTop,
                bottom: DelveDesktop.railMarkBottom,
                left: DelveDesktop.railMarkNudge,
              ),
              child: Center(
                key: Key('rail.mark'),
                child: DelveMark(height: DelveDesktop.railMark),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < groups.length; i++) ...[
                      if (i > 0) const _GroupDivider(),
                      for (final a in groups[i]) item(a),
                    ],
                  ],
                ),
              ),
            ),
            // Search is the palette (Ctrl+K, L2d1)
            _RailItem(
              name: 'search',
              icon: DelveIcons.search,
              title: l.railSearch,
              keys: DesktopKeys.palette,
              onTap: () =>
                  unawaited(showCommandPalette(context, location: location)),
            ),
            for (final a in DesktopArea.foot) item(a),
            const SizedBox(height: DelveDesktop.railDividerMargin),
          ],
        ),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: DelveDesktop.railDividerWidth,
    height: DelveTokens.hairline,
    margin: const EdgeInsets.symmetric(
      vertical: DelveDesktop.railDividerMargin,
    ),
    color: context.colors.outlineVariant,
  );
}

/// One item: 40 × 34, radius 10, icon 20; hover `surface-3`, selected
/// `accent-container` with the accent icon filled; after 500 ms a tooltip
/// with the key, 8 px to the right of the rail.
class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.name,
    required this.icon,
    required this.title,
    required this.onTap,
    this.keys,
    this.selected = false,
    this.dot = false,
    this.pending = 0,
  });

  /// Its key is `rail.<name>`.
  final String name;
  final IconData icon;
  final String title;
  final String? keys;
  final bool selected;
  final bool dot;
  final int pending;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final background = widget.selected
        ? cs.primaryContainer
        : _hover
        ? cs.surfaceContainerHigh
        : Colors.transparent;
    final color = widget.selected
        ? cs.primary
        : _hover
        ? cs.onSurface
        : cs.onSurfaceVariant;
    Widget icon = SymbolIcon(
      widget.icon,
      size: DelveDesktop.railIcon,
      filled: widget.selected,
      color: color,
    );
    if (widget.dot) {
      icon = Badge(
        key: const Key('rail.approvals.dot'),
        smallSize: DelveDesktop.railDot,
        backgroundColor: context.delve.warnFg,
        child: icon,
      );
    }
    final semantics = widget.dot
        ? '${widget.title}, ${l.approvalsBadge(widget.pending)}'
        : widget.title;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DelveDesktop.railItemGap / 2,
      ),
      child: RailTooltip(
        title: widget.title,
        keys: widget.keys,
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: semantics,
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              key: Key('rail.${widget.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: DelveDesktop.hover,
                width: DelveDesktop.railItemWidth,
                height: DelveDesktop.railItemHeight,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(
                    DelveDesktop.railItemRadius,
                  ),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rail's tooltip (Components “Rail”, N437): after 500 ms of hover,
/// `surface-4`, radius 6, padding 5 / 8, `labelMedium` and the key in a key
/// cap, elevation-2, 8 px to the right of the rail and centred on the item
/// – a Material tooltip only opens above or below.
class RailTooltip extends StatefulWidget {
  const RailTooltip({
    super.key,
    required this.title,
    required this.child,
    this.keys,
  });

  final String title;
  final String? keys;
  final Widget child;

  @override
  State<RailTooltip> createState() => _RailTooltipState();
}

class _RailTooltipState extends State<RailTooltip> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  void _enter() {
    _wait?.cancel();
    _wait = Timer(DelveDesktop.tooltipDelay, () {
      if (mounted) _portal.show();
    });
  }

  void _hide() {
    _wait?.cancel();
    _wait = null;
    if (_portal.isShowing) _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    // from the item's right edge to the rail's, then the gap
    const dx =
        (DelveDesktop.railWidth - DelveDesktop.railItemWidth) / 2 +
        DelveDesktop.railTooltipGap;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.centerRight,
            followerAnchor: Alignment.centerLeft,
            offset: const Offset(dx, 0),
            child: IgnorePointer(
              child: Container(
                key: const Key('rail.tooltip'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    DelveDesktop.tooltipRadius,
                  ),
                  boxShadow: DelveTokens.elevation2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: context.text.labelMedium!.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    if (widget.keys case final keys?) ...[
                      const SizedBox(width: DelveTokens.space2),
                      KeyCap(keys),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => _enter(),
          onExit: (_) => _hide(),
          child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
        ),
      ),
    );
  }
}
