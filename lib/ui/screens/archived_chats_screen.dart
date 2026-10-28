import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat_list.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/chat_row.dart';
import '../widgets/page_scaffolds.dart';

/// More → Archived chats: archived conversations, newest first. They are not
/// part of a resync, so the screen loads the first page when it opens; a
/// swipe restores a chat to the Chats list.
class ArchivedChatsScreen extends ConsumerStatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  ConsumerState<ArchivedChatsScreen> createState() =>
      _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends ConsumerState<ArchivedChatsScreen> {
  ChatListPager get _pager => ref.read(chatListPagerProvider(true).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
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

  Future<void> _refresh() async {
    final l = AppLocalizations.of(context);
    try {
      await _pager.refresh();
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsRefreshFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _loadMore() async {
    final l = AppLocalizations.of(context);
    try {
      await _pager.loadMore();
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsRefreshFailed(apiErrorText(l, e)));
    }
  }

  /// Restores first and lets the row go only when the server agreed.
  Future<bool> _restore(String id) async {
    final l = AppLocalizations.of(context);
    final pager = _pager;
    try {
      await pager.setArchived(id, archived: false);
    } on Exception catch (e) {
      if (mounted) _snack(l.archivedRestoreFailed(apiErrorText(l, e)));
      return false;
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
    return true;
  }

  Future<void> _archiveAgain(ChatListPager pager, String id) async {
    final l = AppLocalizations.of(context);
    try {
      await pager.setArchived(id, archived: true);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsArchiveFailed(apiErrorText(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(chatListProvider(true)).value;
    final paging = ref.watch(chatListPagerProvider(true));

    final Widget body;
    if (items == null || (items.isEmpty && paging.loading)) {
      body = const SizedBox.shrink();
    } else if (items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(DelveTokens.space8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SymbolIcon(
                DelveIcons.archive,
                size: 40,
                color: context.delve.textMuted,
              ),
              const SizedBox(height: DelveTokens.space4),
              Text(
                l.archivedEmpty,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final more = !paging.exhausted && items.length >= ChatListPager.pageSize;
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          key: const Key('archived.list'),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (more ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == items.length) {
              return LoadMoreFooter(
                loading: paging.loading,
                onVisible: _loadMore,
              );
            }
            final id = items[i].conversation.id;
            return Dismissible(
              key: ValueKey('archived.$id'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _restore(id),
              background: SwipeBackground(
                icon: DelveIcons.unarchive,
                label: l.archivedRestore,
              ),
              child: ChatRow(
                item: items[i],
                onTap: () => context.push(Routes.chat(id)),
              ),
            );
          },
        ),
      );
    }

    return SubPage(
      title: l.moreArchived,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paging.loading)
            const LinearProgressIndicator(key: Key('archived.progress'))
          else
            const SizedBox(height: 2),
          Expanded(child: body),
        ],
      ),
    );
  }
}
