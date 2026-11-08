import 'dart:convert';

/// Server-sent events from a byte stream: the `data:` payloads, one string
/// per event. Comment lines (`: OPENROUTER PROCESSING`) and other fields are
/// skipped; several `data:` lines of one event are joined with `\n`; an
/// event without a closing blank line at the end of the stream still counts.
Stream<String> sseData(Stream<List<int>> bytes) async* {
  final data = <String>[];
  // bind, not transform: dio's stream is a Stream<Uint8List>, and
  // `transform(utf8.decoder)` on it fails at run time (the decoder is a
  // StreamTransformer<List<int>, String>).
  await for (final line in const LineSplitter().bind(
    utf8.decoder.bind(bytes),
  )) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        yield data.join('\n');
        data.clear();
      }
      continue;
    }
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    if (field != 'data') continue;
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    data.add(value);
  }
  if (data.isNotEmpty) yield data.join('\n');
}
