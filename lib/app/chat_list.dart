import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/rest_client.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';
import 'providers.dart';
import 'session.dart';

/// The conversation list as the database has it (decision 168: the screen
/// only watches the database; the resync and the pager write it). The
/// argument picks the archived conversations (More → Archived chats).
final chatListProvider = StreamProvider.family<List<ChatListItem>, bool>(
  (ref, archived) =>
      ref.watch(databaseProvider).watchChatList(archived: archived),
);

/// Where the event stream stands (the skeleton shows until the first load).
final syncStateProvider = StreamProvider<SyncStateRow>(
  (ref) => ref.watch(databaseProvider).watchSyncState(),
);

/// Paging state of a conversation list. For the active list the first page
/// arrives with every resync; older pages only when the user scrolls to the
/// end. Archived conversations are never part of a resync: their screen
/// loads the first page when it opens.
class ChatListPaging {
  const ChatListPaging({
    this.loading = false,
    this.fetched = false,
    this.cursor,
  });

  /// A request is in flight.
  final bool loading;

  /// This pager has fetched the first page itself (and so knows [cursor]).
  final bool fetched;

  /// The next page; null after [fetched] = no more pages.
  final String? cursor;

  bool get exhausted => fetched && cursor == null;
}

class ChatListPager extends Notifier<ChatListPaging> {
  ChatListPager(this.archived);

  /// Which list this pager loads.
  final bool archived;

  /// Page size of `GET /conversations` (the resync loads one such page).
  static const int pageSize = 50;

  @override
  ChatListPaging build() {
    ref.watch(apiProvider); // a new pairing starts over
    return const ChatListPaging();
  }

  DelveApi? get _api => ref.read(apiProvider);

  /// Pull to refresh: the first page again. Throws [ApiError].
  Future<void> refresh() async {
    if (state.loading) return;
    await _fetch(null);
  }

  /// The next older page; fetches the first page first when this pager has
  /// not seen it (the resync does not keep the cursor). Throws [ApiError].
  Future<void> loadMore() async {
    if (state.loading || state.exhausted) return;
    if (!state.fetched) await _fetch(null);
    final cursor = state.cursor;
    if (cursor == null || !ref.mounted) return;
    await _fetch(cursor);
  }

  Future<void> _fetch(String? cursor) async {
    final api = _api;
    if (api == null) return;
    state = ChatListPaging(
      loading: true,
      fetched: state.fetched,
      cursor: state.cursor,
    );
    try {
      final page = await api.conversations(
        limit: pageSize,
        cursor: cursor,
        archived: archived,
      );
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        for (final c in page.conversations) {
          await db.putConversation(c);
        }
      });
      if (!ref.mounted) return;
      state = ChatListPaging(fetched: true, cursor: page.nextCursor);
    } catch (_) {
      if (ref.mounted) {
        state = ChatListPaging(fetched: state.fetched, cursor: state.cursor);
      }
      rethrow;
    }
  }

  /// Archives or restores a conversation over REST and stores the answer, so
  /// the row leaves (or rejoins) the list at once. Throws [ApiError].
  Future<void> setArchived(
    String conversationId, {
    required bool archived,
  }) async {
    final api = _api;
    if (api == null) return;
    final c = await api.patchConversation(conversationId, archived: archived);
    await ref.read(databaseProvider).putConversation(c);
  }
}

final chatListPagerProvider =
    NotifierProvider.family<ChatListPager, ChatListPaging, bool>(
      ChatListPager.new,
    );
