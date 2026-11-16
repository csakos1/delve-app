import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An app that has posted a notification the mirror could send.
@immutable
class MirrorApp {
  const MirrorApp({
    required this.package,
    required this.label,
    required this.selected,
    this.last,
  });

  final String package;

  /// The app's name as the launcher shows it.
  final String label;

  /// Its notifications go to the desktop.
  final bool selected;

  /// When it last posted one (null: not since the list was last emptied).
  final DateTime? last;
}

/// Notification mirroring as the Android side reports it (no notification
/// content in it).
@immutable
class MirrorState {
  const MirrorState({
    this.granted = false,
    this.connected = false,
    this.enabled = false,
    this.credentials = false,
    this.batteryExempt = true,
    this.okAt,
    this.failAt,
    this.failure,
    this.desk,
    this.apps = const [],
  });

  factory MirrorState.fromMap(Map<Object?, Object?> m) {
    DateTime? time(Object? v) =>
        v is int && v > 0 ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    return MirrorState(
      granted: m['granted'] == true,
      connected: m['connected'] == true,
      enabled: m['enabled'] == true,
      credentials: m['credentials'] == true,
      batteryExempt: m['batteryExempt'] != false,
      okAt: time(m['okAt']),
      failAt: time(m['failAt']),
      failure: switch (m['failure']) {
        final String f when f.isNotEmpty => f,
        _ => null,
      },
      desk: switch (m['desk']) {
        final bool d => d,
        _ => null,
      },
      apps: [
        if (m['apps'] case final List<Object?> list)
          for (final a in list)
            if (a case final Map<Object?, Object?> app)
              if ((app['package'], app['label']) case (
                final String package,
                final String label,
              ))
                MirrorApp(
                  package: package,
                  label: label,
                  selected: app['selected'] == true,
                  last: time(app['last']),
                ),
      ],
    );
  }

  /// The user allowed Delve to read notifications (system settings).
  final bool granted;

  /// The system has the listener bound.
  final bool connected;

  /// The main switch.
  final bool enabled;

  /// The Android side holds the server's address and the token.
  final bool credentials;

  /// Android exempts Delve from battery optimization.
  final bool batteryExempt;

  /// The last request that went through, the last that did not (cleared by
  /// the next good one) and what kind of failure it was (`HTTP 502`, an
  /// exception's name).
  final DateTime? okAt;
  final DateTime? failAt;
  final String? failure;

  /// Whether the desktop agent was there at [okAt] (null: not known).
  final bool? desk;

  final List<MirrorApp> apps;
}

/// The Android side of notification mirroring (DA2b): the listener service,
/// its settings and its copy of the credentials live there, because the
/// listener runs without the Flutter engine. Tests: a fake.
abstract class MirrorPlatform {
  /// null: this platform has no mirroring.
  Future<MirrorState?> state();

  Future<MirrorState?> setEnabled({required bool on});

  Future<MirrorState?> setSelected(String package, {required bool on});

  /// Hands the server's address and the device token to the listener; false:
  /// it could not keep them.
  Future<bool> setCredentials(Uri server, String token);

  /// Forgets everything the Android side keeps (unpaired).
  Future<void> wipe();

  /// Opens the system page where notification access is given; false: it
  /// could not be shown.
  Future<bool> openAccess();

  /// Shows the system dialog asking for the battery exemption.
  Future<bool> requestBatteryExempt();
}

/// The method channel to MainActivity (`hu.csakos.delve/mirror`). Without the
/// platform side (tests, other platforms) there is no mirroring.
class ChannelMirror implements MirrorPlatform {
  const ChannelMirror();

  static const _channel = MethodChannel('hu.csakos.delve/mirror');

  static Future<T?> _call<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<MirrorState?> _state(String method, [Object? arguments]) async {
    final map = await _call(
      () => _channel.invokeMapMethod<Object?, Object?>(method, arguments),
    );
    return map == null ? null : MirrorState.fromMap(map);
  }

  @override
  Future<MirrorState?> state() => _state('state');

  @override
  Future<MirrorState?> setEnabled({required bool on}) =>
      _state('setEnabled', {'on': on});

  @override
  Future<MirrorState?> setSelected(String package, {required bool on}) =>
      _state('setSelected', {'package': package, 'on': on});

  @override
  Future<bool> setCredentials(Uri server, String token) async =>
      await _call(
        () => _channel.invokeMethod<bool>('setCredentials', {
          'server': server.toString(),
          'token': token,
        }),
      ) ??
      false;

  @override
  Future<void> wipe() => _call(() => _channel.invokeMethod<void>('wipe'));

  @override
  Future<bool> openAccess() async =>
      await _call(() => _channel.invokeMethod<bool>('openAccess')) ?? false;

  @override
  Future<bool> requestBatteryExempt() async =>
      await _call(() => _channel.invokeMethod<bool>('requestBatteryExempt')) ??
      false;
}
