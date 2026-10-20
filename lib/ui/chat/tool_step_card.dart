import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// How a tool step reads (07 Tool step states).
enum StepLook {
  running,
  waiting,
  ok,
  error,
  cancelled,
  denied,
  timeout,
  blocked,
}

StepLook stepLook(ToolStepRow step, ApprovalRow? approval) {
  switch (step.status) {
    case 'ok':
      return StepLook.ok;
    case 'error':
      return StepLook.error;
    case 'cancelled':
      return StepLook.cancelled;
    case 'denied':
      return StepLook.denied;
    case 'timeout':
      return StepLook.timeout;
    case 'blocked':
      return StepLook.blocked;
  }
  final waiting =
      approval != null &&
      (approval.status == 'pending' || approval.status == 'expired_in_hermes');
  return waiting ? StepLook.waiting : StepLook.running;
}

/// Seconds as the card meta shows them: `0.4 s`, `12 s`, `1:05`.
String formatDuration(double seconds) {
  if (seconds < 10) return '${seconds.toStringAsFixed(1)} s';
  if (seconds < 60) return '${seconds.round()} s';
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Result keys read on their own; any other key shows the result as JSON.
const _knownResultKeys = {'exit_code', 'output', 'error', 'details'};

/// The result well text: the exit code first when it failed, then the
/// output; tools without `output` show their error (and details), anything
/// else as JSON.
String? stepResultText(ToolStepRow step) {
  final r = step.result;
  if (r == null) {
    final raw = step.resultRaw?.trim();
    return raw == null || raw.isEmpty ? null : raw;
  }
  final exit = r['exit_code'];
  final output = r['output'];
  final error = r['error'];
  final details = r['details'];
  String? body;
  if (output is String && output.trim().isNotEmpty) {
    body = output.trimRight();
  } else if (error is String && error.trim().isNotEmpty) {
    body = error.trim();
    if (details is List<Object?> && details.isNotEmpty) {
      body = '$body\n${details.join('\n')}';
    }
  } else if (r.keys.any((k) => !_knownResultKeys.contains(k))) {
    body = jsonEncode(r);
  }
  final failedExit = exit is int && exit != 0;
  if (failedExit && step.status == 'error') {
    return body == null ? 'exit $exit' : 'exit $exit · $body';
  }
  return body;
}

/// A command as shown: hyphens do not break lines (U+2060 after each '-'),
/// so lines break at spaces only. Copying uses the raw text.
String displayCommand(String command) => command.replaceAll('-', '-⁠');

/// Tool step card: header (status chip, tool, meta, chevron), the command,
/// a note or the result well.
class ToolStepCard extends StatefulWidget {
  const ToolStepCard({super.key, required this.step, this.approval});

  final ToolStepRow step;

  /// The step's approval, if it asked for one.
  final ApprovalRow? approval;

  @override
  State<ToolStepCard> createState() => _ToolStepCardState();
}

class _ToolStepCardState extends State<ToolStepCard> {
  bool _expanded = false;
  bool _all = false;

  void _copy(String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).chatCopied)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final step = widget.step;
    final look = stepLook(step, widget.approval);

    final Color border = switch (look) {
      StepLook.running => cs.primary,
      StepLook.waiting => d.warnBorder,
      StepLook.error || StepLook.blocked => d.alertBorder,
      StepLook.cancelled || StepLook.denied || StepLook.timeout => d.infoBorder,
      StepLook.ok => Colors.transparent,
    };
    final struck = look == StepLook.denied || look == StepLook.blocked;
    final note = switch (look) {
      StepLook.cancelled => l.stepCancelledNote,
      StepLook.denied => l.stepDeniedNote,
      StepLook.blocked => l.stepBlockedNote,
      StepLook.waiting => l.stepWaitingNote,
      _ => null,
    };
    final result = switch (look) {
      StepLook.denied || StepLook.blocked || StepLook.waiting => null,
      StepLook.timeout => _lastLine(stepResultText(step)),
      _ => stepResultText(step),
    };
    final duration = step.durationS;
    final command = step.preview?.trim();

    return Container(
      key: ValueKey('step.${step.id}'),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: border, width: DelveTokens.hairline),
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: result == null
                ? null
                : () => setState(() {
                    _expanded = !_expanded;
                    if (!_expanded) _all = false;
                  }),
            child: Padding(
              padding: const EdgeInsets.only(left: DelveTokens.space3),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    _StepChip(look: look),
                    const SizedBox(width: DelveTokens.space2),
                    Expanded(
                      child: Text(
                        step.tool,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DelveText.monoSmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (duration != null)
                      Text(
                        formatDuration(duration),
                        style: DelveText.monoSmall.copyWith(color: d.textMuted),
                      ),
                    SizedBox(
                      width: 48,
                      child: result == null
                          ? null
                          : SymbolIcon(
                              _expanded
                                  ? DelveIcons.expandLess
                                  : DelveIcons.expandMore,
                              size: DelveTokens.iconMd,
                              color: cs.onSurfaceVariant,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (command != null && command.isNotEmpty)
            GestureDetector(
              onLongPress: () => _copy(command),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DelveTokens.space3,
                  0,
                  DelveTokens.space3,
                  DelveTokens.space2 + 2,
                ),
                child: Text(
                  displayCommand(command),
                  style: DelveText.mono.copyWith(
                    color: struck ? d.textMuted : cs.onSurface,
                    decoration: struck ? TextDecoration.lineThrough : null,
                    decorationColor: d.textMuted,
                  ),
                ),
              ),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space3,
                0,
                DelveTokens.space3,
                DelveTokens.space3,
              ),
              child: Text(
                note,
                style: context.text.bodySmall!.copyWith(
                  color: look == StepLook.blocked
                      ? d.alertFg
                      : look == StepLook.waiting
                      ? d.warnFg
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          if (result != null)
            AnimatedSize(
              duration: DelveTokens.medium,
              curve: DelveTokens.standard,
              alignment: Alignment.topCenter,
              child: _ResultWell(
                text: result,
                expanded: _expanded,
                all: _all,
                onShowMore: () => setState(() => _all = true),
                onCopy: () => _copy(result),
              ),
            ),
          if (look == StepLook.running) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  static String? _lastLine(String? text) {
    if (text == null) return null;
    final lines = text.trimRight().split('\n');
    return lines.isEmpty ? null : '…${lines.last.trim()}';
  }
}

class _ResultWell extends StatelessWidget {
  const _ResultWell({
    required this.text,
    required this.expanded,
    required this.all,
    required this.onShowMore,
    required this.onCopy,
  });

  final String text;
  final bool expanded;
  final bool all;
  final VoidCallback onShowMore;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final lines = '\n'.allMatches(text).length + 1;
    final maxLines = !expanded
        ? 2
        : all
        ? null
        : 12;
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space3,
        DelveTokens.space2 + 2,
        DelveTokens.space3,
        DelveTokens.space2 + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            key: const Key('step.result'),
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            softWrap: expanded,
            style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
          ),
          if (expanded)
            Row(
              children: [
                if (!all && lines > 12)
                  TextButton(onPressed: onShowMore, child: Text(l.showMore)),
                const Spacer(),
                IconButton(
                  tooltip: l.copy,
                  onPressed: onCopy,
                  icon: SymbolIcon(
                    DelveIcons.copy,
                    size: DelveTokens.iconMd,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.look});

  final StepLook look;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (look == StepLook.running) {
      final cs = context.colors;
      return Container(
        constraints: const BoxConstraints(minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(DelveTokens.rxs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(DelveIcons.progress, size: 15, color: cs.primary),
            const SizedBox(width: DelveTokens.space1),
            Text(
              l.stepRunning,
              style: context.text.labelMedium!.copyWith(color: cs.primary),
            ),
          ],
        ),
      );
    }
    final (kind, icon, label) = switch (look) {
      StepLook.ok => (StatusKind.ok, DelveIcons.ok, l.stepOk),
      StepLook.error => (StatusKind.alert, DelveIcons.error, l.stepError),
      StepLook.cancelled => (
        StatusKind.info,
        DelveIcons.cancel,
        l.stepCancelled,
      ),
      StepLook.denied => (StatusKind.info, DelveIcons.block, l.stepDenied),
      StepLook.timeout => (StatusKind.info, DelveIcons.timerOff, l.stepTimeout),
      StepLook.blocked => (StatusKind.alert, DelveIcons.gppBad, l.stepBlocked),
      StepLook.waiting || StepLook.running => (
        StatusKind.warn,
        DelveIcons.approvals,
        l.stepWaiting,
      ),
    };
    return StatusChip(kind: kind, icon: icon, label: label);
  }
}
