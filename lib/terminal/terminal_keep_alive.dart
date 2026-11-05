import 'package:flutter/services.dart';

/// The Android side of "Keep connected in background" (T4): a foreground
/// service with a partial wake lock (TerminalKeepService.kt), so the
/// terminal's SSH connection – and the Tailscale tunnel under it – stays up
/// while the app is away. Tests: a fake.
abstract class TerminalKeepAlive {
  /// Starts the service, or updates its notification's [text]. false: not
  /// allowed now (no platform, or Android refused a start).
  Future<bool> start(String text);

  Future<void> stop();

  /// Whether Android exempts Delve from battery optimization (without it
  /// the system may still cut the network of a dozing phone).
  Future<bool> batteryExempt();

  /// Shows the system dialog asking for the exemption; false: it could not
  /// be shown.
  Future<bool> requestBatteryExempt();
}

/// The method channel to MainActivity (`hu.csakos.delve/terminal`). Without
/// the platform side (tests, other platforms) every call is a quiet no.
class ChannelKeepAlive implements TerminalKeepAlive {
  const ChannelKeepAlive();

  static const _channel = MethodChannel('hu.csakos.delve/terminal');

  @override
  Future<bool> start(String text) =>
      _bool(() => _channel.invokeMethod<bool>('start', {'text': text}));

  @override
  Future<void> stop() => _bool(() async {
    await _channel.invokeMethod<void>('stop');
    return true;
  });

  @override
  Future<bool> batteryExempt() =>
      _bool(() => _channel.invokeMethod<bool>('batteryExempt'));

  @override
  Future<bool> requestBatteryExempt() =>
      _bool(() => _channel.invokeMethod<bool>('requestBatteryExempt'));

  static Future<bool> _bool(Future<bool?> Function() call) async {
    try {
      return await call() ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
