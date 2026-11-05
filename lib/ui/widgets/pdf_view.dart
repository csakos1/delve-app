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

const _gap = 8.0;

/// The pages of a PDF in a scrolling column on the preview's dark ground:
/// rendered by the phone as they come into view (one at a time, the nearest
/// first), pinch or double tap to zoom; [onPage] tells which page is in view.
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
  final _scroll = ScrollController();
  final _zoom = TransformationController();
  final _viewKey = GlobalKey();
  late final ZoomAnimator _animator;
  Offset? _tapAt;
  bool _zoomed = false;
  bool _pinching = false;
  int _down = 0;

  /// Rendered pages at [_width] pixels, least recently shown first.
  final _cache = <int, Uint8List>{};
  final _failed = <int>{};

  /// Pages built now (on screen or just around it), in the order they came.
  final _shown = <int>[];
  int _width = 0;
  bool _pumping = false;
  bool _disposed = false;

  List<double> _tops = const [];
  int _page = 0;
  bool _pageQueued = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_scaled);
    _animator = ZoomAnimator(this, _zoom);
    _scroll.addListener(_scrolled);
  }

  @override
  void dispose() {
    _disposed = true;
    _animator.dispose();
    _zoom
      ..removeListener(_scaled)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scaled() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  /// The page whose top is above a third of the view.
  void _scrolled() {
    if (_tops.isEmpty || !_scroll.hasClients) return;
    final p = _scroll.position;
    final at = p.pixels + p.viewportDimension / 3;
    var page = 0;
    while (page + 1 < _tops.length && _tops[page + 1] <= at) {
      page++;
    }
    if (page == _page) return;
    _page = page;
    // told after the frame: the position also moves while laid out
    if (_pageQueued) return;
    _pageQueued = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _pageQueued = false;
        if (mounted) widget.onPage(_page);
      })
      ..ensureVisualUpdate();
  }

  void _fingers(int delta) {
    _down = math.max(0, _down + delta);
    // two fingers: a pinch until all are lifted (the list would take it)
    final pinching = _down >= 2 || (_pinching && _down > 0);
    if (pinching != _pinching) setState(() => _pinching = pinching);
  }

  void _doubleTap() {
    final view = _viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || !view.hasSize) return;
    _animator.animateTo(
      doubleTapTarget(
        current: _zoom.value,
        tap: _tapAt,
        content: Offset.zero & view.size,
        view: view.size,
      ),
    );
  }

  // ------------------------------------------------------------ rendering

  void _show(int page) {
    _shown
      ..remove(page)
      ..add(page);
    final picture = _cache.remove(page); // to the recent end
    if (picture != null) _cache[page] = picture;
    _schedule();
  }

  void _hide(int page) => _shown.remove(page);

  void _schedule() {
    if (_pumping || _disposed) return;
    _pumping = true;
    unawaited(Future<void>.microtask(_pump));
  }

  /// Renders the built pages that are not here yet, one at a time: the
  /// one nearest the page in view first (of two, the newer).
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

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final pages = widget.info.pages;
    return LayoutBuilder(
      builder: (context, box) {
        final pageWidth = math.max(1.0, box.maxWidth - 2 * _gap);
        final heights = [
          for (final p in pages)
            p.width > 0 ? pageWidth * p.height / p.width : pageWidth,
        ];
        final tops = <double>[];
        var y = _gap;
        for (final h in heights) {
          tops.add(y);
          y += h + _gap;
        }
        _tops = tops;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = math.min(
          kPdfRenderMax,
          (pageWidth * dpr * kPdfRenderScale).round(),
        );
        if (width != _width) {
          // first layout, or the screen turned: render again at the new size
          _width = width;
          _cache.clear();
          _failed.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
        }
        return Listener(
          onPointerDown: (_) => _fingers(1),
          onPointerUp: (_) => _fingers(-1),
          onPointerCancel: (_) => _fingers(-1),
          child: GestureDetector(
            onDoubleTapDown: (d) => _tapAt = d.localPosition,
            onDoubleTap: _doubleTap,
            child: InteractiveViewer(
              key: _viewKey,
              transformationController: _zoom,
              panEnabled: _zoomed,
              minScale: 1,
              maxScale: 5,
              onInteractionStart: (_) => _animator.stop(),
              child: ListView.builder(
                key: const Key('preview.pdf'),
                controller: _scroll,
                physics: _pinching
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: _gap,
                  vertical: _gap,
                ),
                itemCount: pages.length,
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.only(
                    bottom: i == pages.length - 1 ? 0 : _gap,
                  ),
                  child: _PdfPage(
                    key: ValueKey(i),
                    index: i,
                    height: heights[i],
                    picture: _cache[i],
                    failed: _failed.contains(i),
                    onShow: _show,
                    onHide: _hide,
                  ),
                ),
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
class _PdfPage extends StatefulWidget {
  const _PdfPage({
    super.key,
    required this.index,
    required this.height,
    required this.picture,
    required this.failed,
    required this.onShow,
    required this.onHide,
  });

  final int index;
  final double height;
  final Uint8List? picture;
  final bool failed;
  final ValueChanged<int> onShow;
  final ValueChanged<int> onHide;

  @override
  State<_PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<_PdfPage> {
  @override
  void initState() {
    super.initState();
    widget.onShow(widget.index);
  }

  @override
  void dispose() {
    widget.onHide(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picture = widget.picture;
    return SizedBox(
      key: Key('preview.pdf.page.${widget.index}'),
      height: widget.height,
      child: ColoredBox(
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
                child: widget.failed
                    ? SymbolIcon(
                        DelveIcons.error,
                        color: context.delve.textMuted,
                      )
                    : const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
      ),
    );
  }
}
