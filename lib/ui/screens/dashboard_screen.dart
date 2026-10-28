import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/dashboard.dart';
import '../../app/router.dart';
import '../../app/system.dart';
import '../../app/watches.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../links.dart';
import '../schedule_text.dart';
import '../widgets/chart_paint.dart';
import '../widgets/connection_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/system_ui.dart';
import '../widgets/water_chart.dart';

/// 12 Dashboard: connection, the Lake Balaton water level with its week (B2),
/// the morning brief (B4), the watches' newest hits (W3) and the System card
/// (B3).
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
    unawaited(_refreshWatches());
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

  /// The Watches card keeps what it had when this fails.
  Future<void> _refreshWatches() async {
    try {
      await ref.read(watchesProvider.notifier).refresh();
    } on Object {
      // kept in WatchesView.error
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
      tintOnScroll: true,
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
            const BriefCard(),
            const WatchesCard(),
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
            // The readings keep their width and the trend ends on the right
            // edge: the unused share of the loose readings block goes between
            // them, not after the trend.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(child: big(last.station, last.levelCm)),
                    if (last.lakeAvgCm case final avg?) ...[
                      const SizedBox(width: DelveTokens.space6),
                      Flexible(child: big(l.dashLakeAverage, avg)),
                    ],
                  ],
                ),
              ),
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
              ChartLegend(
                label: last.station,
                color: context.colors.primary,
                dashed: false,
                markKey: const Key('water.legend.solid'),
              ),
              if (last.lakeAvgCm != null)
                ChartLegend(
                  label: l.dashLakeAverage,
                  color: context.colors.onSurfaceVariant,
                  dashed: true,
                  markKey: const Key('water.legend.dashed'),
                ),
            ],
          ),
        ],
      ),
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
    // the version or model, then the state last in the row
    Widget pair(String? text, Widget status) => Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: DelveTokens.space3,
      children: [
        if (text != null) Text(text, style: muted),
        status,
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
              info.hermes.version == null ? null : 'v${info.hermes.version}',
              hermesStatus(l, info.hermes.status),
            ),
          ),
          InfoRow(
            label: l.systemLlama,
            trailing: pair(info.llama.model, llamaStatus(l, info.llama.status)),
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

/// Morning brief (design 12): uptime, package updates and open incidents in a
/// recessed row, then llama-server and the last boot. Written by the backend
/// each morning; nothing shows before the first one.
class BriefCard extends ConsumerWidget {
  const BriefCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(latestBriefProvider).value;
    if (reading == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final b = reading.brief;
    final now = DateTime.now();
    final open = b.openIncidents;
    final booted = b.bootedAt;
    final firstIncident = b.incidents.isEmpty ? null : b.incidents.first;
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space3),
      child: SurfaceCard(
        key: const Key('dashboard.brief'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHeader(
              title: l.dashBriefTitle,
              note: switch (b.lateByS) {
                // written after the desktop was switched on (N74)
                final s? when s > 0 => l.dashBriefLate(
                  clockTime(reading.card.ts, now),
                  uptimeText(Duration(seconds: s)),
                ),
                _ => clockTime(reading.card.ts, now),
              },
            ),
            _BriefTiles(
              uptime: b.uptimeS == null
                  ? null
                  : uptimeText(Duration(seconds: b.uptimeS!)),
              updates: b.updatesCount,
              incidents: open,
            ),
            const SizedBox(height: DelveTokens.space2),
            if (b.llamaState case final state?)
              InfoRow(label: l.systemLlama, trailing: llamaStatus(l, state)),
            if (booted != null)
              InfoRow(
                label: l.dashBriefLastBoot,
                value: DateFormat('EEE d MMM HH:mm').format(booted.toLocal()),
              ),
            if (firstIncident != null) ...[
              const SizedBox(height: DelveTokens.space2),
              StatusBanner(
                key: const Key('brief.incident'),
                kind: StatusKind.warn,
                icon: DelveIcons.warning,
                text: [
                  firstIncident.job ?? firstIncident.id,
                  ?firstIncident.error,
                ].join(' · '),
              ),
            ],
            if (b.missing.isNotEmpty) ...[
              const SizedBox(height: DelveTokens.space2),
              Text(
                l.dashBriefMissing(b.missing.join(', ')),
                key: const Key('brief.missing'),
                style: context.text.bodyMedium!.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The three figures of the brief side by side in a recessed well.
class _BriefTiles extends StatelessWidget {
  const _BriefTiles({this.uptime, this.updates, this.incidents});
  final String? uptime;
  final int? updates;
  final int? incidents;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final divider = VerticalDivider(
      width: DelveTokens.space4,
      thickness: DelveTokens.hairline,
      color: context.colors.outlineVariant,
    );
    final inc = incidents;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DelveTokens.space4,
        vertical: DelveTokens.space3,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Tile(
                key: const Key('brief.uptime'),
                label: l.dashBriefUptime,
                value: uptime ?? '—',
              ),
            ),
            divider,
            Expanded(
              child: _Tile(
                key: const Key('brief.updates'),
                label: l.dashBriefUpdates,
                value: updates?.toString() ?? '—',
              ),
            ),
            divider,
            Expanded(
              child: _Tile(
                key: const Key('brief.incidents'),
                label: l.dashBriefIncidents,
                value: inc?.toString() ?? '—',
                status: inc == null
                    ? null
                    : inc == 0
                    ? StatusKind.ok
                    : StatusKind.warn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.value,
    this.status,
  });
  final String label;
  final String value;
  final StatusKind? status;

  @override
  Widget build(BuildContext context) {
    final kind = status;
    final c = kind == null ? null : context.status(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DelveTokens.space1),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                style: context.text.titleLarge!.copyWith(
                  color: kind == StatusKind.warn ? c!.fg : null,
                ),
              ),
            ),
            if (c != null) ...[
              const SizedBox(width: DelveTokens.space2),
              SymbolIcon(
                kind == StatusKind.ok ? DelveIcons.ok : DelveIcons.warning,
                size: DelveTokens.iconMd,
                filled: true,
                color: c.fg,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Watches (design 21d), between the brief and System, when at least one
/// watch exists: how many are active and the newest hits with Open link, or
/// "No hits yet" and the next check. The header opens the list.
class WatchesCard extends ConsumerWidget {
  const WatchesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(watchesProvider);
    final items = view.items;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final recent = view.recent ?? const <RecentHit>[];
    final muted = context.delve.textMuted;
    final next = [
      for (final w in items)
        if (!w.paused) ?w.nextRunAt,
    ]..sort();
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space3),
      child: Container(
        key: const Key('dashboard.watches'),
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          DelveTokens.space3,
          DelveTokens.space4,
          DelveTokens.space1,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DelveTokens.rlg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const Key('dashboard.watches.open'),
              onTap: () => context.push(Routes.watches),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: DelveTokens.touchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.dashWatchesTitle,
                        style: context.text.titleMedium,
                      ),
                    ),
                    Text(
                      l.dashWatchesActive(view.active),
                      style: context.text.labelMedium!.copyWith(color: muted),
                    ),
                    const SizedBox(width: DelveTokens.space1),
                    SymbolIcon(DelveIcons.chevronRight, size: 22, color: muted),
                  ],
                ),
              ),
            ),
            if (recent.isEmpty)
              Padding(
                key: const Key('dashboard.watches.empty'),
                padding: const EdgeInsets.only(bottom: DelveTokens.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.watchNoHitsYet, style: context.text.bodyMedium),
                    if (next.isNotEmpty)
                      Text(
                        l.dashWatchesNext(aheadText(l, next.first, now)),
                        style: context.text.bodySmall!.copyWith(color: muted),
                      ),
                  ],
                ),
              )
            else
              for (final r in recent) _RecentHitLine(hit: r, now: now),
          ],
        ),
      ),
    );
  }
}

/// One hit on the Dashboard card: title, "price · watch" (or the marker
/// word), time, Open link.
class _RecentHitLine extends ConsumerWidget {
  const _RecentHitLine({required this.hit, required this.now});

  final RecentHit hit;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final i = hit.item;
    final secondary = context.colors.onSurfaceVariant;
    final meta = context.text.labelMedium!.copyWith(color: secondary);
    final (word, color) = i.reserved
        ? (l.watchItemOnHold, context.delve.warnFg)
        : i.availableAgain
        ? (l.watchItemAvailable, context.delve.okFg)
        : (hit.watchName, secondary);
    return InkWell(
      key: Key('dashboard.watches.hit.${i.id}'),
      onTap: () => openLink(context, ref, i.url),
      onLongPress: () => copyLink(context, i.url),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (i.price case final p? when p.isNotEmpty)
                          TextSpan(text: '$p · '),
                        TextSpan(
                          text: word,
                          style: TextStyle(color: color),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: meta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DelveTokens.space2),
            Text(
              listTime(i.seenAt, now),
              style: context.text.labelMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
            IconButton(
              tooltip: l.watchOpenLink,
              onPressed: () => openLink(context, ref, i.url),
              icon: SymbolIcon(
                DelveIcons.openLink,
                size: DelveTokens.iconMd,
                color: secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
