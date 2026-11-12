// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SystemInfo _$SystemInfoFromJson(Map<String, dynamic> json) => _SystemInfo(
  checkedAt: DateTime.parse(json['checked_at'] as String),
  helper: HelperState.fromJson(json['helper'] as Map<String, dynamic>),
  hermes: HermesInfo.fromJson(json['hermes'] as Map<String, dynamic>),
  llama: LlamaInfo.fromJson(json['llama'] as Map<String, dynamic>),
  queue: QueueInfo.fromJson(json['queue'] as Map<String, dynamic>),
  gpus: (json['gpus'] as List<dynamic>?)
      ?.map((e) => GpuInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SystemInfoToJson(_SystemInfo instance) =>
    <String, dynamic>{
      'checked_at': instance.checkedAt.toIso8601String(),
      'helper': instance.helper.toJson(),
      'hermes': instance.hermes.toJson(),
      'llama': instance.llama.toJson(),
      'queue': instance.queue.toJson(),
      'gpus': instance.gpus?.map((e) => e.toJson()).toList(),
    };

_HelperState _$HelperStateFromJson(Map<String, dynamic> json) =>
    _HelperState(ok: json['ok'] as bool, error: json['error'] as String?);

Map<String, dynamic> _$HelperStateToJson(_HelperState instance) =>
    <String, dynamic>{'ok': instance.ok, 'error': instance.error};

_HermesInfo _$HermesInfoFromJson(Map<String, dynamic> json) => _HermesInfo(
  status: json['status'] as String,
  version: json['version'] as String?,
  since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
  issues:
      (json['issues'] as List<dynamic>?)
          ?.map((e) => HermesIssue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <HermesIssue>[],
);

Map<String, dynamic> _$HermesInfoToJson(_HermesInfo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'version': instance.version,
      'since': instance.since?.toIso8601String(),
      'issues': instance.issues.map((e) => e.toJson()).toList(),
    };

_HermesIssue _$HermesIssueFromJson(Map<String, dynamic> json) => _HermesIssue(
  check: json['check'] as String,
  status: json['status'] as String,
  detail: json['detail'] as String?,
);

Map<String, dynamic> _$HermesIssueToJson(_HermesIssue instance) =>
    <String, dynamic>{
      'check': instance.check,
      'status': instance.status,
      'detail': instance.detail,
    };

_LlamaInfo _$LlamaInfoFromJson(Map<String, dynamic> json) => _LlamaInfo(
  status: json['status'] as String,
  intent: json['intent'] as String?,
  since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
  model: json['model'] as String?,
  quant: json['quant'] as String?,
  ctx: (json['ctx'] as num?)?.toInt(),
  slots: (json['slots'] as num?)?.toInt(),
  slotsBusy: (json['slots_busy'] as num?)?.toInt(),
  genTps: (json['gen_tps'] as num?)?.toDouble(),
  preset: json['preset'] as String?,
  vision: json['vision'] as bool?,
  thinking: json['thinking'] as String?,
  models: (json['models'] as List<dynamic>?)
      ?.map((e) => LlamaModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  switchState: json['switch'] == null
      ? null
      : LlamaSwitch.fromJson(json['switch'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LlamaInfoToJson(_LlamaInfo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'intent': instance.intent,
      'since': instance.since?.toIso8601String(),
      'model': instance.model,
      'quant': instance.quant,
      'ctx': instance.ctx,
      'slots': instance.slots,
      'slots_busy': instance.slotsBusy,
      'gen_tps': instance.genTps,
      'preset': instance.preset,
      'vision': instance.vision,
      'thinking': instance.thinking,
      'models': instance.models?.map((e) => e.toJson()).toList(),
      'switch': instance.switchState?.toJson(),
    };

_LlamaModel _$LlamaModelFromJson(Map<String, dynamic> json) => _LlamaModel(
  name: json['name'] as String,
  model: json['model'] as String,
  quant: json['quant'] as String?,
  note: json['note'] as String?,
  ctx: (json['ctx'] as num?)?.toInt(),
  vision: json['vision'] as bool? ?? false,
  thinking: json['thinking'] as String? ?? 'toggle',
  sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  usable: json['usable'] as bool? ?? false,
  reason: json['reason'] as String?,
  active: json['active'] as bool? ?? false,
);

Map<String, dynamic> _$LlamaModelToJson(_LlamaModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'model': instance.model,
      'quant': instance.quant,
      'note': instance.note,
      'ctx': instance.ctx,
      'vision': instance.vision,
      'thinking': instance.thinking,
      'size_bytes': instance.sizeBytes,
      'usable': instance.usable,
      'reason': instance.reason,
      'active': instance.active,
    };

_LlamaSwitch _$LlamaSwitchFromJson(Map<String, dynamic> json) => _LlamaSwitch(
  state: json['state'] as String,
  from: json['from'] as String?,
  to: json['to'] as String,
  by: json['by'] as String?,
  at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
  error: json['error'] as String?,
  elapsedS: (json['elapsed_s'] as num?)?.toInt(),
);

Map<String, dynamic> _$LlamaSwitchToJson(_LlamaSwitch instance) =>
    <String, dynamic>{
      'state': instance.state,
      'from': instance.from,
      'to': instance.to,
      'by': instance.by,
      'at': instance.at?.toIso8601String(),
      'error': instance.error,
      'elapsed_s': instance.elapsedS,
    };

_QueueInfo _$QueueInfoFromJson(Map<String, dynamic> json) => _QueueInfo(
  active: (json['active'] as num).toInt(),
  queued: (json['queued'] as num).toInt(),
);

Map<String, dynamic> _$QueueInfoToJson(_QueueInfo instance) =>
    <String, dynamic>{'active': instance.active, 'queued': instance.queued};

_GpuInfo _$GpuInfoFromJson(Map<String, dynamic> json) => _GpuInfo(
  index: (json['index'] as num).toInt(),
  name: json['name'] as String,
  tempC: (json['temp_c'] as num?)?.toDouble(),
  memUsedMib: (json['mem_used_mib'] as num?)?.toInt(),
  memTotalMib: (json['mem_total_mib'] as num?)?.toInt(),
  utilPct: (json['util_pct'] as num?)?.toDouble(),
  powerW: (json['power_w'] as num?)?.toDouble(),
  powerLimitW: (json['power_limit_w'] as num?)?.toDouble(),
);

Map<String, dynamic> _$GpuInfoToJson(_GpuInfo instance) => <String, dynamic>{
  'index': instance.index,
  'name': instance.name,
  'temp_c': instance.tempC,
  'mem_used_mib': instance.memUsedMib,
  'mem_total_mib': instance.memTotalMib,
  'util_pct': instance.utilPct,
  'power_w': instance.powerW,
  'power_limit_w': instance.powerLimitW,
};
