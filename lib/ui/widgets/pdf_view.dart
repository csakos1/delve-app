import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../files/pdf_pages.dart';
import '../../theme/delve_theme.dart';
import 'page_scaffolds.dart';
import 'zoom.dart';

/// Pages are rendered this much wider than the screen's pixels (sharp up to
/// a moderate zoom), at most [kPdfRenderMax] pixels wide.
const kPdfRenderScale = 1.5;
const kPdfRenderMax = 2400;

/// Rendered pages kept besides the ones on screen.
const kPdfCachedPages = 8;

/// The friction of a fling (the [InteractiveViewer]'s default, 0.0000135,
/// stops a fast fling within a fraction of a page): a fling travels about a
/// third of its speed in pixels, close to a list's.
const kPdfFlingDrag = 0.05;

/// The viewer multiplies the fling friction by this for a pinch's coasting:
/// with it the pinch keeps the default (0.0000135 × 200). It also scales a
/// mouse wheel or trackpad zoom, which a phone has not.
const kPdfScaleFactor = 0.0027 / kPdfFlingDrag;

const _gap = 8.0;

/// The pages laid out one under the other in a view of [view] size.
class PdfLayout {
  PdfLayout(List<Size> pages, this.view) {
    pageWidth = math.max(1.0, view.width - 2 * _gap);
    var y = _gap;
    for (final p in pages) {
      final h = p.width > 0 ? pageWidth * p.height / p.width : pageWidth;
      tops.add(y);
      heights.add(h);
      y += h + _gap;
    }
    height = math.max(y, view.height);
  }

  final Size view;
  late final double pageWidth;
  final tops = <double>[];
  final heights = <double>[];

  /// The column's height (at least the view's: the viewer would otherwise
  /// zoom a short document in to fill it).
  late final double height;

  Rect get content => Offset.zero & Size(view.width, height);

  /// For the transform [m]: the pages to build (on screen, one screen above
  /// and two below) and the page in view (the last whose top is above a
  /// third of the screen).
  ({int first, int last, int page}) window(Matrix4 m) {
    final n = tops.length;
    if (n == 0) return (first: 0, last: -1, page: 0);
    final s = m.getMaxScaleOnAxis();
    final top = -m.getTranslation().y / s;
    final h = view.height / s;
    var first = 0;
    while (first < n - 1 && tops[first] + heights[first] < top - h) {
      first++;
    }
    var last = first;
    while (last < n - 1 && tops[last + 1] <= top + 2 * h) {
      last++;
    }
    var page = 0;
    while (page < n - 1 && tops[page + 1] <= top + h / 3) {
      page++;
    }
    return (first: first, last: last, page: page);
  }
}

/// The double-tap target in a PDF: [kDoubleTapZoom]× into the tapped spot,
/// or back to the page's width with the spot kept under the finger (not back
/// to the document's top). A drag moves both ways at once while zoomed.
Matrix4 pdfDoubleTapTarget({
  required Matrix4 current,
  required Offset tap,
  required PdfLayout layout,
}) {
  final zoomed = current.getMaxScaleOnAxis() > 1.01;
  return zoomInto(
    point: MatrixUtils.transformPoint(Matrix4.inverted(current), tap),
    under: tap,
    image: layout.content,
    view: layout.view,
    scale: zoomed ? 1 : kDoubleTapZoom,
  );
}

/// The pages of a PDF in one zoomable column on the preview's dark ground:
/// one viewer moves it every way (scroll, pan in any direction, pinch,
/// double tap), and pages are rendered by the phone as they come into view
/// (one at a time, the nearest first); [onPage] tells which page is in view.
class PdfView extends StatefulWidget {
  const PdfView({
    super.key,
    required this.pdf,
    required this.info,
    required this.onPage,
  });

  final PdfPages pdf;
  final PdfInfo info;
  final ValueChanged<int> onPage;

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  late final ZoomAnimator _animator;
  Offset? _tapAt;

  PdfLayout? _layout;
  ({int first, int last, int page})? _window;
  int _page = 0;
  bool _syncQueued = false;

  /// Rendered pages at [_width] pixels, least recently shown first.
  final _cache = <int, Uint8List>{};
  final _failed = <int>{};

  /// Pages built now (on screen or just around it).
  final _shown = <int>{};
  int _width = 0;
  bool _pumping = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_moved);
    _animator = ZoomAnimator(this, _zoom);
  }

  @override
  void dispose() {
    _disposed = true;
    _animator.dispose();
    _zoom
      ..removeListener(_moved)
      ..dispose();
    super.dispose();
  }

  /// The column moved or zoomed: build other pages if the window changed.
  void _moved() {
    final layout = _layout;
    if (layout == null) return;
    final w = layout.window(_zoom.value);
    if (w != _window) setState(() {});
  }

  /// After a frame: the pages built are the ones to render; the page in
  /// view is told.
  void _sync() {
    _syncQueued = false;
    final w = _window;
    if (!mounted || w == null) return;
    final now = {for (var i = w.first; i <= w.last; i++) i};
    for (final p in now.difference(_shown)) {
      final picture = _cache.remove(p); // to the recent end
      if (picture != null) _cache[p] = picture;
    }
    _shown
      ..clear()
      ..addAll(now);
    _schedule();
    if (w.page != _page) {
      _page = w.page;
      widget.onPage(_page);
    }
  }

  void _doubleTap() {
    final layout = _layout;
    if (layout == null) return;
    _animator.animateTo(
      pdfDoubleTapTarget(
        current: _zoom.value,
        tap: _tapAt ?? layout.view.center(Offset.zero),
        layout: layout,
      ),
    );
  }

  // ------------------------------------------------------------ rendering

  void _schedule() {
    if (_pumping || _disposed) return;
    _pumping = true;
    unawaited(Future<void>.microtask(_pump));
  }

  /// Renders the built pages that are not here yet, one at a time: the
  /// one nearest the page in view first (of two, the later).
  Future<void> _pump() async {
    try {
      while (!_disposed) {
        int? page;
        for (final p in _shown) {
          if (_cache.containsKey(p) || _failed.contains(p)) continue;
          if (page == null || (p - _page).abs() <= (page - _page).abs()) {
            page = p;
          }
        }
        if (page == null) break;
        final width = _width;
        try {
          final picture = await widget.pdf.render(widget.info.id, page, width);
          if (_disposed) return;
          if (width != _width) continue; // the size changed meanwhile
          _cache[page] = picture;
          _evict();
        } on Object {
          if (_disposed) return;
          _failed.add(page);
        }
        setState(() {});
      }
    } finally {
      _pumping = false;
    }
  }

  /// Drops the least recently shown pages beyond [kPdfCachedPages] (never
  /// one on screen).
  void _evict() {
    final spare = _cache.keys.where((p) => !_shown.contains(p)).toList();
    final extra = _cache.length - _shown.length - kPdfCachedPages;
    for (final p in spare.take(math.max(0, extra))) {
      _cache.remove(p);
    }
  }

  /// The screen turned (another width): the same page stays at the top, at
  /// no zoom.
  void _relaid(PdfLayout old, PdfLayout layout) {
    final page = old.window(_zoom.value).page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final top = layout.tops.isEmpty ? 0.0 : layout.tops[page] - _gap;
      final lowest = math.max(0.0, layout.height - layout.view.height);
      _zoom.value = Matrix4.translationValues(
        0,
        -math.min(math.max(top, 0.0), lowest),
        0,
      );
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final pages = widget.info.pages;
    return LayoutBuilder(
      builder: (context, box) {
        final view = box.biggest;
        var layout = _layout;
        if (layout == null || layout.view != view) {
          final old = layout;
          layout = PdfLayout(pages, view);
          _layout = layout;
          if (old != null && old.view.width != view.width) {
            _relaid(old, layout);
          }
        }
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = math.min(
          kPdfRenderMax,
          (layout.pageWidth * dpr * kPdfRenderScale).round(),
        );
        if (width != _width) {
          // first layout, or the screen turned: render again at the new size
          _width = width;
          _cache.clear();
          _failed.clear();
        }
        final w = layout.window(_zoom.value);
        _window = w;
        if (!_syncQueued) {
          _syncQueued = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
        }
        return GestureDetector(
          onDoubleTapDown: (d) => _tapAt = d.localPosition,
          onDoubleTap: _doubleTap,
          child: InteractiveViewer(
            key: const Key('preview.pdf'),
            transformationController: _zoom,
            constrained: false,
            minScale: 1,
            maxScale: 5,
            interactionEndFrictionCoefficient: kPdfFlingDrag,
            scaleFactor: kPdfScaleFactor,
            onInteractionStart: (_) => _animator.stop(),
            child: SizedBox(
              width: view.width,
              height: layout.height,
              child: Stack(
                children: [
                  for (var i = w.first; i <= w.last; i++)
                    Positioned(
                      key: ValueKey(i),
                      left: _gap,
                      top: layout.tops[i],
                      width: layout.pageWidth,
                      height: layout.heights[i],
                      child: _PdfPage(
                        index: i,
                        picture: _cache[i],
                        failed: _failed.contains(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One page: white paper with its picture, or a quiet placeholder until it
/// is rendered.
class _PdfPage extends StatelessWidget {
  const _PdfPage({
    required this.index,
    required this.picture,
    required this.failed,
  });

  final int index;
  final Uint8List? picture;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final picture = this.picture;
    return ColoredBox(
      key: Key('preview.pdf.page.$index'),
      color: Colors.white,
      child: picture != null
          ? Image.memory(
              picture,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, _, _) => Center(
                child: SymbolIcon(
                  DelveIcons.error,
                  color: context.delve.textMuted,
                ),
              ),
            )
          : Center(
              child: failed
                  ? SymbolIcon(DelveIcons.error, color: context.delve.textMuted)
                  : const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
    );
  }
}
