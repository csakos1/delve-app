import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/events.dart';
import '../api/models/models.dart';
import '../api/protocol.dart' show kInboxRevision;
import '../sync/sync_providers.dart';
import 'approvals.dart';
import 'news.dart';
import 'session.dart';

/// How often the Inbox is read again while the app runs: a story the model
/// scores into it (a must-read) comes without an event of its own, and an
/// item's 7 days run out silently.
const Duration kInboxPoll = Duration(minutes: 1);

/// The server has the Inbox (API 23, [kInboxRevision]); false until it has
/// answered once. Without it the desktop shows no Inbox at all.
final inboxSupportedProvider = Provider<bool>((ref) {
  final revision = ref.watch(
    sessionProvider.select(
      (s) => s is SessionPaired ? s.meta?.apiRevision : null,
    ),
  );
  return revision != null && revision >= kInboxRevision;
});

/// Where an item is now: in the list, under Done today, or neither (it was
/// answered, read, cleared on another day, or its cause is gone).
enum InboxPlace { open, done, gone }

/// The Inbox (L2e, I0): one list of what needs the reader. Kept in memory
/// like the watches – the server derives it from the tables that own the
/// things, a stored copy would only go stale.
@immutable
class InboxState {
  const InboxState({this.inbox, this.error, this.cleared = const []});

  /// The server's last answer (null before the first one).
  final Inbox? inbox;

  /// The last reload failed (an older [inbox] may still be shown).
  final Object? error;

  /// What was cleared from this window, the latest last (the list says
  /// “Cleared · Undo”, Ctrl+Z takes the last one back). The same list
  /// instance until it changes.
  final List<String> cleared;

  /// The open items, newest first.
  List<InboxItem> get items => inbox?.items ?? const <InboxItem>[];

  /// What was cleared today, the latest first.
  List<InboxItem> get done => inbox?.done ?? const <InboxItem>[];

  /// All open items: the one number of the rail's badge, the Inbox header,
  /// the status bar and the Dashboard block.
  int get open => inbox?.open ?? 0;

  /// How many of them are approvals that can be answered (the badge is warn
  /// while there is one).
  int get approvals => inbox?.approvals ?? 0;

  InboxItem? openItem(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  InboxItem? doneItem(String id) {
    for (final i in done) {
      if (i.id == id) return i;
    }
    return null;
  }

  InboxPlace placeOf(String id) => openItem(id) != null
      ? InboxPlace.open
      : doneItem(id) != null
      ? InboxPlace.done
      : InboxPlace.gone;

  /// What Ctrl+Z takes back: the item cleared last from this window that
  /// is still under Done today (null: none).
  String? get lastCleared {
    for (final id in cleared.reversed) {
      if (doneItem(id) != null) return id;
    }
    return null;
  }
}

/// Loads the Inbox over REST and reads it again when something may have
/// entered or left: `inbox.updated` (an item was cleared, here or on
/// another device), an approval that came or was answered, a watcher's
/// listing, a News round, a model switch, a schedule – and once a minute.
/// Clearing and taking back answer with the new view.
class InboxController extends Notifier<InboxState> {
  Timer? _soon;

  /// Answers of requests older than the last write are dropped.
  int _seq = 0;

  /// The failed switch the system view last showed (`state|at`).
  String? _switch;

  /// The last copy of every item seen while the app ran.
  final Map<String, InboxItem> _known = {};

  /// [InboxState.cleared]: replaced, never changed in place.
  List<String> _cleared = const [];

  @override
  InboxState build() {
    final supported = ref.watch(inboxSupportedProvider);
    ref.watch(apiProvider); // another server starts empty
    _known.clear();
    _cleared = const [];
    _switch = null;
    if (!supported) return const InboxState();

    final engine = ref.watch(syncEngineProvider);
    if (engine != null) {
      final subs = <StreamSubscription<Object?>>[
        engine.inboxUpdates.listen((_) => reloadSoon()),
        engine.watchChanges.listen((change) {
          if (change is WatchItemSeen) reloadSoon();
        }),
        engine.newsUpdates.listen((_) => reloadSoon()),
        engine.scheduleChanges.listen((_) => reloadSoon()),
        engine.systemUpdates.listen((info) {
          // the system view comes often; only a switch that failed (or was
          // dismissed) changes the Inbox
          final sw = info.llama.switchState;
          final now = sw == null ? '' : '${sw.state}|${sw.at}';
          if (now != _switch) {
            _switch = now;
            reloadSoon();
          }
        }),
      ];
      ref.onDispose(() {
        for (final s in subs) {
          unawaited(s.cancel());
        }
      });
    }
    // approvals reach the database with their own events
    ref
      ..listen(approvalInboxProvider, (before, now) {
        if (_waiting(before?.value) != _waiting(now.value)) reloadSoon();
      })
      // a story read anywhere in the app leaves the list
      ..listen(newsProvider.select((v) => v.latest), (_, latest) {
        final read = state.items.any(
          (i) => i.story != null && (latest[i.story!.id]?.read ?? false),
        );
        if (read) reloadSoon();
      });
    final poll = Timer.periodic(kInboxPoll, (_) => unawaited(_quiet()));
    ref.onDispose(() {
      poll.cancel();
      _soon?.cancel();
      _soon = null;
    });
    unawaited(
      Future<void>.microtask(() async {
        if (ref.mounted) await _quiet();
      }),
    );
    return const InboxState();
  }

  /// The approvals that can be answered, with their status (pending or
  /// late), in a fixed order.
  static String _waiting(ApprovalInbox? inbox) {
    if (inbox == null) return '';
    final rows = [
      for (final i in [...inbox.pending, ...inbox.expired])
        '${i.approval.requestId}:${i.approval.status}',
    ]..sort();
    return rows.join(',');
  }

  void _set(Inbox inbox) {
    for (final i in inbox.done) {
      _known[i.id] = i;
    }
    for (final i in inbox.items) {
      _known[i.id] = i;
    }
    state = InboxState(inbox: inbox, cleared: _cleared);
  }

  Future<void> _quiet() async {
    try {
      await refresh();
    } on Object {
      // kept in InboxState.error
    }
  }

  /// Reads the Inbox again shortly: events come in bursts (a watcher's
  /// round, an approval and its run).
  void reloadSoon() {
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 400), () {
      _soon = null;
      unawaited(_quiet());
    });
  }

  /// Reloads the view; a failure is kept in [InboxState.error] and
  /// rethrown.
  Future<void> refresh() async {
    final api = ref.read(apiProvider);
    if (api == null || !ref.read(inboxSupportedProvider)) return;
    final n = ++_seq;
    try {
      final inbox = await api.inbox();
      if (ref.mounted && n == _seq) _set(inbox);
    } on Object catch (e) {
      if (ref.mounted && n == _seq) {
        state = InboxState(inbox: state.inbox, error: e, cleared: _cleared);
      }
      rethrow;
    }
  }

  /// Clears the open item [id] (Done, E); the server's view replaces the
  /// list. False: it had left by itself meanwhile (answered, read, its
  /// cause gone) – the list is read again. Other errors are rethrown.
  Future<bool> done(String id) async {
    final api = ref.read(apiProvider);
    if (api == null) return false;
    final n = ++_seq;
    final Inbox inbox;
    try {
      inbox = await api.inboxDone(id);
    } on ApiRequestError catch (e) {
      if (e.code != 'inbox_item_not_found') rethrow;
      if (ref.mounted) reloadSoon();
      return false;
    }
    if (!ref.mounted) return true;
    _cleared = [
      for (final c in _cleared)
        if (c != id) c,
      id,
    ];
    if (n == _seq) {
      _set(inbox);
    } else {
      reloadSoon();
    }
    return true;
  }

  /// Takes the clearing of [id] back (Undo, Ctrl+Z): it shows again if it
  /// is still the case. A story that was read since is unread again – that
  /// is what bringing it back means.
  Future<void> undo(String id) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    final n = ++_seq;
    var inbox = await api.inboxUndo(id);
    final story = _known[id]?.story;
    if (story != null && inbox.items.every((i) => i.id != id)) {
      final unread = await api.markNews(story.id, read: false);
      if (!ref.mounted) return;
      ref.read(newsProvider.notifier).put(unread.item);
      inbox = await api.inbox();
    }
    if (!ref.mounted) return;
    _cleared = [
      for (final c in _cleared)
        if (c != id) c,
    ];
    if (n == _seq) {
      _set(inbox);
    } else {
      reloadSoon();
    }
  }

  /// The listing [id] was opened from its watch (the Watches area, the
  /// Dashboard's card): its hit leaves the Inbox, as with Open link there.
  /// Nothing happens when the Inbox does not hold it; a failure leaves it.
  Future<void> hitOpened(int id) async {
    final item = '${InboxKind.watchHit}:$id';
    if (state.openItem(item) == null) return;
    try {
      await done(item);
    } on Object {
      // it stays in the list
    }
  }

  /// The last copy of an item that was open or under Done today while the
  /// app ran – also after it left (the content keeps showing it).
  InboxItem? known(String id) => _known[id];
}

final inboxProvider = NotifierProvider<InboxController, InboxState>(
  InboxController.new,
);
