import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../app/system.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/system_ui.dart';

/// 13a/13c System: Hermes, llama-server (stop/start), GPUs. Asks again every
/// [kSystemPoll] while open (N47); `system.updated` arrives meanwhile.
class SystemScreen extends ConsumerStatefulWidget {
  const SystemScreen({super.key});

  @override
  ConsumerState<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends ConsumerState<SystemScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(quiet: true));
    _poll = Timer.periodic(
      kSystemPoll,
      (_) => unawaited(_refresh(quiet: true)),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool quiet = false}) async {
    try {
      await ref.read(systemProvider.notifier).refresh();
    } on Object catch (e) {
      if (quiet || !mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.systemLoadFailed(apiErrorText(l, e)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(systemProvider);
    final info = view.info;
    final error = view.error;
    return SubPage(
      title: l.moreSystem,
      actions: [
        IconButton(
          key: const Key('system.refresh'),
          tooltip: l.retry,
          onPressed: _refresh,
          icon: const SymbolIcon(DelveIcons.refresh),
        ),
      ],
      child: switch (info) {
        null when error != null => Padding(
          padding: const EdgeInsets.all(DelveTokens.space4),
          child: Align(
            alignment: Alignment.topCenter,
            child: StatusBanner(
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.systemLoadFailed(apiErrorText(l, error)),
              actionLabel: l.retry,
              onAction: _refresh,
            ),
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
        final SystemInfo data => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space2,
              DelveTokens.space4,
              DelveTokens.space6,
            ),
            children: [
              if (!data.helper.ok) ...[
                StatusBanner(
                  key: const Key('system.helper'),
                  kind: StatusKind.warn,
                  icon: DelveIcons.warning,
                  text: data.helper.error == 'helper_unavailable'
                      ? l.systemHelperMissing
                      : l.systemHelperProblem(data.helper.error ?? ''),
                ),
                const SizedBox(height: DelveTokens.space3),
              ],
              if (error != null) ...[
                StatusBanner(
                  kind: StatusKind.warn,
                  icon: DelveIcons.syncProblem,
                  text: l.systemLoadFailed(apiErrorText(l, error)),
                  actionLabel: l.retry,
                  onAction: _refresh,
                ),
                const SizedBox(height: DelveTokens.space3),
              ],
              HermesCard(info: data, now: DateTime.now()),
              const SizedBox(height: DelveTokens.space3),
              LlamaCard(info: data),
              if (data.gpus case final gpus? when gpus.isNotEmpty) ...[
                const SizedBox(height: DelveTokens.space3),
                GpuCard(gpus: gpus, checkedAt: data.checkedAt),
              ],
            ],
          ),
        ),
      },
    );
  }
}

/// Hermes Agent: status (with what makes it degraded), version, uptime, queue.
class HermesCard extends StatelessWidget {
  const HermesCard({super.key, required this.info, required this.now});
  final SystemInfo info;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = info.hermes;
    final q = info.queue;
    final queue = [
      if (q.active > 0) l.systemQueueActive(q.active),
      if (q.queued > 0) l.systemQueueQueued(q.queued),
    ];
    final none = l.settingsUnknown;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: l.systemHermes,
            note: l.systemChecked(clockTime(info.checkedAt, now)),
          ),
          InfoRow(label: l.systemStatus, trailing: hermesChip(l, h.status)),
          for (final issue in h.issues)
            InfoRow(
              label: _capitalized(issue.check),
              value: issue.detail ?? issue.status,
              valueColor: context.delve.warnFg,
            ),
          InfoRow(
            label: l.systemVersion,
            value: h.version == null ? none : 'v${h.version}',
          ),
          InfoRow(
            label: l.systemUptime,
            value: h.since == null
                ? none
                : uptimeText(now.difference(h.since!)),
          ),
          InfoRow(
            key: const Key('system.queue'),
            label: l.systemQueue,
            value: queue.isEmpty ? '0' : queue.join(' · '),
          ),
        ],
      ),
    );
  }
}

/// llama-server: state since when, model, context, slots, speed; why queued
/// messages wait; the stop/start button.
class LlamaCard extends StatelessWidget {
  const LlamaCard({super.key, required this.info});
  final SystemInfo info;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ll = info.llama;
    final none = l.settingsUnknown;
    final running = ll.status == 'running';
    final model = ll.model == null ? none : [ll.model!, ?ll.quant].join(' · ');
    final slots = ll.slots;
    final busy = ll.slotsBusy ?? 0;
    final waiting = ll.intent == 'stopped';
    final loading =
        ll.intent == 'starting' ||
        (ll.status == 'loading' && info.queue.queued > 0);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(title: l.systemLlama),
          InfoRow(
            label: l.systemStatus,
            trailing: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: DelveTokens.space3,
              children: [
                llamaChip(l, ll.status),
                if (ll.since case final since?)
                  Text(
                    l.systemSince(clockTime(since, DateTime.now())),
                    style: DelveText.mono.copyWith(
                      color: context.delve.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          InfoRow(label: l.systemModel, value: model),
          InfoRow(
            label: l.systemContext,
            value: ll.ctx == null ? none : l.systemTokens(tokenCount(ll.ctx!)),
          ),
          InfoRow(
            label: l.systemSlots,
            value: slots == null
                ? none
                : busy > 0
                ? l.systemSlotsBusy(busy, slots)
                : l.systemSlotsIdle(busy, slots),
          ),
          if (running && ll.genTps != null)
            InfoRow(
              label: l.systemGeneration,
              value: l.systemTps(ll.genTps!.toStringAsFixed(1)),
            ),
          if (waiting || loading) ...[
            const SizedBox(height: DelveTokens.space2),
            StatusBanner(
              key: const Key('system.waiting'),
              kind: StatusKind.info,
              icon: DelveIcons.hourglass,
              text: waiting
                  ? l.systemHeldQueue(info.queue.queued)
                  : l.systemLoadingNote,
            ),
          ],
          const SizedBox(height: DelveTokens.space4),
          LlamaButton(info: info),
        ],
      ),
    );
  }
}

/// GPUs: name, temperature, power, memory with its bar.
class GpuCard extends StatelessWidget {
  const GpuCard({super.key, required this.gpus, required this.checkedAt});
  final List<GpuInfo> gpus;
  final DateTime checkedAt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: l.systemGpus,
            note: l.systemGpuSource(
              ageText(DateTime.now().difference(checkedAt)),
            ),
          ),
          for (final g in gpus) GpuRow(gpu: g),
        ],
      ),
    );
  }
}

String _capitalized(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
