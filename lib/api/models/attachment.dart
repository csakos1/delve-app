import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

/// `attachment` shape (API 8): `POST /attachments`, and each user message's
/// `attachments`. `kind`: image | file. [messageId] is null until
/// `chat.send` binds the upload; [available] is false once the server has
/// deleted the bytes (14 days).
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    required String kind,
    required String mime,
    required String filename,
    required int sizeBytes,
    int? messageId,
    @Default(true) bool available,
    DateTime? createdAt,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, Object?> json) =>
      _$AttachmentFromJson(json);
}

extension AttachmentKind on Attachment {
  bool get isImage => kind == 'image';
}
