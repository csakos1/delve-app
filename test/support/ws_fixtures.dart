import 'dart:convert';
import 'dart:io';

import 'package:delve/api/events.dart';

/// Recorded WebSocket conversations (`tool/ws-record.py`).
const recordings = [
  'basic',
  'tool',
  'interim',
  'deny',
  'thinking',
  'stop',
  'queued',
  'reconnect',
];

/// One recording: every line after the metadata line.
class Recording {
  Recording(this.name)
    : lines = [
        for (final l in File(
          'test/fixtures/ws/$name.jsonl',
        ).readAsLinesSync().skip(1))
          if (l.trim().isNotEmpty) jsonDecode(l) as Map<String, Object?>,
      ];

  final String name;
  final List<Map<String, Object?>> lines;

  Iterable<Map<String, Object?>> get incoming => [
    for (final l in lines)
      if (l['dir'] == 'in') l['frame']! as Map<String, Object?>,
  ];

  /// Server events in stream order, each seq once (a resume may overlap).
  List<ServerEvent> get events {
    final bySeq = <int, ServerEvent>{};
    for (final f in incoming) {
      final seq = f['seq'];
      if (seq is int) {
        bySeq[seq] = IncomingFrame.parse(f) as ServerEvent;
      }
    }
    return [for (final k in bySeq.keys.toList()..sort()) bySeq[k]!];
  }

  /// Raw event frames of one type, in order.
  List<Map<String, Object?>> data(String type) => [
    for (final f in incoming)
      if (f['type'] == type && f['seq'] is int)
        f['data']! as Map<String, Object?>,
  ];

  String get epoch {
    final hello = incoming.firstWhere((f) => f['type'] == 'hello.ok');
    return (hello['data']! as Map<String, Object?>)['epoch']! as String;
  }
}

/// A shape from the contract samples (`test/fixtures/contract/samples.json`)
/// with some keys replaced.
Map<String, Object?> sample(
  String shape, [
  Map<String, Object?> overrides = const {},
]) {
  final all =
      jsonDecode(File('test/fixtures/contract/samples.json').readAsStringSync())
          as Map<String, Object?>;
  final shapes = all['shapes']! as Map<String, Object?>;
  return {...shapes[shape]! as Map<String, Object?>, ...overrides};
}
