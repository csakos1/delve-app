import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/dashboard.dart';
import '../../app/system.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/connection_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/system_ui.dart';
import '../widgets/water_chart.dart';

/// 12 Dashboard: connection, the Lake Balaton water level with its week (B2)
/// and the System card (B3). The morning brief arrives with B4.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _updated;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(quiet: true)); // the stored cards show meanwhile
  }

  Future<void> _refresh({bool quiet = false}) async {
    unawaited(_refreshSystem());
    final service = ref.read(dashboardServiceProvider);
    if (service == null) return;
    try {
      await service.refresh();
      if (mounted) setState(() => _updated = DateTime.now());
    } on Object catch (e) {
      if (quiet || !mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.approvalsRefreshFailed(apiErrorText(l, e)))),
      );
    }
  }

  /// The System card shows its own failure; no snackbar for it.
  Future<void> _refreshSystem() async {
    try {
      await ref.read(systemProvider.notifier).refresh();
    } on Object {
      // kept in SystemView.error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final readings = ref.watch(waterReadingsProvider);
    final updated = _updated;
    return TopLevelPage(
      title: l.navDashboard,
      actions: [
        if (updated != null)
          Padding(
            padding: const EdgeInsets.only(right: DelveTokens.space2),
            child: Text(
              l.dashUpdated(DateFormat('HH:mm').format(updated)),
              key: const Key('dashboard.updated'),
              style: context.text.bodyMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            0,
            DelveTokens.space4,
            DelveTokens.space6,
          ),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: _ConnectionPill(),
            ),
            const SizedBox(height: DelveTokens.space4),
            switch (readings) {
              AsyncData(:final value) when value.isNotEmpty => WaterCard(
                readings: value,
                now: DateTime.now(),
              ),
              AsyncData() || AsyncError() => const _WaterEmpty(),
              _ => const SizedBox(height: 320),
            },
            const SizedBox(height: DelveTokens.space3),
            const SystemCard(),
          ],
        ),
      ),
    );
  }
}

/// "Connected · tailnet" with a status dot, else the connection state's word.
class _ConnectionPill extends ConsumerWidget {
  const _ConnectionPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status =
        ref.watch(connectionStatusProvider).value ?? ConnectionStatus.initial;
    final view = ConnectionView.of(l, status);
    final c = context.status(view.kind);
    return Semantics(
      label: view.text,
      excludeSemantics: true,
      child: Container(
        height: DelveTokens.chip,
        padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space3),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(DelveTokens.chip / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: DelveTokens.space2),
            Flexible(
              child: Text(
                status.isLive ? l.dashConnected : view.chip,
                style: context.text.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Surface-1 card frame of the dashboard (radius 16).
class _DashCard extends StatelessWidget {
  const _DashCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DelveTokens.space4),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DelveTokens.rlg),
    ),
    child: child,
  );
}

/// "Lake Balaton water level": the latest reading (station and lake average),
/// the change against yesterday, and the week's chart.
class WaterCard extends StatelessWidget {
  const WaterCard({super.key, required this.readings, required this.now});

  /// Oldest first; the last one is shown.
  final List<WaterReading> readings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final last = readings.last;
    final local = last.cardTs.toLocal();
    final n = now.toLocal();
    final sameDay =
        local.year == n.year && local.month == n.month && local.day == n.day;
    final when = sameDay
        ? l.dashToday(DateFormat('HH:mm').format(local))
        : clockTime(last.cardTs, now);
    final trend = last.trendCm;
    final secondary = context.text.bodyMedium!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    Widget big(String label, double value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: secondary, overflow: TextOverflow.ellipsis),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${value.round()}',
                style: context.text.displaySmall,
              ),
              TextSpan(
                text: ' ${l.dashCm}',
                style: context.text.titleMedium!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(l.dashWaterTitle, style: context.text.titleLarge),
              ),
              const SizedBox(width: DelveTokens.space2),
              Text(
                when,
                key: const Key('water.time'),
                style: context.text.bodyMedium!.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DelveTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: big(last.station, last.levelCm)),
              if (last.lakeAvgCm case final avg?) ...[
                const SizedBox(width: DelveTokens.space6),
                Flexible(child: big(l.dashLakeAverage, avg)),
              ],
              if (trend != null) ...[
                const SizedBox(width: DelveTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.dashVsYesterday,
                        style: secondary,
                        textAlign: TextAlign.end,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SymbolIcon(
                            trend < 0
                                ? DelveIcons.arrowDown
                                : trend > 0
                                ? DelveIcons.arrowUp
                                : DelveIcons.arrowFlat,
                            size: DelveTokens.iconMd,
                          ),
                          const SizedBox(width: DelveTokens.space1),
                          Flexible(
                            child: Text(
                              '${signedCm(trend)} ${l.dashCm}',
                              key: const Key('water.trend'),
                              style: context.text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DelveTokens.space4),
          WaterChart(days: waterDays(readings, now)),
          const SizedBox(height: DelveTokens.space2),
          Wrap(
            spacing: DelveTokens.space4,
            children: [
              _Legend(label: last.station, dashed: false),
              if (last.lakeAvgCm != null)
                _Legend(label: l.dashLakeAverage, dashed: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.dashed});
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final color = dashed
        ? context.colors.onSurfaceVariant
        : context.colors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 2,
          child: dashed
              ? Row(
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
}

class _WaterEmpty extends StatelessWidget {
  const _WaterEmpty();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.dashWaterTitle, style: context.text.titleLarge),
          const SizedBox(height: DelveTokens.space3),
          StatusBanner(
            kind: StatusKind.info,
            icon: DelveIcons.water,
            text: l.dashWaterEmpty,
          ),
        ],
      ),
    );
  }
}

/// System (design 12): Hermes and llama-server with their state, the GPUs
/// (without power), and the stop/start button with the same dialog as 13b.
class SystemCard extends ConsumerWidget {
  const SystemCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(systemProvider);
    final info = view.info;
    if (info == null) {
      final error = view.error;
      if (error == null) return const SizedBox.shrink();
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHeader(title: l.systemTitle),
            StatusBanner(
              kind: StatusKind.warn,
              icon: DelveIcons.syncProblem,
              text: l.systemLoadFailed(apiErrorText(l, error)),
            ),
          ],
        ),
      );
    }
    final gpus = info.gpus;
    final muted = DelveText.mono.copyWith(color: context.delve.textMuted);
    Widget pair(Widget chip, String? text) => Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: DelveTokens.space3,
      children: [
        chip,
        if (text != null) Text(text, style: muted),
      ],
    );
    return SurfaceCard(
      key: const Key('dashboard.system'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: l.systemTitle,
            note: gpus == null ? null : l.systemGpuCount(gpus.length),
          ),
          InfoRow(
            label: l.systemHermesShort,
            trailing: pair(
              hermesChip(l, info.hermes.status),
              info.hermes.version == null ? null : 'v${info.hermes.version}',
            ),
          ),
          InfoRow(
            label: l.systemLlama,
            trailing: pair(llamaChip(l, info.llama.status), info.llama.model),
          ),
          for (final g in gpus ?? const <GpuInfo>[])
            GpuRow(gpu: g, showPower: false),
          if (info.llama.intent == 'stopped') ...[
            const SizedBox(height: DelveTokens.space2),
            StatusBanner(
              kind: StatusKind.info,
              icon: DelveIcons.hourglass,
              text: l.systemHeldQueue(info.queue.queued),
            ),
          ],
          const SizedBox(height: DelveTokens.space3),
          LlamaButton(info: info),
        ],
      ),
    );
  }
}
