import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat_list.dart';
import '../../app/router.dart';
import '../../data/db/database.dart';
import '../../general/general_database.dart';
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../general/general_format.dart';
import '../general/general_widgets.dart';
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

  /// A General chat back to Chats (on this phone, nothing to wait for).
  Future<bool> _restoreGeneral(String id) async {
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
    final general =
        ref.watch(generalChatsProvider(true)).value ?? const <GeneralChatRow>[];
    final models = {
      for (final m
          in ref.watch(generalModelsProvider).value ?? const <OrModelRow>[])
        m.id: m,
    };
    // agent and General, newest first (General chats older than the agent
    // page loaded so far wait for the next page)
    final agentMore =
        items != null &&
        !paging.exhausted &&
        items.length >= ChatListPager.pageSize;
    final floor = agentMore && items.isNotEmpty
        ? items
              .map((i) => i.conversation.updatedAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final entries = <(DateTime, ChatListItem?, GeneralChatRow?)>[
      for (final i in items ?? const <ChatListItem>[])
        (i.conversation.updatedAt, i, null),
      for (final g in general)
        if (floor == null || !g.updatedAt.isBefore(floor))
          (g.updatedAt, null, g),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    final Widget body;
    if (entries.isEmpty &&
        (items == null || (items.isEmpty && paging.loading))) {
      body = const SizedBox.shrink();
    } else if (entries.isEmpty) {
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
      final more = agentMore;
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          key: const Key('archived.list'),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: entries.length + (more ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == entries.length) {
              return LoadMoreFooter(
                loading: paging.loading,
                onVisible: _loadMore,
              );
            }
            final (_, item, g) = entries[i];
            if (g != null) {
              return Dismissible(
                key: ValueKey('archived.general.${g.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _restoreGeneral(g.id),
                background: SwipeBackground(
                  icon: DelveIcons.unarchive,
                  label: l.archivedRestore,
                ),
                child: GeneralListRow(
                  chat: g,
                  modelName: modelShortName(g.modelId, models[g.modelId]),
                  onTap: () => context.push(Routes.generalChat(g.id)),
                ),
              );
            }
            final id = item!.conversation.id;
            return Dismissible(
              key: ValueKey('archived.$id'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _restore(id),
              background: SwipeBackground(
                icon: DelveIcons.unarchive,
                label: l.archivedRestore,
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
