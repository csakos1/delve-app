import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'background.dart';

/// Where pushes come from. Tests use a fake; the phone uses Firebase, the
/// desktop app its WebSocket ([SocketPushTransport]).
abstract interface class PushTransport {
  /// False when this build has no Firebase configuration
  /// (`android/app/google-services.json` was missing at build time).
  Future<bool> init();

  /// Asks FCM for this app instance's registration; the token arrives on
  /// [tokens].
  Future<void> register();

  /// The FCM registration token: once after [register], again when it changes.
  Stream<String> get tokens;

  /// Data messages while the app is in the foreground.
  Stream<Map<String, Object?>> get messages;
}

class FirebasePushTransport implements PushTransport {
  Future<bool>? _init;

  @override
  Future<bool> init() => _init ??= _start();

  Future<bool> _start() async {
    try {
      await Firebase.initializeApp();
    } on Object {
      return false; // no google-services.json: push stays off, the app works
    }
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessage);
    return true;
  }

  @override
  Future<void> register() => FirebaseMessaging.instance.register();

  @override
  Stream<String> get tokens => FirebaseMessaging.instance.onRegistered;

  @override
  Stream<Map<String, Object?>> get messages =>
      FirebaseMessaging.onMessage.map((m) => Map<String, Object?>.from(m.data));
}

/// The desktop app (L3, API 21): the backend sends a device without an FCM
/// token the same data on its socket. Only what arrives while the window is
/// not [focused] goes on (in front, the app shows the change itself); an
/// approval's removal always does, so no stale notification stays.
class SocketPushTransport implements PushTransport {
  SocketPushTransport(this._source, {required bool Function() focused})
    : _focused = focused;

  final Stream<Map<String, Object?>> _source;
  final bool Function() _focused;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> register() async {}

  @override
  Stream<String> get tokens => const Stream.empty();

  @override
  Stream<Map<String, Object?>> get messages => _source.where(
    (data) => data['kind'] == 'approval_resolved' || !_focused(),
  );
}
