import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/models/models.dart';
import '../../app/news.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../links.dart';
import 'page_scaffolds.dart';

/// News icons (design 26, `delve_tokens.json` → news.icons).
abstract final class NewsIcons {
  static const IconData news = Symbols.newspaper_rounded;
  static const IconData mustRead = Symbols.flag_rounded;
  static const IconData setup = Symbols.desktop_windows_rounded;
  static const IconData saved = Symbols.bookmark_rounded;
  static const IconData ai = Symbols.psychology_rounded;
  static const IconData summaryPending = Symbols.hourglass_top_rounded;
  static const IconData fetchText = Symbols.article_rounded;
  static const IconData queued = Symbols.schedule_rounded;
  static const IconData tryAgain = Symbols.refresh_rounded;
  static const IconData openOriginal = Symbols.open_in_new_rounded;
  static const IconData more = Symbols.thumb_up_rounded;
  static const IconData less = Symbols.thumb_down_rounded;
  static const IconData hide = Symbols.visibility_off_rounded;
  static const IconData copyLink = Symbols.link_rounded;
  static const IconData lastWeek = Symbols.history_rounded;
  static const IconData failingFeeds = Symbols.rss_feed_rounded;
  static const IconData expand = Symbols.expand_more_rounded;
}

/// The age of a story (design 26-0): `35 min` / `2 h` under a day, the
/// weekday within six days, else `12 Nov`. Local time.
String newsAge(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  if (d.inDays < 7) return DateFormat('EEE').format(at.toLocal());
  return DateFormat('d MMM').format(at.toLocal());
}

/// The host of a link, without `www.` (`sail-world.com`).
String newsHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  return host.startsWith('www.') ? host.substring(4) : host;
}

/// The meta line of a story row: Must read · Your setup first (one step
/// brighter, icon + word), then topic · publisher · N sources · age, or
/// Releases; a bookmark at the end when saved.
class NewsMetaLine extends ConsumerWidget {
  const NewsMetaLine({
    super.key,
    required this.item,
    required this.now,
    this.showTopic = true,
    this.read = false,
  });

  final NewsItem item;
  final DateTime now;
  final bool showTopic;
  final bool read;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final topic = showTopic
        ? ref.watch(newsProvider.select((v) => v.topicName(item.topic)))
        : '';
    final base = context.text.labelMedium!.copyWith(
      color: read ? context.delve.textMuted : context.colors.onSurfaceVariant,
    );
    final bright = base.copyWith(color: context.colors.onSurface);
    final parts = [
      if (topic.isNotEmpty) topic,
      if (item.isRelease) l.newsReleases,
      ?item.publisher,
      if (item.sources > 1) l.newsSources(item.sources),
      newsAge(item.at, now),
    ];
    InlineSpan marker(IconData icon, String word) => TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SymbolIcon(
            icon,
            size: 14,
            filled: icon == NewsIcons.mustRead,
            color: bright.color,
          ),
        ),
        TextSpan(text: ' $word  ', style: bright),
      ],
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (item.mustRead) marker(NewsIcons.mustRead, l.newsMustRead),
          if (item.touchesSetup) marker(NewsIcons.setup, l.newsYourSetup),
          TextSpan(text: parts.join(' · ')),
          if (item.saved)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: DelveTokens.space2),
                child: SymbolIcon(
                  NewsIcons.saved,
                  key: Key('news.saved.${item.id}'),
                  size: DelveTokens.iconSm,
                  filled: true,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One story (design 26-0 “Story row”): title (2 lines, weight by read
/// state) and the meta line. Tap → reading view; long press → [onLongPress]
/// (the menu; on the Dashboard: copy the link).
class NewsStoryRow extends ConsumerWidget {
  const NewsStoryRow({
    super.key,
    required this.item,
    required this.now,
    this.showTopic = true,
    this.dense = false,
    this.divider = true,
    this.onLongPress,
  });

  final NewsItem item;
  final DateTime now;
  final bool showTopic;

  /// The Dashboard block: padding 8 0, the rule above.
  final bool dense;
  final bool divider;
  final void Function(BuildContext context, NewsItem item)? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(newsProvider.select((v) => v.current(item)));
    final rule = BorderSide(color: context.colors.outlineVariant);
    final title = i.read
        ? context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          )
        : context.text.titleSmall;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('news.row.${i.id}'),
        onTap: () => openNewsStory(context, i.id),
        onLongPress: onLongPress == null
            ? null
            : () => onLongPress!(context, i),
        child: Container(
          constraints: BoxConstraints(minHeight: dense ? 56 : 64),
          padding: dense
              ? const EdgeInsets.symmetric(vertical: DelveTokens.space2)
              : const EdgeInsets.fromLTRB(
                  DelveTokens.space4,
                  10,
                  DelveTokens.space4,
                  10,
                ),
          decoration: BoxDecoration(
            border: !divider
                ? null
                : dense
                ? Border(top: rule)
                : null,
          ),
          foregroundDecoration: !divider || dense
              ? null
              : _InsetRule(context.colors.outlineVariant),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                i.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: title,
              ),
              const SizedBox(height: 3),
              NewsMetaLine(
                item: i,
                now: now,
                showTopic: showTopic,
                read: i.read,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1 dp rule at the bottom, inset 16 on the left (design 26-0).
class _InsetRule extends Decoration {
  const _InsetRule(this.color);
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _InsetPainter(color);
}

class _InsetPainter extends BoxPainter {
  _InsetPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final y = offset.dy + size.height - 0.5;
    canvas.drawLine(
      Offset(offset.dx + DelveTokens.space4, y),
      Offset(offset.dx + size.width, y),
      Paint()
        ..color = color
        ..strokeWidth = DelveTokens.hairline,
    );
  }
}

/// Opens the reading view of a story.
void openNewsStory(BuildContext context, int id) =>
    unawaited(context.push(Routes.newsStory(id)));

/// What the long-press menu offers.
enum _MenuAction { more, less, hide, save, copy }

/// The long-press menu of a row (design 26c): More / Less like this, Hide
/// the feed, Save, Copy link - opened under the pressed row.
Future<void> showNewsMenu(
  BuildContext context,
  WidgetRef ref,
  NewsItem item,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final topLeft = box == null
      ? Offset.zero
      : box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);
  final position = RelativeRect.fromRect(
    Rect.fromLTWH(topLeft.dx + DelveTokens.space4, topLeft.dy, 0, 0),
    Offset.zero & overlay.size,
  );
  PopupMenuItem<_MenuAction> row(
    _MenuAction a,
    IconData icon,
    String label, {
    bool filled = false,
  }) => PopupMenuItem<_MenuAction>(
    key: Key('news.menu.${a.name}'),
    value: a,
    child: Row(
      children: [
        SymbolIcon(
          icon,
          size: DelveTokens.iconMd,
          filled: filled,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: DelveTokens.space3),
        Flexible(child: Text(label, style: context.text.bodyMedium)),
      ],
    ),
  );
  final hideable = item.source != null && !item.gn;
  final choice = await showMenu<_MenuAction>(
    context: context,
    position: position,
    constraints: const BoxConstraints(minWidth: 248),
    items: [
      row(
        _MenuAction.more,
        NewsIcons.more,
        l.newsMoreLikeThis,
        filled: item.feedback == 'more',
      ),
      row(
        _MenuAction.less,
        NewsIcons.less,
        l.newsLessLikeThis,
        filled: item.feedback == 'less',
      ),
      if (hideable)
        row(
          _MenuAction.hide,
          NewsIcons.hide,
          l.newsHideSource(item.publisher ?? item.source!),
        ),
      row(
        _MenuAction.save,
        NewsIcons.saved,
        item.saved ? l.newsRemoveFromSaved : l.newsSave,
        filled: item.saved,
      ),
      row(_MenuAction.copy, NewsIcons.copyLink, l.newsCopyLink),
    ],
  );
  if (choice == null || !context.mounted) return;
  final news = ref.read(newsProvider.notifier);
  void say(String text, {VoidCallback? undo}) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: undo == null
            ? null
            : SnackBarAction(label: l.newsUndo, onPressed: undo),
      ),
    );
  try {
    switch (choice) {
      case _MenuAction.more || _MenuAction.less:
        final f = choice == _MenuAction.more ? 'more' : 'less';
        final clear = item.feedback == f;
        await news.mark(item, feedback: clear ? null : f, clearFeedback: clear);
        if (!clear) {
          say(f == 'more' ? l.newsMoreLikeThis : l.newsLessLikeThis);
        }
      case _MenuAction.hide:
        final source = item.source!;
        await news.setSource(source, enabled: false);
        say(
          l.newsSourceHidden(item.publisher ?? source),
          undo: () => unawaited(news.setSource(source, enabled: true)),
        );
      case _MenuAction.save:
        await news.mark(item, saved: !item.saved);
        say(item.saved ? l.newsRemovedFromSaved : l.newsSavedSnack);
      case _MenuAction.copy:
        if (context.mounted) await copyLink(context, item.originalUrl);
    }
  } on Object catch (e) {
    say(l.newsActionFailed(apiErrorText(l, e)));
  }
}

/// 26a Dashboard News block, between the Brief and Watches: the header
/// opens the News page; the best unread story of each topic of the last
/// day; the Monday “Last week” row; the failing feeds. Hidden until the
/// first answer (and while the server has no News).
class NewsCard extends ConsumerWidget {
  const NewsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(newsProvider.select((v) => v.digest));
    if (digest == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final muted = context.delve.textMuted;
    final rule = BorderSide(color: context.colors.outlineVariant);
    final updated = digest.updatedAt;
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space3),
      child: Container(
        key: const Key('dashboard.news'),
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          DelveTokens.space3,
          DelveTokens.space4,
          DelveTokens.space1,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DelveTokens.rlg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const Key('dashboard.news.open'),
              onTap: () => context.push(Routes.news),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: DelveTokens.touchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l.newsTitle, style: context.text.titleMedium),
                    ),
                    if (digest.fresh > 0)
                      Text(
                        l.newsNew(digest.fresh),
                        style: context.text.labelMedium!.copyWith(color: muted),
                      ),
                    const SizedBox(width: DelveTokens.space1),
                    SymbolIcon(DelveIcons.chevronRight, size: 22, color: muted),
                  ],
                ),
              ),
            ),
            if (digest.weekly case final w? when w.count > 0)
              InkWell(
                key: const Key('dashboard.news.weekly'),
                onTap: () => context.push(Routes.newsWeekly),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(border: Border(top: rule)),
                  child: Row(
                    children: [
                      SymbolIcon(
                        NewsIcons.lastWeek,
                        size: DelveTokens.iconMd,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: DelveTokens.space3),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: l.newsLastWeek,
                                style: context.text.titleSmall,
                              ),
                              TextSpan(text: ' · ${l.newsMissed(w.count)}'),
                            ],
                          ),
                          style: context.text.bodyMedium,
                        ),
                      ),
                      SymbolIcon(
                        DelveIcons.chevronRight,
                        size: DelveTokens.iconMd,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            if (digest.state == 'empty')
              Padding(
                key: const Key('dashboard.news.first'),
                padding: const EdgeInsets.only(bottom: DelveTokens.space3),
                child: Text(l.newsFirstRound, style: context.text.bodyMedium),
              )
            else if (digest.top.isEmpty)
              Padding(
                key: const Key('dashboard.news.nothing'),
                padding: const EdgeInsets.only(bottom: DelveTokens.space3),
                child: Text(
                  updated == null
                      ? l.newsNothingNewShort
                      : l.newsNothingNew(clockTime(updated, now)),
                  style: context.text.bodyMedium!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final item in digest.top)
                NewsStoryRow(
                  item: item,
                  now: now,
                  dense: true,
                  onLongPress: (ctx, i) => copyLink(ctx, i.originalUrl),
                ),
            if (digest.failing > 0)
              Container(
                key: const Key('dashboard.news.failing'),
                constraints: const BoxConstraints(minHeight: 40),
                decoration: BoxDecoration(border: Border(top: rule)),
                child: Row(
                  children: [
                    SymbolIcon(
                      NewsIcons.failingFeeds,
                      size: DelveTokens.iconSm,
                      color: muted,
                    ),
                    const SizedBox(width: DelveTokens.space2),
                    Expanded(
                      child: Text(
                        l.newsFailingFeeds(digest.failing),
                        style: context.text.bodySmall!.copyWith(color: muted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
