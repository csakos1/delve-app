import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_localizations.dart';
import 'background.dart';
import 'notification_spec.dart';

/// Shows and removes notifications. Tests use a fake.
abstract interface class Notifications {
  Future<void> show(NotificationSpec spec);
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

/// [Notifications] plus what only the main isolate needs: taps, the
/// permission, the tap that launched the app.
abstract interface class PhoneNotifications implements Notifications {
  Stream<NotificationTap> get taps;
  Future<NotificationTap?> launchTap();
  Future<bool> enabled();
  Future<bool> requestPermission();
}

/// A tap on a notification or one of its actions that reached this isolate.
class NotificationTap {
  const NotificationTap({this.actionId, this.payload});
  final String? actionId;
  final String? payload;
}

/// The Android implementation (flutter_local_notifications). Every isolate
/// initializes it with the same background action handler, so the handle the
/// plugin stores is always the right one.
class LocalNotifications implements PhoneNotifications {
  LocalNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<NotificationTap> _taps =
      StreamController<NotificationTap>.broadcast();
  Future<void>? _ready;

  /// Taps and app-opening actions while this isolate runs (main isolate).
  @override
  Stream<NotificationTap> get taps => _taps.stream;

  static AppLocalizations get _l => lookupAppLocalizations(const Locale('en'));

  Future<void> init() => _ready ??= _init();

  Future<void> _init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) =>
          _taps.add(NotificationTap(actionId: r.actionId, payload: r.payload)),
      onDidReceiveBackgroundNotificationResponse: notificationActionBackground,
    );
  }

  /// The tap that started the app, if it was started from a notification.
  @override
  Future<NotificationTap?> launchTap() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    final r = details?.notificationResponse;
    if (details == null || !details.didNotificationLaunchApp || r == null) {
      return null;
    }
    return NotificationTap(actionId: r.actionId, payload: r.payload);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Whether Android lets Delve post notifications.
  @override
  Future<bool> enabled() async {
    await init();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  /// Android 13+: the system dialog (Android stops showing it after the user
  /// declined twice; then only the app's system settings help).
  @override
  Future<bool> requestPermission() async {
    await init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> show(NotificationSpec spec) async {
    await init();
    final l = _l;
    final approvals = spec.channel == NotifyChannel.approvals;
    final now = DateTime.now();
    final timeout = spec.timeoutAt?.difference(now).inMilliseconds;
    if (timeout != null && timeout <= 0) {
      await cancel(spec.id);
      return;
    }
    final countdown = spec.countdownTo;
    final (name, description) = switch (spec.channel) {
      NotifyChannel.approvals => (
        l.notifyChannelApprovals,
        l.notifyChannelApprovalsDesc,
      ),
      NotifyChannel.runs => (l.notifyChannelRuns, l.notifyChannelRunsDesc),
      NotifyChannel.cards => (l.notifyChannelCards, l.notifyChannelCardsDesc),
    };
    final android = AndroidNotificationDetails(
      spec.channel.name,
      name,
      channelDescription: description,
      importance: approvals ? Importance.high : Importance.defaultImportance,
      priority: approvals ? Priority.high : Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(spec.body),
      // an approval's update (agent stopped waiting) stays quiet; a new
      // reading or answer replacing an older one alerts again
      onlyAlertOnce: approvals,
      usesChronometer: countdown != null,
      chronometerCountDown: countdown != null,
      when: countdown?.millisecondsSinceEpoch,
      timeoutAfter: timeout,
      category: approvals ? AndroidNotificationCategory.reminder : null,
      actions: [
        for (final a in spec.actions)
          AndroidNotificationAction(
            a.id,
            a.label,
            showsUserInterface: a.opensApp,
            // Deny stays until the server confirmed (the handler removes it)
            cancelNotification: a.opensApp,
          ),
      ],
    );
    await _plugin.show(
      id: spec.id,
      title: spec.title,
      body: spec.body.split('\n').first,
      notificationDetails: NotificationDetails(android: android),
      payload: spec.payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
