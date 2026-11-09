import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:delve/app/router.dart';
import 'package:delve/attachments/picker.dart';
import 'package:delve/general/general_database.dart';
import 'package:delve/general/general_export.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attachments_test.dart' show FakeAttachmentApi, FakePicker, FakePrep;
import 'general_ui_test.dart' show go, pumpUntil, seedModels;
import 'support/fake_openrouter.dart';
import 'support/harness.dart';

DateTime at(int minute, [int second = 0]) =>
    DateTime.utc(2026, 11, 9, 10, minute, second);

Uint8List jpeg(int fill, [int length = 300]) =>
    Uint8List.fromList([0xff, 0xd8, ...List.filled(length, fill), 0xff, 0xd9]);

GeneralChatRow chatRow(
  String id, {
  String? title,
  DateTime? updated,
  bool archived = false,
  double cost = 0,
  int tokensIn = 0,
  int tokensOut = 0,
}) => GeneralChatRow(
  id: id,
  title: title ?? 'Chat $id',
  titleSet: false,
  preview: 'preview $id',
  modelId: 'z-ai/glm-5.3',
  reasoning: true,
  reasoningEffort: id == 'a' ? 'high' : null,
  createdAt: at(0),
  updatedAt: updated ?? at(5),
  archived: archived,
  tokensIn: tokensIn,
  tokensOut: tokensOut,
  costUsd: cost,
  lastPromptTokens: tokensIn == 0 ? null : tokensIn,
  lastContextLength: tokensIn == 0 ? null : 1048576,
);

GeneralMessageRow messageRow(
  String id,
  String chatId,
  int seq, {
  String role = 'user',
  String status = 'final',
  String content = 'hello',
  int? tokensIn,
  int? tokensOut,
  double? cost,
  DateTime? created,
}) => GeneralMessageRow(
  id: id,
  chatId: chatId,
  seq: seq,
  role: role,
  content: content,
  reasoning: role == 'assistant' ? 'Thinking.' : null,
  modelId: role == 'user' ? null : 'z-ai/glm-5.3',
  provider: role == 'assistant' ? 'Z.AI' : null,
  status: status,
  errorCode: status == 'failed' ? 'key_limit' : null,
  errorMessage: status == 'failed' ? 'Key limit reached' : null,
  tokensIn: tokensIn,
  tokensOut: tokensOut,
  costUsd: cost,
  generationId: role == 'assistant' ? 'gen-$id' : null,
  createdAt: created ?? at(1, seq),
);

/// Two chats (one archived) with a switch, a streaming and a failed answer,
/// two images, and every setting.
Future<void> seed(GeneralDatabase db) async {
  await db.batch((b) {
    b.insertAll(db.generalChats, [
      chatRow('a', cost: 0.0062, tokensIn: 1180, tokensOut: 330),
      chatRow('b', archived: true, updated: at(3)),
    ]);
    b.insertAll(db.generalMessages, [
      messageRow('a1', 'a', 1),
      messageRow(
        'a2',
        'a',
        2,
        role: 'assistant',
        content: 'Star and Finn.',
        tokensIn: 500,
        tokensOut: 30,
        cost: 0.0002,
      ),
      messageRow('a3', 'a', 3, role: 'switch', content: ''),
      messageRow('a4', 'a', 4),
      messageRow(
        'a5',
        'a',
        5,
        role: 'assistant',
        status: 'streaming',
        content: 'Half',
        tokensIn: 680,
        tokensOut: 300,
        cost: 0.006,
      ),
      messageRow('b1', 'b', 1),
      messageRow('b2', 'b', 2, role: 'assistant', status: 'failed'),
    ]);
    b.insertAll(db.generalAttachments, [
      GeneralAttachmentRow(
        id: 'img1',
        messageId: 'a1',
        ord: 0,
        mime: 'image/jpeg',
        bytes: jpeg(1),
        size: 304,
      ),
      GeneralAttachmentRow(
        id: 'img2',
        messageId: 'a4',
        ord: 0,
        mime: 'image/jpeg',
        bytes: jpeg(2),
        size: 304,
      ),
    ]);
  });
  await db.setMetaList(GeneralMetaKeys.favourites, [
    'z-ai/glm-5.3-flash',
    'z-ai/glm-5.3',
  ]);
  await db.setMeta(GeneralMetaKeys.defaultModel, 'moonshotai/kimi-k3.1-pro');
  await db.setMeta(GeneralMetaKeys.systemPrompt, 'Be brief.');
  await db.setMeta(GeneralMetaKeys.showTokens, '1');
}

Future<List<GeneralChatRow>> chatsOf(GeneralDatabase db) => (db.select(
  db.generalChats,
)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

Future<List<GeneralMessageRow>> messagesOf(GeneralDatabase db) =>
    (db.select(db.generalMessages)..orderBy([
          (t) => OrderingTerm.asc(t.chatId),
          (t) => OrderingTerm.asc(t.seq),
        ]))
        .get();

Future<List<GeneralAttachmentRow>> imagesOf(GeneralDatabase db) => (db.select(
  db.generalAttachments,
)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

Future<Uint8List> exportOf(GeneralDatabase db) async =>
    (await GeneralExporter(db, now: () => at(30)).export()).bytes;

/// A zip with these files (text as UTF-8).
Uint8List zipOf(Map<String, Object> files) {
  final a = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    a.addFile(
      value is Uint8List
          ? ArchiveFile.bytes(key, value)
          : ArchiveFile.string(
              key,
              value is String ? value : jsonEncode(value),
            ),
    );
  }
  return ZipEncoder().encodeBytes(a);
}

Map<String, Uint8List> filesOf(Uint8List zip) => {
  for (final f in ZipDecoder().decodeBytes(zip)) f.name: f.readBytes()!,
};

Map<String, Object?> jsonOf(Uint8List bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;

void main() {
  group('export', () {
    late GeneralDatabase src;
    late GeneralDatabase dst;
    setUp(() {
      src = memoryGeneralDb();
      dst = memoryGeneralDb();
    });
    tearDown(() async {
      await src.close();
      await dst.close();
    });

    test(
      'the zip: manifest, chats, settings and stored images; no key',
      () async {
        await seed(src);
        final file = await GeneralExporter(src, now: () => at(30)).export();
        expect(file.chats, 2);
        expect(file.images, 2);
        expect(file.name, startsWith('delve-general-2026-11-'));
        expect(file.name, endsWith('.zip'));

        final files = filesOf(file.bytes);
        expect(files.keys, {
          'manifest.json',
          'chats.json',
          'settings.json',
          'images/img1.jpg',
          'images/img2.jpg',
        });
        expect(jsonOf(files['manifest.json']!), {
          'format': 'delve-general-export',
          'version': 1,
          'exported_at': '2026-11-09T10:30:00.000Z',
          'schema': 2,
          'chats': 2,
          'messages': 7,
          'images': 2,
        });
        expect(files['images/img2.jpg'], jpeg(2));
        // JPEG is stored, not deflated
        final entry = ZipDecoder()
            .decodeBytes(file.bytes)
            .findFile('images/img1.jpg')!;
        expect(entry.compression, CompressionType.none);
        expect(jsonOf(files['settings.json']!), {
          'favourites': ['z-ai/glm-5.3-flash', 'z-ai/glm-5.3'],
          'default_model': 'moonshotai/kimi-k3.1-pro',
          'system_prompt': 'Be brief.',
          'show_tokens': true,
        });
        final all = utf8.decode(files['chats.json']!);
        expect(all, isNot(contains('sk-or-')));
        expect(all, isNot(contains('or_models')));
      },
    );

    test('round trip: export → empty database → import = the same', () async {
      await seed(src);
      final bytes = await exportOf(src);

      final r = await GeneralExporter(dst).import(bytes);
      expect(
        (r.chats, r.created, r.updated, r.images, r.settings),
        (2, 2, 0, 2, true),
      );
      expect(await chatsOf(dst), await chatsOf(src));
      final expected = [
        for (final m in await messagesOf(src))
          m.status == 'streaming' ? m.copyWith(status: 'stopped') : m,
      ];
      expect(await messagesOf(dst), expected);
      expect(await imagesOf(dst), await imagesOf(src));
      for (final k in [
        GeneralMetaKeys.favourites,
        GeneralMetaKeys.defaultModel,
        GeneralMetaKeys.systemPrompt,
        GeneralMetaKeys.showTokens,
      ]) {
        expect(await dst.meta(k), await src.meta(k), reason: k);
      }

      // the same file again changes nothing
      final again = await GeneralExporter(dst).import(bytes);
      expect(
        (again.chats, again.created, again.updated, again.images),
        (2, 0, 0, 0),
      );
      expect(await messagesOf(dst), expected);
    });

    test('merge by id: newer chat wins, messages and images joined', () async {
      await seed(src);
      final bytes = await exportOf(src);

      // the phone: `a` renamed later with an answer of its own; `b` older
      // and missing its answer; `c` only here; other settings
      await dst.batch((b) {
        b.insertAll(dst.generalChats, [
          chatRow('a', title: 'Renamed here', updated: at(20)),
          chatRow('b', title: 'Old b', updated: at(1), archived: true),
          chatRow('c', updated: at(2)),
        ]);
        b.insertAll(dst.generalMessages, [
          messageRow('a1', 'a', 1),
          messageRow(
            'a2',
            'a',
            2,
            role: 'assistant',
            content: 'Star and Finn.',
            tokensIn: 500,
            tokensOut: 30,
            cost: 0.0002,
          ),
          // written here after the export (same place as a3 in the file)
          messageRow(
            'x3',
            'a',
            3,
            role: 'assistant',
            content: 'Local answer',
            tokensIn: 100,
            tokensOut: 10,
            cost: 0.001,
            created: at(15),
          ),
          messageRow('b1', 'b', 1, content: 'edited here'),
          messageRow('c1', 'c', 1),
        ]);
        b.insert(
          dst.generalAttachments,
          GeneralAttachmentRow(
            id: 'img1',
            messageId: 'a1',
            ord: 0,
            mime: 'image/jpeg',
            bytes: jpeg(1),
            size: 304,
          ),
        );
      });
      await dst.setMeta(GeneralMetaKeys.systemPrompt, 'Local prompt');

      final r = await GeneralExporter(dst).import(bytes);
      expect((r.chats, r.created, r.updated, r.images), (2, 0, 2, 1));

      final chats = {for (final c in await chatsOf(dst)) c.id: c};
      expect(chats.keys, {'a', 'b', 'c'});
      expect(chats['a']!.title, 'Renamed here'); // the phone's is newer
      expect(chats['b']!.title, 'Chat b'); // the file's is newer
      expect(chats['c']!.title, 'Chat c'); // only here: untouched

      final a = await dst.messages('a');
      // one order for both sides: by time, the local answer last
      expect([for (final m in a) m.id], ['a1', 'a2', 'a3', 'a4', 'a5', 'x3']);
      expect([for (final m in a) m.seq], [1, 2, 3, 4, 5, 6]);
      expect(a.firstWhere((m) => m.id == 'a5').status, 'stopped');
      // the totals add up the merged answers
      expect(chats['a']!.tokensIn, 500 + 680 + 100);
      expect(chats['a']!.tokensOut, 30 + 300 + 10);
      expect(chats['a']!.costUsd, closeTo(0.0002 + 0.006 + 0.001, 1e-9));

      // the file's chat won: its version of b1, and the missing answer
      final b = await dst.messages('b');
      expect([for (final m in b) m.id], ['b1', 'b2']);
      expect(b.first.content, 'hello');

      expect([for (final i in await imagesOf(dst)) i.id], ['img1', 'img2']);
      expect(await dst.meta(GeneralMetaKeys.systemPrompt), 'Be brief.');
    });

    test(
      'settings from the file replace the phone\'s, empty ones too',
      () async {
        // the source has none: favourites back to the defaults, no prompt
        final bytes = await exportOf(src);
        await dst.setMetaList(GeneralMetaKeys.favourites, ['x/y']);
        await dst.setMeta(GeneralMetaKeys.systemPrompt, 'Local prompt');
        await dst.setMeta(GeneralMetaKeys.showTokens, '1');

        final r = await GeneralExporter(dst).import(bytes);
        expect((r.chats, r.created, r.settings), (0, 0, true));
        expect(await dst.meta(GeneralMetaKeys.favourites), isNull);
        expect(await dst.meta(GeneralMetaKeys.systemPrompt), isNull);
        expect(await dst.meta(GeneralMetaKeys.showTokens), isNull);
      },
    );

    Future<GeneralImportProblem> problemOf(Uint8List bytes) async {
      try {
        await GeneralExporter(dst).import(bytes);
      } on GeneralImportError catch (e) {
        return e.problem;
      }
      fail('imported');
    }

    test('wrong files: not a zip, no manifest, another format, too new, '
        'damaged – nothing changes', () async {
      await seed(src);
      final good = filesOf(await exportOf(src));
      final manifest = jsonOf(good['manifest.json']!);

      expect(
        await problemOf(Uint8List.fromList(utf8.encode('just text'))),
        GeneralImportProblem.notExport,
      );
      expect(
        await problemOf(zipOf({'chats.json': good['chats.json']!})),
        GeneralImportProblem.notExport,
      );
      expect(
        await problemOf(
          zipOf({
            'manifest.json': {...manifest, 'format': 'something-else'},
          }),
        ),
        GeneralImportProblem.notExport,
      );
      expect(
        await problemOf(
          zipOf({
            ...good,
            'manifest.json': {...manifest, 'version': 2},
          }),
        ),
        GeneralImportProblem.tooNew,
      );
      expect(
        await problemOf(zipOf({'manifest.json': good['manifest.json']!})),
        GeneralImportProblem.damaged,
      );
      // an image listed but missing: the whole file is refused
      expect(
        await problemOf(zipOf({...good}..remove('images/img2.jpg'))),
        GeneralImportProblem.damaged,
      );
      expect(
        await problemOf(
          zipOf({
            ...good,
            'chats.json': {
              'chats': [
                {'id': 'z', 'model_id': 'm'},
              ],
            },
          }),
        ),
        GeneralImportProblem.damaged,
      );
      expect(await chatsOf(dst), isEmpty);
      expect(await dst.meta(GeneralMetaKeys.systemPrompt), isNull);
    });
  });

  group('Settings → General', () {
    Finder settingsList() => find
        .descendant(
          of: find.byKey(const Key('generalSettings.list')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> open(WidgetTester tester, Key row) async {
      await go(tester, Routes.generalSettings);
      await pumpUntil(
        tester,
        find.byKey(const Key('generalSettings.spend.line')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(row),
        200,
        scrollable: settingsList(),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Export chats → Downloads/Delve, then Share', (tester) async {
      final env = await pumpDelve(
        tester,
        generalKey: testOpenRouterKey,
        before: (env) async {
          await seedModels(env);
          await seed(env.general);
        },
      );
      await open(tester, const Key('generalSettings.export'));
      expect(find.text('Export chats'), findsOneWidget);

      await tester.tap(find.byKey(const Key('generalSettings.export')));
      await pumpUntil(
        tester,
        find.byKey(const Key('generalSettings.exported')),
      );
      expect(find.text('Exported 2 chats to Downloads/Delve'), findsOneWidget);

      final device = env.terminal.device;
      expect(device.published, hasLength(1));
      final (name, mime, bytes) = device.published.single;
      expect(
        name,
        matches(RegExp(r'^delve-general-\d{4}-\d\d-\d\d-\d{4}\.zip$')),
      );
      expect(mime, 'application/zip');
      expect(device.publishedIn.single, isNull);
      expect(jsonOf(filesOf(bytes)['manifest.json']!)['chats'], 2);

      // the snack bar in place (it slides in), then its action
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();
      expect(device.shared, [
        ('content://media/external/downloads/1', 'application/zip'),
      ]);
    });

    testWidgets('Import chats: a wrong file, another pick, the result', (
      tester,
    ) async {
      final exported = memoryGeneralDb();
      // closed on real time, as the harness closes its own
      addTearDown(() => tester.runAsync(exported.close));
      late Uint8List good;
      final picker = FakePicker()
        ..next = [
          PickedAttachment(
            kind: 'file',
            name: 'notes.txt',
            read: () async => Uint8List.fromList(utf8.encode('not a zip')),
          ),
        ];
      final env = await pumpDelve(
        tester,
        generalKey: testOpenRouterKey,
        attachments: AttachmentFakes(
          api: FakeAttachmentApi(),
          picker: picker,
          prep: FakePrep(),
        ),
        before: (env) async {
          await seedModels(env);
          await seed(exported);
          good = await exportOf(exported);
        },
      );
      await open(tester, const Key('generalSettings.import'));

      await tester.tap(find.byKey(const Key('generalSettings.import')));
      await pumpUntil(
        tester,
        find.byKey(const Key('generalSettings.importProblem')),
      );
      expect(find.text("This file isn't a Delve export"), findsOneWidget);
      expect(picker.asked, ['files 1']);

      picker.next = [
        PickedAttachment(
          kind: 'file',
          name: 'delve-general.zip',
          read: () async => good,
        ),
      ];
      await tester.tap(find.byKey(const Key('generalSettings.importAgain')));
      await pumpUntil(
        tester,
        find.byKey(const Key('generalSettings.imported')),
      );
      expect(
        find.text('Imported 2 chats — 2 new, 0 updated, 2 images'),
        findsOneWidget,
      );
      expect(picker.asked, ['files 1', 'files 1']);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('generalSettings.imported')), findsNothing);

      final chats = await tester.runAsync(() => chatsOf(env.general));
      expect([for (final c in chats!) c.id], ['a', 'b']);
      // the imported system prompt is in the field
      final prompt = find.byKey(const Key('generalSettings.prompt'));
      await tester.scrollUntilVisible(prompt, -200, scrollable: settingsList());
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(prompt).controller!.text, 'Be brief.');
    });
  });
}
