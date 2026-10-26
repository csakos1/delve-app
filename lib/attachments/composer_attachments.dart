import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/models/models.dart';
import 'attachment_store.dart';
import 'image_prep.dart';
import 'picker.dart';

/// At most this many attachments in one message (decision 334).
const int kMaxAttachments = 4;

enum DraftState { preparing, uploading, ready, failed }

/// Why a draft attachment failed.
sealed class DraftProblem {
  const DraftProblem();
}

/// Larger than the server takes ([limit] bytes).
final class DraftTooLarge extends DraftProblem {
  const DraftTooLarge(this.limit);
  final int limit;
}

/// Not readable as an image.
final class DraftUnreadable extends DraftProblem {
  const DraftUnreadable();
}

/// The upload (or the copy) failed; [error] is what the API threw.
final class DraftUploadFailed extends DraftProblem {
  const DraftUploadFailed(this.error);
  final Object error;
}

/// One attachment in the composer, from picking to the server's id.
class DraftAttachment {
  DraftAttachment._(this.localId, this.kind, this.filename);

  final int localId;
  final String kind;
  String filename;
  DraftState state = DraftState.preparing;

  /// The prepared image (thumbnail and upload body); null for files.
  Uint8List? preview;

  /// Set once uploaded.
  Attachment? uploaded;
  DraftProblem? problem;

  // what a retry needs
  PickedAttachment? _source;
  Uint8List? _body;
  String? _mime;
  String? _copyOf;

  bool get isImage => kind == 'image';
}

/// The composer's attachments: picked ones are prepared (photos resized to
/// 1536 px JPEG 85) and uploaded at once, so Send only binds their ids.
class ComposerAttachments extends ChangeNotifier {
  ComposerAttachments({
    required AttachmentApi? Function() api,
    required this.prep,
    this.cache,
  }) : _api = api;

  final AttachmentApi? Function() _api;
  final ImagePrep prep;
  final AttachmentCache? cache;
  final List<DraftAttachment> _items = [];
  int _next = 0;
  bool _disposed = false;

  List<DraftAttachment> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get room => kMaxAttachments - _items.length;

  /// Something is still being prepared or uploaded.
  bool get busy => _items.any(
    (d) => d.state == DraftState.preparing || d.state == DraftState.uploading,
  );
  bool get hasFailed => _items.any((d) => d.state == DraftState.failed);

  /// Everything is uploaded: what Send binds, in order.
  List<Attachment> get ready => [for (final d in _items) ?d.uploaded];

  /// Adds what fits ([room]); returns how many were left out.
  int addAll(Iterable<PickedAttachment> picked) {
    var left = 0;
    for (final p in picked) {
      if (room <= 0) {
        left++;
        continue;
      }
      final d = DraftAttachment._(_next++, p.kind, p.name).._source = p;
      _items.add(d);
      unawaited(_prepareAndUpload(d));
    }
    _changed();
    return left;
  }

  /// An earlier attachment again: the server copies it (its id can be sent
  /// once). False when there is no room.
  bool addCopy(Attachment a, {Uint8List? preview}) {
    if (room <= 0) return false;
    final d = DraftAttachment._(_next++, a.kind, a.filename)
      .._copyOf = a.id
      ..preview = preview
      ..state = DraftState.uploading;
    _items.add(d);
    _changed();
    unawaited(_copy(d));
    return true;
  }

  void remove(int localId) {
    _items.removeWhere((d) => d.localId == localId);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  /// A failed one again (from the step that failed).
  void retry(int localId) {
    final d = _find(localId);
    if (d == null || d.state != DraftState.failed) return;
    d.problem = null;
    if (d._copyOf != null) {
      d.state = DraftState.uploading;
      unawaited(_copy(d));
    } else if (d._body != null) {
      d.state = DraftState.uploading;
      unawaited(_upload(d));
    } else {
      d.state = DraftState.preparing;
      unawaited(_prepareAndUpload(d));
    }
    _changed();
  }

  DraftAttachment? _find(int localId) {
    for (final d in _items) {
      if (d.localId == localId) return d;
    }
    return null;
  }

  bool _gone(DraftAttachment d) => _disposed || !_items.contains(d);

  Future<void> _prepareAndUpload(DraftAttachment d) async {
    final source = d._source!;
    try {
      if (d.isImage) {
        final raw = await source.read();
        if (_gone(d)) return;
        final Uint8List jpeg;
        try {
          jpeg = await prep.prepare(raw);
        } on Object {
          _fail(d, const DraftUnreadable());
          return;
        }
        d
          .._body = jpeg
          .._mime = 'image/jpeg'
          ..preview = jpeg
          ..filename = _jpegName(source.name);
      } else {
        if ((source.size ?? 0) > kMaxFileBytes) {
          _fail(d, const DraftTooLarge(kMaxFileBytes));
          return;
        }
        final raw = await source.read();
        if (_gone(d)) return;
        if (raw.length > kMaxFileBytes) {
          _fail(d, const DraftTooLarge(kMaxFileBytes));
          return;
        }
        d
          .._body = raw
          .._mime = source.mime ?? mimeForName(source.name);
      }
    } on Object catch (e) {
      _fail(d, DraftUploadFailed(e));
      return;
    }
    if (_gone(d)) return;
    d.state = DraftState.uploading;
    _changed();
    await _upload(d);
  }

  Future<void> _upload(DraftAttachment d) async {
    final api = _api();
    if (api == null) {
      _fail(d, DraftUploadFailed(StateError('offline')));
      return;
    }
    try {
      final a = await api.upload(
        kind: d.kind,
        filename: d.filename,
        mime: d._mime!,
        bytes: d._body!,
      );
      if (d.isImage) cache?.put(a.id, d._body!);
      _done(d, a);
    } on Object catch (e) {
      _fail(d, DraftUploadFailed(e));
    }
  }

  Future<void> _copy(DraftAttachment d) async {
    final api = _api();
    if (api == null) {
      _fail(d, DraftUploadFailed(StateError('offline')));
      return;
    }
    try {
      final a = await api.copy(d._copyOf!);
      if (d.preview case final p?) cache?.put(a.id, p);
      _done(d, a);
    } on Object catch (e) {
      _fail(d, DraftUploadFailed(e));
    }
  }

  void _done(DraftAttachment d, Attachment a) {
    if (_gone(d)) return;
    d
      ..uploaded = a
      ..filename = a.filename
      ..state = DraftState.ready
      .._body = null;
    _changed();
  }

  void _fail(DraftAttachment d, DraftProblem problem) {
    if (_gone(d)) return;
    d
      ..state = DraftState.failed
      ..problem = problem;
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// `IMG_1234.HEIC` → `IMG_1234.jpg` (the phone sends JPEG).
String _jpegName(String name) {
  final dot = name.lastIndexOf('.');
  final stem = dot <= 0 ? name : name.substring(0, dot);
  return '${stem.isEmpty ? 'image' : stem}.jpg';
}
