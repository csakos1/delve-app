import 'dart:async';
import 'dart:io';

import 'package:delve/data/db/store.dart';
import 'package:delve/share/share_channel.dart';
import 'package:delve/sync/connection_status.dart';
import 'package:delve/ui/screens/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attachments_test.dart'
    show FakeAttachmentApi, FakePicker, FakePrep, file, photo;
import 'chat_screen_test.dart' show FakeChatActions, conversation, liveStatus;
import 'support/harness.dart';

/// Shares added by the test (single listener, like the platform's).
class ManualShareSource implements ShareSource {
  final _out = StreamController<SharedPayload>();

  void add(SharedPayload p) => _out.add(p);

  @override
  Stream<SharedPayload> get shares => _out.stream;

  @override
  void dispose() => unawaited(_out.close());
}

void main() {
  group('payload', () {
    test('parses files, kinds, sizes and the text', () async {
      final dir = await Directory.systemTemp.createTemp('share');
      addTearDown(() => dir.delete(recursive: true));
      final notes = File('${dir.path}/notes.txt')..writeAsStringSync('hi');
      final p = SharedPayload.parse(<Object?, Object?>{
        'files': [
          {
            'name': 'notes.txt',
            'mime': 'text/plain',
            'size': 2,
            'path': notes.path,
          },
          {'name': 'shot', 'mime': 'image/png', 'size': 10, 'path': notes.path},
          {'name': 'big.iso', 'mime': null, 'size': 30000000, 'path': null},
          {'name': '', 'path': notes.path}, // no name: left out
        ],
        'text': '  Arch news\nhttps://archlinux.org  ',
        'skipped': 2,
        'failed': 1,
      })!;
      expect([for (final f in p.files) f.kind], ['file', 'image', 'file']);
      expect(
        [for (final f in p.files) f.name],
        ['notes.txt', 'shot', 'big.iso'],
      );
      expect(p.files[2].mime, 'application/octet-stream');
      expect(p.files[2].size, 30000000);
      expect(await p.files[0].read(), [104, 105]);
      await expectLater(p.files[2].read(), throwsA(isA<FileSystemException>()));
      expect(p.text, 'Arch news\nhttps://archlinux.org');
      expect(p.skipped, 2);
      expect(p.failed, 1);
    });

    test('nothing usable is null; a failure alone is kept', () {
      expect(SharedPayload.parse(null), isNull);
      expect(SharedPayload.parse('text'), isNull);
      expect(
        SharedPayload.parse(<Object?, Object?>{
          'files': <Object?>[],
          'text': ' ',
        }),
        isNull,
      );
      final failed = SharedPayload.parse(<Object?, Object?>{'failed': 1});
      expect(failed?.failed, 1);
    });

    test('photos by name or type; two shares merge', () {
      expect(sharedKind('IMG_1.HEIC', null), 'image');
      expect(sharedKind('photo', 'image/webp'), 'image');
      expect(sharedKind('anim.gif', 'image/gif'), 'file');
      expect(sharedKind('log.txt', 'text/plain'), 'file');
      final a = SharedPayload(files: [file('a.log')], text: 'one');
      final b = SharedPayload(files: [file('b.log')], text: 'two', skipped: 1);
      final m = a.merge(b);
      expect([for (final f in m.files) f.name], ['a.log', 'b.log']);
      expect((m.text, m.skipped), ('one\ntwo', 1));
      expect(a.merge(const SharedPayload()).text, 'one');
    });
  });

  group('platform channel', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('hu.csakos.delve/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    test(
      'takes the share at start and again when the activity says so',
      () async {
        final answers = <Object?>[
          <Object?, Object?>{'text': 'first'},
          <Object?, Object?>{'text': 'second'},
        ];
        final methods = <String>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          methods.add(call.method);
          return answers.isEmpty ? null : answers.removeAt(0);
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

        final source = PlatformShareSource();
        addTearDown(source.dispose);
        await pumpEventQueue();
        // the first share waits for the listener
        final got = <String?>[];
        final sub = source.shares.listen((p) => got.add(p.text));
        addTearDown(sub.cancel);
        await pumpEventQueue();
        expect(got, ['first']);

        await messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('changed'),
          ),
          (_) {},
        );
        await pumpEventQueue();
        expect(got, ['first', 'second']);
        expect(methods, ['take', 'take']);
      },
    );

    test('no platform side: nothing, no error', () async {
      final source = PlatformShareSource(const MethodChannel('nowhere'));
      addTearDown(source.dispose);
      final got = <SharedPayload>[];
      final sub = source.shares.listen(got.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(got, isEmpty);
    });
  });

  group('Share to Delve', () {
    late FakeChatActions actions;
    late FakeAttachmentApi api;
    late ManualShareSource source;
    setUp(() {
      actions = FakeChatActions();
      api = FakeAttachmentApi();
      source = ManualShareSource();
    });

    Future<TestEnv> start(
      WidgetTester t, {
      bool paired = true,
      bool live = true,
    }) => pumpDelve(
      t,
      paired: paired,
      actions: actions,
      status: live ? liveStatus : ConnectionStatus.initial,
      attachments: AttachmentFakes(
        api: api,
        picker: FakePicker(),
        prep: FakePrep(),
      ),
      share: source,
      before: (env) async {
        actions.db = env.db;
        await env.db.putConversation(conversation('c_1'));
      },
    );

    Future<void> share(WidgetTester t, SharedPayload p) async {
      source.add(p);
      await t.pumpAndSettle();
    }

    String field(WidgetTester t) => t
        .widget<TextField>(find.byKey(const Key('composer.field')))
        .controller!
        .text;

    testWidgets('a photo and a question go to a new chat by default', (
      t,
    ) async {
      await start(t);
      await share(
        t,
        SharedPayload(files: [photo('Screenshot_1.png')], text: 'Normal?'),
      );
      expect(find.text('Share to Delve'), findsOneWidget);
      expect(
        find.text('Thinking off · starts a new conversation'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('share.chat.c_1')), findsOneWidget);
      expect(find.text('Screenshot_1.jpg'), findsOneWidget);
      expect(field(t), 'Normal?');

      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(actions.calls, contains('send Normal? null [att_1]'));
      // the new chat shows the message until the server makes the chat
      expect(find.text('Share to Delve'), findsNothing);
      expect(find.text('Normal?'), findsOneWidget);
    });

    testWidgets('Thinking for the new chat goes with its first message', (
      t,
    ) async {
      await start(t);
      await share(t, const SharedPayload(text: 'Explain this'));
      await t.tap(find.byKey(const Key('composer.thinking')));
      await t.pumpAndSettle();
      expect(
        find.text('Thinking on · starts a new conversation'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(actions.calls, contains('send Explain this null thinking'));
    });

    testWidgets('an existing chat: its Thinking, Send opens it', (t) async {
      await start(t);
      await share(t, const SharedPayload(text: 'https://archlinux.org/news'));
      await t.tap(find.byKey(const ValueKey('share.chat.c_1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('composer.thinking')));
      await t.pumpAndSettle();
      expect(actions.calls, contains('thinking c_1 true'));
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pumpAndSettle();
      expect(actions.calls, contains('send https://archlinux.org/news c_1'));
      expect(find.byKey(const Key('chat.title')), findsOneWidget);
      expect(find.text('Kernel check'), findsWidgets);
    });

    testWidgets('more than four: four chips and a note', (t) async {
      await start(t);
      await share(
        t,
        SharedPayload(
          files: [
            for (final n in ['a', 'b', 'c', 'd', 'e']) file('$n.log'),
          ],
          skipped: 1,
        ),
      );
      expect(find.text('d.log'), findsOneWidget);
      expect(find.text('e.log'), findsNothing);
      expect(find.text('2 were left out: up to 4 per message'), findsOneWidget);
    });

    testWidgets('a second share while open adds to the message', (t) async {
      await start(t);
      await share(t, SharedPayload(files: [file('a.log')], text: 'one'));
      await share(t, SharedPayload(files: [file('b.log')], text: 'two'));
      expect(find.text('a.log'), findsOneWidget);
      expect(find.text('b.log'), findsOneWidget);
      expect(field(t), 'one\ntwo');
      expect(find.byType(ShareScreen, skipOffstage: false), findsOneWidget);
      expect(find.text('Share to Delve'), findsOneWidget);
    });

    testWidgets('unreadable items are reported', (t) async {
      await start(t);
      await share(t, const SharedPayload(text: 'x', failed: 2));
      expect(find.text('2 shared items could not be read'), findsOneWidget);
    });

    testWidgets('close: back where the user was, nothing sent', (t) async {
      await start(t);
      await share(t, SharedPayload(files: [file('a.log')]));
      await t.tap(find.byKey(const Key('share.close')));
      await t.pumpAndSettle();
      expect(find.text('Share to Delve'), findsNothing);
      expect(find.text('Kernel check'), findsOneWidget);
      expect(actions.calls.where((c) => c.startsWith('send')), isEmpty);
    });

    testWidgets('offline: text can go, attachments wait for the connection', (
      t,
    ) async {
      await start(t, live: false);
      await share(t, SharedPayload(files: [file('a.log')], text: 'hi'));
      expect(find.text('Attachments need a live connection'), findsOneWidget);
      await t.tap(find.byKey(const Key('composer.send')));
      await t.pump();
      expect(actions.calls.where((c) => c.startsWith('send')), isEmpty);
    });

    testWidgets('not paired: the share waits', (t) async {
      await start(t, paired: false);
      await share(t, const SharedPayload(text: 'later'));
      expect(find.text('Share to Delve'), findsNothing);
      expect(find.text('Pair this phone'), findsOneWidget);
    });

    testWidgets('a big text size does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await start(t);
      await share(
        t,
        SharedPayload(
          files: [photo('Screenshot_20261019.png')],
          text: 'Normal?',
        ),
      );
      expect(find.text('Share to Delve'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
