import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/layout.dart';
import '../../app/news.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart';
import '../desktop/intake.dart'
    show ListCommandSlot, ListCommands, listCommandSlotProvider;
import '../format.dart';
import '../general/general_widgets.dart' show DelveFilterChip;
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// What the News page shows: All (sections), Saved, one topic, or last
/// week's unopened best ones (from the Dashboard's Monday row).
sealed class NewsFilter {
  const NewsFilter();
}

final class NewsFilterAll extends NewsFilter {
  const NewsFilterAll();
}

final class NewsFilterSaved extends NewsFilter {
  const NewsFilterSaved();
}

final class NewsFilterWeekly extends NewsFilter {
  const NewsFilterWeekly();
}

final class NewsFilterTopic extends NewsFilter {
  const NewsFilterTopic(this.topic);
  final String topic;
}

/// Where a section's edge and its rows' text start (design 26 D3: the edge
/// at x = 31-34, centred under the 32 dp tile; the text at x = 48).
const double _edgeX = 31;
const double _textX = 48;

/// D3-b News page: chips (All · Saved · the topics, each with its colour
/// dot), All as one section per topic (tile, coloured name, its best 3 of
/// the day on one edge, Show all N), one topic with an edge per day,
/// Saved with an edge per row. “Last week” is the same page without chips.
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key, this.weekly = false, this.topic, this.selected});

  /// Opened from the Dashboard's “Last week” row.
  final bool weekly;

  /// The desktop (L2c2): open on this topic (the inspector's Open topic).
  final String? topic;

  /// The desktop: the story open in the content (its row is selected).
  final int? selected;

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late NewsFilter _filter = switch (widget.topic) {
    final t? => NewsFilterTopic(t),
    null when widget.weekly => const NewsFilterWeekly(),
    null => const NewsFilterAll(),
  };

  /// The desktop: the stories in the order shown (J / K).
  List<int> _order = const [];
  late final ListCommandSlot _keys;
  late final PageCommandSlot _pageKeys;

  @override
  void initState() {
    super.initState();
    _keys = ref.read(listCommandSlotProvider);
    _pageKeys = ref.read(pageCommandSlotProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  /// The desktop's list stays while the content changes: a new topic (Open
  /// topic) or last week (the Dashboard's row) changes the filter; a story
  /// opening (no topic in its location) keeps it.
  @override
  void didUpdateWidget(NewsScreen old) {
    super.didUpdateWidget(old);
    final NewsFilter? next = switch (widget.topic) {
      final t? when t != old.topic => NewsFilterTopic(t),
      null when widget.weekly && !old.weekly => const NewsFilterWeekly(),
      _ => null,
    };
    if (next == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _select(next);
    });
  }

  @override
  void dispose() {
    _keys.unregister(this);
    _pageKeys.unregister(this);
    super.dispose();
  }

  /// J / K: the next / previous story of the list (the first without one
  /// open).
  void _step(int by) {
    final order = _order;
    if (order.isEmpty) return;
    final at = widget.selected == null ? -1 : order.indexOf(widget.selected!);
    final next = at < 0 ? 0 : (at + by).clamp(0, order.length - 1);
    if (next == at) return;
    openNewsStory(context, order[next]);
  }

  NewsListKey? get _listKey => switch (_filter) {
    NewsFilterAll() => null,
    NewsFilterSaved() => const NewsListKey.saved(),
    NewsFilterWeekly() => const NewsListKey.weekly(),
    NewsFilterTopic(:final topic) => NewsListKey.topic(topic),
  };

  Future<void> _refresh({bool quiet = false}) async {
    try {
      final news = ref.read(newsProvider.notifier);
      final key = _listKey;
      await Future.wait([
        news.refreshSections(),
        news.refreshDigest(),
        if (key != null) ref.read(newsListProvider(key).notifier).refresh(),
      ]);
    } on Object catch (e) {
      if (quiet || !mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.newsLoadFailed(apiErrorText(l, e)))),
      );
    }
  }

  void _select(NewsFilter f) {
    setState(() => _filter = f);
    final key = _listKey;
    if (key != null) {
      unawaited(
        ref.read(newsListProvider(key).notifier).refresh().catchError((_) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(newsProvider);
    final sections = view.sections;
    if (DesktopLayout.of(context)) return _desktop(context, l, view);
    return Scaffold(
      appBar: PageColourBar(
        title: widget.weekly ? l.newsLastWeek : l.newsTitle,
        actions: [
          if (!widget.weekly)
            IconButton(
              key: const Key('news.settings'),
              tooltip: l.newsSettingsTitle,
              onPressed: () => context.open(Routes.newsSettings),
              icon: const SymbolIcon(DelveIcons.settings),
            ),
        ],
      ),
      body: UnderBarFade(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: UnderBarFade.height),
              ),
              if (!widget.weekly)
                SliverToBoxAdapter(
                  child: _Chips(
                    filter: _filter,
                    sections: sections ?? const [],
                    onSelect: _select,
                  ),
                ),
              ..._body(context, l, view),
              const SliverToBoxAdapter(
                child: SizedBox(height: DelveTokens.space6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The desktop's list column (27W-5a): a 48 px header with News settings,
  /// the chips, the sections or the filtered list; the open story's row is
  /// selected. J / K step through the stories, Ctrl+R reloads.
  Widget _desktop(BuildContext context, AppLocalizations l, NewsView view) {
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
    final order = <int>[];
    final body = _body(context, l, view, order: order);
    _order = order;
    return SelectedNewsStory(
      id: widget.selected,
      child: TopLevelPage(
        title: _filter is NewsFilterWeekly ? l.newsLastWeek : l.newsTitle,
        background: context.colors.surfaceContainerLow,
        actions: [
          IconButton(
            key: const Key('news.settings'),
            tooltip: l.newsSettingsTitle,
            onPressed: () => context.open(Routes.newsSettingsAt('topics')),
            icon: const SymbolIcon(
              DelveIcons.settings,
              size: DelveDesktop.iconButtonIcon,
            ),
          ),
        ],
        child: CustomScrollView(
          key: const Key('news.list'),
          slivers: [
            SliverToBoxAdapter(
              child: _Chips(
                filter: _filter,
                sections: view.sections ?? const [],
                onSelect: _select,
              ),
            ),
            ...body,
            const SliverToBoxAdapter(
              child: SizedBox(height: DelveTokens.space4),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    NewsView view, {
    List<int>? order,
  }) {
    final key = _listKey;
    if (key == null) return _all(context, l, view, order);
    return _list(context, l, key, order);
  }

  Widget _status(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      0,
      DelveTokens.space4,
      DelveTokens.space1,
    ),
    child: Text(
      text,
      key: const Key('news.status'),
      style: context.text.labelMedium!.copyWith(color: context.delve.textMuted),
    ),
  );

  Widget _loading(Object? error) => error != null
      ? _ErrorBanner(error: error, onRetry: _refresh)
      : const Padding(
          padding: EdgeInsets.all(DelveTokens.space8),
          child: Center(child: CircularProgressIndicator()),
        );

  void _menu(BuildContext ctx, NewsItem i) =>
      unawaited(showNewsMenu(ctx, ref, i));

  List<Widget> _all(
    BuildContext context,
    AppLocalizations l,
    NewsView view, [
    List<int>? order,
  ]) {
    final sections = view.sections;
    if (sections == null) {
      return [SliverToBoxAdapter(child: _loading(view.error))];
    }
    if (sections.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Empty(
            title: l.newsEmptyTopicsOff,
            body: l.newsEmptyTopicsOffBody,
            action: (
              l.newsSettingsOpen,
              () => context.open(Routes.newsSettings),
            ),
          ),
        ),
      ];
    }
    final now = DateTime.now();
    final total = sections.fold<int>(0, (n, s) => n + s.count);
    final updated = view.digest?.updatedAt;
    final shown = [
      for (final s in sections)
        if (s.week > 0 || s.count > 0) s,
    ];
    order?.addAll([
      for (final s in shown)
        for (final item in s.top) item.id,
    ]);
    return [
      SliverToBoxAdapter(
        child: _status(
          context,
          updated == null
              ? l.newsStoriesToday(total)
              : l.newsLastRound(clockTime(updated, now), total),
        ),
      ),
      if (shown.isEmpty)
        SliverToBoxAdapter(
          child: _Empty(title: l.newsEmptyTitle, body: l.newsEmptyBody),
        ),
      for (final s in shown)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                topic: s.topic,
                name: s.name,
                trailing: l.newsToday(s.count),
                onTap: () => _select(NewsFilterTopic(s.topic)),
              ),
              if (s.top.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _textX,
                    0,
                    DelveTokens.space4,
                    DelveTokens.space2,
                  ),
                  child: Text(
                    l.newsNothingToday,
                    style: context.text.bodyMedium!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                _OnEdge(
                  topic: s.topic,
                  children: [
                    for (final item in s.top)
                      NewsStoryRow(
                        item: item,
                        now: now,
                        layout: NewsRowLayout.onSection,
                        gap: 16,
                        onLongPress: _menu,
                      ),
                  ],
                ),
              _ShowAll(
                key: Key('news.showAll.${s.topic}'),
                count: s.count > 0 ? s.count : s.week,
                onTap: () => _select(NewsFilterTopic(s.topic)),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    NewsListKey key, [
    List<int>? order,
  ]) {
    final list = ref.watch(newsListProvider(key));
    final items = list.items;
    final now = DateTime.now();
    final sections = ref.watch(newsProvider.select((v) => v.sections));
    final topic = key.topic;
    final section = topic == null
        ? null
        : sections?.where((s) => s.topic == topic).firstOrNull;
    final head = <Widget>[
      if (topic != null)
        SliverToBoxAdapter(
          child: _SectionHeader(
            topic: topic,
            name: section?.name ?? ref.read(newsProvider).topicName(topic),
            trailing: section == null
                ? null
                : l.newsTopicStatus(section.count, section.week),
          ),
        )
      else if (_filter is NewsFilterSaved && items != null)
        SliverToBoxAdapter(
          child: _status(context, l.newsSavedCount(items.length)),
        )
      else if (_filter is NewsFilterWeekly && items != null)
        SliverToBoxAdapter(
          child: _status(context, l.newsLastWeekStatus(items.length)),
        ),
    ];
    if (items == null) {
      return [...head, SliverToBoxAdapter(child: _loading(list.error))];
    }
    if (items.isEmpty) {
      return [
        ...head,
        SliverToBoxAdapter(
          child: switch (_filter) {
            NewsFilterSaved() => _Empty(
              title: l.newsEmptySavedTitle,
              body: l.newsEmptySavedBody,
            ),
            _ => _Empty(title: l.newsEmptyTitle, body: l.newsEmptyBody),
          },
        ),
      ];
    }
    order?.addAll([for (final item in items) item.id]);
    final List<Widget> body;
    if (topic != null) {
      // one edge per day, the day's header at the text column
      final days = <String, List<NewsItem>>{};
      for (final item in items) {
        days.putIfAbsent(_dayLabel(l, item.at, now), () => []).add(item);
      }
      body = [
        for (final MapEntry(key: day, value: rows) in days.entries) ...[
          SliverToBoxAdapter(child: _DayHeader(label: day)),
          SliverToBoxAdapter(
            child: _OnEdge(
              topic: topic,
              children: [
                for (final item in rows)
                  NewsStoryRow(
                    item: item,
                    now: now,
                    layout: NewsRowLayout.onSection,
                    gap: 16,
                    onLongPress: _menu,
                  ),
              ],
            ),
          ),
        ],
      ];
    } else {
      body = [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
          sliver: SliverList.list(
            children: [
              for (final item in items)
                NewsStoryRow(item: item, now: now, onLongPress: _menu),
            ],
          ),
        ),
      ];
    }
    return [
      ...head,
      ...body,
      if (list.next != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              topic != null ? _textX - DelveTokens.space3 : DelveTokens.space2,
              DelveTokens.space2,
              DelveTokens.space4,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('news.loadOlder'),
                onPressed: () => unawaited(
                  ref
                      .read(newsListProvider(key).notifier)
                      .loadMore()
                      .catchError((_) {}),
                ),
                child: Text(l.newsLoadOlder),
              ),
            ),
          ),
        ),
    ];
  }

  static String _dayLabel(AppLocalizations l, DateTime at, DateTime now) {
    final a = at.toLocal();
    final n = now.toLocal();
    final days = DateTime.utc(
      n.year,
      n.month,
      n.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
    if (days <= 0) return l.newsDayToday;
    if (days == 1) return l.newsYesterday;
    return DateFormat('EEE d MMM').format(a);
  }
}

/// All · Saved · the topics (Saved second, so it is never off-screen);
/// a topic chip has its colour dot while off.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.filter,
    required this.sections,
    required this.onSelect,
  });

  final NewsFilter filter;
  final List<NewsSection> sections;
  final ValueChanged<NewsFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chips = <(NewsFilter, String, IconData?, Color?, String)>[
      (const NewsFilterAll(), l.newsAll, null, null, 'all'),
      (const NewsFilterSaved(), l.newsSaved, NewsIcons.saved, null, 'saved'),
      for (final s in sections)
        (
          NewsFilterTopic(s.topic),
          s.name,
          null,
          TopicStyle.of(s.topic).color,
          s.topic,
        ),
    ];
    bool on(NewsFilter f) => switch ((f, filter)) {
      (NewsFilterAll(), NewsFilterAll()) => true,
      (NewsFilterSaved(), NewsFilterSaved()) => true,
      (NewsFilterTopic(:final topic), NewsFilterTopic(topic: final t)) =>
        topic == t,
      _ => false,
    };
    return SizedBox(
      height: 48,
      child: ListView(
        key: const Key('news.chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
        children: [
          for (final (n, (f, label, icon, dot, id)) in chips.indexed) ...[
            if (n > 0) const SizedBox(width: DelveTokens.space2),
            Center(
              child: DelveFilterChip(
                key: Key('news.chip.$id'),
                selected: on(f),
                icon: icon,
                dot: dot,
                label: label,
                semantics: label,
                onTap: () => onSelect(f),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A topic's header: the 32 dp tile with the glyph, the name in the topic
/// colour, a count on the right. Tapping opens the topic.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.topic,
    required this.name,
    this.trailing,
    this.onTap,
  });

  final String topic;
  final String name;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = TopicStyle.of(topic);
    final t = trailing;
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space1),
      child: InkWell(
        key: Key('news.section.$topic'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: s.tile,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SymbolIcon(s.glyph, size: 20, color: s.color),
                ),
              ),
              const SizedBox(width: DelveTokens.space3),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium!.copyWith(color: s.color),
                ),
              ),
              if (t != null) ...[
                const SizedBox(width: DelveTokens.space2),
                // a narrow list column (the desktop's 240 – 300) cuts the
                // count before the name
                Flexible(
                  child: Text(
                    t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: context.text.labelMedium!.copyWith(
                      color: context.delve.textMuted,
                    ),
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

/// Rows on one continuous edge in the topic colour (x = 31-34), the text
/// at x = 48.
class _OnEdge extends StatelessWidget {
  const _OnEdge({required this.topic, required this.children});

  final String topic;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(_edgeX, 2, DelveTokens.space4, 2),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopicEdge(color: TopicStyle.of(topic).color),
          const SizedBox(width: _textX - _edgeX - 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}

/// “Show all N”: neutral, at the text column, no rule (design 26 D3).
class _ShowAll extends StatelessWidget {
  const _ShowAll({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.fromLTRB(_textX, 0, DelveTokens.space4, 0),
        child: Row(
          children: [
            Text(
              l.newsShowAll(count),
              style: context.text.labelLarge!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: DelveTokens.space1),
            SymbolIcon(
              DelveIcons.chevronRight,
              size: DelveTokens.iconMd,
              color: context.delve.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(_textX, 16, DelveTokens.space4, 8),
    child: Text(
      label.toUpperCase(),
      style: context.text.labelSmall!.copyWith(color: context.delve.textMuted),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body, this.action});
  final String title;
  final String body;

  /// A tonal button under the text (“Open News settings”).
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('news.empty'),
    padding: const EdgeInsets.fromLTRB(40, 28, 40, 32),
    child: Column(
      children: [
        SymbolIcon(NewsIcons.news, size: 40, color: context.delve.textMuted),
        const SizedBox(height: DelveTokens.space3),
        Text(
          title,
          style: context.text.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DelveTokens.space2),
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (action case (final label, final onPressed)) ...[
          const SizedBox(height: DelveTokens.space4),
          FilledButton.tonal(
            key: const Key('news.empty.settings'),
            onPressed: onPressed,
            child: Text(label),
          ),
        ],
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(DelveTokens.space4),
      child: StatusBanner(
        kind: StatusKind.alert,
        icon: DelveIcons.error,
        text: l.newsLoadFailed(apiErrorText(l, error)),
        actionLabel: l.retry,
        onAction: () => unawaited(onRetry()),
      ),
    );
  }
}
