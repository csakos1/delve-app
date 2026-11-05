import 'package:flutter/services.dart';

/// A PDF opened on the phone for the preview: an id and the pages' sizes in
/// points (1/72 inch).
class PdfInfo {
  const PdfInfo(this.id, this.pages);

  final int id;
  final List<Size> pages;
}

/// Why a PDF does not open.
enum PdfProblemKind {
  /// It has a password.
  locked,

  /// Not a PDF, or damaged.
  broken,
  failed,
}

class PdfProblem implements Exception {
  const PdfProblem(this.kind, [this.detail = '']);

  final PdfProblemKind kind;
  final String detail;

  @override
  String toString() => 'PdfProblem(${kind.name}: $detail)';
}

/// The phone renders PDF pages (Android's PdfRenderer; tests: a fake).
abstract interface class PdfPages {
  Future<PdfInfo> open(String path);

  /// Page [page] (from 0) of document [doc], [width] pixels wide (JPEG).
  Future<Uint8List> render(int doc, int page, int width);

  Future<void> close(int doc);
}

/// MainActivity's `hu.csakos.delve/files` channel (PdfPages.kt).
class ChannelPdfPages implements PdfPages {
  const ChannelPdfPages();

  static const _channel = MethodChannel('hu.csakos.delve/files');

  static Future<T?> _call<T>(String method, Map<String, Object> args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw PdfProblem(switch (e.code) {
        'pdfLocked' => PdfProblemKind.locked,
        'pdfBroken' => PdfProblemKind.broken,
        _ => PdfProblemKind.failed,
      }, e.message ?? e.code);
    }
  }

  @override
  Future<PdfInfo> open(String path) async {
    final r = (await _call<Map<Object?, Object?>>('pdfOpen', {'path': path}))!;
    final pages = [
      for (final p in (r['pages']! as List<Object?>).cast<List<Object?>>())
        Size((p[0]! as int).toDouble(), (p[1]! as int).toDouble()),
    ];
    return PdfInfo(r['id']! as int, pages);
  }

  @override
  Future<Uint8List> render(int doc, int page, int width) async =>
      (await _call<Uint8List>('pdfRender', {
        'id': doc,
        'page': page,
        'width': width,
      }))!;

  @override
  Future<void> close(int doc) async {
    await _call<void>('pdfClose', {'id': doc});
  }
}
