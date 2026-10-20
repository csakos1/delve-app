import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import 'tool_step_card.dart' show displayCommand;

/// Whether [a] is still answerable: shown as an [ApprovalCard] in place of
/// its tool step.
bool isAnswerable(ApprovalRow a) =>
    answerableApprovalStatuses.contains(a.status);

/// The `action_class` as the class chip names it.
String approvalClassLabel(AppLocalizations l, String actionClass) =>
    switch (actionClass) {
      'pkg_upgrade' => l.approvalClassPkgUpgrade,
      'service_restart' => l.approvalClassServiceRestart,
      'delete_kill' => l.approvalClassDeleteKill,
      _ => l.approvalClassOther,
    };

/// The approval card (04 waiting, 08a expired in the agent): the class, the
/// command verbatim, the countdown and Allow once / Deny (/ Allow for
/// session while the agent still waits). `always` is never offered.
class ApprovalCard extends StatefulWidget {
  const ApprovalCard({super.key, required this.approval, this.onAnswer});

  final ApprovalRow approval;

  /// Sends the answer. Null when not connected: the buttons are disabled
  /// (an answer is never queued, decision 170).
  final Future<void> Function(ApprovalChoice choice)? onAnswer;

  /// "Agent waits" turns alert-coloured at or below this.
  static const Duration urgent = Duration(seconds: 60);

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _answer(ApprovalChoice choice) async {
    final send = widget.onAnswer;
    if (send == null || _busy) return;
    setState(() => _busy = true);
    try {
      await send(choice);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final a = widget.approval;
    final now = DateTime.now();
    final waiting = a.status == 'pending';
    final closed = !waiting && now.isAfter(a.expiresAt);
    final canAnswer = widget.onAnswer != null && !_busy && !closed;

    void Function()? press(ApprovalChoice c) =>
        canAnswer ? () => unawaited(_answer(c)) : null;

    final header = Row(
      children: [
        SymbolIcon(
          waiting ? DelveIcons.approvals : DelveIcons.timerOff,
          size: DelveTokens.iconMd,
          filled: waiting,
          color: waiting ? d.warnFg : cs.onSurfaceVariant,
        ),
        const SizedBox(width: DelveTokens.space2),
        Expanded(
          child: Text(
            waiting ? l.approvalNeeded : l.approvalStoppedWaiting,
            style: context.text.titleSmall!.copyWith(
              color: waiting ? d.warnFg : cs.onSurface,
            ),
          ),
        ),
        const SizedBox(width: DelveTokens.space2),
        _ClassChip(label: approvalClassLabel(l, a.actionClass)),
      ],
    );

    final description = a.description?.trim();
    final children = <Widget>[
      header,
      const SizedBox(height: DelveTokens.space3),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DelveTokens.rsm),
        ),
        child: SelectableText(
          displayCommand(a.command),
          key: const Key('approval.command'),
          style: DelveText.mono.copyWith(color: cs.onSurface),
        ),
      ),
      if (description != null &&
          description.isNotEmpty &&
          description != a.command)
        Padding(
          padding: const EdgeInsets.only(top: DelveTokens.space2),
          child: Text(
            description,
            style: context.text.bodySmall!.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      const SizedBox(height: DelveTokens.space3),
      if (waiting)
        _Countdown(
          remaining: a.hermesDeadline.difference(now),
          total: a.hermesDeadline.difference(a.createdAt),
        )
      else
        _LateBody(
          text: closed
              ? l.approvalClosed(clockTime(a.expiresAt, now))
              : l.approvalLateBody(clockTime(a.expiresAt, now)),
          time: clockTime(a.expiresAt, now),
        ),
      if (widget.onAnswer == null && !closed)
        Padding(
          padding: const EdgeInsets.only(top: DelveTokens.space2),
          child: Row(
            key: const Key('approval.offline'),
            children: [
              SymbolIcon(DelveIcons.cloudOff, size: 16, color: d.textMuted),
              const SizedBox(width: DelveTokens.space1),
              Expanded(
                child: Text(
                  l.approvalOffline,
                  style: context.text.labelSmall!.copyWith(color: d.textMuted),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: DelveTokens.space3),
      Row(
        children: [
          Expanded(
            child: FilledButton(
              key: const Key('approval.once'),
              onPressed: press(ApprovalChoice.once),
              child: Text(l.approvalAllowOnce),
            ),
          ),
          const SizedBox(width: DelveTokens.space2),
          Expanded(
            child: FilledButton(
              key: const Key('approval.deny'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurface,
              ),
              onPressed: press(ApprovalChoice.deny),
              child: Text(l.approvalDeny),
            ),
          ),
        ],
      ),
      if (waiting && a.choices.contains(ApprovalChoice.session.wire))
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const Key('approval.session'),
            onPressed: press(ApprovalChoice.session),
            child: Text(l.approvalAllowSession),
          ),
        )
      else
        const SizedBox(height: DelveTokens.space3),
    ];

    return Semantics(
      container: true,
      child: Container(
        key: ValueKey('approval.${a.requestId}'),
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space3,
          DelveTokens.space3,
          DelveTokens.space3,
          0,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          border: Border.all(
            color: waiting ? d.warnBorder : d.infoBorder,
            width: DelveTokens.hairline,
          ),
          borderRadius: BorderRadius.circular(DelveTokens.rlg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Class chip: h 28 · radius-full · surface-4 · labelMedium.
class _ClassChip extends StatelessWidget {
  const _ClassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 28),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space3),
    decoration: ShapeDecoration(
      color: context.colors.surfaceContainerHighest,
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      key: const Key('approval.class'),
      style: context.text.labelMedium,
    ),
  );
}

/// "Agent waits m:ss" with a 20 dp ring: warn above a minute, alert below.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining, required this.total});

  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final left = remaining.isNegative ? Duration.zero : remaining;
    final kind = left <= ApprovalCard.urgent
        ? StatusKind.alert
        : StatusKind.warn;
    final c = context.status(kind);
    final value = total.inMilliseconds <= 0
        ? 0.0
        : (left.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return Row(
      key: const Key('approval.countdown'),
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 3,
            color: c.fg,
            backgroundColor: c.bg,
          ),
        ),
        const SizedBox(width: DelveTokens.space2),
        Text(
          l.approvalWaits(countdownText(left)),
          style: context.text.labelMedium!.copyWith(
            color: c.fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// 08a: the agent stopped waiting; the deadline of the late approval in
/// bold.
class _LateBody extends StatelessWidget {
  const _LateBody({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final at = text.indexOf(time);
    if (at < 0) {
      return Text(text, key: const Key('approval.late'), style: style);
    }
    return Text.rich(
      key: const Key('approval.late'),
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: time,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          TextSpan(text: text.substring(at + time.length)),
        ],
      ),
    );
  }
}

/// How an approval ended, for the line under its tool step (resolved
/// state): status chip, who and when.
class ApprovalOutcome extends StatelessWidget {
  const ApprovalOutcome({super.key, required this.approval, this.selfDevice});

  final ApprovalRow approval;

  /// This phone's device name: its answers read "by you".
  final String? selfDevice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = approval;
    final (kind, icon, label) = switch (a.status) {
      'approved_once' ||
      'approved_session' => (StatusKind.ok, DelveIcons.ok, l.approvalApproved),
      'late_approved' || 'followup_started' => (
        StatusKind.ok,
        DelveIcons.ok,
        l.approvalApprovedLate,
      ),
      'executed' => (StatusKind.ok, DelveIcons.ok, l.approvalRanLater),
      'superseded' => (StatusKind.info, DelveIcons.info, l.approvalSuperseded),
      'denied' => (StatusKind.info, DelveIcons.block, l.approvalDenied),
      'expired' => (StatusKind.info, DelveIcons.timerOff, l.approvalExpired),
      _ => (StatusKind.info, DelveIcons.cancel, l.approvalCancelled),
    };
    final by = a.decidedBy;
    final parts = <String>[
      if (by != null && by != 'late_approval')
        by == selfDevice ? l.approvalByYou : l.approvalBy(by),
      if (a.choice == ApprovalChoice.once.wire && a.status != 'denied')
        l.approvalAllowOnce,
      if (a.choice == ApprovalChoice.session.wire) l.approvalAllowSession,
      if (a.respondedAt case final at?) clockTime(at, DateTime.now()),
    ];
    return Wrap(
      key: ValueKey('approval.outcome.${a.requestId}'),
      spacing: DelveTokens.space2,
      runSpacing: DelveTokens.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusChip(kind: kind, icon: icon, label: label),
        if (parts.isNotEmpty)
          Text(
            parts.join(' · '),
            style: context.text.labelMedium!.copyWith(
              color: context.delve.textMuted,
            ),
          ),
      ],
    );
  }
}
