import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/protocol.dart';
import '../../app/chat.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/live_runs.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../chat/approval_card.dart';
import '../chat/tool_step_card.dart';
import '../chat/usage.dart';
import '../widgets/page_scaffolds.dart';
import 'panes.dart';
import 'status_bar.dart' show clockText;

/// The chat inspector's tabs (design 27): the run, and Usage – the phone's
/// Usage sheet.
enum ChatInspectorTab { run, usage }

/// The chat inspector's open tab (Ctrl+] the next one, Ctrl+U and the
/// context chip: Usage).
class ChatInspectorTabs extends Notifier<ChatInspectorTab> {
  @override
  ChatInspectorTab build() => ChatInspectorTab.run;

  void show(ChatInspectorTab tab) => state = tab;

  void next() => state = ChatInspectorTab
      .values[(state.index + 1) % ChatInspectorTab.values.length];
}

final chatInspectorTabProvider =
    NotifierProvider<ChatInspectorTabs, ChatInspectorTab>(
      ChatInspectorTabs.new,
    );

/// An agent chat's inspector (L2b): a 48 px tab row (Run · Usage), then the
/// tab. Docked it has no close button (the content header's toggle closes
/// it); as an overlay it has one.
class ChatInspector extends ConsumerWidget {
  const ChatInspector({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tab = ref.watch(chatInspectorTabProvider);
    return Column(
      key: const Key('inspector.chat'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: DelveDesktop.paneHeader,
          child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 6),
            child: Row(
              children: [
                _Tab(
                  key: const Key('inspector.tab.run'),
                  label: l.desktopInspectorRun,
                  selected: tab == ChatInspectorTab.run,
                  onTap: () => ref
                      .read(chatInspectorTabProvider.notifier)
                      .show(ChatInspectorTab.run),
                ),
                _Tab(
                  key: const Key('inspector.tab.usage'),
                  label: l.usageTitle,
                  selected: tab == ChatInspectorTab.usage,
                  onTap: () => ref
                      .read(chatInspectorTabProvider.notifier)
                      .show(ChatInspectorTab.usage),
                ),
                const Spacer(),
                const InspectorOverlayClose(),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (tab) {
            ChatInspectorTab.run => RunInspector(
              conversationId: conversationId,
            ),
            ChatInspectorTab.usage => UsageSheet(
              conversationId: conversationId,
              title: '',
              embedded: true,
            ),
          },
        ),
      ],
    );
  }
}

/// A tab: `labelLarge` 13, selected 600 with a 2 px accent underline.
class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: DelveDesktop.paneHeader,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: context.text.labelLarge!.copyWith(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// The run an inspector shows: the live one, else the run of the newest
/// answer, else the newest run (null: none yet).
@visibleForTesting
RunRow? inspectedRun(ChatData data, LiveRun? live) {
  if (live != null) {
    final run = data.runs[live.runId];
    if (run != null) return run;
  }
  for (final m in data.messages.reversed) {
    final id = m.runId;
    if (m.role == 'assistant' && id != null && data.runs[id] != null) {
      return data.runs[id];
    }
  }
  RunRow? newest;
  for (final r in data.runs.values) {
    final at = r.startedAt ?? r.queuedAt;
    final best = newest?.startedAt ?? newest?.queuedAt;
    if (newest == null || (at != null && (best == null || at.isAfter(best)))) {
      newest = r;
    }
  }
  return newest;
}

/// The Run tab: the steps as 30 px rows (status icon, command, duration);
/// the selected step's full output in a well; an approval the run waits
/// for, answerable here; the context fill.
class RunInspector extends ConsumerStatefulWidget {
  const RunInspector({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<RunInspector> createState() => _RunInspectorState();
}

class _RunInspectorState extends ConsumerState<RunInspector> {
  /// The step whose output shows; null: the newest.
  int? _selected;

  Future<void> _answer(ApprovalRow a, ApprovalChoice choice) async {
    final l = AppLocalizations.of(context);
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    try {
      await actions.answer(a.requestId, choice);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.approvalFailed('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final id = widget.conversationId;
    final data = ref.watch(chatProvider(id)).value;
    final live = ref.watch(liveRunsProvider.select((m) => m[id]));
    final connected = ref.watch(
      connectionStatusProvider.select(
        (s) => s.value?.phase == ConnectionPhase.live,
      ),
    );
    final run = data == null ? null : inspectedRun(data, live);
    if (data == null || run == null) {
      return Center(
        key: const Key('inspector.run.none'),
        child: Text(
          l.desktopInspectorNoRun,
          style: context.text.bodyMedium!.copyWith(color: d.textMuted),
        ),
      );
    }
    final steps = data.steps[run.runId] ?? const <ToolStepRow>[];
    final selected =
        steps.where((s) => s.id == _selected).firstOrNull ?? steps.lastOrNull;
    final waiting = [
      for (final s in steps)
        if (data.approvals[s.approvalRequestId] case final a?)
          if (a.status == 'pending' || a.status == 'expired_in_hermes') a,
    ];
    final now = DateTime.now();
    final started = run.startedAt;
    final ended = run.endedAt;
    final hm = DateFormat('HH:mm');
    final runLine = switch ((started, ended)) {
      (final s?, final e?) =>
        '${hm.format(s.toLocal())} · ${clockText(e.difference(s))}',
      (final s?, null) => l.desktopStatusRun(clockText(now.difference(s))),
      _ => run.status,
    };
    final output = selected == null ? null : stepResultText(selected);
    final pct = data.conversation?.contextPct ?? live?.context?.pct;

    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: d.textMuted,
        ),
      ),
    );

    return ListView(
      key: const Key('inspector.run'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        eyebrow(l.desktopInspectorRun),
        Text(
          runLine,
          key: const Key('inspector.run.line'),
          style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
        ),
        if (steps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: DelveTokens.space2),
            child: Text(
              l.desktopInspectorNoSteps,
              style: context.text.bodySmall!.copyWith(color: d.textMuted),
            ),
          )
        else ...[
          const SizedBox(height: 6),
          for (final s in steps)
            _StepRow(
              step: s,
              approval: data.approvals[s.approvalRequestId],
              selected: s.id == selected?.id,
              onTap: () => setState(() => _selected = s.id),
            ),
          if (selected != null) ...[
            const SizedBox(height: DelveTokens.space2),
            Container(
              key: const Key('inspector.run.output'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(DelveTokens.rsm),
              ),
              child: SelectableText(
                output ?? l.desktopInspectorNoOutput,
                style: DelveText.mono.copyWith(
                  fontSize: 12,
                  color: output == null ? d.textMuted : d.codeFg,
                ),
              ),
            ),
          ],
        ],
        for (final a in waiting) ...[
          const SizedBox(height: DelveTokens.space3),
          ApprovalCard(
            key: ValueKey('inspector.approval.${a.requestId}'),
            approval: a,
            onAnswer: connected ? (choice) => _answer(a, choice) : null,
          ),
        ],
        if (pct != null) ...[
          eyebrow(l.desktopInspectorContext),
          ContextBar(pct: pct, height: 4),
          const SizedBox(height: DelveTokens.space1),
          Text(
            '${pct.round()} %',
            style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// A step in the inspector: 30 px, status icon 15, the command in mono 12
/// (one line), the duration.
class _StepRow extends StatefulWidget {
  const _StepRow({
    required this.step,
    required this.approval,
    required this.selected,
    required this.onTap,
  });

  final ToolStepRow step;
  final ApprovalRow? approval;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final d = context.delve;
    final s = widget.step;
    final (icon, color) = switch (stepLook(s, widget.approval)) {
      StepLook.ok => (DelveIcons.ok, d.okFg),
      StepLook.error => (DelveIcons.error, d.alertFg),
      StepLook.running => (DelveIcons.progress, cs.primary),
      StepLook.waiting => (DelveIcons.approvals, d.warnFg),
      StepLook.cancelled => (DelveIcons.cancel, d.textMuted),
      StepLook.denied => (DelveIcons.block, d.infoFg),
      StepLook.timeout => (DelveIcons.timerOff, d.infoFg),
      StepLook.blocked => (DelveIcons.gppBad, d.alertFg),
    };
    final command = s.preview?.trim();
    final duration = s.durationS;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: ValueKey('inspector.step.${s.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? cs.surfaceContainerHigh
                : _hover
                ? cs.surfaceContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DelveDesktop.rowRadius - 1),
          ),
          child: Row(
            children: [
              SymbolIcon(
                icon,
                size: 15,
                filled: icon == DelveIcons.approvals,
                color: color,
              ),
              const SizedBox(width: DelveTokens.space2),
              Expanded(
                child: Text(
                  command == null || command.isEmpty
                      ? s.tool
                      : displayCommand(command),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DelveText.mono.copyWith(
                    fontSize: 12,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (duration != null) ...[
                const SizedBox(width: DelveTokens.space2),
                Text(
                  formatDuration(duration),
                  style: DelveText.monoSmall.copyWith(color: d.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the chat inspector on [tab] in [area] (Ctrl+U, the context chip).
void showChatInspectorTab(
  WidgetRef ref,
  BuildContext context,
  String area,
  ChatInspectorTab tab,
) {
  ref.read(chatInspectorTabProvider.notifier).show(tab);
  final overlay =
      MediaQuery.sizeOf(context).width < DelveDesktop.inspectorOverlayBelow;
  final layouts = ref.read(paneLayoutsProvider.notifier);
  final p = layouts.of(area);
  if (overlay ? !p.inspectorOverlay : !p.inspectorOpen) {
    layouts.toggleInspector(area, overlay: overlay);
  }
}
