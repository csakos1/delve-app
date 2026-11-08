import 'dart:typed_data';

import '../api/models/models.dart';
import '../attachments/attachment_store.dart';

/// The General composer's “upload”: the prepared JPEG stays on the phone
/// until Send writes it into the chat (nothing goes to the desktop). It lets
/// the General chat reuse the composer's attachment strip.
class LocalImageApi implements AttachmentApi {
  final Map<String, (String, Uint8List)> _images = {};
  int _next = 0;

  @override
  Future<Attachment> upload({
    required String kind,
    required String filename,
    required String mime,
    required Uint8List bytes,
  }) async {
    if (kind != 'image') {
      throw UnsupportedError('General chats take images only');
    }
    final id = 'local-${_next++}';
    _images[id] = (mime, bytes);
    return Attachment(
      id: id,
      kind: kind,
      mime: mime,
      filename: filename,
      sizeBytes: bytes.length,
    );
  }

  @override
  Future<Attachment> copy(String id) async {
    final img = _images[id];
    if (img == null) throw StateError('no image $id');
    final (mime, bytes) = img;
    return upload(
      kind: 'image',
      filename: 'image.jpg',
      mime: mime,
      bytes: bytes,
    );
  }

  @override
  Future<Uint8List> bytes(String id) async {
    final img = _images[id];
    if (img == null) throw StateError('no image $id');
    return img.$2;
  }

  /// `(mime, bytes)` of [attachments], in order; unknown ids are left out.
  List<(String, Uint8List)> take(Iterable<Attachment> attachments) => [
    for (final a in attachments) ?_images.remove(a.id),
  ];

  void clear() => _images.clear();
}
