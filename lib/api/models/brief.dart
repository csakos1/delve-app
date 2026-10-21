import 'package:freezed_annotation/freezed_annotation.dart';

part 'brief.freezed.dart';
part 'brief.g.dart';

/// The `payload` of a `brief` card (B4): written by the backend each morning
/// without the model. A source it could not read is null and named in
/// [missing] (`host`, `incidents`, `updates`, `water`, `system`).
@freezed
abstract class Brief with _$Brief {
  const factory Brief({
    /// Local date, `YYYY-MM-DD`.
    required String date,
    int? uptimeS,
    DateTime? bootedAt,
    int? openIncidents,
    @Default(<BriefIncident>[]) List<BriefIncident> incidents,
    int? updatesCount,
    DateTime? updatesCheckedAt,
    BriefWater? water,
    String? llamaState,
    String? hermesState,
    @Default(<String>[]) List<String> missing,
  }) = _Brief;

  factory Brief.fromJson(Map<String, Object?> json) => _$BriefFromJson(json);
}

/// An agent cron incident that is still open (not acknowledged).
@freezed
abstract class BriefIncident with _$BriefIncident {
  const factory BriefIncident({
    required String id,

    /// `detected` | `alerted` | `resolved`.
    required String state,
    String? job,
    String? error,
    String? lastSeen,
  }) = _BriefIncident;

  factory BriefIncident.fromJson(Map<String, Object?> json) =>
      _$BriefIncidentFromJson(json);
}

/// The latest scheduled water reading the brief was written with.
@freezed
abstract class BriefWater with _$BriefWater {
  const factory BriefWater({
    String? station,
    double? levelCm,
    double? lakeAvgCm,
    @JsonKey(name: 'trend_cm_24h') double? trendCm24h,
    @JsonKey(name: 'lake_avg_trend_cm_24h') double? lakeAvgTrendCm24h,
    String? measuredAt,
  }) = _BriefWater;

  factory BriefWater.fromJson(Map<String, Object?> json) =>
      _$BriefWaterFromJson(json);
}
