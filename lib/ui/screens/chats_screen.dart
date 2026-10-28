import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat_list.dart';
import '../../app/router.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
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

    final connecting = switch (status.phase) {
      ConnectionPhase.connecting || ConnectionPhase.awaitingHello => true,
      ConnectionPhase.live => status.resyncing,
      _ => false,
    };
    final skeleton =
        items == null || (items.isEmpty && neverLoaded && connecting);
    final empty = !skeleton && items.isEmpty;
    final retrying =
        status.phase == ConnectionPhase.backoff ||
        ((status.phase == ConnectionPhase.connecting ||
                status.phase == ConnectionPhase.awaitingHello) &&
            status.attempt > 0);

    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final item in items ?? const <ChatListItem>[])
        if (query.isEmpty || _matches(item, query)) item,
    ];

    final Widget body;
    if (skeleton) {
      body = const _SkeletonList();
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
      final more =
          query.isEmpty &&
          !paging.exhausted &&
          shown.length >= ChatListPager.pageSize;
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
            final item = shown[i];
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
        actions: [
          IconButton(
            key: const Key('chats.search'),
            tooltip: _searching ? l.chatsSearchClose : l.chatsSearch,
            onPressed: empty || skeleton ? null : _toggleSearch,
            icon: SymbolIcon(_searching ? DelveIcons.close : DelveIcons.search),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (skeleton || (status.resyncing && !retrying))
              const LinearProgressIndicator(key: Key('chats.progress'))
            else
              const SizedBox(height: 2),
            if (retrying) _RetryBanner(status: status),
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
  const _RetryBanner({required this.status});

  final ConnectionStatus status;

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
        text: view.text,
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
