import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// One area's panes as the reader left them: the widths and whether the
/// list and the inspector are open. Docked panes keep this; the overlays of
/// narrow windows ([listOverlay], [inspectorOverlay]) are opened per visit.
@immutable
class PaneLayout {
  const PaneLayout({
    required this.list,
    this.listOpen = true,
    this.inspector = DelveDesktop.inspectorDefault,
    this.inspectorOpen = true,
    this.listOverlay = true,
    this.inspectorOverlay = false,
  });

  final double list;
  final bool listOpen;
  final double inspector;
  final bool inspectorOpen;

  /// Below 900 the list is an overlay: open while nothing is selected.
  final bool listOverlay;

  /// Below 1232 the inspector is an overlay: closed until asked for.
  final bool inspectorOverlay;

  PaneLayout copyWith({
    double? list,
    bool? listOpen,
    double? inspector,
    bool? inspectorOpen,
    bool? listOverlay,
    bool? inspectorOverlay,
  }) => PaneLayout(
    list: list ?? this.list,
    listOpen: listOpen ?? this.listOpen,
    inspector: inspector ?? this.inspector,
    inspectorOpen: inspectorOpen ?? this.inspectorOpen,
    listOverlay: listOverlay ?? this.listOverlay,
    inspectorOverlay: inspectorOverlay ?? this.inspectorOverlay,
  );
}

/// The panes of every area, by area key (kept while the app runs; keeping
/// them across starts comes with Settings → Desktop tools, L2c).
class PaneLayouts extends Notifier<Map<String, PaneLayout>> {
  @override
  Map<String, PaneLayout> build() => const {};

  PaneLayout of(String area, {double list = DelveDesktop.listDefault}) =>
      state[area] ?? PaneLayout(list: list);

  void _set(String area, PaneLayout layout) => state = {...state, area: layout};

  void setList(String area, double width, {double? fallback}) => _set(
    area,
    of(area, list: fallback ?? DelveDesktop.listDefault).copyWith(
      list: width
          .clamp(DelveDesktop.listMin, DelveDesktop.listMax)
          .roundToDouble(),
    ),
  );

  void setInspector(String area, double width) => _set(
    area,
    of(area).copyWith(
      inspector: width
          .clamp(DelveDesktop.inspectorMin, DelveDesktop.inspectorMax)
          .roundToDouble(),
    ),
  );

  /// Ctrl+B: the docked list, or below 900 its overlay.
  void toggleList(String area, {required bool overlay}) {
    final p = of(area);
    _set(
      area,
      overlay
          ? p.copyWith(listOverlay: !p.listOverlay)
          : p.copyWith(listOpen: !p.listOpen),
    );
  }

  /// Ctrl+I and the header's toggle: the docked inspector, or below 1232
  /// its overlay.
  void toggleInspector(String area, {required bool overlay}) {
    final p = of(area);
    _set(
      area,
      overlay
          ? p.copyWith(inspectorOverlay: !p.inspectorOverlay)
          : p.copyWith(inspectorOpen: !p.inspectorOpen),
    );
  }

  /// Esc: closes an open overlay; false when there was none.
  bool closeOverlays(String area) {
    final p = of(area);
    if (!(p.listOverlay || p.inspectorOverlay)) return false;
    _set(area, p.copyWith(listOverlay: false, inspectorOverlay: false));
    return true;
  }

  /// Something was selected in the list: its overlay makes way.
  void closeListOverlay(String area) {
    final p = of(area);
    if (p.listOverlay) _set(area, p.copyWith(listOverlay: false));
  }

  /// Nothing selected: the list overlay shows again.
  void openListOverlay(String area) {
    final p = of(area);
    if (!p.listOverlay) _set(area, p.copyWith(listOverlay: true));
  }
}

final paneLayoutsProvider =
    NotifierProvider<PaneLayouts, Map<String, PaneLayout>>(PaneLayouts.new);

/// How the panes of a window [width] are placed.
@immutable
class PanePlacement {
  const PanePlacement({
    required this.listDocked,
    required this.listWidth,
    required this.listOverlay,
    required this.inspectorDocked,
    required this.inspectorWidth,
    required this.inspectorOverlay,
  });

  /// [area]'s panes at a window [width]; [hasList] / [hasInspector]: the
  /// page has them at all.
  factory PanePlacement.of(
    PaneLayout p,
    double width, {
    required bool hasList,
    required bool hasInspector,
  }) {
    final listAsOverlay = width < DelveDesktop.listOverlayBelow;
    final inspectorAsOverlay = width < DelveDesktop.inspectorOverlayBelow;
    final inspectorDocked =
        hasInspector && !inspectorAsOverlay && p.inspectorOpen;
    return PanePlacement(
      listDocked: hasList && !listAsOverlay && p.listOpen,
      listWidth: DelveDesktop.listWidth(
        width,
        remembered: p.list,
        inspectorDocked: inspectorDocked,
        inspector: p.inspector,
      ),
      listOverlay: hasList && listAsOverlay && p.listOverlay,
      inspectorDocked: inspectorDocked,
      inspectorWidth: p.inspector,
      inspectorOverlay:
          hasInspector && inspectorAsOverlay && p.inspectorOverlay,
    );
  }

  final bool listDocked;
  final double listWidth;
  final bool listOverlay;
  final bool inspectorDocked;
  final double inspectorWidth;
  final bool inspectorOverlay;

  bool get inspectorShown => inspectorDocked || inspectorOverlay;
}

/// What a pane's widgets need from the panes around them (the inspector
/// toggle in the content header).
class PaneScope extends InheritedWidget {
  const PaneScope({
    super.key,
    required this.area,
    required this.placement,
    required this.hasInspector,
    required super.child,
  });

  final String area;
  final PanePlacement placement;
  final bool hasInspector;

  static PaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneScope>();

  @override
  bool updateShouldNotify(PaneScope old) =>
      area != old.area ||
      hasInspector != old.hasInspector ||
      placement.inspectorShown != old.placement.inspectorShown ||
      placement.inspectorOverlay != old.placement.inspectorOverlay;
}

/// The Workbench panes of one area: list column · content · inspector
/// (design 27). The content is never narrower than 600: the list narrows
/// first (to 240), below 1232 the inspector is an overlay, below 900 the
/// list too. Docked panes are resizable at their edge (double-click: the
/// default width); the widths are kept per [area].
class DesktopPanes extends ConsumerWidget {
  const DesktopPanes({
    super.key,
    required this.area,
    required this.content,
    this.list,
    this.inspector,
    this.listDefault = DelveDesktop.listDefault,
  });

  final String area;
  final Widget content;
  final Widget? list;
  final Widget? inspector;
  final double listDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final layouts = ref.watch(paneLayoutsProvider.notifier);
    ref.watch(paneLayoutsProvider);
    final p = layouts.of(area, list: listDefault);
    final width = MediaQuery.sizeOf(context).width;
    final at = PanePlacement.of(
      p,
      width,
      hasList: list != null,
      hasInspector: inspector != null,
    );

    Widget pane(Widget child, Color color, Key key) =>
        ColoredBox(key: key, color: color, child: child);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (at.listDocked)
          SizedBox(
            width: at.listWidth,
            child: pane(list!, cs.surfaceContainerLow, const Key('pane.list')),
          ),
        Expanded(child: pane(content, cs.surface, const Key('pane.content'))),
        if (at.inspectorDocked)
          SizedBox(
            width: at.inspectorWidth,
            child: pane(
              inspector!,
              cs.surfaceContainerLow,
              const Key('pane.inspector'),
            ),
          ),
      ],
    );

    return PaneScope(
      area: area,
      placement: at,
      hasInspector: inspector != null,
      child: LayoutBuilder(
        builder: (context, box) {
          final listMax =
              (box.maxWidth -
                      (at.inspectorDocked ? at.inspectorWidth : 0) -
                      DelveDesktop.contentMin)
                  .clamp(DelveDesktop.listMin, DelveDesktop.listMax)
                  .toDouble();
          final inspectorMax =
              (box.maxWidth -
                      (at.listDocked ? at.listWidth : 0) -
                      DelveDesktop.contentMin)
                  .clamp(DelveDesktop.inspectorMin, DelveDesktop.inspectorMax)
                  .toDouble();
          return Stack(
            children: [
              Positioned.fill(child: row),
              if (at.listDocked)
                Positioned(
                  left: at.listWidth - DelveDesktop.dividerGrab / 2,
                  top: 0,
                  bottom: 0,
                  child: PaneDivider(
                    key: const Key('pane.list.divider'),
                    onDrag: (dx) => layouts.setList(
                      area,
                      (layouts.of(area, list: listDefault).list + dx)
                          .clamp(DelveDesktop.listMin, listMax)
                          .toDouble(),
                      fallback: listDefault,
                    ),
                    onReset: () => layouts.setList(
                      area,
                      listDefault,
                      fallback: listDefault,
                    ),
                  ),
                ),
              if (at.inspectorDocked)
                Positioned(
                  right: at.inspectorWidth - DelveDesktop.dividerGrab / 2,
                  top: 0,
                  bottom: 0,
                  child: PaneDivider(
                    key: const Key('pane.inspector.divider'),
                    onDrag: (dx) => layouts.setInspector(
                      area,
                      (layouts.of(area).inspector - dx)
                          .clamp(DelveDesktop.inspectorMin, inspectorMax)
                          .toDouble(),
                    ),
                    onReset: () => layouts.setInspector(
                      area,
                      DelveDesktop.inspectorDefault,
                    ),
                  ),
                ),
              if (at.listOverlay || at.inspectorOverlay)
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('pane.barrier'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => layouts.closeOverlays(area),
                  ),
                ),
              if (at.listOverlay)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: DelveDesktop.listDefault,
                  child: _Floating(
                    child: pane(
                      list!,
                      cs.surfaceContainerLow,
                      const Key('pane.list.overlay'),
                    ),
                  ),
                ),
              if (at.inspectorOverlay)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: DelveDesktop.inspectorDefault,
                  child: _Floating(
                    child: pane(
                      inspector!,
                      cs.surfaceContainerLow,
                      const Key('pane.inspector.overlay'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// An overlay pane: the one neutral shadow of floating layers, no scrim.
class _Floating extends StatelessWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(boxShadow: DelveTokens.elevation2),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

/// The edge between two panes: no line at rest, a 2 px `outline` line after
/// 150 ms of hover, `accent` while dragged; double-click resets the width.
class PaneDivider extends StatefulWidget {
  const PaneDivider({super.key, required this.onDrag, required this.onReset});

  /// The pointer moved by dx (positive: to the right).
  final ValueChanged<double> onDrag;
  final VoidCallback onReset;

  @override
  State<PaneDivider> createState() => _PaneDividerState();
}

class _PaneDividerState extends State<PaneDivider> {
  Timer? _hoverDelay;
  bool _hover = false;
  bool _dragging = false;

  @override
  void dispose() {
    _hoverDelay?.cancel();
    super.dispose();
  }

  void _enter() {
    _hoverDelay?.cancel();
    _hoverDelay = Timer(DelveDesktop.dividerHoverDelay, () {
      if (mounted) setState(() => _hover = true);
    });
  }

  void _exit() {
    _hoverDelay?.cancel();
    if (_hover) setState(() => _hover = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final color = _dragging
        ? cs.primary
        : _hover
        ? cs.outline
        : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => _enter(),
      onExit: (_) => _exit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // the whole movement counts, from the press on
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        onDoubleTap: widget.onReset,
        child: SizedBox(
          width: DelveDesktop.dividerGrab,
          child: Center(
            child: Container(width: DelveDesktop.dividerLine, color: color),
          ),
        ),
      ),
    );
  }
}

/// A pane's 48 px header: the title (Jost 16 / 22), then the trailing icon
/// buttons; in a page with an inspector its toggle is always the last one.
class PaneHeader extends StatelessWidget {
  const PaneHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.inspectorToggle = false,
  });

  final String title;
  final List<Widget> actions;

  /// Ends with the [InspectorToggle] (only where the page has an inspector).
  final bool inspectorToggle;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: DelveDesktop.paneHeader,
    child: Padding(
      padding: const EdgeInsets.only(left: 16, right: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DelveDesktopText.paneTitle.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
          ...actions,
          if (inspectorToggle) const InspectorToggle(),
        ],
      ),
    ),
  );
}

/// The only control that opens and closes a docked inspector (decision 8 of
/// the L plan): at the end of the content header, selected (`surface-3`)
/// while the inspector shows. Pages without an inspector have none.
class InspectorToggle extends ConsumerWidget {
  const InspectorToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = PaneScope.maybeOf(context);
    if (scope == null || !scope.hasInspector) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final open = scope.placement.inspectorShown;
    return Tooltip(
      message: l.desktopInspectorToggle,
      child: IconButton(
        key: const Key('pane.inspector.toggle'),
        isSelected: open,
        style: IconButton.styleFrom(
          backgroundColor: open ? cs.surfaceContainerHigh : null,
          foregroundColor: open ? cs.onSurface : cs.onSurfaceVariant,
        ),
        onPressed: () => ref
            .read(paneLayoutsProvider.notifier)
            .toggleInspector(
              scope.area,
              overlay:
                  MediaQuery.sizeOf(context).width <
                  DelveDesktop.inspectorOverlayBelow,
            ),
        icon: const SymbolIcon(
          DelveIcons.inspector,
          size: DelveDesktop.iconButtonIcon,
        ),
      ),
    );
  }
}

/// The overlay inspector's own close button (below 1232 it covers the
/// header's toggle); a docked inspector has none.
class InspectorOverlayClose extends ConsumerWidget {
  const InspectorOverlayClose({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = PaneScope.maybeOf(context);
    if (scope == null || !scope.placement.inspectorOverlay) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: const Key('pane.inspector.close'),
      tooltip: AppLocalizations.of(context).desktopInspectorClose,
      onPressed: () => ref
          .read(paneLayoutsProvider.notifier)
          .toggleInspector(scope.area, overlay: true),
      icon: const SymbolIcon(
        DelveIcons.close,
        size: DelveDesktop.iconButtonIcon,
      ),
    );
  }
}

/// A key in a key cap (tooltips, buttons with a shortcut): mono 10.5,
/// 18 high, `surface-3` with an `outline-variant` hairline.
class KeyCap extends StatelessWidget {
  const KeyCap(this.keys, {super.key});

  final String keys;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      height: DelveDesktop.keyCapHeight,
      constraints: const BoxConstraints(minWidth: DelveDesktop.keyCapHeight),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DelveDesktop.keyCapRadius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        keys,
        style: DelveDesktopText.keyCap.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

/// For tests and the shell: the logical keys of Ctrl+digit.
const Map<String, LogicalKeyboardKey> digitKeys = {
  '1': LogicalKeyboardKey.digit1,
  '2': LogicalKeyboardKey.digit2,
  '3': LogicalKeyboardKey.digit3,
  '4': LogicalKeyboardKey.digit4,
  '5': LogicalKeyboardKey.digit5,
  '6': LogicalKeyboardKey.digit6,
  '7': LogicalKeyboardKey.digit7,
  '8': LogicalKeyboardKey.digit8,
  '9': LogicalKeyboardKey.digit9,
  '0': LogicalKeyboardKey.digit0,
};
