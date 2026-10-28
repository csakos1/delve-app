import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/models/models.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import '../sync/sync_providers.dart';
import 'session.dart';

/// How many hits the Dashboard card shows (design 21d).
const int kRecentHits = 3;

/// A hit with the name of its watch (Dashboard card).
@immutable
class RecentHit {
  const RecentHit(this.watchName, this.item);
  final String watchName;
  final WatchItem item;
}

/// The watch list (W3, design 21a) and the newest hits across watches (21d).
/// Kept in memory like the schedules: loaded over REST when a screen opens,
/// kept current by `watch.updated` / `watch.item`.
@immutable
class WatchesView {
  const WatchesView({this.items, this.recent, this.error});

  /// By name (null before the first answer); deleted watches are left out.
  final List<Watch>? items;

  /// The newest [kRecentHits] hits of all watches, newest first (null before
  /// they were loaded).
  final List<RecentHit>? recent;

  /// The last refresh failed (older data may still be shown).
  final Object? error;

  Watch? bySlug(String slug) {
    for (final w in items ?? const <Watch>[]) {
      if (w.slug == slug) return w;
    }
    return null;
  }

  int get active => (items ?? const <Watch>[]).where((w) => !w.paused).length;

  WatchesView copyWith({
    List<Watch>? items,
    List<RecentHit>? recent,
    Object? error,
  }) => WatchesView(
    items: items ?? this.items,
    recent: recent ?? this.recent,
    error: error ?? this.error,
  );
}

class WatchesController extends Notifier<WatchesView> {
  @override
  WatchesView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider); // another server starts empty
    if (engine != null) {
      final sub = engine.watchChanges.listen((change) {
        if (!ref.mounted) return;
        switch (change) {
          case WatchUpdated(:final watch):
            _put(watch);
          case WatchItemSeen(:final item):
            _seen(item);
        }
      });
      ref.onDispose(sub.cancel);
    }
    return const WatchesView();
  }

  DelveApi? get _api => ref.read(apiProvider);

  static List<Watch> _sorted(Iterable<Watch> items) =>
      items.toList()..sort((a, b) {
        final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return c != 0 ? c : a.slug.compareTo(b.slug);
      });

  void _put(Watch w) {
    final items = state.items;
    if (items == null) return; // the first load brings it
    final rest = items.where((i) => i.slug != w.slug);
    state = state.copyWith(
      items: _sorted(w.state == 'deleted' ? rest : [...rest, w]),
    );
  }

  void _seen(WatchItem item) {
    final recent = state.recent;
    if (recent == null) return;
    final others = recent.where((r) => r.item.id != item.id).toList();
    if (!item.isHit) {
      if (others.length != recent.length) {
        state = state.copyWith(recent: others);
      }
      return;
    }
    final name = state.bySlug(item.slug)?.name ?? item.slug;
    state = state.copyWith(recent: _newest([...others, RecentHit(name, item)]));
  }

  static List<RecentHit> _newest(List<RecentHit> hits) {
    hits.sort((a, b) {
      final c = b.item.seenAt.compareTo(a.item.seenAt);
      return c != 0 ? c : b.item.id.compareTo(a.item.id);
    });
    return hits.take(kRecentHits).toList();
  }

  /// Reloads the list and the newest hits; a failure is kept in
  /// [WatchesView.error] and rethrown.
  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    try {
      final items = _sorted(await api.watches());
      final hits = <RecentHit>[];
      for (final w in items.where((w) => w.hits > 0)) {
        try {
          final page = await api.watchItems(w.slug, limit: kRecentHits);
          hits.addAll([for (final i in page.items) RecentHit(w.name, i)]);
        } on Object {
          // one watch's hits missing does not hide the list
        }
      }
      if (ref.mounted) {
        state = WatchesView(items: items, recent: _newest(hits));
      }
    } on Object catch (e) {
      if (ref.mounted) state = state.copyWith(error: e);
      rethrow;
    }
  }

  /// Pause, resume or run now; the server's answer replaces the stored copy.
  Future<Watch> act(String slug, WatchAction action) async {
    final w = await _api!.watchAction(slug, action);
    if (ref.mounted) _put(w);
    return w;
  }
}

final watchesProvider = NotifierProvider<WatchesController, WatchesView>(
  WatchesController.new,
);

/// One watch's items (design 21b): hits and the rejected ones (with the
/// listings the judge could not decide), newest first, paged.
@immutable
class WatchItemsView {
  const WatchItemsView({
    this.hits,
    this.hitsNext,
    this.rejects,
    this.rejectsNext,
    this.error,
  });

  final List<WatchItem>? hits;

  /// Where the next page of hits starts (null = all loaded).
  final int? hitsNext;
  final List<WatchItem>? rejects;
  final int? rejectsNext;
  final Object? error;
}

/// Verdicts of the Rejected section: rejects and judge failures.
const List<String> kRejectVerdicts = ['reject', 'error'];

class WatchItemsController extends Notifier<WatchItemsView> {
  WatchItemsController(this.slug);

  final String slug;

  static const int pageSize = 30;

  @override
  WatchItemsView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider);
    if (engine != null) {
      final sub = engine.watchChanges.listen((change) {
        if (!ref.mounted) return;
        if (change case WatchItemSeen(:final item) when item.slug == slug) {
          _seen(item);
        }
      });
      ref.onDispose(sub.cancel);
    }
    return const WatchItemsView();
  }

  DelveApi? get _api => ref.read(apiProvider);

  static List<WatchItem> _byNewest(Iterable<WatchItem> items) =>
      items.toList()..sort((a, b) => b.id.compareTo(a.id));

  /// [more] added to [items], one per id (the newer copy wins).
  static List<WatchItem> _merged(
    List<WatchItem>? items,
    List<WatchItem> more,
  ) => _byNewest(
    {
      for (final i in items ?? const <WatchItem>[]) i.id: i,
      for (final i in more) i.id: i,
    }.values,
  );

  /// An item moves between the lists as it is judged (pending → match), and
  /// is upserted where it belongs; pending ones are only counted (the watch).
  void _seen(WatchItem item) {
    final hits = state.hits;
    final rejects = state.rejects;
    if (hits == null || rejects == null) return;
    final h = hits.where((i) => i.id != item.id);
    final r = rejects.where((i) => i.id != item.id);
    state = WatchItemsView(
      hits: _byNewest(item.isHit ? [...h, item] : h),
      hitsNext: state.hitsNext,
      rejects: _byNewest(
        kRejectVerdicts.contains(item.verdict) ? [...r, item] : r,
      ),
      rejectsNext: state.rejectsNext,
      error: state.error,
    );
  }

  /// The first page of both lists; a failure is kept and rethrown.
  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    try {
      final hits = await api.watchItems(slug, limit: pageSize);
      final rejects = await api.watchItems(
        slug,
        verdicts: kRejectVerdicts,
        limit: pageSize,
      );
      if (ref.mounted) {
        state = WatchItemsView(
          hits: hits.items,
          hitsNext: hits.nextBefore,
          rejects: rejects.items,
          rejectsNext: rejects.nextBefore,
        );
      }
    } on Object catch (e) {
      if (ref.mounted) {
        state = WatchItemsView(
          hits: state.hits,
          hitsNext: state.hitsNext,
          rejects: state.rejects,
          rejectsNext: state.rejectsNext,
          error: e,
        );
      }
      rethrow;
    }
  }

  /// The next page of hits ([rejected] = of the Rejected section).
  Future<void> loadMore({bool rejected = false}) async {
    final api = _api;
    final next = rejected ? state.rejectsNext : state.hitsNext;
    if (api == null || next == null) return;
    final page = await api.watchItems(
      slug,
      verdicts: rejected ? kRejectVerdicts : const ['hits'],
      before: next,
      limit: pageSize,
    );
    if (!ref.mounted) return;
    final s = state;
    state = rejected
        ? WatchItemsView(
            hits: s.hits,
            hitsNext: s.hitsNext,
            rejects: _merged(s.rejects, page.items),
            rejectsNext: page.nextBefore,
          )
        : WatchItemsView(
            hits: _merged(s.hits, page.items),
            hitsNext: page.nextBefore,
            rejects: s.rejects,
            rejectsNext: s.rejectsNext,
          );
  }
}

final watchItemsProvider =
    NotifierProvider.family<WatchItemsController, WatchItemsView, String>(
      WatchItemsController.new,
    );
