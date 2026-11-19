import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import 'panes.dart';

/// What the open page does on a window key (L2c): Ctrl+R refreshes it.
class PageCommands {
  const PageCommands({required this.refresh});

  final VoidCallback refresh;
}

/// The open page's [PageCommands] (the last one built wins), as the chat's
/// and the list's slots (L2b2): the page registers in its build and leaves
/// in its dispose, by owner.
class PageCommandSlot {
  Object? _owner;
  PageCommands? _current;

  PageCommands? get current => _current;

  void register(Object owner, PageCommands commands) {
    _owner = owner;
    _current = commands;
  }

  void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _current = null;
  }
}

final pageCommandSlotProvider = Provider<PageCommandSlot>(
  (ref) => PageCommandSlot(),
);

/// The Dashboard's columns for a [window] width (design 27 “Breakpoints”):
/// 1 below 820, 2 below 1100, 3 below 1920, then 4.
int dashboardColumns(double window) {
  if (window < DelveDesktop.dashboardOneColumnBelow) return 1;
  if (window < DelveDesktop.dashboardTwoColumnsBelow) return 2;
  if (window < DelveDesktop.wide) return 3;
  return 4;
}

/// A grid of cards for pages like Observability: 3 columns, 2 below a
/// 1100 window.
int gridColumns(double window) =>
    window < DelveDesktop.dashboardTwoColumnsBelow ? 2 : 3;

/// [children] dealt into [n] columns in reading order (1, 2, 3 | 4, 5, 6).
List<List<Widget>> dealColumns(List<Widget> children, int n) => [
  for (var c = 0; c < n; c++)
    [for (var i = c; i < children.length; i += n) children[i]],
];

/// Columns of cards side by side, each a stack with [gap] between its
/// cards (the Dashboard's masonry, Observability's grid). An empty column
/// keeps its width.
class DesktopColumns extends StatelessWidget {
  const DesktopColumns({
    super.key,
    required this.columns,
    this.gap = DelveDesktop.dashboardGap,
    this.selfSpaced = false,
  });

  final List<List<Widget>> columns;
  final double gap;

  /// The cards put the gap above themselves ([DashSpacing]): a card with
  /// nothing to show (a Dashboard card before its data) leaves no gap.
  final bool selfSpaced;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, column) in columns.indexed) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (j, card) in column.indexed)
                if (selfSpaced)
                  DashSpacing(top: j == 0 ? 0 : gap, child: card)
                else
                  Padding(
                    padding: EdgeInsets.only(top: j == 0 ? 0 : gap),
                    child: card,
                  ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// A page of the desktop's content pane (System, Observability, a News
/// settings section): the 48 px pane header, then the body. A Scaffold, so
/// its snackbars show.
class DesktopPage extends StatelessWidget {
  const DesktopPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.inspectorToggle = false,
  });

  final String title;
  final List<Widget> actions;
  final Widget child;

  /// The header ends with the inspector toggle (it shows only where the
  /// area has an inspector).
  final bool inspectorToggle;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.surface,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          title: title,
          actions: actions,
          inspectorToggle: inspectorToggle,
        ),
        Expanded(child: child),
      ],
    ),
  );
}

/// The body of a desktop page in a column of at most [maxWidth], centred,
/// with the content's 20 px gutters.
class DesktopPageBody extends StatelessWidget {
  const DesktopPageBody({
    super.key,
    required this.children,
    this.maxWidth = DelveDesktop.dashboardMaxWidth,
    this.top = 4,
  });

  final List<Widget> children;
  final double maxWidth;
  final double top;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gutter = DelveDesktop.contentGutter;
      final side = math.max(gutter, (box.maxWidth - maxWidth) / 2);
      return ListView(
        padding: EdgeInsets.fromLTRB(side, top, side, gutter),
        children: children,
      );
    },
  );
}

/// The header's refresh button: 28, “Refresh (Ctrl+R)”.
class DesktopRefreshButton extends StatelessWidget {
  const DesktopRefreshButton({
    super.key,
    required this.onPressed,
    this.buttonKey,
  });

  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => IconButton(
    key: buttonKey,
    tooltip: AppLocalizations.of(context).desktopRefresh,
    onPressed: onPressed,
    icon: const SymbolIcon(
      DelveIcons.refresh,
      size: DelveDesktop.iconButtonIcon,
    ),
  );
}
