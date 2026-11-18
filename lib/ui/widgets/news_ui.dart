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

/// News icons (design 26 D3, `delve_tokens.json` → news.icons).
abstract final class NewsIcons {
  static const IconData news = Symbols.newspaper_rounded;
  static const IconData mustRead = Symbols.flag_rounded;
  static const IconData setup = Symbols.desktop_windows_rounded;
  static const IconData releases = Symbols.sell_rounded;
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
  static const IconData tune = Symbols.tune_rounded;
}

/// A topic's quiet colour and glyph (design 26 D3, Components → “Topic
/// palette”): the label, the edge, the glyph and its tile, the chip dot and
/// the Must read tag - nowhere else. Fixed per topic id; an id the app does
/// not know gets [fallback].
@immutable
class TopicStyle {
  const TopicStyle({
    required this.color,
    required this.tag,
    required this.tile,
    required this.readLabel,
    required this.readEdge,
    required this.glyph,
  });

  /// [readLabel] / [readEdge]: the colour at 70 % / 45 % over the
  /// background (a read row with its own edge).
  final Color color;
  final Color tag;
  final Color tile;
  final Color readLabel;
  final Color readEdge;
  final IconData glyph;

  static const fallback = TopicStyle(
    color: Color(0xFFADB1B6),
    tag: Color(0xFF393A3D),
    tile: Color(0xFF2A2B2D),
    readLabel: Color(0xFF7E8185),
    readEdge: Color(0xFF575A5C),
    glyph: Symbols.label_rounded,
  );

  static const Map<String, TopicStyle> _topics = {
    'sailing': TopicStyle(
      color: Color(0xFF8FB4E8),
      tag: Color(0xFF323B48),
      tile: Color(0xFF252C35),
      readLabel: Color(0xFF6983A8),
      readEdge: Color(0xFF4A5B73),
      glyph: Symbols.sailing_rounded,
    ),
    'local_ai': TopicStyle(
      color: Color(0xFFB5A2EC),
      tag: Color(0xFF3B3749),
      tile: Color(0xFF2B2936),
      readLabel: Color(0xFF8477AB),
      readEdge: Color(0xFF5B5375),
      glyph: Symbols.memory_rounded,
    ),
    'linux': TopicStyle(
      color: Color(0xFFB9C77B),
      tag: Color(0xFF3B3F30),
      tile: Color(0xFF2C2F24),
      readLabel: Color(0xFF87915C),
      readEdge: Color(0xFF5D6342),
      glyph: Symbols.terminal_rounded,
    ),
    'hardware': TopicStyle(
      color: Color(0xFFD8A77C),
      tag: Color(0xFF423830),
      tile: Color(0xFF312A24),
      readLabel: Color(0xFF9C7A5C),
      readEdge: Color(0xFF6B5542),
      glyph: Symbols.developer_board_rounded,
    ),
    'development': TopicStyle(
      color: Color(0xFF86C2B6),
      tag: Color(0xFF303E3D),
      tile: Color(0xFF242E2D),
      readLabel: Color(0xFF638D85),
      readEdge: Color(0xFF46615C),
      glyph: Symbols.code_rounded,
    ),
    'games_film': TopicStyle(
      color: Color(0xFFE29BC4),
      tag: Color(0xFF443640),
      tile: Color(0xFF32282F),
      readLabel: Color(0xFFA3728F),
      readEdge: Color(0xFF6F5063),
      glyph: Symbols.sports_esports_rounded,
    ),
    'tech': TopicStyle(
      color: Color(0xFFA7B7CB),
      tag: Color(0xFF373C42),
      tile: Color(0xFF292C30),
      readLabel: Color(0xFF7A8694),
      readEdge: Color(0xFF545C66),
      glyph: Symbols.devices_rounded,
    ),
    'hungary': TopicStyle(
      color: Color(0xFFD8A09A),
      tag: Color(0xFF423737),
      tile: Color(0xFF312929),
      readLabel: Color(0xFF9C7572),
      readEdge: Color(0xFF6B5250),
      glyph: Symbols.home_pin_rounded,
    ),
    'world': TopicStyle(
      color: Color(0xFFCFC3A2),
      tag: Color(0xFF403E39),
      tile: Color(0xFF2F2E2A),
      readLabel: Color(0xFF968E77),
      readEdge: Color(0xFF666253),
      glyph: Symbols.public_rounded,
    ),
  };

  static TopicStyle of(String? id) => _topics[id] ?? fallback;
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

/// The 3 dp coloured edge (radius 1.5).
class TopicEdge extends StatelessWidget {
  const TopicEdge({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1.5),
    ),
  );
}

/// The topic label: glyph 14 + small caps in the topic colour.
class TopicLabel extends ConsumerWidget {
  const TopicLabel({
    super.key,
    required this.topic,
    this.read = false,
    this.name,
  });
  final String? topic;
  final bool read;

  /// The topic's name when the caller knows it (a topic that is off is not
  /// among the News page's sections).
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = TopicStyle.of(topic);
    final known = ref.watch(newsProvider.select((v) => v.topicName(topic)));
    final name = this.name ?? known;
    final color = read ? style.readLabel : style.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SymbolIcon(style.glyph, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall!.copyWith(
              color: color,
              letterSpacing: 0.9,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small tag (h 22, radius 6) on [bg]; a plain icon + word without [bg].
class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
    this.bg,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? bg;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SymbolIcon(
          icon,
          size: bg == null ? 14 : 13,
          filled: filled,
          color: color,
        ),
        const SizedBox(width: 4),
        // a tag wider than its line (big text, a narrow Dashboard row)
        // shortens instead of overflowing
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall!.copyWith(color: color),
          ),
        ),
      ],
    );
    if (bg == null) return row;
    return Container(
      height: 22,
      padding: const EdgeInsets.fromLTRB(5, 0, 7, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DelveTokens.rxs),
      ),
      child: row,
    );
  }
}

/// The Must read tag: `flag` + words in the topic colour on its tag tint.
Widget mustReadTag(BuildContext context, String? topic) {
  final s = TopicStyle.of(topic);
  return _Tag(
    icon: NewsIcons.mustRead,
    label: AppLocalizations.of(context).newsMustRead,
    color: s.color,
    bg: s.tag,
    filled: true,
  );
}

/// The tags of a story: topic label (where topics are mixed) · Must read ·
/// Your setup · Releases; empty when none applies.
List<Widget> newsTags(
  BuildContext context,
  NewsItem item, {
  bool topic = true,
  bool read = false,
}) {
  final l = AppLocalizations.of(context);
  return [
    if (topic) TopicLabel(topic: item.topic, read: read),
    if (item.mustRead) mustReadTag(context, item.topic),
    if (item.touchesSetup)
      _Tag(
        icon: NewsIcons.setup,
        label: l.newsYourSetup,
        color: read
            ? context.colors.onSurfaceVariant
            : context.colors.onSurface,
      ),
    if (item.isRelease)
      _Tag(
        icon: NewsIcons.releases,
        label: l.newsReleases,
        color: context.colors.onSurfaceVariant,
      ),
  ];
}

/// How a story row is laid out (design 26 D3 “Story row”).
enum NewsRowLayout {
  /// Topics mixed (Saved, Last week): its own edge and the topic label.
  ownEdge,

  /// In a topic section: no edge (the section draws one), no label.
  onSection,

  /// The Dashboard block: own edge, “publisher · age” on the tags line, no
  /// meta line; [NewsStoryRow.why] decides the why (the first row only).
  dashboard,
}

/// One story: tags, title (2 lines, weight by read state), the why (unread
/// only, one line), “publisher · N sources · age”. Tap → reading view; long
/// press → [onLongPress] (the menu; on the Dashboard: copy the link).
class NewsStoryRow extends ConsumerWidget {
  const NewsStoryRow({
    super.key,
    required this.item,
    required this.now,
    this.layout = NewsRowLayout.ownEdge,
    this.why = true,
    this.gap = 18,
    this.onLongPress,
  });

  final NewsItem item;
  final DateTime now;
  final NewsRowLayout layout;

  /// Show the why (unread stories only).
  final bool why;

  /// Space between rows (split above and below, so it is in the tap area).
  final double gap;
  final void Function(BuildContext context, NewsItem item)? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final i = ref.watch(newsProvider.select((v) => v.current(item)));
    final style = TopicStyle.of(i.topic);
    final muted = context.delve.textMuted;
    final dash = layout == NewsRowLayout.dashboard;
    final title = i.read
        ? context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          )
        : context.text.titleSmall;
    final tags = newsTags(
      context,
      i,
      topic: layout != NewsRowLayout.onSection,
      read: i.read,
    );
    final whyText = i.why;
    final showWhy = why && !i.read && whyText != null && whyText.isNotEmpty;
    final metaStyle = context.text.labelMedium!.copyWith(color: muted);
    final tagsLine = dash
        ? Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: DelveTokens.space2,
                  runSpacing: DelveTokens.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: tags,
                ),
              ),
              const SizedBox(width: DelveTokens.space2),
              if (i.publisher case final p?)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    '$p · ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
                  ),
                ),
              Text(newsAge(i.at, now), style: metaStyle),
            ],
          )
        : tags.isEmpty
        ? null
        : Wrap(
            spacing: DelveTokens.space2,
            runSpacing: DelveTokens.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: tags,
          );
    final meta = [
      ?i.publisher,
      if (i.sources > 1) l.newsSources(i.sources),
      newsAge(i.at, now),
    ].join(' · ');
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tagsLine != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 22),
            child: Align(alignment: Alignment.centerLeft, child: tagsLine),
          ),
          const SizedBox(height: 5),
        ],
        Text(
          i.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: title,
        ),
        if (showWhy) ...[
          const SizedBox(height: 2),
          Text(
            whyText,
            key: Key('news.why.${i.id}'),
            maxLines: dash ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        if (!dash) ...[
          const SizedBox(height: DelveTokens.space1),
          Row(
            children: [
              Expanded(child: Text(meta, style: metaStyle)),
              if (i.saved)
                SymbolIcon(
                  NewsIcons.saved,
                  key: Key('news.saved.${i.id}'),
                  size: DelveTokens.iconSm,
                  filled: true,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ],
    );
    final body = layout == NewsRowLayout.onSection
        ? content
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopicEdge(color: i.read ? style.readEdge : style.color),
                const SizedBox(width: DelveTokens.space3),
                Expanded(child: content),
              ],
            ),
          );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('news.row.${i.id}'),
        borderRadius: BorderRadius.circular(4),
        onTap: () => openNewsStory(context, i.id),
        onLongPress: onLongPress == null
            ? null
            : () => onLongPress!(context, i),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: gap / 2),
          child: body,
        ),
      ),
    );
  }
}

/// Opens the reading view of a story.
void openNewsStory(BuildContext context, int id) =>
    unawaited(context.push(Routes.newsStory(id)));

/// What the long-press menu offers.
enum _MenuAction { more, less, hide, save, copy }

/// The long-press menu of a row (design 26 D3-b6): More / Less like this,
/// Hide the feed (not for a Google News story), Save, Copy link - opened
/// under the pressed row.
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

/// D3-a Dashboard News block, between the Brief and Watches: the header
/// opens the News page; the best unread story of each topic of the last
/// day, each on its topic's edge (the why under the first); the Monday
/// “Last week” row; the failing feeds. Hidden until the first answer (and
/// while the server has no News).
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
          DelveTokens.space4,
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
                  decoration: BoxDecoration(border: Border(bottom: rule)),
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
                padding: const EdgeInsets.only(top: DelveTokens.space1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.newsFirstRound, style: context.text.bodyMedium),
                    Text(
                      l.newsRoundsHourly,
                      style: context.text.bodySmall!.copyWith(color: muted),
                    ),
                  ],
                ),
              )
            else if (digest.top.isEmpty)
              Padding(
                key: const Key('dashboard.news.nothing'),
                padding: const EdgeInsets.only(top: DelveTokens.space1),
                child: Text(
                  updated == null
                      ? l.newsNothingNewShort
                      : l.newsNothingNew(clockTime(updated, now)),
                  style: context.text.bodyMedium!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              for (final (n, item) in digest.top.indexed)
                NewsStoryRow(
                  item: item,
                  now: now,
                  layout: NewsRowLayout.dashboard,
                  why: n == 0,
                  gap: 14,
                  onLongPress: (ctx, i) => copyLink(ctx, i.originalUrl),
                ),
            ],
            if (digest.failing > 0)
              InkWell(
                key: const Key('dashboard.news.failing'),
                onTap: () => context.push(Routes.newsSettings),
                child: Container(
                  margin: const EdgeInsets.only(top: DelveTokens.space2),
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
                      Text(
                        l.newsSetFeeds,
                        style: context.text.labelMedium!.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      SymbolIcon(
                        DelveIcons.chevronRight,
                        size: 18,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
