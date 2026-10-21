import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats.freezed.dart';
part 'stats.g.dart';

/// `stats` shape (`GET /stats?range=24h|7d|30d`, B5): the Observability
/// screen. Buckets are Europe/Budapest hours (24 h), six hours (7 d) or days
/// (30 d); the last one holds [now]. The GPU series use finer buckets
/// ([gpuBucketS]) over the same span, from the backend's 60 s samples.
@freezed
abstract class Stats with _$Stats {
  const factory Stats({
    /// `24h` | `7d` | `30d`.
    required String range,
    required DateTime from,
    required DateTime to,
    required DateTime now,
    required String tz,
    required int bucketS,
    required int gpuBucketS,
    required StatsSeries generation,
    required StatsSeries prefill,

    /// Prefill only counts runs with at least this many prompt tokens.
    required int prefillMinPromptTokens,
    required StatsSeries queue,

    /// Seconds from the request to the answer (median).
    required StatsSeries approvalLatency,

    /// Percent of the input tokens read from the cache.
    required StatsSeries cacheHit,
    required TokensPerDay tokensPerDay,
    @Default(<StatsGpu>[]) List<StatsGpu> gpus,
    required StatsSampling sampling,
  }) = _Stats;

  factory Stats.fromJson(Map<String, Object?> json) => _$StatsFromJson(json);
}

/// One series: the headline [value] and one point per bucket.
@freezed
abstract class StatsSeries with _$StatsSeries {
  const factory StatsSeries({
    double? value,
    @Default(<StatsPoint>[]) List<StatsPoint> points,
  }) = _StatsSeries;

  factory StatsSeries.fromJson(Map<String, Object?> json) =>
      _$StatsSeriesFromJson(json);
}

/// A bucket starting at [t]; [v] is null where there was no data.
@freezed
abstract class StatsPoint with _$StatsPoint {
  const factory StatsPoint({required DateTime t, double? v}) = _StatsPoint;

  factory StatsPoint.fromJson(Map<String, Object?> json) =>
      _$StatsPointFromJson(json);
}

/// Tokens per local day; [value] is today's.
@freezed
abstract class TokensPerDay with _$TokensPerDay {
  const factory TokensPerDay({
    required int value,
    @Default(<StatsDay>[]) List<StatsDay> days,
  }) = _TokensPerDay;

  factory TokensPerDay.fromJson(Map<String, Object?> json) =>
      _$TokensPerDayFromJson(json);
}

@freezed
abstract class StatsDay with _$StatsDay {
  const factory StatsDay({
    /// Local date, `YYYY-MM-DD`.
    required String date,
    required int tokens,
  }) = _StatsDay;

  factory StatsDay.fromJson(Map<String, Object?> json) =>
      _$StatsDayFromJson(json);
}

/// One GPU's temperature (°C) and power (W) series.
@freezed
abstract class StatsGpu with _$StatsGpu {
  const factory StatsGpu({
    required int index,
    String? name,
    required StatsSeries temp,
    required StatsSeries power,
  }) = _StatsGpu;

  factory StatsGpu.fromJson(Map<String, Object?> json) =>
      _$StatsGpuFromJson(json);
}

/// Whether the GPU sampling works ([error]: the last failure).
@freezed
abstract class StatsSampling with _$StatsSampling {
  const factory StatsSampling({
    required int intervalS,
    required bool ok,
    String? error,
    DateTime? lastAt,
  }) = _StatsSampling;

  factory StatsSampling.fromJson(Map<String, Object?> json) =>
      _$StatsSamplingFromJson(json);
}
