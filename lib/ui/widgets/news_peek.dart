import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../app/news.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import 'news_ui.dart';
import 'page_scaffolds.dart';

/// What the long-press card of a story offers (N4a): the row's actions
/// under the summary, and [open] for a tap on its head.
enum NewsAction { open, more, less, hide, save, copy }

/// The phone's long press on a story (N4a, the News page and the Dashboard
/// block): a small window by the row with the Hungarian AI summary - or
/// where its text and summary are, with Fetch text - and the row's actions
/// under it. Nothing in it marks the story read; a tap on its head opens
/// the reading view (which does). Returns the chosen action.
Future<NewsAction?> showNewsPeek(BuildContext context, NewsItem item) {
  // over the bottom bar too: the root navigator's overlay
  final navigator = Navigator.of(context, rootNavigator: true);
  final box = context.findRenderObject() as RenderBox?;
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final anchor = box == null
      ? Rect.fromLTWH(0, overlay.size.height / 3, overlay.size.width, 0)
      : MatrixUtils.transformRect(
          box.getTransformTo(overlay),
          Offset.zero & box.size,
        );
  return navigator.push(
    _PeekRoute(
      anchor: anchor,
      item: item,
      barrierColor: context.delve.scrim,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    ),
  );
}

class _PeekRoute extends PopupRoute<NewsAction> {
  _PeekRoute({
    required this.anchor,
    required this.item,
    required this.barrierColor,
    required this.barrierLabel,
    required this.themes,
  });

  final Rect anchor;
  final NewsItem item;
  final CapturedThemes themes;

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => DelveTokens.short;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final padding = MediaQuery.paddingOf(context);
    return themes.wrap(
      CustomSingleChildLayout(
        delegate: _PeekLayout(anchor: anchor, padding: padding),
        child: NewsPeek(item: item),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: DelveTokens.shortCurve),
    child: child,
  );
}

/// Under the row when it fits, else over it, else as far up as it must:
/// the page's width less the margins (at most [maxWidth]).
class _PeekLayout extends SingleChildLayoutDelegate {
  _PeekLayout({required this.anchor, required this.padding});

  final Rect anchor;
  final EdgeInsets padding;

  static const double margin = DelveTokens.space4;
  static const double gap = DelveTokens.space1;
  static const double maxWidth = 560;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(maxWidth, constraints.maxWidth - 2 * margin);
    final height =
        constraints.maxHeight - padding.top - padding.bottom - 2 * margin;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.max(0, height),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (size.width - childSize.width) / 2;
    final top = padding.top + margin;
    final bottom = size.height - padding.bottom - margin;
    final below = anchor.bottom + gap;
    final above = anchor.top - gap - childSize.height;
    final y = below + childSize.height <= bottom
        ? below
        : above >= top
        ? above
        : math.max(top, bottom - childSize.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PeekLayout old) =>
      old.anchor != anchor || old.padding != padding;
}

/// The card itself: the story's head, its summary or the state of its text,
/// then the actions. It follows the story as the server answers (a Fetch
/// text, the summary the model writes later) without marking it read.
class NewsPeek extends ConsumerStatefulWidget {
  const NewsPeek({super.key, required this.item});

  final NewsItem item;

  @override
  ConsumerState<NewsPeek> createState() => _NewsPeekState();
}

class _NewsPeekState extends ConsumerState<NewsPeek> {
  Object? _error;

  NewsStoryController get _story =>
      ref.read(newsStoryProvider(widget.item.id).notifier);

  @override
  void initState() {
    super.initState();
    // a text or a summary is on its way: the story's controller reloads it
    // (unread) when the server says something new came
    if (_waiting(widget.item)) {
      unawaited(_quietly(() => _story.load(read: false)));
    }
  }

  static bool _waiting(NewsItem i) =>
      i.textState == 'queued' || (i.textState == 'ok' && i.summaryHu == null);

  static Future<void> _quietly(Future<void> Function() f) async {
    try {
      await f();
    } on Object {
      // the card shows what the list had
    }
  }

  Future<void> _fetch() async {
    setState(() => _error = null);
    try {
      if (ref.read(newsStoryProvider(widget.item.id)).story == null) {
        await _story.load(read: false);
      }
      await _story.fetchText();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = ref.watch(newsProvider.select((v) => v.current(widget.item)));
    final fetching = ref.watch(
      newsStoryProvider(widget.item.id).select((s) => s.fetching),
    );
    final menu = context.theme.popupMenuTheme;
    final muted = context.delve.textMuted;
    final style = TopicStyle.of(i.topic);
    final now = DateTime.now();
    final hideable = i.source != null && !i.gn;
    final meta = [?i.publisher, newsAge(i.at, now)].join(' · ');

    Widget action(
      NewsAction a,
      IconData icon,
      String label, {
      bool filled = false,
    }) => InkWell(
      key: Key('news.menu.${a.name}'),
      onTap: () => Navigator.of(context).pop(a),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
          child: Row(
            children: [
              SymbolIcon(
                icon,
                size: DelveTokens.iconMd,
                filled: filled,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: DelveTokens.space3),
              Expanded(child: Text(label, style: context.text.bodyMedium)),
            ],
          ),
        ),
      ),
    );

    final head = InkWell(
      key: const Key('news.peek.open'),
      onTap: () => Navigator.of(context).pop(NewsAction.open),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          DelveTokens.space4,
          DelveTokens.space4,
          DelveTokens.space3,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopicEdge(color: style.color),
              const SizedBox(width: DelveTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: DelveTokens.space2,
                      runSpacing: DelveTokens.space1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: newsTags(context, i, read: i.read),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      i.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: DelveTokens.space1),
                    Text(
                      meta,
                      style: context.text.labelMedium!.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      key: const Key('news.peek'),
      type: MaterialType.card,
      color: menu.color ?? context.colors.surfaceContainerHigh,
      shape:
          menu.shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DelveTokens.rlg),
          ),
      elevation: menu.elevation ?? 3,
      shadowColor: menu.shadowColor,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            if (!i.isRelease)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DelveTokens.space4,
                  0,
                  DelveTokens.space4,
                  DelveTokens.space4,
                ),
                child: _PeekSummary(
                  item: i,
                  fetching: fetching,
                  error: _error,
                  onFetch: () => unawaited(_fetch()),
                ),
              ),
            Divider(height: 1, color: context.colors.outlineVariant),
            const SizedBox(height: DelveTokens.space1),
            action(
              NewsAction.more,
              NewsIcons.more,
              l.newsMoreLikeThis,
              filled: i.feedback == 'more',
            ),
            action(
              NewsAction.less,
              NewsIcons.less,
              l.newsLessLikeThis,
              filled: i.feedback == 'less',
            ),
            if (hideable)
              action(
                NewsAction.hide,
                NewsIcons.hide,
                l.newsHideSource(i.publisher ?? i.source!),
              ),
            action(
              NewsAction.save,
              NewsIcons.saved,
              i.saved ? l.newsRemoveFromSaved : l.newsSave,
              filled: i.saved,
            ),
            action(NewsAction.copy, NewsIcons.copyLink, l.newsCopyLink),
            const SizedBox(height: DelveTokens.space1),
          ],
        ),
      ),
    );
  }
}

/// The summary between two hairlines (as in the reading view), or what is
/// happening to the story's text: nothing asked yet (Fetch text), on its
/// way, here but not summarised yet, or no text came (Try again).
class _PeekSummary extends StatelessWidget {
  const _PeekSummary({
    required this.item,
    required this.fetching,
    required this.error,
    required this.onFetch,
  });

  final NewsItem item;
  final bool fetching;
  final Object? error;
  final VoidCallback onFetch;

  static const double maxSummaryHeight = 240;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = context.delve.textMuted;
    final small = context.text.bodySmall!.copyWith(color: muted);
    final rule = BorderSide(color: context.colors.outlineVariant);
    final summary = item.summaryHu;
    if (summary != null) {
      final excerpt = item.summaryBasis == 'excerpt';
      return Container(
        key: const Key('news.peek.summary'),
        padding: const EdgeInsets.symmetric(vertical: DelveTokens.space3),
        decoration: BoxDecoration(
          border: Border(top: rule, bottom: rule),
        ),
        child: Column(
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
                Flexible(
                  child: Text(
                    excerpt
                        ? '${l.newsAiSummary} · ${l.newsFromExcerpt}'
                        : l.newsAiSummary,
                    key: const Key('news.peek.summary.label'),
                    style: DelveText.monoSmall.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DelveTokens.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: maxSummaryHeight),
              child: SingleChildScrollView(
                child: Text(
                  summary,
                  key: const Key('news.peek.summary.text'),
                  style: context.text.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final state = fetching ? 'queued' : item.textState;
    Widget fetchButton(IconData icon, String label) => Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          key: const Key('news.peek.fetch'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: fetching ? null : onFetch,
          icon: SymbolIcon(icon, size: 18),
          label: Text(label),
        ),
      ),
    );
    final (
      IconData icon,
      String line,
      String? sub,
      Widget? button,
    ) = switch (state) {
      'queued' => (
        NewsIcons.queued,
        l.newsPeekFetching,
        l.newsSummaryPending,
        null,
      ),
      'ok' => (NewsIcons.summaryPending, l.newsSummaryPending, null, null),
      'failed' => (
        NewsIcons.fetchText,
        l.newsNoText,
        null,
        fetchButton(NewsIcons.tryAgain, l.newsTryAgain),
      ),
      _ => (
        NewsIcons.ai,
        l.newsPeekNoSummary,
        l.newsTeaserOnlySub,
        fetchButton(NewsIcons.fetchText, l.newsFetchText),
      ),
    };
    final err = error;
    return Container(
      key: Key('news.peek.state.${state ?? 'none'}'),
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space3),
      decoration: BoxDecoration(
        border: Border(top: rule, bottom: rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SymbolIcon(icon, size: DelveTokens.iconSm, color: muted),
              const SizedBox(width: DelveTokens.space2),
              Expanded(child: Text(line, style: context.text.bodyMedium)),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: DelveTokens.space1),
            Text(sub, style: small),
          ],
          if (err != null) ...[
            const SizedBox(height: DelveTokens.space1),
            Text(
              l.newsActionFailed(apiErrorText(l, err)),
              key: const Key('news.peek.error'),
              style: small.copyWith(color: context.colors.error),
            ),
          ],
          ?button,
        ],
      ),
    );
  }
}
