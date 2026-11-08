import 'dart:async';

import 'package:flutter/services.dart';

/// What the ongoing "Transfers" notification shows (23g2).
class TransferNoticeState {
  const TransferNoticeState({
    required this.title,
    this.text = '',
    this.sub = '',
    this.progress,
    required this.cancelLabel,
    required this.openLabel,
  });

  /// "Downloading notes.pdf".
  final String title;

  /// "448 MB of 1.2 GB · 31 MB/s".
  final String text;

  /// "1 of 3" (empty for a single transfer).
  final String sub;

  /// 0…1; null: not known (the bar runs without an end).
  final double? progress;
  final String cancelLabel;
  final String openLabel;

  /// The bar in steps of 0.1 % (what the notification can show).
  int get permille =>
      progress == null ? -1 : (progress!.clamp(0, 1) * 1000).round();

  /// The same notification (no update needed).
  bool sameAs(TransferNoticeState o) =>
      title == o.title &&
      text == o.text &&
      sub == o.sub &&
      permille == o.permille &&
      cancelLabel == o.cancelLabel &&
      openLabel == o.openLabel;

  /// The same transfer in the same phase (an update may wait for the
  /// throttle; a new title or "2 of 3" goes out at once).
  bool sameStepAs(TransferNoticeState o) =>
      title == o.title &&
      sub == o.sub &&
      (progress == null) == (o.progress == null);

  Map<String, Object> toMap() => {
    'title': title,
    'text': text,
    'sub': sub,
    'progress': permille,
    'cancel': cancelLabel,
    'open': openLabel,
  };

  @override
  String toString() => '$title | $text | $sub | $permille';
}

/// The notification after the queue emptied with the app away.
class TransferSummary {
  const TransferSummary({
    required this.title,
    this.text = '',
    this.uri,
    this.mime,
    required this.openLabel,
  });

  /// "Saved to Downloads/Delve".
  final String title;
  final String text;

  /// A single downloaded file: Open opens it in another app (otherwise the
  /// app's Transfers sheet).
  final String? uri;
  final String? mime;
  final String openLabel;

  @override
  String toString() => '$title | $text | ${uri ?? '-'}';
}

/// A tap on the transfer notification.
enum TransferNoticeAction {
  /// Cancel all.
  cancelAll,

  /// Open (or the notification itself): the Transfers sheet.
  open,
}

/// The Android side of the Files transfers in the background (F3b): a
/// `dataSync` foreground service with the "Transfers" notification
/// (TransfersService.kt). Tests: a fake.
abstract interface class TransferNotice {
  /// Starts the service, or updates its notification. false: not allowed
  /// now (no platform, or Android refused a start from the background).
  Future<bool> show(TransferNoticeState state);

  /// Stops the service (its notification goes with it).
  Future<void> stop();

  /// The queue emptied with the app away.
  Future<void> finished(TransferSummary summary);

  /// Taps on the notification's actions.
  Stream<TransferNoticeAction> get actions;

  /// Whether the app was started from a transfers notification (asked once,
  /// at start).
  Future<bool> takeOpen();
}

/// No notification (tests that don't look at it, other platforms).
class NoTransferNotice implements TransferNotice {
  const NoTransferNotice();

  @override
  Future<bool> show(TransferNoticeState state) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> finished(TransferSummary summary) async {}

  @override
  Stream<TransferNoticeAction> get actions => const Stream.empty();

  @override
  Future<bool> takeOpen() async => false;
}

/// MainActivity's `hu.csakos.delve/transfers` channel. Without the platform
/// side every call is a quiet no.
class ChannelTransferNotice implements TransferNotice {
  ChannelTransferNotice();

  static const _channel = MethodChannel('hu.csakos.delve/transfers');

  /// Lives as long as the app.
  // ignore: close_sinks
  StreamController<TransferNoticeAction>? _actions;

  @override
  Future<bool> show(TransferNoticeState state) async {
    try {
      return await _channel.invokeMethod<bool>('show', state.toMap()) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stop() => _quiet(() => _channel.invokeMethod<void>('stop'));

  @override
  Future<void> finished(TransferSummary s) => _quiet(
    () => _channel.invokeMethod<void>('finished', {
      'title': s.title,
      'text': s.text,
      'uri': ?s.uri,
      'mime': ?s.mime,
      'open': s.openLabel,
    }),
  );

  @override
  Stream<TransferNoticeAction> get actions {
    final known = _actions;
    if (known != null) return known.stream;
    _actions = StreamController<TransferNoticeAction>.broadcast();
    _channel.setMethodCallHandler((call) async {
      final action = switch (call.method) {
        'cancelAll' => TransferNoticeAction.cancelAll,
        'open' => TransferNoticeAction.open,
        _ => null,
      };
      if (action != null) _actions?.add(action);
    });
    return _actions!.stream;
  }

  @override
  Future<bool> takeOpen() async {
    try {
      return await _channel.invokeMethod<bool>('takeOpen') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> _quiet(Future<void> Function() call) async {
    try {
      await call();
    } on MissingPluginException {
      // no platform side
    } on PlatformException {
      // nothing to do
    }
  }
}
