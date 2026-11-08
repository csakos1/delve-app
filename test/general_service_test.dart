import 'package:delve/data/db/database.dart';
import 'package:delve/general/general_database.dart';
import 'package:delve/general/general_service.dart';
import 'package:delve/general/openrouter_client.dart';
import 'package:delve/general/openrouter_errors.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_openrouter.dart';

void main() {
  late GeneralDatabase db;
  late FakeOpenRouter fake;
  late OpenRouterClient client;
  late GeneralChatService service;
  OpenRouterClient? current;
  var now = DateTime.utc(2026, 11, 9, 21, 14);

  setUp(() async {
    db = memoryGeneralDb();
    fake = FakeOpenRouter();
    client = OpenRouterClient(key: 'sk-or-v1-test', adapter: fake);
    current = client;
    now = DateTime.utc(2026, 11, 9, 21, 14);
    service = GeneralChatService(
      db: db,
      client: () => current,
      now: () => now,
      flushEvery: Duration.zero,
      costLookupDelays: const [Duration.zero, Duration.zero],
    );
    await service.catalog.refresh(client);
    fake.requests.clear();
  });

  tearDown(() async {
    service.dispose();
    await service.idle();
    client.close();
    await db.close();
  });

  FakeChatReply glmAnswer({
    String text = 'Star and Finn.',
    String provider = 'Z.AI',
    String model = 'z-ai/glm-5.3',
  }) => FakeChatReply.sse(
    sseOf([
      chunk(reasoning: 'Thinking.', provider: provider, model: model),
      chunk(content: text, provider: provider, model: model),
      chunk(finish: 'stop', provider: provider, model: model),
      chunk(
        finish: 'stop',
        provider: provider,
        model: model,
        usage: {
          'prompt_tokens': 120,
          'completion_tokens': 30,
          'total_tokens': 150,
          'cost': 0.0002,
          'completion_tokens_details': {'reasoning_tokens': 10},
        },
      ),
    ]),
  );

  Future<List<GeneralMessageRow>> msgs(String chatId) => db.messages(chatId);

  Future<void> until(Future<bool> Function() ok) async {
    for (var i = 0; i < 400; i++) {
      if (await ok()) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('condition not reached');
  }

  test('the General tables are not in the agent database', () {
    final agent = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(agent.close);
    final names = {for (final t in agent.allTables) t.actualTableName};
    for (final t in db.allTables) {
      expect(names, isNot(contains(t.actualTableName)));
    }
    expect(GeneralDatabase.fileName, isNot('delve'));
  });

  test('a new chat uses the default model', () async {
    final id = await service.createChat();
    final chat = (await db.chat(id))!;
    expect(chat.modelId, 'z-ai/glm-5.3');
    expect(chat.title, isNull);
    expect(chat.reasoning, isTrue);
  });

  test('send: question, streamed answer, cost, title', () async {
    final id = await service.createChat();
    fake.chatReplies.add(glmAnswer());
    await service.send(
      id,
      'Name two sailing boat classes raced on lakes, please',
    );

    final m = await msgs(id);
    expect(m.map((e) => e.role), ['user', 'assistant']);
    expect(
      m[0].content,
      'Name two sailing boat classes raced on lakes, please',
    );
    final a = m[1];
    expect(a.status, 'final');
    expect(a.content, 'Star and Finn.');
    expect(a.reasoning, 'Thinking.');
    expect(a.modelId, 'z-ai/glm-5.3');
    expect(a.provider, 'Z.AI');
    expect(a.finishReason, 'stop');
    expect(a.tokensIn, 120);
    expect(a.tokensOut, 30);
    expect(a.tokensReasoning, 10);
    expect(a.costUsd, closeTo(0.0002, 1e-12));
    expect(a.generationId, 'gen-test-1');
    expect(a.providerWarning, isNull);

    final chat = (await db.chat(id))!;
    expect(chat.title, 'Name two sailing boat classes raced on lakes,…');
    expect(chat.preview, 'Star and Finn.');
    expect(chat.costUsd, closeTo(0.0002, 1e-12));
    expect(chat.tokensIn, 120);
    expect(chat.lastPromptTokens, 120);
    expect(chat.lastContextLength, 1048576);

    final body = fake.chatBodies.single;
    expect(body['model'], 'z-ai/glm-5.3');
    expect(body['provider'], {'zdr': true, 'data_collection': 'deny'});
    expect(body['reasoning'], {'enabled': true});
    expect(body['messages'], [
      {
        'role': 'user',
        'content': 'Name two sailing boat classes raced on lakes, please',
      },
    ]);
  });

  test('history and system prompt; the title is not changed later', () async {
    final id = await service.createChat();
    await db.setMeta(GeneralMetaKeys.systemPrompt, 'Answer briefly.');
    fake.chatReplies
      ..add(glmAnswer(text: 'The Star.'))
      ..add(glmAnswer(text: 'The Finn.'));
    await service.send(id, 'A lake class?');
    await service.send(id, 'Another one?');
    expect(fake.chatBodies.last['messages'], [
      {'role': 'system', 'content': 'Answer briefly.'},
      {'role': 'user', 'content': 'A lake class?'},
      {'role': 'assistant', 'content': 'The Star.'},
      {'role': 'user', 'content': 'Another one?'},
    ]);
    expect((await db.chat(id))!.title, 'A lake class?');
    expect((await db.chat(id))!.costUsd, closeTo(0.0004, 1e-12));
  });

  test('thinking off: a model that always thinks still gets enabled', () async {
    final id = await service.createChat();
    await service.setReasoning(id, on: false);
    fake.chatReplies.add(glmAnswer());
    await service.send(id, 'x');
    expect(fake.chatBodies.single['reasoning'], {'enabled': true});

    final luna = await service.createChat(modelId: 'openai/gpt-6-luna');
    await service.setReasoning(luna, on: false);
    fake.chatReplies.add(
      FakeChatReply.sse(openRouterFixture('stream-luna-none.sse')),
    );
    await service.send(luna, 'Why is the sky blue?');
    expect(fake.chatBodies.last['reasoning'], {'effort': 'none'});
    expect((await msgs(luna)).last.provider, 'Azure');
    expect((await msgs(luna)).last.providerWarning, isNull);

    final nemo = await service.createChat(modelId: 'mistralai/mistral-nemo');
    fake.chatReplies.add(
      glmAnswer(provider: 'Mistral', model: 'mistralai/mistral-nemo'),
    );
    await service.send(nemo, 'x');
    expect(fake.chatBodies.last.containsKey('reasoning'), isFalse);
  });

  test('images go to image models, again on every message', () async {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0x01, 0xFF, 0xD9]);
    final id = await service.createChat(modelId: 'z-ai/glm-5.3-flash');
    fake.chatReplies
      ..add(glmAnswer(provider: 'Crusoe', model: 'z-ai/glm-5.3-flash'))
      ..add(glmAnswer(provider: 'Crusoe', model: 'z-ai/glm-5.3-flash'));
    await service.send(id, 'what colour?', images: [('image/jpeg', jpeg)]);
    await service.send(id, 'and now?');

    final atts = await db.attachmentsOf([(await msgs(id)).first.id]);
    expect(atts.single.bytes, jpeg);
    expect(atts.single.size, 5);
    for (final body in fake.chatBodies) {
      final first =
          (body['messages']! as List<Object?>).first! as Map<String, Object?>;
      expect(first['content'], isA<List<Object?>>());
      expect(
        ((first['content']! as List<Object?>)[1]!
            as Map<String, Object?>)['type'],
        'image_url',
      );
    }

    // a model without image input: the text goes, the image does not
    await service.setModel(id, 'z-ai/glm-5.3');
    fake.chatReplies.add(glmAnswer());
    await service.send(id, 'text only now');
    final first =
        (fake.chatBodies.last['messages']! as List<Object?>).first!
            as Map<String, Object?>;
    expect(first['content'], 'what colour?');
  });

  test(
    'switching models: one marker, never sent, gone when switched back',
    () async {
      final id = await service.createChat();
      await service.setModel(id, 'z-ai/glm-5.3-flash'); // empty chat: no marker
      expect(await msgs(id), isEmpty);
      fake.chatReplies.add(
        glmAnswer(provider: 'Crusoe', model: 'z-ai/glm-5.3-flash'),
      );
      await service.send(id, 'first');

      await service.setModel(id, 'openai/gpt-6-luna');
      await service.setModel(id, 'z-ai/glm-5.3');
      var m = await msgs(id);
      expect(m.map((e) => e.role), ['user', 'assistant', 'switch']);
      expect(m.last.modelId, 'z-ai/glm-5.3');

      await service.setModel(
        id,
        'z-ai/glm-5.3-flash',
      ); // back to the answer's model
      m = await msgs(id);
      expect(m.map((e) => e.role), ['user', 'assistant']);

      await service.setModel(id, 'z-ai/glm-5.3');
      fake.chatReplies.add(glmAnswer());
      await service.send(id, 'second');
      m = await msgs(id);
      expect(m.map((e) => e.role), [
        'user',
        'assistant',
        'switch',
        'user',
        'assistant',
      ]);
      expect(m.last.modelId, 'z-ai/glm-5.3');
      expect(
        (fake.chatBodies.last['messages']! as List<Object?>).length,
        3,
      ); // user, assistant, user – no marker
    },
  );

  test(
    'a model without a strict zero-retention provider cannot be used',
    () async {
      final id = await service.createChat();
      await expectLater(
        service.setModel(id, 'qwen/qwen3.7-flash'),
        throwsA(isA<GeneralModelUnavailable>()),
      );
      final q = await service.createChat(modelId: 'qwen/qwen3.7-flash');
      await expectLater(
        service.send(q, 'x'),
        throwsA(isA<GeneralModelUnavailable>()),
      );
      expect(fake.chatRequests, isEmpty);
      await expectLater(
        service.setModel(id, '~z-ai/glm-latest'),
        throwsArgumentError,
      );
    },
  );

  test('no key: nothing is sent', () async {
    final id = await service.createChat();
    current = null;
    await expectLater(service.send(id, 'x'), throwsA(isA<GeneralNoKey>()));
    expect(await msgs(id), isEmpty);
  });

  test('a failed answer keeps the reason; Retry replaces it', () async {
    final id = await service.createChat();
    fake.chatReplies.add(
      FakeChatReply.error(402, {
        'error': {'code': 402, 'message': 'Key limit exceeded'},
      }),
    );
    await service.send(id, 'hello');
    var m = await msgs(id);
    expect(m.last.status, 'failed');
    expect(m.last.errorCode, 'key_limit');
    expect(m.last.errorMessage, 'Key limit exceeded');
    expect((await db.chat(id))!.costUsd, 0);

    fake.chatReplies.add(glmAnswer(text: 'Hi.'));
    await service.retry(id);
    m = await msgs(id);
    expect(m.map((e) => e.role), ['user', 'assistant']);
    expect(m.last.status, 'final');
    expect(m.last.content, 'Hi.');
    // the failed answer was not sent back
    expect(fake.chatBodies.last['messages'], [
      {'role': 'user', 'content': 'hello'},
    ]);
  });

  test('429 keeps Retry-After', () async {
    final id = await service.createChat();
    fake.chatReplies.add(
      FakeChatReply.error(
        429,
        {
          'error': {'code': 429, 'message': 'Rate limit exceeded'},
        },
        headers: {'retry-after': '20'},
      ),
    );
    await service.send(id, 'x');
    final a = (await msgs(id)).last;
    expect(a.errorCode, 'rate_limited');
    expect(a.retryAfterS, 20);
    expect(
      GeneralFailure.fromCode(
        a.errorCode!,
        a.errorMessage!,
        retryAfterS: a.retryAfterS,
      ),
      isA<GeneralRateLimited>(),
    );
  });

  test(
    'Stop keeps the answer so far; the cost comes from /generation',
    () async {
      final id = await service.createChat(modelId: 'z-ai/glm-5.3-flash');
      fake.generations['gen-1794177894-4W340eEZ2QM6x869XPl9'] = openRouterJson(
        'generation-cancelled.json',
      );
      fake.chatReplies.add(
        FakeChatReply.sse(
          openRouterFixture('stream-cut.sse'),
          headers: {'x-generation-id': 'gen-1794177894-4W340eEZ2QM6x869XPl9'},
          chunkSize: 4096,
          holdOpen: true,
        ),
      );
      final sending = service.send(id, 'Write a story.');
      await until(() async {
        final m = await msgs(id);
        return m.length == 2 && m.last.content.length == 2426;
      });
      expect(service.isStreaming(id), isTrue);
      service.stop(id);
      await sending;
      await service.idle();

      final a = (await msgs(id)).last;
      expect(a.status, 'stopped');
      expect(a.content.length, 2426);
      expect(a.provider, 'OpenInference');
      expect(a.costUsd, closeTo(0.00014814, 1e-12));
      expect(a.tokensOut, 614);
      expect((await db.chat(id))!.costUsd, closeTo(0.00014814, 1e-12));
      expect(service.isStreaming(id), isFalse);
      expect(fake.calls.where((c) => c.endsWith('/generation')), isNotEmpty);
    },
  );

  test(
    'a provider off the zero-retention list stops the chat until acknowledged',
    () async {
      final id = await service.createChat();
      fake.chatReplies.add(glmAnswer(provider: 'Unlisted Cloud'));
      await service.send(id, 'x');
      final a = (await msgs(id)).last;
      expect(a.status, 'final');
      expect(a.providerWarning, 'pending');

      await expectLater(
        service.send(id, 'y'),
        throwsA(isA<GeneralWarningPending>()),
      );
      expect(fake.chatRequests.length, 1);

      await service.acknowledgeWarning(a.id);
      fake.chatReplies.add(glmAnswer());
      await service.send(id, 'y');
      expect(fake.chatRequests.length, 2);
    },
  );

  test('rename, archive, delete', () async {
    final id = await service.createChat(modelId: 'z-ai/glm-5.3-flash');
    fake.chatReplies.add(
      glmAnswer(provider: 'Crusoe', model: 'z-ai/glm-5.3-flash'),
    );
    await service.send(
      id,
      'pic',
      images: [
        ('image/jpeg', Uint8List.fromList([1, 2, 3])),
      ],
    );
    await service.rename(id, '  My chat ');
    expect((await db.chat(id))!.title, 'My chat');
    expect((await db.chat(id))!.titleSet, isTrue);
    await service.archive(id);
    expect(await db.watchChats().first, isEmpty);
    expect((await db.watchChats(archived: true).first).single.id, id);
    await service.deleteChat(id);
    expect(await db.chat(id), isNull);
    expect(await msgs(id), isEmpty);
    expect(await db.select(db.generalAttachments).get(), isEmpty);
  });

  test('answers a killed app left streaming become stopped', () async {
    final id = await service.createChat();
    await db
        .into(db.generalMessages)
        .insert(
          GeneralMessagesCompanion.insert(
            id: 'm1',
            chatId: id,
            seq: 1,
            role: 'assistant',
            status: 'streaming',
            createdAt: now,
          ),
        );
    await service.settleInterrupted();
    expect((await db.message('m1'))!.status, 'stopped');
  });

  test('titles', () {
    expect(generalTitleFrom('  short  question '), 'short question');
    expect(generalTitleFrom('', hasImages: true), 'Image');
    expect(
      generalTitleFrom(
        'Compare btrfs and ZFS snapshots for a single-disk home desktop',
      ),
      'Compare btrfs and ZFS snapshots for a…',
    );
    expect(generalTitleFrom('x' * 60), '${'x' * 45}…');
  });

  test('a second send while an answer streams is refused', () async {
    final id = await service.createChat();
    fake.chatReplies.add(
      FakeChatReply.sse(
        sseOf([chunk(content: 'a')], done: false),
        holdOpen: true,
      ),
    );
    final first = service.send(id, 'one');
    await until(() async => service.isStreaming(id));
    await expectLater(service.send(id, 'two'), throwsStateError);
    service.stop(id);
    await first;
  });
}
