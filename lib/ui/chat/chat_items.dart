import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models/models.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/live_runs.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import 'markdown.dart';
import 'tool_step_card.dart';

void _copyWithNote(BuildContext context, String text) {
  unawaited(Clipboard.setData(ClipboardData(text: text)));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).chatCopied)),
    );
}

/// The user's message: surface-2 bubble on the right (radius 16/16/4/16),
/// at most 86 % wide. Long press copies.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text, this.footer});

  final String text;

  /// Under the bubble (outbox state).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FractionallySizedBox(
          widthFactor: 0.86,
          alignment: Alignment.centerRight,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onLongPress: () => _copyWithNote(context, text),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DelveTokens.rlg),
                    topRight: Radius.circular(DelveTokens.rlg),
                    bottomLeft: Radius.circular(DelveTokens.rlg),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(text, style: context.text.bodyLarge),
              ),
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: DelveTokens.space1),
            child: footer,
          ),
      ],
    );
  }
}

/// A message the server has not acknowledged: the bubble with its state —
/// waiting for the connection, sending, or not sent (Retry / Discard).
class OutboxBubble extends StatelessWidget {
  const OutboxBubble({
    super.key,
    required this.row,
    required this.onRetry,
    required this.onDiscard,
  });

  final OutboxRow row;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final Widget footer;
    if (row.state == 'failed') {
      footer = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DelveTokens.space1,
        children: [
          SymbolIcon(
            DelveIcons.error,
            size: 14,
            filled: true,
            color: d.alertFg,
          ),
          Text(
            row.lastError == null
                ? l.outboxFailed
                : l.outboxFailedWhy(row.lastError!),
            style: context.text.labelSmall!.copyWith(color: d.alertFg),
          ),
          TextButton(onPressed: onRetry, child: Text(l.outboxRetry)),
          TextButton(onPressed: onDiscard, child: Text(l.outboxDiscard)),
        ],
      );
    } else {
      final sending = row.state == 'sending';
      footer = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(
            sending ? DelveIcons.sync : DelveIcons.schedule,
            size: 14,
            color: d.textMuted,
          ),
          const SizedBox(width: DelveTokens.space1),
          Text(
            sending ? l.outboxSending : l.outboxWaiting,
            style: context.text.labelSmall!.copyWith(color: d.textMuted),
          ),
        ],
      );
    }
    return UserBubble(
      key: ValueKey('outbox.${row.clientMsgId}'),
      text: row.body,
      footer: footer,
    );
  }
}

/// A system message (e.g. the late-approval prompt): centred, small.
class SystemLine extends StatelessWidget {
  const SystemLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space6),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.text.bodySmall!.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

/// One run: interim remarks, tool steps and the answer on a rail (indent
/// 20, 2 dp rail, 8 dp nodes). A run that is still going sits in a surface-1
/// container with an accent rail and a "running · m:ss" footer.
class RunBlock extends StatelessWidget {
  const RunBlock({
    super.key,
    required this.message,
    required this.run,
    required this.steps,
    required this.approvals,
    this.live,
    this.onRetry,
  });

  final MessageRow message;
  final RunRow? run;
  final List<ToolStepRow> steps;
  final Map<String, ApprovalRow> approvals;

  /// The streaming part, while this run streams.
  final LiveRun? live;

  /// Re-sends the message that started a failed run.
  final VoidCallback? onRetry;

  bool get active =>
      (run != null && openRunStatuses.contains(run!.status)) ||
      message.status == 'streaming';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final isActive = active;
    final railColor = isActive ? cs.primary : cs.outlineVariant;
    final nodeColor = isActive ? cs.primary : cs.surfaceContainerHighest;

    final live = this.live;
    final interim = live != null
        ? live.interim
        : [
            for (final s in (message.interim ?? '').split('\n\n'))
              if (s.trim().isNotEmpty) s.trim(),
          ];
    var text = message.content;
    if (live != null && live.text.isNotEmpty) {
      text = live.partial ? '…${live.text}' : live.text;
    }
    final failed = run?.status == 'failed' || message.status == 'failed';
    final cancelled =
        run?.status == 'cancelled' || message.status == 'cancelled';

    final items = <Widget>[
      for (final s in interim)
        _RailItem(
          rail: railColor,
          node: nodeColor,
          child: Text(
            s,
            style: context.text.bodyMedium!.copyWith(
              fontStyle: FontStyle.italic,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      for (final step in steps)
        _RailItem(
          rail: railColor,
          node: _stepNode(context, step, nodeColor),
          child: ToolStepCard(
            step: step,
            approval: step.approvalRequestId == null
                ? null
                : approvals[step.approvalRequestId],
          ),
        ),
      if (text.trim().isNotEmpty)
        _RailItem(
          rail: railColor,
          node: nodeColor,
          child: GestureDetector(
            onLongPress: () => _copyWithNote(context, message.content),
            child: DelveMarkdown(data: text),
          ),
        )
      else if (isActive && steps.isEmpty && interim.isEmpty)
        _RailItem(
          rail: railColor,
          node: nodeColor,
          child: Text(
            l.chatWorking,
            style: context.text.labelMedium!.copyWith(color: d.textMuted),
          ),
        ),
      if (failed)
        _RailItem(
          rail: railColor,
          node: d.alertFg,
          child: FailedRunCard(error: run?.error, onRetry: onRetry),
        )
      else if (cancelled)
        _RailItem(
          rail: railColor,
          node: d.infoFg,
          child: Text(
            l.chatRunStopped,
            style: context.text.labelMedium!.copyWith(color: d.textMuted),
          ),
        ),
      if (isActive)
        _RailItem(
          rail: railColor,
          node: nodeColor,
          last: true,
          child: _RunningFooter(
            since: run?.startedAt ?? live?.startedAt ?? message.createdAt,
            waiting: run?.status == 'waiting_for_approval',
            queued: run?.status == 'queued',
          ),
        ),
    ];

    final column = Column(
      key: ValueKey('run.${message.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
    if (!isActive) return column;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space3,
        DelveTokens.space3,
        DelveTokens.space3,
        DelveTokens.space2 + 2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(
          color: cs.primaryContainer,
          width: DelveTokens.hairline,
        ),
        borderRadius: BorderRadius.circular(DelveTokens.rlg),
      ),
      child: column,
    );
  }

  Color _stepNode(BuildContext context, ToolStepRow step, Color normal) {
    final d = context.delve;
    final approval = step.approvalRequestId == null
        ? null
        : approvals[step.approvalRequestId];
    return switch (stepLook(step, approval)) {
      StepLook.waiting => d.warnFg,
      StepLook.error || StepLook.blocked => d.alertFg,
      _ => normal,
    };
  }
}

/// One entry on the run rail: the rail segment, its node, the content.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.rail,
    required this.node,
    required this.child,
    this.last = false,
  });

  final Color rail;
  final Color node;
  final Widget child;

  /// The rail ends at this node.
  final bool last;

  static const double indent = 20;
  static const double nodeSize = 8;
  static const double nodeTop = 8;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 3,
          top: 0,
          bottom: last ? null : 0,
          height: last ? nodeTop : null,
          child: Container(width: DelveTokens.railWidth, color: rail),
        ),
        Positioned(
          left: 0,
          top: nodeTop,
          child: Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(color: node, shape: BoxShape.circle),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: indent,
            bottom: last ? 0 : DelveTokens.space2,
          ),
          child: child,
        ),
      ],
    );
  }
}

/// "running · 1:47" — ticks every second while shown.
class _RunningFooter extends StatefulWidget {
  const _RunningFooter({
    required this.since,
    required this.waiting,
    required this.queued,
  });

  final DateTime since;
  final bool waiting;
  final bool queued;

  @override
  State<_RunningFooter> createState() => _RunningFooterState();
}

class _RunningFooterState extends State<_RunningFooter> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final elapsed = DateTime.now().difference(widget.since);
    final secs = elapsed.isNegative ? 0 : elapsed.inSeconds;
    final clock = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final label = widget.queued
        ? l.chatRunQueued
        : widget.waiting
        ? l.chatRunWaiting(clock)
        : l.chatRunRunning(clock);
    return Text(
      label,
      key: const Key('run.footer'),
      style: DelveText.monoSmall.copyWith(
        color: widget.waiting ? d.warnFg : cs.primary,
      ),
    );
  }
}

/// 09: the run failed — what happened and a Retry that sends the message
/// again.
class FailedRunCard extends StatelessWidget {
  const FailedRunCard({super.key, required this.error, this.onRetry});

  /// The backend's error code or text (`run_lost`, `stream_unstable`, …).
  final String? error;
  final VoidCallback? onRetry;

  static String reason(AppLocalizations l, String? error) => switch (error) {
    null || '' => l.runFailedUnknown,
    'run_lost' => l.runFailedLost,
    'stream_unstable' => l.runFailedUnstable,
    final e when e.startsWith('hermes_') => l.runFailedHermes(e),
    final e => e,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.status(StatusKind.alert);
    return Container(
      key: const Key('run.failed'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space3,
        DelveTokens.space3,
        DelveTokens.space2,
        DelveTokens.space3,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border, width: DelveTokens.hairline),
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: Row(
        children: [
          SymbolIcon(
            DelveIcons.error,
            size: DelveTokens.iconMd,
            filled: true,
            color: c.fg,
          ),
          const SizedBox(width: DelveTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.runFailed, style: context.text.titleSmall),
                Text(
                  reason(l, error),
                  style: context.text.bodySmall!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const SymbolIcon(
                DelveIcons.refresh,
                size: DelveTokens.iconMd,
              ),
              label: Text(l.runRetry),
            ),
        ],
      ),
    );
  }
}
