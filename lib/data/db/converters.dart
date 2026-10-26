import 'dart:convert';

import 'package:drift/drift.dart';

import '../../api/models/attachment.dart';

/// JSON object column (usage, perf, tool results); null stays null.
class JsonMapConverter extends TypeConverter<Map<String, Object?>, String> {
  const JsonMapConverter();

  @override
  Map<String, Object?> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as Map<String, Object?>?) ?? <String, Object?>{};

  @override
  String toSql(Map<String, Object?> value) => jsonEncode(value);
}

/// JSON string-list column (approval choices, pattern keys).
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => [
    for (final v in jsonDecode(fromDb) as List<Object?>) v.toString(),
  ];

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// JSON list of `attachment` objects (a message's photos and files, B6).
class AttachmentListConverter extends TypeConverter<List<Attachment>, String> {
  const AttachmentListConverter();

  @override
  List<Attachment> fromSql(String fromDb) => [
    for (final v in jsonDecode(fromDb) as List<Object?>)
      if (v is Map<String, Object?>) Attachment.fromJson(v),
  ];

  @override
  String toSql(List<Attachment> value) =>
      jsonEncode([for (final a in value) a.toJson()]);
}
