import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import 'page_scaffolds.dart';

/// One conversation (List row · chat): title, time, preview, context bar and
/// the run / approval marker. Used by Chats and Archived chats.
class ChatRow extends StatelessWidget {
  const ChatRow({super.key, required this.item, required this.onTap});

  final ChatListItem item;
  final VoidCallback onTap;

  /// Title shown for a conversation: the agent's title, else the first user
  /// message, else [fallback].
  static String titleOf(ChatListItem item, String fallback) {
    final title = item.conversation.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final first = previewText(item.firstUserText ?? '');
    return first.isNotEmpty ? first : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final c = item.conversation;

    final approval = item.approvalCommand;
    final last = item.lastText;
    final preview = approval != null
        ? l.chatsApprovalPreview(approval)
        : (last == null ? '' : previewText(last));
    final marker = _marker(context, l);
    final pct = c.contextPct;

    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: onTap,
        highlightColor: cs.surfaceContainerLow,
        child: Container(
          constraints: const BoxConstraints(minHeight: DelveTokens.listRow),
          margin: const EdgeInsets.only(left: DelveTokens.space4),
          padding: const EdgeInsets.fromLTRB(
            0,
            DelveTokens.space3,
            DelveTokens.space4,
            DelveTokens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant,
                width: DelveTokens.hairline,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // The title block takes all the room left of the time, so
                  // the time always sits on the right edge.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            titleOf(item, l.newChat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall,
                          ),
                        ),
                        if (c.thinking) ...[
                          const SizedBox(width: 6),
                          SymbolIcon(
                            DelveIcons.thinking,
                            key: const Key('chats.thinking'),
                            size: DelveTokens.iconSm,
                            color: d.textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: DelveTokens.space3),
                  Text(
                    listTime(c.updatedAt, DateTime.now()),
                    key: const Key('chats.time'),
                    style: context.text.labelMedium!.copyWith(
                      color: d.textMuted,
                    ),
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: DelveTokens.space1),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium!.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (pct != null || marker != null) ...[
                const SizedBox(height: DelveTokens.space2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DelveTokens.space4,
                  runSpacing: DelveTokens.space1,
                  children: [
                    if (pct != null) ContextFill(pct: pct, warn: c.contextWarn),
                    ?marker,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _marker(BuildContext context, AppLocalizations l) {
    final d = context.delve;
    if (item.approvalCommand != null) {
      return Row(
        key: const Key('chats.marker.approval'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(
            DelveIcons.approvals,
            size: 14,
            filled: true,
            color: d.warnFg,
          ),
          const SizedBox(width: DelveTokens.space1),
          Text(
            l.chatsMarkerApproval,
            style: context.text.labelSmall!.copyWith(color: d.warnFg),
          ),
        ],
      );
    }
    if (item.activeRuns == 0 && item.queuedRuns == 0) return null;
    final running = item.activeRuns > 0;
    final color = running ? context.colors.primary : d.textMuted;
    final label = !running
        ? l.chatsMarkerWaiting
        : item.queuedRuns > 0
        ? l.chatsMarkerRunningQueued(item.queuedRuns)
        : l.chatsMarkerRunning;
    return Row(
      key: const Key('chats.marker.run'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.text.labelSmall!.copyWith(color: color)),
      ],
    );
  }
}

/// Context fill: 96 × 2 dp bar and the percentage (warn above 75 %).
class ContextFill extends StatelessWidget {
  const ContextFill({super.key, required this.pct, required this.warn});

  final double pct;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final color = warn ? context.delve.warnFg : cs.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 2,
          alignment: Alignment.centerLeft,
          color: cs.surfaceContainerHighest,
          child: FractionallySizedBox(
            widthFactor: (pct / 100).clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
        const SizedBox(width: DelveTokens.space3),
        Text(
          '${pct.round()}%',
          style: DelveText.monoSmall.copyWith(
            color: warn ? color : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// What a row swiped to the left reveals (02b): accent container, icon and
/// a word on the right.
class SwipeBackground extends StatelessWidget {
  const SwipeBackground({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      color: cs.primaryContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: DelveTokens.space6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(icon, color: cs.primary),
          const SizedBox(width: DelveTokens.space3),
          Text(
            label,
            style: context.text.labelLarge!.copyWith(color: cs.primary),
          ),
        ],
      ),
    );
  }
}

/// List footer: asks for the next page once it scrolls into view.
class LoadMoreFooter extends StatefulWidget {
  const LoadMoreFooter({
    super.key,
    required this.loading,
    required this.onVisible,
  });

  final bool loading;
  final Future<void> Function() onVisible;

  @override
  State<LoadMoreFooter> createState() => _LoadMoreFooterState();
}

class _LoadMoreFooterState extends State<LoadMoreFooter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.onVisible());
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Center(
      child: widget.loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    ),
  );
}
