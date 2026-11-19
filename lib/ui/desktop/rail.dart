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
import 'panes.dart';

/// The desktop's navigation (design 27): a 52 px `surface-2` column with
/// the Delve mark, the areas in their groups and, after a spacer, About me
/// and Settings. Terminal and Files only with the desktop tools; Approvals
/// carries the phone's warn dot while an approval can still be answered.
class DesktopRail extends ConsumerWidget {
  const DesktopRail({super.key, required this.location});

  /// The router's location: its area is selected.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    Widget item(DesktopArea a) => _RailItem(
      area: a,
      selected: a == selected,
      dot: a == DesktopArea.approvals && pending > 0,
      pending: pending,
    );

    return ColoredBox(
      key: const Key('desktop.rail'),
      color: cs.surfaceContainer,
      child: SizedBox(
        width: DelveDesktop.railWidth,
        child: Column(
          children: [
            const SizedBox(
              height: DelveDesktop.railMarkSlot,
              child: Center(child: DelveMark(height: DelveDesktop.railMark)),
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

/// One area: 40 × 34, radius 10, icon 20; hover `surface-3`, selected
/// `accent-container` with the accent icon filled; a tooltip with the key.
class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.area,
    required this.selected,
    required this.dot,
    required this.pending,
  });

  final DesktopArea area;
  final bool selected;
  final bool dot;
  final int pending;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final a = widget.area;
    final title = a.title(l);
    final keys = a.keys(l);
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
      a.icon,
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
        ? '$title, ${l.approvalsBadge(widget.pending)}'
        : title;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DelveDesktop.railItemGap / 2,
      ),
      child: Tooltip(
        excludeFromSemantics: true,
        richMessage: WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: context.text.labelMedium!.copyWith(color: cs.onSurface),
              ),
              if (keys != null) ...[
                const SizedBox(width: DelveTokens.space2),
                KeyCap(keys),
              ],
            ],
          ),
        ),
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
              key: Key('rail.${a.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => context.go(a.route),
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
