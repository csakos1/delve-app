import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/platform.dart';
import '../../app/router.dart';
import '../../theme/delve_theme.dart';
import 'areas.dart';
import 'chat_inspector.dart';
import 'intake.dart';
import 'panes.dart';
import 'rail.dart';
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

/// A key of the open list (J / K / ↓ / ↑, E, Ctrl+Z – L2b2).
enum _ListKey { next, previous, archive, undo }

class _ListKeyIntent extends Intent {
  const _ListKeyIntent(this.key);
  final _ListKey key;
}

/// The list's keys: only outside text fields (they type there, and Ctrl+Z
/// undoes typing).
class _ListKeyAction extends Action<_ListKeyIntent> {
  _ListKeyAction(this._slot);

  final ListCommandSlot _slot;

  @override
  bool isEnabled(_ListKeyIntent intent) =>
      _slot.current != null && !focusInTextField();

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
/// not in a text field, which pastes its own way).
class _ChatKeyAction extends Action<_ChatKeyIntent> {
  _ChatKeyAction(this._slot);

  final ChatCommandSlot _slot;

  @override
  bool isEnabled(_ChatKeyIntent intent) =>
      _slot.current != null &&
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
/// Ctrl+2…0 the areas, Ctrl+N / Ctrl+Shift+N a new Agent / General chat,
/// Ctrl+, Settings, Ctrl+B the list column, Ctrl+I the inspector, Esc an
/// open overlay pane; Ctrl+F the list's search, Ctrl+U a chat's Usage,
/// Ctrl+] the inspector's next tab; in an open chat Ctrl+O attaches a file,
/// Ctrl+V an image, Ctrl+. stops the run, Ctrl+T switches Thinking. No title
/// bar: the compositor draws the window.
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
                ref.read(chatInspectorTabProvider.notifier).next();
                return null;
              },
            ),
            _ChatKeyIntent: _ChatKeyAction(ref.read(chatCommandSlotProvider)),
            _ListKeyIntent: _ListKeyAction(ref.read(listCommandSlotProvider)),
            _CloseOverlayIntent: _CloseOverlayAction(
              () => area != null && layouts.closeOverlays(area),
              () => area != null && _hasOverlay(ref, area, width()),
            ),
          },
          child: Focus(
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
                        Expanded(child: child),
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
    );
  }

  /// An overlay pane shows: the list below 900, the inspector below 1232.
  static bool _hasOverlay(WidgetRef ref, String area, double width) {
    final p = ref.read(paneLayoutsProvider.notifier).of(area);
    return (p.listOverlay && width < DelveDesktop.listOverlayBelow) ||
        (p.inspectorOverlay && width < DelveDesktop.inspectorOverlayBelow);
  }
}

/// Esc closes an overlay pane; with none open the key goes on (a dialog's
/// or a text field's own Esc).
class _CloseOverlayAction extends Action<_CloseOverlayIntent> {
  _CloseOverlayAction(this._close, this._enabled);

  final bool Function() _close;
  final bool Function() _enabled;

  @override
  bool isEnabled(_CloseOverlayIntent intent) => _enabled();

  @override
  Object? invoke(_CloseOverlayIntent intent) => _close();
}
