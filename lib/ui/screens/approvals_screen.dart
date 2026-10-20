import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/protocol.dart';
import '../../app/approvals.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/approval_card.dart';
import '../chat/tool_step_card.dart' show displayCommand;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 11 Approvals — pending, expired in agent (still approvable), recent.
/// Answers go over REST (decision 246).
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// [quiet]: the automatic reload on open says nothing when it fails (the
  /// stored approvals stay on screen).
  Future<void> _refresh({bool quiet = false}) async {
    final l = AppLocalizations.of(context);
    final service = ref.read(approvalInboxServiceProvider);
    if (service == null) return;
    try {
      await service.refresh();
    } on Exception catch (e) {
      if (mounted && !quiet) {
        _snack(l.approvalsRefreshFailed(apiErrorText(l, e)));
      }
    }
  }

  Future<void> _answer(ApprovalRow a, ApprovalChoice choice) async {
    final l = AppLocalizations.of(context);
    final service = ref.read(approvalInboxServiceProvider);
    if (service == null) return;
    try {
      final answered = await service.answer(a.requestId, choice);
      if (mounted && answered.status == 'late_approved') {
        _snack(l.approvalsLateStarted);
      }
    } on Exception catch (e) {
      if (mounted) _snack(l.approvalFailed(apiErrorText(l, e)));
    }
  }

  void _openChat(ApprovalRow a) =>
      unawaited(context.push(Routes.chat(a.conversationId)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inbox = ref.watch(approvalInboxProvider).value;
    final self = ref.watch(
      sessionProvider.select((s) => s.credentials?.deviceName),
    );

    final children = <Widget>[];
    if (inbox == null || inbox.isEmpty) {
      children.add(_Empty(loading: inbox == null));
    } else {
      if (inbox.pending.isEmpty && inbox.expired.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DelveTokens.space4),
            child: Text(
              l.approvalsNothingWaiting,
              key: const Key('approvals.nothingWaiting'),
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      if (inbox.pending.isNotEmpty) {
        children.add(
          _SectionHeader(
            label: l.approvalsPending,
            count: inbox.pending.length,
          ),
        );
        for (final i in inbox.pending) {
          children
            ..add(_card(i))
            ..add(const SizedBox(height: DelveTokens.space3));
        }
      }
      if (inbox.expired.isNotEmpty) {
        children.add(
          _SectionHeader(
            label: l.approvalsExpired,
            count: inbox.expired.length,
          ),
        );
        for (final i in inbox.expired) {
          children
            ..add(_card(i))
            ..add(const SizedBox(height: DelveTokens.space3));
        }
      }
      if (inbox.recent.isNotEmpty) {
        children.add(_SectionHeader(label: l.approvalsRecent));
        for (final (n, i) in inbox.recent.indexed) {
          if (n > 0) children.add(const Divider(height: 1));
          children.add(
            _RecentRow(
              item: i,
              selfDevice: self,
              onTap: () => _openChat(i.approval),
            ),
          );
        }
      }
    }

    return TopLevelPage(
      title: l.navApprovals,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: const Key('approvals.list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            0,
            DelveTokens.space4,
            DelveTokens.space6,
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _card(InboxApproval i) => InboxApprovalCard(
    key: ValueKey('inbox.${i.approval.requestId}'),
    approval: i.approval,
    chatTitle: i.chatTitle,
    onAnswer: (c) => _answer(i.approval, c),
    onOpenChat: () => _openChat(i.approval),
  );
}

/// "PENDING   2": muted, letter-spaced, the count on the right.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final style = context.text.labelMedium!.copyWith(
      color: context.colors.onSurfaceVariant,
      letterSpacing: 1.2,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        DelveTokens.space4,
        0,
        DelveTokens.space2,
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: style)),
            if (count case final n?) Text('$n', style: style),
          ],
        ),
      ),
    );
  }
}

/// An approval in the inbox: countdown (or the late deadline) and class,
/// the command verbatim, its chat, Allow once / Deny and ⋯ (Allow for
/// session while the agent waits, Open chat).
class InboxApprovalCard extends StatefulWidget {
  const InboxApprovalCard({
    super.key,
    required this.approval,
    required this.onAnswer,
    required this.onOpenChat,
    this.chatTitle,
  });

  final ApprovalRow approval;
  final String? chatTitle;
  final Future<void> Function(ApprovalChoice choice) onAnswer;
  final VoidCallback onOpenChat;

  @override
  State<InboxApprovalCard> createState() => _InboxApprovalCardState();
}

enum _More { session, chat }

class _InboxApprovalCardState extends State<InboxApprovalCard> {
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
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onAnswer(choice);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _more(_More item) {
    switch (item) {
      case _More.session:
        unawaited(_answer(ApprovalChoice.session));
      case _More.chat:
        widget.onOpenChat();
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
    final canAnswer = !_busy && !closed;
    final session = waiting && a.choices.contains(ApprovalChoice.session.wire);

    void Function()? press(ApprovalChoice c) =>
        canAnswer ? () => unawaited(_answer(c)) : null;

    final Widget lead;
    if (waiting) {
      lead = ApprovalCountdown(
        remaining: a.hermesDeadline.difference(now),
        total: a.hermesDeadline.difference(a.createdAt),
      );
    } else {
      final time = clockTime(a.expiresAt, now);
      final text = closed
          ? l.approvalsClosedAt(time)
          : l.approvalsExpiredUntil(time);
      final at = text.indexOf(time);
      lead = Row(
        children: [
          SymbolIcon(
            DelveIcons.timerOff,
            size: DelveTokens.iconMd,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: DelveTokens.space2),
          Expanded(
            child: Text.rich(
              key: const Key('inbox.expiredLine'),
              TextSpan(
                style: context.text.labelLarge,
                children: at < 0
                    ? [TextSpan(text: text)]
                    : [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(
                          text: time,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: text.substring(at + time.length)),
                      ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(DelveTokens.space4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(
          color: waiting ? d.warnBorder : d.infoBorder,
          width: DelveTokens.hairline,
        ),
        borderRadius: BorderRadius.circular(DelveTokens.rlg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: lead),
              const SizedBox(width: DelveTokens.space2),
              ApprovalClassChip(label: approvalClassLabel(l, a.actionClass)),
            ],
          ),
          const SizedBox(height: DelveTokens.space3),
          Text(
            displayCommand(a.command),
            key: const Key('inbox.command'),
            style: DelveText.mono.copyWith(color: cs.onSurface),
          ),
          InkWell(
            key: ValueKey('inbox.chat.${a.requestId}'),
            onTap: widget.onOpenChat,
            borderRadius: BorderRadius.circular(DelveTokens.rxs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: DelveTokens.touchTarget,
              ),
              child: Row(
                children: [
                  SymbolIcon(DelveIcons.forum, size: 16, color: d.textMuted),
                  const SizedBox(width: DelveTokens.space2),
                  Expanded(
                    child: Text(
                      widget.chatTitle ?? l.chatTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium!.copyWith(
                        color: d.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DelveTokens.space1),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('inbox.once'),
                  onPressed: press(ApprovalChoice.once),
                  child: Text(l.approvalAllowOnce),
                ),
              ),
              const SizedBox(width: DelveTokens.space2),
              Expanded(
                child: FilledButton(
                  key: const Key('inbox.deny'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.surfaceContainerHighest,
                    foregroundColor: cs.onSurface,
                  ),
                  onPressed: press(ApprovalChoice.deny),
                  child: Text(l.approvalDeny),
                ),
              ),
              const SizedBox(width: DelveTokens.space2),
              Container(
                width: DelveTokens.touchTarget,
                height: DelveTokens.touchTarget,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DelveTokens.rmd),
                ),
                child: PopupMenuButton<_More>(
                  key: const Key('inbox.more'),
                  tooltip: l.approvalsMore,
                  icon: SymbolIcon(DelveIcons.more, color: cs.onSurface),
                  onSelected: _more,
                  itemBuilder: (context) => [
                    if (session)
                      PopupMenuItem(
                        value: _More.session,
                        enabled: canAnswer,
                        child: Text(l.approvalAllowSession),
                      ),
                    PopupMenuItem(
                      value: _More.chat,
                      child: Text(l.approvalsOpenChat),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A recent approval: status chip, who answered, when; the command under
/// it. Tapping opens its chat.
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.item,
    required this.selfDevice,
    required this.onTap,
  });

  final InboxApproval item;
  final String? selfDevice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final a = item.approval;
    final (kind, icon, label) = approvalOutcomeLook(l, a.status);
    final who = switch (a.decidedBy) {
      null => null,
      lateApprovalDecider => l.approvalsWhoAuto,
      final name when name == selfDevice => l.approvalsWhoYou,
      final name => name,
    };
    final at = a.respondedAt ?? a.createdAt;
    return InkWell(
      key: ValueKey('inbox.recent.${a.requestId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DelveTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                StatusChip(kind: kind, icon: icon, label: label),
                const SizedBox(width: DelveTokens.space2),
                Expanded(
                  child: Text(
                    who ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  clockTime(at, DateTime.now()),
                  style: context.text.labelMedium!.copyWith(color: d.textMuted),
                ),
              ],
            ),
            const SizedBox(height: DelveTokens.space2),
            Text(
              displayCommand(a.command),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DelveText.mono.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nothing stored yet (or still loading).
class _Empty extends StatelessWidget {
  const _Empty({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const SizedBox.shrink();
    return Padding(
      key: const Key('approvals.empty'),
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          SymbolIcon(
            DelveIcons.approvals,
            size: 40,
            color: context.delve.textMuted,
          ),
          const SizedBox(height: DelveTokens.space3),
          Text(l.approvalsEmptyTitle, style: context.text.titleMedium),
          const SizedBox(height: DelveTokens.space2),
          Text(
            l.approvalsEmptyBody,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
