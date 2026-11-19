import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../terminal/terminal_providers.dart';
import 'session.dart';

/// What this build of Delve can do where it runs (L1). The Android phone has
/// everything; the Linux desktop app has no push (yet – L3), no Android
/// services and no phone-only pages, and shows the SSH tools (Terminal,
/// Files, the desktop's clipboard) only when they are switched on: on the
/// desktop itself they would only reach the same machine.
@immutable
class PlatformCaps {
  const PlatformCaps({
    required this.phone,
    required this.push,
    required this.notificationMirror,
    required this.shareTarget,
    required this.shareSheet,
    required this.backgroundService,
    required this.terminalLock,
    required this.desktopToolsByDefault,
    required this.nativeImages,
    required this.pdfPreview,
    required this.camera,
    required this.deviceName,
  });

  /// The Android phone.
  static const android = PlatformCaps(
    phone: true,
    push: true,
    notificationMirror: true,
    shareTarget: true,
    shareSheet: true,
    backgroundService: true,
    terminalLock: true,
    desktopToolsByDefault: true,
    nativeImages: true,
    pdfPreview: true,
    camera: true,
    deviceName: kDeviceName,
  );

  /// The Linux desktop app.
  static PlatformCaps linux({String? host}) => PlatformCaps(
    phone: false,
    push: false,
    notificationMirror: false,
    shareTarget: false,
    shareSheet: false,
    backgroundService: false,
    terminalLock: false,
    desktopToolsByDefault: false,
    nativeImages: false,
    pdfPreview: false,
    camera: false,
    deviceName: linuxDeviceName(host ?? _hostname()),
  );

  /// The platform this runs on. Widget tests see Android (the framework's
  /// default target platform there) unless they say otherwise.
  static PlatformCaps current() => switch (defaultTargetPlatform) {
    TargetPlatform.linux when !kIsWeb => linux(),
    _ => android,
  };

  /// A phone (texts say "this phone"); false: a computer.
  final bool phone;

  /// Firebase push (Settings → Notifications, the background handler).
  final bool push;

  /// This phone's notifications to the desktop (DA2b, More → Mirroring).
  final bool notificationMirror;

  /// Share to Delve from other apps.
  final bool shareTarget;

  /// The system share sheet (General export's Share; elsewhere the folder).
  final bool shareSheet;

  /// Android foreground services: the terminal's "Keep connected in
  /// background", the transfers' notification.
  final bool backgroundService;

  /// The terminal's fingerprint lock (design 22f).
  final bool terminalLock;

  /// Terminal, Files and the desktop's clipboard show without a switch.
  final bool desktopToolsByDefault;

  /// flutter_image_compress (else the pure Dart encoder).
  final bool nativeImages;

  /// The Files preview's PDF pages (Android's PdfRenderer).
  final bool pdfPreview;

  /// "+" → Camera.
  final bool camera;

  /// Sent once, when pairing.
  final String deviceName;

  static String _hostname() {
    try {
      return Platform.localHostname;
    } on Object {
      return '';
    }
  }
}

/// `linux-archlinux`: the host name, cut to what the server takes.
@visibleForTesting
String linuxDeviceName(String host) {
  final h = host.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  final name = h.isEmpty ? 'linux' : 'linux-$h';
  return name.length <= 64 ? name : name.substring(0, 64);
}

final platformCapsProvider = Provider<PlatformCaps>(
  (ref) => PlatformCaps.current(),
);

/// Settings → Desktop tools (Linux): the switch's key in the terminal's
/// store (the keyring on Linux).
const kDesktopToolsKey = 'delve.desktopTools.v1';

/// Whether Terminal, Files and the desktop's clipboard show. Always on the
/// phone; on Linux a switch, off until it is turned on (read once from the
/// store – until then off).
class DesktopTools extends Notifier<bool> {
  bool _set = false;

  @override
  bool build() {
    if (ref.watch(platformCapsProvider).desktopToolsByDefault) return true;
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    String? stored;
    try {
      stored = await ref.read(terminalStoreProvider).read(kDesktopToolsKey);
    } on Object {
      stored = null; // the store failed: the tools stay hidden
    }
    if (ref.mounted && !_set) state = stored == '1';
  }

  /// Settings → Desktop tools; no-op where the tools always show.
  Future<void> set({required bool on}) async {
    if (ref.read(platformCapsProvider).desktopToolsByDefault) return;
    _set = true;
    state = on;
    await ref
        .read(terminalStoreProvider)
        .write(kDesktopToolsKey, on ? '1' : '0');
  }
}

final desktopToolsProvider = NotifierProvider<DesktopTools, bool>(
  DesktopTools.new,
);
