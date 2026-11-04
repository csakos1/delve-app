import 'package:local_auth/local_auth.dart';

/// How long the terminal stays open without input (design 22f).
const kTerminalLockAfter = Duration(minutes: 15);

/// The terminal locks after [after] without input, and on a cold start.
class TerminalLock {
  TerminalLock({this.after = kTerminalLockAfter, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration after;
  final DateTime Function() _now;
  DateTime? _lastActive;

  bool get locked {
    final last = _lastActive;
    return last == null || _now().difference(last) >= after;
  }

  /// An unlock (or the end of setup): open, and the clock starts again.
  void touch() => _lastActive = _now();

  /// Input: keeps an open terminal open, but never opens a locked one. The
  /// terminal's own answers to tmux (device attributes, cursor reports) come
  /// the same way as keystrokes, and tmux asks on every attach – a connect
  /// behind the lock screen must not unlock it (T2a phone test).
  void keepAlive() {
    if (!locked) touch();
  }
}

enum UnlockResult {
  ok,

  /// The user closed the prompt.
  canceled,

  /// This phone has no screen lock or biometrics: nothing to check against.
  unavailable,

  /// Too many tries, or an error; [UnlockOutcome.detail] says which.
  failed,
}

class UnlockOutcome {
  const UnlockOutcome(this.result, [this.detail]);

  final UnlockResult result;
  final String? detail;
}

/// Fingerprint or device credential (BiometricPrompt).
abstract interface class Biometrics {
  Future<UnlockOutcome> unlock(String reason);
}

/// local_auth 3: biometrics or the device credential.
class LocalAuthBiometrics implements Biometrics {
  LocalAuthBiometrics([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<UnlockOutcome> unlock(String reason) async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return const UnlockOutcome(UnlockResult.unavailable);
      }
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return UnlockOutcome(ok ? UnlockResult.ok : UnlockResult.canceled);
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback => const UnlockOutcome(
          UnlockResult.canceled,
        ),
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware => const UnlockOutcome(
          UnlockResult.unavailable,
        ),
        _ => UnlockOutcome(UnlockResult.failed, e.description ?? e.code.name),
      };
    }
  }
}
