import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/observability.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/chart_paint.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/stats_chart.dart';
import '../widgets/status_ui.dart';
import '../widgets/system_ui.dart';

/// 15 Observability: generation and prefill speed, queue length, approval
/// latency, cache hit ratio, tokens per day, GPU temperature and power, for
/// 24 h, 7 d or 30 d. Loaded when opened, on a range chip, on refresh.
class ObservabilityScreen extends ConsumerStatefulWidget {
  const ObservabilityScreen({super.key});

  @override
  ConsumerState<ObservabilityScreen> createState() =>
      _ObservabilityScreenState();
}

class _ObservabilityScreenState extends ConsumerState<ObservabilityScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame: refresh() marks the view as loading, and a
    // provider may not change while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  Future<void> _refresh({bool quiet = false}) async {
    try {
      await ref.read(observabilityProvider.notifier).refresh();
    } on Object catch (e) {
      if (quiet || !mounted) return;
      _snack(e);
    }
  }

  Future<void> _select(StatsRange range) async {
    try {
      await ref.read(observabilityProvider.notifier).select(range);
    } on Object {
      // the banner says it; the old range's numbers stay
    }
  }

  void _snack(Object e) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.obsLoadFailed(apiErrorText(l, e)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(observabilityProvider);
    final stats = view.stats;
    final error = view.error;
    return SubPage(
      title: l.moreObservability,
      actions: [
        IconButton(
          key: const Key('obs.refresh'),
          tooltip: l.retry,
          onPressed: _refresh,
          icon: const SymbolIcon(DelveIcons.refresh),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space2,
              DelveTokens.space4,
              DelveTokens.space2,
            ),
            child: Wrap(
              spacing: DelveTokens.space2,
              runSpacing: DelveTokens.space2,
              children: [
                for (final r in StatsRange.values)
                  _RangeChip(
                    range: r,
                    selected: r == view.range,
                    onSelected: () => unawaited(_select(r)),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 2,
            child: view.loading
                ? const LinearProgressIndicator(
                    key: Key('obs.loading'),
                    minHeight: 2,
                  )
                : null,
          ),
          Expanded(
            child: switch (stats) {
              null when error != null => Padding(
                padding: const EdgeInsets.all(DelveTokens.space4),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: StatusBanner(
                    key: const Key('obs.error'),
                    kind: StatusKind.alert,
                    icon: DelveIcons.error,
                    text: l.obsLoadFailed(apiErrorText(l, error)),
                    actionLabel: l.retry,
                    onAction: _refresh,
                  ),
                ),
              ),
              null => const Center(child: CircularProgressIndicator()),
              final Stats data => RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  key: const Key('obs.list'),
                  padding: const EdgeInsets.fromLTRB(
                    DelveTokens.space4,
                    DelveTokens.space2,
                    DelveTokens.space4,
                    DelveTokens.space6,
                  ),
                  children: [
                    if (error != null) ...[
                      StatusBanner(
                        key: const Key('obs.error'),
                        kind: StatusKind.warn,
                        icon: DelveIcons.syncProblem,
                        text: l.obsLoadFailed(apiErrorText(l, error)),
                        actionLabel: l.retry,
                        onAction: _refresh,
                      ),
                      const SizedBox(height: DelveTokens.space3),
                    ],
                    ..._cards(context, l, data),
                  ],
                ),
              ),
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _cards(BuildContext context, AppLocalizations l, Stats s) {
    final accent = context.colors.primary;
    final muted = context.colors.onSurfaceVariant;
    final x = _xLabels(s);
    final cards = <Widget>[
      _StatCard(
        key: const Key('obs.generation'),
        title: l.obsGeneration,
        value: s.generation.value == null
            ? '—'
            : l.obsTokPerS(s.generation.value!.toStringAsFixed(1)),
        chart: _line(s.generation, accent, x, _plain, emptyText: l.obsNoRuns),
      ),
      _StatCard(
        key: const Key('obs.prefill'),
        title: l.obsPrefill,
        note: l.obsPrefillNote(s.prefillMinPromptTokens),
        value: s.prefill.value == null
            ? '—'
            : l.obsTokPerS(s.prefill.value!.round().toString()),
        chart: _line(
          s.prefill,
          accent,
          x,
          _plain,
          minSpan: 40,
          emptyText: l.obsNoRuns,
        ),
      ),
      _StatCard(
        key: const Key('obs.queue'),
        title: l.obsQueue,
        value: _int(s.queue.value),
        chart: _bars(s.queue, accent, x, _plain, minSpan: 2),
      ),
      _StatCard(
        key: const Key('obs.latency'),
        title: l.obsApprovalLatency,
        note: switch (s.range) {
          '7d' => l.obsMedianPer6h,
          '30d' => l.obsMedianPerDay,
          _ => l.obsMedianPerHour,
        },
        value: s.approvalLatency.value == null
            ? '—'
            : secondsText(s.approvalLatency.value!),
        chart: _bars(
          s.approvalLatency,
          context.delve.warnFg,
          x,
          _secondsAxis,
          minSpan: 60,
          emptyText: l.obsNoApprovals,
        ),
      ),
      _StatCard(
        key: const Key('obs.cache'),
        title: l.obsCacheHit,
        value: s.cacheHit.value == null
            ? '—'
            : '${s.cacheHit.value!.round()} %',
        chart: StatsChart(
          kind: StatsChartKind.area,
          series: [ChartSeries(_values(s.cacheHit), color: accent)],
          scale: statsScale(_present(s.cacheHit), minSpan: 20, max: 100),
          yLabel: (v) => '${v.round()}%',
          xLabels: x,
          emptyText: l.obsNoRuns,
          semanticLabel: l.obsCacheHit,
        ),
      ),
      _StatCard(
        key: const Key('obs.tokens'),
        title: l.obsTokensPerDay,
        note: l.obsLastDays(s.tokensPerDay.days.length),
        value: tokenCount(s.tokensPerDay.value),
        chart: _tokens(context, l, s.tokensPerDay),
      ),
    ];
    final sampling = s.sampling;
    final banner = sampling.intervalS == 0
        ? StatusBanner(
            key: const Key('obs.sampling'),
            kind: StatusKind.info,
            icon: DelveIcons.info,
            text: l.obsSamplingOff,
          )
        : !sampling.ok
        ? StatusBanner(
            key: const Key('obs.sampling'),
            kind: StatusKind.warn,
            icon: DelveIcons.warning,
            text: l.obsSamplingFailed(sampling.error ?? ''),
          )
        : null;
    final gx = _xLabels(s, gpu: true);
    final gpus = s.gpus;
    List<ChartSeries> gpuSeries(StatsSeries Function(StatsGpu) pick) => [
      for (final (i, g) in gpus.indexed)
        ChartSeries(
          _values(pick(g)),
          color: i == 0 ? accent : muted,
          dashed: i > 0,
        ),
    ];
    String pair(StatsSeries Function(StatsGpu) pick, String unit) =>
        gpus.isEmpty
        ? '—'
        : '${gpus.map((g) => _int(pick(g).value)).join(' / ')} $unit';
    Widget legend() => Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space2),
      child: Wrap(
        spacing: DelveTokens.space4,
        runSpacing: DelveTokens.space1,
        children: [
          for (final (i, g) in gpus.indexed)
            ChartLegend(
              label: gpuName(g.name ?? 'GPU ${g.index}'),
              color: i == 0 ? accent : muted,
              dashed: i > 0,
            ),
        ],
      ),
    );
    Widget gpuChart(
      StatsSeries Function(StatsGpu) pick,
      String Function(double) yLabel,
      double minSpan,
      String title,
    ) {
      final series = gpuSeries(pick);
      return StatsChart(
        kind: StatsChartKind.line,
        series: series,
        scale: statsScale([
          for (final g in gpus) ..._present(pick(g)),
        ], minSpan: minSpan),
        yLabel: yLabel,
        xLabels: gx,
        emptyText: l.obsNoSamples,
        semanticLabel: title,
      );
    }

    return [
      for (final c in cards) ...[c, const SizedBox(height: DelveTokens.space3)],
      if (banner != null) ...[
        banner,
        const SizedBox(height: DelveTokens.space3),
      ],
      _StatCard(
        key: const Key('obs.gpuTemp'),
        title: l.obsGpuTemp,
        value: pair((g) => g.temp, '°C'),
        chart: gpuChart(
          (g) => g.temp,
          (v) => '${v.round()}°',
          20,
          l.obsGpuTemp,
        ),
        footer: gpus.isEmpty ? null : legend(),
      ),
      const SizedBox(height: DelveTokens.space3),
      _StatCard(
        key: const Key('obs.gpuPower'),
        title: l.obsGpuPower,
        value: pair((g) => g.power, 'W'),
        chart: gpuChart(
          (g) => g.power,
          (v) => '${v.round()}W',
          50,
          l.obsGpuPower,
        ),
        footer: gpus.isEmpty ? null : legend(),
      ),
    ];
  }

  Widget _line(
    StatsSeries s,
    Color color,
    (String, String, String) x,
    String Function(double) yLabel, {
    double minSpan = 2,
    String? emptyText,
  }) => StatsChart(
    kind: StatsChartKind.line,
    series: [ChartSeries(_values(s), color: color)],
    scale: statsScale(_present(s), minSpan: minSpan),
    yLabel: yLabel,
    xLabels: x,
    emptyText: emptyText,
  );

  Widget _bars(
    StatsSeries s,
    Color color,
    (String, String, String) x,
    String Function(double) yLabel, {
    double minSpan = 2,
    String? emptyText,
  }) => StatsChart(
    kind: StatsChartKind.bars,
    series: [ChartSeries(_values(s), color: color)],
    scale: statsScale(_present(s), zero: true, minSpan: minSpan),
    yLabel: yLabel,
    xLabels: x,
    emptyText: emptyText,
    height: 110,
  );

  Widget _tokens(BuildContext context, AppLocalizations l, TokensPerDay t) {
    final dates = [for (final d in t.days) DateTime.parse(d.date)];
    final values = [for (final d in t.days) d.tokens.toDouble()];
    final scale = statsScale(values, zero: true, minSpan: 1000);
    final big = scale.hi >= 2000;
    return StatsChart(
      kind: StatsChartKind.bars,
      series: [ChartSeries(values, color: context.colors.primary)],
      scale: scale,
      yLabel: (v) => big ? '${(v / 1000).round()}k' : v.round().toString(),
      xLabels: dates.isEmpty
          ? ('', '', '')
          : (
              DateFormat('d MMM').format(dates.first),
              DateFormat('d MMM').format(dates[dates.length ~/ 2]),
              DateFormat('d MMM').format(dates.last),
            ),
      barLabels: dates.length <= 7
          ? [for (final d in dates) DateFormat('E').format(d)]
          : null,
      emptyText: l.obsNoRuns,
      height: 120,
    );
  }
}

List<double?> _values(StatsSeries s) => [for (final p in s.points) p.v];

List<double> _present(StatsSeries s) => [for (final p in s.points) ?p.v];

String _int(double? v) => v == null ? '—' : v.round().toString();

/// Axis numbers: whole when whole, else one decimal (21.5).
String _plain(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

String _secondsAxis(double v) =>
    v >= 600 ? '${(v / 60).round()}m' : '${v.round()}s';

/// First, middle and last bucket of the range: hours for 24 h, weekdays for
/// 7 d, dates for 30 d (local time).
(String, String, String) _xLabels(Stats s, {bool gpu = false}) {
  final series = gpu && s.gpus.isNotEmpty ? s.gpus.first.temp : s.generation;
  final times = [for (final p in series.points) p.t.toLocal()];
  if (times.isEmpty) return ('', '', '');
  final f = switch (s.range) {
    '7d' => DateFormat('E'),
    '30d' => DateFormat('d MMM'),
    _ => DateFormat('HH'),
  };
  return (
    f.format(times.first),
    f.format(times[times.length ~/ 2]),
    f.format(times.last),
  );
}

/// A card of the screen: title (and a muted note), the headline value on the
/// right in mono, the chart, an optional legend.
class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.chart,
    this.note,
    this.footer,
  });

  final String title;
  final String? note;
  final String value;
  final Widget chart;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: title, style: context.text.titleMedium),
                    if (note case final n?)
                      TextSpan(
                        text: ' · $n',
                        style: context.text.bodyMedium!.copyWith(
                          color: context.delve.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: DelveTokens.space3),
            Text(
              value,
              key: const Key('obs.value'),
              textAlign: TextAlign.end,
              style: DelveText.mono.copyWith(color: context.colors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: DelveTokens.space3),
        chart,
        ?footer,
      ],
    ),
  );
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.range,
    required this.selected,
    required this.onSelected,
  });

  final StatsRange range;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ChoiceChip(
      key: Key('obs.range.${range.query}'),
      label: Text(switch (range) {
        StatsRange.day => l.obsRange24h,
        StatsRange.week => l.obsRange7d,
        StatsRange.month => l.obsRange30d,
      }),
      selected: selected,
      showCheckmark: true,
      side: selected
          ? BorderSide.none
          : BorderSide(color: context.colors.outline),
      onSelected: (_) => onSelected(),
    );
  }
}
