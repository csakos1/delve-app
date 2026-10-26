import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import '../api/rest_client.dart';
import '../app/session.dart';

/// What the composer needs from the server. Tests replace it.
abstract class AttachmentApi {
  Future<Attachment> upload({
    required String kind,
    required String filename,
    required String mime,
    required Uint8List bytes,
  });

  /// A new, unsent upload with the content of [id] ("Send again").
  Future<Attachment> copy(String id);

  Future<Uint8List> bytes(String id);
}

class RestAttachmentApi implements AttachmentApi {
  RestAttachmentApi(this.api);
  final DelveApi api;

  @override
  Future<Attachment> upload({
    required String kind,
    required String filename,
    required String mime,
    required Uint8List bytes,
  }) => api.uploadAttachment(
    kind: kind,
    filename: filename,
    mime: mime,
    bytes: bytes,
  );

  @override
  Future<Attachment> copy(String id) => api.copyAttachment(id);

  @override
  Future<Uint8List> bytes(String id) => api.attachmentBytes(id);
}

final attachmentApiProvider = Provider<AttachmentApi?>((ref) {
  final api = ref.watch(apiProvider);
  return api == null ? null : RestAttachmentApi(api);
});

/// Image bytes by attachment id, newest kept (the chat shows them again and
/// again while it scrolls). An upload puts its own bytes here, so a sent
/// photo shows without a download.
class AttachmentCache {
  AttachmentCache({this.capacity = 48});
  final int capacity;
  final _items = <String, Uint8List>{}; // insertion-ordered

  Uint8List? get(String id) {
    final hit = _items.remove(id);
    if (hit != null) _items[id] = hit;
    return hit;
  }

  void put(String id, Uint8List bytes) {
    _items.remove(id);
    _items[id] = bytes;
    while (_items.length > capacity) {
      _items.remove(_items.keys.first);
    }
  }
}

final attachmentCacheProvider = Provider<AttachmentCache>(
  (ref) => AttachmentCache(),
);

/// The bytes of one attachment (images in the chat and the viewer).
final attachmentBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
      final cache = ref.watch(attachmentCacheProvider);
      final hit = cache.get(id);
      if (hit != null) return hit;
      final api = ref.watch(attachmentApiProvider);
      if (api == null) throw StateError('not paired');
      final bytes = await api.bytes(id);
      cache.put(id, bytes);
      return bytes;
    });
