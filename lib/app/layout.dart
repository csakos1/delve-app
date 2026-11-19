import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/delve_desktop.dart';
import 'platform.dart';
import 'router.dart';

/// Whether [caps] at a window [width] (dp) uses the desktop layout (L2): a
/// computer and at least 720 dp. The phone never does; a narrower window on
/// the computer keeps the phone layout unchanged.
bool desktopLayoutFor(PlatformCaps caps, double width) =>
    !caps.phone && width >= DelveDesktop.windowMinWidth;

/// The app window's width in dp (0 before the first frame).
double windowWidth() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final view =
      dispatcher.implicitView ??
      (dispatcher.views.isEmpty ? null : dispatcher.views.first);
  if (view == null || view.devicePixelRatio == 0) return 0;
  return view.physicalSize.width / view.devicePixelRatio;
}

/// Which layout runs: true = the desktop shell (rail, panes, status bar).
/// [DelveApp] updates it when the window is resized across 720 dp.
class DesktopLayoutMode extends Notifier<bool> {
  @override
  bool build() =>
      desktopLayoutFor(ref.watch(platformCapsProvider), windowWidth());

  void update(double width) {
    final next = desktopLayoutFor(ref.read(platformCapsProvider), width);
    if (next != state) state = next;
  }
}

final desktopLayoutProvider = NotifierProvider<DesktopLayoutMode, bool>(
  DesktopLayoutMode.new,
);

/// Ctrl+F in the desktop layout: each press counts up; the open list's
/// search (Chats) listens and opens its field.
class DesktopFind extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final desktopFindProvider = NotifierProvider<DesktopFind, int>(DesktopFind.new);

/// Marks everything under the desktop shell: screens shared with the phone
/// ask [DesktopLayout.of] where they run (no back arrow where nothing is
/// pushed; [DelveNav.open] goes instead of pushing).
class DesktopLayout extends InheritedWidget {
  const DesktopLayout({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DesktopLayout>() != null;

  @override
  bool updateShouldNotify(DesktopLayout oldWidget) => false;
}

extension DelveNav on BuildContext {
  /// Opens [location]: on the phone it is pushed (back returns here, as
  /// before); in the desktop layout the router goes there – an area's own
  /// pages stack under it, so its back arrow stays inside the area.
  void open(String location, {Object? extra}) {
    if (DesktopLayout.of(this)) {
      go(location, extra: extra);
    } else {
      unawaited(push<void>(location, extra: extra));
    }
  }
}

/// Leaves a page whose subject is gone (an archived or deleted chat): back
/// where it was pushed from, as before; in the desktop layout, where nothing
/// is under it, to [fallback].
void leavePage(BuildContext context, {required String fallback}) {
  final navigator = Navigator.of(context);
  if (DesktopLayout.of(context) && !navigator.canPop()) {
    context.go(fallback);
    return;
  }
  unawaited(navigator.maybePop());
}

/// Where the desktop router goes for a phone [location] (when the window
/// grows past 720 dp): More and the phone-only pages become the Dashboard,
/// Share becomes Chats.
String desktopLocation(String location) {
  final path = Uri.parse(location).path;
  if (path == Routes.more || path.startsWith(Routes.mirroring)) {
    return Routes.dashboard;
  }
  if (path.startsWith(Routes.share)) return Routes.chats;
  return location;
}

/// Where the phone router goes for a desktop [location] (when the window
/// shrinks below 720 dp): the paths are the phone's, a new chat drops its
/// kind (the phone remembers its own).
String phoneLocation(String location) {
  final uri = Uri.parse(location);
  if (uri.path == Routes.newChat) return Routes.newChat;
  return location;
}
