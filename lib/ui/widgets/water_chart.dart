import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/dashboard.dart';
import '../../theme/delve_theme.dart';

/// The week of water levels (design 12): the station as an accent line with a
/// filled area and a dot on the latest day, the lake average dashed, three
/// grid lines with their values, weekday labels. Drawn by hand: two lines and
/// a grid do not need a chart package. Days without a reading are gaps.
class WaterChart extends StatelessWidget {
  const WaterChart({super.key, required this.days, this.height = 196});

  final List<WaterDay> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final d in days) ...[?d.levelCm, ?d.lakeAvgCm],
    ];
    final label = values.isEmpty
        ? ''
        : '${values.reduce(math.min).round()}–${values.reduce(math.max).round()} cm';
    return Semantics(
      label: label,
      child: CustomPaint(
        size: Size.fromHeight(height),
        painter: WaterChartPainter(
          days: days,
          accent: context.colors.primary,
          muted: context.colors.onSurfaceVariant,
          grid: context.colors.outlineVariant,
          labelStyle: DelveText.monoSmall.copyWith(
            color: context.delve.textMuted,
          ),
          dayStyle: context.text.labelMedium!.copyWith(
            color: context.delve.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Scale: from the lowest to the highest value, padded to even centimetres,
/// at least 8 cm tall so a calm week does not look stormy.
({double lo, double hi}) waterScale(Iterable<double> values) {
  if (values.isEmpty) return (lo: 0, hi: 8);
  var lo = values.reduce(math.min);
  var hi = values.reduce(math.max);
  lo = (lo / 2).floorToDouble() * 2;
  hi = (hi / 2).ceilToDouble() * 2;
  if (hi - lo < 8) {
    final mid = ((lo + hi) / 4).roundToDouble() * 2; // even
    lo = mid - 4;
    hi = mid + 4;
  }
  if ((hi - lo) % 4 != 0) hi += 2; // an even middle grid line
  return (lo: lo, hi: hi);
}

class WaterChartPainter extends CustomPainter {
  WaterChartPainter({
    required this.days,
    required this.accent,
    required this.muted,
    required this.grid,
    required this.labelStyle,
    required this.dayStyle,
  });

  final List<WaterDay> days;
  final Color accent;
  final Color muted;
  final Color grid;
  final TextStyle labelStyle;
  final TextStyle dayStyle;

  static const double _left = 44;
  static const double _bottom = 24;
  static const double _top = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final d in days) ...[?d.levelCm, ?d.lakeAvgCm],
    ];
    final scale = waterScale(values);
    final plot = Rect.fromLTRB(_left, _top, size.width, size.height - _bottom);
    double y(double v) =>
        plot.bottom - (v - scale.lo) / (scale.hi - scale.lo) * plot.height;
    double x(int i) => days.length < 2
        ? plot.center.dx
        : plot.left + 8 + i * (plot.width - 16) / (days.length - 1);

    // grid: bottom, middle, top
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [scale.lo, (scale.lo + scale.hi) / 2, scale.hi]) {
      final gy = y(v);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), gridPaint);
      _text(
        canvas,
        v.round().toString(),
        labelStyle,
        Offset(0, gy),
        center: true,
      );
    }

    // weekday labels
    for (var i = 0; i < days.length; i++) {
      _text(
        canvas,
        DateFormat('E').format(days[i].day),
        dayStyle,
        Offset(x(i), plot.bottom + 6),
        hCenter: true,
      );
    }

    final station = [
      for (var i = 0; i < days.length; i++)
        if (days[i].levelCm case final v?) Offset(x(i), y(v)),
    ];
    final lake = [
      for (var i = 0; i < days.length; i++)
        if (days[i].lakeAvgCm case final v?) Offset(x(i), y(v)),
    ];

    if (station.length >= 2) {
      final area = Path()..moveTo(station.first.dx, plot.bottom);
      for (final p in station) {
        area.lineTo(p.dx, p.dy);
      }
      area
        ..lineTo(station.last.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, plot.top),
            Offset(0, plot.bottom),
            [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.04)],
          ),
      );
    }
    if (lake.length >= 2) {
      _dashed(
        canvas,
        lake,
        Paint()
          ..color = muted
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
    if (station.length >= 2) {
      canvas.drawPath(
        Path()..addPolygon(station, false),
        Paint()
          ..color = accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (station.isNotEmpty) {
      canvas.drawCircle(station.last, 4, Paint()..color = accent);
    }
  }

  void _dashed(Canvas canvas, List<Offset> points, Paint paint) {
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

  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset at, {
    bool center = false,
    bool hCenter = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp
      ..paint(
        canvas,
        Offset(
          hCenter ? at.dx - tp.width / 2 : at.dx,
          center ? at.dy - tp.height / 2 : at.dy,
        ),
      )
      ..dispose();
  }

  @override
  bool shouldRepaint(WaterChartPainter old) =>
      old.days != days ||
      old.accent != accent ||
      old.muted != muted ||
      old.grid != grid;
}
