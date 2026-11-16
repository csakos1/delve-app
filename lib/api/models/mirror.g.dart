// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mirror.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MirrorStatus _$MirrorStatusFromJson(Map<String, dynamic> json) =>
    _MirrorStatus(
      desk: DeskLink.fromJson(json['desk'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MirrorStatusToJson(_MirrorStatus instance) =>
    <String, dynamic>{'desk': instance.desk.toJson()};

_DeskLink _$DeskLinkFromJson(Map<String, dynamic> json) => _DeskLink(
  connected: json['connected'] as bool,
  lastSeenS: (json['last_seen_s'] as num?)?.toInt(),
);

Map<String, dynamic> _$DeskLinkToJson(_DeskLink instance) => <String, dynamic>{
  'connected': instance.connected,
  'last_seen_s': instance.lastSeenS,
};
