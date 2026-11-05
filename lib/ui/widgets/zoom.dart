import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/delve_theme.dart';

/// The transform that zooms [scale]× into [point] (in the content, as laid
/// out without a transform) of an image laid out at [image] in a viewer of
/// size [view]: the spot stays [under] the finger (in the viewer; by default
/// where it is laid out, i.e. from no zoom), but where the zoomed picture is
/// larger than the viewer it covers it (no black band beside it), and where
/// it is smaller it is centred.
Matrix4 zoomInto({
  required Offset point,
  required Rect image,
  required Size view,
  required double scale,
  Offset? under,
}) {
  final finger = under ?? point;
  double axis(double p, double u, double lo, double hi, double extent) {
    final a = lo * scale;
    final b = hi * scale;
    if (b - a <= extent) return (extent - (b - a)) / 2 - a;
    final at = math.min(math.max(p, lo), hi);
    return math.max(extent - b, math.min(-a, u - scale * at));
  }

  return Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(
    axis(point.dx, finger.dx, image.left, image.right, view.width),
    axis(point.dy, finger.dy, image.top, image.bottom, view.height),
    0,
  );
}

/// A double tap zooms this much.
const kDoubleTapZoom = 2.5;

/// Moves a [TransformationController] to a target smoothly (double tap).
class ZoomAnimator {
  ZoomAnimator(TickerProvider vsync, this.zoom)
    : _anim = AnimationController(vsync: vsync, duration: DelveTokens.medium) {
    _anim.addListener(() {
      if (_to case final to?) zoom.value = to.value;
    });
  }

  final TransformationController zoom;
  final AnimationController _anim;
  Animation<Matrix4>? _to;

  void animateTo(Matrix4 target) {
    _to = Matrix4Tween(
      begin: zoom.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: DelveTokens.shortCurve));
    unawaited(_anim.forward(from: 0));
  }

  /// A finger takes over.
  void stop() => _anim.stop();

  void dispose() => _anim.dispose();
}

/// The double-tap target for a viewer of [view] size showing [content]
/// (laid out, without the current transform): back out when zoomed,
/// otherwise [kDoubleTapZoom]× into [tap] (in the viewer).
Matrix4 doubleTapTarget({
  required Matrix4 current,
  required Offset? tap,
  required Rect content,
  required Size view,
}) {
  if (current.getMaxScaleOnAxis() > 1.01) return Matrix4.identity();
  final inverse = Matrix4.inverted(current);
  return zoomInto(
    point: MatrixUtils.transformPoint(inverse, tap ?? view.center(Offset.zero)),
    image: content,
    view: view,
    scale: kDoubleTapZoom,
  );
}
