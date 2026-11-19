import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../app/chat.dart';
import '../../app/system.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/live_runs.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../chat/approval_card.dart';
import '../chat/chat_items.dart' show thoughtSeconds;
import '../chat/thinking_block.dart';
import '../chat/tool_step_card.dart';
import '../chat/usage.dart';
import '../general/general_usage.dart';
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

/// A run (and a step of it) picked in the chat for the inspector – the
/// context menus' “Show in inspector” (L2b2).
@immutable
class InspectorPin {
  const InspectorPin(this.conversationId, this.runId, [this.stepId]);

  final String conversationId;
  final String runId;
  final int? stepId;

  @override
  bool operator ==(Object other) =>
      other is InspectorPin &&
      other.conversationId == conversationId &&
      other.runId == runId &&
      other.stepId == stepId;

  @override
  int get hashCode => Object.hash(conversationId, runId, stepId);
}

/// The pinned run; null: the inspector follows the live (else the newest)
/// run.
class InspectorPins extends Notifier<InspectorPin?> {
  @override
  InspectorPin? build() => null;

  void pin(InspectorPin pin) => state = pin;

  void clear() => state = null;
}

final inspectorPinProvider = NotifierProvider<InspectorPins, InspectorPin?>(
  InspectorPins.new,
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
                InspectorTab(
                  key: const Key('inspector.tab.run'),
                  label: l.desktopInspectorRun,
                  selected: tab == ChatInspectorTab.run,
                  onTap: () => ref
                      .read(chatInspectorTabProvider.notifier)
                      .show(ChatInspectorTab.run),
                ),
                InspectorTab(
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

/// A General chat's inspector (L2b2): one tab, Usage – the phone's General
/// Usage sheet.
class GeneralInspector extends StatelessWidget {
  const GeneralInspector({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      key: const Key('inspector.general'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: DelveDesktop.paneHeader,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                InspectorTab(label: l.usageTitle, selected: true, onTap: () {}),
                const Spacer(),
                const InspectorOverlayClose(),
              ],
            ),
          ),
        ),
        Expanded(child: GeneralUsageSheet(chatId: chatId, embedded: true)),
      ],
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
  /// The step whose output shows; null: the pinned one, else the newest.
  int? _selected;

  /// The pin last seen: a new pin drops the step picked here.
  InspectorPin? _pinSeen;

  /// The finished run the usage was fetched again for (once: a run that
  /// ended after the fetch is not in it yet).
  String? _refetchedFor;

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

  /// The model that wrote [run]: from the chat's usage (fetched once more
  /// when a finished run is not in it yet); a live run: the loaded model.
  String? _modelOf(RunRow run, LiveRun? live) {
    final id = widget.conversationId;
    final usage = ref.watch(conversationUsageProvider(id)).value;
    final known = usage?.runs.where((r) => r.runId == run.runId).firstOrNull;
    if (known?.model case final m?) return m;
    if (live != null || openRunStatuses.contains(run.status)) {
      return ref.watch(systemProvider.select((v) => v.info?.llama.model));
    }
    if (usage != null && known == null && _refetchedFor != run.runId) {
      _refetchedFor = run.runId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(conversationUsageProvider(id));
      });
    }
    return usage?.lastModel;
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
    final pin = ref.watch(inspectorPinProvider);
    if (pin != _pinSeen) {
      _pinSeen = pin;
      _selected = null;
    }
    final latest = data == null ? null : inspectedRun(data, live);
    final pinned = data != null && pin != null && pin.conversationId == id
        ? data.runs[pin.runId]
        : null;
    final run = pinned ?? latest;
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
    final wanted = _selected ?? (pinned == null ? null : pin?.stepId);
    final selected =
        steps.where((s) => s.id == wanted).firstOrNull ?? steps.lastOrNull;
    final liveHere = live != null && live.runId == run.runId ? live : null;
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
    final answer = data.messages
        .where((m) => m.role == 'assistant' && m.runId == run.runId)
        .firstOrNull;
    final thinking = run.thinking || (liveHere?.thinking ?? false);
    final model = _modelOf(run, liveHere);

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
        Row(
          children: [
            Expanded(child: eyebrow(l.desktopInspectorRun)),
            // a pinned older run: back to the one the chat is at
            if (pinned != null && pinned.runId != latest?.runId)
              TextButton(
                key: const Key('inspector.run.latest'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    ref.read(inspectorPinProvider.notifier).clear(),
                child: Text(l.desktopInspectorLatest),
              ),
          ],
        ),
        Text(
          runLine,
          key: const Key('inspector.run.line'),
          style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
        ),
        if (model != null) ...[
          eyebrow(l.desktopInspectorModel),
          Text(
            model,
            key: const Key('inspector.run.model'),
            style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        if (thinking) ...[
          eyebrow(l.desktopInspectorThinking),
          _Thinking(run: run, live: liveHere, answer: answer),
        ],
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

/// Shows [runId] of [conversationId] (and [stepId], its output) on the
/// inspector's Run tab, opening the inspector (“Show in inspector”).
void showRunInInspector(
  WidgetRef ref,
  BuildContext context, {
  required String area,
  required String conversationId,
  required String runId,
  int? stepId,
}) {
  ref
      .read(inspectorPinProvider.notifier)
      .pin(InspectorPin(conversationId, runId, stepId));
  showChatInspectorTab(ref, context, area, ChatInspectorTab.run);
}

/// The run's thinking in the inspector (design 27W-2c): live, the clock and
/// the tokens; afterwards how long, and the whole reasoning as selectable
/// text (the server sends it when the run ends).
class _Thinking extends StatelessWidget {
  const _Thinking({
    required this.run,
    required this.live,
    required this.answer,
  });

  final RunRow run;
  final LiveRun? live;
  final MessageRow? answer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final live = this.live;
    if (live != null && live.isThinking) {
      return ThinkingBlock(
        key: const Key('inspector.thinking.live'),
        live: true,
        since: run.startedAt ?? live.startedAt,
        tokens: live.contextGrowth,
      );
    }
    final seconds = thoughtSeconds(run, live);
    final reasoning = answer?.reasoning?.trim();
    return Column(
      key: const Key('inspector.thinking'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          seconds == null
              ? l.thinkingThought
              : l.thinkingThoughtFor(formatDuration(seconds)),
          style: context.text.labelMedium!.copyWith(color: d.textMuted),
        ),
        const SizedBox(height: 6),
        if (reasoning == null || reasoning.isEmpty)
          Text(
            l.desktopInspectorReasoningLater,
            style: context.text.bodySmall!.copyWith(color: d.textMuted),
          )
        else
          Container(
            key: const Key('inspector.thinking.text'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DelveTokens.rsm),
            ),
            child: SelectableText(
              reasoning,
              style: context.text.bodySmall!.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
