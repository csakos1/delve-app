import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/platform.dart';
import '../../app/router.dart';
import '../../theme/delve_theme.dart';
import 'areas.dart';
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

/// The desktop layout (design 27 Workbench, L2a): the rail, the current
/// area's page and the status bar under both. The window keys live here:
/// Ctrl+2…0 the areas, Ctrl+N / Ctrl+Shift+N a new Agent / General chat,
/// Ctrl+, Settings, Ctrl+B the list column, Ctrl+I the inspector, Esc an
/// open overlay pane. No title bar: the compositor draws the window.
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
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = DesktopArea.of(location)?.name;
    final layouts = ref.read(paneLayoutsProvider.notifier);
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
                context.go(target.route);
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
