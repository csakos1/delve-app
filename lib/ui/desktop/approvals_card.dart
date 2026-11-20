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
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import 'desktop_row.dart';
import 'panes.dart';

/// The approvals the reader can still answer: what the agent waits for and
/// what it stopped waiting for but is still approvable, newest first.
List<InboxApproval> answerableNow(ApprovalInbox? inbox, DateTime now) => [
  ...?inbox?.pending,
  for (final i in inbox?.expired ?? const <InboxApproval>[])
    if (now.isBefore(i.approval.expiresAt)) i,
]..sort((x, y) => y.approval.createdAt.compareTo(x.approval.createdAt));

/// The Dashboard's “Needs approval” card (design 27W-4a, desktop only): it
/// exists while an approval can be answered – no empty state. At most three
/// rows, newest first, each with the chat, the command in full, the state
/// and Allow once / Deny (⋯: Allow for session, Open chat, Copy command); a
/// focused row takes Ctrl+Enter / Ctrl+Backspace. An answer – here or
/// anywhere else – shows its outcome for 1.5 s, then the row collapses; a
/// failed one stays with Retry. More than three: “Show all N” → Approvals.
class NeedsApprovalCard extends ConsumerStatefulWidget {
  const NeedsApprovalCard({super.key});

  @override
  ConsumerState<NeedsApprovalCard> createState() => _NeedsApprovalCardState();
}

class _NeedsApprovalCardState extends ConsumerState<NeedsApprovalCard> {
  /// The answerable rows shown in the last build.
  Set<String> _shown = const {};

  /// The last row seen of each id shown (its chat title, its command).
  final Map<String, InboxApproval> _seen = {};

  /// Rows that stopped being answerable: their outcome, until the timer.
  final Map<String, InboxApproval> _leaving = {};
  final Map<String, Timer> _timers = {};

  /// A failed answer's reason, and the choice to retry.
  final Map<String, String> _failed = {};
  final Map<String, ApprovalChoice> _tried = {};
  final Set<String> _busy = {};

  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  /// A second's tick only while rows count down.
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

  static InboxApproval? _find(ApprovalInbox? inbox, String id) {
    if (inbox == null) return null;
    for (final list in [inbox.pending, inbox.expired, inbox.recent]) {
      for (final i in list) {
        if (i.approval.requestId == id) return i;
      }
    }
    return null;
  }

  void _leave(String id, InboxApproval item) {
    _leaving[id] = item;
    _failed.remove(id);
    _timers[id]?.cancel();
    _timers[id] = Timer(DelveDesktop.outcomeHold, () {
      if (!mounted) return;
      setState(() {
        _leaving.remove(id);
        _timers.remove(id);
        _seen.remove(id);
        _tried.remove(id);
      });
    });
  }

  Future<void> _answer(InboxApproval item, ApprovalChoice choice) async {
    final id = item.approval.requestId;
    final service = ref.read(approvalInboxServiceProvider);
    if (service == null || _busy.contains(id)) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy.add(id);
      _tried[id] = choice;
      _failed.remove(id);
    });
    try {
      await service.answer(id, choice);
    } on Object catch (e) {
      if (mounted) setState(() => _failed[id] = apiErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(approvalInboxProvider).value;
    final self = ref.watch(
      sessionProvider.select((s) => s.credentials?.deviceName),
    );
    final now = DateTime.now();
    final answerable = answerableNow(inbox, now);
    final ids = {for (final i in answerable) i.approval.requestId};

    // what was shown and cannot be answered any more leaves with its outcome
    for (final id in _shown) {
      if (ids.contains(id) || _leaving.containsKey(id)) continue;
      final item = _find(inbox, id) ?? _seen[id];
      if (item != null) _leave(id, item);
    }
    final top = answerable.take(DelveDesktop.approvalsMaxRows).toList();
    _shown = {for (final i in top) i.approval.requestId};
    for (final i in top) {
      _seen[i.approval.requestId] = i;
    }
    final rows = [
      ...top,
      for (final e in _leaving.entries)
        if (!_shown.contains(e.key)) e.value,
    ]..sort((x, y) => y.approval.createdAt.compareTo(x.approval.createdAt));
    _ticking(top.isNotEmpty);

    return AnimatedSize(
      duration: DelveDesktop.rowCollapse,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: rows.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: DelveDesktop.dashboardGap),
              child: _Card(
                rows: rows,
                answerable: answerable,
                leaving: _leaving.keys.toSet(),
                failed: _failed,
                busy: _busy,
                self: self,
                now: now,
                onAnswer: (i, c) => unawaited(_answer(i, c)),
                onRetry: (i) => unawaited(
                  _answer(
                    i,
                    _tried[i.approval.requestId] ?? ApprovalChoice.once,
                  ),
                ),
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.rows,
    required this.answerable,
    required this.leaving,
    required this.failed,
    required this.busy,
    required this.self,
    required this.now,
    required this.onAnswer,
    required this.onRetry,
  });

  final List<InboxApproval> rows;
  final List<InboxApproval> answerable;
  final Set<String> leaving;
  final Map<String, String> failed;
  final Set<String> busy;
  final String? self;
  final DateTime now;
  final void Function(InboxApproval, ApprovalChoice) onAnswer;
  final void Function(InboxApproval) onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    // only late ones left: the card turns info
    final onlyLate =
        answerable.isNotEmpty &&
        answerable.every((i) => i.approval.status != 'pending');
    final color = onlyLate ? d.infoFg : d.warnFg;
    final wideWindow =
        MediaQuery.sizeOf(context).width >= DelveDesktop.statusBarDropRunBelow;
    return Container(
      key: const Key('dashboard.approvals'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(
          color: onlyLate ? d.infoBorder : d.warnBorder,
          width: DelveTokens.hairline,
        ),
        borderRadius: BorderRadius.circular(DelveDesktop.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: DelveDesktop.approvalsHeader,
            child: Row(
              children: [
                SymbolIcon(
                  onlyLate ? DelveIcons.timerOff : DelveIcons.approvals,
                  size: 18,
                  filled: !onlyLate,
                  color: color,
                ),
                const SizedBox(width: DelveTokens.space2),
                Expanded(
                  child: Text(
                    l.desktopApprovalsTitle,
                    style: context.text.titleMedium!.copyWith(color: color),
                  ),
                ),
                if (answerable.isNotEmpty)
                  Text(
                    l.desktopApprovalsWaiting(answerable.length),
                    key: const Key('dashboard.approvals.count'),
                    style: context.text.bodySmall!.copyWith(color: d.textMuted),
                  ),
              ],
            ),
          ),
          for (final (n, i) in rows.indexed) ...[
            if (n > 0)
              Divider(
                height: DelveTokens.hairline,
                thickness: DelveTokens.hairline,
                color: cs.outlineVariant,
              ),
            _Row(
              key: ValueKey('dashboard.approval.${i.approval.requestId}'),
              item: i,
              leaving: leaving.contains(i.approval.requestId),
              failed: failed[i.approval.requestId],
              busy: busy.contains(i.approval.requestId),
              self: self,
              now: now,
              rightWidth: wideWindow
                  ? DelveDesktop.approvalsRight
                  : DelveDesktop.approvalsRightCompact,
              onAnswer: (c) => onAnswer(i, c),
              onRetry: () => onRetry(i),
            ),
          ],
          if (answerable.length > DelveDesktop.approvalsMaxRows) ...[
            Divider(
              height: DelveTokens.hairline,
              thickness: DelveTokens.hairline,
              color: cs.outlineVariant,
            ),
            InkWell(
              key: const Key('dashboard.approvals.all'),
              onTap: () => context.open(Routes.approvals),
              child: SizedBox(
                height: DelveDesktop.approvalsShowAll,
                child: Row(
                  children: [
                    Text(
                      l.desktopApprovalsShowAll(answerable.length),
                      style: context.text.labelLarge!.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    SymbolIcon(
                      DelveIcons.chevronRight,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One approval of the card: chat link and class, the command, the reason
/// (left); the state and the buttons (right, [rightWidth]); one column in a
/// narrow card. Focusable as a whole (Tab moves row by row): with focus,
/// Ctrl+Enter allows once and Ctrl+Backspace denies, and the buttons show
/// those keys.
class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.item,
    required this.leaving,
    required this.failed,
    required this.busy,
    required this.self,
    required this.now,
    required this.rightWidth,
    required this.onAnswer,
    required this.onRetry,
  });

  final InboxApproval item;
  final bool leaving;
  final String? failed;
  final bool busy;
  final String? self;
  final DateTime now;
  final double rightWidth;
  final void Function(ApprovalChoice) onAnswer;
  final VoidCallback onRetry;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  final FocusNode _focus = FocusNode(debugLabel: 'dashboard.approval');
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  bool get _canAnswer => !widget.leaving && !widget.busy;

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent || !_canAnswer) return KeyEventResult.ignored;
    if (!HardwareKeyboard.instance.isControlPressed) {
      return KeyEventResult.ignored;
    }
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (widget.failed != null) {
        widget.onRetry();
      } else {
        widget.onAnswer(ApprovalChoice.once);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      widget.onAnswer(ApprovalChoice.deny);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final a = widget.item.approval;
    final description = a.description?.trim();
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: DelveTokens.space2,
          runSpacing: DelveTokens.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ApprovalChatLink(
              key: ValueKey('dashboard.approval.chat.${a.requestId}'),
              title: widget.item.chatTitle ?? l.chatTitle,
              onTap: () => context.open(Routes.chat(a.conversationId)),
            ),
            _ClassChip(label: approvalClassLabel(l, a.actionClass)),
          ],
        ),
        const SizedBox(height: DelveTokens.space2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(
              DelveDesktop.approvalsWellRadius,
            ),
          ),
          child: Text(
            displayCommand(a.command),
            key: const Key('dashboard.approval.command'),
            style: DelveText.mono.copyWith(color: cs.onSurface),
          ),
        ),
        if (description != null &&
            description.isNotEmpty &&
            description != a.command) ...[
          const SizedBox(height: 6),
          Text(
            description,
            style: context.text.bodySmall!.copyWith(
              fontStyle: FontStyle.italic,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    final right = widget.leaving
        ? ApprovalOutcomeLine(approval: a, self: widget.self)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApprovalStateLine(approval: a, now: widget.now),
              if (widget.failed case final reason?) ...[
                const SizedBox(height: 6),
                Row(
                  key: const Key('dashboard.approval.failed'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SymbolIcon(
                      DelveIcons.error,
                      size: 15,
                      color: context.delve.alertFg,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.desktopApprovalsFailed(reason),
                        style: context.text.bodySmall!.copyWith(
                          color: context.delve.alertFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              ExcludeFocus(child: _buttons(context, l)),
            ],
          );

    return Focus(
      focusNode: _focus,
      canRequestFocus: !widget.leaving,
      skipTraversal: widget.leaving,
      onKeyEvent: _onKey,
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.leaving ? null : _focus.requestFocus,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: DelveDesktop.approvalsRowPadding,
          ),
          foregroundDecoration:
              _focused &&
                  FocusManager.instance.highlightMode ==
                      FocusHighlightMode.traditional
              ? BoxDecoration(
                  border: Border.all(color: cs.primary, width: 2),
                  borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
                )
              : null,
          child: LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth < DelveDesktop.approvalsTwoColumnsFrom) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [left, const SizedBox(height: 10), right],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: DelveDesktop.approvalsColumnGap),
                  SizedBox(width: widget.rightWidth, child: right),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context, AppLocalizations l) {
    final cs = context.colors;
    final a = widget.item.approval;
    final can = _canAnswer;
    final tonal = FilledButton.styleFrom(
      backgroundColor: cs.surfaceContainerHighest,
      foregroundColor: cs.onSurface,
    );
    Widget label(String text, String keys) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (_focused) ...[const SizedBox(width: 6), KeyCap(keys)],
      ],
    );
    final first = widget.failed != null
        ? OutlinedButton(
            key: const Key('dashboard.approval.retry'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, DelveDesktop.buttonSmall),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: context.delve.alertFg,
              side: BorderSide(color: context.delve.alertFg),
            ),
            onPressed: can ? widget.onRetry : null,
            child: label(l.retry, l.desktopKeyAllow),
          )
        : FilledButton(
            key: const Key('dashboard.approval.once'),
            onPressed: can ? () => widget.onAnswer(ApprovalChoice.once) : null,
            child: label(l.approvalAllowOnce, l.desktopKeyAllow),
          );
    return Wrap(
      spacing: DelveTokens.space2,
      runSpacing: DelveTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        first,
        FilledButton(
          key: const Key('dashboard.approval.deny'),
          style: tonal,
          onPressed: can ? () => widget.onAnswer(ApprovalChoice.deny) : null,
          child: label(l.approvalDeny, l.desktopKeyDeny),
        ),
        Builder(
          builder: (context) => IconButton(
            key: const Key('dashboard.approval.more'),
            tooltip: l.approvalsMore,
            onPressed: () {
              final box = context.findRenderObject()! as RenderBox;
              final at = box.localToGlobal(Offset(0, box.size.height));
              unawaited(
                showDesktopMenu(context, at, [
                  if (a.status == 'pending' &&
                      a.choices.contains(ApprovalChoice.session.wire))
                    DesktopMenuItem(
                      key: const Key('dashboard.approval.session'),
                      icon: DelveIcons.verified,
                      label: l.approvalAllowSession,
                      onSelected: () {
                        if (_canAnswer) {
                          widget.onAnswer(ApprovalChoice.session);
                        }
                      },
                    ),
                  DesktopMenuItem(
                    icon: DelveIcons.forum,
                    label: l.approvalsOpenChat,
                    onSelected: () =>
                        context.open(Routes.chat(a.conversationId)),
                  ),
                  DesktopMenuItem(
                    icon: DelveIcons.copy,
                    label: l.desktopMenuCopyCommand,
                    onSelected: () => unawaited(
                      Clipboard.setData(
                        ClipboardData(text: displayCommand(a.command)),
                      ),
                    ),
                  ),
                ]),
              );
            },
            icon: const SymbolIcon(
              DelveIcons.more,
              size: DelveDesktop.iconButtonIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// The chat's title as a link: `titleSmall` + `arrow_outward` 14.
class ApprovalChatLink extends StatelessWidget {
  const ApprovalChatLink({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall,
          ),
        ),
        const SizedBox(width: 2),
        SymbolIcon(
          DelveIcons.arrowOutward,
          size: 14,
          color: context.colors.onSurfaceVariant,
        ),
      ],
    ),
  );
}

/// The class chip at 22 (the chat card's is 28).
class _ClassChip extends StatelessWidget {
  const _ClassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: ShapeDecoration(
      color: context.colors.surfaceContainerHighest,
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      key: const Key('dashboard.approval.class'),
      style: context.text.labelSmall,
    ),
  );
}

/// Waiting: the ring and “Agent waits m:ss” (alert in the last minute), then
/// both deadlines muted. Late: “Agent stopped waiting at … · approvable
/// until …” in info.
class ApprovalStateLine extends StatelessWidget {
  const ApprovalStateLine({
    super.key,
    required this.approval,
    required this.now,
  });

  final ApprovalRow approval;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final a = approval;
    final until = clockTime(a.expiresAt, now);
    if (a.status != 'pending') {
      return Row(
        key: const Key('dashboard.approval.late'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SymbolIcon(DelveIcons.timerOff, size: 17, color: d.infoFg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l.desktopApprovalsLate(clockTime(a.hermesDeadline, now), until),
              style: context.text.labelMedium!.copyWith(color: d.infoFg),
            ),
          ),
        ],
      );
    }
    final left = a.hermesDeadline.difference(now);
    final total = a.hermesDeadline.difference(a.createdAt);
    final kind = left <= ApprovalCard.urgent
        ? StatusKind.alert
        : StatusKind.warn;
    final c = context.status(kind);
    final value = total.inMilliseconds <= 0 || left.isNegative
        ? 0.0
        : (left.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const Key('dashboard.approval.countdown'),
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 2.5,
                color: c.fg,
                backgroundColor: c.bg,
              ),
            ),
            const SizedBox(width: DelveTokens.space2),
            Flexible(
              child: Text(
                l.approvalWaits(
                  countdownText(left.isNegative ? Duration.zero : left),
                ),
                style: context.text.labelMedium!.copyWith(
                  color: c.fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l.desktopApprovalsDeadlines(clockTime(a.hermesDeadline, now), until),
          style: context.text.bodySmall!.copyWith(color: d.textMuted),
        ),
      ],
    );
  }
}

/// How the row ended: the status chip and who / when (“You · this device ·
/// HH:mm” for this device's answer); an approval whose window closed reads
/// Expired.
class ApprovalOutcomeLine extends StatelessWidget {
  const ApprovalOutcomeLine({
    super.key,
    required this.approval,
    required this.self,
  });

  final ApprovalRow approval;
  final String? self;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = approval;
    if (isAnswerable(a)) {
      return StatusChip(
        key: const Key('dashboard.approval.outcome'),
        kind: StatusKind.info,
        icon: DelveIcons.timerOff,
        label: l.approvalExpired,
      );
    }
    final (kind, icon, label) = approvalOutcomeLook(l, a.status);
    final by = a.decidedBy;
    final mine = by != null && by == self;
    final parts = [
      if (mine) l.desktopApprovalsYou else if (by != lateApprovalDecider) ?by,
      if (a.respondedAt case final at?) clockTime(at, DateTime.now()),
    ];
    return Column(
      key: const Key('dashboard.approval.outcome'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(kind: kind, icon: icon, label: label),
        if (parts.isNotEmpty) ...[
          const SizedBox(height: DelveTokens.space1),
          Text(
            parts.join(' · '),
            style: context.text.labelMedium!.copyWith(
              color: context.delve.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
