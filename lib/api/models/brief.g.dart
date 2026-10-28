// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brief.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Brief _$BriefFromJson(Map<String, dynamic> json) => _Brief(
  date: json['date'] as String,
  uptimeS: (json['uptime_s'] as num?)?.toInt(),
  bootedAt: json['booted_at'] == null
      ? null
      : DateTime.parse(json['booted_at'] as String),
  openIncidents: (json['open_incidents'] as num?)?.toInt(),
  incidents:
      (json['incidents'] as List<dynamic>?)
          ?.map((e) => BriefIncident.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BriefIncident>[],
  updatesCount: (json['updates_count'] as num?)?.toInt(),
  updatesCheckedAt: json['updates_checked_at'] == null
      ? null
      : DateTime.parse(json['updates_checked_at'] as String),
  water: json['water'] == null
      ? null
      : BriefWater.fromJson(json['water'] as Map<String, dynamic>),
  llamaState: json['llama_state'] as String?,
  hermesState: json['hermes_state'] as String?,
  missing:
      (json['missing'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  lateByS: (json['late_by_s'] as num?)?.toInt(),
);

Map<String, dynamic> _$BriefToJson(_Brief instance) => <String, dynamic>{
  'date': instance.date,
  'uptime_s': instance.uptimeS,
  'booted_at': instance.bootedAt?.toIso8601String(),
  'open_incidents': instance.openIncidents,
  'incidents': instance.incidents.map((e) => e.toJson()).toList(),
  'updates_count': instance.updatesCount,
  'updates_checked_at': instance.updatesCheckedAt?.toIso8601String(),
  'water': instance.water?.toJson(),
  'llama_state': instance.llamaState,
  'hermes_state': instance.hermesState,
  'missing': instance.missing,
  'late_by_s': instance.lateByS,
};

_BriefIncident _$BriefIncidentFromJson(Map<String, dynamic> json) =>
    _BriefIncident(
      id: json['id'] as String,
      state: json['state'] as String,
      job: json['job'] as String?,
      error: json['error'] as String?,
      lastSeen: json['last_seen'] as String?,
    );

Map<String, dynamic> _$BriefIncidentToJson(_BriefIncident instance) =>
    <String, dynamic>{
      'id': instance.id,
      'state': instance.state,
      'job': instance.job,
      'error': instance.error,
      'last_seen': instance.lastSeen,
    };

_BriefWater _$BriefWaterFromJson(Map<String, dynamic> json) => _BriefWater(
  station: json['station'] as String?,
  levelCm: (json['level_cm'] as num?)?.toDouble(),
  lakeAvgCm: (json['lake_avg_cm'] as num?)?.toDouble(),
  trendCm24h: (json['trend_cm_24h'] as num?)?.toDouble(),
  lakeAvgTrendCm24h: (json['lake_avg_trend_cm_24h'] as num?)?.toDouble(),
  measuredAt: json['measured_at'] as String?,
);

Map<String, dynamic> _$BriefWaterToJson(_BriefWater instance) =>
    <String, dynamic>{
      'station': instance.station,
      'level_cm': instance.levelCm,
      'lake_avg_cm': instance.lakeAvgCm,
      'trend_cm_24h': instance.trendCm24h,
      'lake_avg_trend_cm_24h': instance.lakeAvgTrendCm24h,
      'measured_at': instance.measuredAt,
    };
