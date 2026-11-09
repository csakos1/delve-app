import 'dart:async';
import 'dart:io';

import 'package:delve/api/models/models.dart';
import 'package:delve/app/router.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/general/general_database.dart';
import 'package:delve/general/model_catalog.dart';
import 'package:delve/general/openrouter_client.dart';
import 'package:delve/ui/screens/general_settings_screen.dart'
    show promptSaveDelay;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_openrouter.dart';
import 'support/harness.dart';
import 'support/ws_fixtures.dart';

/// The model list as G0 recorded it, cached in the phone's General database.
Future<void> seedModels(TestEnv env) async {
  final client = OpenRouterClient(
    key: testOpenRouterKey,
    adapter: env.openRouter,
  );
  await ModelCatalog(env.general).refresh(client);
  env.openRouter.requests.clear();
}

FakeChatReply glmAnswer({
  String text = 'Star and Finn.',
  double cost = 0.0002,
}) => FakeChatReply.sse(
  sseOf([
    chunk(reasoning: 'Thinking.'),
    chunk(content: text),
    chunk(finish: 'stop'),
    chunk(
      finish: 'stop',
      usage: {
        'prompt_tokens': 120,
        'completion_tokens': 30,
        'total_tokens': 150,
        'cost': cost,
      },
    ),
  ]),
);

/// Pumps (fake time) until [f] finds something; on a timeout it says what
/// the screen shows instead.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder f, {
  int max = 300,
  TestEnv? env,
}) async {
  for (var i = 0; i < max; i++) {
    if (f.evaluate().isNotEmpty) return;
    await step(tester);
  }
  final keys = [
    for (final e in find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> && k.value.startsWith('general.');
    }).evaluate())
      (e.widget.key! as ValueKey<String>).value,
  ];
  final texts = [
    for (final e in find.byType(Text).evaluate())
      (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText(),
  ];
  final rows = env == null
      ? null
      : await tester.runAsync(
          () => env.general.select(env.general.generalMessages).get(),
        );
  fail(
    'never found: $f\n'
    'keys: $keys\n'
    'texts: $texts\n'
    'calls: ${env?.openRouter.calls}\n'
    'messages: ${[for (final r in rows ?? const <GeneralMessageRow>[]) '${r.role}/${r.status}/${r.errorCode}/${r.errorMessage}']}',
  );
}

Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder f, {
  int max = 300,
}) async {
  for (var i = 0; i < max; i++) {
    if (f.evaluate().isEmpty) return;
    await step(tester);
  }
  fail('still there: $f');
}

/// One step while a request to the fake OpenRouter runs: Dio's streamed
/// response does not move on fake time alone (seen in the G1b-1 run), the
/// screen does, so both get a turn.
Future<void> step(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> go(WidgetTester tester, String location) async {
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(location),
  );
  await tester.pumpAndSettle();
}

Finder rich(String text) => find.text(text, findRichText: true);

void main() {
  group('request parameters', () {
    test('an effort is sent where the model offers it', () {
      const glm = ReasoningSpec(
        supported: true,
        mandatory: true,
        efforts: ['max', 'high', 'low'],
        defaultEffort: 'max',
      );
      expect(glm.choosableEfforts, ['max', 'high', 'low']);
      expect(glm.param(on: true, effort: 'high'), {'effort': 'high'});
      expect(glm.param(on: false, effort: 'low'), {'effort': 'low'});
      expect(glm.param(on: true, effort: 'xhigh'), {'enabled': true});
      expect(glm.param(on: true), {'enabled': true});

      const kimi = ReasoningSpec(
        supported: true,
        efforts: ['max', 'high', 'low', 'none'],
      );
      expect(kimi.choosableEfforts, ['max', 'high', 'low']);
      expect(kimi.param(on: false, effort: 'high'), {'effort': 'none'});
      expect(kimi.param(on: true, effort: 'none'), {'enabled': true});
      expect(ReasoningSpec.none.param(on: true, effort: 'high'), isNull);
    });

    test('a version 1 General database gets the effort column', () async {
      final dir = await Directory.systemTemp.createTemp('delve-general');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/delve_general.sqlite');
      final v1 = GeneralDatabase(NativeDatabase(file));
      await v1.customStatement(
        'ALTER TABLE general_chats DROP COLUMN reasoning_effort',
      );
      await v1.customStatement(
        'INSERT INTO general_chats (id, model_id, created_at, updated_at) '
        "VALUES ('g_old', 'z-ai/glm-5.3', 0, 0)",
      );
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final v2 = GeneralDatabase(NativeDatabase(file));
      addTearDown(v2.close);
      final row = (await v2.chat('g_old'))!;
      expect(
        (row.modelId, row.reasoningEffort, row.reasoning),
        ('z-ai/glm-5.3', null, true),
      );
      await v2.updateChat(
        'g_old',
        const GeneralChatsCompanion(reasoningEffort: Value('high')),
      );
      expect((await v2.chat('g_old'))!.reasoningEffort, 'high');
    });
  });

  testWidgets('Chats: General chats among the agent ones; the filter chips', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final env = await pumpDelve(
      tester,
      generalKey: testOpenRouterKey,
      before: (env) async {
        await env.db.putConversation(
          Conversation.fromJson(
            sample('conversation', {
              'id': 'c_1',
              'title': 'Kernel and CPU count',
              'updated_at': now
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
              'archived': false,
            }),
          ),
        );
        await seedModels(env);
        await env.general
            .into(env.general.generalChats)
            .insert(
              GeneralChatsCompanion.insert(
                id: 'g_1',
                modelId: 'z-ai/glm-5.3',
                createdAt: now,
                updatedAt: now,
                title: const Value('Carbonara ratios'),
                costUsd: const Value(0.0049),
              ),
            );
      },
    );

    expect(find.byKey(const Key('chats.filters')), findsOneWidget);
    expect(find.text('General · GLM 5.3'), findsOneWidget);
    expect(find.text(' · \$0.0049'), findsOneWidget);
    final general = tester.getTopLeft(find.text('Carbonara ratios')).dy;
    final agent = tester.getTopLeft(find.text('Kernel and CPU count')).dy;
    expect(general, lessThan(agent), reason: 'newest first');

    await tester.tap(find.byKey(const Key('chats.filter.general')));
    await tester.pumpAndSettle();
    expect(find.text('Kernel and CPU count'), findsNothing);
    expect(find.text('Carbonara ratios'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => env.general.meta(GeneralMetaKeys.chatsFilter),
      ),
      'general',
    );

    await tester.tap(find.byKey(const Key('chats.filter.agent')));
    await tester.pumpAndSettle();
    expect(find.text('Carbonara ratios'), findsNothing);
    expect(find.text('Kernel and CPU count'), findsOneWidget);
  });

  testWidgets('without a key Chats has no filter chips', (tester) async {
    await pumpDelve(tester);
    expect(find.byKey(const Key('chats.filters')), findsNothing);
  });

  testWidgets(
    'new chat: Agent / General, remembered; no key leads to Settings → General',
    (tester) async {
      final env = await pumpDelve(tester);
      await tester.tap(find.byKey(const Key('chats.emptyNew')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('newChat.kind')), findsOneWidget);
      expect(find.byKey(const Key('general.noKey')), findsNothing);

      await tester.tap(find.byKey(const Key('newChat.kind.general')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('general.noKey')), findsOneWidget);
      expect(find.byKey(const Key('composer.field')), findsNothing);
      expect(
        await tester.runAsync(
          () => env.general.meta(GeneralMetaKeys.newChatKind),
        ),
        'general',
      );

      await tester.tap(find.byKey(const Key('general.addKey')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('generalSettings.field')), findsOneWidget);
    },
  );

  testWidgets('General: a message streams in; footer, title, request body', (
    tester,
  ) async {
    final env = await pumpDelve(
      tester,
      generalKey: testOpenRouterKey,
      before: (env) async {
        await seedModels(env);
        await env.general.setMeta(GeneralMetaKeys.newChatKind, 'general');
      },
    );
    env.openRouter.chatReplies.add(glmAnswer());

    await tester.tap(find.byKey(const Key('chats.emptyNew')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('general.intro.model')), findsOneWidget);
    expect(find.text('GLM 5.3'), findsWidgets);
    // GLM 5.3 always thinks: the pill is locked
    expect(find.byKey(const Key('general.thinking.lock')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('composer.field')),
      'Name two dogs',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('composer.send')));
    await pumpUntil(tester, find.byKey(const Key('general.footer')), env: env);
    await tester.pumpAndSettle();

    expect(rich('Star and Finn.'), findsOneWidget);
    expect(find.text('Name two dogs'), findsWidgets);
    expect(find.text('GLM 5.3 · \$0.0002'), findsOneWidget);
    expect(find.byKey(const Key('newChat.kind')), findsNothing);
    expect(find.text('Name two dogs'), findsWidgets, reason: 'the title');

    final body = env.openRouter.chatBodies.single;
    expect(body['model'], 'z-ai/glm-5.3');
    expect(body['reasoning'], {'enabled': true});
    expect(body['provider'], kPrivacyProvider);
    final request = env.openRouter.chatRequests.single;
    expect(
      request.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('http-referer')),
    );

    // back in Chats the chat is there
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.text('General · GLM 5.3'), findsOneWidget);
  });

  testWidgets('General: long press picks the effort; it is sent', (
    tester,
  ) async {
    final env = await pumpDelve(
      tester,
      generalKey: testOpenRouterKey,
      before: (env) async {
        await seedModels(env);
        await env.general.setMeta(GeneralMetaKeys.newChatKind, 'general');
      },
    );
    env.openRouter.chatReplies.add(glmAnswer());
    await tester.tap(find.byKey(const Key('chats.emptyNew')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('general.thinking')));
    await tester.pumpAndSettle();
    expect(find.text('Model default (Max)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('effort.high')));
    await tester.pumpAndSettle();
    expect(find.text('Thinking · High'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('composer.field')), 'Hi');
    await tester.pump();
    await tester.tap(find.byKey(const Key('composer.send')));
    await pumpUntil(tester, find.byKey(const Key('general.footer')), env: env);
    await tester.pumpAndSettle();
    expect(env.openRouter.chatBodies.single['reasoning'], {'effort': 'high'});
  });

  Future<TestEnv> openChat(WidgetTester tester) async {
    final now = DateTime.now().toUtc();
    final env = await pumpDelve(
      tester,
      generalKey: testOpenRouterKey,
      before: (env) async {
        await seedModels(env);
        final db = env.general;
        await db
            .into(db.generalChats)
            .insert(
              GeneralChatsCompanion.insert(
                id: 'g_1',
                modelId: 'z-ai/glm-5.3',
                createdAt: now,
                updatedAt: now,
                title: const Value('Dog names'),
              ),
            );
        await db
            .into(db.generalMessages)
            .insert(
              GeneralMessagesCompanion.insert(
                id: 'm_1',
                chatId: 'g_1',
                seq: 1,
                role: 'user',
                status: 'final',
                content: const Value('Name two dogs'),
                createdAt: now,
              ),
            );
        await db
            .into(db.generalMessages)
            .insert(
              GeneralMessagesCompanion.insert(
                id: 'm_2',
                chatId: 'g_1',
                seq: 2,
                role: 'assistant',
                status: 'final',
                content: const Value('Star and Finn.'),
                modelId: const Value('z-ai/glm-5.3'),
                costUsd: const Value(0.0002),
                tokensOut: const Value(30),
                createdAt: now,
              ),
            );
      },
    );
    await go(tester, Routes.generalChat('g_1'));
    return env;
  }

  testWidgets('General: the picker switches the model and marks it', (
    tester,
  ) async {
    await openChat(tester);
    expect(find.text('Dog names'), findsOneWidget);

    await tester.tap(find.byKey(const Key('general.modelChip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker')), findsOneWidget);
    expect(find.byKey(const Key('picker.fav.z-ai/glm-5.3')), findsOneWidget);
    expect(find.byKey(const Key('picker.check')), findsWidgets);

    // a model without a strict zero-retention provider cannot be picked
    await tester.enterText(find.byKey(const Key('picker.search')), 'qwen');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker.noZdr')), findsOneWidget);
    await tester.tap(find.byKey(const Key('picker.all.qwen/qwen3.7-flash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('picker.search')), 'kimi');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('picker.fav.moonshotai/kimi-k3.1-pro')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker')), findsNothing);
    expect(find.byKey(const Key('general.switch')), findsOneWidget);
    expect(find.textContaining('Switched to Kimi K3.1 Pro'), findsOneWidget);
    expect(find.text('Kimi K3.1 Pro'), findsOneWidget, reason: 'the chip');
    // Kimi can think without having to: the pill is a switch again
    expect(find.byKey(const Key('general.thinking.lock')), findsNothing);
  });

  testWidgets('General: tokens in the footer when switched on', (tester) async {
    final env = await openChat(tester);
    expect(find.text('GLM 5.3 · \$0.0002'), findsOneWidget);
    await tester.runAsync(
      () => env.general.setMeta(GeneralMetaKeys.showTokens, '1'),
    );
    await tester.pumpAndSettle();
    expect(find.text('GLM 5.3 · \$0.0002 · 30 tok'), findsOneWidget);
  });

  testWidgets('General: a failed answer shows its banner; Retry answers', (
    tester,
  ) async {
    final env = await openChat(tester);
    env.openRouter.chatReplies.add(
      FakeChatReply.error(402, {
        'error': {'message': 'Key limit exceeded', 'code': 402},
      }),
    );
    await tester.enterText(find.byKey(const Key('composer.field')), 'More');
    await tester.pump();
    await tester.tap(find.byKey(const Key('composer.send')));
    await pumpUntil(tester, find.byKey(const Key('general.error.key_limit')));
    await tester.pumpAndSettle();
    expect(find.text('Key limit reached'), findsOneWidget);
    expect(find.textContaining('HTTP 402'), findsOneWidget);

    env.openRouter.chatReplies.add(glmAnswer(text: 'Rex and Bo.'));
    await tester.tap(find.byKey(const Key('general.error.retry')));
    await pumpUntilGone(
      tester,
      find.byKey(const Key('general.error.key_limit')),
    );
    await pumpUntil(tester, rich('Rex and Bo.'));
    await tester.pumpAndSettle();
    expect(env.openRouter.chatBodies, hasLength(2));
  });

  testWidgets('General: rename and delete from the menu', (tester) async {
    final env = await openChat(tester);
    await tester.tap(find.byKey(const Key('general.menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('general.menu.rename')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('general.rename.field')),
      'Two dogs',
    );
    await tester.tap(find.byKey(const Key('general.rename.save')));
    await tester.pumpAndSettle();
    expect(find.text('Two dogs'), findsOneWidget);

    await tester.tap(find.byKey(const Key('general.menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('general.menu.delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('general.delete.confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('general.topBar')), findsNothing);
    expect(await tester.runAsync(() => env.general.chat('g_1')), isNull);
  });

  testWidgets('Settings → General: paste, check, save, mask, remove', (
    tester,
  ) async {
    final env = await pumpDelve(tester);
    await go(tester, Routes.generalSettings);

    // a key OpenRouter rejects is not saved
    env.openRouter.keyStatus = 401;
    await tester.enterText(
      find.byKey(const Key('generalSettings.field')),
      testOpenRouterKey,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('generalSettings.save')));
    await pumpUntil(tester, find.text('OpenRouter rejected this key'));
    expect(env.generalKeys.key, isNull);

    env.openRouter.keyStatus = 200;
    await tester.enterText(
      find.byKey(const Key('generalSettings.field')),
      testOpenRouterKey,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('generalSettings.save')));
    await pumpUntil(tester, find.byKey(const Key('generalSettings.masked')));
    await pumpUntil(
      tester,
      find.byKey(const Key('generalSettings.spend.line')),
    );
    await tester.pumpAndSettle();
    expect(env.generalKeys.key, testOpenRouterKey);
    expect(find.text('sk-or-v1-…4f2a'), findsOneWidget);
    expect(find.text('\$3.68 of \$100.00'), findsOneWidget);
    // the G0 key's limit never resets (N188)
    expect(find.byKey(const Key('generalSettings.noReset')), findsOneWidget);

    await tester.tap(find.byKey(const Key('generalSettings.remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generalSettings.remove.confirm')));
    await tester.pumpAndSettle();
    expect(env.generalKeys.key, isNull);
    expect(find.byKey(const Key('generalSettings.field')), findsOneWidget);
  });

  testWidgets('General: Usage from the menu and the chip; by model; the key', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final env = await pumpDelve(
      tester,
      generalKey: testOpenRouterKey,
      before: (env) async {
        await seedModels(env);
        final db = env.general;
        await db
            .into(db.generalChats)
            .insert(
              GeneralChatsCompanion.insert(
                id: 'g_1',
                modelId: 'moonshotai/kimi-k3.1-pro',
                createdAt: now,
                updatedAt: now,
                title: const Value('Dog names'),
                tokensIn: const Value(1180),
                tokensOut: const Value(330),
                costUsd: const Value(0.0062),
                lastPromptTokens: const Value(1180),
                lastContextLength: const Value(1048576),
              ),
            );
        Future<void> message(
          String id,
          int seq,
          String role, {
          String status = 'final',
          String? model,
          int? tokensIn,
          int? tokensOut,
          double? cost,
        }) => db
            .into(db.generalMessages)
            .insert(
              GeneralMessagesCompanion.insert(
                id: id,
                chatId: 'g_1',
                seq: seq,
                role: role,
                status: status,
                content: Value('text $seq'),
                modelId: Value(model),
                tokensIn: Value(tokensIn),
                tokensOut: Value(tokensOut),
                costUsd: Value(cost),
                createdAt: now,
              ),
            );
        await message('m_1', 1, 'user');
        await message(
          'm_2',
          2,
          'assistant',
          model: 'z-ai/glm-5.3',
          tokensIn: 500,
          tokensOut: 30,
          cost: 0.0002,
        );
        await message('m_3', 3, 'switch', model: 'moonshotai/kimi-k3.1-pro');
        await message('m_4', 4, 'user');
        await message(
          'm_5',
          5,
          'assistant',
          model: 'moonshotai/kimi-k3.1-pro',
          tokensIn: 680,
          tokensOut: 300,
          cost: 0.006,
        );
        // a failed answer is not counted
        await message('m_6', 6, 'user');
        await message(
          'm_7',
          7,
          'assistant',
          status: 'failed',
          model: 'moonshotai/kimi-k3.1-pro',
        );
      },
    );
    await go(tester, Routes.generalChat('g_1'));

    await tester.tap(find.byKey(const Key('general.menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('general.menu.usage')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('generalUsage.sheet')), findsOneWidget);

    Finder tile(String key, String value) => find.descendant(
      of: find.byKey(Key('generalUsage.$key')),
      matching: find.text(value),
    );
    expect(tile('input', '1,180'), findsOneWidget);
    expect(tile('output', '330'), findsOneWidget);
    expect(tile('cost', '\$0.0062'), findsOneWidget);
    expect(tile('answers', '2'), findsOneWidget);
    expect(find.text('1,180 / 1,048,576 · 0.1%'), findsOneWidget);

    // by model, the most expensive first
    final kimi = find.byKey(
      const ValueKey('generalUsage.model.moonshotai/kimi-k3.1-pro'),
    );
    final glm = find.byKey(const ValueKey('generalUsage.model.z-ai/glm-5.3'));
    expect(kimi, findsOneWidget);
    expect(glm, findsOneWidget);
    expect(tester.getTopLeft(kimi).dy, lessThan(tester.getTopLeft(glm).dy));
    expect(
      find.descendant(
        of: kimi,
        matching: find.text('in 680 · out 300 · 1 answer'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: glm, matching: find.text('\$0.0002')),
      findsOneWidget,
    );

    // the key's spend (the G0 key: no reset)
    await pumpUntil(
      tester,
      find.byKey(const Key('generalUsage.key.line')),
      env: env,
    );
    await tester.pumpAndSettle();
    expect(find.text('\$3.68 of \$100.00'), findsOneWidget);
    expect(find.text('sk-or-v1-…4f2a'), findsOneWidget);

    await tester.tap(find.byKey(const Key('generalUsage.close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('generalUsage.sheet')), findsNothing);

    // a long press on the model chip opens it too; a tap is the picker
    await tester.longPress(find.byKey(const Key('general.modelChip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('generalUsage.sheet')), findsOneWidget);
    expect(find.byKey(const Key('picker')), findsNothing);
    await pumpUntil(tester, find.byKey(const Key('generalUsage.key.line')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generalUsage.close')));
    await tester.pumpAndSettle();
  });

  testWidgets('Settings → General: favourites and the system prompt', (
    tester,
  ) async {
    final env = await pumpDelve(
      tester,
      generalKey: testOpenRouterKey,
      before: seedModels,
    );
    await go(tester, Routes.generalSettings);
    await pumpUntil(
      tester,
      find.byKey(const Key('generalSettings.spend.line')),
    );
    await tester.pumpAndSettle();

    Future<List<String>?> stored() => tester.runAsync<List<String>?>(
      () => env.general.metaList(GeneralMetaKeys.favourites),
    );
    Finder fav(String id) => find.byKey(ValueKey('generalSettings.fav.$id'));
    for (final id in kDefaultFavourites) {
      expect(fav(id), findsOneWidget);
    }

    // remove, then Undo
    await tester.tap(
      find.byKey(const Key('generalSettings.fav.remove.z-ai/glm-5.3-flash')),
    );
    await tester.pumpAndSettle();
    expect(fav('z-ai/glm-5.3-flash'), findsNothing);
    expect(await stored(), [
      'z-ai/glm-5.3',
      'moonshotai/kimi-k3.1-pro',
      'anthropic/claude-opus-5.5',
      'openai/gpt-6-astra',
    ]);
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect(await stored(), kDefaultFavourites);
    expect(fav('z-ai/glm-5.3-flash'), findsOneWidget);

    // drag the first one below the second
    final from = tester.getCenter(
      find.byKey(const Key('generalSettings.fav.drag.z-ai/glm-5.3')),
    );
    // held at its centre, moved one row: its far edge is past the second
    // row's middle (with room for the touch slop), not past the third's
    final second = tester.getRect(fav('z-ai/glm-5.3-flash'));
    final to = Offset(from.dx, second.center.dy);
    final g = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 100));
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(0, (to.dy - from.dy) / steps));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();
    expect((await stored())!.take(2), ['z-ai/glm-5.3-flash', 'z-ai/glm-5.3']);

    // remove Astra, then add it back from the picker: it goes last
    await tester.tap(
      find.byKey(const Key('generalSettings.fav.remove.openai/gpt-6-astra')),
    );
    await tester.pumpAndSettle();
    expect(fav('openai/gpt-6-astra'), findsNothing);
    await tester.tap(find.byKey(const Key('generalSettings.fav.add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('picker.search')), 'astra');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker.all.openai/gpt-6-astra')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker')), findsNothing);
    expect((await stored())!.last, 'openai/gpt-6-astra');
    expect(fav('openai/gpt-6-astra'), findsOneWidget);

    // the system prompt is saved a moment after typing; blank removes it
    final prompt = find.byKey(const Key('generalSettings.prompt'));
    await tester.scrollUntilVisible(
      prompt,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('generalSettings.list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(prompt, 'Be brief.');
    await tester.pump(promptSaveDelay + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => env.general.meta(GeneralMetaKeys.systemPrompt),
      ),
      'Be brief.',
    );
    await tester.enterText(prompt, '  ');
    await tester.pump(promptSaveDelay + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => env.general.meta(GeneralMetaKeys.systemPrompt),
      ),
      isNull,
    );
  });
}
