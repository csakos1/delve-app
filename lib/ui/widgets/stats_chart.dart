import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';
import 'chart_paint.dart';

/// How a [StatsChart] draws its series.
enum StatsChartKind {
  /// Lines, broken where a bucket has no value; a dot on the newest value.
  line,

  /// The first series as a line with a filled area (cache hit ratio).
  area,

  /// Bars from zero, one per bucket; empty and zero buckets draw nothing.
  bars,
}

/// One series of a chart: a value per bucket (null: no data).
@immutable
class ChartSeries {
  const ChartSeries(this.values, {required this.color, this.dashed = false});

  final List<double?> values;
  final Color color;
  final bool dashed;
}

/// Three grid lines: [lo], the middle and [hi].
typedef ChartScale = ({double lo, double hi});

/// The smallest "nice" step (1, 2, 2.5, 5 × 10^k) that is at least [raw].
double niceStep(double raw) {
  if (raw <= 0) return 1;
  final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (m * exp >= raw - 1e-9) return m * exp;
  }
  return 10 * exp;
}

/// The axis for [values]: two equal steps between three grid lines.
/// [zero] starts at 0 (bars); [minSpan] keeps a calm series from looking
/// stormy; [max] caps the top (100 for a percentage).
ChartScale statsScale(
  Iterable<double> values, {
  bool zero = false,
  double minSpan = 1,
  double? max,
}) {
  if (values.isEmpty) {
    return (lo: 0, hi: zero ? 2 * niceStep(minSpan / 2) : minSpan);
  }
  final vMin = values.reduce(math.min);
  final vMax = values.reduce(math.max);
  if (zero) {
    final step = niceStep(math.max(vMax, minSpan) / 2);
    return (lo: 0, hi: 2 * step);
  }
  final span = math.max(vMax - vMin, minSpan);
  var step = niceStep(span / 2);
  var lo = (vMin / step).floor() * step;
  while (lo + 2 * step < vMax) {
    step = niceStep(step * 1.01);
    lo = (vMin / step).floor() * step;
  }
  var hi = lo + 2 * step;
  if (max != null && hi > max) {
    hi = max;
    lo = math.max(0, hi - 2 * step);
  }
  return (lo: lo, hi: hi);
}

/// A chart of the Observability screen (design 15), drawn by hand like the
/// water chart: three grid lines with their values on the left, three time
/// labels under the plot (or one per bar when [barLabels] is given).
class StatsChart extends StatelessWidget {
  const StatsChart({
    super.key,
    required this.kind,
    required this.series,
    required this.scale,
    required this.yLabel,
    required this.xLabels,
    this.barLabels,
    this.emptyText,
    this.height = 132,
    this.semanticLabel,
  });

  final StatsChartKind kind;
  final List<ChartSeries> series;
  final ChartScale scale;
  final String Function(double) yLabel;

  /// Under the first, the middle and the last bucket.
  final (String, String, String) xLabels;

  /// One label per bar (tokens per day); replaces [xLabels].
  final List<String>? barLabels;

  /// Shown in the plot when no series has a value.
  final String? emptyText;
  final double height;
  final String? semanticLabel;

  bool get isEmpty =>
      series.every((s) => s.values.every((v) => v == null || v == 0)) &&
      (kind == StatsChartKind.bars ||
          series.every((s) => s.values.every((v) => v == null)));

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    excludeSemantics: true,
    child: CustomPaint(
      size: Size.fromHeight(height),
      painter: StatsChartPainter(
        kind: kind,
        series: series,
        scale: scale,
        yLabel: yLabel,
        xLabels: xLabels,
        barLabels: barLabels,
        emptyText: isEmpty ? emptyText : null,
        grid: context.colors.outlineVariant,
        labelStyle: DelveText.monoSmall.copyWith(
          color: context.delve.textMuted,
        ),
        timeStyle: context.text.labelMedium!.copyWith(
          color: context.delve.textMuted,
        ),
        emptyStyle: context.text.bodyMedium!.copyWith(
          color: context.delve.textMuted,
        ),
      ),
    ),
  );
}

class StatsChartPainter extends CustomPainter {
  StatsChartPainter({
    required this.kind,
    required this.series,
    required this.scale,
    required this.yLabel,
    required this.xLabels,
    required this.barLabels,
    required this.emptyText,
    required this.grid,
    required this.labelStyle,
    required this.timeStyle,
    required this.emptyStyle,
  });

  final StatsChartKind kind;
  final List<ChartSeries> series;
  final ChartScale scale;
  final String Function(double) yLabel;
  final (String, String, String) xLabels;
  final List<String>? barLabels;
  final String? emptyText;
  final Color grid;
  final TextStyle labelStyle;
  final TextStyle timeStyle;
  final TextStyle emptyStyle;

  static const double _left = 44;
  static const double _bottom = 22;
  static const double _top = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_left, _top, size.width, size.height - _bottom);
    final span = scale.hi - scale.lo;
    double y(double v) =>
        plot.bottom -
        ((v.clamp(scale.lo, scale.hi) - scale.lo) / (span == 0 ? 1 : span)) *
            plot.height;
    final n = series.isEmpty ? 0 : series.first.values.length;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [scale.lo, (scale.lo + scale.hi) / 2, scale.hi]) {
      final gy = y(v);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), gridPaint);
      paintChartText(
        canvas,
        yLabel(v),
        labelStyle,
        Offset(0, gy),
        vCenter: true,
      );
    }

    final bars = kind == StatsChartKind.bars;
    final slot = n == 0 ? 0.0 : plot.width / n;
    double x(int i) => bars
        ? plot.left + slot * (i + 0.5)
        : n < 2
        ? plot.center.dx
        : plot.left + 8 + i * (plot.width - 16) / (n - 1);

    final labels = barLabels;
    if (labels != null && bars) {
      for (var i = 0; i < labels.length && i < n; i++) {
        paintChartText(
          canvas,
          labels[i],
          timeStyle,
          Offset(x(i), plot.bottom + 4),
          hCenter: true,
        );
      }
    } else if (n > 0) {
      final at = plot.bottom + 4;
      paintChartText(
        canvas,
        xLabels.$1,
        timeStyle,
        Offset(x(0), at),
        hCenter: true,
      );
      paintChartText(
        canvas,
        xLabels.$2,
        timeStyle,
        Offset(x(n ~/ 2), at),
        hCenter: true,
      );
      paintChartText(
        canvas,
        xLabels.$3,
        timeStyle,
        Offset(math.min(x(n - 1), plot.right - 8), at),
        hCenter: true,
      );
    }

    if (emptyText case final text?) {
      paintChartText(
        canvas,
        text,
        emptyStyle,
        plot.center,
        vCenter: true,
        hCenter: true,
      );
      return;
    }

    if (bars) {
      final width = math.max(3.0, math.min(slot * 0.55, 40.0));
      for (final s in series) {
        final paint = Paint()..color = s.color;
        for (var i = 0; i < n; i++) {
          final v = s.values[i];
          if (v == null || v <= 0) continue;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTRB(
                x(i) - width / 2,
                y(v),
                x(i) + width / 2,
                plot.bottom,
              ),
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2),
            ),
            paint,
          );
        }
      }
      return;
    }

    for (var k = series.length - 1; k >= 0; k--) {
      // the first series is drawn last, on top
      final s = series[k];
      final runs = <List<Offset>>[];
      var current = <Offset>[];
      for (var i = 0; i < n; i++) {
        final v = s.values[i];
        if (v == null) {
          if (current.isNotEmpty) runs.add(current);
          current = <Offset>[];
        } else {
          current.add(Offset(x(i), y(v)));
        }
      }
      if (current.isNotEmpty) runs.add(current);
      final stroke = Paint()
        ..color = s.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      for (final run in runs) {
        if (kind == StatsChartKind.area && k == 0 && run.length >= 2) {
          final area = Path()..moveTo(run.first.dx, plot.bottom);
          for (final p in run) {
            area.lineTo(p.dx, p.dy);
          }
          area
            ..lineTo(run.last.dx, plot.bottom)
            ..close();
          canvas.drawPath(
            area,
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(0, plot.top),
                Offset(0, plot.bottom),
                [
                  s.color.withValues(alpha: 0.22),
                  s.color.withValues(alpha: 0.04),
                ],
              ),
          );
        }
        if (run.length == 1) {
          canvas.drawCircle(run.single, 2, Paint()..color = s.color);
        } else if (s.dashed) {
          drawDashedPolyline(canvas, run, stroke);
        } else {
          canvas.drawPath(Path()..addPolygon(run, false), stroke);
        }
      }
      if (k == 0 && runs.isNotEmpty) {
        canvas.drawCircle(runs.last.last, 4, Paint()..color = s.color);
      }
    }
  }

  @override
  bool shouldRepaint(StatsChartPainter old) =>
      old.series != series ||
      old.scale != scale ||
      old.kind != kind ||
      old.xLabels != xLabels ||
      old.emptyText != emptyText ||
      old.grid != grid;
}
