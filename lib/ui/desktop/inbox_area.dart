import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../app/approvals.dart';
import '../../app/inbox.dart';
import '../../app/news.dart';
import '../../app/router.dart';
import '../../app/system.dart';
import '../../data/db/database.dart' show ApprovalRow;
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/approval_card.dart' show approvalOutcomeLook, isAnswerable;
import '../chat/tool_step_card.dart' show displayCommand;
import '../format.dart';
import '../screens/news_story_screen.dart' show NewsStoryInspector;
import '../watch_text.dart' show itemMeta;
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import 'approvals_area.dart' show ApprovalRunInspector;
import 'areas.dart';
import 'desktop_page.dart'
    show PageCommandSlot, PageCommands, pageCommandSlotProvider;
import 'desktop_row.dart';
import 'inbox_detail.dart';
import 'intake.dart'
    show ListCommandSlot, ListCommands, listCommandSlotProvider;
import 'list_area.dart';
import 'panes.dart' show KeyCap;

/// The item an Inbox [location] shows (`<kind>:<ref>`; null: none).
@visibleForTesting
String? selectedInboxItem(String location) {
  final s = Uri.parse(location).pathSegments;
  if (s.length == 2 && s[0] == 'inbox') return s[1];
  return null;
}

/// The Inbox in the desktop layout (27W-1a … 1f, L2e): one list of what
/// needs the reader in the list column, the open item in the content, where
/// it comes from in the inspector – the run of an approval's chat, the
/// watch of a hit, the Story of a must-read, nothing for a notice.
class InboxArea extends ConsumerWidget {
  const InboxArea({super.key, required this.location, required this.content});

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = selectedInboxItem(location);
    return ListArea(
      area: DesktopArea.inbox.name,
      selected: id,
      list: InboxList(selected: id),
      content: content,
      inspector: id == null ? null : _inspector(ref, id),
    );
  }

  Widget? _inspector(WidgetRef ref, String id) {
    final subject = InboxItem.subjectOf(id);
    switch (InboxItem.kindOf(id)) {
      case InboxKind.approval || InboxKind.lateApproval:
        return ApprovalRunInspector(
          key: ValueKey('inspector.approval.$subject'),
          id: subject,
        );
      case InboxKind.mustRead:
        final story = int.tryParse(subject);
        return story == null
            ? null
            : NewsStoryInspector(
                key: ValueKey('inspector.story.$story'),
                id: story,
              );
      case InboxKind.watchHit:
        // the hit names its watch; it is known once the list has loaded
        final view = ref.watch(inboxProvider);
        final item =
            view.openItem(id) ??
            view.doneItem(id) ??
            ref.read(inboxProvider.notifier).known(id);
        final slug = item?.hit?.slug;
        return slug == null
            ? null
            : InboxWatchInspector(
                key: ValueKey('inspector.inbox.watch.$slug'),
                slug: slug,
              );
      default:
        return null;
    }
  }
}

/// The Inbox's list column (27W-1a): every open item, newest first and all
/// kinds mixed, as three-line rows – the kind and the time, the gist (a
/// command in full), where it comes from; under them “Done today”,
/// collapsed, with Undo on its rows; at the foot the keys. An approval
/// that was answered shows how it ended for 1.5 s before its row goes
/// (27W-1b). J / K (↓ / ↑)
/// step through the rows, Enter goes into the content, E clears the open
/// item and moves on, Ctrl+Z brings the last cleared one back, Ctrl+R
/// reloads.
class InboxList extends ConsumerStatefulWidget {
  const InboxList({super.key, this.selected});

  /// The item open in the content (its row is selected).
  final String? selected;

  @override
  ConsumerState<InboxList> createState() => _InboxListState();
}

class _InboxListState extends ConsumerState<InboxList> {
  /// The rows in the order shown (J / K).
  List<String> _order = const [];

  /// Where the open item was in [_order] when it was last there: J / K go
  /// on from its place once it has left the list.
  int? _lastAt;

  /// “Done today” is open.
  bool _doneOpen = false;

  late final ListCommandSlot _keys;
  late final PageCommandSlot _pageKeys;

  /// A second's tick while an agent waits (the countdowns).
  Timer? _tick;

  /// The approval rows of the last build, by item id.
  Map<String, InboxItem> _approvalRows = const {};

  /// Approval rows that left the list answered (or lapsed), with how they
  /// ended: shown for [DelveDesktop.outcomeHold], then gone.
  final Map<String, (InboxItem, ApprovalRow)> _leaving = {};
  final Map<String, Timer> _leaveTimers = {};

  @override
  void initState() {
    super.initState();
    _keys = ref.read(listCommandSlotProvider);
    _pageKeys = ref.read(pageCommandSlotProvider);
    // after the first frame: the refresh changes provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final t in _leaveTimers.values) {
      t.cancel();
    }
    _keys.unregister(this);
    _pageKeys.unregister(this);
    super.dispose();
  }

  /// The row of [item] stays for a moment with its [outcome].
  void _leave(InboxItem item, ApprovalRow outcome) {
    final id = item.id;
    _leaving[id] = (item, outcome);
    _leaveTimers[id]?.cancel();
    _leaveTimers[id] = Timer(DelveDesktop.outcomeHold, () {
      _leaveTimers.remove(id);
      if (!mounted) return;
      setState(() => _leaving.remove(id));
    });
  }

  /// The open items with the rows that are leaving among them, each where
  /// its time puts it (newest first).
  List<InboxItem> _withLeaving(List<InboxItem> items) {
    if (_leaving.isEmpty) return items;
    final rows = [...items];
    for (final (item, _) in _leaving.values) {
      if (rows.any((i) => i.id == item.id)) continue;
      final at = item.at;
      final before = at == null
          ? -1
          : rows.indexWhere((i) => i.at == null || i.at!.isBefore(at));
      rows.insert(before < 0 ? rows.length : before, item);
    }
    return rows;
  }

  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  void _snack(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        action == null
            ? SnackBar(content: Text(text))
            // an action would keep the bar up until tapped: Undo goes by
            // itself too
            : SnackBar(
                content: Text(text),
                action: action,
                persist: false,
                duration: DelveTokens.undoSnack,
              ),
      );
  }

  /// The list, and the approvals its rows show (they live in the
  /// database). [quiet]: the reload on opening says nothing when it fails.
  Future<void> _refresh({bool quiet = false}) async {
    final l = AppLocalizations.of(context);
    final approvals = ref.read(approvalInboxServiceProvider);
    try {
      await ref.read(inboxProvider.notifier).refresh();
    } on Object catch (e) {
      if (!quiet && mounted) _snack(l.inboxLoadFailed(apiErrorText(l, e)));
    }
    try {
      await approvals?.refresh();
    } on Object {
      // the stored approvals stay
    }
  }

  void _open(String id) => context.go(Routes.inboxItem(id));

  /// J / K: the next / previous row (the first without one open; from the
  /// place of an item that has left the list).
  void _step(int by) {
    final order = _order;
    if (order.isEmpty) return;
    final open = widget.selected;
    final at = open == null ? -1 : order.indexOf(open);
    final last = _lastAt;
    final int next;
    if (at >= 0) {
      next = (at + by).clamp(0, order.length - 1);
      if (next == at) return;
    } else if (open == null || last == null) {
      next = by > 0 ? 0 : order.length - 1;
    } else {
      // the row that took its place is the next one
      next = (by > 0 ? last : last - 1).clamp(0, order.length - 1);
    }
    _open(order[next]);
  }

  /// Done (the row's check, its menu, E on the open item): cleared; from
  /// the open item on to the row that takes its place.
  Future<void> _done(InboxItem item) async {
    final l = AppLocalizations.of(context);
    final inbox = ref.read(inboxProvider.notifier);
    final after = inboxRouteAfter(ref.read(inboxProvider), item.id);
    try {
      await inbox.done(item.id);
    } on Object catch (e) {
      if (mounted) _snack(l.inboxDoneFailed(apiErrorText(l, e)));
      return;
    }
    if (mounted && widget.selected == item.id) context.go(after);
  }

  Future<void> _undo(String id) async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(inboxProvider.notifier).undo(id);
    } on Object catch (e) {
      if (mounted) _snack(l.inboxUndoFailed(apiErrorText(l, e)));
    }
  }

  /// E: the open item is cleared (an approval is answered instead).
  void _doneOpenItem() {
    final id = widget.selected;
    if (id == null) return;
    final item = ref.read(inboxProvider).openItem(id);
    if (item == null || !item.doneable) return;
    unawaited(_done(item));
  }

  /// Ctrl+Z: the last item cleared here comes back.
  void _undoLast() {
    final id = ref.read(inboxProvider).lastCleared;
    if (id != null) unawaited(_undo(id));
  }

  /// What a row's menu offers: Done or Undo, and the way to its source.
  List<DesktopMenuItem> _menu(
    AppLocalizations l,
    InboxItem i, {
    required bool open,
  }) => [
    if (open && i.doneable)
      DesktopMenuItem(
        key: const Key('inbox.menu.done'),
        icon: DelveIcons.check,
        label: l.inboxDone,
        onSelected: () => unawaited(_done(i)),
      ),
    if (!open)
      DesktopMenuItem(
        key: const Key('inbox.menu.undo'),
        icon: DelveIcons.undo,
        label: l.chatsUndo,
        onSelected: () => unawaited(_undo(i.id)),
      ),
    if (i.approval case final a?)
      DesktopMenuItem(
        icon: DelveIcons.forum,
        label: l.approvalsOpenChat,
        onSelected: () => context.go(Routes.chat(a.conversationId)),
      ),
    if (i.hit case final h?)
      DesktopMenuItem(
        icon: DelveIcons.watches,
        label: l.inboxOpenWatch,
        onSelected: () => context.go(Routes.watchHit(h.slug, h.id)),
      ),
    if (i.story case final s?)
      DesktopMenuItem(
        icon: NewsIcons.news,
        label: l.inboxOpenInNews,
        onSelected: () => context.go(Routes.newsStory(s.id)),
      ),
    if (i.feed case final f?)
      DesktopMenuItem(
        icon: NewsIcons.failingFeeds,
        label: l.inboxOpenFeed,
        onSelected: () => context.go(Routes.newsFeed(f.id)),
      ),
    if (i.llamaSwitch != null)
      DesktopMenuItem(
        icon: DelveIcons.system,
        label: l.inboxOpenSystem,
        onSelected: () => context.go(Routes.system),
      ),
    if (i.schedule case final s?)
      DesktopMenuItem(
        icon: DelveIcons.schedules,
        label: l.inboxOpenSchedule,
        onSelected: () => context.go(Routes.schedule(s.id)),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final view = ref.watch(inboxProvider);
    _keys.register(
      this,
      ListCommands(
        next: () => _step(1),
        previous: () => _step(-1),
        archive: _doneOpenItem,
        undo: _undoLast,
      ),
    );
    _pageKeys.register(
      this,
      PageCommands(refresh: () => unawaited(_refresh())),
    );
    // “Cleared · Undo” for what was cleared from this window – from the
    // list, the content's Done or by showing a story
    ref.listen(inboxProvider.select((s) => s.cleared), (before, cleared) {
      // an Undo shortens the list; a clearing adds to it or moves an id to
      // its end
      if (before == null || cleared.isEmpty) return;
      if (cleared.length < before.length) return;
      if (cleared.length == before.length && cleared.last == before.last) {
        return;
      }
      final id = cleared.last;
      _snack(
        l.inboxCleared,
        action: SnackBarAction(
          label: l.chatsUndo,
          onPressed: () => unawaited(_undo(id)),
        ),
      );
    });

    final items = view.items;
    final done = view.done;
    final open = widget.selected;
    // an approval that left the list because it was answered – here or
    // anywhere – or lapsed says how it ended before its row goes
    final approvals = ref.watch(approvalInboxProvider).value;
    final openIds = {for (final i in items) i.id};
    final waiting = {
      for (final i in items)
        if (i.isApproval) i.subject,
    };
    for (final was in _approvalRows.values) {
      if (openIds.contains(was.id) || _leaving.containsKey(was.id)) continue;
      // pending → late: the same approval under its other id
      if (waiting.contains(was.subject)) continue;
      final row = approvals?.byId(was.subject)?.approval;
      if (row != null && !isAnswerable(row)) _leave(was, row);
    }
    _approvalRows = {
      for (final i in items)
        if (i.isApproval) i.id: i,
    };
    final rows = _withLeaving(items);
    // an open item under Done today shows its row
    final doneShown =
        done.isNotEmpty && (_doneOpen || done.any((i) => i.id == open));
    _order = [
      for (final i in rows) i.id,
      if (doneShown)
        for (final i in done) i.id,
    ];
    final at = open == null ? -1 : _order.indexOf(open);
    if (at >= 0) _lastAt = at;
    if (open == null) _lastAt = null;
    _ticking(items.any((i) => i.kind == InboxKind.approval));
    final now = DateTime.now();
    final error = view.error;

    final Widget body;
    if (view.inbox == null) {
      body = error == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(DelveTokens.space3),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  key: const Key('inbox.failed'),
                  kind: StatusKind.alert,
                  icon: DelveIcons.error,
                  text: l.inboxLoadFailed(apiErrorText(l, error)),
                  actionLabel: l.retry,
                  onAction: () => unawaited(_refresh()),
                ),
              ),
            );
    } else {
      body = ListView(
        key: const Key('inbox.list'),
        padding: const EdgeInsets.only(bottom: DelveTokens.space4),
        children: [
          if (rows.isEmpty)
            Padding(
              key: const Key('inbox.empty'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.inboxEmptyTitle, style: context.text.titleSmall),
                  if (done.firstOrNull?.doneAt case final last?) ...[
                    const SizedBox(height: DelveTokens.space1),
                    Text(
                      l.inboxLastCleared(clockTime(last, now)),
                      style: DelveDesktopText.rowSecondary.copyWith(
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          for (final i in rows)
            if (_leaving[i.id] case (_, final outcome)?)
              InboxRow(
                item: i,
                now: now,
                selected: i.id == open,
                outcome: outcome,
                onTap: () => _open(i.id),
              )
            else
              InboxRow(
                item: i,
                now: now,
                selected: i.id == open,
                onTap: () => _open(i.id),
                onDone: i.doneable ? () => unawaited(_done(i)) : null,
                menu: _menu(l, i, open: true),
              ),
          if (done.isNotEmpty)
            _DoneToday(
              count: done.length,
              open: doneShown,
              onTap: () => setState(() => _doneOpen = !doneShown),
            ),
          if (doneShown)
            for (final i in done)
              InboxRow(
                item: i,
                now: now,
                selected: i.id == open,
                cleared: true,
                onTap: () => _open(i.id),
                onUndo: () => unawaited(_undo(i.id)),
                menu: _menu(l, i, open: false),
              ),
        ],
      );
    }

    // a Scaffold: the list's own snackbars (Cleared · Undo) show in it
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: TopLevelPage(
        title: l.navInbox,
        background: cs.surfaceContainerLow,
        actions: [
          if (view.open > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                l.inboxOpen(view.open),
                key: const Key('inbox.count'),
                style: DelveDesktopText.meta.copyWith(color: muted),
              ),
            ),
          IconButton(
            key: const Key('inbox.refresh'),
            tooltip: l.desktopRefresh,
            onPressed: () => unawaited(_refresh()),
            icon: const SymbolIcon(
              DelveIcons.refresh,
              size: DelveDesktop.iconButtonIcon,
            ),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: body),
            const _KeyHints(),
          ],
        ),
      ),
    );
  }
}

/// The “Done today” eyebrow with its count: a click opens and closes the
/// section (it empties at midnight).
class _DoneToday extends StatelessWidget {
  const _DoneToday({
    required this.count,
    required this.open,
    required this.onTap,
  });

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = context.delve.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
      child: InkWell(
        key: const Key('inbox.doneToday'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
        child: SizedBox(
          height: DelveDesktop.inboxHintRow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.inboxDoneToday.toUpperCase()}  $count',
                    style: context.text.labelSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      color: muted,
                    ),
                  ),
                ),
                SymbolIcon(
                  open ? DelveIcons.expandLess : DelveIcons.expandMore,
                  size: DelveTokens.iconSm,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 30 px hint row at the foot of the list column: the Inbox's keys.
class _KeyHints extends StatelessWidget {
  const _KeyHints();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final style = DelveDesktopText.meta.copyWith(
      color: context.delve.textMuted,
    );
    Widget hint(List<String> keys, String what) => Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in keys) ...[KeyCap(k), const SizedBox(width: 3)],
          const SizedBox(width: 1),
          Text(what, style: style),
        ],
      ),
    );
    return Container(
      key: const Key('inbox.hints'),
      height: DelveDesktop.inboxHintRow,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant,
            width: DelveTokens.hairline,
          ),
        ),
      ),
      // a narrow list column cuts the row instead of wrapping it
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              hint(const ['J', 'K'], l.inboxHintMove),
              hint(const ['Enter'], l.inboxHintOpen),
              hint(const ['E'], l.inboxHintDone),
              hint(const ['Ctrl+Z'], l.inboxHintUndo),
            ],
          ),
        ),
      ),
    );
  }
}

/// An item in the Inbox's list column (Components “Inbox”): the kind's icon
/// in its colour; the kind's word and the time; the gist – a command in
/// mono, wrapping at spaces, never cut; where it comes from in one line (a
/// waiting approval starts with the agent's countdown; an answered one that
/// is leaving shows its status chip there). On hover Done (or Undo under
/// “Done today”, where the gist is muted and the last line says when it was
/// cleared).
class InboxRow extends ConsumerWidget {
  const InboxRow({
    super.key,
    required this.item,
    required this.now,
    required this.selected,
    required this.onTap,
    this.cleared = false,
    this.outcome,
    this.onDone,
    this.onUndo,
    this.menu = const [],
  });

  final InboxItem item;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  /// It is under “Done today”.
  final bool cleared;

  /// An approval that was answered (or lapsed) and is leaving the list:
  /// its last line is how it ended.
  final ApprovalRow? outcome;
  final VoidCallback? onDone;
  final VoidCallback? onUndo;
  final List<DesktopMenuItem> menu;

  /// Where it comes from, and what state it is in.
  (String, Color?) _source(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final source = item.source ?? '';
    String joined(List<String?> parts) =>
        parts.whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    if (cleared) {
      final at = item.doneAt;
      return (
        joined([if (at != null) l.inboxClearedAt(clockTime(at, now)), source]),
        null,
      );
    }
    if (item.approval case final a?) {
      if (item.kind == InboxKind.approval) {
        final left = a.hermesDeadline.difference(now);
        return (
          joined([
            l.approvalWaits(
              countdownText(left.isNegative ? Duration.zero : left),
            ),
            source,
          ]),
          d.warnFg,
        );
      }
      return (
        joined([l.desktopApprovalUntil(clockTime(a.expiresAt, now)), source]),
        null,
      );
    }
    if (item.hit case final h?) {
      return (joined([itemMeta(h), source]), null);
    }
    if (item.feed case final f?) {
      return (joined([source, l.newsFeedInRow(f.errorsInRow)]), null);
    }
    if (item.llamaSwitch case final sw?) {
      if (sw.state == 'down') return (l.inboxSwitchDown, null);
      final llama = ref.watch(systemProvider.select((v) => v.info?.llama));
      final from = llama?.presetText(sw.from) ?? sw.from;
      return (from == null ? '' : l.inboxSwitchBack(from), null);
    }
    if (item.schedule case final s?) {
      return (scheduleFailureText(l, s), null);
    }
    return (source, null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final look = inboxLook(context, item);
    final (source, sourceColor) = _source(context, ref);
    final at = item.at;

    // a must-read: its topic's name in the topic colour and the Must read tag
    final Widget word;
    if (item.story case final story?) {
      final topic = ref.watch(
        newsProvider.select((v) => v.topicName(story.topic)),
      );
      word = Row(
        children: [
          Flexible(
            child: Text(
              topic,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium!.copyWith(color: look.color),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(child: mustReadTag(context, story.topic)),
        ],
      );
    } else {
      word = Text(
        look.word,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.labelMedium!.copyWith(color: look.color),
      );
    }

    final gist = inboxGist(ref, item);

    return DesktopRowFrame(
      key: ValueKey('inbox.row.${item.id}'),
      selected: selected,
      onTap: onTap,
      actions: [
        if (onDone case final done?)
          DesktopRowAction(
            key: ValueKey('inbox.row.done.${item.id}'),
            icon: DelveIcons.check,
            tooltip: l.inboxDone,
            onPressed: done,
          ),
        if (onUndo case final undo?)
          DesktopRowAction(
            key: ValueKey('inbox.row.undo.${item.id}'),
            icon: DelveIcons.undo,
            tooltip: l.chatsUndo,
            onPressed: undo,
          ),
      ],
      menu: menu,
      moreTooltip: l.desktopRowMore,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SymbolIcon(
              look.icon,
              size: DelveDesktop.inboxIcon,
              filled: look.filled,
              color: cleared ? d.textMuted : look.color,
            ),
          ),
          const SizedBox(width: DelveDesktop.inboxIconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: word),
                    if (at != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          listTime(at, now),
                          style: DelveDesktopText.meta.copyWith(
                            color: d.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                if (item.isApproval)
                  Text(
                    displayCommand(gist),
                    key: ValueKey('inbox.row.gist.${item.id}'),
                    style: DelveText.mono.copyWith(
                      fontSize: 12.5,
                      height: 18 / 12.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  )
                else
                  Text(
                    gist,
                    key: ValueKey('inbox.row.gist.${item.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DelveDesktopText.rowTitle.copyWith(
                      fontWeight: cleared ? FontWeight.w400 : FontWeight.w600,
                      color: cleared ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                if (outcome case final a?) ...[
                  const SizedBox(height: 3),
                  Row(
                    key: ValueKey('inbox.row.outcome.${item.id}'),
                    children: [
                      switch (approvalOutcomeLook(l, a.status)) {
                        (final kind, final icon, final label) => StatusChip(
                          kind: kind,
                          icon: icon,
                          label: label,
                        ),
                      },
                      const SizedBox(width: DelveTokens.space2),
                      Flexible(
                        child: Text(
                          l.inboxLeaves,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DelveDesktopText.rowSecondary.copyWith(
                            color: d.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (source.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    source,
                    key: ValueKey('inbox.row.source.${item.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DelveDesktopText.rowSecondary.copyWith(
                      color: sourceColor ?? cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
