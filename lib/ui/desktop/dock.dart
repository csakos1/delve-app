import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/terminal_service.dart';
import '../../terminal/terminal_tabs.dart';
import '../../theme/delve_theme.dart';
import '../screens/terminal_screen.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/terminal_tabs_ui.dart';
import '../widgets/terminal_ui.dart';
import 'areas.dart';
import 'desktop_prefs.dart';

/// The dock panel (Components “Dock panel”, 27W-2i): open or not, and its
/// height. Kept in `desktop.json` with the panes (Remember pane widths).
@immutable
class DockState {
  const DockState({this.open = false, this.height = DelveDesktop.dockDefault});

  final bool open;

  /// As the reader left it; the layout keeps it between 160 and 60 % of the
  /// content.
  final double height;

  DockState copyWith({bool? open, double? height}) =>
      DockState(open: open ?? this.open, height: height ?? this.height);

  @override
  bool operator ==(Object other) =>
      other is DockState && other.open == open && other.height == height;

  @override
  int get hashCode => Object.hash(open, height);
}

/// The dock as `desktop.json` keeps it.
Map<String, Object?> dockToJson(DockState d) => {
  'open': d.open,
  'height': d.height,
};

/// The file's dock; null when it has none (or a broken one).
DockState? dockFromJson(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final height = json['height'];
  return DockState(
    open: json['open'] == true,
    height: height is num
        ? math.max(DelveDesktop.dockMin, height.toDouble())
        : DelveDesktop.dockDefault,
  );
}

/// Whether the keyboard focus is in the dock (its terminal or its tab row):
/// there the keys are the terminal's (NL13) – the chat's and the list's keys
/// stand back.
bool focusInDock() {
  final c = FocusManager.instance.primaryFocus?.context;
  if (c == null) return false;
  return c.widget is TerminalDock ||
      c.findAncestorWidgetOfExactType<TerminalDock>() != null;
}

/// The dock: Ctrl+` opens it and moves the focus into it, from the dock
/// Shift+Esc gives the focus back to the pane above without closing it
/// (Esc itself stays the terminal's – vim, less, fzf). The terminal's
/// connection, scrollback and selection are the [TerminalService]'s: the
/// dock under another area shows the same tab, as it was (N450).
class DockController extends Notifier<DockState> {
  @override
  DockState build() {
    ref.onDispose(focusRequests.dispose);
    return const DockState();
  }

  /// A dock that is built asks for the focus when this ticks (one built
  /// later takes the request in its first frame: [takeFocusRequest]).
  final focusRequests = ValueNotifier<int>(0);

  bool _focusWanted = false;
  FocusNode? _returnTo;
  bool _touched = false;

  void _set(DockState next) {
    _touched = true;
    if (next == state) return;
    state = next;
    ref.read(desktopPrefsProvider.notifier).dockChanged(next);
  }

  /// The file's dock (at start), unless it was changed already.
  void restore(DockState kept) {
    if (!_touched) state = kept;
  }

  /// Opens the dock; [focus]: and moves the focus into it ([rememberFocus]:
  /// Shift+Esc goes back to where it was).
  void show({bool focus = false, bool rememberFocus = true}) {
    if (focus) _askFocus(remember: rememberFocus);
    if (!state.open) _set(state.copyWith(open: true));
  }

  /// Closes the dock (its sessions keep running); the focus goes back.
  void hide() {
    if (focusInDock()) returnFocus();
    if (state.open) _set(state.copyWith(open: false));
  }

  /// Ctrl+`: closed → open, with the focus in it; open without the focus →
  /// the focus into it; open with the focus → closed.
  void keyToggle() {
    if (!state.open) {
      show(focus: true);
    } else if (!focusInDock()) {
      _askFocus(remember: true);
    } else {
      hide();
    }
  }

  /// The dragged or reset height (the layout clamps it first).
  void setHeight(double height) =>
      _set(state.copyWith(height: height.roundToDouble()));

  double? _dragBase;

  /// A drag on the edge starts at the height shown ([resizeBy] counts from
  /// there, so the gesture's slop is not lost).
  void beginResize(double shown) => _dragBase = shown;

  /// The pointer is [dy] from where the drag went down (negative: up, the
  /// dock grows); [max]: 60 % of the content.
  void resizeBy(double dy, double max) => setHeight(
    ((_dragBase ?? state.height) - dy)
        .clamp(DelveDesktop.dockMin, max)
        .toDouble(),
  );

  void _askFocus({required bool remember}) {
    final now = FocusManager.instance.primaryFocus;
    _returnTo = remember && now != null && !focusInDock() ? now : null;
    _focusWanted = true;
    focusRequests.value++;
  }

  /// The dock's terminal takes a pending focus request (once).
  bool takeFocusRequest() {
    final wanted = _focusWanted;
    _focusWanted = false;
    return wanted;
  }

  /// Shift+Esc in the dock: the focus back where it was before the dock
  /// took it, else out of the dock (the page's own scope).
  void returnFocus() {
    final back = _returnTo;
    _returnTo = null;
    // a scope (a page with nothing focused) would hand the focus to its last
    // focused child – the dock itself; then the dock just lets go
    if (back != null &&
        back is! FocusScopeNode &&
        back.context != null &&
        back.canRequestFocus) {
      back.requestFocus();
      return;
    }
    final now = FocusManager.instance.primaryFocus;
    if (now != null && focusInDock()) now.unfocus();
  }
}

final dockProvider = NotifierProvider<DockController, DockState>(
  DockController.new,
);

/// The Terminal area's `dock_to_bottom` (and Ctrl+` there): the tab goes to
/// the dock, under the place shown last outside the Terminal area.
void dockTerminal(BuildContext context, WidgetRef ref) {
  ref.read(dockProvider.notifier).show(focus: true, rememberFocus: false);
  context.go(ref.read(desktopPlacesProvider).outsideTerminal());
}

/// The dock's `open_in_full`: the tab to the Terminal area; the dock closes.
void undockTerminal(BuildContext context, WidgetRef ref) {
  ref.read(dockProvider.notifier).hide();
  context.go(Routes.terminal);
}

/// An area's content pane with the dock under it (the list column and the
/// inspector keep their height): only with Terminal on (Settings → Desktop
/// tools) and not in the Terminal area itself. The content keeps its place
/// in the tree whether the dock shows or not (a chat's draft survives).
class DockedContent extends ConsumerWidget {
  const DockedContent({super.key, required this.area, required this.child});

  /// The area's key ([DesktopArea.name]).
  final String area;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(desktopToolsProvider);
    final dock = ref.watch(dockProvider);
    final shown = tools && dock.open && area != DesktopArea.terminal.name;
    return LayoutBuilder(
      builder: (context, box) {
        final max = dockMaxHeight(box.maxHeight);
        final height = dock.height.clamp(DelveDesktop.dockMin, max).toDouble();
        final controller = ref.read(dockProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: child),
            if (shown)
              SizedBox(
                key: const Key('dock'),
                height: height,
                child: TerminalDock(
                  onDragStart: () => controller.beginResize(height),
                  onDrag: (dy) => controller.resizeBy(dy, max),
                  onReset: () => controller.setHeight(
                    DelveDesktop.dockDefault
                        .clamp(DelveDesktop.dockMin, max)
                        .toDouble(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The dock's highest: 60 % of the content, never under its minimum.
double dockMaxHeight(double content) => math.max(
  DelveDesktop.dockMin,
  (content * DelveDesktop.dockMaxShare).floorToDouble(),
);

/// The dock panel: the edge (an `outline-variant` hairline with the 36 × 4
/// handle; drag: the height, double-click: 262), then the terminal with its
/// 34 px tab row ([TerminalScreen] in its dock form).
class TerminalDock extends StatelessWidget {
  const TerminalDock({
    super.key,
    required this.onDragStart,
    required this.onDrag,
    required this.onReset,
  });

  final VoidCallback onDragStart;

  /// The pointer is dy from where the drag went down (negative: up).
  final ValueChanged<double> onDrag;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DockEdge(onDragStart: onDragStart, onDrag: onDrag, onReset: onReset),
      const Expanded(child: TerminalScreen(dock: true)),
    ],
  );
}

/// The dock's top edge: the one hairline between panes (`outline-variant`;
/// hover `outline` after 150 ms, dragging `accent`, 2 px), the handle pill
/// on it; row-resize cursor over the whole grab area.
class _DockEdge extends StatefulWidget {
  const _DockEdge({
    required this.onDragStart,
    required this.onDrag,
    required this.onReset,
  });

  final VoidCallback onDragStart;
  final ValueChanged<double> onDrag;
  final VoidCallback onReset;

  @override
  State<_DockEdge> createState() => _DockEdgeState();
}

class _DockEdgeState extends State<_DockEdge> {
  Timer? _hoverDelay;
  bool _hover = false;
  bool _dragging = false;

  /// Where the drag went down (global y).
  double _startY = 0;

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
    final active = _dragging || _hover;
    final line = _dragging
        ? cs.primary
        : _hover
        ? cs.outline
        : cs.outlineVariant;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => _enter(),
      onExit: (_) => _exit(),
      child: GestureDetector(
        key: const Key('dock.handle'),
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (d) {
          _startY = d.globalPosition.dy;
          widget.onDragStart();
          setState(() => _dragging = true);
        },
        onVerticalDragUpdate: (d) =>
            widget.onDrag(d.globalPosition.dy - _startY),
        onVerticalDragEnd: (_) => setState(() => _dragging = false),
        onVerticalDragCancel: () => setState(() => _dragging = false),
        onDoubleTap: widget.onReset,
        child: SizedBox(
          height: DelveDesktop.dividerGrab,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Container(
                    height: active ? DelveDesktop.dividerLine : 1,
                    color: line,
                  ),
                  Expanded(child: ColoredBox(color: cs.surfaceContainerLow)),
                ],
              ),
              Container(
                width: DelveDesktop.dockHandleWidth,
                height: DelveDesktop.dockHandleHeight,
                decoration: BoxDecoration(
                  color: _dragging ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dock's 34 px tab row on `surface-1`: the tabs (dot + session name in
/// mono 12.5, a 2 px accent underline on the active one; right-click: the
/// tab's menu), `add`, then right-aligned “ssh host · tmux · cols × rows”,
/// `open_in_full` (to the Terminal area) and `close`.
class DockTabRow extends StatefulWidget {
  const DockTabRow({
    super.key,
    required this.service,
    required this.onSelect,
    required this.onNew,
    required this.onOpenInFull,
    required this.onClose,
  });

  final TerminalService service;
  final ValueChanged<int> onSelect;
  final VoidCallback onNew;
  final VoidCallback onOpenInFull;
  final VoidCallback onClose;

  @override
  State<DockTabRow> createState() => _DockTabRowState();
}

class _DockTabRowState extends State<DockTabRow> {
  /// The size shown: the terminal knows its columns and rows after its
  /// layout, which comes after this row's in the frame.
  (int, int)? _shown;

  (int, int)? _size() {
    final t = widget.service.current?.connection.terminal;
    return t == null ? null : (t.viewWidth, t.viewHeight);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final service = widget.service;
    final tabs = service.tabs;
    final size = _shown = _size();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _size() != _shown) setState(() {});
    });
    final host = service.config.host;
    final info = [
      if (host.isNotEmpty) 'ssh $host',
      'tmux',
      if (size != null && service.current != null) '${size.$1} × ${size.$2}',
    ].join(' · ');
    Widget button(Key key, IconData icon, String tip, VoidCallback onTap) =>
        IconButton(
          key: key,
          tooltip: tip,
          onPressed: onTap,
          icon: SymbolIcon(icon, size: DelveDesktop.dockIcon),
        );
    return Container(
      key: const Key('dock.tabs'),
      height: DelveDesktop.dockTabRow,
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    _DockTab(
                      tab: tabs[i],
                      active: i == service.activeIndex,
                      onTap: () => widget.onSelect(i),
                      onMenu: (at) => unawaited(
                        showTabMenu(
                          context,
                          service: service,
                          tab: tabs[i],
                          at: at,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          button(
            const Key('dock.new'),
            DelveIcons.add,
            l.termNewTab,
            widget.onNew,
          ),
          const Spacer(),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                info,
                key: const Key('dock.info'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DelveText.monoSmall.copyWith(color: d.textMuted),
              ),
            ),
          ),
          button(
            const Key('dock.openInFull'),
            DelveIcons.openInFull,
            l.desktopDockOpenInFull,
            widget.onOpenInFull,
          ),
          button(
            const Key('dock.close'),
            DelveIcons.close,
            l.desktopDockClose,
            widget.onClose,
          ),
        ],
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.tab,
    required this.active,
    required this.onTap,
    required this.onMenu,
  });

  final TerminalTab tab;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<Rect> onMenu;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('dock.tab.${tab.session}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onSecondaryTapUp: (_) {
          final box = context.findRenderObject();
          if (box is! RenderBox || !box.hasSize) return;
          onMenu(box.localToGlobal(Offset.zero) & box.size);
        },
        child: SizedBox(
          height: DelveDesktop.dockTabRow,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConnectionDot(phase: tab.connection.phase),
                    const SizedBox(width: 7),
                    Text(
                      tab.session,
                      style: DelveText.mono.copyWith(
                        fontSize: DelveDesktop.dockFontSize,
                        height: 16 / DelveDesktop.dockFontSize,
                        color: active ? cs.onSurface : cs.onSurfaceVariant,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Positioned(
                  key: const Key('dock.tab.underline'),
                  left: 10,
                  right: 10,
                  bottom: 0,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dock while the terminal cannot show (not set up yet, refused, or
/// locked): one line and the way to the Terminal area, where it is done.
class DockNotReady extends StatelessWidget {
  const DockNotReady({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      key: const Key('dock.notReady'),
      color: context.colors.surfaceContainerLowest,
      child: Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              l.desktopDockNotReady,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            OutlinedButton(
              key: const Key('dock.notReady.open'),
              onPressed: onOpen,
              child: Text(l.desktopDockOpenTerminal),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dock key: Ctrl and the key left of 1 (under Esc), whatever the
/// layout makes of it – `` ` `` on a US keyboard, `0` on a Hungarian one.
class DockKeyActivator extends ShortcutActivator {
  const DockKeyActivator();

  @override
  Iterable<LogicalKeyboardKey>? get triggers => null;

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      event is KeyDownEvent &&
      (event.physicalKey == PhysicalKeyboardKey.backquote ||
          event.logicalKey == LogicalKeyboardKey.backquote) &&
      state.isControlPressed &&
      !state.isShiftPressed &&
      !state.isAltPressed &&
      !state.isMetaPressed;

  @override
  String debugDescribeKeys() => 'Ctrl+`';
}
