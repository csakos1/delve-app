import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat_list.dart';
import '../../app/layout.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/db/database.dart';
import '../../general/general_database.dart';
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_row.dart';
import '../desktop/intake.dart';
import '../desktop/layers.dart';
import '../desktop/panes.dart' show KeyCap;
import '../format.dart';
import '../general/general_format.dart';
import '../general/general_widgets.dart';
import '../widgets/chat_row.dart';
import '../widgets/connection_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/skeleton.dart';
import '../widgets/status_ui.dart';

/// 02 Chats: the conversation list (02a), swipe to archive (02b), empty
/// (02c), reconnecting banner (02d) and the first-load skeleton (20a).
///
/// In the desktop layout it is the Chats list column (L2a): the open chat's
/// row is selected, New chat is a header button (no FAB), Approvals has its
/// own rail item, and Archived is the foot row – a filter of the list
/// (L2b2), with Unarchive (and Delete for General) on hover. J / K / ↓ / ↑
/// open the next / previous chat, E archives the open one, Ctrl+Z undoes.
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key, this.selected});

  /// The desktop's open chat: `c:<id>`, `g:<id>` or `new` (null: none).
  final String? selected;

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _search = TextEditingController();
  bool _searching = false;

  /// The desktop: the list shows the archived chats (the foot row, L2b2).
  bool _archived = false;

  /// The desktop's last archive, for Ctrl+Z: `c:<id>` or `g:<id>`.
  String? _undo;

  /// The rows as shown (`c:<id>` / `g:<id>`), for J / K.
  List<String> _rows = const [];

  late final ListCommandSlot _keys;
  late final ListCommands _commands = ListCommands(
    next: () => _step(1),
    previous: () => _step(-1),
    archive: _archiveOpen,
    undo: _undoArchive,
  );

  @override
  void initState() {
    super.initState();
    _keys = ref.read(listCommandSlotProvider);
  }

  @override
  void dispose() {
    _keys.unregister(this);
    _search.dispose();
    super.dispose();
  }

  bool get _inArchive => _archived && DesktopLayout.of(context);

  /// The chat a row key opens.
  static String _routeOf(String row) => row.startsWith('g:')
      ? Routes.generalChat(row.substring(2))
      : Routes.chat(row.substring(2));

  /// J / K: the next / previous row opens.
  void _step(int by) {
    if (_rows.isEmpty) return;
    final at = _rows.indexOf(widget.selected ?? '');
    final next = at < 0
        ? (by > 0 ? 0 : _rows.length - 1)
        : (at + by).clamp(0, _rows.length - 1);
    if (next != at) context.go(_routeOf(_rows[next]));
  }

  /// Where to go once [gone] has left the list (taken before it leaves):
  /// the row that takes its place, or the empty content.
  String _routeAfter(String gone) {
    final at = _rows.indexOf(gone);
    final rest = [..._rows]..remove(gone);
    if (rest.isEmpty || at < 0) return Routes.chats;
    return _routeOf(rest[at.clamp(0, rest.length - 1)]);
  }

  /// E: the open chat is archived.
  void _archiveOpen() {
    final open = widget.selected;
    if (_inArchive || open == null || !_rows.contains(open)) return;
    if (open.startsWith('g:')) {
      unawaited(_archiveGeneral(open.substring(2)));
    } else {
      unawaited(_archive(open.substring(2)));
    }
  }

  /// Ctrl+Z: the last archive is undone.
  void _undoArchive() {
    final row = _undo;
    if (row == null) return;
    _undo = null;
    final id = row.substring(2);
    if (row.startsWith('g:')) {
      unawaited(
        ref.read(generalChatServiceProvider).archive(id, archived: false),
      );
    } else {
      unawaited(_restore(ref.read(chatListPagerProvider(false).notifier), id));
    }
  }

  /// The foot row: the archive in the list, or back.
  void _toggleArchived() {
    setState(() => _archived = !_archived);
    if (_archived) unawaited(_refresh());
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) _search.clear();
  });

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

  Future<void> _refresh() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(chatListPagerProvider(_inArchive).notifier).refresh();
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsRefreshFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _loadMore() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(chatListPagerProvider(_inArchive).notifier).loadMore();
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsRefreshFailed(apiErrorText(l, e)));
    }
  }

  /// Archives first and lets the row go only when the server agreed.
  Future<bool> _archive(String id) async {
    final l = AppLocalizations.of(context);
    final pager = ref.read(chatListPagerProvider(false).notifier);
    final after = _routeAfter('c:$id');
    try {
      await pager.setArchived(id, archived: true);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsArchiveFailed(apiErrorText(l, e)));
      return false;
    }
    _archivedOnDesktop('c:$id', after);
    if (mounted) {
      _snack(
        l.chatsArchived,
        action: SnackBarAction(
          label: l.chatsUndo,
          onPressed: () => unawaited(_restore(pager, id)),
        ),
      );
    }
    return true;
  }

  /// A General chat is archived on this phone: nothing to wait for.
  Future<bool> _archiveGeneral(String id) async {
    final l = AppLocalizations.of(context);
    final service = ref.read(generalChatServiceProvider);
    final after = _routeAfter('g:$id');
    await service.archive(id);
    _archivedOnDesktop('g:$id', after);
    if (mounted) {
      _snack(
        l.chatsArchived,
        action: SnackBarAction(
          label: l.chatsUndo,
          onPressed: () => unawaited(service.archive(id, archived: false)),
        ),
      );
    }
    return true;
  }

  /// The desktop: Ctrl+Z can undo [row]'s archive; the open chat makes way
  /// for [after].
  void _archivedOnDesktop(String row, String after) {
    if (!mounted || !DesktopLayout.of(context)) return;
    _undo = row;
    if (widget.selected == row) context.go(after);
  }

  /// The archive (desktop): an agent chat back to the list.
  Future<void> _unarchive(String id) async {
    final l = AppLocalizations.of(context);
    final pager = ref.read(chatListPagerProvider(true).notifier);
    try {
      await pager.setArchived(id, archived: false);
    } on Exception catch (e) {
      if (mounted) _snack(l.archivedRestoreFailed(apiErrorText(l, e)));
      return;
    }
    if (mounted) {
      _snack(
        l.archivedRestored,
        action: SnackBarAction(
          label: l.chatsUndo,
          onPressed: () => unawaited(_archiveAgain(pager, id)),
        ),
      );
    }
  }

  Future<void> _archiveAgain(ChatListPager pager, String id) async {
    final l = AppLocalizations.of(context);
    try {
      await pager.setArchived(id, archived: true);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsArchiveFailed(apiErrorText(l, e)));
    }
  }

  /// The archive (desktop): a General chat back to the list.
  Future<void> _unarchiveGeneral(String id) async {
    final l = AppLocalizations.of(context);
    final service = ref.read(generalChatServiceProvider);
    await service.archive(id, archived: false);
    if (mounted) {
      _snack(
        l.archivedRestored,
        action: SnackBarAction(
          label: l.chatsUndo,
          onPressed: () => unawaited(service.archive(id)),
        ),
      );
    }
  }

  /// The archive (desktop): a General chat deleted, after the dialog.
  Future<void> _deleteGeneral(GeneralChatRow g) async {
    final l = AppLocalizations.of(context);
    final ok = await showDesktopConfirm(
      context,
      title: l.generalDeleteTitle,
      body: l.generalDeleteBody,
      action: l.generalMenuDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final after = _routeAfter('g:${g.id}');
    await ref.read(generalChatServiceProvider).deleteChat(g.id);
    if (!mounted) return;
    if (widget.selected == 'g:${g.id}') context.go(after);
    _snack(l.generalDeleted);
  }

  void _setFilter(ChatsFilter f) => unawaited(
    ref
        .read(generalDatabaseProvider)
        .setMeta(GeneralMetaKeys.chatsFilter, f.name),
  );

  Future<void> _restore(ChatListPager pager, String id) async {
    final l = AppLocalizations.of(context);
    try {
      await pager.setArchived(id, archived: false);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsArchiveFailed(apiErrorText(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final desktop = DesktopLayout.of(context);
    if (desktop) {
      // Ctrl+F (L2b): the search field opens
      ref.listen(desktopFindProvider, (_, _) {
        if (!_searching) _toggleSearch();
      });
    }
    final archive = desktop && _archived;
    if (desktop) _keys.register(this, _commands);
    final items = ref.watch(chatListProvider(archive)).value;
    final status =
        ref.watch(connectionStatusProvider).value ?? ConnectionStatus.initial;
    final neverLoaded = ref.watch(
      syncStateProvider.select((s) => s.value?.lastSeq == null),
    );
    final paging = ref.watch(chatListPagerProvider(archive));
    final pending = ref.watch(answerableApprovalCountProvider).value ?? 0;
    // General (24): its chats live on this phone; the filter chips show
    // once a key is saved
    final hasKey = ref.watch(generalKeyProvider).value != null;
    final filter = hasKey
        ? chatsFilterOf(
            ref.watch(generalMetaProvider(GeneralMetaKeys.chatsFilter)).value,
          )
        : ChatsFilter.all;
    final general =
        ref.watch(generalChatsProvider(archive)).value ??
        const <GeneralChatRow>[];
    final models = {
      for (final m
          in ref.watch(generalModelsProvider).value ?? const <OrModelRow>[])
        m.id: m,
    };

    final connecting = switch (status.phase) {
      ConnectionPhase.connecting || ConnectionPhase.awaitingHello => true,
      ConnectionPhase.live => status.resyncing,
      _ => false,
    };
    final agentItems = filter == ChatsFilter.general
        ? const <ChatListItem>[]
        : items ?? const <ChatListItem>[];
    final generalItems = filter == ChatsFilter.agent
        ? const <GeneralChatRow>[]
        : general;
    final agentMore =
        !paging.exhausted && agentItems.length >= ChatListPager.pageSize;
    final skeleton =
        !archive &&
        filter != ChatsFilter.general &&
        generalItems.isEmpty &&
        (items == null || (items.isEmpty && neverLoaded && connecting));
    final empty = !skeleton && agentItems.isEmpty && generalItems.isEmpty;
    final retrying =
        status.phase == ConnectionPhase.backoff ||
        ((status.phase == ConnectionPhase.connecting ||
                status.phase == ConnectionPhase.awaitingHello) &&
            status.attempt > 0);

    final query = _search.text.trim().toLowerCase();
    // while older agent pages are still to come, General chats older than
    // the oldest loaded agent chat wait for them (the list stays in order)
    final floor = agentMore && agentItems.isNotEmpty
        ? agentItems
              .map((i) => i.conversation.updatedAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final shown = <_Entry>[
      for (final item in agentItems)
        if (query.isEmpty || _matches(item, query)) _Entry.agent(item),
      for (final g in generalItems)
        if ((floor == null || !g.updatedAt.isBefore(floor)) &&
            (query.isEmpty || _matchesGeneral(g, query)))
          _Entry.general(g),
    ]..sort((a, b) => b.at.compareTo(a.at));
    _rows = [
      for (final e in shown)
        if (e.general case final g?)
          'g:${g.id}'
        else
          'c:${e.agent!.conversation.id}',
    ];
    // the desktop's new chat: a draft row on top (27W-2h)
    final draft = desktop && !archive && widget.selected == 'new';

    final Widget body;
    if (skeleton) {
      body = const _SkeletonList();
    } else if (archive && items == null) {
      // the archive's first page is on its way
      body = const SizedBox.shrink();
    } else if (desktop && empty && !draft) {
      // the desktop's compact empty states (27W-2b)
      body = archive
          ? _DesktopEmpty(
              icon: DelveIcons.archive,
              title: l.desktopArchivedEmpty,
            )
          : filter == ChatsFilter.general
          ? _DesktopEmpty(icon: DelveIcons.cloud, title: l.chatsGeneralEmpty)
          : _DesktopEmpty(
              icon: DelveIcons.forum,
              title: l.chatsEmptyTitle,
              newChat: true,
            );
    } else if (desktop && shown.isEmpty && !draft) {
      body = _DesktopEmpty(
        icon: DelveIcons.search,
        title: l.chatsNoMatch(_search.text.trim()),
      );
    } else if (empty && filter == ChatsFilter.general) {
      body = Center(
        child: Text(
          l.chatsGeneralEmpty,
          key: const Key('chats.generalEmpty'),
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    } else if (empty) {
      body = _EmptyState(onNewChat: () => context.open(Routes.newChat));
    } else if (shown.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(DelveTokens.space6),
          child: Text(
            l.chatsNoMatch(_search.text.trim()),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      final more = query.isEmpty && agentMore;
      final lead = draft ? 1 : 0;
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          key: const Key('chats.list'),
          physics: const AlwaysScrollableScrollPhysics(),
          // clear of the FAB (none on the desktop)
          padding: EdgeInsets.only(bottom: desktop ? DelveTokens.space2 : 96),
          itemCount: lead + shown.length + (more ? 1 : 0),
          itemBuilder: (context, index) {
            if (draft && index == 0) return const _DraftRow();
            final i = index - lead;
            if (i == shown.length) {
              return LoadMoreFooter(
                loading: paging.loading,
                onVisible: _loadMore,
              );
            }
            final entry = shown[i];
            final g = entry.general;
            if (g != null) {
              return Dismissible(
                key: ValueKey('general.${g.id}'),
                // a mouse archives with the hover action instead
                direction: desktop
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                confirmDismiss: (_) => _archiveGeneral(g.id),
                background: SwipeBackground(
                  icon: DelveIcons.archive,
                  label: l.chatsArchive,
                ),
                child: GeneralListRow(
                  chat: g,
                  modelName: modelShortName(g.modelId, models[g.modelId]),
                  selected: widget.selected == 'g:${g.id}',
                  onArchive: desktop && !archive
                      ? () => unawaited(_archiveGeneral(g.id))
                      : null,
                  onUnarchive: archive
                      ? () => unawaited(_unarchiveGeneral(g.id))
                      : null,
                  onDelete: archive ? () => unawaited(_deleteGeneral(g)) : null,
                  onTap: () => context.open(Routes.generalChat(g.id)),
                ),
              );
            }
            final item = entry.agent!;
            final id = item.conversation.id;
            return Dismissible(
              key: ValueKey('chat.$id'),
              direction: desktop
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              confirmDismiss: (_) => _archive(id),
              background: SwipeBackground(
                icon: DelveIcons.archive,
                label: l.chatsArchive,
              ),
              child: ChatRow(
                item: item,
                selected: widget.selected == 'c:$id',
                onArchive: desktop && !archive
                    ? () => unawaited(_archive(id))
                    : null,
                onUnarchive: archive ? () => unawaited(_unarchive(id)) : null,
                onTap: () => context.open(Routes.chat(id)),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: desktop ? cs.surfaceContainerLow : null,
      body: TopLevelPage(
        title: archive ? l.moreArchived : l.navChats,
        tintOnScroll: true,
        background: desktop ? cs.surfaceContainerLow : null,
        actions: [
          IconButton(
            key: const Key('chats.search'),
            tooltip: _searching ? l.chatsSearchClose : l.chatsSearch,
            onPressed: (empty && !desktop) || skeleton ? null : _toggleSearch,
            icon: SymbolIcon(_searching ? DelveIcons.close : DelveIcons.search),
          ),
          if (desktop)
            IconButton(
              key: const Key('chats.new'),
              tooltip: l.newChat,
              onPressed: () => context.open(Routes.newChat),
              icon: const SymbolIcon(DelveIcons.edit),
            )
          else
            _ApprovalsButton(pending: pending),
        ],
        // the progress line, the search field, the chips and the banner stay
        // put: in the header, which tints while the list scrolls
        below: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (skeleton || (status.resyncing && !retrying))
              const LinearProgressIndicator(key: Key('chats.progress'))
            else
              const SizedBox(height: 2),
            if (_searching && desktop)
              _DesktopSearchField(
                controller: _search,
                onChanged: () => setState(() {}),
                onClose: _toggleSearch,
              )
            else if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DelveTokens.space4,
                  DelveTokens.space2,
                  DelveTokens.space4,
                  DelveTokens.space2,
                ),
                child: TextField(
                  key: const Key('chats.searchField'),
                  controller: _search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l.chatsSearchHint,
                    prefixIcon: const SymbolIcon(
                      DelveIcons.search,
                      size: DelveTokens.iconMd,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            if (hasKey) ChatsFilterChips(value: filter, onChanged: _setFilter),
            if (retrying && filter != ChatsFilter.general)
              _RetryBanner(status: status, generalWorks: hasKey),
          ],
        ),
        child: desktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: body),
                  _ArchivedRow(selected: archive, onTap: _toggleArchived),
                ],
              )
            : body,
      ),
      floatingActionButton: empty || desktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newChat),
              icon: const SymbolIcon(DelveIcons.edit),
              label: Text(l.newChat),
            ),
    );
  }

  static bool _matchesGeneral(GeneralChatRow g, String query) => [
    g.title,
    g.preview,
  ].any((s) => s != null && s.toLowerCase().contains(query));

  static bool _matches(ChatListItem item, String query) {
    final c = item.conversation;
    return [
      c.title,
      item.firstUserText,
      item.lastText,
      item.approvalCommand,
    ].any((s) => s != null && s.toLowerCase().contains(query));
  }
}

/// 02d: the socket keeps failing; "Details" opens the connection log.
class _RetryBanner extends StatelessWidget {
  const _RetryBanner({required this.status, this.generalWorks = false});

  final ConnectionStatus status;

  /// General chats do not need the desktop (24a): the banner says so.
  final bool generalWorks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ConnectionView.of(l, status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        DelveTokens.space2,
        DelveTokens.space4,
        DelveTokens.space2,
      ),
      child: StatusBanner(
        key: const Key('chats.banner'),
        kind: StatusKind.warn,
        icon: view.icon,
        text: generalWorks ? '${view.text} ${l.chatsGeneralWorks}' : view.text,
        actionLabel: l.chatsDetails,
        onAction: () => context.open(Routes.connectionLog),
      ),
    );
  }
}

/// The desktop list column's foot (L2a): Archived chats – a filter of the
/// list (L2b2), `surface-3` while it is on.
class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return Material(
      color: selected ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
      child: InkWell(
        key: const Key('chats.archived'),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant,
                width: DelveTokens.hairline,
              ),
            ),
          ),
          child: Row(
            children: [
              SymbolIcon(
                DelveIcons.archive,
                size: DelveTokens.iconSm,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: DelveTokens.space2),
              Text(
                l.moreArchived,
                style: DelveDesktopText.control.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The desktop list column's empty states (27W-2b): no chats, a filter or
/// a search with nothing in it, the empty archive – an icon and a line,
/// New chat with its key where it helps.
class _DesktopEmpty extends StatelessWidget {
  const _DesktopEmpty({
    required this.icon,
    required this.title,
    this.newChat = false,
  });

  final IconData icon;
  final String title;
  final bool newChat;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      key: const Key('chats.desktopEmpty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DelveTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(icon, size: 30, color: context.delve.textDisabled),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleSmall,
            ),
            if (newChat) ...[
              const SizedBox(height: DelveTokens.space3),
              FilledButton.tonal(
                key: const Key('chats.emptyNew'),
                onPressed: () => context.open(Routes.newChat),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.newChat),
                    const SizedBox(width: DelveTokens.space2),
                    KeyCap(l.desktopKeyNewChat),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The desktop's new chat in the list (27W-2h): a selected draft row on top
/// until its first message makes it a chat.
class _DraftRow extends StatelessWidget {
  const _DraftRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return DesktopRowFrame(
      key: const Key('chats.row.draft'),
      selected: true,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.newChat,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DelveDesktopText.rowTitle.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            l.desktopDraft,
            style: DelveDesktopText.rowSecondary.copyWith(
              color: context.delve.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The desktop list's search (Ctrl+F): a 36 px field under the header; Esc
/// closes it.
class _DesktopSearchField extends StatefulWidget {
  const _DesktopSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  @override
  State<_DesktopSearchField> createState() => _DesktopSearchFieldState();
}

class _DesktopSearchFieldState extends State<_DesktopSearchField> {
  final FocusNode _focus = FocusNode(debugLabel: 'chats.search');

  @override
  void initState() {
    super.initState();
    // the shell holds the focus: asked for, not autofocus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        },
        child: SizedBox(
          height: 36,
          child: TextField(
            key: const Key('chats.searchField'),
            controller: widget.controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            style: context.text.bodyMedium,
            onChanged: (_) => widget.onChanged(),
            decoration: InputDecoration(
              isDense: true,
              hintText: l.chatsSearchHint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              prefixIcon: const SymbolIcon(DelveIcons.search, size: 16),
              prefixIconConstraints: const BoxConstraints(minWidth: 32),
              filled: true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DelveDesktop.buttonRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 02c.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNewChat});

  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DelveTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(
              DelveIcons.forum,
              size: 40,
              color: context.delve.textMuted,
            ),
            const SizedBox(height: DelveTokens.space4),
            Text(
              l.chatsEmptyTitle,
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: DelveTokens.space2),
            Text(
              l.chatsEmptyBody,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DelveTokens.space6),
            FilledButton.icon(
              key: const Key('chats.emptyNew'),
              onPressed: onNewChat,
              icon: const SymbolIcon(DelveIcons.edit, size: DelveTokens.iconMd),
              label: Text(l.newChat),
            ),
          ],
        ),
      ),
    );
  }
}

/// 20a: seven placeholder rows.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  static const _titles = <double>[230, 150, 205, 125, 215, 170, 140];
  static const _previews = <double>[340, 310, 280, 350, 255, 325, 270];

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SkeletonPulse(
      child: ListView(
        key: const Key('chats.skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < _titles.length; i++)
            Container(
              margin: const EdgeInsets.only(left: DelveTokens.space4),
              padding: const EdgeInsets.fromLTRB(
                0,
                DelveTokens.space4,
                DelveTokens.space4,
                DelveTokens.space3,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant,
                    width: DelveTokens.hairline,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SkeletonBlock(width: _titles[i], height: 12),
                        ),
                      ),
                      const SizedBox(width: DelveTokens.space3),
                      const SkeletonBlock(width: 32, height: 10),
                    ],
                  ),
                  const SizedBox(height: DelveTokens.space3),
                  FractionallySizedBox(
                    widthFactor: _previews[i] / 416,
                    child: const SkeletonBlock(
                      width: double.infinity,
                      height: 10,
                      strong: false,
                    ),
                  ),
                  const SizedBox(height: DelveTokens.space3),
                  const SkeletonBlock(width: 96, height: 2, strong: false),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The Approvals inbox (11) from the Chats header, with the waiting count.
class _ApprovalsButton extends StatelessWidget {
  const _ApprovalsButton({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final icon = SymbolIcon(DelveIcons.approvals, filled: pending > 0);
    return IconButton(
      key: const Key('chats.approvals'),
      tooltip: pending > 0
          ? '${l.navApprovals}, ${l.approvalsBadge(pending)}'
          : l.navApprovals,
      onPressed: () => context.push(Routes.approvals),
      icon: pending > 0
          ? Badge(
              key: const Key('chats.approvals.badge'),
              label: Text('$pending'),
              backgroundColor: context.delve.warnFg,
              textColor: context.colors.onTertiary,
              textStyle: context.text.labelSmall,
              largeSize: DelveTokens.approvalsBadge,
              child: icon,
            )
          : icon,
    );
  }
}

/// One row of the Chats list: an agent conversation or a General chat.
class _Entry {
  _Entry.agent(ChatListItem this.agent)
    : general = null,
      at = agent.conversation.updatedAt;
  _Entry.general(GeneralChatRow this.general)
    : agent = null,
      at = general.updatedAt;

  final ChatListItem? agent;
  final GeneralChatRow? general;
  final DateTime at;
}
