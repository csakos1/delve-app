import 'dart:convert';
import 'dart:typed_data';

import 'package:delve/general/general_key_store.dart';
import 'package:delve/general/model_catalog.dart';
import 'package:delve/general/openrouter_client.dart';
import 'package:delve/general/openrouter_errors.dart';
import 'package:delve/general/sse.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_openrouter.dart';

void main() {
  group('request body (privacy on every branch)', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

    void privacyRules(Map<String, Object?> body) {
      expect(body['provider'], {'zdr': true, 'data_collection': 'deny'});
      expect(body.keys, isNot(contains('user')));
      expect(body.keys, isNot(contains('plugins')));
      expect(body.keys, isNot(contains('transforms')));
      expect(body['stream'], isTrue);
    }

    test('plain text, no system prompt, no reasoning', () {
      final body = buildChatBody(
        model: 'z-ai/glm-5.3',
        turns: const [GeneralTurn.user('hi')],
      );
      privacyRules(body);
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
      ]);
      expect(body.containsKey('reasoning'), isFalse);
      expect(body.containsKey('max_tokens'), isFalse);
    });

    test('system prompt, history, reasoning, images', () {
      final body = buildChatBody(
        model: 'z-ai/glm-5.3-flash',
        systemPrompt: 'Be brief.',
        reasoning: const {'enabled': true},
        turns: [
          GeneralTurn.user('what is this?', images: [('image/jpeg', jpeg)]),
          const GeneralTurn.assistant('A tiny JPEG.'),
          const GeneralTurn.user('thanks'),
        ],
      );
      privacyRules(body);
      expect(body['reasoning'], {'enabled': true});
      final messages = body['messages']! as List<Object?>;
      expect(messages.first, {'role': 'system', 'content': 'Be brief.'});
      expect(messages[1], {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'what is this?'},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,${base64Encode(jpeg)}',
            },
          },
        ],
      });
      expect(messages[2], {'role': 'assistant', 'content': 'A tiny JPEG.'});
      expect(messages[3], {'role': 'user', 'content': 'thanks'});
    });

    test('a blank system prompt is left out; images are not sent when off', () {
      final body = buildChatBody(
        model: 'z-ai/glm-5.3',
        systemPrompt: '   ',
        sendImages: false,
        turns: [
          GeneralTurn.user('look', images: [('image/jpeg', jpeg)]),
        ],
      );
      privacyRules(body);
      expect(body['messages'], [
        {'role': 'user', 'content': 'look'},
      ]);
    });

    test('aliases, routers and :online are refused', () {
      for (final id in [
        '~z-ai/glm-latest',
        'openrouter/auto',
        'openai/gpt-6-astra:online',
        '',
      ]) {
        expect(
          () => buildChatBody(model: id, turns: const [GeneralTurn.user('x')]),
          throwsArgumentError,
          reason: id,
        );
      }
    });
  });

  group('reasoning parameter', () {
    test('a model that always thinks never gets “off”', () {
      const spec = ReasoningSpec(
        supported: true,
        mandatory: true,
        efforts: ['max', 'high', 'low'],
      );
      expect(spec.param(on: true), {'enabled': true});
      expect(spec.param(on: false), {'enabled': true});
    });

    test('off is effort none where offered, else enabled false', () {
      const withNone = ReasoningSpec(supported: true, efforts: ['low', 'none']);
      const without = ReasoningSpec(supported: true);
      expect(withNone.param(on: false), {'effort': 'none'});
      expect(without.param(on: false), {'enabled': false});
      expect(without.param(on: true), {'enabled': true});
    });

    test('no reasoning support: nothing is sent', () {
      expect(ReasoningSpec.none.param(on: true), isNull);
      expect(ReasoningSpec.none.param(on: false), isNull);
    });
  });

  group('SSE', () {
    // a Stream<Uint8List>, like dio's response stream
    Stream<Uint8List> bytesOf(String s, [int size = 5]) async* {
      final b = utf8.encode(s);
      for (var i = 0; i < b.length; i += size) {
        yield b.sublist(i, i + size > b.length ? b.length : i + size);
      }
    }

    test('comments are skipped, multi-line data joined, tail kept', () async {
      const body =
          ': OPENROUTER PROCESSING\n\n'
          'data: {"a":1}\n\n'
          'event: x\ndata: line1\ndata: line2\n\n'
          'data: ő ű\r\n\r\n'
          'data: [DONE]';
      expect(await sseData(bytesOf(body)).toList(), [
        '{"a":1}',
        'line1\nline2',
        'ő ű',
        '[DONE]',
      ]);
    });
  });

  group('client', () {
    late FakeOpenRouter fake;
    late OpenRouterClient client;
    setUp(() {
      fake = FakeOpenRouter();
      client = OpenRouterClient(key: 'sk-or-v1-test', adapter: fake);
    });
    tearDown(() => client.close());

    Map<String, Object?> body() => buildChatBody(
      model: 'z-ai/glm-5.3-flash',
      turns: const [GeneralTurn.user('x')],
    );

    test('only the key goes in the headers', () async {
      fake.chatReplies.add(
        FakeChatReply.sse(openRouterFixture('stream-luna-none.sse')),
      );
      await client.chat(body()).drain<void>();
      await client.keyInfo();
      for (final r in fake.requests) {
        final names = r.headers.keys.map((k) => k.toLowerCase()).toSet();
        expect(names, contains('authorization'));
        expect(names, isNot(contains('http-referer')));
        expect(names, isNot(contains('referer')));
        expect(names, isNot(contains('x-title')));
        expect(
          r.headers['authorization'] ?? r.headers['Authorization'],
          'Bearer sk-or-v1-test',
        );
      }
      expect(fake.chatBodies.single['provider'], {
        'zdr': true,
        'data_collection': 'deny',
      });
    });

    test('a thinking stream (GLM 5.3 Flash, G0)', () async {
      fake.chatReplies.add(
        FakeChatReply.sse(
          openRouterFixture('stream-glm-flash-reasoning.sse'),
          headers: {'x-generation-id': 'gen-1794175210-1M4hHHEotu48TIdnWABf'},
        ),
      );
      final events = await client.chat(body()).toList();
      expect(events.first, isA<ChatStarted>());
      expect(
        (events.first as ChatStarted).generationId,
        'gen-1794175210-1M4hHHEotu48TIdnWABf',
      );
      final route = events.whereType<ChatRoute>().single;
      expect(route.provider, 'InferenceNet');
      expect(route.model, 'z-ai/glm-5.3-flash');
      final deltas = events.whereType<ChatDelta>();
      final content = deltas.map((d) => d.content).join();
      final reasoning = deltas.map((d) => d.reasoning).join();
      expect(content, startsWith('**13 km**'));
      expect(content.length, 75);
      expect(reasoning, startsWith('This is a simple right triangle problem.'));
      expect(reasoning.length, 199);
      // two chunks carry finish_reason; one event
      expect(events.whereType<ChatFinish>().single.reason, 'stop');
      final usage = events.whereType<ChatUsage>().single;
      expect(usage.promptTokens, 37);
      expect(usage.completionTokens, 98);
      expect(usage.reasoningTokens, 65);
      expect(usage.cost, closeTo(3.8296e-05, 1e-12));
      expect(events.last, isA<ChatUsage>());
    });

    test('keep-alive comments (Opus 5.5 on Bedrock, G0b)', () async {
      fake.chatReplies.add(
        FakeChatReply.sse(
          openRouterFixture('stream-opus-comments.sse'),
          chunkSize: 11,
        ),
      );
      final events = await client.chat(body()).toList();
      expect(events.whereType<ChatRoute>().single.provider, 'Amazon Bedrock');
      expect(
        events.whereType<ChatDelta>().map((d) => d.content).join(),
        startsWith('The boat is **13 km**'),
      );
      expect(
        events.whereType<ChatUsage>().single.cost,
        closeTo(0.001244, 1e-9),
      );
    });

    test('a cut stream ends without finish and usage', () async {
      fake.chatReplies.add(
        FakeChatReply.sse(openRouterFixture('stream-cut.sse')),
      );
      final events = await client.chat(body()).toList();
      expect(events.whereType<ChatFinish>(), isEmpty);
      expect(events.whereType<ChatUsage>(), isEmpty);
      expect(
        events.whereType<ChatDelta>().map((d) => d.content).join().length,
        2426,
      );
    });

    test('an error inside the stream', () async {
      fake.chatReplies.add(
        FakeChatReply.sse(
          sseOf([
            chunk(content: 'Hel'),
            {
              'id': 'gen-test-1',
              'error': {'code': 502, 'message': 'Provider disconnected'},
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': ''},
                  'finish_reason': 'error',
                },
              ],
            },
          ]),
        ),
      );
      final events = <ChatEvent>[];
      await expectLater(
        client.chat(body()).forEach(events.add),
        throwsA(
          isA<GeneralUpstream>().having(
            (e) => e.message,
            'message',
            'Provider disconnected',
          ),
        ),
      );
      expect(events.whereType<ChatDelta>().single.content, 'Hel');
    });

    Future<GeneralFailure> failure(FakeChatReply reply) async {
      fake.chatReplies.add(reply);
      try {
        await client.chat(body()).drain<void>();
      } on GeneralFailure catch (f) {
        return f;
      }
      fail('no failure');
    }

    test('HTTP errors (G0 bodies)', () async {
      final unauthorized = await failure(
        FakeChatReply.error(401, openRouterJson('err-401.json')),
      );
      expect(unauthorized, isA<GeneralUnauthorized>());
      expect(unauthorized.message, 'User not found.');

      final mandatory = await failure(
        FakeChatReply.error(400, openRouterJson('err-400-mandatory.json')),
      );
      expect(mandatory, isA<GeneralBadRequest>());
      expect(mandatory.message, startsWith('Reasoning is mandatory'));

      expect(
        await failure(
          FakeChatReply.error(400, openRouterJson('err-400-model.json')),
        ),
        isA<GeneralBadRequest>(),
      );
      expect(
        await failure(
          FakeChatReply.error(404, openRouterJson('err-404-providers.json')),
        ),
        isA<GeneralNoProvider>(),
      );
      expect(
        await failure(
          FakeChatReply.error(402, {
            'error': {'code': 402, 'message': 'Key limit exceeded'},
          }),
        ),
        isA<GeneralKeyLimit>(),
      );
      final limited = await failure(
        FakeChatReply.error(
          429,
          {
            'error': {'code': 429, 'message': 'Rate limit exceeded'},
          },
          headers: {'retry-after': '20'},
        ),
      );
      expect(
        limited,
        isA<GeneralRateLimited>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 20),
        ),
      );
      expect(
        await failure(
          FakeChatReply.error(503, {
            'error': {'code': 503, 'message': 'Overloaded'},
          }),
        ),
        isA<GeneralUpstream>(),
      );
    });

    test('no connection', () async {
      fake.unreachable = true;
      await expectLater(
        client.chat(body()).drain<void>(),
        throwsA(isA<GeneralNetwork>()),
      );
      await expectLater(client.models(), throwsA(isA<GeneralNetwork>()));
    });

    test('key and generation', () async {
      final key = await client.keyInfo();
      expect(key.label, 'masked-key-label');
      expect(key.limit, 100);
      expect(key.limitReset, isNull);
      expect(key.limitRemaining, closeTo(96.32, 0.01));
      expect(key.usageMonthly, closeTo(3.6756, 0.001));

      expect(await client.generation('gen-none'), isNull);
      fake.generations['gen-1'] = openRouterJson('generation-cancelled.json');
      final g = (await client.generation('gen-1'))!;
      expect(g.cancelled, isTrue);
      expect(g.totalCost, closeTo(0.00014814, 1e-12));
      expect(g.tokensPrompt, 13);
      expect(g.tokensCompletion, 614);
      expect(g.provider, 'OpenInference');

      fake.keyStatus = 401;
      await expectLater(client.keyInfo(), throwsA(isA<GeneralUnauthorized>()));
    });
  });

  group('model list', () {
    test('strict zero-retention providers skip Safety Retention', () {
      final zdr = strictZdrProviders([
        for (final e in openRouterJson('zdr.json')['data']! as List<Object?>)
          e! as Map<String, Object?>,
      ]);
      expect(zdr['mistralai/mistral-nemo'], {'Io Net', 'Mistral'});
      expect(zdr['openai/gpt-6-astra'], {'Azure'});
      expect(zdr.containsKey('qwen/qwen3.7-flash'), isFalse);
    });

    test('refresh filters, keeps 24 h, and force fetches again', () async {
      final db = memoryGeneralDb();
      addTearDown(db.close);
      final fake = FakeOpenRouter();
      final client = OpenRouterClient(key: 'sk-or-v1-test', adapter: fake);
      addTearDown(client.close);
      var now = DateTime.utc(2026, 11, 9, 21);
      final catalog = ModelCatalog(db, now: () => now);

      expect(await catalog.refresh(client), isTrue);
      final rows = {for (final m in await db.models()) m.id: m};
      expect(rows.keys.toSet(), {
        'z-ai/glm-5.3',
        'z-ai/glm-5.3-flash',
        'moonshotai/kimi-k3.1-pro',
        'anthropic/claude-opus-5.5',
        'openai/gpt-6-astra',
        'openai/gpt-6-luna',
        'mistralai/mistral-nemo',
        'qwen/qwen3.7-flash',
      }); // no :batch, no ~alias, no router

      final glm = rows['z-ai/glm-5.3']!;
      expect(glm.shortName, 'GLM 5.3');
      expect(glm.reasoningSpec.mandatory, isTrue);
      expect(glm.readsImages, isFalse);
      expect(glm.selectable, isTrue);
      expect(rows['z-ai/glm-5.3-flash']!.readsImages, isTrue);
      expect(rows['openai/gpt-6-luna']!.reasoningSpec.param(on: false), {
        'effort': 'none',
      });
      expect(rows['anthropic/claude-opus-5.5']!.reasoningMandatory, isTrue);
      expect(rows['anthropic/claude-opus-5.5']!.zdrProviders, [
        'Amazon Bedrock',
        'Google',
      ]);
      expect(rows['mistralai/mistral-nemo']!.reasoningSupported, isFalse);
      expect(rows['qwen/qwen3.7-flash']!.selectable, isFalse);
      expect(rows['openai/gpt-6-astra']!.pricePrompt, closeTo(10e-6, 1e-12));

      final calls = fake.requests.length;
      now = now.add(const Duration(hours: 23));
      expect(await catalog.refresh(client), isFalse);
      expect(fake.requests.length, calls);
      expect(await catalog.refresh(client, force: true), isTrue);
      now = now.add(const Duration(hours: 25));
      expect(await catalog.refresh(client), isTrue);
    });

    test('favourites and the default model', () async {
      final db = memoryGeneralDb();
      addTearDown(db.close);
      final catalog = ModelCatalog(db);
      expect(await catalog.favourites(), kDefaultFavourites);
      expect(await catalog.defaultModel(), 'z-ai/glm-5.3');
      await catalog.setFavourites(['openai/gpt-6-astra']);
      await catalog.setDefaultModel('openai/gpt-6-luna');
      expect(await catalog.favourites(), ['openai/gpt-6-astra']);
      expect(await catalog.defaultModel(), 'openai/gpt-6-luna');
      expect(
        () => catalog.setDefaultModel('~z-ai/glm-latest'),
        throwsArgumentError,
      );
    });
  });

  group('key', () {
    test('shape and mask', () {
      expect(looksLikeOpenRouterKey('sk-or-v1-0123456789abcdef0123'), isTrue);
      expect(
        looksLikeOpenRouterKey(' sk-or-v1-0123456789abcdef0123 \n'),
        isTrue,
      );
      expect(looksLikeOpenRouterKey('sk-0123456789abcdef0123'), isFalse);
      expect(looksLikeOpenRouterKey('sk-or-v1-short'), isFalse);
      expect(maskKey('sk-or-v1-0123456789abcdef4f2a'), 'sk-or-v1-…4f2a');
    });
  });
}
