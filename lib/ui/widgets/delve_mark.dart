import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';

/// The Delve mark (design "App icon", concept B "D of depth"): a D cut into
/// four contour layers – lighter is closer, darker is deeper – with the cyan
/// cursor at the deepest point. The same geometry as the launcher icon, in
/// the theme's colours. [height] is the mark's height; it is 46 × 48 wide.
class DelveMark extends StatelessWidget {
  const DelveMark({super.key, this.height = 32, this.semanticLabel});

  final double height;

  /// Null: decorative (the wordmark next to it says "Delve").
  final String? semanticLabel;

  /// The mark's box in the icon's 108 × 108 canvas.
  static const Rect bounds = Rect.fromLTWH(32, 30, 46, 48);

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final mark = SizedBox(
      width: height * bounds.width / bounds.height,
      height: height,
      child: CustomPaint(
        painter: DelveMarkPainter(
          layers: [
            cs.onSurface,
            cs.outline,
            cs.surfaceContainerHighest,
            cs.surface,
          ],
          cursor: cs.primary,
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: mark);
    return Semantics(label: label, image: true, child: mark);
  }
}

/// One contour of the D: a straight top and bottom from [left] to [right],
/// a half circle of [radius] on the right, rounded left corners ([corner]).
@visibleForTesting
Path dContour(
  double left,
  double top,
  double right,
  double radius,
  double corner,
) {
  final bottom = top + 2 * radius;
  return Path()
    ..moveTo(left + corner, top)
    ..lineTo(right, top)
    ..arcToPoint(Offset(right, bottom), radius: Radius.circular(radius))
    ..lineTo(left + corner, bottom)
    ..arcToPoint(Offset(left, bottom - corner), radius: Radius.circular(corner))
    ..lineTo(left, top + corner)
    ..arcToPoint(Offset(left + corner, top), radius: Radius.circular(corner))
    ..close();
}

class DelveMarkPainter extends CustomPainter {
  DelveMarkPainter({required this.layers, required this.cursor})
    : assert(layers.length == 4, 'four contour colours, closest first');

  /// Closest (outer) first.
  final List<Color> layers;
  final Color cursor;

  static final _contours = [
    dContour(33, 31, 52, 23, 3),
    dContour(39.5, 37.5, 53, 17.5, 3),
    dContour(46, 44, 54, 12, 2),
    dContour(52, 50.5, 55, 6.5, 2),
  ];

  static final _cursor = RRect.fromLTRBR(
    53,
    58,
    59.5,
    61,
    const Radius.circular(1.5),
  );

  @override
  void paint(Canvas canvas, Size size) {
    const b = DelveMark.bounds;
    canvas
      ..save()
      ..scale(size.width / b.width, size.height / b.height)
      ..translate(-b.left, -b.top);
    final paint = Paint()..isAntiAlias = true;
    for (var i = 0; i < _contours.length; i++) {
      canvas.drawPath(_contours[i], paint..color = layers[i]);
    }
    canvas
      ..drawRRect(_cursor, paint..color = cursor)
      ..restore();
  }

  @override
  bool shouldRepaint(DelveMarkPainter old) {
    if (old.cursor != cursor) return true;
    for (var i = 0; i < layers.length; i++) {
      if (old.layers[i] != layers[i]) return true;
    }
    return false;
  }
}
