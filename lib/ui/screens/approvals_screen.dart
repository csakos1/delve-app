import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/protocol.dart';
import '../../app/approvals.dart';
import '../../app/layout.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/approval_card.dart';
import '../chat/tool_step_card.dart' show displayCommand;
import '../desktop/approvals_card.dart'
    show ApprovalChatLink, ApprovalOutcomeLine, ApprovalStateLine;
import '../desktop/desktop_page.dart';
import '../desktop/desktop_row.dart';
import '../desktop/intake.dart'
    show ListCommandSlot, ListCommands, listCommandSlotProvider;
import '../desktop/panes.dart' show KeyCap;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 11 Approvals — pending, expired in agent (still approvable), recent.
/// Answers go over REST (decision 246). On the desktop (27W-3) the list
/// column of the Approvals area: the whole history as rows.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key, this.selected});

  /// The desktop: the approval open in the content (its row is selected).
  final String? selected;

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  /// The desktop: the rows in the order shown (J / K).
  List<String> _order = const [];
  late final ListCommandSlot _keys;
  late final PageCommandSlot _pageKeys;

  /// The desktop: a second's tick while an agent waits (the countdowns).
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _keys = ref.read(listCommandSlotProvider);
    _pageKeys = ref.read(pageCommandSlotProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _keys.unregister(this);
    _pageKeys.unregister(this);
    super.dispose();
  }

  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  /// J / K: the next / previous approval (the first without one open).
  void _step(int by) {
    final order = _order;
    if (order.isEmpty) return;
    final at = widget.selected == null ? -1 : order.indexOf(widget.selected!);
    final next = at < 0 ? 0 : (at + by).clamp(0, order.length - 1);
    if (next == at) return;
    context.open(Routes.approval(order[next]));
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

  void _openChat(ApprovalRow a) => context.open(Routes.chat(a.conversationId));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inbox = ref.watch(approvalInboxProvider).value;
    final self = ref.watch(
      sessionProvider.select((s) => s.credentials?.deviceName),
    );
    if (DesktopLayout.of(context)) return _desktop(context, l, inbox, self);

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

    return SubPage(
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

  /// The desktop's list column (27W-3): Pending · Expired in agent ·
  /// Recent as rows, the open one selected; J / K, Ctrl+R.
  Widget _desktop(
    BuildContext context,
    AppLocalizations l,
    ApprovalInbox? inbox,
    String? self,
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
      PageCommands(refresh: () => unawaited(_refresh())),
    );
    final now = DateTime.now();
    final pending = inbox?.pending ?? const <InboxApproval>[];
    final expired = inbox?.expired ?? const <InboxApproval>[];
    final recent = inbox?.recent ?? const <InboxApproval>[];
    _order = [
      for (final i in [...pending, ...expired, ...recent]) i.approval.requestId,
    ];
    _ticking(pending.isNotEmpty);
    Widget rows(List<InboxApproval> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in items)
          DesktopApprovalRow(
            item: i,
            self: self,
            now: now,
            selected: i.approval.requestId == widget.selected,
            onTap: () => context.open(Routes.approval(i.approval.requestId)),
          ),
      ],
    );
    return TopLevelPage(
      title: l.navApprovals,
      background: context.colors.surfaceContainerLow,
      actions: [
        IconButton(
          key: const Key('approvals.refresh'),
          tooltip: l.desktopRefresh,
          onPressed: () => unawaited(_refresh()),
          icon: const SymbolIcon(
            DelveIcons.refresh,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
      ],
      child: inbox == null
          ? const SizedBox.shrink()
          : inbox.isEmpty
          ? Padding(
              key: const Key('approvals.empty'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l.approvalsEmptyTitle,
                style: context.text.titleSmall,
              ),
            )
          : ListView(
              key: const Key('approvals.list'),
              padding: const EdgeInsets.only(bottom: DelveTokens.space4),
              children: [
                if (pending.isEmpty && expired.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      l.approvalsNothingWaiting,
                      key: const Key('approvals.nothingWaiting'),
                      style: DelveDesktopText.rowSecondary.copyWith(
                        color: context.delve.textMuted,
                      ),
                    ),
                  ),
                if (pending.isNotEmpty) ...[
                  _ListEyebrow(l.approvalsPending, count: pending.length),
                  rows(pending),
                ],
                if (expired.isNotEmpty) ...[
                  _ListEyebrow(l.approvalsExpired, count: expired.length),
                  rows(expired),
                ],
                if (recent.isNotEmpty) ...[
                  _ListEyebrow(l.approvalsRecent),
                  rows(recent),
                ],
              ],
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

/// A group's eyebrow in the desktop's list column, with its count.
class _ListEyebrow extends StatelessWidget {
  const _ListEyebrow(this.label, {this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      [label.toUpperCase(), if (count != null) '$count'].join('  '),
      style: context.text.labelSmall!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
        color: context.delve.textMuted,
      ),
    ),
  );
}

/// An approval in the desktop's list column (27W-3): the state's icon and
/// word, the time; the command in full (mono, wrapping at spaces); the
/// countdown or the outcome and who, and the chat.
class DesktopApprovalRow extends StatelessWidget {
  const DesktopApprovalRow({
    super.key,
    required this.item,
    required this.self,
    required this.now,
    required this.selected,
    required this.onTap,
  });

  final InboxApproval item;
  final String? self;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final a = item.approval;
    final chat = item.chatTitle ?? l.chatTitle;
    final (
      Color fg,
      IconData icon,
      String word,
      String detail,
    ) = switch (a.status) {
      'pending' => (
        d.warnFg,
        DelveIcons.approvals,
        l.desktopApprovalWaitingWord,
        l.approvalWaits(
          countdownText(
            a.hermesDeadline.difference(now).isNegative
                ? Duration.zero
                : a.hermesDeadline.difference(now),
          ),
        ),
      ),
      'expired_in_hermes' => (
        d.infoFg,
        DelveIcons.timerOff,
        l.desktopApprovalLateWord,
        l.desktopApprovalUntil(clockTime(a.expiresAt, now)),
      ),
      _ => switch (approvalOutcomeLook(l, a.status)) {
        (final kind, final icon, final label) => (
          context.status(kind).fg,
          icon,
          label,
          switch (a.decidedBy) {
            null => '',
            lateApprovalDecider => l.approvalsWhoAuto,
            final name when name == self => l.approvalsWhoYou,
            final name => name,
          },
        ),
      },
    };
    final waiting = a.status == 'pending';
    return DesktopRowFrame(
      key: ValueKey('approval.row.${a.requestId}'),
      selected: selected,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SymbolIcon(icon, size: 16, filled: waiting, color: fg),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word,
                        style: context.text.labelMedium!.copyWith(color: fg),
                      ),
                    ),
                    Text(
                      clockTime(a.respondedAt ?? a.createdAt, now),
                      style: DelveDesktopText.meta.copyWith(color: d.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  displayCommand(a.command),
                  key: ValueKey('approval.row.command.${a.requestId}'),
                  style: DelveText.mono.copyWith(
                    fontSize: 12.5,
                    height: 18 / 12.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [if (detail.isNotEmpty) detail, chat].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DelveDesktopText.rowSecondary.copyWith(
                    color: waiting ? d.warnFg : cs.onSurfaceVariant,
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

/// The desktop's approval page (27W-3): its class as the heading, the chat
/// it came from, the command in a well with Copy, the state (the countdown,
/// the late deadline, or the outcome and who), Allow once · Deny · Allow
/// for session while it can be answered (Ctrl+Enter / Ctrl+Backspace), and
/// why the agent asks.
class ApprovalDetail extends ConsumerStatefulWidget {
  const ApprovalDetail({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ApprovalDetail> createState() => _ApprovalDetailState();
}

class _ApprovalDetailState extends ConsumerState<ApprovalDetail> {
  final _keys = FocusNode(debugLabel: 'approval.detail');
  Timer? _tick;
  bool _busy = false;
  String? _failed;
  ApprovalChoice? _tried;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // the shell keeps the focus otherwise (autofocus does not reach here)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keys.requestFocus();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _keys.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _answer(ApprovalChoice choice) async {
    final l = AppLocalizations.of(context);
    final service = ref.read(approvalInboxServiceProvider);
    if (service == null || _busy) return;
    setState(() {
      _busy = true;
      _tried = choice;
      _failed = null;
    });
    try {
      final answered = await service.answer(widget.requestId, choice);
      if (answered.status == 'late_approved') _snack(l.approvalsLateStarted);
    } on Object catch (e) {
      if (mounted) setState(() => _failed = apiErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static InboxApproval? _find(ApprovalInbox? inbox, String id) {
    if (inbox == null) return null;
    for (final list in [inbox.pending, inbox.expired, inbox.recent]) {
      for (final i in list) {
        if (i.approval.requestId == id) return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inbox = ref.watch(approvalInboxProvider).value;
    final self = ref.watch(
      sessionProvider.select((s) => s.credentials?.deviceName),
    );
    final item = _find(inbox, widget.requestId);
    if (item == null) {
      return DesktopPage(
        title: l.navApprovals,
        child: inbox == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(DelveDesktop.contentGutter),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: StatusBanner(
                    key: const Key('approval.gone'),
                    kind: StatusKind.info,
                    icon: DelveIcons.info,
                    text: l.desktopApprovalGone,
                  ),
                ),
              ),
      );
    }
    final a = item.approval;
    final now = DateTime.now();
    final cs = context.colors;
    final d = context.delve;
    final can = isAnswerable(a) && !_busy;
    final description = a.description?.trim();
    final tonal = FilledButton.styleFrom(
      backgroundColor: cs.surfaceContainerHighest,
      foregroundColor: cs.onSurface,
    );
    Widget withKey(String text, String keys) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [Text(text), const SizedBox(width: 6), KeyCap(keys)],
    );
    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: d.textMuted,
        ),
      ),
    );
    return DesktopPage(
      title: item.chatTitle ?? l.chatTitle,
      inspectorToggle: true,
      child: CallbackShortcuts(
        bindings: {
          if (isAnswerable(a)) ...{
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
              if (!_busy) {
                unawaited(
                  _answer(_failed != null ? _tried! : ApprovalChoice.once),
                );
              }
            },
            const SingleActivator(
              LogicalKeyboardKey.backspace,
              control: true,
            ): () {
              if (!_busy) unawaited(_answer(ApprovalChoice.deny));
            },
          },
        },
        child: Focus(
          focusNode: _keys,
          child: DesktopPageBody(
            key: const Key('approval.detail'),
            maxWidth: DelveDesktop.detailColumn,
            top: DelveTokens.space4,
            children: [
              Text(
                approvalClassLabel(l, a.actionClass),
                style: DelveDesktopText.pageTitle.copyWith(
                  fontSize: 22,
                  height: 28 / 22,
                ),
              ),
              const SizedBox(height: DelveTokens.space2),
              Align(
                alignment: Alignment.centerLeft,
                child: ApprovalChatLink(
                  key: const Key('approval.detail.chat'),
                  title: item.chatTitle ?? l.chatTitle,
                  onTap: () => context.open(Routes.chat(a.conversationId)),
                ),
              ),
              const SizedBox(height: DelveTokens.space4),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        displayCommand(a.command),
                        key: const Key('approval.detail.command'),
                        style: DelveText.mono.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('approval.detail.copy'),
                      tooltip: l.desktopMenuCopyCommand,
                      onPressed: () => unawaited(
                        Clipboard.setData(
                          ClipboardData(text: displayCommand(a.command)),
                        ),
                      ),
                      icon: const SymbolIcon(
                        DelveIcons.copy,
                        size: DelveDesktop.iconButtonIcon,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DelveTokens.space4),
              if (isAnswerable(a)) ...[
                ApprovalStateLine(approval: a, now: now),
                if (_failed case final reason?) ...[
                  const SizedBox(height: 6),
                  Text(
                    l.desktopApprovalsFailed(reason),
                    key: const Key('approval.detail.failed'),
                    style: context.text.bodySmall!.copyWith(color: d.alertFg),
                  ),
                ],
                const SizedBox(height: DelveTokens.space3),
                Wrap(
                  spacing: DelveTokens.space2,
                  runSpacing: DelveTokens.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_failed != null)
                      OutlinedButton(
                        key: const Key('approval.detail.retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: d.alertFg,
                          side: BorderSide(color: d.alertFg),
                        ),
                        onPressed: can
                            ? () => unawaited(_answer(_tried!))
                            : null,
                        child: withKey(l.retry, l.desktopKeyAllow),
                      )
                    else
                      FilledButton(
                        key: const Key('approval.detail.once'),
                        onPressed: can
                            ? () => unawaited(_answer(ApprovalChoice.once))
                            : null,
                        child: withKey(l.approvalAllowOnce, l.desktopKeyAllow),
                      ),
                    FilledButton(
                      key: const Key('approval.detail.deny'),
                      style: tonal,
                      onPressed: can
                          ? () => unawaited(_answer(ApprovalChoice.deny))
                          : null,
                      child: withKey(l.approvalDeny, l.desktopKeyDeny),
                    ),
                    if (a.status == 'pending' &&
                        a.choices.contains(ApprovalChoice.session.wire))
                      TextButton(
                        key: const Key('approval.detail.session'),
                        onPressed: can
                            ? () => unawaited(_answer(ApprovalChoice.session))
                            : null,
                        child: Text(l.approvalAllowSession),
                      ),
                  ],
                ),
              ] else
                ApprovalOutcomeLine(approval: a, self: self),
              if (description != null &&
                  description.isNotEmpty &&
                  description != a.command) ...[
                eyebrow(l.desktopApprovalWhy),
                Text(
                  description,
                  key: const Key('approval.detail.why'),
                  style: context.text.bodyMedium!.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
