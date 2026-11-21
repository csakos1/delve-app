import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xterm/xterm.dart' show TerminalView;

import '../../app/inbox.dart';
import '../../app/layout.dart';
import '../../app/platform.dart';
import '../../app/router.dart';
import '../../theme/delve_theme.dart';
import 'approval_notice.dart';
import 'areas.dart';
import 'chat_inspector.dart';
import 'desktop_page.dart';
import 'desktop_row.dart' show SelectedRows;
import 'dock.dart';
import 'files_area.dart' show fileInspectorTabProvider;
import 'intake.dart';
import 'layers.dart' show LayerMark;
import 'palette.dart';
import 'pane_focus.dart';
import 'panes.dart';
import 'rail.dart';
import 'shortcut_sheet.dart';
import 'status_bar.dart';

/// Where Ctrl+N goes: a new chat of [kind] (`agent` or `general`).
String newChatLocation(String kind) =>
    Uri(path: Routes.newChat, queryParameters: {'kind': kind}).toString();

class _AreaIntent extends Intent {
  const _AreaIntent(this.digit);
  final String digit;
}

class _GoIntent extends Intent {
  const _GoIntent(this.location);
  final String location;
}

class _ToggleListIntent extends Intent {
  const _ToggleListIntent();
}

class _ToggleInspectorIntent extends Intent {
  const _ToggleInspectorIntent();
}

class _CloseOverlayIntent extends Intent {
  const _CloseOverlayIntent();
}

class _FindIntent extends Intent {
  const _FindIntent();
}

class _UsageIntent extends Intent {
  const _UsageIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

/// Ctrl+` (the key under Esc): the dock panel (L2c4b).
class _DockIntent extends Intent {
  const _DockIntent();
}

/// Ctrl+K: the command palette (L2d1).
class _PaletteIntent extends Intent {
  const _PaletteIntent();
}

/// ?: the shortcut sheet (L2d1).
class _SheetIntent extends Intent {
  const _SheetIntent();
}

/// Ctrl+M: the local model picker (L2d3).
class _ModelIntent extends Intent {
  const _ModelIntent();
}

/// ? types itself in a text field and in a terminal (the Terminal area's
/// or the dock's); an editor keeps it out too.
class _SheetAction extends Action<_SheetIntent> {
  _SheetAction(this._open);

  final VoidCallback _open;

  @override
  bool isEnabled(_SheetIntent intent) =>
      !focusInTextField() && !focusInEditor() && !_focusInTerminal();

  @override
  Object? invoke(_SheetIntent intent) {
    _open();
    return null;
  }
}

/// F6 / Shift+F6: the next / previous pane (L2d2).
class _PaneIntent extends Intent {
  const _PaneIntent(this.by);
  final int by;
}

/// Enter on a pane (L2d2).
class _EnterIntent extends Intent {
  const _EnterIntent();
}

/// Shift+F10 / the menu key: the selected row's menu (L2d2).
class _RowMenuIntent extends Intent {
  const _RowMenuIntent();
}

/// The shell's own focus point: what holds the focus when nothing else
/// does.
const _shellFocusKey = Key('desktop.focus');

/// Nothing in particular has the focus: the shell, a pane itself or a
/// page's route scope (a field or a button keeps its own Enter).
bool _focusOnShellOrPane() {
  if (PaneFocus.onPane()) return true;
  final f = FocusManager.instance.primaryFocus;
  // a route's scope: the page itself, after a menu of its navigator closed
  if (f is FocusScopeNode) return true;
  return f?.context?.widget.key == _shellFocusKey;
}

/// A context menu or a popover is open over the shell (the focus stays
/// below it): Esc is the layer's, the pane keys wait.
bool _layerUp() => LayerMark.open > 0;

/// The panes in F6 order: the list, the content, the dock (open, outside
/// the Terminal area), the inspector; from the shell F6 starts at the first.
void _cyclePanes(WidgetRef ref, String? area, int by) {
  final dock =
      ref.read(desktopToolsProvider) &&
      ref.read(dockProvider).open &&
      area != DesktopArea.terminal.name;
  final stops = <Object>[
    for (final role in PaneRole.values) ...[
      if (PaneFocus.has(role)) role,
      if (role == PaneRole.content && dock) 'dock',
    ],
  ];
  if (stops.isEmpty) return;
  final Object? now = focusInDock() ? 'dock' : PaneFocus.focused();
  final at = stops.indexOf(now ?? '');
  final next = at < 0
      ? (by > 0 ? 0 : stops.length - 1)
      : (at + by) % stops.length;
  final stop = stops[next];
  if (stop is PaneRole) {
    PaneFocus.focus(stop);
  } else {
    ref.read(dockProvider.notifier).show(focus: true);
  }
}

/// Enter on a pane: the selected row's own Enter (a hit's link) if it has
/// one; from the list (or the shell) into the content – at the composer if
/// the content has one.
class _EnterAction extends Action<_EnterIntent> {
  VoidCallback? _what() {
    if (_layerUp() || !_focusOnShellOrPane()) return null;
    final role = PaneFocus.focused() ?? PaneFocus.last ?? PaneRole.list;
    final open = SelectedRows.openIn(role);
    if (open != null) return open;
    if (role == PaneRole.list && PaneFocus.has(PaneRole.content)) {
      return enterContent;
    }
    return null;
  }

  @override
  bool isEnabled(_EnterIntent intent) => _what() != null;

  @override
  Object? invoke(_EnterIntent intent) {
    _what()?.call();
    return null;
  }
}

/// Shift+F10: the menu of the selected row in the focused pane (the list
/// when no pane has the focus); a text field keeps its own.
class _RowMenuAction extends Action<_RowMenuIntent> {
  PaneRole get _role => PaneFocus.focused() ?? PaneFocus.last ?? PaneRole.list;

  @override
  bool isEnabled(_RowMenuIntent intent) =>
      !_layerUp() && !focusInTextField() && SelectedRows.hasMenuIn(_role);

  @override
  Object? invoke(_RowMenuIntent intent) {
    SelectedRows.showMenuIn(_role);
    return null;
  }
}

/// The focus is in a terminal: the Terminal area's or the dock's.
bool _focusInTerminal() {
  final c = FocusManager.instance.primaryFocus?.context;
  if (c == null) return false;
  return c.widget is TerminalView ||
      c.findAncestorWidgetOfExactType<TerminalView>() != null ||
      focusInDock();
}

/// Ctrl+R: the open page's refresh (L2c), where it has one.
class _RefreshAction extends Action<_RefreshIntent> {
  _RefreshAction(this._slot);

  final PageCommandSlot _slot;

  @override
  bool isEnabled(_RefreshIntent intent) => _slot.current != null;

  @override
  Object? invoke(_RefreshIntent intent) {
    _slot.current?.refresh();
    return null;
  }
}

/// A key of the open list (J / K / ↓ / ↑, E, Ctrl+Z – L2b2).
enum _ListKey { next, previous, archive, undo }

class _ListKeyIntent extends Intent {
  const _ListKeyIntent(this.key);
  final _ListKey key;
}

/// The list's keys: only outside text fields (they type there, and Ctrl+Z
/// undoes typing), editors (N515) and the dock (the terminal's keys).
class _ListKeyAction extends Action<_ListKeyIntent> {
  _ListKeyAction(this._slot);

  final ListCommandSlot _slot;

  @override
  bool isEnabled(_ListKeyIntent intent) =>
      _slot.current != null &&
      !focusInTextField() &&
      !focusInEditor() &&
      !focusInDock();

  @override
  Object? invoke(_ListKeyIntent intent) {
    final c = _slot.current;
    if (c == null) return null;
    switch (intent.key) {
      case _ListKey.next:
        c.next();
      case _ListKey.previous:
        c.previous();
      case _ListKey.archive:
        c.archive();
      case _ListKey.undo:
        c.undo();
    }
    return null;
  }
}

/// A key of the open chat (Ctrl+O, Ctrl+V, Ctrl+., Ctrl+T – L2b2).
enum _ChatKey { attach, paste, stop, thinking }

class _ChatKeyIntent extends Intent {
  const _ChatKeyIntent(this.key);
  final _ChatKey key;
}

/// The open chat's keys: enabled only while a chat is open (Ctrl+V also
/// not in a text field, which pastes its own way), and never while the
/// focus is in the dock – there the keys are the terminal's (NL13).
class _ChatKeyAction extends Action<_ChatKeyIntent> {
  _ChatKeyAction(this._slot);

  final ChatCommandSlot _slot;

  @override
  bool isEnabled(_ChatKeyIntent intent) =>
      _slot.current != null &&
      !focusInDock() &&
      (intent.key != _ChatKey.paste || !focusInTextField());

  @override
  Object? invoke(_ChatKeyIntent intent) {
    final c = _slot.current;
    if (c == null) return null;
    switch (intent.key) {
      case _ChatKey.attach:
        c.attachFile();
      case _ChatKey.paste:
        unawaited(c.paste());
      case _ChatKey.stop:
        c.stop();
      case _ChatKey.thinking:
        c.toggleThinking();
    }
    return null;
  }
}

/// The desktop layout (design 27 Workbench, L2a): the rail, the current
/// area's page and the status bar under both. The window keys live here:
/// Ctrl+1…0 the areas (Ctrl+1 the Inbox, with a server that has it), Ctrl+N
/// / Ctrl+Shift+N a new Agent / General chat,
/// Ctrl+, Settings, Ctrl+B the list column, Ctrl+I the inspector, Esc an
/// open overlay pane; Ctrl+F the list's search, Ctrl+U a chat's Usage,
/// Ctrl+] the inspector's next tab, Ctrl+R the open page's refresh, Ctrl+K
/// the command palette, ? the shortcut sheet (outside text fields), Ctrl+M
/// the local model picker over the status bar's model; in an
/// open chat Ctrl+O attaches a file,
/// Ctrl+V an image, Ctrl+. stops the run, Ctrl+T switches Thinking; Ctrl+`
/// the dock (with Terminal on; in the Terminal area it sends the tab to the
/// dock). No title bar: the compositor draws the window.
class DesktopShell extends ConsumerWidget {
  const DesktopShell({super.key, required this.location, required this.child});

  /// The router's location.
  final String location;

  /// The area's page.
  final Widget child;

  static final Map<ShortcutActivator, Intent> _keys = {
    for (final e in digitKeys.entries)
      SingleActivator(e.value, control: true): _AreaIntent(e.key),
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): _GoIntent(
      newChatLocation('agent'),
    ),
    const SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true):
        _GoIntent(newChatLocation('general')),
    const SingleActivator(LogicalKeyboardKey.comma, control: true):
        const _GoIntent(Routes.settings),
    const SingleActivator(LogicalKeyboardKey.keyB, control: true):
        const _ToggleListIntent(),
    const SingleActivator(LogicalKeyboardKey.keyI, control: true):
        const _ToggleInspectorIntent(),
    const SingleActivator(LogicalKeyboardKey.escape):
        const _CloseOverlayIntent(),
    const SingleActivator(LogicalKeyboardKey.keyF, control: true):
        const _FindIntent(),
    const SingleActivator(LogicalKeyboardKey.keyU, control: true):
        const _UsageIntent(),
    const SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
        const _NextTabIntent(),
    const SingleActivator(LogicalKeyboardKey.keyR, control: true):
        const _RefreshIntent(),
    const SingleActivator(LogicalKeyboardKey.keyK, control: true):
        const _PaletteIntent(),
    const CharacterActivator('?'): const _SheetIntent(),
    const SingleActivator(LogicalKeyboardKey.keyM, control: true):
        const _ModelIntent(),
    const SingleActivator(LogicalKeyboardKey.f6): const _PaneIntent(1),
    const SingleActivator(LogicalKeyboardKey.f6, shift: true):
        const _PaneIntent(-1),
    const SingleActivator(LogicalKeyboardKey.enter): const _EnterIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadEnter): const _EnterIntent(),
    const SingleActivator(LogicalKeyboardKey.f10, shift: true):
        const _RowMenuIntent(),
    const SingleActivator(LogicalKeyboardKey.contextMenu):
        const _RowMenuIntent(),
    const SingleActivator(LogicalKeyboardKey.keyO, control: true):
        const _ChatKeyIntent(_ChatKey.attach),
    const SingleActivator(LogicalKeyboardKey.keyV, control: true):
        const _ChatKeyIntent(_ChatKey.paste),
    const SingleActivator(LogicalKeyboardKey.period, control: true):
        const _ChatKeyIntent(_ChatKey.stop),
    const SingleActivator(LogicalKeyboardKey.keyT, control: true):
        const _ChatKeyIntent(_ChatKey.thinking),
    const SingleActivator(LogicalKeyboardKey.keyJ): const _ListKeyIntent(
      _ListKey.next,
    ),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const _ListKeyIntent(
      _ListKey.next,
    ),
    const SingleActivator(LogicalKeyboardKey.keyK): const _ListKeyIntent(
      _ListKey.previous,
    ),
    const SingleActivator(LogicalKeyboardKey.arrowUp): const _ListKeyIntent(
      _ListKey.previous,
    ),
    const SingleActivator(LogicalKeyboardKey.keyE): const _ListKeyIntent(
      _ListKey.archive,
    ),
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
        const _ListKeyIntent(_ListKey.undo),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = DesktopArea.of(location)?.name;
    final layouts = ref.read(paneLayoutsProvider.notifier);
    // every place shown is remembered: an area opens again where it was left
    final places = ref.read(desktopPlacesProvider)..remember(location);
    double width() => MediaQuery.sizeOf(context).width;
    return DesktopLayout(
      child: Shortcuts(
        shortcuts: _keys,
        child: Actions(
          actions: {
            _AreaIntent: CallbackAction<_AreaIntent>(
              onInvoke: (i) {
                final target = DesktopArea.ofDigit(i.digit);
                if (target == null) return null;
                if (target.tool && !ref.read(desktopToolsProvider)) {
                  return null;
                }
                // the Inbox only with a server that has it (API 23)
                if (target == DesktopArea.inbox &&
                    !ref.read(inboxSupportedProvider)) {
                  return null;
                }
                context.go(places.target(target, location));
                return null;
              },
            ),
            _GoIntent: CallbackAction<_GoIntent>(
              onInvoke: (i) {
                context.go(i.location);
                return null;
              },
            ),
            _ToggleListIntent: CallbackAction<_ToggleListIntent>(
              onInvoke: (_) {
                if (area != null) {
                  layouts.toggleList(
                    area,
                    overlay: width() < DelveDesktop.listOverlayBelow,
                  );
                }
                return null;
              },
            ),
            _ToggleInspectorIntent: CallbackAction<_ToggleInspectorIntent>(
              onInvoke: (_) {
                if (area != null) {
                  layouts.toggleInspector(
                    area,
                    overlay: width() < DelveDesktop.inspectorOverlayBelow,
                  );
                }
                return null;
              },
            ),
            _FindIntent: CallbackAction<_FindIntent>(
              onInvoke: (_) {
                // an open chat searches itself (L2b2), else the list
                final find = ref.read(chatCommandSlotProvider).current?.find;
                if (find != null) {
                  find();
                } else {
                  ref.read(desktopFindProvider.notifier).request();
                }
                return null;
              },
            ),
            _UsageIntent: CallbackAction<_UsageIntent>(
              onInvoke: (_) {
                final path = Uri.parse(location).path;
                if (area == DesktopArea.chats.name &&
                    (path.startsWith('${Routes.chats}/c/') ||
                        path.startsWith('${Routes.chats}/g/'))) {
                  showChatInspectorTab(
                    ref,
                    context,
                    area!,
                    ChatInspectorTab.usage,
                  );
                }
                return null;
              },
            ),
            _NextTabIntent: CallbackAction<_NextTabIntent>(
              onInvoke: (_) {
                if (area == DesktopArea.files.name) {
                  ref.read(fileInspectorTabProvider.notifier).next();
                } else {
                  ref.read(chatInspectorTabProvider.notifier).next();
                }
                return null;
              },
            ),
            _ChatKeyIntent: _ChatKeyAction(ref.read(chatCommandSlotProvider)),
            _RefreshIntent: _RefreshAction(ref.read(pageCommandSlotProvider)),
            _ListKeyIntent: _ListKeyAction(ref.read(listCommandSlotProvider)),
            _CloseOverlayIntent: _CloseOverlayAction(
              () {
                if (area != null && _hasOverlay(ref, area, width())) {
                  return layouts.closeOverlays(area);
                }
                // from the content back to the list (L2d2)
                return PaneFocus.focus(PaneRole.list);
              },
              () =>
                  !_layerUp() &&
                  ((area != null && _hasOverlay(ref, area, width())) ||
                      (PaneFocus.focused() == PaneRole.content &&
                          PaneFocus.has(PaneRole.list))),
            ),
            _PaneIntent: CallbackAction<_PaneIntent>(
              onInvoke: (i) {
                if (!_layerUp()) _cyclePanes(ref, area, i.by);
                return null;
              },
            ),
            _EnterIntent: _EnterAction(),
            _RowMenuIntent: _RowMenuAction(),
            _PaletteIntent: CallbackAction<_PaletteIntent>(
              onInvoke: (_) {
                unawaited(showCommandPalette(context, location: location));
                return null;
              },
            ),
            _SheetIntent: _SheetAction(
              () => unawaited(showShortcutSheet(context)),
            ),
            _ModelIntent: CallbackAction<_ModelIntent>(
              onInvoke: (_) {
                openModelPicker(ref);
                return null;
              },
            ),
            _DockIntent: CallbackAction<_DockIntent>(
              onInvoke: (_) {
                if (!ref.read(desktopToolsProvider)) return null;
                if (area == DesktopArea.terminal.name) {
                  dockTerminal(context, ref);
                } else {
                  ref.read(dockProvider.notifier).keyToggle();
                }
                return null;
              },
            ),
          },
          // closer to the focus than the area keys: on a Hungarian layout
          // the key under Esc is also Ctrl+0
          child: Shortcuts(
            shortcuts: const {DockKeyActivator(): _DockIntent()},
            child: Focus(
              key: _shellFocusKey,
              autofocus: true,
              child: Material(
                color: context.colors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DesktopRail(location: location),
                          // the in-app approval notice over the area, at
                          // its bottom right (L2d4)
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(child: child),
                                Positioned(
                                  right: DelveDesktop.noticeInset,
                                  bottom: DelveDesktop.noticeInset,
                                  child: ApprovalNotice(location: location),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const DesktopStatusBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// An overlay pane shows: the list below 900, the inspector below 1232.
  static bool _hasOverlay(WidgetRef ref, String area, double width) {
    final p = ref.read(paneLayoutsProvider.notifier).of(area);
    return (p.listOverlay && width < DelveDesktop.listOverlayBelow) ||
        (p.inspectorOverlay && width < DelveDesktop.inspectorOverlayBelow);
  }
}

/// Esc closes an overlay pane; with none open, from the content it goes
/// back to the list (L2d2); otherwise the key goes on (a dialog's or a text
/// field's own Esc).
class _CloseOverlayAction extends Action<_CloseOverlayIntent> {
  _CloseOverlayAction(this._close, this._enabled);

  final bool Function() _close;
  final bool Function() _enabled;

  @override
  bool isEnabled(_CloseOverlayIntent intent) => _enabled();

  @override
  Object? invoke(_CloseOverlayIntent intent) => _close();
}
