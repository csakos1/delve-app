import 'package:freezed_annotation/freezed_annotation.dart';

part 'news.freezed.dart';
part 'news.g.dart';

/// The lowest score the app shows (the backend's `SHOW_MIN_SCORE`, N2).
const int kNewsMinScore = 5;

/// A must-read (pushed, marked "Must read").
const int kNewsMustRead = 9;

/// `news_item` shape (N1, API 14-16): one lead story - a feed item with the
/// items about the same event merged under it ([sources] counts them all),
/// or a day of one project's releases ([kind] `release`, [releases]).
///
/// [score] .. [summaryHu] are null until the local model scored, explained
/// and summarised it. [textState]: null (no text asked for) | `queued` |
/// `ok` | `failed` (N1c). [originalUrl] is the publisher's address once a
/// Google News link was followed, else [url]. [summaryBasis] (API 24):
/// `text` | `excerpt` (no article came: written from the feed's excerpt) |
/// null; [textPublisher] (API 24): the publisher of the text when it is a
/// merged item's article.
@freezed
abstract class NewsItem with _$NewsItem {
  const factory NewsItem({
    required int id,
    String? topic,
    String? source,

    /// `feed` | `release`.
    required String kind,
    required String title,
    required String url,
    String? publisher,
    String? excerpt,
    DateTime? publishedAt,
    required DateTime seenAt,
    @Default(false) bool gn,
    @Default(1) int sources,
    List<NewsRelease>? releases,
    int? score,
    String? why,
    bool? setup,
    String? summaryHu,
    String? summaryBasis,
    String? textState,
    String? textPublisher,
    required String originalUrl,
    @Default(false) bool read,
    @Default(false) bool saved,

    /// `more` | `less` | null.
    String? feedback,
  }) = _NewsItem;

  factory NewsItem.fromJson(Map<String, Object?> json) =>
      _$NewsItemFromJson(json);
}

/// One release of a release row, newest first.
@freezed
abstract class NewsRelease with _$NewsRelease {
  const factory NewsRelease({
    required String tag,
    required String url,
    DateTime? publishedAt,
  }) = _NewsRelease;

  factory NewsRelease.fromJson(Map<String, Object?> json) =>
      _$NewsReleaseFromJson(json);
}

/// Another publisher's item merged into a story (`news_other`).
@freezed
abstract class NewsOther with _$NewsOther {
  const factory NewsOther({
    required int id,
    String? publisher,
    required String title,
    required String url,
    DateTime? publishedAt,
  }) = _NewsOther;

  factory NewsOther.fromJson(Map<String, Object?> json) =>
      _$NewsOtherFromJson(json);
}

/// `news_section` (API 17-18): one topic of the News page's All view - of
/// its stories scored 5 or more [count] of the last 24 hours, [week] of the
/// last 7 days, [fresh] the unread ones of the last 24 hours, and [top] the
/// best 3 of the last 24 hours (read ones too).
@freezed
abstract class NewsSection with _$NewsSection {
  const factory NewsSection({
    required String topic,
    required String name,
    @Default(0) int count,
    @Default(0) int week,
    @JsonKey(name: 'new') @Default(0) int fresh,
    @Default(<NewsItem>[]) List<NewsItem> top,
  }) = _NewsSection;

  factory NewsSection.fromJson(Map<String, Object?> json) =>
      _$NewsSectionFromJson(json);
}

/// `news_digest` (`GET /news`): the Dashboard block - at most 4 unread
/// stories of the last day scored 5 or more, one a topic; [fresh] how many
/// such are unread; [state] `empty` before the collector's first round.
@freezed
abstract class NewsDigest with _$NewsDigest {
  const factory NewsDigest({
    @Default(<NewsItem>[]) List<NewsItem> top,
    @JsonKey(name: 'new') @Default(0) int fresh,
    DateTime? updatedAt,

    /// `empty` | `ok`.
    required String state,
    @Default(0) int sources,
    @Default(0) int failing,

    /// On Mondays from the digest time on: how many of last week's best
    /// were not opened.
    NewsWeekly? weekly,
  }) = _NewsDigest;

  factory NewsDigest.fromJson(Map<String, Object?> json) =>
      _$NewsDigestFromJson(json);
}

@freezed
abstract class NewsWeekly with _$NewsWeekly {
  const factory NewsWeekly({required int count}) = _NewsWeekly;

  factory NewsWeekly.fromJson(Map<String, Object?> json) =>
      _$NewsWeeklyFromJson(json);
}

/// `news_topic`: what the model scores against ([description]).
@freezed
abstract class NewsTopic with _$NewsTopic {
  const factory NewsTopic({
    required String id,
    required String name,
    @Default('') String description,
    @Default(0) int position,
    @Default(true) bool enabled,
    @Default(0) int sources,
    @JsonKey(name: 'items_24h') @Default(0) int items24h,
  }) = _NewsTopic;

  factory NewsTopic.fromJson(Map<String, Object?> json) =>
      _$NewsTopicFromJson(json);
}

/// `news_source`: one feed and what it answered last.
@freezed
abstract class NewsSource with _$NewsSource {
  const factory NewsSource({
    required String id,
    String? topic,
    required String url,

    /// `feed` | `release`.
    required String kind,
    @Default(48) int windowH,
    @Default(60) int everyMin,
    @Default(true) bool enabled,

    /// `import` | `app` | `agent`.
    @Default('import') String origin,
    DateTime? lastAt,
    DateTime? lastOkAt,

    /// `ok` | `not_modified` | `skipped` | `error` | null.
    String? lastStatus,
    int? lastHttp,
    String? lastErrorCode,
    String? lastError,
    int? lastItems,
    int? lastNew,
    @Default(0) int errorsInRow,

    /// When the feed's newest story arrived (API 20); null without one.
    DateTime? lastItemAt,
  }) = _NewsSource;

  factory NewsSource.fromJson(Map<String, Object?> json) =>
      _$NewsSourceFromJson(json);
}

/// `news_settings`.
@freezed
abstract class NewsSettings with _$NewsSettings {
  const factory NewsSettings({
    @Default('') String setup,
    @Default('07:00') String digestAt,
    @Default(true) bool push,
    @Default(2) int pushMax,
  }) = _NewsSettings;

  factory NewsSettings.fromJson(Map<String, Object?> json) =>
      _$NewsSettingsFromJson(json);
}

/// `news_story` (`GET /news/items/{id}`, its `PATCH` and `POST .../text`):
/// the story's item with its other sources and its article ([text] when
/// `text_state` is `ok`: paragraphs split by blank lines; [textError] the
/// collector's reason when `failed`).
@immutable
class NewsStory {
  const NewsStory({
    required this.item,
    this.others = const [],
    this.text,
    this.textAt,
    this.textNow = false,
    this.textError,
  });

  factory NewsStory.fromJson(Map<String, Object?> json) => NewsStory(
    item: NewsItem.fromJson(json),
    others: [
      for (final o in (json['others'] as List<Object?>?) ?? const <Object?>[])
        NewsOther.fromJson(o! as Map<String, Object?>),
    ],
    text: json['text'] as String?,
    textAt: switch (json['text_at']) {
      final String s => DateTime.parse(s),
      _ => null,
    },
    textNow: json['text_now'] as bool? ?? false,
    textError: json['text_error'] as String?,
  );

  final NewsItem item;
  final List<NewsOther> others;
  final String? text;
  final DateTime? textAt;

  /// A “Fetch text” started the agent's job at once (API 19): the text comes
  /// in seconds; false while it waits for the hourly round.
  final bool textNow;
  final String? textError;

  Map<String, Object?> toJson() => {
    ...item.toJson(),
    'others': [for (final o in others) o.toJson()],
    'text': text,
    'text_at': textAt?.toIso8601String(),
    'text_now': textNow,
    'text_error': textError,
  };

  NewsStory withItem(NewsItem next) => NewsStory(
    item: next,
    others: others,
    text: text,
    textAt: textAt,
    textNow: textNow,
    textError: textError,
  );
}

/// What a story means on screen.
extension NewsItemX on NewsItem {
  bool get isRelease => kind == 'release';
  bool get mustRead => (score ?? 0) >= kNewsMustRead;
  bool get touchesSetup => setup ?? false;

  /// When it was published (or first seen).
  DateTime get at => publishedAt ?? seenAt;

  /// The collector can be asked for its article (not a day of releases, not
  /// while it is queued or there).
  bool get canFetchText =>
      !isRelease && (textState == null || textState == 'failed');
}
