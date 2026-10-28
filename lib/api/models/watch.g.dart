// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Watch _$WatchFromJson(Map<String, dynamic> json) => _Watch(
  slug: json['slug'] as String,
  name: json['name'] as String,
  source: json['source'] as String,
  url: json['url'] as String,
  criteria: json['criteria'] as String?,
  include:
      (json['include'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  any:
      (json['any'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  exclude:
      (json['exclude'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  minPrice: (json['min_price'] as num?)?.toInt(),
  maxPrice: (json['max_price'] as num?)?.toInt(),
  fetchDetails: json['fetch_details'] as bool,
  stopAfterHit: json['stop_after_hit'] as bool,
  schedule: json['schedule'] as String,
  state: json['state'] as String,
  jobId: json['job_id'] as String?,
  nextRunAt: json['next_run_at'] == null
      ? null
      : DateTime.parse(json['next_run_at'] as String),
  lastCheckAt: json['last_check_at'] == null
      ? null
      : DateTime.parse(json['last_check_at'] as String),
  lastStatus: json['last_status'] as String?,
  lastErrorCode: json['last_error_code'] as String?,
  lastError: json['last_error'] as String?,
  lastItems: (json['last_items'] as num?)?.toInt(),
  lastMatched: (json['last_matched'] as num?)?.toInt(),
  errorsInRow: (json['errors_in_row'] as num?)?.toInt() ?? 0,
  hits: (json['hits'] as num?)?.toInt() ?? 0,
  hits24h: (json['hits_24h'] as num?)?.toInt() ?? 0,
  pending: (json['pending'] as num?)?.toInt() ?? 0,
  rejected: (json['rejected'] as num?)?.toInt() ?? 0,
  lastHitAt: json['last_hit_at'] == null
      ? null
      : DateTime.parse(json['last_hit_at'] as String),
  stoppedAt: json['stopped_at'] == null
      ? null
      : DateTime.parse(json['stopped_at'] as String),
  definedAt: DateTime.parse(json['defined_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$WatchToJson(_Watch instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'source': instance.source,
  'url': instance.url,
  'criteria': instance.criteria,
  'include': instance.include,
  'any': instance.any,
  'exclude': instance.exclude,
  'min_price': instance.minPrice,
  'max_price': instance.maxPrice,
  'fetch_details': instance.fetchDetails,
  'stop_after_hit': instance.stopAfterHit,
  'schedule': instance.schedule,
  'state': instance.state,
  'job_id': instance.jobId,
  'next_run_at': instance.nextRunAt?.toIso8601String(),
  'last_check_at': instance.lastCheckAt?.toIso8601String(),
  'last_status': instance.lastStatus,
  'last_error_code': instance.lastErrorCode,
  'last_error': instance.lastError,
  'last_items': instance.lastItems,
  'last_matched': instance.lastMatched,
  'errors_in_row': instance.errorsInRow,
  'hits': instance.hits,
  'hits_24h': instance.hits24h,
  'pending': instance.pending,
  'rejected': instance.rejected,
  'last_hit_at': instance.lastHitAt?.toIso8601String(),
  'stopped_at': instance.stoppedAt?.toIso8601String(),
  'defined_at': instance.definedAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

_WatchItem _$WatchItemFromJson(Map<String, dynamic> json) => _WatchItem(
  id: (json['id'] as num).toInt(),
  slug: json['slug'] as String,
  itemId: json['item_id'] as String,
  title: json['title'] as String,
  url: json['url'] as String,
  price: json['price'] as String?,
  priceValue: (json['price_value'] as num?)?.toInt(),
  location: json['location'] as String?,
  posted: json['posted'] as String?,
  excerpt: json['excerpt'] as String?,
  reserved: json['reserved'] as bool? ?? false,
  verdict: json['verdict'] as String,
  reason: json['reason'] as String?,
  seenAt: DateTime.parse(json['seen_at'] as String),
  judgedAt: json['judged_at'] == null
      ? null
      : DateTime.parse(json['judged_at'] as String),
  notifiedAt: json['notified_at'] == null
      ? null
      : DateTime.parse(json['notified_at'] as String),
  availableAt: json['available_at'] == null
      ? null
      : DateTime.parse(json['available_at'] as String),
);

Map<String, dynamic> _$WatchItemToJson(_WatchItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'item_id': instance.itemId,
      'title': instance.title,
      'url': instance.url,
      'price': instance.price,
      'price_value': instance.priceValue,
      'location': instance.location,
      'posted': instance.posted,
      'excerpt': instance.excerpt,
      'reserved': instance.reserved,
      'verdict': instance.verdict,
      'reason': instance.reason,
      'seen_at': instance.seenAt.toIso8601String(),
      'judged_at': instance.judgedAt?.toIso8601String(),
      'notified_at': instance.notifiedAt?.toIso8601String(),
      'available_at': instance.availableAt?.toIso8601String(),
    };
