import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import '../api/rest_client.dart';
import '../sync/sync_providers.dart';
import 'session.dart';

/// News (N2): the Dashboard block and the News page's All view, kept in
/// memory like the watches - loaded over REST when a screen opens, reloaded
/// on `news.updated`. [latest] holds the newest copy of every story the app
/// marked (read, saved, feedback) or opened, so a list shows the change
/// without reloading.
@immutable
class NewsView {
  const NewsView({
    this.digest,
    this.sections,
    this.latest = const {},
    this.error,
  });

  final NewsDigest? digest;

  /// The topics that are on, in their order (null before the first answer).
  final List<NewsSection>? sections;
  final Map<int, NewsItem> latest;

  /// The last refresh failed (older data may still be shown).
  final Object? error;

  /// [item] as the app last saw it.
  NewsItem current(NewsItem item) => latest[item.id] ?? item;

  /// The topic's name (its id, tidied, while the sections are not loaded).
  String topicName(String? id) {
    if (id == null) return '';
    for (final s in sections ?? const <NewsSection>[]) {
      if (s.topic == id) return s.name;
    }
    final words = id.replaceAll('_', ' ');
    return words.isEmpty ? id : words[0].toUpperCase() + words.substring(1);
  }

  NewsView copyWith({
    NewsDigest? digest,
    List<NewsSection>? sections,
    Map<int, NewsItem>? latest,
    Object? error,
    bool clearError = false,
  }) => NewsView(
    digest: digest ?? this.digest,
    sections: sections ?? this.sections,
    latest: latest ?? this.latest,
    error: clearError ? null : error ?? this.error,
  );
}

class NewsController extends Notifier<NewsView> {
  @override
  NewsView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider); // another server starts empty
    if (engine != null) {
      final sub = engine.newsUpdates.listen((_) {
        if (!ref.mounted) return;
        // a new round or new texts: what is shown is reloaded quietly
        if (state.digest != null) unawaited(_quiet(refreshDigest));
        if (state.sections != null) unawaited(_quiet(refreshSections));
      });
      ref.onDispose(sub.cancel);
    }
    return const NewsView();
  }

  DelveApi? get _api => ref.read(apiProvider);

  static Future<void> _quiet(Future<void> Function() f) async {
    try {
      await f();
    } on Object {
      // kept in NewsView.error
    }
  }

  /// The Dashboard block; a failure is kept and rethrown.
  Future<void> refreshDigest() async {
    final api = _api;
    if (api == null) return;
    try {
      final d = await api.newsDigest();
      if (ref.mounted) state = state.copyWith(digest: d, clearError: true);
    } on Object catch (e) {
      if (ref.mounted) state = state.copyWith(error: e);
      rethrow;
    }
  }

  /// The All view's sections (also the topic names and the chips).
  Future<void> refreshSections() async {
    final api = _api;
    if (api == null) return;
    try {
      final s = await api.newsSections();
      if (ref.mounted) state = state.copyWith(sections: s, clearError: true);
    } on Object catch (e) {
      if (ref.mounted) state = state.copyWith(error: e);
      rethrow;
    }
  }

  /// Both, for the Dashboard and the News page.
  Future<void> refresh() async {
    await Future.wait([refreshDigest(), refreshSections()]);
  }

  /// The server's newest copy of a story; a story read now leaves the
  /// Dashboard block at the next reload.
  void put(NewsItem item) {
    final before = state.latest[item.id];
    state = state.copyWith(latest: {...state.latest, item.id: item});
    final digest = state.digest;
    if (item.read &&
        before?.read != true &&
        digest != null &&
        digest.top.any((t) => t.id == item.id)) {
      unawaited(_quiet(refreshDigest));
    }
  }

  /// Read / saved / feedback of [item]; the answer replaces the copy.
  Future<NewsStory> mark(
    NewsItem item, {
    bool? read,
    bool? saved,
    String? feedback,
    bool clearFeedback = false,
  }) async {
    final story = await _api!.markNews(
      item.id,
      read: read,
      saved: saved,
      feedback: feedback,
      clearFeedback: clearFeedback,
    );
    if (ref.mounted) put(story.item);
    return story;
  }

  /// "Hide this source": the feed off (or on again for Undo); the lists
  /// reload without it.
  Future<void> setSource(String sourceId, {required bool enabled}) async {
    await _api!.setNewsSource(sourceId, enabled: enabled);
    if (ref.mounted) unawaited(_quiet(refresh));
  }
}

final newsProvider = NotifierProvider<NewsController, NewsView>(
  NewsController.new,
);

/// Which list of the News page: one topic's stories, the saved ones, or
/// last week's unopened best ones.
@immutable
class NewsListKey {
  const NewsListKey.topic(String this.topic) : saved = false, weekly = false;
  const NewsListKey.saved() : topic = null, saved = true, weekly = false;
  const NewsListKey.weekly() : topic = null, saved = false, weekly = true;

  final String? topic;
  final bool saved;
  final bool weekly;

  @override
  bool operator ==(Object other) =>
      other is NewsListKey &&
      other.topic == topic &&
      other.saved == saved &&
      other.weekly == weekly;

  @override
  int get hashCode => Object.hash(topic, saved, weekly);
}

@immutable
class NewsListView {
  const NewsListView({this.items, this.next, this.error});

  /// Newest first (weekly: best first); null before the first answer.
  final List<NewsItem>? items;

  /// Where the next page starts (null = all loaded).
  final int? next;
  final Object? error;
}

/// One list of the News page, paged.
class NewsListController extends Notifier<NewsListView> {
  NewsListController(this.key);

  final NewsListKey key;

  static const int pageSize = 20;

  @override
  NewsListView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider);
    if (engine != null && !key.saved) {
      final sub = engine.newsUpdates.listen((e) {
        if (!ref.mounted || e.fresh == 0 || state.items == null) return;
        unawaited(_quiet());
      });
      ref.onDispose(sub.cancel);
    }
    return const NewsListView();
  }

  DelveApi? get _api => ref.read(apiProvider);

  Future<void> _quiet() async {
    try {
      await refresh();
    } on Object {
      // kept in NewsListView.error
    }
  }

  Future<NewsItemPage> _page(DelveApi api, {int? before}) => api.newsItems(
    topic: key.topic,
    saved: key.saved,
    weekly: key.weekly,
    // the saved ones are all shown; the lists only from score 5
    minScore: key.saved ? null : kNewsMinScore,
    before: before,
    limit: pageSize,
  );

  /// The first page; a failure is kept and rethrown.
  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    try {
      final page = await _page(api);
      if (ref.mounted) {
        state = NewsListView(items: page.items, next: page.nextBefore);
      }
    } on Object catch (e) {
      if (ref.mounted) {
        state = NewsListView(items: state.items, next: state.next, error: e);
      }
      rethrow;
    }
  }

  /// The next page.
  Future<void> loadMore() async {
    final api = _api;
    final next = state.next;
    if (api == null || next == null) return;
    final page = await _page(api, before: next);
    if (!ref.mounted) return;
    final seen = {for (final i in state.items ?? const <NewsItem>[]) i.id};
    state = NewsListView(
      items: [
        ...?state.items,
        for (final i in page.items)
          if (!seen.contains(i.id)) i,
      ],
      next: page.nextBefore,
    );
  }
}

final newsListProvider =
    NotifierProvider.family<NewsListController, NewsListView, NewsListKey>(
      NewsListController.new,
    );

@immutable
class NewsStoryView {
  const NewsStoryView({this.story, this.error, this.fetching = false});

  final NewsStory? story;
  final Object? error;

  /// "Fetch text" is on its way.
  final bool fetching;
}

/// One story in the reading view: loaded, marked read, reloaded when the
/// collector brings its text or the model its summary.
class NewsStoryController extends Notifier<NewsStoryView> {
  NewsStoryController(this.id);

  final int id;

  @override
  NewsStoryView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider);
    if (engine != null) {
      final sub = engine.newsUpdates.listen((_) {
        final s = state.story;
        if (!ref.mounted || s == null) return;
        final waiting =
            s.item.textState == 'queued' ||
            (s.item.textState == 'ok' && s.item.summaryHu == null);
        if (waiting) unawaited(_reload());
      });
      ref.onDispose(sub.cancel);
    }
    return const NewsStoryView();
  }

  DelveApi? get _api => ref.read(apiProvider);
  NewsController get _news => ref.read(newsProvider.notifier);

  void _set(NewsStory story) {
    state = NewsStoryView(story: story, fetching: state.fetching);
    _news.put(story.item);
  }

  /// Loads the story and marks it read (once).
  Future<void> load() async {
    final api = _api;
    if (api == null) return;
    try {
      var story = await api.newsStory(id);
      if (!ref.mounted) return;
      _set(story);
      if (!story.item.read) {
        story = await api.markNews(story.item.id, read: true);
        if (ref.mounted) _set(story);
      }
    } on Object catch (e) {
      if (ref.mounted) {
        state = NewsStoryView(story: state.story, error: e);
      }
      rethrow;
    }
  }

  Future<void> _reload() async {
    final api = _api;
    if (api == null) return;
    try {
      final story = await api.newsStory(id);
      if (ref.mounted) _set(story);
    } on Object {
      // the shown copy stays
    }
  }

  NewsItem get _item => state.story!.item;

  Future<void> setSaved(bool saved) async =>
      _set(await _news.mark(_item, saved: saved));

  /// [feedback] `more` | `less`; the same again clears it.
  Future<void> setFeedback(String feedback) async {
    final clear = _item.feedback == feedback;
    _set(
      await _news.mark(
        _item,
        feedback: clear ? null : feedback,
        clearFeedback: clear,
      ),
    );
  }

  /// "Fetch text" / "Try again".
  Future<void> fetchText() async {
    final api = _api;
    if (api == null || state.story == null) return;
    state = NewsStoryView(story: state.story, fetching: true);
    try {
      final story = await api.fetchNewsText(_item.id);
      if (ref.mounted) {
        state = NewsStoryView(story: story);
        _news.put(story.item);
      }
    } on Object {
      if (ref.mounted) state = NewsStoryView(story: state.story);
      rethrow;
    }
  }
}

final newsStoryProvider =
    NotifierProvider.family<NewsStoryController, NewsStoryView, int>(
      NewsStoryController.new,
    );
