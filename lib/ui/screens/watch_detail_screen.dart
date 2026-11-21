import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../app/layout.dart';
import '../../app/router.dart';
import '../../app/watches.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart';
import '../desktop/panes.dart' show InspectorFrame, InspectorTab;
import '../format.dart';
import '../links.dart';
import '../watch_text.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/watch_ui.dart';
import 'watches_screen.dart' show startWatchChat;

/// 21b Watch: its condition and filters, pause / resume / run now, change it
/// in a chat; the hits (newest first) and the rejected listings, collapsed.
/// On the desktop (27W-9a) the content of the Watches area: the same top,
/// then the listings in three tabs (Hits · Rejected · Waiting).
class WatchDetailScreen extends ConsumerStatefulWidget {
  const WatchDetailScreen({super.key, required this.slug, this.hit});

  final String slug;

  /// The desktop: the listing selected in the tabs (the Hit inspector
  /// shows it).
  final int? hit;

  @override
  ConsumerState<WatchDetailScreen> createState() => _WatchDetailScreenState();
}

class _WatchDetailScreenState extends ConsumerState<WatchDetailScreen> {
  bool _rejectedOpen = false;
  WatchAction? _busy;
  bool _loadingMore = false;

  /// The desktop's tab.
  WatchItemList _tab = WatchItemList.hits;

  @override
  void initState() {
    super.initState();
    // after the first frame: the refresh changes provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh({bool quiet = false}) async {
    final l = AppLocalizations.of(context);
    try {
      await Future.wait([
        ref.read(watchesProvider.notifier).refresh(),
        ref.read(watchItemsProvider(widget.slug).notifier).refresh(),
      ]);
    } on Object catch (e) {
      if (!quiet) _snack(l.watchesLoadFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _act(WatchAction action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = action);
    try {
      await ref.read(watchesProvider.notifier).act(widget.slug, action);
      if (action == WatchAction.run) _snack(l.watchRunStarted);
    } on Object catch (e) {
      _snack(l.watchActionFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _more({bool rejected = false, WatchItemList? list}) async {
    final l = AppLocalizations.of(context);
    setState(() => _loadingMore = true);
    try {
      await ref
          .read(watchItemsProvider(widget.slug).notifier)
          .loadMore(rejected: rejected, list: list);
    } on Object catch (e) {
      _snack(l.watchesLoadFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(watchesProvider);
    final w = view.bySlug(widget.slug);
    final items = ref.watch(watchItemsProvider(widget.slug));
    final now = DateTime.now();
    if (DesktopLayout.of(context)) {
      return _desktop(context, l, view, w, items, now);
    }
    final Widget body;
    if (w == null) {
      final error = view.error;
      body = view.items == null && error == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                UnderBarFade.height,
                DelveTokens.space4,
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  kind: error == null ? StatusKind.info : StatusKind.alert,
                  icon: error == null ? DelveIcons.info : DelveIcons.error,
                  text: error == null
                      ? l.watchGone
                      : l.watchesLoadFailed(apiErrorText(l, error)),
                  actionLabel: error == null ? null : l.retry,
                  onAction: error == null ? null : _refresh,
                ),
              ),
            );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: const Key('watch.detail'),
          padding: const EdgeInsets.only(
            top: UnderBarFade.height,
            bottom: DelveTokens.space8,
          ),
          children: [
            ..._header(l, w, now),
            ..._hits(l, w, items, now),
            ..._rejected(l, w, items, now),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: PageColourBar(title: w?.name ?? l.moreWatches),
      body: UnderBarFade(child: body),
    );
  }

  Future<void> _loadWaiting() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(watchItemsProvider(widget.slug).notifier).loadWaiting();
    } on Object catch (e) {
      _snack(l.watchesLoadFailed(apiErrorText(l, e)));
    }
  }

  void _selectTab(WatchItemList tab, WatchItemsView items) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (tab == WatchItemList.waiting && items.waiting == null) {
      unawaited(_loadWaiting());
    }
  }

  /// The desktop's content (27W-9a / 9b): a 48 px header with the name, then
  /// a 680 column – the banners (a failing watch: the reason, Fix in chat),
  /// the condition and facts, the actions – and the listings in tabs. A
  /// click on a listing shows it in the Hit inspector.
  Widget _desktop(
    BuildContext context,
    AppLocalizations l,
    WatchesView view,
    Watch? w,
    WatchItemsView items,
    DateTime now,
  ) {
    final Widget body;
    if (w == null) {
      final error = view.error;
      body = view.items == null && error == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(DelveDesktop.contentGutter),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  kind: error == null ? StatusKind.info : StatusKind.alert,
                  icon: error == null ? DelveIcons.info : DelveIcons.error,
                  text: error == null
                      ? l.watchGone
                      : l.watchesLoadFailed(apiErrorText(l, error)),
                  actionLabel: error == null ? null : l.retry,
                  onAction: error == null ? null : _refresh,
                ),
              ),
            );
    } else {
      body = DesktopPageBody(
        key: const Key('watch.detail'),
        maxWidth: DelveDesktop.detailColumn + 2 * DelveTokens.space4,
        top: DelveTokens.space3,
        children: [
          ..._header(l, w, now),
          _tabs(l, w, items),
          ..._tabItems(l, items, now),
        ],
      );
    }
    return DesktopPage(
      title: w?.name ?? l.moreWatches,
      inspectorToggle: true,
      actions: [
        DesktopRefreshButton(
          buttonKey: const Key('watch.refresh'),
          onPressed: () => unawaited(_refresh()),
        ),
      ],
      child: body,
    );
  }

  /// Hits · Rejected · Waiting, with their counts.
  Widget _tabs(AppLocalizations l, Watch w, WatchItemsView items) {
    Widget tab(WatchItemList t, String label) => InspectorTab(
      key: Key('watch.tab.${t.name}'),
      label: label,
      selected: _tab == t,
      onTap: () => _selectTab(t, items),
    );
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              tab(WatchItemList.hits, l.watchTabHits(w.hits)),
              tab(WatchItemList.rejected, l.watchTabRejected(w.rejected)),
              tab(WatchItemList.waiting, l.watchTabWaiting(w.pending)),
              const Spacer(),
              if (_tab == WatchItemList.hits && w.hits24h > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    l.watchHits24h(w.hits24h),
                    style: DelveDesktopText.meta.copyWith(
                      color: context.delve.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The open tab's listings, the selected one marked.
  List<Widget> _tabItems(
    AppLocalizations l,
    WatchItemsView items,
    DateTime now,
  ) {
    final (list, next, empty) = switch (_tab) {
      WatchItemList.hits => (items.hits, items.hitsNext, l.watchNoHits),
      WatchItemList.rejected => (
        items.rejects,
        items.rejectsNext,
        l.desktopWatchNoRejected,
      ),
      WatchItemList.waiting => (
        items.waiting,
        items.waitingNext,
        l.desktopWatchNoWaiting,
      ),
    };
    final error = items.error;
    if (list == null) {
      return [
        if (error != null)
          Padding(
            padding: _side.copyWith(top: DelveTokens.space4),
            child: StatusBanner(
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.watchesLoadFailed(apiErrorText(l, error)),
              actionLabel: l.retry,
              onAction: _tab == WatchItemList.waiting ? _loadWaiting : _refresh,
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(DelveTokens.space6),
            child: Center(child: CircularProgressIndicator()),
          ),
      ];
    }
    if (list.isEmpty) {
      return [
        Padding(
          padding: _side.copyWith(top: DelveTokens.space4),
          child: Text(
            empty,
            key: const Key('watch.tab.empty'),
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 6),
      for (final i in list)
        DesktopHitRow(
          key: ValueKey('watch.hit.${i.id}'),
          item: i,
          now: now,
          selected: i.id == widget.hit,
          onSelect: () => context.open(Routes.watchHit(widget.slug, i.id)),
        ),
      if (next != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6, top: DelveTokens.space1),
            child: TextButton(
              key: const Key('watch.moreItems'),
              onPressed: _loadingMore
                  ? null
                  : () => unawaited(_more(list: _tab)),
              child: Text(l.watchLoadMore),
            ),
          ),
        ),
    ];
  }

  static const _side = EdgeInsets.symmetric(horizontal: DelveTokens.space4);

  List<Widget> _header(AppLocalizations l, Watch w, DateTime now) {
    final keywords = keywordsText(l, w);
    final last = lastCheckText(l, w, now);
    final busy = _busy != null;
    return [
      if (w.failing)
        Padding(
          padding: _side.copyWith(bottom: DelveTokens.space4),
          child: StatusBanner(
            key: const Key('watch.errorBanner'),
            kind: StatusKind.alert,
            icon: DelveIcons.error,
            text: [
              w.lastError ?? w.lastErrorCode ?? l.watchStateError,
              if (w.errorsInRow > 1) l.watchErrorsInRow(w.errorsInRow),
            ].join(' · '),
            actionLabel: l.watchFixInChat,
            onAction: () => startWatchChat(
              context,
              draft: l.watchFixDraft(
                w.name,
                w.lastError ?? w.lastErrorCode ?? '',
              ),
            ),
          ),
        ),
      if (w.stoppedAfterHit)
        Padding(
          padding: _side.copyWith(bottom: DelveTokens.space4),
          child: StatusBanner(
            key: const Key('watch.stoppedBanner'),
            kind: StatusKind.info,
            icon: DelveIcons.onHold,
            text: l.watchStoppedAfterHit(pastText(l, w.stoppedAt!, now)),
            actionLabel: l.watchResume,
            onAction: busy ? null : () => unawaited(_act(WatchAction.resume)),
          ),
        ),
      _SectionLabel(l.watchCondition),
      Padding(
        padding: _side,
        child: _Condition(criteria: w.criteria),
      ),
      const SizedBox(height: DelveTokens.space2),
      Padding(
        padding: _side,
        child: Column(
          children: [
            _DetailRow(label: l.watchSource, value: sourceLabel(l, w.source)),
            _DetailRow(
              key: const Key('watch.search'),
              label: l.watchSearch,
              value: w.url.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
              mono: true,
              oneLine: true,
              onTap: () {
                unawaited(Clipboard.setData(ClipboardData(text: w.url)));
                _snack(l.chatLinkCopied);
              },
            ),
            if (keywords != null)
              _DetailRow(label: l.watchKeywords, value: keywords),
            _DetailRow(label: l.watchPrice, value: priceText(w) ?? '—'),
            _DetailRow(
              label: l.watchSchedule,
              value: watchScheduleText(l, w.schedule),
            ),
            _DetailRow(
              label: l.watchNextCheck,
              value: nextCheckText(l, w, now),
            ),
            if (last != null)
              _DetailRow(
                key: const Key('watch.lastCheck'),
                label: l.watchLastCheck,
                value: last,
                color: w.failing ? context.delve.alertFg : null,
              ),
            _DetailRow(
              label: l.watchDetailsPages,
              value: w.fetchDetails ? l.watchDetailsOn : l.watchOff,
            ),
            if (w.stopAfterHit)
              _DetailRow(label: l.watchStopAfterHit, value: l.watchOn),
          ],
        ),
      ),
      Padding(
        padding: _side.copyWith(top: DelveTokens.space4),
        child: Wrap(
          spacing: DelveTokens.space2,
          runSpacing: DelveTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('watch.pause'),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.surfaceContainerHighest,
                foregroundColor: context.colors.onSurface,
              ),
              onPressed: busy || w.state == 'unknown'
                  ? null
                  : () => unawaited(
                      _act(w.paused ? WatchAction.resume : WatchAction.pause),
                    ),
              icon: SymbolIcon(
                w.paused ? DelveIcons.play : DelveIcons.pause,
                size: DelveTokens.iconMd,
                filled: true,
              ),
              label: Text(w.paused ? l.watchResume : l.watchPause),
            ),
            OutlinedButton.icon(
              key: const Key('watch.run'),
              onPressed: busy || w.state == 'unknown'
                  ? null
                  : () => unawaited(_act(WatchAction.run)),
              icon: const SymbolIcon(
                DelveIcons.refresh,
                size: DelveTokens.iconMd,
              ),
              label: Text(l.watchRunNow),
            ),
            TextButton.icon(
              key: const Key('watch.change'),
              onPressed: () =>
                  startWatchChat(context, draft: l.watchChangeDraft(w.name)),
              icon: const SymbolIcon(
                DelveIcons.forum,
                size: DelveTokens.iconMd,
              ),
              label: Text(l.watchChangeInChat),
            ),
          ],
        ),
      ),
      if (w.pending > 0)
        Padding(
          padding: _side.copyWith(top: DelveTokens.space3),
          child: Row(
            children: [
              SymbolIcon(
                DelveIcons.hourglass,
                size: DelveTokens.iconSm,
                color: context.delve.textMuted,
              ),
              const SizedBox(width: DelveTokens.space2),
              Expanded(
                child: Text(
                  l.watchPending(w.pending),
                  key: const Key('watch.pending'),
                  style: context.text.bodySmall!.copyWith(
                    color: context.delve.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _hits(
    AppLocalizations l,
    Watch w,
    WatchItemsView items,
    DateTime now,
  ) {
    final hits = items.hits;
    return [
      _SectionLabel(
        l.watchHits(w.hits),
        trailing: w.hits24h > 0 ? l.watchHits24h(w.hits24h) : null,
      ),
      if (hits == null)
        const Padding(
          padding: EdgeInsets.all(DelveTokens.space4),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (hits.isEmpty)
        Padding(
          padding: _side,
          child: Text(
            l.watchNoHits,
            key: const Key('watch.noHits'),
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        )
      else ...[
        for (final i in hits) HitRow(item: i, now: now),
        if (items.hitsNext != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space1,
                vertical: DelveTokens.space1,
              ),
              child: TextButton(
                key: const Key('watch.moreHits'),
                onPressed: _loadingMore ? null : () => unawaited(_more()),
                child: Text(l.watchLoadMore),
              ),
            ),
          ),
      ],
    ];
  }

  List<Widget> _rejected(
    AppLocalizations l,
    Watch w,
    WatchItemsView items,
    DateTime now,
  ) {
    final rejects = items.rejects ?? const <WatchItem>[];
    if (w.rejected == 0 && rejects.isEmpty) return const [];
    return [
      const SizedBox(height: DelveTokens.space4),
      InkWell(
        key: const Key('watch.rejectedToggle'),
        onTap: () => setState(() => _rejectedOpen = !_rejectedOpen),
        child: Container(
          constraints: const BoxConstraints(minHeight: DelveTokens.touchTarget),
          padding: const EdgeInsets.only(
            left: DelveTokens.space4,
            right: DelveTokens.space1,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.colors.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.watchRejected(w.rejected > 0 ? w.rejected : rejects.length),
                  style: context.text.titleSmall,
                ),
              ),
              SizedBox.square(
                dimension: DelveTokens.touchTarget,
                child: Center(
                  child: SymbolIcon(
                    _rejectedOpen
                        ? DelveIcons.expandLess
                        : DelveIcons.expandMore,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      AnimatedSize(
        duration: DelveTokens.medium,
        curve: DelveTokens.standard,
        alignment: Alignment.topCenter,
        child: !_rejectedOpen
            ? const SizedBox(width: double.infinity)
            : Column(
                key: const Key('watch.rejectedList'),
                children: [
                  for (final i in rejects) HitRow(item: i, now: now),
                  if (items.rejectsNext != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _loadingMore
                            ? null
                            : () => unawaited(_more(rejected: true)),
                        child: Text(l.watchLoadMore),
                      ),
                    ),
                ],
              ),
      ),
    ];
  }
}

/// "CONDITION", "HITS · 3" (labelSmall, muted, upper case) with an optional
/// note on the right.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = context.text.labelSmall!.copyWith(
      color: context.delve.textMuted,
      letterSpacing: 0.9,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        DelveTokens.space5,
        DelveTokens.space4,
        DelveTokens.space2,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: style)),
          if (trailing case final t?)
            Text(
              t,
              style: context.text.labelMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// The condition in a recessed block (design 21b), or "No condition".
class _Condition extends StatelessWidget {
  const _Condition({required this.criteria});

  final String? criteria;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = criteria;
    return Container(
      key: const Key('watch.condition'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space3,
        DelveTokens.space3,
        DelveTokens.space4,
        DelveTokens.space3,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SymbolIcon(
            DelveIcons.quote,
            size: DelveTokens.iconMd,
            filled: true,
            color: context.delve.textMuted,
          ),
          const SizedBox(width: DelveTokens.space2),
          Expanded(
            child: Text(
              c == null || c.isEmpty ? l.watchNoCondition : c,
              style: c == null || c.isEmpty
                  ? context.text.bodyMedium!.copyWith(
                      color: context.delve.textMuted,
                    )
                  : context.text.bodyMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Key (96 dp) and value, a divider under it (design 21b info row).
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.oneLine = false,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final bool mono;
  final bool oneLine;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: context.text.bodyMedium!.copyWith(color: secondary),
            ),
          ),
          const SizedBox(width: DelveTokens.space3),
          Expanded(
            child: Text(
              value,
              maxLines: oneLine ? 1 : null,
              overflow: oneLine ? TextOverflow.ellipsis : null,
              style: mono
                  ? DelveText.mono.copyWith(color: color ?? secondary)
                  : context.text.bodyMedium!.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// The desktop's Hit inspector (27W-9a): the selected listing – title, the
/// price large, place and posting, the judge's note, the listing's text –
/// with Open link and Copy link.
class WatchHitInspector extends ConsumerWidget {
  const WatchHitInspector({super.key, required this.slug, required this.id});

  final String slug;
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final item = ref.watch(watchItemsProvider(slug)).byId(id);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: muted,
        ),
      ),
    );
    return InspectorFrame(
      key: const Key('inspector.hit'),
      label: l.watchHitTab,
      child: switch (item) {
        null => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l.desktopWatchHitGone,
            style: context.text.bodyMedium!.copyWith(color: muted),
          ),
        ),
        final WatchItem i => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          children: [
            SelectableText(
              i.title,
              key: const Key('inspector.hit.title'),
              style: context.text.titleMedium,
            ),
            if (i.price case final price? when price.isNotEmpty) ...[
              const SizedBox(height: DelveTokens.space2),
              Text(
                price,
                key: const Key('inspector.hit.price'),
                style: context.text.displaySmall!.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const SizedBox(height: DelveTokens.space2),
            Text(
              [
                ?i.location,
                ?i.posted,
                l.desktopWatchSeen(listTime(i.seenAt, DateTime.now())),
              ].where((s) => s.isNotEmpty).join(' · '),
              style: context.text.bodySmall!.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            if (itemMarker(l, i) case final marker?) ...[
              const SizedBox(height: DelveTokens.space2),
              Align(alignment: Alignment.centerLeft, child: marker),
            ],
            eyebrow(l.desktopWatchJudge),
            Text(
              switch (i) {
                WatchItem(verdict: 'mechanical') => l.watchItemByFilters,
                WatchItem(verdict: 'pending') => l.watchItemWaiting,
                WatchItem(verdict: 'error', :final reason) =>
                  reason ?? l.watchItemCouldntJudge,
                WatchItem(:final reason) => reason ?? '—',
              },
              key: const Key('inspector.hit.judge'),
              style: context.text.bodyMedium!.copyWith(
                fontStyle: i.reason != null ? FontStyle.italic : null,
              ),
            ),
            if (i.excerpt case final excerpt? when excerpt.isNotEmpty) ...[
              eyebrow(l.desktopWatchListing),
              SelectableText(
                excerpt,
                style: context.text.bodyMedium!.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: DelveTokens.space5),
            Wrap(
              spacing: DelveTokens.space2,
              runSpacing: DelveTokens.space2,
              children: [
                FilledButton.icon(
                  key: const Key('inspector.hit.open'),
                  onPressed: () => unawaited(openHit(context, ref, i)),
                  icon: const SymbolIcon(DelveIcons.openLink, size: 16),
                  label: Text(l.watchOpenLink),
                ),
                TextButton.icon(
                  key: const Key('inspector.hit.copy'),
                  onPressed: () => unawaited(copyLink(context, i.url)),
                  icon: const SymbolIcon(DelveIcons.copy, size: 16),
                  label: Text(l.watchCopyLink),
                ),
              ],
            ),
          ],
        ),
      },
    );
  }
}
