import 'dart:async';

import '../api/api_error.dart';
import '../api/models/models.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import 'background.dart';
import 'local_notifications.dart';
import 'notification_spec.dart';
import 'push_message.dart';
import 'push_transport.dart';

/// Push on this phone: null while unknown.
class PushState {
  const PushState({this.available, this.permitted});

  /// This build can receive pushes (Firebase is configured).
  final bool? available;

  /// Android lets Delve post notifications.
  final bool? permitted;

  PushState copyWith({bool? available, bool? permitted}) => PushState(
    available: available ?? this.available,
    permitted: permitted ?? this.permitted,
  );
}

/// What the UI does after a notification tap (the host navigates).
sealed class PushEvent {
  const PushEvent(this.target);
  final PushTarget target;
}

/// Open the chat (a tap, Open).
final class PushOpen extends PushEvent {
  const PushOpen(super.target);
}

/// Open link on a watch's notification: the listing in the browser.
final class PushOpenLink extends PushEvent {
  const PushOpenLink(super.target);
}

/// Allow once from the notification went through.
final class PushAnswered extends PushEvent {
  const PushAnswered(super.target, this.approval);
  final Approval approval;
}

/// Allow once from the notification failed.
final class PushAnswerFailed extends PushEvent {
  const PushAnswerFailed(super.target, this.error);
  final ApiError error;
}

/// Registers this phone's FCM token with the paired server, shows pushes
/// that arrive in the foreground and turns notification taps into
/// [PushEvent]s. One per pairing; created by `pushControllerProvider`.
class PushController {
  PushController({
    required this.api,
    required this.transport,
    required this.notifications,
    required this.visibleChat,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final DelveApi api;
  final PushTransport transport;
  final PhoneNotifications notifications;

  /// The chat on screen (its approvals show in the chat, not as a
  /// notification); null when none is.
  final String? Function() visibleChat;
  final DateTime Function() _now;

  final _events = StreamController<PushEvent>.broadcast();
  final _states = StreamController<PushState>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  PushState _state = const PushState();
  bool _started = false;
  bool _disposed = false;
  String? _sentToken;

  Stream<PushEvent> get events => _events.stream;
  Stream<PushState> get states => _states.stream;
  PushState get state => _state;

  void _set(PushState s) {
    _state = s;
    if (!_disposed) _states.add(s);
  }

  /// Taps are handled even without Firebase (a notification from before).
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subs.add(notifications.taps.listen((t) => unawaited(_onTap(t))));
    final launch = await notifications.launchTap();
    if (launch != null) unawaited(_onTap(launch));

    final available = await transport.init();
    if (_disposed) return;
    _set(_state.copyWith(available: available));
    if (!available) return;

    var permitted = await notifications.enabled();
    if (!permitted) permitted = await notifications.requestPermission();
    if (_disposed) return;
    _set(_state.copyWith(permitted: permitted));

    _subs
      ..add(transport.tokens.listen((t) => unawaited(_register(t))))
      ..add(
        transport.messages.listen(
          (data) => unawaited(
            handlePush(
              data,
              notifications,
              now: _now(),
              foreground: true,
              visibleChat: visibleChat(),
            ),
          ),
        ),
      );
    try {
      await transport.register(); // the token arrives on `tokens`
    } on Object {
      // FCM refused (no Play services, misconfigured build): no pushes, the
      // app works on; Settings says this phone cannot receive notifications
      if (!_disposed) _set(_state.copyWith(available: false));
    }
  }

  /// The Settings banner's "Allow".
  Future<bool> requestPermission() async {
    final ok = await notifications.requestPermission();
    _set(_state.copyWith(permitted: ok));
    return ok;
  }

  /// Re-reads the permission (back from the system settings).
  Future<void> refreshPermission() async {
    if (_state.available != true) return;
    _set(_state.copyWith(permitted: await notifications.enabled()));
  }

  Future<void> _register(String token) async {
    if (_disposed || token == _sentToken) return;
    try {
      await api.putFcmToken(token);
      _sentToken = token;
    } on ApiError {
      _sentToken = null; // tried again at the next start or refresh
    }
  }

  Future<void> _onTap(NotificationTap tap) async {
    final target = PushTarget.decode(tap.payload);
    if (target == null || _disposed) return;
    final requestId = target.requestId;
    final choice = switch (tap.actionId) {
      NotifyActions.allowOnce => ApprovalChoice.once,
      // Deny normally reaches the background handler; if the plugin hands it
      // to this isolate instead, answer here (a second answer gets 409)
      NotifyActions.deny => ApprovalChoice.deny,
      _ => null,
    };
    if (choice != null && requestId != null) {
      try {
        final a = await api.answerApproval(requestId, choice);
        await notifications.cancel(notificationId(requestId));
        if (!_disposed) _events.add(PushAnswered(target, a));
      } on ApiError catch (e) {
        if (e is ApiRequestError &&
            e.status == 409 &&
            choice == ApprovalChoice.deny) {
          await notifications.cancel(notificationId(requestId)); // done already
          return;
        }
        if (!_disposed) _events.add(PushAnswerFailed(target, e));
      }
      return;
    }
    if (tap.actionId == NotifyActions.openLink && target.url != null) {
      _events.add(PushOpenLink(target));
      return;
    }
    _events.add(PushOpen(target));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    await _events.close();
    await _states.close();
  }
}
