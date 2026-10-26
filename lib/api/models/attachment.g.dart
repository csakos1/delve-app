// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Attachment _$AttachmentFromJson(Map<String, dynamic> json) => _Attachment(
  id: json['id'] as String,
  kind: json['kind'] as String,
  mime: json['mime'] as String,
  filename: json['filename'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  messageId: (json['message_id'] as num?)?.toInt(),
  available: json['available'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AttachmentToJson(_Attachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'mime': instance.mime,
      'filename': instance.filename,
      'size_bytes': instance.sizeBytes,
      'message_id': instance.messageId,
      'available': instance.available,
      'created_at': instance.createdAt?.toIso8601String(),
    };
