import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../app/layout.dart';
import '../../app/router.dart';
import '../../app/schedules.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart';
import '../desktop/desktop_row.dart';
import '../desktop/intake.dart'
    show ListCommandSlot, ListCommands, listCommandSlotProvider;
import '../desktop/layers.dart' show showDesktopConfirm;
import '../desktop/panes.dart' show InspectorFrame;
import '../format.dart';
import '../schedule_text.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 14a Schedules: the morning brief and the prompt schedules, each with its
/// timing, next and last run, an on/off switch and "Run now". On the desktop
/// (27W-7a) the list column of the Schedules area.
class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key, this.selected});

  /// The desktop: the schedule open in the content (its row is selected).
  final String? selected;

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  /// Switches flipped but not yet confirmed by the server.
  final Map<String, bool> _pending = {};

  /// Schedules whose "Run now" is on its way.
  final Set<String> _running = {};

  /// The desktop: the schedules in the order shown (J / K).
  List<String> _order = const [];
  late final ListCommandSlot _keys;
  late final PageCommandSlot _pageKeys;

  @override
  void initState() {
    super.initState();
    _keys = ref.read(listCommandSlotProvider);
    _pageKeys = ref.read(pageCommandSlotProvider);
    unawaited(_refresh(quiet: true));
  }

  @override
  void dispose() {
    _keys.unregister(this);
    _pageKeys.unregister(this);
    super.dispose();
  }

  /// J / K: the next / previous schedule (the first without one open).
  void _step(int by) {
    final order = _order;
    if (order.isEmpty) return;
    final at = widget.selected == null ? -1 : order.indexOf(widget.selected!);
    final next = at < 0 ? 0 : (at + by).clamp(0, order.length - 1);
    if (next == at) return;
    context.open(Routes.schedule(order[next]));
  }

  /// Ctrl+R: the list, and the open schedule's runs.
  Future<void> _refreshAll() async {
    final id = widget.selected;
    await _refresh();
    if (id == null || !mounted) return;
    try {
      await ref.read(scheduleRunsProvider(id).notifier).refresh();
    } on Object {
      // the inspector shows the failure
    }
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
    if (DesktopLayout.of(context)) return _desktop(context, l, view, now);
    return Scaffold(
      appBar: AppBar(
        leading: pageBackButton(context),
        title: Text(l.moreSchedules),
      ),
      floatingActionButton: items == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('schedules.new'),
              onPressed: () => context.open(Routes.newSchedule),
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
                  onTap: () => context.open(Routes.editSchedule(s.id)),
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

  /// The desktop's list column (27W-7a): a 48 px header with New schedule,
  /// the schedules as 52 px rows with their switches, the open one
  /// selected. J / K step through them, Ctrl+R reloads.
  Widget _desktop(
    BuildContext context,
    AppLocalizations l,
    SchedulesView view,
    DateTime now,
  ) {
    _keys.register(
      this,
      ListCommands(
        next: () => _step(1),
        previous: () => _step(-1),
        archive: () {},
        undo: () {},
      ),
    );
    _pageKeys.register(
      this,
      PageCommands(refresh: () => unawaited(_refreshAll())),
    );
    final items = view.items;
    final error = view.error;
    _order = [for (final s in items ?? const <Schedule>[]) s.id];
    return TopLevelPage(
      title: l.moreSchedules,
      background: context.colors.surfaceContainerLow,
      actions: [
        IconButton(
          key: const Key('schedules.new'),
          tooltip: l.schedulesNew,
          onPressed: () => context.open(Routes.newSchedule),
          icon: const SymbolIcon(
            DelveIcons.add,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
      ],
      child: switch (items) {
        null when error != null => Padding(
          padding: const EdgeInsets.all(DelveTokens.space3),
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
        final List<Schedule> list => ListView(
          key: const Key('schedules.list'),
          padding: const EdgeInsets.only(bottom: DelveTokens.space4),
          children: [
            for (final s in list)
              DesktopScheduleRow(
                schedule: s,
                now: now,
                selected: s.id == widget.selected,
                enabled: _pending[s.id] ?? s.enabled,
                switching: _pending.containsKey(s.id),
                onToggle: (on) => _toggle(s, on),
                onTap: () => context.open(Routes.schedule(s.id)),
              ),
            if (!list.any((s) => s.kind == 'prompt'))
              Padding(
                key: const Key('schedules.empty'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  l.schedulesEmptyBody,
                  style: DelveDesktopText.meta.copyWith(
                    color: context.delve.textMuted,
                  ),
                ),
              ),
          ],
        ),
      },
    );
  }
}

/// The desktop's switch: 40 × 24 (the phone's 52 × 32 scaled).
class DesktopSwitch extends StatelessWidget {
  const DesktopSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 24,
    child: FittedBox(
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
}

/// A schedule in the desktop's list column (27W-7a): a 52 px two-line row –
/// icon, name, and under it the timing and the next run (or Paused); the
/// last run's failure in `alert`; the switch on the right.
class DesktopScheduleRow extends StatelessWidget {
  const DesktopScheduleRow({
    super.key,
    required this.schedule,
    required this.now,
    required this.selected,
    required this.enabled,
    required this.switching,
    required this.onToggle,
    required this.onTap,
  });

  final Schedule schedule;
  final DateTime now;
  final bool selected;
  final bool enabled;
  final bool switching;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = schedule;
    final cs = context.colors;
    final d = context.delve;
    final failed = lastOutcome(s) == LastOutcome.failed;
    return DesktopRowFrame(
      key: Key('schedule.${s.id}'),
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          SymbolIcon(
            s.kind == 'brief' ? DelveIcons.brief : DelveIcons.schedules,
            size: 16,
            filled: selected,
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DelveDesktopText.rowTitle.copyWith(
                          color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (failed) ...[
                      const SizedBox(width: DelveTokens.space1),
                      Tooltip(
                        message: lastRunText(l, s, now),
                        child: SymbolIcon(
                          DelveIcons.error,
                          key: Key('schedule.${s.id}.failed'),
                          size: 14,
                          filled: true,
                          color: d.alertFg,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    scheduleTimingText(l, s),
                    if (enabled) nextRunText(l, s, now) else l.schedulesPaused,
                  ].join(' · '),
                  key: Key('schedule.${s.id}.timing'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DelveDesktopText.rowSecondary.copyWith(
                    color: enabled ? cs.onSurfaceVariant : d.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DelveTokens.space2),
          DesktopSwitch(
            key: Key('schedule.${s.id}.switch'),
            value: enabled,
            onChanged: switching ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

/// The desktop's page of one schedule (27W-7a): the timing and the switch,
/// Run now and Edit, the prompt, where it posts, thinking and the last run;
/// the runs are in the inspector. Edit opens the editor in the content.
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  bool _running = false;
  bool? _pending;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh() async {
    final l = AppLocalizations.of(context);
    try {
      await Future.wait([
        ref.read(schedulesProvider.notifier).refresh(),
        ref.read(scheduleRunsProvider(widget.id).notifier).refresh(),
      ]);
    } on Object catch (e) {
      _snack(l.schedulesLoadFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _toggle(bool on) async {
    final l = AppLocalizations.of(context);
    setState(() => _pending = on);
    try {
      await ref.read(schedulesProvider.notifier).change(widget.id, {
        'enabled': on,
      });
    } on Object catch (e) {
      _snack(l.schedulesSaveFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  Future<void> _runNow(Schedule s) async {
    final l = AppLocalizations.of(context);
    setState(() => _running = true);
    try {
      await ref.read(schedulesProvider.notifier).runNow(s.id);
      _snack(
        s.kind == 'brief' ? l.schedulesBriefWritten : l.schedulesRunQueued,
      );
      unawaited(
        ref
            .read(scheduleRunsProvider(s.id).notifier)
            .refresh()
            .catchError((Object _) {}),
      );
    } on Object catch (e) {
      _snack(l.schedulesRunFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _delete(Schedule s) async {
    final l = AppLocalizations.of(context);
    final ok = await showDesktopConfirm(
      context,
      title: l.schedDeleteTitle(s.name),
      body: l.schedDeleteBody,
      action: l.schedDeleteConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(schedulesProvider.notifier).delete(s.id);
      if (mounted) context.open(Routes.schedules);
    } on Object catch (e) {
      _snack(l.schedulesSaveFailed(apiErrorText(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(schedulesProvider);
    final s = view.byId(widget.id);
    if (s == null) {
      return DesktopPage(
        title: l.moreSchedules,
        child: view.items == null && view.error == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(DelveDesktop.contentGutter),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: StatusBanner(
                    kind: StatusKind.info,
                    icon: DelveIcons.info,
                    text: l.schedMissing,
                  ),
                ),
              ),
      );
    }
    final now = DateTime.now();
    final cs = context.colors;
    final d = context.delve;
    final enabled = _pending ?? s.enabled;
    final failed = lastOutcome(s) == LastOutcome.failed;
    final brief = s.kind == 'brief';
    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: d.textMuted,
        ),
      ),
    );
    final chat = s.conversationId;
    return DesktopPage(
      title: s.name,
      inspectorToggle: true,
      actions: [
        DesktopRefreshButton(
          buttonKey: const Key('schedule.page.refresh'),
          onPressed: () => unawaited(_refresh()),
        ),
        if (!brief)
          IconButton(
            key: const Key('schedule.page.delete'),
            tooltip: l.schedDelete,
            onPressed: () => unawaited(_delete(s)),
            icon: const SymbolIcon(
              DelveIcons.delete,
              size: DelveDesktop.iconButtonIcon,
            ),
          ),
      ],
      child: DesktopPageBody(
        key: const Key('schedule.page'),
        maxWidth: DelveDesktop.detailColumn,
        top: DelveTokens.space4,
        children: [
          if (failed)
            Padding(
              padding: const EdgeInsets.only(bottom: DelveTokens.space4),
              child: StatusBanner(
                key: const Key('schedule.page.failed'),
                kind: StatusKind.alert,
                icon: DelveIcons.error,
                // a missed time has no run to name and no error to quote
                text: scheduleMissed(s)
                    ? l.schedulesMissedWhy
                    : [lastRunText(l, s, now), ?s.lastError].join(' · '),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduleTimingText(l, s),
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? nextRunText(l, s, now) : l.schedulesPaused,
                      key: const Key('schedule.page.next'),
                      style: context.text.bodySmall!.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DesktopSwitch(
                key: const Key('schedule.page.switch'),
                value: enabled,
                onChanged: _pending != null ? null : _toggle,
              ),
            ],
          ),
          const SizedBox(height: DelveTokens.space4),
          Wrap(
            spacing: DelveTokens.space2,
            runSpacing: DelveTokens.space2,
            children: [
              FilledButton.icon(
                key: const Key('schedule.page.run'),
                onPressed: _running ? null : () => unawaited(_runNow(s)),
                icon: _running
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SymbolIcon(DelveIcons.play, size: 16, filled: true),
                label: Text(l.schedulesRunNow),
              ),
              OutlinedButton.icon(
                key: const Key('schedule.page.edit'),
                onPressed: () => context.open(Routes.editSchedule(s.id)),
                icon: const SymbolIcon(DelveIcons.edit, size: 16),
                label: Text(l.schedEditTitle),
              ),
            ],
          ),
          if (brief) ...[
            const SizedBox(height: DelveTokens.space5),
            StatusBanner(
              kind: StatusKind.info,
              icon: DelveIcons.brief,
              text: l.schedBriefNote,
            ),
          ] else ...[
            eyebrow(l.schedPrompt),
            Container(
              key: const Key('schedule.page.prompt'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
              ),
              child: SelectableText(
                s.prompt ?? '',
                style: context.text.bodyMedium,
              ),
            ),
          ],
          eyebrow(l.desktopScheduleDetails),
          _Fact(label: l.desktopScheduleCron, value: s.cron, mono: true),
          _Fact(
            label: l.desktopScheduleLastRun,
            value: lastRunText(l, s, now),
            color: failed ? d.alertFg : null,
          ),
          if (!brief) ...[
            _Fact(
              label: l.schedPostTo,
              value: s.conversationMode == 'fixed'
                  ? s.conversationTitle ?? l.schedFixedChat
                  : l.schedNewChat,
              onTap: s.conversationMode == 'fixed' && chat != null
                  ? () => context.open(Routes.chat(chat))
                  : null,
            ),
            _Fact(
              label: l.schedThinking,
              value: s.thinking ? l.watchOn : l.watchOff,
            ),
          ],
        ],
      ),
    );
  }
}

/// A label (120) and its value on the schedule's page; a hairline under it.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.mono = false,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final bool mono;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final link = onTap != null;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: context.text.bodyMedium!.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? DelveText.mono.copyWith(color: color ?? cs.onSurface)
                  : context.text.bodyMedium!.copyWith(
                      color: link ? cs.primary : color,
                    ),
            ),
          ),
          if (link)
            SymbolIcon(DelveIcons.chevronRight, size: 16, color: cs.primary),
        ],
      ),
    );
    return link
        ? InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            child: row,
          )
        : row;
  }
}

/// The desktop's Runs inspector (27W-7a): the schedule's runs, newest first
/// – status, when, how long, the chat it went to (a click opens it). The
/// brief (and an older server) has only its last run.
class ScheduleRunsInspector extends ConsumerStatefulWidget {
  const ScheduleRunsInspector({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ScheduleRunsInspector> createState() =>
      _ScheduleRunsInspectorState();
}

class _ScheduleRunsInspectorState extends ConsumerState<ScheduleRunsInspector> {
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    // after the first frame: the refresh changes provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    try {
      await ref.read(scheduleRunsProvider(widget.id).notifier).refresh();
    } on Object {
      // shown in the inspector
    }
  }

  Future<void> _more() async {
    setState(() => _loadingMore = true);
    try {
      await ref.read(scheduleRunsProvider(widget.id).notifier).loadMore();
    } on Object {
      // the button stays; a second click tries again
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // a new run (Run now, the schedule firing) moves the last run on
    ref.listen(
      schedulesProvider.select((v) {
        final s = v.byId(widget.id);
        return (s?.lastRunId, s?.lastStatus, s?.lastRunAt);
      }),
      (before, now) {
        if (before != now) unawaited(_refresh());
      },
    );
    final s = ref.watch(schedulesProvider).byId(widget.id);
    final view = ref.watch(scheduleRunsProvider(widget.id));
    final now = DateTime.now();
    final muted = context.delve.textMuted;
    final items = view.items;
    final error = view.error;
    final Widget body;
    if (s != null && (s.kind == 'brief' || view.unsupported)) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          Text(
            lastRunText(l, s, now),
            key: const Key('inspector.runs.last'),
            style: context.text.bodyMedium!.copyWith(
              color: lastOutcome(s) == LastOutcome.failed
                  ? context.delve.alertFg
                  : null,
            ),
          ),
          const SizedBox(height: DelveTokens.space2),
          Text(
            s.kind == 'brief'
                ? l.desktopScheduleBriefRuns
                : l.desktopScheduleRunsOld,
            style: context.text.bodySmall!.copyWith(color: muted),
          ),
        ],
      );
    } else if (items == null) {
      body = error != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: StatusBanner(
                kind: StatusKind.alert,
                icon: DelveIcons.error,
                text: l.schedulesLoadFailed(apiErrorText(l, error)),
                actionLabel: l.retry,
                onAction: _refresh,
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          l.schedulesNotRunYet,
          key: const Key('inspector.runs.empty'),
          style: context.text.bodyMedium!.copyWith(color: muted),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
        children: [
          for (final r in items) _RunRow(run: r, now: now),
          if (view.next != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('inspector.runs.more'),
                onPressed: _loadingMore ? null : () => unawaited(_more()),
                child: Text(l.desktopScheduleOlderRuns),
              ),
            ),
        ],
      );
    }
    return InspectorFrame(
      key: const Key('inspector.runs'),
      label: l.desktopScheduleRunsTab,
      child: body,
    );
  }
}

/// One run in the Runs inspector: the status icon, when it was queued, how
/// long it ran; under it the chat it went to (or the error).
class _RunRow extends StatelessWidget {
  const _RunRow({required this.run, required this.now});

  final ScheduleRunEntry run;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = run;
    final cs = context.colors;
    final (kind, icon, word) = switch (r.status) {
      'completed' => (StatusKind.ok, DelveIcons.ok, l.schedulesStatusOk),
      'failed' => (StatusKind.alert, DelveIcons.error, l.schedulesStatusFailed),
      'cancelled' => (
        StatusKind.info,
        DelveIcons.cancel,
        l.schedulesStatusStopped,
      ),
      'queued' => (
        StatusKind.info,
        DelveIcons.hourglass,
        l.schedulesStatusQueued,
      ),
      _ => (StatusKind.info, DelveIcons.play, l.schedulesStatusRunning),
    };
    final fg = context.status(kind).fg;
    final started = r.startedAt;
    final ended = r.endedAt;
    final took = started != null && ended != null
        ? ageText(ended.difference(started))
        : null;
    final error = r.error;
    return DesktopRowFrame(
      key: Key('inspector.runs.${r.runId}'),
      onTap: () => context.open(Routes.chat(r.conversationId)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SymbolIcon(icon, size: 15, filled: true, color: fg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  [clockTime(r.queuedAt, now), word, ?took].join(' · '),
                  style: DelveDesktopText.rowTitle.copyWith(
                    color: cs.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  error ?? r.conversationTitle ?? l.newChat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DelveDesktopText.rowSecondary.copyWith(
                    color: error != null
                        ? context.delve.alertFg
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                        style: context.text.bodyLarge!.copyWith(
                          color: secondary,
                        ),
                      ),
                      const SizedBox(height: DelveTokens.space1),
                      Text(
                        enabled ? nextRunText(l, s, now) : l.schedulesPaused,
                        key: Key('schedule.${s.id}.next'),
                        style: context.text.bodyMedium!.copyWith(color: muted),
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
            // Spans under the switch too, so Run now ends on the right edge,
            // in line with the switch track.
            Padding(
              padding: const EdgeInsets.only(
                left: DelveTokens.iconLg + DelveTokens.space4,
              ),
              child: Row(
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
                  const SizedBox(width: DelveTokens.space2),
                  TextButton.icon(
                    key: Key('schedule.${s.id}.run'),
                    onPressed: running ? null : onRunNow,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsetsDirectional.only(
                        start: DelveTokens.space3,
                        end: DelveTokens.space1,
                      ),
                    ),
                    icon: running
                        ? const SizedBox.square(
                            dimension: DelveTokens.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
            ),
          ],
        ),
      ),
    );
  }
}
