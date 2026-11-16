import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/models/models.dart';
import '../app/session.dart';
import 'mirror_platform.dart';

/// The Android side (tests: a fake).
final mirrorPlatformProvider = Provider<MirrorPlatform>(
  (ref) => const ChannelMirror(),
);

/// What the Mirroring page shows.
@immutable
class MirrorView {
  const MirrorView({this.loaded = false, this.state});

  /// The Android side has answered once.
  final bool loaded;

  /// null: no mirroring on this platform.
  final MirrorState? state;
}

/// Notification mirroring, phone to desktop (DA2b), seen from Dart: the page's
/// state and the one thing the listener cannot get on its own – the server's
/// address and the device token.
///
/// The Android side holds a copy of them only while mirroring is on: turning
/// it on hands them over, turning it off takes them back (the Android side
/// does that itself), and unpairing wipes everything there. The app's root
/// listens to this provider, so a session that ends is followed even when the
/// page was never opened.
class MirrorController extends Notifier<MirrorView> {
  @override
  MirrorView build() {
    ref.listen(
      sessionProvider,
      (_, session) => unawaited(_follow(session)),
      fireImmediately: true,
    );
    return const MirrorView();
  }

  MirrorPlatform get _platform => ref.read(mirrorPlatformProvider);

  void _set(MirrorState? next) {
    if (ref.mounted) state = MirrorView(loaded: true, state: next);
  }

  Future<void> _follow(SessionState session) async {
    if (session is SessionLoading) return;
    final creds = session.credentials;
    var now = await _platform.state();
    if (now == null) {
      _set(null);
      return;
    }
    if (creds == null) {
      if (now.enabled || now.credentials || now.apps.isNotEmpty) {
        await _platform.wipe();
        now = await _platform.state();
      }
    } else if (now.enabled && !now.credentials) {
      // on, but the copy is gone (the Keystore key was lost): hand it over
      await _platform.setCredentials(creds.server, creds.token);
      now = await _platform.state();
    }
    _set(now);
  }

  /// Asks the Android side again (the page opens, the app comes back).
  Future<void> refresh() async => _set(await _platform.state());

  /// The main switch. false: it could not be turned on.
  Future<bool> setEnabled({required bool on}) async {
    if (on) {
      final creds = ref.read(sessionProvider).credentials;
      if (creds == null) return false;
      if (!await _platform.setCredentials(creds.server, creds.token)) {
        await refresh();
        return false;
      }
    }
    final next = await _platform.setEnabled(on: on);
    _set(next);
    return next != null && next.enabled == on;
  }

  Future<void> setSelected(String package, {required bool on}) async =>
      _set(await _platform.setSelected(package, on: on));

  Future<bool> openAccess() => _platform.openAccess();

  Future<bool> requestBatteryExempt() => _platform.requestBatteryExempt();
}

final mirrorProvider = NotifierProvider<MirrorController, MirrorView>(
  MirrorController.new,
);

/// `GET /mirror`: is the desktop agent there. Refresh = invalidate.
final mirrorDeskProvider = FutureProvider.autoDispose<MirrorStatus>((ref) {
  final api = ref.watch(apiProvider);
  if (api == null) throw const ApiUnauthorized();
  return api.mirror();
});
