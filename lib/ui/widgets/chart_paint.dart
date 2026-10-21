import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';

/// Shared bits of the hand-drawn charts (the water week, Observability).

/// A dashed polyline: 6 dp dashes, 5 dp gaps, carried across the vertices.
void drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint) {
  const dash = 6.0;
  const gap = 5.0;
  var on = true;
  var left = dash;
  for (var i = 0; i < points.length - 1; i++) {
    var a = points[i];
    final b = points[i + 1];
    var segment = (b - a).distance;
    if (segment == 0) continue;
    final dir = (b - a) / segment;
    while (segment > 0) {
      final step = math.min(left, segment);
      final next = a + dir * step;
      if (on) canvas.drawLine(a, next, paint);
      a = next;
      segment -= step;
      left -= step;
      if (left <= 0) {
        on = !on;
        left = on ? dash : gap;
      }
    }
  }
}

/// Paints [text] at [at]; [vCenter] centres it vertically on `at.dy`,
/// [hCenter] horizontally on `at.dx`, [right] ends it at `at.dx`.
void paintChartText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at, {
  bool vCenter = false,
  bool hCenter = false,
  bool right = false,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  final dx = hCenter
      ? at.dx - tp.width / 2
      : right
      ? at.dx - tp.width
      : at.dx;
  tp
    ..paint(canvas, Offset(dx, vCenter ? at.dy - tp.height / 2 : at.dy))
    ..dispose();
}

/// A legend entry under a chart: a 20 × 2 dp mark (solid, or two dashes) and
/// the label.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.label,
    required this.color,
    required this.dashed,
    this.markKey,
  });

  final String label;
  final Color color;
  final bool dashed;
  final Key? markKey;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        key: markKey,
        width: 20,
        height: 2,
        child: dashed
            // Stretched: a ColoredBox without a child takes the smallest
            // size it is allowed, so under a Row's loose height the dashes
            // would be 0 dp high.
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ColoredBox(color: color)),
                  const SizedBox(width: 4),
                  Expanded(child: ColoredBox(color: color)),
                ],
              )
            : ColoredBox(color: color),
      ),
      const SizedBox(width: DelveTokens.space2),
      Flexible(
        child: Text(
          label,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
