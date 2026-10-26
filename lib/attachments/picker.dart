import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A photo or file the user picked, before it is prepared and uploaded.
/// [read] loads the bytes (a picked file is read only when needed).
class PickedAttachment {
  const PickedAttachment({
    required this.kind,
    required this.name,
    required this.read,
    this.mime,
    this.size,
  });

  /// `image` (resized on the phone, the model sees it) or `file` (the agent
  /// reads it from its inbox).
  final String kind;
  final String name;
  final String? mime;

  /// Bytes, when the picker knows it without reading the file.
  final int? size;
  final Future<Uint8List> Function() read;
}

/// The system pickers. Tests replace it.
abstract class AttachmentPicker {
  /// Up to [limit] photos from the gallery (Android Photo Picker).
  Future<List<PickedAttachment>> photos({required int limit});

  /// One photo from the camera, or null when cancelled.
  Future<PickedAttachment?> camera();

  /// Files of any type; photos among them count as images. Returns at most
  /// [limit] of them (the picker itself has no limit).
  Future<List<PickedAttachment>> files({required int limit});
}

/// Image types that go to the model natively when picked as a file.
const _imageExtensions = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
};

/// A MIME type for a file name when the picker gives none.
String mimeForName(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return _imageExtensions[ext] ??
      switch (ext) {
        'txt' || 'log' || 'md' => 'text/plain',
        'csv' => 'text/csv',
        'json' => 'application/json',
        'yaml' || 'yml' => 'application/yaml',
        'pdf' => 'application/pdf',
        'zip' => 'application/zip',
        'gz' || 'tgz' => 'application/gzip',
        'html' || 'htm' => 'text/html',
        'xml' => 'application/xml',
        'py' => 'text/x-python',
        'sh' => 'application/x-sh',
        _ => 'application/octet-stream',
      };
}

bool isImageName(String name) {
  final dot = name.lastIndexOf('.');
  return dot >= 0 &&
      _imageExtensions.containsKey(name.substring(dot + 1).toLowerCase());
}

class DeviceAttachmentPicker implements AttachmentPicker {
  final _images = ImagePicker();

  PickedAttachment _image(XFile f) => PickedAttachment(
    kind: 'image',
    name: f.name,
    mime: f.mimeType,
    read: f.readAsBytes,
  );

  @override
  Future<List<PickedAttachment>> photos({required int limit}) async {
    final picked = await _images.pickMultiImage(
      limit: limit,
      requestFullMetadata: false,
    );
    return [for (final f in picked.take(limit)) _image(f)];
  }

  @override
  Future<PickedAttachment?> camera() async {
    final f = await _images.pickImage(
      source: ImageSource.camera,
      requestFullMetadata: false,
    );
    return f == null ? null : _image(f);
  }

  @override
  Future<List<PickedAttachment>> files({required int limit}) async {
    final picked = await FilePicker.pickFiles();
    return [
      for (final f in picked.take(limit))
        PickedAttachment(
          kind: isImageName(f.name) ? 'image' : 'file',
          name: f.name,
          mime: f.xFile.mimeType ?? mimeForName(f.name),
          size: f.lengthSync(),
          read: f.readAsBytes,
        ),
    ];
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => DeviceAttachmentPicker(),
);
