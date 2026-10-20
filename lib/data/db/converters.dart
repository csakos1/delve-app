import 'dart:convert';

import 'package:drift/drift.dart';

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
