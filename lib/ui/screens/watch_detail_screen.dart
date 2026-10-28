import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../app/watches.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../watch_text.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/watch_ui.dart';
import 'watches_screen.dart' show startWatchChat;

/// 21b Watch: its condition and filters, pause / resume / run now, change it
/// in a chat; the hits (newest first) and the rejected listings, collapsed.
class WatchDetailScreen extends ConsumerStatefulWidget {
  const WatchDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<WatchDetailScreen> createState() => _WatchDetailScreenState();
}

class _WatchDetailScreenState extends ConsumerState<WatchDetailScreen> {
  bool _rejectedOpen = false;
  WatchAction? _busy;
  bool _loadingMore = false;

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

  Future<void> _more({bool rejected = false}) async {
    final l = AppLocalizations.of(context);
    setState(() => _loadingMore = true);
    try {
      await ref
          .read(watchItemsProvider(widget.slug).notifier)
          .loadMore(rejected: rejected);
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
