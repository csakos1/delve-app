import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../app/platform.dart';

/// The longer side of a photo sent to the model (decision 323).
const int kImageLongSide = 1536;
const int kImageQuality = 85;

/// The backend's limit for one image (1.5 MiB: four of them, base64, stay
/// under the Hermes request cap).
const int kMaxImageBytes = 1572864;

/// The backend's limit for one file (decision 324).
const int kMaxFileBytes = 20 * 1024 * 1024;

class ImagePrepFailed implements Exception {
  const ImagePrepFailed(this.reason);
  final String reason;

  @override
  String toString() => 'ImagePrepFailed($reason)';
}

/// Turns a picked photo into what the backend takes. Tests replace it.
abstract class ImagePrep {
  /// JPEG, the longer side at most [kImageLongSide], at most [kMaxImageBytes].
  Future<Uint8List> prepare(Uint8List source);
}

/// `minWidth`/`minHeight` for flutter_image_compress so that the longer side
/// becomes [longSide]: it scales by `max(1, min(w / minWidth, h / minHeight))`,
/// so the same value for both gives `short / m`, whatever the EXIF rotation.
/// A smaller image keeps its size.
@visibleForTesting
int compressBound(int width, int height, {int longSide = kImageLongSide}) {
  final long = max(width, height);
  final short = min(width, height);
  if (long <= 0 || short <= 0) return longSide * 3 ~/ 4;
  if (long <= longSide) return short;
  return max(1, (longSide * short / long).round());
}

class NativeImagePrep implements ImagePrep {
  @override
  Future<Uint8List> prepare(Uint8List source) async {
    final m = await _bound(source);
    for (final quality in const [kImageQuality, 70]) {
      final out = await FlutterImageCompress.compressWithList(
        source,
        minWidth: m,
        minHeight: m,
        quality: quality,
      );
      if (out.isEmpty) throw const ImagePrepFailed('not a readable image');
      if (out.length <= kMaxImageBytes) return out;
    }
    throw const ImagePrepFailed('too large after compression');
  }

  /// The bound from the image's size; a type Flutter cannot read (HEIC on
  /// some phones) gets the bound of a 4:3 photo.
  static Future<int> _bound(Uint8List source) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? desc;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(source);
      desc = await ui.ImageDescriptor.encoded(buffer);
      return compressBound(desc.width, desc.height);
    } on Object {
      return kImageLongSide * 3 ~/ 4;
    } finally {
      desc?.dispose();
      buffer?.dispose();
    }
  }
}

/// The same result without a platform plugin (the Linux app): decode, turn
/// upright by the EXIF orientation, scale the longer side to
/// [kImageLongSide], JPEG at [kImageQuality] (70 when still too large), EXIF
/// dropped. In an isolate: a 12 MP photo takes a moment in pure Dart.
class DartImagePrep implements ImagePrep {
  const DartImagePrep();

  @override
  Future<Uint8List> prepare(Uint8List source) async {
    final out = await Isolate.run(() => dartPrepare(source));
    return switch (out) {
      DartPrepOk(:final bytes) => bytes,
      DartPrepUnreadable() => throw const ImagePrepFailed(
        'not a readable image',
      ),
      DartPrepTooLarge() => throw const ImagePrepFailed(
        'too large after compression',
      ),
    };
  }
}

/// [DartImagePrep]'s answer across the isolate (plain data, no exception).
sealed class DartPrepResult {
  const DartPrepResult();
}

class DartPrepOk extends DartPrepResult {
  const DartPrepOk(this.bytes);
  final Uint8List bytes;
}

class DartPrepUnreadable extends DartPrepResult {
  const DartPrepUnreadable();
}

class DartPrepTooLarge extends DartPrepResult {
  const DartPrepTooLarge();
}

/// The work of [DartImagePrep], synchronous (tests call it directly).
@visibleForTesting
DartPrepResult dartPrepare(Uint8List source, {int maxBytes = kMaxImageBytes}) {
  final decoded = img.decodeImage(source);
  if (decoded == null) return const DartPrepUnreadable();
  var image = img.bakeOrientation(decoded);
  final long = max(image.width, image.height);
  if (long > kImageLongSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: kImageLongSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: kImageLongSide,
            interpolation: img.Interpolation.average,
          );
  }
  image.exif = img.ExifData(); // no GPS or camera data to the model
  for (final quality in const [kImageQuality, 70]) {
    final out = img.encodeJpg(image, quality: quality);
    if (out.length <= maxBytes) return DartPrepOk(out);
  }
  return const DartPrepTooLarge();
}

/// The phone: flutter_image_compress; elsewhere the Dart encoder.
final imagePrepProvider = Provider<ImagePrep>(
  (ref) => ref.watch(platformCapsProvider).nativeImages
      ? NativeImagePrep()
      : const DartImagePrep(),
);
