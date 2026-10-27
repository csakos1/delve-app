import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../attachments/picker.dart';

/// What another app shared with Delve ("Share to Delve", design 17).
class SharedPayload {
  const SharedPayload({
    this.files = const [],
    this.text,
    this.skipped = 0,
    this.failed = 0,
  });

  /// Photos and files, as the composer takes picked ones.
  final List<PickedAttachment> files;

  /// Shared text or link (with its title); goes into the message field.
  final String? text;

  /// Left out on the phone: more than one message holds.
  final int skipped;

  /// Could not be read from the sharing app.
  final int failed;

  /// Two shares before the screen took the first.
  SharedPayload merge(SharedPayload next) => SharedPayload(
    files: [...files, ...next.files],
    text: switch ((text, next.text)) {
      (final String a, final String b) => '$a\n$b',
      (final a, final b) => a ?? b,
    },
    skipped: skipped + next.skipped,
    failed: failed + next.failed,
  );

  /// The map the Android side sends (MainActivity.kt); null when it holds
  /// nothing at all.
  static SharedPayload? parse(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final files = <PickedAttachment>[];
    if (raw['files'] case final List<Object?> list) {
      for (final f in list) {
        if (f is! Map<Object?, Object?>) continue;
        final name = switch (f['name']) {
          final String s when s.isNotEmpty => s,
          _ => null,
        };
        if (name == null) continue;
        final mime = switch (f['mime']) {
          final String s => s,
          _ => null,
        };
        final path = switch (f['path']) {
          final String s => s,
          _ => null,
        };
        files.add(
          PickedAttachment(
            kind: sharedKind(name, mime),
            name: name,
            mime: mime ?? mimeForName(name),
            size: switch (f['size']) {
              final int n => n,
              _ => null,
            },
            read: () async {
              // not copied: over the size limit (the size says so)
              if (path == null) throw const FileSystemException('not copied');
              return File(path).readAsBytes();
            },
          ),
        );
      }
    }
    final text = switch (raw['text']) {
      final String s when s.trim().isNotEmpty => s.trim(),
      _ => null,
    };
    int count(Object? v) => v is int ? v : 0;
    final p = SharedPayload(
      files: files,
      text: text,
      skipped: count(raw['skipped']),
      failed: count(raw['failed']),
    );
    final nothing =
        files.isEmpty && text == null && p.skipped == 0 && p.failed == 0;
    return nothing ? null : p;
  }
}

/// Image types the phone resizes and the model sees; anything else goes to
/// the agent's inbox as a file.
const _imageMimes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
};

String sharedKind(String name, String? mime) =>
    isImageName(name) || _imageMimes.contains(mime) ? 'image' : 'file';

/// Shares from other apps. Tests replace it.
abstract class ShareSource {
  /// Single listener; shares that arrive before it listens wait.
  Stream<SharedPayload> get shares;
  void dispose();
}

/// The Android side (MainActivity.kt) over a method channel: Dart takes the
/// waiting share when it starts and whenever the activity says "changed".
class PlatformShareSource implements ShareSource {
  PlatformShareSource([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('hu.csakos.delve/share') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await _take();
    });
    unawaited(_take());
  }

  final MethodChannel _channel;

  // not broadcast: keeps a share until the listener comes
  final _out = StreamController<SharedPayload>();

  @override
  Stream<SharedPayload> get shares => _out.stream;

  Future<void> _take() async {
    final Object? raw;
    try {
      raw = await _channel.invokeMethod<Object?>('take');
    } on MissingPluginException {
      return; // not Android (or a test)
    } on PlatformException {
      return;
    }
    final p = SharedPayload.parse(raw);
    if (p != null && !_out.isClosed) _out.add(p);
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_out.close());
  }
}

/// Null: no sharing (tests, unless they give a fake).
final shareSourceProvider = Provider<ShareSource?>((ref) {
  final source = PlatformShareSource();
  ref.onDispose(source.dispose);
  return source;
});

/// The share waiting for the Share to Delve screen; the screen takes it.
class PendingShare extends Notifier<SharedPayload?> {
  @override
  SharedPayload? build() {
    final sub = ref.watch(shareSourceProvider)?.shares.listen((p) {
      final now = state;
      state = now == null ? p : now.merge(p);
    });
    ref.onDispose(() => unawaited(sub?.cancel()));
    return null;
  }

  /// Hands the waiting share over (once).
  SharedPayload? take() {
    final p = state;
    state = null;
    return p;
  }
}

final pendingShareProvider = NotifierProvider<PendingShare, SharedPayload?>(
  PendingShare.new,
);
