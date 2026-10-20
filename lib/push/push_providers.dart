import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/session.dart';
import '../sync/sync_providers.dart';
import 'local_notifications.dart';
import 'push_controller.dart';
import 'push_transport.dart';

/// Widget tests turn push off (no Firebase, no notification plugin).
final pushEnabledProvider = Provider<bool>((ref) => true);

final pushTransportProvider = Provider<PushTransport>(
  (ref) => FirebasePushTransport(),
);

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
  final controller = PushController(
    api: api,
    transport: ref.watch(pushTransportProvider),
    notifications: notifications,
    visibleChat: () => ref.read(syncEngineProvider)?.focus,
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
