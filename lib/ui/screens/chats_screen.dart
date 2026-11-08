import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat_list.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/db/database.dart';
import '../../general/general_database.dart';
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
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
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
      await ref.read(chatListPagerProvider(false).notifier).refresh();
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsRefreshFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _loadMore() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(chatListPagerProvider(false).notifier).loadMore();
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsRefreshFailed(apiErrorText(l, e)));
    }
  }

  /// Archives first and lets the row go only when the server agreed.
  Future<bool> _archive(String id) async {
    final l = AppLocalizations.of(context);
    final pager = ref.read(chatListPagerProvider(false).notifier);
    try {
      await pager.setArchived(id, archived: true);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsArchiveFailed(apiErrorText(l, e)));
      return false;
    }
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
    await service.archive(id);
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
    final items = ref.watch(chatListProvider(false)).value;
    final status =
        ref.watch(connectionStatusProvider).value ?? ConnectionStatus.initial;
    final neverLoaded = ref.watch(
      syncStateProvider.select((s) => s.value?.lastSeq == null),
    );
    final paging = ref.watch(chatListPagerProvider(false));
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
        ref.watch(generalChatsProvider(false)).value ??
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

    final Widget body;
    if (skeleton) {
      body = const _SkeletonList();
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
      body = _EmptyState(onNewChat: () => context.push(Routes.newChat));
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
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          key: const Key('chats.list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96), // clear of the FAB
          itemCount: shown.length + (more ? 1 : 0),
          itemBuilder: (context, i) {
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
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _archiveGeneral(g.id),
                background: SwipeBackground(
                  icon: DelveIcons.archive,
                  label: l.chatsArchive,
                ),
                child: GeneralListRow(
                  chat: g,
                  modelName: modelShortName(g.modelId, models[g.modelId]),
                  onTap: () => context.push(Routes.generalChat(g.id)),
                ),
              );
            }
            final item = entry.agent!;
            final id = item.conversation.id;
            return Dismissible(
              key: ValueKey('chat.$id'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _archive(id),
              background: SwipeBackground(
                icon: DelveIcons.archive,
                label: l.chatsArchive,
              ),
              child: ChatRow(
                item: item,
                onTap: () => context.push(Routes.chat(id)),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: TopLevelPage(
        title: l.navChats,
        tintOnScroll: true,
        actions: [
          IconButton(
            key: const Key('chats.search'),
            tooltip: _searching ? l.chatsSearchClose : l.chatsSearch,
            onPressed: empty || skeleton ? null : _toggleSearch,
            icon: SymbolIcon(_searching ? DelveIcons.close : DelveIcons.search),
          ),
          _ApprovalsButton(pending: pending),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (skeleton || (status.resyncing && !retrying))
              const LinearProgressIndicator(key: Key('chats.progress'))
            else
              const SizedBox(height: 2),
            if (_searching)
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
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: empty
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
        onAction: () => context.push(Routes.connectionLog),
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
