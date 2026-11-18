import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/news.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
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

/// 26b News page: filter chips (All · Saved · the topics), All as one
/// section per topic (its best 3 of the day, Show all N), one topic newest
/// first with day headers, Saved. A row opens the reading view; long press
/// the menu.
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key, this.weekly = false});

  /// Opened from the Dashboard's “Last week” row.
  final bool weekly;

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late NewsFilter _filter = widget.weekly
      ? const NewsFilterWeekly()
      : const NewsFilterAll();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
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
    return Scaffold(
      appBar: PageColourBar(title: l.newsTitle),
      body: UnderBarFade(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: UnderBarFade.height),
              ),
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

  List<Widget> _body(BuildContext context, AppLocalizations l, NewsView view) {
    final key = _listKey;
    if (key == null) return _all(context, l, view);
    return _list(context, l, key);
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

  List<Widget> _all(BuildContext context, AppLocalizations l, NewsView view) {
    final sections = view.sections;
    final error = view.error;
    if (sections == null) {
      return [
        SliverToBoxAdapter(
          child: error != null
              ? _ErrorBanner(error: error, onRetry: _refresh)
              : const Padding(
                  padding: EdgeInsets.all(DelveTokens.space8),
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      ];
    }
    if (sections.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Empty(
            title: l.newsEmptyTopicsOff,
            body: l.newsEmptyTopicsOffBody,
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
      for (final s in shown) ...[
        SliverToBoxAdapter(child: _SectionHeader(section: s)),
        SliverList.list(
          children: [
            for (final (n, item) in s.top.indexed)
              NewsStoryRow(
                item: item,
                now: now,
                showTopic: false,
                divider: n < s.top.length - 1,
                onLongPress: (ctx, i) => showNewsMenu(ctx, ref, i),
              ),
            if (s.top.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DelveTokens.space4,
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
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: _ShowAll(
            key: Key('news.showAll.${s.topic}'),
            count: s.week,
            onTap: () => _select(NewsFilterTopic(s.topic)),
          ),
        ),
      ],
    ];
  }

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    NewsListKey key,
  ) {
    final list = ref.watch(newsListProvider(key));
    final items = list.items;
    final now = DateTime.now();
    final sections = ref.watch(newsProvider.select((v) => v.sections));
    final section = key.topic == null
        ? null
        : sections?.where((s) => s.topic == key.topic).firstOrNull;
    final status = switch (_filter) {
      NewsFilterSaved() =>
        items == null ? null : l.newsSavedCount(items.length),
      NewsFilterWeekly() => l.newsLastWeekStatus,
      NewsFilterTopic() when section != null => l.newsTopicStatus(
        section.week,
        section.fresh,
      ),
      _ => null,
    };
    if (items == null) {
      final error = list.error;
      return [
        SliverToBoxAdapter(
          child: error != null
              ? _ErrorBanner(error: error, onRetry: _refresh)
              : const Padding(
                  padding: EdgeInsets.all(DelveTokens.space8),
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      ];
    }
    if (items.isEmpty) {
      return [
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
    final rows = <Widget>[];
    String? day;
    for (final (n, item) in items.indexed) {
      if (key.topic != null) {
        final d = _dayLabel(l, item.at, now);
        if (d != day) {
          day = d;
          rows.add(_DayHeader(label: d));
        }
      }
      rows.add(
        NewsStoryRow(
          item: item,
          now: now,
          showTopic: key.topic == null,
          divider: n < items.length - 1,
          onLongPress: (ctx, i) => showNewsMenu(ctx, ref, i),
        ),
      );
    }
    return [
      if (status != null) SliverToBoxAdapter(child: _status(context, status)),
      SliverList.list(children: rows),
      if (list.next != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(DelveTokens.space2),
            child: Center(
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
    if (days <= 0) return l.newsToday;
    if (days == 1) return l.newsYesterday;
    return DateFormat('EEE d MMM').format(a);
  }
}

/// All · Saved · the topics (Saved second, so it is never off-screen).
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
    final chips = <(NewsFilter, String, IconData?, String)>[
      if (filter is NewsFilterWeekly)
        (
          const NewsFilterWeekly(),
          l.newsLastWeek,
          NewsIcons.lastWeek,
          'weekly',
        ),
      (const NewsFilterAll(), l.newsAll, null, 'all'),
      (const NewsFilterSaved(), l.newsSaved, NewsIcons.saved, 'saved'),
      for (final s in sections)
        (NewsFilterTopic(s.topic), s.name, null, s.topic),
    ];
    bool on(NewsFilter f) => switch ((f, filter)) {
      (NewsFilterAll(), NewsFilterAll()) => true,
      (NewsFilterSaved(), NewsFilterSaved()) => true,
      (NewsFilterWeekly(), NewsFilterWeekly()) => true,
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
          for (final (n, (f, label, icon, id)) in chips.indexed) ...[
            if (n > 0) const SizedBox(width: DelveTokens.space2),
            Center(
              child: DelveFilterChip(
                key: Key('news.chip.$id'),
                selected: on(f),
                icon: icon,
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

/// A topic's header in All: name, “14 stories · 5 new” (7 days · unread
/// today).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});
  final NewsSection section;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      key: Key('news.section.${section.topic}'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        DelveTokens.space3,
        DelveTokens.space4,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(section.name, style: context.text.titleMedium)),
          Text(
            l.newsSectionCounts(section.week, section.fresh),
            style: context.text.labelMedium!.copyWith(
              color: context.delve.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// “Show all N”: neutral row (design 26-0), opens the topic.
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
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          0,
          DelveTokens.space2,
          0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.newsShowAll(count),
                style: context.text.labelLarge!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
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
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      14,
      DelveTokens.space4,
      2,
    ),
    child: Text(
      label.toUpperCase(),
      style: context.text.labelSmall!.copyWith(color: context.delve.textMuted),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

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
