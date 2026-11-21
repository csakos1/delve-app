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
import '../desktop/panes.dart';
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
/// marks the story read. The desktop's Inbox (L2e) shows the same view
/// under its own header ([title], [headerActions]) and counts a story as
/// read only once it was on screen for [readAfter].
class NewsStoryScreen extends ConsumerStatefulWidget {
  const NewsStoryScreen({
    super.key,
    required this.id,
    this.title,
    this.headerActions = const [],
    this.readAfter,
    this.beforeRead,
  });

  final int id;

  /// The desktop header's title (null: the topic's name).
  final String? title;

  /// The desktop header's buttons before the story's own.
  final List<Widget> headerActions;

  /// The story is marked read only after it was shown this long (null: when
  /// it opens).
  final Duration? readAfter;

  /// Runs right before that late mark (the Inbox clears its item first).
  final Future<void> Function()? beforeRead;

  @override
  ConsumerState<NewsStoryScreen> createState() => _NewsStoryScreenState();
}

class _NewsStoryScreenState extends ConsumerState<NewsStoryScreen> {
  /// Runs out when the story was shown for [NewsStoryScreen.readAfter].
  Timer? _shown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _shown?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final wait = widget.readAfter;
    try {
      await ref
          .read(newsStoryProvider(widget.id).notifier)
          .load(read: wait == null);
    } on Object {
      // shown from NewsStoryView.error
      return;
    }
    if (wait == null || !mounted) return;
    _shown?.cancel();
    _shown = Timer(wait, () => unawaited(_markShown()));
  }

  /// It was on screen long enough: read (after [NewsStoryScreen.beforeRead]).
  Future<void> _markShown() async {
    if (!mounted) return;
    final story = ref.read(newsStoryProvider(widget.id).notifier);
    try {
      await widget.beforeRead?.call();
      await story.markRead();
    } on Object {
      // it stays unread: the next opening tries again
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
    final desktop = DesktopLayout.of(context);
    final icon = desktop ? DelveDesktop.iconButtonIcon : 22.0;
    final actions = [
      if (item != null) ...[
        IconButton(
          key: const Key('news.story.open'),
          tooltip: l.newsOpenOriginal,
          onPressed: () => openLink(context, ref, item.originalUrl),
          icon: SymbolIcon(NewsIcons.openOriginal, size: icon),
        ),
        _Toggle(
          key: const Key('news.story.save'),
          on: item.saved,
          icon: NewsIcons.saved,
          size: icon,
          tooltip: item.saved ? l.newsRemoveFromSaved : l.newsSave,
          onPressed: () => _act(
            () => ctl.setSaved(!item.saved),
            item.saved ? l.newsRemovedFromSaved : l.newsSavedSnack,
          ),
        ),
        if (!desktop) const SizedBox(width: DelveTokens.space1),
      ],
    ];
    // the desktop (27W-5a): the reading column under a 48 px header; with
    // the inspector docked, sources, Open original and the feedback are
    // there instead of at the end of the column
    final docked =
        desktop &&
        (PaneScope.maybeOf(context)?.placement.inspectorDocked ?? false);
    final Widget content = switch (story) {
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
        inInspector: docked,
        onFetch: () => _act(ctl.fetchText),
        onFeedback: (f) => _act(() => ctl.setFeedback(f)),
        onHide: () => _hide(s.item),
      ),
    };
    if (desktop) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaneHeader(
              title:
                  widget.title ??
                  (item == null
                      ? ''
                      : ref.watch(newsProvider).topicName(item.topic)),
              actions: [...widget.headerActions, ...actions],
              inspectorToggle: true,
            ),
            Expanded(child: ReadingColumn(child: content)),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: PageColourBar(title: '', actions: actions),
      body: UnderBarFade(child: content),
    );
  }

  Future<void> _hide(NewsItem item) => hideNewsSource(context, ref, item);
}

/// Hides [item]'s feed, with Undo in the snackbar (the reading view and the
/// desktop's Story inspector).
Future<void> hideNewsSource(
  BuildContext context,
  WidgetRef ref,
  NewsItem item,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final news = ref.read(newsProvider.notifier);
  final source = item.source!;
  final name = item.publisher ?? source;
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
    await news.setSource(source, enabled: false);
    say(
      l.newsSourceHidden(name),
      undo: () => unawaited(news.setSource(source, enabled: true)),
    );
  } on Object catch (e) {
    say(l.newsActionFailed(apiErrorText(l, e)));
  }
}

/// The desktop's Story inspector (27W-5a): the topic with Open topic, the
/// sources, Open original and the feedback – what the phone has at the end
/// of the reading view.
class NewsStoryInspector extends ConsumerWidget {
  const NewsStoryInspector({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final story = ref.watch(newsStoryProvider(id)).story;
    final ctl = ref.read(newsStoryProvider(id).notifier);
    final messenger = ScaffoldMessenger.of(context);
    Future<void> feedback(String f) async {
      try {
        await ctl.setFeedback(f);
      } on Object catch (e) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l.newsActionFailed(apiErrorText(l, e)))),
          );
      }
    }

    return InspectorFrame(
      key: const Key('inspector.story'),
      label: l.newsStoryTab,
      child: switch (story) {
        null => const SizedBox.shrink(),
        final NewsStory s => ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          children: [
            if (s.item.topic case final topic?) ...[
              _InspectorTopic(topic: topic),
              const SizedBox(height: DelveTokens.space3),
            ],
            if (s.others.isNotEmpty) _Sources(story: s, now: DateTime.now()),
            const SizedBox(height: DelveTokens.space4),
            _OpenOriginal(item: s.item),
            const SizedBox(height: DelveTokens.space4),
            _Feedback(
              item: s.item,
              onFeedback: (f) => unawaited(feedback(f)),
              onHide: () => unawaited(hideNewsSource(context, ref, s.item)),
            ),
          ],
        ),
      },
    );
  }
}

/// The inspector's topic: the tile, the name in the topic colour, Open
/// topic (the list column shows the topic).
class _InspectorTopic extends ConsumerWidget {
  const _InspectorTopic({required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final style = TopicStyle.of(topic);
    return Row(
      key: const Key('news.inspector.topic'),
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: style.tile,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: SymbolIcon(style.glyph, size: 20, color: style.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            ref.watch(newsProvider).topicName(topic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall!.copyWith(color: style.color),
          ),
        ),
        TextButton(
          key: const Key('news.inspector.openTopic'),
          onPressed: () => context.open(Routes.newsTopic(topic)),
          child: Text(l.newsOpenTopic),
        ),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({
    required this.story,
    required this.fetching,
    required this.onFetch,
    required this.onFeedback,
    required this.onHide,
    this.inInspector = false,
  });

  final NewsStory story;
  final bool fetching;

  /// The desktop's docked inspector shows the sources, Open original and
  /// the feedback: the column ends with the text.
  final bool inInspector;
  final VoidCallback onFetch;
  final ValueChanged<String> onFeedback;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = story.item;
    final now = DateTime.now();
    final text = story.text;
    final tags = newsTags(context, i, topic: false);
    final why = i.why;
    final summaryBlock = !i.isRelease && (i.summaryHu != null || text != null);
    return ListView(
      key: const Key('news.story'),
      padding: EdgeInsets.fromLTRB(
        DelveTokens.space5,
        DesktopLayout.of(context)
            ? DelveDesktop.contentGutter
            : UnderBarFade.height + 6,
        DelveTokens.space5,
        28,
      ),
      children: [
        Wrap(
          spacing: DelveTokens.space2,
          runSpacing: DelveTokens.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TopicPill(topic: i.topic),
            ...tags,
          ],
        ),
        const SizedBox(height: DelveTokens.space3),
        SelectableText(
          i.title,
          key: const Key('news.story.title'),
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: DelveTokens.space3),
        Text(
          key: const Key('news.story.byline'),
          [
            ?i.publisher,
            newsAge(i.at, now),
            if (i.sources > 1)
              l.newsSources(i.sources)
            else
              newsHost(i.originalUrl),
          ].join(' · '),
          style: context.text.labelMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (why != null && why.trim().isNotEmpty) ...[
          const SizedBox(height: DelveTokens.space4),
          _WhyQuote(topic: i.topic, why: why),
        ],
        if (summaryBlock) ...[
          const SizedBox(height: 18),
          _AiSummary(summary: i.summaryHu),
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
        if (!inInspector) ...[
          if (story.others.isNotEmpty) _Sources(story: story, now: now),
          const SizedBox(height: DelveTokens.space5),
          _OpenOriginal(item: i),
          const SizedBox(height: DelveTokens.space5),
          _Feedback(item: i, onFeedback: onFeedback, onHide: onHide),
        ],
      ],
    );
  }
}

/// The topic pill: glyph + small caps in the topic colour on its tile tint.
class _TopicPill extends ConsumerWidget {
  const _TopicPill({required this.topic});
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = TopicStyle.of(topic);
    final name = ref.watch(newsProvider.select((v) => v.topicName(topic)));
    return Container(
      key: const Key('news.story.topic'),
      height: 24,
      padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
      decoration: BoxDecoration(
        color: s.tile,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(s.glyph, size: 14, color: s.color),
          const SizedBox(width: 5),
          Text(
            name.toUpperCase(),
            style: context.text.labelSmall!.copyWith(
              color: s.color,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

/// The why as a quote on the topic's edge.
class _WhyQuote extends StatelessWidget {
  const _WhyQuote({required this.topic, required this.why});
  final String? topic;
  final String why;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IntrinsicHeight(
      key: const Key('news.story.why'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopicEdge(color: TopicStyle.of(topic).color),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.newsWhy.toUpperCase(),
                    style: context.text.labelSmall!.copyWith(
                      color: context.delve.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    why,
                    style: context.text.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// “AI summary” between two hairlines; with the text there but no summary
/// yet, the pending line.
class _AiSummary extends StatelessWidget {
  const _AiSummary({required this.summary});
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = context.delve.textMuted;
    final rule = BorderSide(color: context.colors.outlineVariant);
    final s = summary;
    return Container(
      key: const Key('news.story.ai'),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: rule, bottom: rule),
      ),
      child: s == null
          ? Row(
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
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SymbolIcon(
                      NewsIcons.ai,
                      size: DelveTokens.iconSm,
                      color: muted,
                    ),
                    const SizedBox(width: DelveTokens.space1),
                    Text(
                      l.newsAiSummary,
                      style: DelveText.monoSmall.copyWith(color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: DelveTokens.space2),
                SelectableText(s, style: _reading(context)),
                const SizedBox(height: DelveTokens.space2),
                Text(
                  l.newsAiDisclaimer,
                  style: context.text.bodySmall!.copyWith(color: muted),
                ),
              ],
            ),
    );
  }
}

/// The sources of a merged story, after the text: the lead (whose text
/// this is) first, at most 5 rows before “Show all N”.
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
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.newsSources(rows.length).toUpperCase(),
            style: context.text.labelSmall!.copyWith(color: muted),
          ),
          const SizedBox(height: DelveTokens.space2),
          DecoratedBox(
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
      'queued' when story.textNow => [
        StatusText(
          kind: StatusKind.info,
          icon: NewsIcons.fetchText,
          label: l.newsFetchingWord,
        ),
        const SizedBox(height: DelveTokens.space2),
        Text(l.newsFetchingNow, style: context.text.bodyMedium),
        Text(l.newsFetchingNowSub, style: small),
      ],
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
      padding: const EdgeInsets.only(top: 22),
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
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
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
          style: FilledButton.styleFrom(
            minimumSize: Size(0, DesktopLayout.of(context) ? 36 : 48),
          ),
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
