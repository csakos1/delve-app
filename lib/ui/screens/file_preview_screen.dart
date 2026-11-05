import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../files/device_files.dart';
import '../../files/files_providers.dart';
import '../../files/files_service.dart';
import '../../files/pdf_pages.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/files_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/pdf_view.dart';
import '../widgets/zoom.dart';

/// What the preview opens: one file, or a folder's images to swipe through
/// (starting at [index]).
class FilePreviewArgs {
  const FilePreviewArgs(this.entries, {this.index = 0});

  final List<RemoteEntry> entries;
  final int index;
}

/// The preview route's `extra`: [FilePreviewArgs], or a single
/// [RemoteEntry]; anything else is not a preview.
FilePreviewArgs? previewArgsOf(Object? extra) => switch (extra) {
  final FilePreviewArgs a when a.entries.isNotEmpty => FilePreviewArgs(
    a.entries,
    index: a.index.clamp(0, a.entries.length - 1),
  ),
  final RemoteEntry e => FilePreviewArgs([e]),
  _ => null,
};

/// Images are decoded at most this large (longest side, px): a phone photo
/// in full would hold ~50 MB of pixels per page, and 8× zoom on a ~1300 px
/// wide screen does not need more.
const kPreviewDecodeMax = 3072;

/// 23h: a text file (read-only, mono, line numbers), an image (pinch to
/// zoom; the folder's other images a swipe away) or a PDF (its pages
/// rendered by the phone), with Download.
class FilePreviewScreen extends ConsumerStatefulWidget {
  const FilePreviewScreen({super.key, required this.args});

  final FilePreviewArgs args;

  @override
  ConsumerState<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends ConsumerState<FilePreviewScreen> {
  late final FilesService _service;
  late final List<RemoteEntry> _entries = widget.args.entries;
  late int _index = widget.args.index;
  late final PageController _pages = PageController(initialPage: _index);
  late final PreviewKind _kind = previewKindOf(_entries[_index]);
  late final bool _gallery = _kind == PreviewKind.image;
  late final bool _pdf = _kind == PreviewKind.pdf;
  int _pdfPage = 0;
  int _pdfCount = 0;
  Future<Object?>? _load;
  bool _lineNumbers = true;
  bool _zoomed = false;
  bool _pinching = false;
  int _down = 0;

  RemoteEntry get _entry => _entries[_index];

  @override
  void initState() {
    super.initState();
    _service = ref.read(filesServiceProvider);
    if (!_gallery && !_pdf) _load = _fetch();
  }

  @override
  void dispose() {
    _pages.dispose();
    // (the PDF view's own dispose has closed the document by now)
    if (_gallery || _pdf) unawaited(_service.clearPreviews());
    super.dispose();
  }

  /// A text file's start; null (not text, or not a kind it shows) is the
  /// "Not a text file" message.
  Future<Object?> _fetch() => previewKindOf(_entry) == PreviewKind.text
      ? _service.readText(_entry)
      : Future<Object?>.value();

  void _download() {
    final l = AppLocalizations.of(context);
    _service.download(_entry);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.filesDownloadQueued(kDownloadFolder))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = _entry;
    final cs = context.colors;
    final dark = _gallery || _pdf;
    final background = dark ? const Color(0xFF0C0D0E) : cs.surface;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        notificationPredicate: (_) => false,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.name,
              key: const Key('preview.title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              [
                if (_entries.length > 1)
                  l.filesPreviewPosition(_index + 1, _entries.length),
                if (_pdf && _pdfCount > 0)
                  l.filesPdfPage(_pdfPage + 1, _pdfCount),
                tildePath(parentPath(e.path), _service.home),
                if (e.size != null) sizeText(e.size!),
              ].join(' · '),
              key: const Key('preview.subtitle'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DelveText.monoSmall.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('preview.download'),
            tooltip: l.filesActDownload,
            icon: const SymbolIcon(FileIcons.download),
            onPressed: _download,
          ),
          if (!dark)
            IconButton(
              key: const Key('preview.lineNumbers'),
              tooltip: l.filesLineNumbers,
              isSelected: _lineNumbers,
              icon: const SymbolIcon(FileIcons.numbers),
              onPressed: () => setState(() => _lineNumbers = !_lineNumbers),
            ),
        ],
      ),
      body: _gallery
          ? _imagePages()
          : _pdf
          ? _PdfPreview(
              entry: e,
              service: _service,
              pdf: ref.read(pdfPagesProvider),
              onDownload: _download,
              onPages: (n) => setState(() => _pdfCount = n),
              onPage: (i) => setState(() => _pdfPage = i),
            )
          : _single(l),
    );
  }

  /// The folder's images. The pages stand still while the image is zoomed
  /// (a drag moves the picture) and while two fingers are down: a pinch
  /// starts with one finger moving, and the page drag would win it.
  Widget _imagePages() => Listener(
    onPointerDown: (_) => _fingers(1),
    onPointerUp: (_) => _fingers(-1),
    onPointerCancel: (_) => _fingers(-1),
    child: PageView.builder(
      key: const Key('preview.pages'),
      controller: _pages,
      physics: _zoomed || _pinching
          ? const NeverScrollableScrollPhysics()
          : null,
      itemCount: _entries.length,
      onPageChanged: (i) => setState(() {
        _index = i;
        _zoomed = false;
      }),
      itemBuilder: (context, i) => _ImagePage(
        key: ValueKey(_entries[i].path),
        entry: _entries[i],
        service: _service,
        onDownload: _download,
        onZoomed: (zoomed) {
          if (zoomed != _zoomed && mounted) setState(() => _zoomed = zoomed);
        },
      ),
    ),
  );

  void _fingers(int delta) {
    _down = math.max(0, _down + delta);
    // two fingers: a pinch until all are lifted
    final pinching = _down >= 2 || (_pinching && _down > 0);
    if (pinching != _pinching) setState(() => _pinching = pinching);
  }

  Widget _single(AppLocalizations l) => FutureBuilder<Object?>(
    future: _load,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError) {
        return FilesMessage(
          key: const Key('preview.error'),
          icon: DelveIcons.error,
          title: l.filesPreviewFailed,
          body: Text('${snap.error}'),
          actions: [
            FilledButton.tonal(
              onPressed: () => setState(() => _load = _fetch()),
              child: Text(l.filesRetry),
            ),
          ],
        );
      }
      return switch (snap.data) {
        (final String text, final bool cut) => _TextView(
          text: text,
          cut: cut,
          lineNumbers: _lineNumbers,
          onDownload: _download,
        ),
        _ => FilesMessage(
          key: const Key('preview.binary'),
          icon: FileIcons.other,
          title: l.filesPreviewBinary,
          body: Text(l.filesPreviewBinaryBody),
          actions: [
            FilledButton(onPressed: _download, child: Text(l.filesActDownload)),
          ],
        ),
      };
    },
  );
}

/// One image of the gallery: fetched when its page is built, the fetch
/// stopped when the page is left before it arrived.
class _ImagePage extends StatefulWidget {
  const _ImagePage({
    super.key,
    required this.entry,
    required this.service,
    required this.onDownload,
    required this.onZoomed,
  });

  final RemoteEntry entry;
  final FilesService service;
  final VoidCallback onDownload;
  final ValueChanged<bool> onZoomed;

  @override
  State<_ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<_ImagePage> {
  final _bytes = ValueNotifier<int>(0);
  Future<File?>? _load;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void dispose() {
    _left = true;
    _bytes.dispose();
    super.dispose();
  }

  Future<File?> _fetch() async {
    final e = widget.entry;
    if ((e.size ?? 0) > kPreviewImageMax) return null;
    return widget.service.fetchPreview(
      e,
      onProgress: (n) {
        if (!_left) _bytes.value = n;
      },
      cancelled: () => _left,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<File?>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _Loading(total: widget.entry.size, bytes: _bytes);
        }
        if (snap.hasError) {
          return FilesMessage(
            key: const Key('preview.error'),
            icon: DelveIcons.error,
            title: l.filesPreviewFailed,
            body: Text('${snap.error}'),
            actions: [
              FilledButton.tonal(
                onPressed: () => setState(() => _load = _fetch()),
                child: Text(l.filesRetry),
              ),
            ],
          );
        }
        final file = snap.data;
        if (file == null) {
          return FilesMessage(
            icon: FileIcons.image,
            title: l.filesPreviewTooBig,
            actions: [
              FilledButton(
                onPressed: widget.onDownload,
                child: Text(l.filesActDownload),
              ),
            ],
          );
        }
        return _ImageView(file: file, onZoomed: widget.onZoomed);
      },
    );
  }
}

/// A PDF: fetched into the preview folder (with progress), opened by the
/// phone, its pages in a [PdfView]; closed when the preview goes.
class _PdfPreview extends StatefulWidget {
  const _PdfPreview({
    required this.entry,
    required this.service,
    required this.pdf,
    required this.onDownload,
    required this.onPages,
    required this.onPage,
  });

  final RemoteEntry entry;
  final FilesService service;
  final PdfPages pdf;
  final VoidCallback onDownload;
  final ValueChanged<int> onPages;
  final ValueChanged<int> onPage;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  final _bytes = ValueNotifier<int>(0);
  Future<PdfInfo?>? _load;
  PdfInfo? _open;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void dispose() {
    _left = true;
    _bytes.dispose();
    final open = _open;
    if (open != null) unawaited(_close(open.id));
    super.dispose();
  }

  Future<void> _close(int id) => widget.pdf.close(id).catchError((Object _) {});

  /// The opened PDF; null: too big to preview here.
  Future<PdfInfo?> _fetch() async {
    final e = widget.entry;
    if ((e.size ?? 0) > kPreviewPdfMax) return null;
    final file = await widget.service.fetchPreview(
      e,
      onProgress: (n) {
        if (!_left) _bytes.value = n;
      },
      cancelled: () => _left,
    );
    if (_left) throw const PreviewCancelled();
    final info = await widget.pdf.open(file.path);
    if (_left || info.pages.isEmpty) {
      unawaited(_close(info.id));
      if (_left) throw const PreviewCancelled();
      throw const PdfProblem(PdfProblemKind.broken, 'no pages');
    }
    _open = info;
    widget.onPages(info.pages.length);
    return info;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final download = FilledButton(
      onPressed: widget.onDownload,
      child: Text(l.filesActDownload),
    );
    return FutureBuilder<PdfInfo?>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _Loading(total: widget.entry.size, bytes: _bytes);
        }
        final error = snap.error;
        if (error is PdfProblem && error.kind != PdfProblemKind.failed) {
          final locked = error.kind == PdfProblemKind.locked;
          return FilesMessage(
            key: Key(locked ? 'preview.pdfLocked' : 'preview.pdfBroken'),
            icon: locked ? DelveIcons.lock : FileIcons.pdf,
            title: locked ? l.filesPdfLocked : l.filesPdfBroken,
            body: Text(locked ? l.filesPdfLockedBody : l.filesPdfBrokenBody),
            actions: [download],
          );
        }
        if (snap.hasError) {
          return FilesMessage(
            key: const Key('preview.error'),
            icon: DelveIcons.error,
            title: l.filesPreviewFailed,
            body: Text('$error'),
            actions: [
              FilledButton.tonal(
                onPressed: () => setState(() => _load = _fetch()),
                child: Text(l.filesRetry),
              ),
            ],
          );
        }
        final info = snap.data;
        if (info == null) {
          return FilesMessage(
            icon: FileIcons.pdf,
            title: l.filesPreviewTooBig,
            actions: [download],
          );
        }
        return PdfView(pdf: widget.pdf, info: info, onPage: widget.onPage);
      },
    );
  }
}

/// While an image or a PDF comes in: how much of it is here.
class _Loading extends StatelessWidget {
  const _Loading({required this.total, required this.bytes});

  final int? total;
  final ValueListenable<int> bytes;

  @override
  Widget build(BuildContext context) => Center(
    child: ValueListenableBuilder<int>(
      valueListenable: bytes,
      builder: (context, n, _) {
        final all = total ?? 0;
        return Column(
          key: const Key('preview.loading'),
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: all > 0 && n > 0 ? (n >= all ? 1.0 : n / all) : null,
            ),
            const SizedBox(height: DelveTokens.space3),
            Text(
              all > 0 ? '${sizeText(n)} / ${sizeText(all)}' : sizeText(n),
              style: DelveText.monoSmall.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _TextView extends StatelessWidget {
  const _TextView({
    required this.text,
    required this.cut,
    required this.lineNumbers,
    required this.onDownload,
  });

  final String text;
  final bool cut;
  final bool lineNumbers;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    var lines = text.split('\n');
    if (lines.length > 1 && lines.last.isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }
    final style = DelveText.mono.copyWith(color: d.codeFg, height: 20 / 13);
    final gutter = DelveText.mono.copyWith(color: d.textMuted, height: 20 / 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            key: const Key('preview.text'),
            margin: const EdgeInsets.symmetric(horizontal: DelveTokens.space2),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DelveTokens.rmd),
            ),
            child: SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: DelveTokens.space3,
                ),
                itemCount: lines.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: DelveTokens.space3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lineNumbers)
                        SizedBox(
                          width:
                              FilesTokens.previewGutter +
                              (lines.length >= 1000 ? 10 : 0),
                          child: SelectionContainer.disabled(
                            child: Text(
                              '${i + 1}',
                              textAlign: TextAlign.right,
                              style: gutter,
                            ),
                          ),
                        ),
                      const SizedBox(width: DelveTokens.space3),
                      Expanded(child: Text(lines[i], style: style)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space2,
            DelveTokens.space2,
            DelveTokens.space2,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cut ? l.filesPreviewCut : l.filesPreviewInfo(lines.length),
                    style: context.text.labelMedium!.copyWith(
                      color: d.textMuted,
                    ),
                  ),
                ),
                if (cut)
                  TextButton(
                    onPressed: onDownload,
                    child: Text(l.filesActDownload),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageView extends StatefulWidget {
  const _ImageView({required this.file, required this.onZoomed});

  final File file;
  final ValueChanged<bool> onZoomed;

  @override
  State<_ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<_ImageView>
    with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  final _viewKey = GlobalKey();
  final _imageKey = GlobalKey();
  late final ZoomAnimator _animator;
  Offset? _tapAt;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_scaled);
    _animator = ZoomAnimator(this, _zoom);
  }

  @override
  void dispose() {
    _animator.dispose();
    _zoom
      ..removeListener(_scaled)
      ..dispose();
    super.dispose();
  }

  void _scaled() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    // the parent rebuilds this page too (paging off while zoomed)
    setState(() => _zoomed = zoomed);
    widget.onZoomed(zoomed);
  }

  /// Double tap: zoom into the tapped spot of the picture, or back out.
  void _doubleTap() {
    final view = _viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || !view.hasSize) return;
    final image = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    // the image as laid out, without the current (pinch) transform
    var rect = Offset.zero & view.size;
    if (image != null && image.hasSize) {
      rect = MatrixUtils.transformRect(
        Matrix4.inverted(_zoom.value),
        MatrixUtils.transformRect(
          image.getTransformTo(view),
          Offset.zero & image.size,
        ),
      );
    }
    _animator.animateTo(
      doubleTapTarget(
        current: _zoom.value,
        tap: _tapAt,
        content: rect,
        view: view.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTapDown: (d) => _tapAt = d.localPosition,
    onDoubleTap: _doubleTap,
    child: InteractiveViewer(
      key: _viewKey,
      transformationController: _zoom,
      panEnabled: _zoomed,
      maxScale: 8,
      onInteractionStart: (_) => _animator.stop(),
      child: Center(
        child: Image(
          key: _imageKey,
          // decoded no larger than kPreviewDecodeMax (never upscaled)
          image: ResizeImage(
            FileImage(widget.file),
            width: kPreviewDecodeMax,
            height: kPreviewDecodeMax,
            policy: ResizeImagePolicy.fit,
          ),
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => FilesMessage(
            icon: FileIcons.image,
            title: AppLocalizations.of(context).filesPreviewBinary,
          ),
        ),
      ),
    ),
  );
}
