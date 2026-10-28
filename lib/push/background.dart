import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_error.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import '../data/credentials.dart';
import '../l10n/app_localizations.dart';
import '../ui/format.dart';
import 'local_notifications.dart';
import 'notification_spec.dart';
import 'push_message.dart';

// Entry points the system calls while the app is in the background or not
// running at all, each in an isolate of its own. They must be top-level and
// kept from tree shaking.

/// FCM data message while the app is not in the foreground.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessage(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await handlePush(
    Map<String, Object?>.from(message.data),
    LocalNotifications(),
    now: DateTime.now(),
  );
}

/// An action that does not open the app (Deny), from any isolate.
@pragma('vm:entry-point')
void notificationActionBackground(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(
    denyFromNotification(
      response.actionId,
      response.payload,
      store: SecureCredentialStore(),
      notifications: LocalNotifications(),
    ),
  );
}

/// One push: show, replace or remove its notification. [visibleChat] is the
/// chat on screen (foreground): its approvals show in the chat, not here.
/// [foreground]: a finished run is visible in the app, no notification.
Future<void> handlePush(
  Map<String, Object?> data,
  Notifications notifications, {
  required DateTime now,
  bool foreground = false,
  String? visibleChat,
}) async {
  final l = lookupAppLocalizations(const Locale('en'));
  switch (PushMessage.parse(data)) {
    case final ApprovalPush p:
      if (visibleChat == p.conversationId) {
        await notifications.cancel(notificationId(p.requestId));
      } else {
        await notifications.show(approvalNotification(l, p, now));
      }
    case ApprovalResolvedPush(:final requestId):
      await notifications.cancel(notificationId(requestId));
    case final RunDonePush p:
      if (!foreground) await notifications.show(runDoneNotification(l, p));
    case final WaterPush p:
      // in the foreground the dashboard has it already (card.new)
      if (!foreground) await notifications.show(waterNotification(l, p));
    case final BriefPush p:
      if (!foreground) await notifications.show(briefNotification(l, p));
    case final WatchPush p:
      // also in the foreground: a hit matters wherever the app is
      await notifications.show(watchNotification(l, p));
    case null:
      break;
  }
}

/// Deny from the notification (also on the lock screen): REST, never queued.
/// The notification goes away once the server answered; a failure replaces
/// it with the reason and an Open action. Returns whether it was answered.
Future<bool> denyFromNotification(
  String? actionId,
  String? payload, {
  required CredentialStore store,
  required Notifications notifications,
  HttpClientAdapter? adapter,
}) async {
  if (actionId != NotifyActions.deny) return false;
  final target = PushTarget.decode(payload);
  final requestId = target?.requestId;
  if (target == null || requestId == null) return false;
  final id = notificationId(requestId);
  final creds = await store.read();
  if (creds == null) {
    await notifications.cancel(id); // unpaired meanwhile
    return false;
  }
  final api = DelveApi(
    server: creds.server,
    token: creds.token,
    adapter: adapter,
  );
  try {
    await api.answerApproval(requestId, ApprovalChoice.deny);
    await notifications.cancel(id);
    return true;
  } on ApiError catch (e) {
    if (e is ApiRequestError && (e.status == 409 || e.status == 404)) {
      // answered elsewhere or gone: nothing left to do here
      await notifications.cancel(id);
      return false;
    }
    final l = lookupAppLocalizations(const Locale('en'));
    await notifications.show(
      NotificationSpec(
        id: id,
        channel: NotifyChannel.approvals,
        title: l.approvalFailed(apiErrorText(l, e)),
        body: '',
        payload: payload!,
        actions: [
          NotifyAction(NotifyActions.open, l.notifyOpen, opensApp: true),
        ],
      ),
    );
    return false;
  } finally {
    api.close();
  }
}
