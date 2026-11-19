import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_localizations.dart';
import '../theme/delve_colors.dart';
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
        // white D on transparent (res/drawable/ic_stat_delve.xml): Android
        // tints the small icon, a full-colour one would show as a square
        android: AndroidInitializationSettings('@drawable/ic_stat_delve'),
        // the desktop app (L3): freedesktop notifications (swaync)
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
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
    final NotificationAppLaunchDetails? details;
    try {
      details = await _plugin.getNotificationAppLaunchDetails();
    } on Object {
      return null; // a platform without launch details (the desktop)
    }
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

  /// Whether Android lets Delve post notifications (the desktop has no
  /// such permission: yes).
  @override
  Future<bool> enabled() async {
    await init();
    final android = _android;
    return android == null ||
        (await android.areNotificationsEnabled() ?? false);
  }

  /// Android 13+: the system dialog (Android stops showing it after the user
  /// declined twice; then only the app's system settings help).
  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _android;
    return android == null ||
        (await android.requestNotificationsPermission() ?? false);
  }

  @override
  Future<void> show(NotificationSpec spec) async {
    await init();
    final l = _l;
    final approvals = spec.channel == NotifyChannel.approvals;
    final high = approvals || spec.channel == NotifyChannel.watches;
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
      NotifyChannel.watches => (
        l.notifyChannelWatches,
        l.notifyChannelWatchesDesc,
      ),
      NotifyChannel.system => (
        l.notifyChannelSystem,
        l.notifyChannelSystemDesc,
      ),
      NotifyChannel.news => (l.notifyChannelNews, l.notifyChannelNewsDesc),
    };
    final android = AndroidNotificationDetails(
      spec.channel.name,
      name,
      channelDescription: description,
      importance: high ? Importance.high : Importance.defaultImportance,
      priority: high ? Priority.high : Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(spec.body),
      // the small icon's tint (the design's cyan accent)
      color: delveColorScheme.primary,
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
            // Deny and Save stay until the server confirmed (the handler
            // removes them)
            cancelNotification: a.opensApp,
          ),
      ],
    );
    // the desktop (L3): the whole body (swaync shows several lines, as
    // markup – hence the escaping), the same actions; an approval stays until
    // it is answered or removed (critical: no timeout)
    final linux = LinuxNotificationDetails(
      urgency: approvals
          ? LinuxNotificationUrgency.critical
          : LinuxNotificationUrgency.normal,
      actions: [
        for (final a in spec.actions)
          LinuxNotificationAction(key: a.id, label: a.label),
      ],
    );
    final body = _android == null
        ? linuxMarkupEscape(spec.body)
        : spec.body.split('\n').first;
    await _plugin.show(
      id: spec.id,
      title: spec.title,
      body: body,
      notificationDetails: NotificationDetails(android: android, linux: linux),
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

/// freedesktop notification bodies are markup (`body-markup`): a command
/// such as `ls > out && cat <f` must show as written.
String linuxMarkupEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
