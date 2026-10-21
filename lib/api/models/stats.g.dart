// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Stats _$StatsFromJson(Map<String, dynamic> json) => _Stats(
  range: json['range'] as String,
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  now: DateTime.parse(json['now'] as String),
  tz: json['tz'] as String,
  bucketS: (json['bucket_s'] as num).toInt(),
  gpuBucketS: (json['gpu_bucket_s'] as num).toInt(),
  generation: StatsSeries.fromJson(json['generation'] as Map<String, dynamic>),
  prefill: StatsSeries.fromJson(json['prefill'] as Map<String, dynamic>),
  prefillMinPromptTokens: (json['prefill_min_prompt_tokens'] as num).toInt(),
  queue: StatsSeries.fromJson(json['queue'] as Map<String, dynamic>),
  approvalLatency: StatsSeries.fromJson(
    json['approval_latency'] as Map<String, dynamic>,
  ),
  cacheHit: StatsSeries.fromJson(json['cache_hit'] as Map<String, dynamic>),
  tokensPerDay: TokensPerDay.fromJson(
    json['tokens_per_day'] as Map<String, dynamic>,
  ),
  gpus:
      (json['gpus'] as List<dynamic>?)
          ?.map((e) => StatsGpu.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <StatsGpu>[],
  sampling: StatsSampling.fromJson(json['sampling'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StatsToJson(_Stats instance) => <String, dynamic>{
  'range': instance.range,
  'from': instance.from.toIso8601String(),
  'to': instance.to.toIso8601String(),
  'now': instance.now.toIso8601String(),
  'tz': instance.tz,
  'bucket_s': instance.bucketS,
  'gpu_bucket_s': instance.gpuBucketS,
  'generation': instance.generation.toJson(),
  'prefill': instance.prefill.toJson(),
  'prefill_min_prompt_tokens': instance.prefillMinPromptTokens,
  'queue': instance.queue.toJson(),
  'approval_latency': instance.approvalLatency.toJson(),
  'cache_hit': instance.cacheHit.toJson(),
  'tokens_per_day': instance.tokensPerDay.toJson(),
  'gpus': instance.gpus.map((e) => e.toJson()).toList(),
  'sampling': instance.sampling.toJson(),
};

_StatsSeries _$StatsSeriesFromJson(Map<String, dynamic> json) => _StatsSeries(
  value: (json['value'] as num?)?.toDouble(),
  points:
      (json['points'] as List<dynamic>?)
          ?.map((e) => StatsPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <StatsPoint>[],
);

Map<String, dynamic> _$StatsSeriesToJson(_StatsSeries instance) =>
    <String, dynamic>{
      'value': instance.value,
      'points': instance.points.map((e) => e.toJson()).toList(),
    };

_StatsPoint _$StatsPointFromJson(Map<String, dynamic> json) => _StatsPoint(
  t: DateTime.parse(json['t'] as String),
  v: (json['v'] as num?)?.toDouble(),
);

Map<String, dynamic> _$StatsPointToJson(_StatsPoint instance) =>
    <String, dynamic>{'t': instance.t.toIso8601String(), 'v': instance.v};

_TokensPerDay _$TokensPerDayFromJson(Map<String, dynamic> json) =>
    _TokensPerDay(
      value: (json['value'] as num).toInt(),
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => StatsDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StatsDay>[],
    );

Map<String, dynamic> _$TokensPerDayToJson(_TokensPerDay instance) =>
    <String, dynamic>{
      'value': instance.value,
      'days': instance.days.map((e) => e.toJson()).toList(),
    };

_StatsDay _$StatsDayFromJson(Map<String, dynamic> json) => _StatsDay(
  date: json['date'] as String,
  tokens: (json['tokens'] as num).toInt(),
);

Map<String, dynamic> _$StatsDayToJson(_StatsDay instance) => <String, dynamic>{
  'date': instance.date,
  'tokens': instance.tokens,
};

_StatsGpu _$StatsGpuFromJson(Map<String, dynamic> json) => _StatsGpu(
  index: (json['index'] as num).toInt(),
  name: json['name'] as String?,
  temp: StatsSeries.fromJson(json['temp'] as Map<String, dynamic>),
  power: StatsSeries.fromJson(json['power'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StatsGpuToJson(_StatsGpu instance) => <String, dynamic>{
  'index': instance.index,
  'name': instance.name,
  'temp': instance.temp.toJson(),
  'power': instance.power.toJson(),
};

_StatsSampling _$StatsSamplingFromJson(Map<String, dynamic> json) =>
    _StatsSampling(
      intervalS: (json['interval_s'] as num).toInt(),
      ok: json['ok'] as bool,
      error: json['error'] as String?,
      lastAt: json['last_at'] == null
          ? null
          : DateTime.parse(json['last_at'] as String),
    );

Map<String, dynamic> _$StatsSamplingToJson(_StatsSampling instance) =>
    <String, dynamic>{
      'interval_s': instance.intervalS,
      'ok': instance.ok,
      'error': instance.error,
      'last_at': instance.lastAt?.toIso8601String(),
    };
