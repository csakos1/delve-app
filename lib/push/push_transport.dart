import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'background.dart';

/// Where pushes come from. Tests use a fake; the app uses Firebase.
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
