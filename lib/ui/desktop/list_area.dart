import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import 'panes.dart';

/// A desktop area of a list and what is selected in it (L2c2: News, News
/// settings; Watches and Schedules next): the list in the list column, the
/// selection in the content, its details in the inspector. As in Chats,
/// below 900 the list is an overlay – open while nothing is selected,
/// closed once something is.
class ListArea extends ConsumerStatefulWidget {
  const ListArea({
    super.key,
    required this.area,
    required this.list,
    required this.content,
    this.inspector,
    this.selected,
    this.listDefault = DelveDesktop.listDefault,
  });

  /// The pane layout's key (the [DesktopArea]'s name).
  final String area;
  final Widget list;
  final Widget content;
  final Widget? inspector;

  /// What is selected (null: nothing – the list overlay opens).
  final String? selected;
  final double listDefault;

  @override
  ConsumerState<ListArea> createState() => _ListAreaState();
}

class _ListAreaState extends ConsumerState<ListArea> {
  @override
  void didUpdateWidget(ListArea old) {
    super.didUpdateWidget(old);
    final now = widget.selected;
    if (old.selected == now) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final layouts = ref.read(paneLayoutsProvider.notifier);
      if (now == null) {
        layouts.openListOverlay(widget.area);
      } else {
        layouts.closeListOverlay(widget.area);
      }
    });
  }

  @override
  Widget build(BuildContext context) => DesktopPanes(
    area: widget.area,
    list: widget.list,
    content: widget.content,
    inspector: widget.inspector,
    listDefault: widget.listDefault,
  );
}

/// The content while nothing is selected: a muted icon, a title and a hint.
class ListPlaceholder extends StatelessWidget {
  const ListPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(icon, size: 30, color: context.delve.textDisabled),
          const SizedBox(height: DelveTokens.space3),
          Text(title, style: context.text.titleMedium),
          const SizedBox(height: DelveTokens.space1),
          Text(
            hint,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A 32 px row of a section list in the list column (News settings, and
/// Settings / About me with L2c3): radius 8, selected `surface-3`, hover a
/// step up.
class SectionRow extends StatelessWidget {
  const SectionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0.5),
      child: Material(
        color: selected ? cs.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: cs.surfaceContainer,
          splashFactory: NoSplash.splashFactory,
          child: SizedBox(
            height: DelveDesktop.rowOneLine,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  if (icon case final i?) ...[
                    SymbolIcon(
                      i,
                      size: 17,
                      filled: selected,
                      color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DelveDesktopText.rowTitle.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (trailing case final t?)
                    Text(
                      t,
                      style: DelveDesktopText.meta.copyWith(
                        color: context.delve.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
