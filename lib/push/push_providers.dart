import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/platform.dart';
import '../app/session.dart';
import '../sync/sync_providers.dart';
import 'local_notifications.dart';
import 'push_controller.dart';
import 'push_transport.dart';

/// Push: Firebase on the phone, the socket on the desktop (L3); widget tests
/// turn it off (no Firebase, no notification plugin).
final pushEnabledProvider = Provider<bool>(
  (ref) => ref.watch(platformCapsProvider).notifications,
);

/// The phone: FCM. The desktop: the `push` frames of the open socket, only
/// while the window is not focused (an approval's removal always).
final pushTransportProvider = Provider<PushTransport>((ref) {
  if (ref.watch(platformCapsProvider).push) return FirebasePushTransport();
  final engine = ref.watch(syncEngineProvider);
  return SocketPushTransport(
    engine?.pushes ?? const Stream.empty(),
    focused: () =>
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
  );
});

final phoneNotificationsProvider = Provider<PhoneNotifications>(
  (ref) => LocalNotifications(),
);

/// Push for the paired server; null while not paired (or push is off).
/// Unpairing removes every notification this app showed.
final pushControllerProvider = Provider<PushController?>((ref) {
  if (!ref.watch(pushEnabledProvider)) return null;
  final paired = ref.watch(sessionProvider.select((s) => s is SessionPaired));
  final api = ref.watch(apiProvider);
  final notifications = ref.watch(phoneNotificationsProvider);
  if (!paired || api == null) {
    if (ref.read(sessionProvider) is SessionUnpaired) {
      unawaited(notifications.cancelAll());
    }
    return null;
  }
  // the desktop shows only what arrives while the window is not focused:
  // everything, as if the app were in the background
  final phone = ref.watch(platformCapsProvider).push;
  final controller = PushController(
    api: api,
    transport: ref.watch(pushTransportProvider),
    notifications: notifications,
    visibleChat: () => ref.read(syncEngineProvider)?.focus,
    inForeground: phone ? null : () => false,
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  unawaited(controller.start());
  return controller;
});

/// Settings → Notifications: can this phone get pushes, are they allowed.
final pushStateProvider = StreamProvider<PushState>((ref) async* {
  final controller = ref.watch(pushControllerProvider);
  if (controller == null) {
    yield const PushState(available: false);
    return;
  }
  yield controller.state;
  yield* controller.states;
});
