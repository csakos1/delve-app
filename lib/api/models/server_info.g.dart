// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerMeta _$ServerMetaFromJson(Map<String, dynamic> json) => _ServerMeta(
  serverVersion: json['server_version'] as String,
  apiRevision: (json['api_revision'] as num).toInt(),
  revision: json['revision'] as String?,
  hermesExpectedVersion: json['hermes_expected_version'] as String?,
  approvalTimeoutS: (json['approval_timeout_s'] as num?)?.toInt(),
);

Map<String, dynamic> _$ServerMetaToJson(_ServerMeta instance) =>
    <String, dynamic>{
      'server_version': instance.serverVersion,
      'api_revision': instance.apiRevision,
      'revision': instance.revision,
      'hermes_expected_version': instance.hermesExpectedVersion,
      'approval_timeout_s': instance.approvalTimeoutS,
    };

_ThinkingRoute _$ThinkingRouteFromJson(Map<String, dynamic> json) =>
    _ThinkingRoute(
      ok: json['ok'] as bool,
      runId: json['run_id'] as String?,
      at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
    );

Map<String, dynamic> _$ThinkingRouteToJson(_ThinkingRoute instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'run_id': instance.runId,
      'at': instance.at?.toIso8601String(),
    };

_ServerStatus _$ServerStatusFromJson(Map<String, dynamic> json) =>
    _ServerStatus(
      serverVersion: json['server_version'] as String,
      apiRevision: (json['api_revision'] as num).toInt(),
      revision: json['revision'] as String?,
      hermes: json['hermes'] as String?,
      hermesVersion: json['hermes_version'] as String?,
      thinkingRoute: json['thinking_route'] == null
          ? null
          : ThinkingRoute.fromJson(
              json['thinking_route'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ServerStatusToJson(_ServerStatus instance) =>
    <String, dynamic>{
      'server_version': instance.serverVersion,
      'api_revision': instance.apiRevision,
      'revision': instance.revision,
      'hermes': instance.hermes,
      'hermes_version': instance.hermesVersion,
      'thinking_route': instance.thinkingRoute?.toJson(),
    };

_HelloOk _$HelloOkFromJson(Map<String, dynamic> json) => _HelloOk(
  serverVersion: json['server_version'] as String,
  apiRevision: (json['api_revision'] as num).toInt(),
  revision: json['revision'] as String?,
  hermes: json['hermes'] as String?,
  hermesVersion: json['hermes_version'] as String?,
  thinkingRoute: json['thinking_route'] == null
      ? null
      : ThinkingRoute.fromJson(json['thinking_route'] as Map<String, dynamic>),
  epoch: json['epoch'] as String,
  seq: (json['seq'] as num).toInt(),
  resyncRequired: json['resync_required'] as bool,
);

Map<String, dynamic> _$HelloOkToJson(_HelloOk instance) => <String, dynamic>{
  'server_version': instance.serverVersion,
  'api_revision': instance.apiRevision,
  'revision': instance.revision,
  'hermes': instance.hermes,
  'hermes_version': instance.hermesVersion,
  'thinking_route': instance.thinkingRoute?.toJson(),
  'epoch': instance.epoch,
  'seq': instance.seq,
  'resync_required': instance.resyncRequired,
};

_RegisteredDevice _$RegisteredDeviceFromJson(Map<String, dynamic> json) =>
    _RegisteredDevice(
      deviceId: json['device_id'] as String,
      name: json['name'] as String,
      token: json['token'] as String,
    );

Map<String, dynamic> _$RegisteredDeviceToJson(_RegisteredDevice instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'name': instance.name,
      'token': instance.token,
    };

_DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => _DeviceInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastSeenAt: json['last_seen_at'] == null
      ? null
      : DateTime.parse(json['last_seen_at'] as String),
  fcm: json['fcm'] as bool,
);

Map<String, dynamic> _$DeviceInfoToJson(_DeviceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'fcm': instance.fcm,
    };
