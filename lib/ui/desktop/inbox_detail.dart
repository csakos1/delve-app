import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../app/inbox.dart';
import '../../app/router.dart';
import '../../app/system.dart';
import '../../app/watches.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../links.dart';
import '../screens/approvals_screen.dart' show ApprovalDetail;
import '../screens/news_story_screen.dart' show NewsStoryScreen;
import '../watch_text.dart';
import '../widgets/model_ui.dart' show switchReasonText;
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/watch_ui.dart' show itemMarker;
import 'desktop_page.dart';
import 'list_area.dart';
import 'panes.dart';

/// How an Inbox kind looks (Components “Inbox”): its 16 px icon, colour and
/// word. A must-read takes its topic's glyph and colour.
typedef InboxLook = ({IconData icon, bool filled, Color color, String word});

InboxLook inboxLook(BuildContext context, InboxItem item) {
  final l = AppLocalizations.of(context);
  final d = context.delve;
  final cs = context.colors;
  final topic = TopicStyle.of(item.story?.topic);
  return switch (item.kind) {
    InboxKind.approval => (
      icon: DelveIcons.approvals,
      filled: true,
      color: d.warnFg,
      word: l.inboxKindApproval,
    ),
    InboxKind.lateApproval => (
      icon: DelveIcons.timerOff,
      filled: false,
      color: d.infoFg,
      word: l.inboxKindLateApproval,
    ),
    InboxKind.watchHit => (
      icon: DelveIcons.watches,
      filled: false,
      color: cs.onSurfaceVariant,
      word: l.inboxKindWatchHit,
    ),
    InboxKind.mustRead => (
      icon: topic.glyph,
      filled: false,
      color: topic.color,
      word: l.newsMustRead,
    ),
    InboxKind.feedFailing => (
      icon: NewsIcons.failingFeeds,
      filled: false,
      color: d.infoFg,
      word: l.inboxKindFeedFailing,
    ),
    InboxKind.switchFailed => (
      icon: DelveIcons.error,
      filled: true,
      color: d.alertFg,
      word: l.inboxKindSwitchFailed,
    ),
    InboxKind.scheduleFailed => (
      icon: DelveIcons.error,
      filled: true,
      color: d.alertFg,
      word: l.inboxKindScheduleFailed,
    ),
    _ => (
      icon: DelveIcons.info,
      filled: false,
      color: cs.onSurfaceVariant,
      word: item.kind,
    ),
  };
}

/// Where the Inbox goes once the open item [id] was cleared: the row that
/// takes its place, or the list alone when it was the last one.
String inboxRouteAfter(InboxState view, String id) {
  final ids = [for (final i in view.items) i.id];
  final at = ids.indexOf(id);
  ids.remove(id);
  if (at < 0 || ids.isEmpty) return Routes.inbox;
  return Routes.inboxItem(ids[at.clamp(0, ids.length - 1)]);
}

/// A failed schedule's reason in words: a missed time, or the run's error.
String scheduleFailureText(AppLocalizations l, Schedule s) {
  final error = s.lastError;
  if (error == 'missed') return l.inboxScheduleMissed;
  return error == null || error.isEmpty ? l.inboxScheduleFailed : error;
}

/// The content of the Inbox while no item is open: with nothing left in the
/// list “Nothing needs you” and when the last item was cleared.
class InboxPlaceholder extends ConsumerWidget {
  const InboxPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(inboxProvider);
    final done = view.done;
    if (view.inbox != null && view.items.isEmpty) {
      final last = done.isEmpty ? null : done.first.doneAt;
      return ListPlaceholder(
        key: const Key('inbox.placeholder.empty'),
        icon: DelveIcons.inbox,
        title: l.inboxEmptyTitle,
        hint: last == null
            ? l.inboxEmptySub
            : l.inboxEmptyDone(
                clockTime(last, DateTime.now()),
                l.inboxDoneCount(done.length),
              ),
      );
    }
    return ListPlaceholder(
      key: const Key('inbox.placeholder'),
      icon: DelveIcons.inbox,
      title: l.desktopInboxEmpty,
      hint: l.desktopInboxEmptySub,
    );
  }
}

/// The open Inbox item in the content (27W-1a … 1e): the header says where
/// it is in the list (“Inbox · 2 of 7”) and holds previous / next and Done
/// (E; an approval is answered instead) – or Undo for one cleared today.
/// An approval is the approval page, answerable here; a watcher's hit its
/// listing with Open link (which clears it) and Open watch; a must-read the
/// reading view (read, and cleared, after 2 s on screen); a notice what
/// failed, since when, and a link into its area. An item that left the list
/// while it was open stays on screen until another one is opened.
class InboxDetail extends ConsumerStatefulWidget {
  const InboxDetail({super.key, required this.id});

  /// `<kind>:<ref>`.
  final String id;

  @override
  ConsumerState<InboxDetail> createState() => _InboxDetailState();
}

class _InboxDetailState extends ConsumerState<InboxDetail> {
  bool _busy = false;

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Done: cleared, then on to the row that takes its place.
  Future<void> _done(InboxItem item) async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final inbox = ref.read(inboxProvider.notifier);
    final after = inboxRouteAfter(ref.read(inboxProvider), item.id);
    setState(() => _busy = true);
    try {
      await inbox.done(item.id);
      if (mounted) context.go(after);
    } on Object catch (e) {
      if (mounted) _snack(l.inboxDoneFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undo() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final inbox = ref.read(inboxProvider.notifier);
    setState(() => _busy = true);
    try {
      await inbox.undo(widget.id);
    } on Object catch (e) {
      if (mounted) _snack(l.inboxUndoFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Clears the item without a word if it is still in the list (a hit that
  /// was opened, a story that was shown); a failure leaves it there.
  Future<void> _clearQuietly() async {
    if (!mounted) return;
    final id = widget.id;
    if (ref.read(inboxProvider).openItem(id) == null) return;
    final inbox = ref.read(inboxProvider.notifier);
    try {
      await inbox.done(id);
    } on Object {
      // it stays in the list
    }
  }

  void _openHit(WatchItem hit) {
    unawaited(openLink(context, ref, hit.url));
    unawaited(_clearQuietly());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final view = ref.watch(inboxProvider);
    final id = widget.id;
    final place = view.placeOf(id);
    final item =
        view.openItem(id) ??
        view.doneItem(id) ??
        ref.read(inboxProvider.notifier).known(id);
    final kind = InboxItem.kindOf(id);
    final subject = InboxItem.subjectOf(id);
    final ids = [for (final i in view.items) i.id];
    final at = ids.indexOf(id);
    final title = switch (place) {
      InboxPlace.open => l.inboxHeader(at + 1, view.open),
      InboxPlace.done => l.inboxHeaderDone,
      InboxPlace.gone => l.navInbox,
    };
    void go(int index) => context.go(Routes.inboxItem(ids[index]));
    final actions = <Widget>[
      if (place == InboxPlace.open) ...[
        IconButton(
          key: const Key('inbox.previous'),
          tooltip: l.inboxPrevious,
          onPressed: at > 0 ? () => go(at - 1) : null,
          icon: const SymbolIcon(
            DelveIcons.expandLess,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
        IconButton(
          key: const Key('inbox.next'),
          tooltip: l.inboxNext,
          onPressed: at < ids.length - 1 ? () => go(at + 1) : null,
          icon: const SymbolIcon(
            DelveIcons.expandMore,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
        if (item != null && item.doneable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton(
              key: const Key('inbox.done'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurface,
                minimumSize: const Size(48, DelveDesktop.buttonSmall),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: _busy ? null : () => unawaited(_done(item)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.inboxDone),
                  const SizedBox(width: 6),
                  const KeyCap('E'),
                ],
              ),
            ),
          ),
      ],
      if (place == InboxPlace.done)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextButton.icon(
            key: const Key('inbox.undo'),
            onPressed: _busy ? null : () => unawaited(_undo()),
            icon: const SymbolIcon(DelveIcons.undo, size: 16),
            label: Text(l.chatsUndo),
          ),
        ),
    ];

    if (kind == InboxKind.approval || kind == InboxKind.lateApproval) {
      return ApprovalDetail(
        key: ValueKey('inbox.approval.$subject'),
        requestId: subject,
        title: title,
        actions: actions,
      );
    }
    final story = kind == InboxKind.mustRead ? int.tryParse(subject) : null;
    if (story != null) {
      return NewsStoryScreen(
        key: ValueKey('inbox.story.$story'),
        id: story,
        title: title,
        headerActions: actions,
        readAfter: DelveDesktop.inboxReadAfter,
        beforeRead: _clearQuietly,
      );
    }
    final left = place == InboxPlace.gone;
    final Widget body;
    if (item == null) {
      body = view.inbox == null
          ? const SizedBox.shrink()
          : const Padding(
              padding: EdgeInsets.all(DelveDesktop.contentGutter),
              child: Align(
                alignment: Alignment.topCenter,
                child: _LeftNote(key: Key('inbox.gone')),
              ),
            );
    } else if (item.hit case final hit?) {
      body = _HitDetail(
        item: item,
        hit: hit,
        left: left,
        onOpen: () => _openHit(hit),
      );
    } else {
      body = _NoticeDetail(item: item, left: left);
    }
    return DesktopPage(
      title: title,
      actions: actions,
      inspectorToggle: true,
      child: body,
    );
  }
}

/// “This item is not in the Inbox any more.”
class _LeftNote extends StatelessWidget {
  const _LeftNote({super.key});

  @override
  Widget build(BuildContext context) => StatusBanner(
    kind: StatusKind.info,
    icon: DelveIcons.info,
    text: AppLocalizations.of(context).inboxGone,
  );
}

/// The kind's icon and word over a detail page, with where it comes from.
class _KindLine extends StatelessWidget {
  const _KindLine({required this.item});

  final InboxItem item;

  @override
  Widget build(BuildContext context) {
    final look = inboxLook(context, item);
    final source = item.isNotice ? null : item.source;
    return Row(
      children: [
        SymbolIcon(
          look.icon,
          size: DelveDesktop.inboxIcon,
          filled: look.filled,
          color: look.color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            [
              look.word,
              if (source != null && source.isNotEmpty) source,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium!.copyWith(color: look.color),
          ),
        ),
      ],
    );
  }
}

Widget _eyebrow(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: 20, bottom: 6),
  child: Text(
    text.toUpperCase(),
    style: context.text.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.7,
      color: context.delve.textMuted,
    ),
  ),
);

TextStyle _heading() =>
    DelveDesktopText.pageTitle.copyWith(fontSize: 22, height: 28 / 22);

/// A watcher's hit (27W-1c): the listing's title, its price large, where
/// and when, the judge's note and the listing's text; Open link (the hit
/// leaves the list), Open watch, Copy link.
class _HitDetail extends StatelessWidget {
  const _HitDetail({
    required this.item,
    required this.hit,
    required this.left,
    required this.onOpen,
  });

  final InboxItem item;
  final WatchItem hit;
  final bool left;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final i = hit;
    final marker = itemMarker(l, i);
    return DesktopPageBody(
      key: const Key('inbox.hit'),
      maxWidth: DelveDesktop.detailColumn,
      top: DelveTokens.space4,
      children: [
        if (left) ...[
          const _LeftNote(),
          const SizedBox(height: DelveTokens.space4),
        ],
        _KindLine(item: item),
        const SizedBox(height: DelveTokens.space2),
        SelectableText(
          i.title,
          key: const Key('inbox.hit.title'),
          style: _heading(),
        ),
        if (i.price case final price? when price.isNotEmpty) ...[
          const SizedBox(height: DelveTokens.space2),
          Text(
            price,
            key: const Key('inbox.hit.price'),
            style: context.text.displaySmall!.copyWith(
              fontSize: 34,
              height: 40 / 34,
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
          style: context.text.bodySmall!.copyWith(color: cs.onSurfaceVariant),
        ),
        if (marker != null) ...[
          const SizedBox(height: DelveTokens.space2),
          Align(alignment: Alignment.centerLeft, child: marker),
        ],
        _eyebrow(context, l.desktopWatchJudge),
        Text(
          switch (i) {
            WatchItem(verdict: 'mechanical') => l.watchItemByFilters,
            WatchItem(:final reason) => reason ?? '—',
          },
          key: const Key('inbox.hit.judge'),
          style: context.text.bodyMedium!.copyWith(
            fontStyle: i.reason != null ? FontStyle.italic : null,
          ),
        ),
        if (i.excerpt case final excerpt? when excerpt.isNotEmpty) ...[
          _eyebrow(context, l.desktopWatchListing),
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
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('inbox.hit.open'),
              onPressed: onOpen,
              icon: const SymbolIcon(DelveIcons.openLink, size: 16),
              label: Text(l.watchOpenLink),
            ),
            FilledButton(
              key: const Key('inbox.hit.watch'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurface,
              ),
              onPressed: () => context.go(Routes.watchHit(i.slug, i.id)),
              child: Text(l.inboxOpenWatch),
            ),
            TextButton.icon(
              key: const Key('inbox.hit.copy'),
              onPressed: () => unawaited(copyLink(context, i.url)),
              icon: const SymbolIcon(DelveIcons.copy, size: 16),
              label: Text(l.watchCopyLink),
            ),
          ],
        ),
      ],
    );
  }
}

/// A notice (27W-1e): what failed – a feed three rounds in a row, a model
/// switch, a schedule's run or its time – since when, and a link into its
/// area.
class _NoticeDetail extends ConsumerWidget {
  const _NoticeDetail({required this.item, required this.left});

  final InboxItem item;
  final bool left;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final now = DateTime.now();
    final llama = ref.watch(systemProvider.select((v) => v.info?.llama));
    String model(String? preset) =>
        llama?.presetText(preset) ?? preset ?? item.title;

    final String heading;
    final String body;
    final facts = <(String, String)>[];
    final String linkLabel;
    final String link;
    if (item.feed case final feed?) {
      heading = newsHost(feed.url).isEmpty ? feed.url : newsHost(feed.url);
      body = l.newsFeedFailedRounds(feed.errorsInRow);
      final answer =
          feed.lastError ??
          feed.lastErrorCode ??
          (feed.lastHttp == null ? null : 'HTTP ${feed.lastHttp}');
      facts.addAll([
        (l.inboxFactAddress, feed.url),
        if (answer != null) (l.newsFeedRowAnswer, answer),
        if (feed.lastAt case final at?)
          (l.newsFeedRowChecked, clockTime(at, now)),
        if (feed.lastOkAt case final at?)
          (l.inboxFactLastWorked, pastText(l, at, now)),
        if (item.source case final topic? when topic.isNotEmpty)
          (l.newsFeedRowTopic, topic),
      ]);
      linkLabel = l.inboxOpenFeed;
      link = Routes.newsFeed(feed.id);
    } else if (item.llamaSwitch case final sw?) {
      final to = model(sw.to);
      final from = sw.from == null ? null : model(sw.from);
      heading = to;
      body = switch ((sw.state == 'down', from)) {
        (false, final f?) => l.modelFailed(to, f),
        (false, null) => l.modelFailedAlone(to),
        (true, final f?) => l.modelFailedDown(to, f),
        (true, null) => l.modelFailedDownAlone(to),
      };
      facts.addAll([
        if (switchReasonText(l, sw) case final why?) (l.inboxFactReason, why),
        if (sw.at case final at?) (l.inboxFactWhen, pastText(l, at, now)),
        if (sw.by case final by? when by.isNotEmpty) (l.inboxFactAskedBy, by),
      ]);
      linkLabel = l.inboxOpenSystem;
      link = Routes.system;
    } else if (item.schedule case final s?) {
      heading = s.name;
      final missed = s.lastError == 'missed';
      body = missed ? l.inboxScheduleMissedBody : l.inboxScheduleFailedBody;
      facts.addAll([
        if (!missed) (l.inboxFactReason, scheduleFailureText(l, s)),
        if (item.at case final at?) (l.inboxFactWhen, pastText(l, at, now)),
        if (s.nextRunAt case final next?)
          (l.inboxFactNextRun, clockTime(next, now)),
      ]);
      linkLabel = l.inboxOpenSchedule;
      link = Routes.schedule(s.id);
    } else {
      heading = item.title;
      body = item.source ?? '';
      linkLabel = '';
      link = '';
    }

    return DesktopPageBody(
      key: const Key('inbox.notice'),
      maxWidth: DelveDesktop.detailColumn,
      top: DelveTokens.space4,
      children: [
        if (left) ...[
          const _LeftNote(),
          const SizedBox(height: DelveTokens.space4),
        ],
        _KindLine(item: item),
        const SizedBox(height: DelveTokens.space2),
        SelectableText(
          heading,
          key: const Key('inbox.notice.title'),
          style: _heading(),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: DelveTokens.space3),
          Text(
            body,
            key: const Key('inbox.notice.body'),
            style: context.text.bodyLarge,
          ),
        ],
        if (facts.isNotEmpty) const SizedBox(height: DelveTokens.space3),
        for (final (label, value) in facts) _Fact(label: label, value: value),
        if (link.isNotEmpty) ...[
          const SizedBox(height: DelveTokens.space5),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('inbox.notice.open'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurface,
              ),
              onPressed: () => context.go(link),
              icon: const SymbolIcon(DelveIcons.arrowOutward, size: 16),
              label: Text(linkLabel),
            ),
          ),
        ],
      ],
    );
  }
}

/// A fact of a notice or of the Watch inspector: its name in a 120 px
/// column, the value beside it (selectable), a hairline under both.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.width = 120});

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width,
          child: Text(
            label,
            style: context.text.bodyMedium!.copyWith(
              fontSize: 13,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: DelveTokens.space3),
        Expanded(
          child: SelectableText(
            value,
            style: context.text.bodyMedium!.copyWith(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

/// The Inbox inspector of a watcher's hit (27W-1c): the watch it came from
/// – its state, its condition, when it checks – and Open watch.
class InboxWatchInspector extends ConsumerStatefulWidget {
  const InboxWatchInspector({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<InboxWatchInspector> createState() =>
      _InboxWatchInspectorState();
}

class _InboxWatchInspectorState extends ConsumerState<InboxWatchInspector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(watchesProvider).items != null) return;
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    try {
      await ref.read(watchesProvider.notifier).refresh();
    } on Object {
      // the inspector says the watch is not loaded
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(watchesProvider);
    final watch = view.bySlug(widget.slug);
    final now = DateTime.now();
    final muted = context.delve.textMuted;
    return InspectorFrame(
      key: const Key('inspector.inbox.watch'),
      label: l.inboxWatchTab,
      child: switch (watch) {
        null => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            view.items == null ? '' : l.watchGone,
            style: context.text.bodyMedium!.copyWith(color: muted),
          ),
        ),
        final Watch w => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          children: [
            SelectableText(
              w.name,
              key: const Key('inspector.inbox.watch.name'),
              style: context.text.titleMedium,
            ),
            const SizedBox(height: DelveTokens.space1),
            Align(alignment: Alignment.centerLeft, child: watchStatus(l, w)),
            _eyebrow(context, l.watchCondition),
            Text(
              w.criteria == null || w.criteria!.isEmpty
                  ? l.watchNoCondition
                  : w.criteria!,
              style: w.criteria == null || w.criteria!.isEmpty
                  ? context.text.bodyMedium!.copyWith(color: muted)
                  : context.text.bodyMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
            ),
            const SizedBox(height: DelveTokens.space3),
            _Fact(
              label: l.watchSource,
              value: sourceLabel(l, w.source),
              width: 96,
            ),
            _Fact(
              label: l.watchSchedule,
              value: watchScheduleText(l, w.schedule),
              width: 96,
            ),
            if (lastCheckText(l, w, now) case final last?)
              _Fact(label: l.watchLastCheck, value: last, width: 96),
            _Fact(
              label: l.watchNextCheck,
              value: nextCheckText(l, w, now),
              width: 96,
            ),
            const SizedBox(height: DelveTokens.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('inspector.inbox.watch.open'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.surfaceContainerHighest,
                  foregroundColor: context.colors.onSurface,
                ),
                onPressed: () => context.go(Routes.watch(w.slug)),
                child: Text(l.inboxOpenWatch),
              ),
            ),
          ],
        ),
      },
    );
  }
}
