import 'package:delve/mirror/mirror_platform.dart';

/// The Android side of notification mirroring in tests: keeps what the app
/// set and what it was handed.
class FakeMirror implements MirrorPlatform {
  FakeMirror({this.available = true, MirrorState state = const MirrorState()})
    : current = state;

  /// false: a platform without mirroring (every answer is "none").
  bool available;

  MirrorState current;

  /// The server and token the app handed over (null: none, or taken back).
  (Uri, String)? credentials;

  /// The Keystore refuses to keep them.
  bool refuseCredentials = false;

  /// The system page cannot be shown.
  bool accessOpens = true;

  final List<String> calls = [];

  void _put({bool? enabled, bool? credentials, List<MirrorApp>? apps}) {
    final c = current;
    current = MirrorState(
      granted: c.granted,
      connected: c.connected,
      enabled: enabled ?? c.enabled,
      credentials: credentials ?? c.credentials,
      batteryExempt: c.batteryExempt,
      okAt: c.okAt,
      failAt: c.failAt,
      failure: c.failure,
      desk: c.desk,
      apps: apps ?? c.apps,
    );
  }

  @override
  Future<MirrorState?> state() async {
    calls.add('state');
    return available ? current : null;
  }

  @override
  Future<MirrorState?> setEnabled({required bool on}) async {
    calls.add('setEnabled $on');
    if (!available) return null;
    if (on) {
      _put(enabled: true);
    } else {
      // turned off: the Android side drops its copy of the token
      credentials = null;
      _put(enabled: false, credentials: false);
    }
    return current;
  }

  @override
  Future<MirrorState?> setSelected(String package, {required bool on}) async {
    calls.add('setSelected $package $on');
    if (!available) return null;
    _put(
      apps: [
        for (final a in current.apps)
          a.package == package
              ? MirrorApp(
                  package: a.package,
                  label: a.label,
                  selected: on,
                  last: a.last,
                )
              : a,
      ],
    );
    return current;
  }

  @override
  Future<bool> setCredentials(Uri server, String token) async {
    calls.add('setCredentials');
    if (!available || refuseCredentials) return false;
    credentials = (server, token);
    _put(credentials: true);
    return true;
  }

  @override
  Future<void> wipe() async {
    calls.add('wipe');
    credentials = null;
    _put(enabled: false, credentials: false, apps: const []);
  }

  @override
  Future<bool> openAccess() async {
    calls.add('openAccess');
    return available && accessOpens;
  }

  @override
  Future<bool> requestBatteryExempt() async {
    calls.add('requestBatteryExempt');
    return available;
  }
}
