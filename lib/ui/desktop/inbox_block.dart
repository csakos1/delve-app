import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../app/approvals.dart';
import '../../app/inbox.dart';
import '../../app/news.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/tool_step_card.dart' show displayCommand;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import 'approvals_card.dart' show answerableNow;
import 'inbox_detail.dart' show inboxGist, inboxLook;

/// The open items the Dashboard's Inbox block lists and counts: all but
/// the approvals the “Needs approval” card above it shows ([inCard], their
/// request ids). Newest first, as the Inbox has them.
@visibleForTesting
List<InboxItem> inboxBlockItems(List<InboxItem> items, Set<String> inCard) => [
  for (final i in items)
    if (!(i.isApproval && inCard.contains(i.subject))) i,
];

/// The Dashboard's Inbox block (Components “Inbox”, 27W-4a … 4c; the
/// desktop, with a server that has the Inbox): a card under the Morning
/// brief with the three newest open items that the “Needs approval” card
/// does not show – the kind, the gist in one line, the time – and how many
/// more there are. The header opens the Inbox, a row its item; the count
/// is the rail badge's. With nothing open: one line, “Nothing needs you”.
class InboxBlock extends ConsumerWidget {
  const InboxBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(inboxSupportedProvider)) return const SizedBox.shrink();
    final view = ref.watch(inboxProvider);
    // nothing before the server's first answer: “Nothing needs you” would
    // be a guess
    if (view.inbox == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final muted = context.delve.textMuted;
    final inCard = {
      for (final i in answerableNow(
        ref.watch(approvalInboxProvider).value,
        now,
      ).take(DelveDesktop.approvalsMaxRows))
        i.approval.requestId,
    };
    final rest = inboxBlockItems(view.items, inCard);
    final rows = rest.take(DelveDesktop.inboxBlockRows).toList();
    final more = rest.length - rows.length;
    final above = view.items.length - rest.length;
    final foot = switch ((more, above)) {
      (0, 0) => null,
      (0, _) => l.inboxBlockAbove(above),
      (_, 0) => l.inboxBlockMore(more),
      _ => l.inboxBlockMoreAbove(more, above),
    };
    final lastCleared = view.done.firstOrNull?.doneAt;
    return Padding(
      padding: EdgeInsets.only(
        top: DashSpacing.maybeOf(context) ?? DelveTokens.space3,
      ),
      child: Container(
        key: const Key('dashboard.inbox'),
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          DelveTokens.space3,
          DelveTokens.space4,
          DelveTokens.space3,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(cardRadiusOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const Key('dashboard.inbox.open'),
              onTap: () => context.go(Routes.inbox),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: DelveTokens.touchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l.navInbox, style: context.text.titleMedium),
                    ),
                    // absent, not zero
                    if (view.open > 0)
                      Text(
                        l.inboxOpen(view.open),
                        key: const Key('dashboard.inbox.count'),
                        style: context.text.labelMedium!.copyWith(color: muted),
                      ),
                    const SizedBox(width: DelveTokens.space1),
                    SymbolIcon(DelveIcons.chevronRight, size: 22, color: muted),
                  ],
                ),
              ),
            ),
            if (view.items.isEmpty)
              SizedBox(
                key: const Key('dashboard.inbox.empty'),
                height: DelveDesktop.inboxBlockEmpty,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lastCleared == null
                        ? l.inboxEmptyTitle
                        : l.inboxBlockEmptyCleared(clockTime(lastCleared, now)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium!.copyWith(color: muted),
                  ),
                ),
              )
            else ...[
              for (final i in rows) _BlockRow(item: i, now: now),
              if (foot != null)
                Padding(
                  padding: const EdgeInsets.only(top: DelveTokens.space1),
                  child: Text(
                    foot,
                    key: const Key('dashboard.inbox.more'),
                    style: context.text.labelMedium!.copyWith(color: muted),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One item of the block, 32 high: the kind's icon and word in its colour
/// (a must-read's topic), the gist in one line – a command in mono – and
/// the time. A click opens it in the Inbox.
class _BlockRow extends ConsumerWidget {
  const _BlockRow({required this.item, required this.now});

  final InboxItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final look = inboxLook(context, item);
    // the two long words would not fit the column: the icon says “failed”
    final word = switch (item.kind) {
      InboxKind.mustRead => ref.watch(
        newsProvider.select((v) => v.topicName(item.story?.topic)),
      ),
      InboxKind.switchFailed => l.inboxBlockSwitch,
      InboxKind.scheduleFailed => l.inboxBlockSchedule,
      _ => look.word,
    };
    final gist = inboxGist(ref, item);
    final at = item.at;
    return InkWell(
      key: ValueKey('dashboard.inbox.row.${item.id}'),
      borderRadius: BorderRadius.circular(DelveTokens.rxs),
      onTap: () => context.go(Routes.inboxItem(item.id)),
      child: SizedBox(
        height: DelveDesktop.inboxBlockRow,
        child: Row(
          children: [
            SymbolIcon(
              look.icon,
              size: DelveDesktop.inboxIcon,
              filled: look.filled,
              color: look.color,
            ),
            const SizedBox(width: DelveDesktop.inboxIconGap),
            SizedBox(
              width: DelveDesktop.inboxBlockWord,
              child: Text(
                word,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium!.copyWith(color: look.color),
              ),
            ),
            const SizedBox(width: DelveTokens.space2),
            Expanded(
              child: Text(
                item.isApproval ? displayCommand(gist) : gist,
                key: ValueKey('dashboard.inbox.gist.${item.id}'),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: item.isApproval
                    ? DelveText.mono.copyWith(
                        fontSize: 12.5,
                        height: 18 / 12.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      )
                    : context.text.titleSmall!.copyWith(color: cs.onSurface),
              ),
            ),
            if (at != null)
              Padding(
                padding: const EdgeInsets.only(left: DelveTokens.space2),
                child: Text(
                  listTime(at, now),
                  style: DelveDesktopText.meta.copyWith(
                    color: context.delve.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
