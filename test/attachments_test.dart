import 'dart:async';
import 'dart:typed_data';

import 'package:delve/api/api_error.dart';
import 'package:delve/api/models/models.dart';
import 'package:delve/api/rest_client.dart';
import 'package:delve/attachments/attachment_store.dart';
import 'package:delve/attachments/composer_attachments.dart';
import 'package:delve/attachments/image_prep.dart';
import 'package:delve/attachments/picker.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/sync/connection_status.dart';
import 'package:delve/ui/format.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_screen_test.dart' show FakeChatActions, conversation, liveStatus;
import 'support/fake_server.dart';
import 'support/harness.dart';

/// A 1×1 PNG (decodes in widget tests).
final png = Uint8List.fromList([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0xcf, 0xc0, 0xf0,
  0x1f, 0x00, 0x05, 0x00, 0x01, 0xff, 0x89, 0x99, 0x3d, 0x1d, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

class FakePrep implements ImagePrep {
  bool fail = false;
  final calls = <int>[];

  @override
  Future<Uint8List> prepare(Uint8List source) async {
    calls.add(source.length);
    if (fail) throw const ImagePrepFailed('nope');
    return png;
  }
}

/// Uploads answer when [gate] completes (null: at once).
class FakeAttachmentApi implements AttachmentApi {
  final uploads = <(String, String, String, int)>[];
  final copies = <String>[];
  Object? error;
  Completer<void>? gate;
  int _n = 0;

  Attachment _made(String kind, String name, String mime, int size) =>
      Attachment(
        id: 'att_${++_n}',
        kind: kind,
        mime: mime,
        filename: name,
        sizeBytes: size,
      );

  @override
  Future<Attachment> upload({
    required String kind,
    required String filename,
    required String mime,
    required Uint8List bytes,
  }) async {
    uploads.add((kind, filename, mime, bytes.length));
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return _made(kind, filename, mime, bytes.length);
  }

  @override
  Future<Attachment> copy(String id) async {
    copies.add(id);
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return _made('image', 'copy.jpg', 'image/jpeg', 1);
  }

  @override
  Future<Uint8List> bytes(String id) async => png;
}

class FakePicker implements AttachmentPicker {
  List<PickedAttachment> next = [];
  final asked = <String>[];

  @override
  Future<List<PickedAttachment>> photos({required int limit}) async {
    asked.add('photos $limit');
    return next;
  }

  @override
  Future<PickedAttachment?> camera() async {
    asked.add('camera');
    return next.firstOrNull;
  }

  @override
  Future<List<PickedAttachment>> files({required int limit}) async {
    asked.add('files $limit');
    return next;
  }
}

PickedAttachment photo([String name = 'IMG_1.HEIC']) => PickedAttachment(
  kind: 'image',
  name: name,
  read: () async => Uint8List(5000),
);

PickedAttachment file(String name, {int size = 12, String? mime}) =>
    PickedAttachment(
      kind: 'file',
      name: name,
      mime: mime,
      size: size,
      read: () async => Uint8List(size),
    );

Future<void> settle(ComposerAttachments c) async {
  for (var i = 0; i < 20 && c.busy; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('helpers', () {
    test('the compress bound makes the longer side 1536, never larger', () {
      expect(compressBound(1080, 2400), 691); // screenshot → 691 × 1536
      expect(compressBound(4000, 3000), 1152); // photo → 1536 × 1152
      expect(compressBound(3000, 4000), 1152); // rotated: the same
      expect(compressBound(690, 1536), 690); // already small: unchanged
      expect(compressBound(400, 300), 300);
      expect(compressBound(0, 0), 1152);
    });

    test('names, types and sizes', () {
      expect(mimeForName('report.PDF'), 'application/pdf');
      expect(mimeForName('dmesg.log'), 'text/plain');
      expect(mimeForName('a.tar.gz'), 'application/gzip');
      expect(mimeForName('noext'), 'application/octet-stream');
      expect(isImageName('IMG_1.HEIC'), isTrue);
      expect(isImageName('scan.pdf'), isFalse);
      expect(byteSize(812), '812 B');
      expect(byteSize(64895), '63 KB');
      expect(byteSize(5 * 1024), '5.0 KB');
      expect(byteSize(1468006), '1.4 MB');
      expect(byteSize(20 * 1024 * 1024), '20 MB');
    });

    test('the image cache keeps the newest', () {
      final c = AttachmentCache(capacity: 2)
        ..put('a', png)
        ..put('b', png);
      expect(c.get('a'), isNotNull); // a is now the newest
      c.put('c', png);
      expect((c.get('a'), c.get('b'), c.get('c')), (png, null, png));
    });
  });

  group('composer attachments', () {
    late FakeAttachmentApi api;
    late FakePrep prep;
    late AttachmentCache cache;
    late ComposerAttachments c;
    setUp(() {
      api = FakeAttachmentApi();
      prep = FakePrep();
      cache = AttachmentCache();
      c = ComposerAttachments(api: () => api, prep: prep, cache: cache);
    });
    tearDown(() => c.dispose());

    test('a photo is resized to JPEG and uploaded; the cache has it', () async {
      api.gate = Completer<void>();
      c.addAll([photo()]);
      expect(c.busy, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(c.items.single.state, DraftState.uploading);
      expect(c.items.single.filename, 'IMG_1.jpg');
      api.gate!.complete();
      await settle(c);
      final d = c.items.single;
      expect((d.state, d.uploaded!.id), (DraftState.ready, 'att_1'));
      expect(api.uploads.single, (
        'image',
        'IMG_1.jpg',
        'image/jpeg',
        png.length,
      ));
      expect(prep.calls, [5000]);
      expect(cache.get('att_1'), png);
      expect(c.ready.map((a) => a.id), ['att_1']);
    });

    test('a file goes as it is, with its type', () async {
      c.addAll([
        file('dmesg.log'),
        file('scan.bin', mime: 'application/x-raw'),
      ]);
      await settle(c);
      expect(api.uploads, [
        ('file', 'dmesg.log', 'text/plain', 12),
        ('file', 'scan.bin', 'application/x-raw', 12),
      ]);
      expect(prep.calls, isEmpty);
    });

    test('too large and unreadable fail without an upload', () async {
      prep.fail = true;
      c.addAll([file('big.iso', size: kMaxFileBytes + 1), photo('x.png')]);
      await settle(c);
      expect(c.items.map((d) => d.state), [
        DraftState.failed,
        DraftState.failed,
      ]);
      expect(c.items.first.problem, isA<DraftTooLarge>());
      expect(c.items.last.problem, isA<DraftUnreadable>());
      expect(c.hasFailed, isTrue);
      expect(c.ready, isEmpty);
      expect(api.uploads, isEmpty);
    });

    test('a failed upload is retried with the prepared bytes', () async {
      api.error = const ApiRequestError(502);
      c.addAll([photo()]);
      await settle(c);
      final d = c.items.single;
      expect(d.state, DraftState.failed);
      expect(d.problem, isA<DraftUploadFailed>());
      api.error = null;
      c.retry(d.localId);
      await settle(c);
      expect(c.items.single.state, DraftState.ready);
      expect(prep.calls, hasLength(1), reason: 'not prepared again');
      expect(api.uploads, hasLength(2));
    });

    test('at most four; the rest is counted', () async {
      expect(c.addAll([for (var i = 0; i < 6; i++) file('f$i.txt')]), 2);
      expect((c.items.length, c.room), (kMaxAttachments, 0));
      await settle(c);
      expect(c.addCopy(c.ready.first), isFalse);
    });

    test('removed while uploading: the late answer is dropped', () async {
      api.gate = Completer<void>();
      c.addAll([file('a.txt')]);
      await Future<void>.delayed(Duration.zero);
      c.remove(c.items.single.localId);
      api.gate!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(c.items, isEmpty);
    });

    test('send again copies on the server', () async {
      final earlier = Attachment.fromJson(FakeServer.sample('attachment'));
      expect(c.addCopy(earlier, preview: png), isTrue);
      await settle(c);
      expect(api.copies, [earlier.id]);
      final d = c.items.single;
      expect(
        (d.state, d.uploaded!.id, d.preview),
        (DraftState.ready, 'att_1', png),
      );
      expect(cache.get('att_1'), png);
    });
  });

  group('REST', () {
    late FakeServer server;
    late DelveApi api;
    setUp(() {
      server = FakeServer();
      api = DelveApi(server: testServer, token: 't', adapter: server);
    });

    test('upload sends the bytes with their type and the name', () async {
      server.on(
        'POST',
        '/api/v1/attachments',
        (_) => FakeReply(201, FakeServer.sample('attachment')),
      );
      final a = await api.uploadAttachment(
        kind: 'image',
        filename: 'screen.jpg',
        mime: 'image/jpeg',
        bytes: png,
      );
      expect(a.filename, 'screen.jpg');
      final r = server.requests.single;
      expect(r.queryParameters, {'kind': 'image', 'filename': 'screen.jpg'});
      expect(r.contentType, 'image/jpeg');
      expect(r.data, png);
    });

    test('bytes and copy; a deleted one is a 410', () async {
      final id = FakeServer.sample('attachment')['id']! as String;
      server
        ..on('GET', '/api/v1/attachments/$id', (_) => FakeReply(200, png))
        ..on(
          'POST',
          '/api/v1/attachments/$id/copy',
          (_) =>
              FakeReply(201, {...FakeServer.sample('attachment'), 'id': 'x'}),
        )
        ..json(
          'GET',
          '/api/v1/attachments/gone',
          FakeServer.detail('attachment_gone'),
          status: 410,
        );
      expect(await api.attachmentBytes(id), png);
      expect((await api.copyAttachment(id)).id, 'x');
      await expectLater(
        api.attachmentBytes('gone'),
        throwsA(isA<ApiRequestError>().having((e) => e.status, 'status', 410)),
      );
    });
  });

  group('chat', () {
    late FakeChatActions actions;
    late FakeAttachmentApi api;
    late FakePicker picker;
    setUp(() {
      actions = FakeChatActions();
      api = FakeAttachmentApi();
      picker = FakePicker();
    });

    Future<TestEnv> start(
      WidgetTester t, {
      bool live = true,
      List<Attachment> sent = const [],
    }) => pumpDelve(
      t,
      actions: actions,
      status: live ? liveStatus : ConnectionStatus.initial,
      attachments: AttachmentFakes(api: api, picker: picker, prep: FakePrep()),
      before: (env) async {
        actions.db = env.db;
        await env.db.putConversation(conversation('c_1'));
        await env.db
            .into(env.db.messages)
            .insert(
              MessagesCompanion.insert(
                id: const Value(1),
                conversationId: 'c_1',
                runId: const Value('run_a'),
                role: 'user',
                content: 'What is this?',
                status: 'final',
                createdAt: DateTime.utc(2026, 10, 20, 8),
                attachments: Value(sent),
              ),
            );
      },
    );

    Future<void> open(WidgetTester t) async {
      await t.tap(find.text('Kernel check'));
      await t.pumpAndSettle();
    }

    testWidgets('+ → Photos: the chip uploads, Send binds it', (t) async {
      await start(t);
      await open(t);
      picker.next = [photo()];
      await t.tap(find.byKey(const Key('composer.add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('attach.photos')));
      await t.pumpAndSettle();
      expect(picker.asked, ['photos 4']);
      expect(find.text('IMG_1.jpg'), findsOneWidget);
      await t.enterText(find.byKey(const Key('composer.field')), 'look');
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(actions.calls.last, 'send look c_1 [att_1]');
      expect(find.byKey(const Key('composer.attachments')), findsNothing);
    });

    testWidgets('a failed upload blocks Send; retried, it can go alone', (
      t,
    ) async {
      await start(t);
      await open(t);
      api.error = const ApiRequestError(413, code: 'too_large');
      picker.next = [file('big.log')];
      await t.tap(find.byKey(const Key('composer.add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('attach.file')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('draft.problem')), findsOneWidget);
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pump();
      expect(actions.calls.where((c) => c.startsWith('send')), isEmpty);

      api.error = null;
      await t.tap(find.text('big.log')); // tap retries
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(actions.calls.last, 'send  c_1 [att_1]');
    });

    testWidgets('offline: + is off', (t) async {
      await start(t, live: false);
      await open(t);
      final add = t.widget<Semantics>(
        find
            .descendant(
              of: find.byKey(const Key('composer.add')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(add.properties.enabled, isFalse);
    });

    testWidgets('a sent photo shows; tapping opens it with Send again', (
      t,
    ) async {
      final sent = Attachment.fromJson(FakeServer.sample('attachment'));
      await start(t, sent: [sent]);
      await open(t);
      expect(find.byKey(ValueKey('att.${sent.id}')), findsOneWidget);
      await t.tap(find.byKey(ValueKey('att.${sent.id}')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('viewer.sendAgain')));
      await t.pumpAndSettle();
      expect(api.copies, [sent.id]);
      expect(find.text('copy.jpg'), findsOneWidget);
    });

    testWidgets('a deleted photo says so, and offers no viewer', (t) async {
      final gone = Attachment.fromJson(
        FakeServer.sample('attachment'),
      ).copyWith(available: false);
      await start(t, sent: [gone]);
      await open(t);
      expect(find.text('No longer available'), findsOneWidget);
    });
  });
}
