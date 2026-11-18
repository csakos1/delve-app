import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/news.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../links.dart';
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// Article text and the summary: bodyLarge with line height 24 (design 26,
/// the round's one new measure).
TextStyle _reading(BuildContext context) =>
    context.text.bodyLarge!.copyWith(height: 24 / 15);

/// 26d Reading view: eyebrow, title, the sources, the “AI summary” well
/// with the why, the article text (or what became of it: Fetch text,
/// queued, failed + Try again; a day of releases lists its tags), Open
/// original and the small feedback icons. Save is in the top bar. Opening
/// marks the story read.
class NewsStoryScreen extends ConsumerStatefulWidget {
  const NewsStoryScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<NewsStoryScreen> createState() => _NewsStoryScreenState();
}

class _NewsStoryScreenState extends ConsumerState<NewsStoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  Future<void> _load() async {
    try {
      await ref.read(newsStoryProvider(widget.id).notifier).load();
    } on Object {
      // shown from NewsStoryView.error
    }
  }

  void _say(String text, {VoidCallback? undo}) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: undo == null
              ? null
              : SnackBarAction(label: l.newsUndo, onPressed: undo),
        ),
      );
  }

  Future<void> _act(Future<void> Function() action, [String? done]) async {
    final l = AppLocalizations.of(context);
    try {
      await action();
      if (done != null && mounted) _say(done);
    } on Object catch (e) {
      if (mounted) _say(l.newsActionFailed(apiErrorText(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(newsStoryProvider(widget.id));
    final story = view.story;
    final ctl = ref.read(newsStoryProvider(widget.id).notifier);
    final item = story?.item;
    return Scaffold(
      appBar: PageColourBar(
        title: '',
        actions: [
          if (item != null) ...[
            IconButton(
              key: const Key('news.story.open'),
              tooltip: l.newsOpenOriginal,
              onPressed: () => openLink(context, ref, item.originalUrl),
              icon: const SymbolIcon(NewsIcons.openOriginal, size: 22),
            ),
            _Toggle(
              key: const Key('news.story.save'),
              on: item.saved,
              icon: NewsIcons.saved,
              size: 22,
              tooltip: item.saved ? l.newsRemoveFromSaved : l.newsSave,
              onPressed: () => _act(
                () => ctl.setSaved(!item.saved),
                item.saved ? l.newsRemovedFromSaved : l.newsSavedSnack,
              ),
            ),
            const SizedBox(width: DelveTokens.space1),
          ],
        ],
      ),
      body: UnderBarFade(
        child: switch (story) {
          null when view.error != null => Padding(
            padding: const EdgeInsets.all(DelveTokens.space4),
            child: Align(
              alignment: Alignment.topCenter,
              child: StatusBanner(
                kind: StatusKind.alert,
                icon: DelveIcons.error,
                text: l.newsStoryFailed(apiErrorText(l, view.error!)),
                actionLabel: l.retry,
                onAction: () => unawaited(_load()),
              ),
            ),
          ),
          null => const Center(child: CircularProgressIndicator()),
          final NewsStory s => _Story(
            story: s,
            fetching: view.fetching,
            onFetch: () => _act(ctl.fetchText),
            onFeedback: (f) => _act(() => ctl.setFeedback(f)),
            onHide: () => _hide(s.item),
          ),
        },
      ),
    );
  }

  Future<void> _hide(NewsItem item) async {
    final l = AppLocalizations.of(context);
    final news = ref.read(newsProvider.notifier);
    final source = item.source!;
    final name = item.publisher ?? source;
    try {
      await news.setSource(source, enabled: false);
      if (!mounted) return;
      _say(
        l.newsSourceHidden(name),
        undo: () => unawaited(news.setSource(source, enabled: true)),
      );
    } on Object catch (e) {
      if (mounted) _say(l.newsActionFailed(apiErrorText(l, e)));
    }
  }
}

class _Story extends StatelessWidget {
  const _Story({
    required this.story,
    required this.fetching,
    required this.onFetch,
    required this.onFeedback,
    required this.onHide,
  });

  final NewsStory story;
  final bool fetching;
  final VoidCallback onFetch;
  final ValueChanged<String> onFeedback;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final i = story.item;
    final now = DateTime.now();
    final text = story.text;
    return ListView(
      key: const Key('news.story'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space5,
        UnderBarFade.height + 6,
        DelveTokens.space5,
        28,
      ),
      children: [
        _Eyebrow(item: i),
        const SizedBox(height: 6),
        SelectableText(
          i.title,
          key: const Key('news.story.title'),
          style: context.text.headlineSmall,
        ),
        _Sources(story: story, now: now),
        if (i.why != null || i.summaryHu != null) ...[
          const SizedBox(height: DelveTokens.space4),
          _AiWell(item: i, hasText: text != null),
        ],
        if (i.isRelease)
          _Releases(item: i, now: now)
        else if (text != null) ...[
          const SizedBox(height: DelveTokens.space5),
          _Article(text: text, at: story.textAt, now: now),
        ] else ...[
          if (i.excerpt case final e? when e.trim().isNotEmpty)
            _Excerpt(text: e),
          _TextState(story: story, fetching: fetching, onFetch: onFetch),
        ],
        const SizedBox(height: DelveTokens.space5),
        _OpenOriginal(item: i),
        const SizedBox(height: DelveTokens.space5),
        _Feedback(item: i, onFeedback: onFeedback, onHide: onHide),
      ],
    );
  }
}

class _Eyebrow extends ConsumerWidget {
  const _Eyebrow({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final topic = ref.watch(
      newsProvider.select((v) => v.topicName(item.topic)),
    );
    final parts = [
      if (topic.isNotEmpty) topic,
      if (item.mustRead) l.newsMustRead,
      if (item.touchesSetup) l.newsYourSetup,
      if (item.isRelease) l.newsReleases,
    ];
    return Text(
      parts.join(' · '),
      style: context.text.labelMedium!.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

/// One source: a line under the title; a merged story: an outlined group,
/// the lead (whose text this is) first, at most 5 rows before “Show all N”.
class _Sources extends ConsumerStatefulWidget {
  const _Sources({required this.story, required this.now});
  final NewsStory story;
  final DateTime now;

  @override
  ConsumerState<_Sources> createState() => _SourcesState();
}

class _SourcesState extends ConsumerState<_Sources> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.story;
    final i = s.item;
    final muted = context.delve.textMuted;
    String stamp(DateTime? at) => at == null
        ? ''
        : '${newsAge(at, widget.now)} · ${DateFormat('HH:mm').format(at.toLocal())}';
    if (s.others.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: DelveTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                ?i.publisher,
                stamp(i.at),
              ].where((p) => p.isNotEmpty).join(' · '),
              style: context.text.labelMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            Text(
              newsHost(i.originalUrl),
              style: DelveText.monoSmall.copyWith(color: muted),
            ),
          ],
        ),
      );
    }
    final rows = <(String, DateTime?, String, bool)>[
      (
        i.publisher ?? newsHost(i.originalUrl),
        i.at,
        i.originalUrl,
        s.text != null,
      ),
      for (final o in s.others)
        (o.publisher ?? newsHost(o.url), o.publishedAt, o.url, false),
    ];
    final cut = !_all && rows.length > 5;
    final shown = cut ? rows.take(4).toList() : rows;
    final rule = BorderSide(color: context.colors.outlineVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DecoratedBox(
        key: const Key('news.story.sources'),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
        ),
        child: Column(
          children: [
            for (final (n, (name, at, url, lead)) in shown.indexed)
              InkWell(
                onTap: () => openLink(context, ref, url),
                onLongPress: () => copyLink(context, url),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
                  decoration: BoxDecoration(
                    border: n == 0 ? null : Border(top: rule),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: name,
                                style: context.text.bodyMedium,
                              ),
                              if (lead)
                                TextSpan(
                                  text: '  ${l.newsTextFromHere}',
                                  style: context.text.labelSmall!.copyWith(
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        stamp(at),
                        style: context.text.labelMedium!.copyWith(color: muted),
                      ),
                      SizedBox(
                        width: 40,
                        child: SymbolIcon(
                          NewsIcons.openOriginal,
                          size: 18,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (cut)
              InkWell(
                key: const Key('news.story.sourcesAll'),
                onTap: () => setState(() => _all = true),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  decoration: BoxDecoration(border: Border(top: rule)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.newsShowAll(rows.length),
                          style: context.text.labelLarge!.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SymbolIcon(
                        NewsIcons.expand,
                        size: DelveTokens.iconMd,
                        color: context.colors.onSurfaceVariant,
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

/// The “AI summary” well: summary, Why, the disclaimer; “AI note” with the
/// why alone while there is no summary.
class _AiWell extends StatelessWidget {
  const _AiWell({required this.item, required this.hasText});
  final NewsItem item;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = context.delve.textMuted;
    final summary = item.summaryHu;
    final why = item.why;
    return Container(
      key: const Key('news.story.ai'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DelveTokens.rlg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SymbolIcon(NewsIcons.ai, size: DelveTokens.iconSm, color: muted),
              const SizedBox(width: DelveTokens.space1),
              Text(
                summary != null ? l.newsAiSummary : l.newsAiNote,
                style: DelveText.monoSmall.copyWith(color: muted),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: DelveTokens.space2),
            SelectableText(summary, style: _reading(context)),
          ],
          if (why != null) ...[
            if (summary != null) ...[
              const SizedBox(height: DelveTokens.space3),
              Divider(height: 1, color: context.colors.outlineVariant),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: DelveTokens.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l.newsWhy,
                  style: context.text.labelMedium!.copyWith(color: muted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    why,
                    style: context.text.bodyMedium!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (summary != null) ...[
            const SizedBox(height: DelveTokens.space2),
            Text(
              l.newsAiDisclaimer,
              style: context.text.bodySmall!.copyWith(color: muted),
            ),
          ] else if (hasText && !item.isRelease) ...[
            const SizedBox(height: DelveTokens.space2),
            Row(
              children: [
                SymbolIcon(NewsIcons.summaryPending, size: 14, color: muted),
                const SizedBox(width: DelveTokens.space1),
                Expanded(
                  child: Text(
                    l.newsSummaryPending,
                    style: context.text.bodySmall!.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The article: paragraphs (blank-line separated), 12 dp apart; at the end
/// the size and when the text came.
class _Article extends StatelessWidget {
  const _Article({required this.text, required this.at, required this.now});
  final String text;
  final DateTime? at;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final paragraphs = [
      for (final p in text.split(RegExp(r'\n\s*\n')))
        if (p.trim().isNotEmpty) p.trim(),
    ];
    final style = _reading(context);
    final fetched = at;
    return SelectionArea(
      child: Column(
        key: const Key('news.story.text'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (n, p) in paragraphs.indexed) ...[
            if (n > 0) const SizedBox(height: DelveTokens.space3),
            Text(p, style: style),
          ],
          const SizedBox(height: DelveTokens.space4),
          Text(
            fetched == null
                ? l.newsTextSize(tokenCount(text.length))
                : l.newsTextSizeAt(
                    tokenCount(text.length),
                    clockTime(fetched, now),
                  ),
            style: DelveText.monoSmall.copyWith(color: context.delve.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Excerpt extends StatelessWidget {
  const _Excerpt({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.newsFromTheFeed.toUpperCase(),
            style: context.text.labelSmall!.copyWith(
              color: context.delve.textMuted,
            ),
          ),
          const SizedBox(height: DelveTokens.space1),
          SelectableText(
            text,
            style: _reading(
              context,
            ).copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Where the text would be when there is none: not asked for (Fetch
/// text), queued (no spinner), or failed with the reason (Try again).
class _TextState extends StatelessWidget {
  const _TextState({
    required this.story,
    required this.fetching,
    required this.onFetch,
  });

  final NewsStory story;
  final bool fetching;
  final VoidCallback onFetch;

  static String reason(AppLocalizations l, String? code) => switch (code) {
    'robots' => l.newsReasonRobots,
    'no_text' => l.newsReasonNoText,
    'unresolved' => l.newsReasonUnresolved,
    'timeout' => l.newsReasonTimeout,
    final String c when c.startsWith('http_') => l.newsReasonHttp(
      c.substring(5),
    ),
    final String c => l.newsReasonOther(c),
    null => l.newsReasonOther('—'),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = story.item;
    final muted = context.delve.textMuted;
    final small = context.text.bodySmall!.copyWith(color: muted);
    Widget button(IconData icon, String label) => Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          key: const Key('news.story.fetch'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: fetching ? null : onFetch,
          icon: SymbolIcon(icon, size: 18),
          label: Text(label),
        ),
      ),
    );
    final children = switch (i.textState) {
      'queued' => [
        StatusText(
          kind: StatusKind.info,
          icon: NewsIcons.queued,
          label: l.newsQueuedWord,
        ),
        const SizedBox(height: DelveTokens.space2),
        Text(l.newsQueued, style: context.text.bodyMedium),
        Text(l.newsQueuedSub, style: small),
      ],
      'failed' => [
        Text(l.newsNoText, style: context.text.bodyMedium),
        Text(reason(l, story.textError), style: small),
        button(NewsIcons.tryAgain, l.newsTryAgain),
      ],
      _ => [
        Text(l.newsTeaserOnly, style: context.text.bodyMedium),
        Text(l.newsTeaserOnlySub, style: small),
        button(NewsIcons.fetchText, l.newsFetchText),
      ],
    };
    return Container(
      key: Key('news.story.state.${i.textState ?? 'none'}'),
      margin: const EdgeInsets.only(top: DelveTokens.space5),
      padding: const EdgeInsets.all(DelveTokens.space4),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outlineVariant),
        borderRadius: BorderRadius.circular(DelveTokens.rlg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// A day of releases: its tags with time and link (design 26d5).
class _Releases extends ConsumerWidget {
  const _Releases({required this.item, required this.now});
  final NewsItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final releases = item.releases ?? const <NewsRelease>[];
    final muted = context.delve.textMuted;
    final rule = BorderSide(color: context.colors.outlineVariant);
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.newsReleasesToday(releases.length).toUpperCase(),
            style: context.text.labelSmall!.copyWith(color: muted),
          ),
          const SizedBox(height: DelveTokens.space2),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.outlineVariant),
              borderRadius: BorderRadius.circular(DelveTokens.rmd),
            ),
            child: Column(
              children: [
                for (final (n, r) in releases.indexed)
                  InkWell(
                    key: Key('news.release.${r.tag}'),
                    onTap: () => openLink(context, ref, r.url),
                    onLongPress: () => copyLink(context, r.url),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                      decoration: BoxDecoration(
                        border: n == 0 ? null : Border(top: rule),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(r.tag, style: DelveText.mono)),
                          if (r.publishedAt case final at?)
                            Text(
                              listTime(at, now),
                              style: context.text.labelMedium!.copyWith(
                                color: muted,
                              ),
                            ),
                          SizedBox(
                            width: 40,
                            child: SymbolIcon(
                              NewsIcons.openOriginal,
                              size: 18,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: DelveTokens.space2),
          Text(
            l.newsReleasesNote,
            style: context.text.bodySmall!.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _OpenOriginal extends ConsumerWidget {
  const _OpenOriginal({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          key: const Key('news.story.original'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => openLink(context, ref, item.originalUrl),
          icon: const SymbolIcon(NewsIcons.openOriginal, size: 20),
          label: Text(item.isRelease ? l.newsOpenReleases : l.newsOpenOriginal),
        ),
        const SizedBox(height: DelveTokens.space1),
        Text(
          l.newsOpensInBrowser(newsHost(item.originalUrl)),
          textAlign: TextAlign.center,
          style: DelveText.monoSmall.copyWith(color: context.delve.textMuted),
        ),
      ],
    );
  }
}

/// More / Less like this and Hide (the feed; not for a Google News search,
/// which carries many publishers), small at the end (design 26-0).
class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.item,
    required this.onFeedback,
    required this.onHide,
  });

  final NewsItem item;
  final ValueChanged<String> onFeedback;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final caption = switch (item.feedback) {
      'more' => l.newsMoreCaption,
      'less' => l.newsLessCaption,
      _ => l.newsTeach,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              caption,
              key: const Key('news.story.feedbackCaption'),
              style: context.text.labelMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ),
          _Toggle(
            key: const Key('news.story.more'),
            on: item.feedback == 'more',
            icon: NewsIcons.more,
            tooltip: l.newsMoreLikeThis,
            onPressed: () => onFeedback('more'),
          ),
          _Toggle(
            key: const Key('news.story.less'),
            on: item.feedback == 'less',
            icon: NewsIcons.less,
            tooltip: l.newsLessLikeThis,
            onPressed: () => onFeedback('less'),
          ),
          if (item.source != null && !item.gn)
            _Toggle(
              key: const Key('news.story.hide'),
              on: false,
              icon: NewsIcons.hide,
              tooltip: l.newsHideSource(item.publisher ?? item.source!),
              onPressed: onHide,
            ),
        ],
      ),
    );
  }
}

/// A small icon button; on = the filled glyph on a 40 dp primaryContainer
/// disc (the chips' “selected”).
class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.on,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 20,
  });

  final bool on;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return IconButton(
      tooltip: tooltip,
      isSelected: on,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        backgroundColor: on ? cs.primaryContainer : Colors.transparent,
      ),
      icon: SymbolIcon(
        icon,
        size: size,
        filled: on,
        color: on ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      ),
    );
  }
}
