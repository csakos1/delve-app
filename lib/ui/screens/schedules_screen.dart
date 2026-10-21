import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../app/router.dart';
import '../../app/schedules.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../schedule_text.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 14a Schedules: the morning brief and the prompt schedules, each with its
/// timing, next and last run, an on/off switch and "Run now".
class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  /// Switches flipped but not yet confirmed by the server.
  final Map<String, bool> _pending = {};

  /// Schedules whose "Run now" is on its way.
  final Set<String> _running = {};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(quiet: true));
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh({bool quiet = false}) async {
    try {
      await ref.read(schedulesProvider.notifier).refresh();
    } on Object catch (e) {
      if (quiet || !mounted) return;
      final l = AppLocalizations.of(context);
      _snack(l.schedulesLoadFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _toggle(Schedule s, bool on) async {
    final l = AppLocalizations.of(context);
    setState(() => _pending[s.id] = on);
    try {
      await ref.read(schedulesProvider.notifier).change(s.id, {'enabled': on});
    } on Object catch (e) {
      _snack(l.schedulesSaveFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _pending.remove(s.id));
    }
  }

  Future<void> _runNow(Schedule s) async {
    final l = AppLocalizations.of(context);
    setState(() => _running.add(s.id));
    try {
      await ref.read(schedulesProvider.notifier).runNow(s.id);
      _snack(
        s.kind == 'brief' ? l.schedulesBriefWritten : l.schedulesRunQueued,
      );
    } on Object catch (e) {
      _snack(l.schedulesRunFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _running.remove(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(schedulesProvider);
    final items = view.items;
    final error = view.error;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l.moreSchedules),
      ),
      floatingActionButton: items == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('schedules.new'),
              onPressed: () => context.push(Routes.newSchedule),
              icon: const SymbolIcon(DelveIcons.add),
              label: Text(l.schedulesNew),
            ),
      body: switch (items) {
        null when error != null => Padding(
          padding: const EdgeInsets.all(DelveTokens.space4),
          child: Align(
            alignment: Alignment.topCenter,
            child: StatusBanner(
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.schedulesLoadFailed(apiErrorText(l, error)),
              actionLabel: l.retry,
              onAction: _refresh,
            ),
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
        final List<Schedule> list => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(
              // clear of the extended FAB
              bottom:
                  DelveTokens.button + DelveTokens.space8 + DelveTokens.space4,
            ),
            children: [
              for (final (i, s) in list.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: DelveTokens.hairline,
                    indent: DelveTokens.space4 * 2 + DelveTokens.iconLg,
                  ),
                ScheduleRow(
                  schedule: s,
                  now: now,
                  enabled: _pending[s.id] ?? s.enabled,
                  switching: _pending.containsKey(s.id),
                  running: _running.contains(s.id),
                  onToggle: (on) => _toggle(s, on),
                  onRunNow: () => _runNow(s),
                  onTap: () => context.push(Routes.editSchedule(s.id)),
                ),
              ],
              if (!list.any((s) => s.kind == 'prompt'))
                Padding(
                  key: const Key('schedules.empty'),
                  padding: const EdgeInsets.all(DelveTokens.space4),
                  child: StatusBanner(
                    kind: StatusKind.info,
                    icon: DelveIcons.schedules,
                    text: l.schedulesEmptyBody,
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}

/// One schedule (design 14a): icon, name, timing, next run, last run with
/// "Run now", and the switch on the right.
class ScheduleRow extends StatelessWidget {
  const ScheduleRow({
    super.key,
    required this.schedule,
    required this.now,
    required this.enabled,
    required this.switching,
    required this.running,
    required this.onToggle,
    required this.onRunNow,
    required this.onTap,
  });

  final Schedule schedule;
  final DateTime now;
  final bool enabled;
  final bool switching;
  final bool running;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRunNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = schedule;
    final muted = context.delve.textMuted;
    final secondary = context.colors.onSurfaceVariant;
    final failed = lastOutcome(s) == LastOutcome.failed;
    return InkWell(
      key: Key('schedule.${s.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          DelveTokens.space4,
          DelveTokens.space4,
          DelveTokens.space1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SymbolIcon(
              s.kind == 'brief' ? DelveIcons.brief : DelveIcons.schedules,
              color: secondary,
            ),
            const SizedBox(width: DelveTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: context.text.titleSmall!.copyWith(
                      color: enabled ? null : secondary,
                    ),
                  ),
                  const SizedBox(height: DelveTokens.space1),
                  Text(
                    scheduleTimingText(l, s),
                    key: Key('schedule.${s.id}.timing'),
                    style: context.text.bodyLarge!.copyWith(color: secondary),
                  ),
                  const SizedBox(height: DelveTokens.space1),
                  Text(
                    enabled ? nextRunText(l, s, now) : l.schedulesPaused,
                    key: Key('schedule.${s.id}.next'),
                    style: context.text.bodyMedium!.copyWith(color: muted),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastRunText(l, s, now),
                          key: Key('schedule.${s.id}.last'),
                          style: context.text.bodyMedium!.copyWith(
                            color: failed ? context.delve.alertFg : muted,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: Key('schedule.${s.id}.run'),
                        onPressed: running ? null : onRunNow,
                        icon: running
                            ? const SizedBox.square(
                                dimension: DelveTokens.iconSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const SymbolIcon(
                                DelveIcons.play,
                                size: DelveTokens.iconMd,
                                filled: true,
                              ),
                        label: Text(l.schedulesRunNow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: DelveTokens.space2),
            Switch(
              key: Key('schedule.${s.id}.switch'),
              value: enabled,
              onChanged: switching ? null : onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
