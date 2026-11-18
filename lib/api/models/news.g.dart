// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NewsItem _$NewsItemFromJson(Map<String, dynamic> json) => _NewsItem(
  id: (json['id'] as num).toInt(),
  topic: json['topic'] as String?,
  source: json['source'] as String?,
  kind: json['kind'] as String,
  title: json['title'] as String,
  url: json['url'] as String,
  publisher: json['publisher'] as String?,
  excerpt: json['excerpt'] as String?,
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
  seenAt: DateTime.parse(json['seen_at'] as String),
  gn: json['gn'] as bool? ?? false,
  sources: (json['sources'] as num?)?.toInt() ?? 1,
  releases: (json['releases'] as List<dynamic>?)
      ?.map((e) => NewsRelease.fromJson(e as Map<String, dynamic>))
      .toList(),
  score: (json['score'] as num?)?.toInt(),
  why: json['why'] as String?,
  setup: json['setup'] as bool?,
  summaryHu: json['summary_hu'] as String?,
  textState: json['text_state'] as String?,
  originalUrl: json['original_url'] as String,
  read: json['read'] as bool? ?? false,
  saved: json['saved'] as bool? ?? false,
  feedback: json['feedback'] as String?,
);

Map<String, dynamic> _$NewsItemToJson(_NewsItem instance) => <String, dynamic>{
  'id': instance.id,
  'topic': instance.topic,
  'source': instance.source,
  'kind': instance.kind,
  'title': instance.title,
  'url': instance.url,
  'publisher': instance.publisher,
  'excerpt': instance.excerpt,
  'published_at': instance.publishedAt?.toIso8601String(),
  'seen_at': instance.seenAt.toIso8601String(),
  'gn': instance.gn,
  'sources': instance.sources,
  'releases': instance.releases?.map((e) => e.toJson()).toList(),
  'score': instance.score,
  'why': instance.why,
  'setup': instance.setup,
  'summary_hu': instance.summaryHu,
  'text_state': instance.textState,
  'original_url': instance.originalUrl,
  'read': instance.read,
  'saved': instance.saved,
  'feedback': instance.feedback,
};

_NewsRelease _$NewsReleaseFromJson(Map<String, dynamic> json) => _NewsRelease(
  tag: json['tag'] as String,
  url: json['url'] as String,
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
);

Map<String, dynamic> _$NewsReleaseToJson(_NewsRelease instance) =>
    <String, dynamic>{
      'tag': instance.tag,
      'url': instance.url,
      'published_at': instance.publishedAt?.toIso8601String(),
    };

_NewsOther _$NewsOtherFromJson(Map<String, dynamic> json) => _NewsOther(
  id: (json['id'] as num).toInt(),
  publisher: json['publisher'] as String?,
  title: json['title'] as String,
  url: json['url'] as String,
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
);

Map<String, dynamic> _$NewsOtherToJson(_NewsOther instance) =>
    <String, dynamic>{
      'id': instance.id,
      'publisher': instance.publisher,
      'title': instance.title,
      'url': instance.url,
      'published_at': instance.publishedAt?.toIso8601String(),
    };

_NewsSection _$NewsSectionFromJson(Map<String, dynamic> json) => _NewsSection(
  topic: json['topic'] as String,
  name: json['name'] as String,
  count: (json['count'] as num?)?.toInt() ?? 0,
  week: (json['week'] as num?)?.toInt() ?? 0,
  fresh: (json['new'] as num?)?.toInt() ?? 0,
  top:
      (json['top'] as List<dynamic>?)
          ?.map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NewsItem>[],
);

Map<String, dynamic> _$NewsSectionToJson(_NewsSection instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'name': instance.name,
      'count': instance.count,
      'week': instance.week,
      'new': instance.fresh,
      'top': instance.top.map((e) => e.toJson()).toList(),
    };

_NewsDigest _$NewsDigestFromJson(Map<String, dynamic> json) => _NewsDigest(
  top:
      (json['top'] as List<dynamic>?)
          ?.map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NewsItem>[],
  fresh: (json['new'] as num?)?.toInt() ?? 0,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  state: json['state'] as String,
  sources: (json['sources'] as num?)?.toInt() ?? 0,
  failing: (json['failing'] as num?)?.toInt() ?? 0,
  weekly: json['weekly'] == null
      ? null
      : NewsWeekly.fromJson(json['weekly'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NewsDigestToJson(_NewsDigest instance) =>
    <String, dynamic>{
      'top': instance.top.map((e) => e.toJson()).toList(),
      'new': instance.fresh,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'state': instance.state,
      'sources': instance.sources,
      'failing': instance.failing,
      'weekly': instance.weekly?.toJson(),
    };

_NewsWeekly _$NewsWeeklyFromJson(Map<String, dynamic> json) =>
    _NewsWeekly(count: (json['count'] as num).toInt());

Map<String, dynamic> _$NewsWeeklyToJson(_NewsWeekly instance) =>
    <String, dynamic>{'count': instance.count};

_NewsTopic _$NewsTopicFromJson(Map<String, dynamic> json) => _NewsTopic(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  position: (json['position'] as num?)?.toInt() ?? 0,
  enabled: json['enabled'] as bool? ?? true,
  sources: (json['sources'] as num?)?.toInt() ?? 0,
  items24h: (json['items_24h'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$NewsTopicToJson(_NewsTopic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'position': instance.position,
      'enabled': instance.enabled,
      'sources': instance.sources,
      'items_24h': instance.items24h,
    };

_NewsSource _$NewsSourceFromJson(Map<String, dynamic> json) => _NewsSource(
  id: json['id'] as String,
  topic: json['topic'] as String?,
  url: json['url'] as String,
  kind: json['kind'] as String,
  windowH: (json['window_h'] as num?)?.toInt() ?? 48,
  everyMin: (json['every_min'] as num?)?.toInt() ?? 60,
  enabled: json['enabled'] as bool? ?? true,
  origin: json['origin'] as String? ?? 'import',
  lastAt: json['last_at'] == null
      ? null
      : DateTime.parse(json['last_at'] as String),
  lastOkAt: json['last_ok_at'] == null
      ? null
      : DateTime.parse(json['last_ok_at'] as String),
  lastStatus: json['last_status'] as String?,
  lastHttp: (json['last_http'] as num?)?.toInt(),
  lastErrorCode: json['last_error_code'] as String?,
  lastError: json['last_error'] as String?,
  lastItems: (json['last_items'] as num?)?.toInt(),
  lastNew: (json['last_new'] as num?)?.toInt(),
  errorsInRow: (json['errors_in_row'] as num?)?.toInt() ?? 0,
  lastItemAt: json['last_item_at'] == null
      ? null
      : DateTime.parse(json['last_item_at'] as String),
);

Map<String, dynamic> _$NewsSourceToJson(_NewsSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topic': instance.topic,
      'url': instance.url,
      'kind': instance.kind,
      'window_h': instance.windowH,
      'every_min': instance.everyMin,
      'enabled': instance.enabled,
      'origin': instance.origin,
      'last_at': instance.lastAt?.toIso8601String(),
      'last_ok_at': instance.lastOkAt?.toIso8601String(),
      'last_status': instance.lastStatus,
      'last_http': instance.lastHttp,
      'last_error_code': instance.lastErrorCode,
      'last_error': instance.lastError,
      'last_items': instance.lastItems,
      'last_new': instance.lastNew,
      'errors_in_row': instance.errorsInRow,
      'last_item_at': instance.lastItemAt?.toIso8601String(),
    };

_NewsSettings _$NewsSettingsFromJson(Map<String, dynamic> json) =>
    _NewsSettings(
      setup: json['setup'] as String? ?? '',
      digestAt: json['digest_at'] as String? ?? '07:00',
      push: json['push'] as bool? ?? true,
      pushMax: (json['push_max'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$NewsSettingsToJson(_NewsSettings instance) =>
    <String, dynamic>{
      'setup': instance.setup,
      'digest_at': instance.digestAt,
      'push': instance.push,
      'push_max': instance.pushMax,
    };
