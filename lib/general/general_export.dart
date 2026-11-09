import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';

import 'general_database.dart';

// Export / import of the General chats (G1c, 24h). One `.zip`:
//
//   manifest.json   format, version, when, the database schema, counts
//   chats.json      every chat (archived ones too) with its messages; the
//                   images are listed by message and stored as files
//   settings.json   favourites, default model, system prompt, token footer
//   images/<id>.jpg the images, stored (JPEG does not deflate)
//
// The OpenRouter key and the model cache are never in it. An import merges
// by id: a chat that is newer in the file wins, messages and images are
// joined, and the file's settings replace the phone's (decision G-24).

const kExportFormat = 'delve-general-export';

/// The newest export this app reads; a newer one is refused, not guessed.
const kExportVersion = 1;

const _manifestName = 'manifest.json';
const _chatsName = 'chats.json';
const _settingsName = 'settings.json';

/// Why a file cannot be imported.
enum GeneralImportProblem {
  /// Not a zip, no `manifest.json`, or another format.
  notExport,

  /// Written by a newer Delve (a higher `version`).
  tooNew,

  /// A Delve export with a missing or broken part; nothing was imported.
  damaged,
}

class GeneralImportError implements Exception {
  const GeneralImportError(this.problem, [this.detail]);

  final GeneralImportProblem problem;
  final String? detail;

  @override
  String toString() =>
      'GeneralImportError(${problem.name}${detail == null ? '' : ': $detail'})';
}

/// A finished export: the file's bytes and what is in it.
class GeneralExportFile {
  const GeneralExportFile({
    required this.name,
    required this.bytes,
    required this.chats,
    required this.images,
  });

  /// `delve-general-2026-11-09-1105.zip` (local time).
  final String name;
  final Uint8List bytes;
  final int chats;
  final int images;
}

/// What an import did.
class GeneralImportResult {
  const GeneralImportResult({
    required this.chats,
    required this.created,
    required this.updated,
    required this.images,
    required this.settings,
  });

  /// Chats in the file.
  final int chats;

  /// Chats the phone did not have.
  final int created;

  /// Chats the phone had that changed (a newer version, or messages or
  /// images it lacked).
  final int updated;

  /// Images added.
  final int images;

  /// The file's settings were applied.
  final bool settings;
}

/// The file name of an export made at [at] (local time).
String generalExportName(DateTime at) {
  final t = at.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'delve-general-${t.year}-${two(t.month)}-${two(t.day)}-'
      '${two(t.hour)}${two(t.minute)}.zip';
}

class GeneralExporter {
  GeneralExporter(this.db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GeneralDatabase db;
  final DateTime Function() _now;

  // ---- export

  Future<GeneralExportFile> export() async {
    final at = _now();
    final chats =
        await (db.select(db.generalChats)..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    final messages =
        await (db.select(db.generalMessages)..orderBy([
              (t) => OrderingTerm.asc(t.chatId),
              (t) => OrderingTerm.asc(t.seq),
            ]))
            .get();
    final attachments =
        await (db.select(db.generalAttachments)..orderBy([
              (t) => OrderingTerm.asc(t.messageId),
              (t) => OrderingTerm.asc(t.ord),
            ]))
            .get();

    final byChat = <String, List<GeneralMessageRow>>{};
    for (final m in messages) {
      (byChat[m.chatId] ??= []).add(m);
    }
    final byMessage = <String, List<GeneralAttachmentRow>>{};
    for (final a in attachments) {
      (byMessage[a.messageId] ??= []).add(a);
    }

    final files = <_Entry>[];
    var messageCount = 0;
    final chatList = <Map<String, Object?>>[];
    for (final c in chats) {
      final list = <Map<String, Object?>>[];
      for (final m in byChat[c.id] ?? const <GeneralMessageRow>[]) {
        messageCount++;
        final images = <Map<String, Object?>>[];
        for (final a in byMessage[m.id] ?? const <GeneralAttachmentRow>[]) {
          final file = 'images/${a.id}${_extension(a.mime)}';
          files.add(_Entry(file, a.bytes, compress: false));
          images.add({
            'id': a.id,
            'ord': a.ord,
            'mime': a.mime,
            'size': a.bytes.length,
            'file': file,
          });
        }
        list.add({..._messageJson(m), 'images': images});
      }
      chatList.add({..._chatJson(c), 'messages': list});
    }

    final settings = <String, Object?>{
      'favourites': await db.metaList(GeneralMetaKeys.favourites),
      'default_model': await db.meta(GeneralMetaKeys.defaultModel),
      'system_prompt': await db.meta(GeneralMetaKeys.systemPrompt),
      'show_tokens': await db.meta(GeneralMetaKeys.showTokens) == '1',
    };
    final manifest = <String, Object?>{
      'format': kExportFormat,
      'version': kExportVersion,
      'exported_at': at.toUtc().toIso8601String(),
      'schema': db.schemaVersion,
      'chats': chats.length,
      'messages': messageCount,
      'images': files.length,
    };
    const pretty = JsonEncoder.withIndent(' ');
    Uint8List text(Object o) => utf8.encode(pretty.convert(o));
    final entries = [
      _Entry(_manifestName, text(manifest)),
      _Entry(_chatsName, text({'chats': chatList})),
      _Entry(_settingsName, text(settings)),
      ...files,
    ];
    return GeneralExportFile(
      name: generalExportName(at),
      bytes: await _zipInBackground(entries),
      chats: chats.length,
      images: files.length,
    );
  }

  // ---- import

  /// Reads an export and merges it in one transaction; a file that is not
  /// an export, too new or damaged changes nothing ([GeneralImportError]).
  Future<GeneralImportResult> import(Uint8List bytes) async {
    final files = await _unzipInBackground(bytes);
    final export = _read(files);

    final result = await db.transaction(() async {
      final localChats = {
        for (final c in await db.select(db.generalChats).get()) c.id: c,
      };
      final localMessages = {
        for (final r
            in await (db.selectOnly(db.generalMessages)..addColumns([
                  db.generalMessages.id,
                  db.generalMessages.chatId,
                ]))
                .get())
          r.read(db.generalMessages.id)!: r.read(db.generalMessages.chatId)!,
      };
      final localImages = {
        for (final r in await (db.selectOnly(
          db.generalAttachments,
        )..addColumns([db.generalAttachments.id])).get())
          r.read(db.generalAttachments.id)!,
      };

      var created = 0;
      var updated = 0;
      var images = 0;
      for (final c in export.chats) {
        final local = localChats[c.row.id];
        final fileWins =
            local == null || c.row.updatedAt.isAfter(local.updatedAt);
        // (companions with explicit nulls: the file's empty fields win too)
        if (fileWins) {
          await db
              .into(db.generalChats)
              .insertOnConflictUpdate(c.row.toCompanion(false));
        }
        var added = 0;
        final fileIds = <String>{};
        for (final m in c.messages) {
          fileIds.add(m.row.id);
          final had = localMessages.containsKey(m.row.id);
          if (!had) {
            await db.into(db.generalMessages).insert(m.row);
            added++;
          } else if (fileWins && local != null) {
            await db
                .into(db.generalMessages)
                .insertOnConflictUpdate(m.row.toCompanion(false));
          }
          for (final a in m.images) {
            if (localImages.contains(a.id)) continue;
            await db.into(db.generalAttachments).insert(a);
            localImages.add(a.id);
            images++;
          }
        }
        if (local == null) {
          created++;
          continue;
        }
        final localExtra = localMessages.entries.any(
          (e) => e.value == c.row.id && !fileIds.contains(e.key),
        );
        // both sides wrote messages: one order, and totals that match them
        if (added > 0 && localExtra) await _renumber(c.row.id);
        if (added > 0 || (fileWins && localExtra)) await _retotal(c.row.id);
        if (fileWins || added > 0) updated++;
      }

      final s = export.settings;
      if (s != null) {
        await db.setMeta(
          GeneralMetaKeys.favourites,
          s.favourites == null ? null : jsonEncode(s.favourites),
        );
        await db.setMeta(GeneralMetaKeys.defaultModel, s.defaultModel);
        await db.setMeta(GeneralMetaKeys.systemPrompt, s.systemPrompt);
        await db.setMeta(GeneralMetaKeys.showTokens, s.showTokens ? '1' : null);
      }
      return GeneralImportResult(
        chats: export.chats.length,
        created: created,
        updated: updated,
        images: images,
        settings: s != null,
      );
    });
    return result;
  }

  /// Messages from both sides in one order: by time, then their old order.
  Future<void> _renumber(String chatId) async {
    final rows = await db.messages(chatId);
    final sorted = [...rows]
      ..sort((a, b) {
        final t = a.createdAt.compareTo(b.createdAt);
        if (t != 0) return t;
        final s = a.seq.compareTo(b.seq);
        return s != 0 ? s : a.id.compareTo(b.id);
      });
    for (final (i, m) in sorted.indexed) {
      if (m.seq != i + 1) {
        await db.updateMessage(
          m.id,
          GeneralMessagesCompanion(seq: Value(i + 1)),
        );
      }
    }
  }

  /// The chat's tokens and cost from its answers (as the chat service adds
  /// them up), when the merged messages differ from either side's.
  Future<void> _retotal(String chatId) async {
    var tokensIn = 0;
    var tokensOut = 0;
    var cost = 0.0;
    for (final m in await db.messages(chatId)) {
      if (m.role != 'assistant') continue;
      tokensIn += m.tokensIn ?? 0;
      tokensOut += m.tokensOut ?? 0;
      cost += m.costUsd ?? 0;
    }
    await db.updateChat(
      chatId,
      GeneralChatsCompanion(
        tokensIn: Value(tokensIn),
        tokensOut: Value(tokensOut),
        costUsd: Value(cost),
      ),
    );
  }
}

// ---- the file's parts

class _Entry {
  const _Entry(this.name, this.bytes, {this.compress = true});
  final String name;
  final Uint8List bytes;
  final bool compress;
}

String _extension(String mime) => switch (mime) {
  'image/jpeg' => '.jpg',
  'image/png' => '.png',
  'image/webp' => '.webp',
  _ => '',
};

/// Zipping copies and checksums every image: off the UI isolate.
Future<Uint8List> _zipInBackground(List<_Entry> entries) {
  final list = [for (final e in entries) (e.name, e.bytes, e.compress)];
  return Isolate.run(() => _zip(list));
}

Uint8List _zip(List<(String, Uint8List, bool)> entries) {
  final archive = Archive();
  for (final (name, bytes, compress) in entries) {
    archive.addFile(
      compress
          ? ArchiveFile.bytes(name, bytes)
          : ArchiveFile.noCompress(name, bytes.length, bytes),
    );
  }
  return ZipEncoder().encodeBytes(archive);
}

/// The files in a zip by name; null when it is not a zip.
Future<Map<String, Uint8List>?> _unzipInBackground(Uint8List bytes) =>
    Isolate.run(() => _unzip(bytes));

Map<String, Uint8List>? _unzip(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    return {
      for (final f in archive)
        if (f.isFile) f.name: f.readBytes() ?? Uint8List(0),
    };
  } on Object {
    return null;
  }
}

// ---- JSON

String? _iso(DateTime? t) => t?.toUtc().toIso8601String();

Map<String, Object?> _chatJson(GeneralChatRow c) => {
  'id': c.id,
  'title': c.title,
  'title_set': c.titleSet,
  'preview': c.preview,
  'model_id': c.modelId,
  'reasoning': c.reasoning,
  'reasoning_effort': c.reasoningEffort,
  'created_at': _iso(c.createdAt),
  'updated_at': _iso(c.updatedAt),
  'archived': c.archived,
  'tokens_in': c.tokensIn,
  'tokens_out': c.tokensOut,
  'cost_usd': c.costUsd,
  'last_prompt_tokens': c.lastPromptTokens,
  'last_context_length': c.lastContextLength,
};

Map<String, Object?> _messageJson(GeneralMessageRow m) => {
  'id': m.id,
  'seq': m.seq,
  'role': m.role,
  'content': m.content,
  'reasoning': m.reasoning,
  'model_id': m.modelId,
  'provider': m.provider,
  'status': m.status,
  'error_code': m.errorCode,
  'error_message': m.errorMessage,
  'retry_after_s': m.retryAfterS,
  'finish_reason': m.finishReason,
  'tokens_in': m.tokensIn,
  'tokens_out': m.tokensOut,
  'tokens_reasoning': m.tokensReasoning,
  'cost_usd': m.costUsd,
  'generation_id': m.generationId,
  'provider_warning': m.providerWarning,
  'created_at': _iso(m.createdAt),
};

class _ExportMessage {
  const _ExportMessage(this.row, this.images);
  final GeneralMessageRow row;
  final List<GeneralAttachmentRow> images;
}

class _ExportChat {
  const _ExportChat(this.row, this.messages);
  final GeneralChatRow row;
  final List<_ExportMessage> messages;
}

class _ExportSettings {
  const _ExportSettings({
    required this.favourites,
    required this.defaultModel,
    required this.systemPrompt,
    required this.showTokens,
  });
  final List<String>? favourites;
  final String? defaultModel;
  final String? systemPrompt;
  final bool showTokens;
}

class _Export {
  const _Export(this.chats, this.settings);
  final List<_ExportChat> chats;
  final _ExportSettings? settings;
}

/// A broken part of a Delve export.
class _Bad implements Exception {
  const _Bad(this.what);
  final String what;
}

/// Reads a JSON object's fields with their types.
class _Obj {
  _Obj(Object? v, this.where)
    : m = v is Map<String, Object?> ? v : throw _Bad('$where: not an object');

  final Map<String, Object?> m;
  final String where;

  Never _bad(String k) => throw _Bad('$where.$k');

  String str(String k) => switch (m[k]) {
    final String s => s,
    _ => _bad(k),
  };

  String? strOr(String k) => switch (m[k]) {
    null => null,
    final String s => s,
    _ => _bad(k),
  };

  int integer(String k) => switch (m[k]) {
    final int i => i,
    _ => _bad(k),
  };

  int? intOr(String k) => switch (m[k]) {
    null => null,
    final int i => i,
    _ => _bad(k),
  };

  double? numOr(String k) => switch (m[k]) {
    null => null,
    final num n => n.toDouble(),
    _ => _bad(k),
  };

  bool flag(String k, {bool or = false}) => switch (m[k]) {
    null => or,
    final bool b => b,
    _ => _bad(k),
  };

  DateTime time(String k) => DateTime.tryParse(str(k))?.toUtc() ?? _bad(k);

  List<Object?> list(String k) => switch (m[k]) {
    null => const [],
    final List<Object?> l => l,
    _ => _bad(k),
  };
}

Object? _json(Uint8List bytes, String name) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw _Bad(name);
  }
}

_Export _read(Map<String, Uint8List>? files) {
  if (files == null) {
    throw const GeneralImportError(GeneralImportProblem.notExport, 'not a zip');
  }
  final manifestBytes = files[_manifestName];
  if (manifestBytes == null) {
    throw const GeneralImportError(
      GeneralImportProblem.notExport,
      'no manifest.json',
    );
  }
  final Map<String, Object?> manifest;
  try {
    manifest = _Obj(_json(manifestBytes, _manifestName), _manifestName).m;
  } on _Bad {
    throw const GeneralImportError(
      GeneralImportProblem.notExport,
      'manifest.json is not JSON',
    );
  }
  if (manifest['format'] != kExportFormat) {
    throw GeneralImportError(
      GeneralImportProblem.notExport,
      'format ${manifest['format']}',
    );
  }
  final version = manifest['version'];
  if (version is! int) {
    throw const GeneralImportError(GeneralImportProblem.notExport, 'version');
  }
  if (version > kExportVersion) {
    throw GeneralImportError(GeneralImportProblem.tooNew, 'version $version');
  }
  try {
    final chatsBytes = files[_chatsName] ?? (throw const _Bad(_chatsName));
    final root = _Obj(_json(chatsBytes, _chatsName), _chatsName);
    final chats = <_ExportChat>[];
    final seen = <String>{};
    for (final (i, v) in root.list('chats').indexed) {
      final c = _Obj(v, 'chats[$i]');
      final id = c.str('id');
      if (!seen.add(id)) throw _Bad('chats[$i].id twice');
      final row = GeneralChatRow(
        id: id,
        title: c.strOr('title'),
        titleSet: c.flag('title_set'),
        preview: c.strOr('preview'),
        modelId: c.str('model_id'),
        reasoning: c.flag('reasoning', or: true),
        reasoningEffort: c.strOr('reasoning_effort'),
        createdAt: c.time('created_at'),
        updatedAt: c.time('updated_at'),
        archived: c.flag('archived'),
        tokensIn: c.intOr('tokens_in') ?? 0,
        tokensOut: c.intOr('tokens_out') ?? 0,
        costUsd: c.numOr('cost_usd') ?? 0,
        lastPromptTokens: c.intOr('last_prompt_tokens'),
        lastContextLength: c.intOr('last_context_length'),
      );
      final messages = <_ExportMessage>[];
      for (final (j, mv) in c.list('messages').indexed) {
        final m = _Obj(mv, 'chats[$i].messages[$j]');
        final mid = m.str('id');
        final status = m.str('status');
        final images = <GeneralAttachmentRow>[];
        for (final (k, av) in m.list('images').indexed) {
          final a = _Obj(av, '${m.where}.images[$k]');
          final file = a.str('file');
          final bytes = files[file] ?? (throw _Bad('missing $file'));
          images.add(
            GeneralAttachmentRow(
              id: a.str('id'),
              messageId: mid,
              ord: a.integer('ord'),
              mime: a.str('mime'),
              bytes: bytes,
              size: bytes.length,
            ),
          );
        }
        messages.add(
          _ExportMessage(
            GeneralMessageRow(
              id: mid,
              chatId: id,
              seq: m.integer('seq'),
              role: m.str('role'),
              content: m.strOr('content') ?? '',
              reasoning: m.strOr('reasoning'),
              modelId: m.strOr('model_id'),
              provider: m.strOr('provider'),
              // an answer cut off when the export was made
              status: status == 'streaming' ? 'stopped' : status,
              errorCode: m.strOr('error_code'),
              errorMessage: m.strOr('error_message'),
              retryAfterS: m.intOr('retry_after_s'),
              finishReason: m.strOr('finish_reason'),
              tokensIn: m.intOr('tokens_in'),
              tokensOut: m.intOr('tokens_out'),
              tokensReasoning: m.intOr('tokens_reasoning'),
              costUsd: m.numOr('cost_usd'),
              generationId: m.strOr('generation_id'),
              providerWarning: m.strOr('provider_warning'),
              createdAt: m.time('created_at'),
            ),
            images,
          ),
        );
      }
      chats.add(_ExportChat(row, messages));
    }

    _ExportSettings? settings;
    if (files[_settingsName] case final bytes?) {
      final s = _Obj(_json(bytes, _settingsName), _settingsName);
      final favs = s.m['favourites'];
      settings = _ExportSettings(
        favourites: switch (favs) {
          null => null,
          final List<Object?> l => [
            for (final e in l)
              if (e is String) e else throw const _Bad('favourites'),
          ],
          _ => throw const _Bad('favourites'),
        },
        defaultModel: s.strOr('default_model'),
        systemPrompt: s.strOr('system_prompt'),
        showTokens: s.flag('show_tokens'),
      );
    }
    return _Export(chats, settings);
  } on _Bad catch (e) {
    throw GeneralImportError(GeneralImportProblem.damaged, e.what);
  }
}
