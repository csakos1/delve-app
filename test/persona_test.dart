import 'package:delve/api/api_error.dart';
import 'package:delve/api/models/models.dart';
import 'package:delve/api/rest_client.dart';
import 'package:delve/app/session.dart';
import 'package:delve/general/general_database.dart';
import 'package:delve/general/openrouter_client.dart';
import 'package:delve/persona/persona_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

Future<void> frames(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The profile of `samples.json`: three sections (the second for General),
/// two topic files (`books` for General, `gepek`).
Map<String, Object?> sample() => FakeServer.sample('persona');

void main() {
  test('a topic file is named after its title', () {
    expect(topicNameOf('Tanulmányok és munka'), 'tanulmanyok-es-munka');
    expect(topicNameOf('  Film / játék  '), 'film-jatek');
    expect(topicNameOf('Desktop (Arch) 2'), 'desktop-arch-2');
    expect(topicNameOf('Őszi űrlap'), 'oszi-urlap');
    expect(topicNameOf('!!!'), '');
    expect(topicNameOf('x' * 60), 'x' * 40);
    expect(topicNameOf('${'a' * 39} b'), 'a' * 39);
  });

  test('the General system message: the profile part, then the prompt', () {
    expect(composeSystemPrompt(), isNull);
    expect(composeSystemPrompt(prompt: ' Brief. '), ' Brief. ');
    expect(composeSystemPrompt(persona: ' About. \n'), 'About.');
    expect(composeSystemPrompt(persona: '  ', prompt: 'Brief.'), 'Brief.');
    expect(composeSystemPrompt(persona: 'About.', prompt: ' '), 'About.');
    expect(
      composeSystemPrompt(persona: 'About.', prompt: 'Brief.'),
      'About.\n\nBrief.',
    );
  });

  group('REST', () {
    late FakeServer server;
    late DelveApi api;

    setUp(() {
      server = FakeServer();
      api = DelveApi(server: testServer, token: 'dlv_x', adapter: server);
      addTearDown(api.close);
    });

    test('GET /persona', () async {
      final p = await api.persona();
      expect(p.available, isTrue);
      expect(p.revision, hasLength(12));
      expect(p.sections.map((s) => (s.title, s.general)), [
        ('Basics', false),
        ('Answering', true),
        ('His own words', false),
      ]);
      expect(p.topics.map((t) => (t.name, t.title, t.general)), [
        ('books', 'Books', true),
        ('gepek', 'Machines', false),
      ]);
      expect(p.blockChars, p.block.length);
      expect(p.generalText, contains('### Answering'));
      expect(p.generalText, isNot(contains('Minta Bence')));
      expect(server.calls, ['GET /api/v1/persona']);
    });

    test('a desktop without a profile directory', () async {
      server.json('GET', '/api/v1/persona', {
        'available': false,
        'revision': null,
        'block': '',
        'block_chars': 0,
        'general_text': '',
        'sections': <Object?>[],
        'topics': <Object?>[],
      });
      final p = await api.persona();
      expect((p.available, p.revision, p.block), (false, null, ''));
      expect(p.sections, isEmpty);
      expect(p.topics, isEmpty);
    });

    test('the core is replaced whole', () async {
      server.json('PUT', '/api/v1/persona/profile', sample());
      await api.putPersonaProfile(const [
        PersonaSection(title: 'Basics', text: '- A'),
        PersonaSection(title: 'Style', text: '- B', general: true),
      ]);
      expect(server.calls, ['PUT /api/v1/persona/profile']);
      expect(server.requests.single.data, {
        'sections': [
          {'title': 'Basics', 'text': '- A', 'general': false},
          {'title': 'Style', 'text': '- B', 'general': true},
        ],
      });
    });

    test('a topic file is saved and removed by its name', () async {
      server
        ..json('PUT', '/api/v1/persona/topics/gepek', sample())
        ..json('DELETE', '/api/v1/persona/topics/gepek', sample());
      await api.putPersonaTopic(
        const PersonaTopic(
          name: 'gepek',
          title: 'Machines',
          summary: 'the parts',
          text: '- 48 GB',
        ),
      );
      expect(server.requests.single.data, {
        'title': 'Machines',
        'summary': 'the parts',
        'text': '- 48 GB',
        'general': false,
      });
      await api.deletePersonaTopic('gepek');
      expect(server.calls, [
        'PUT /api/v1/persona/topics/gepek',
        'DELETE /api/v1/persona/topics/gepek',
      ]);
    });

    test('the server says why it did not save', () async {
      server.json(
        'PUT',
        '/api/v1/persona/profile',
        FakeServer.detail('persona_no_store', 'not set up'),
        status: 503,
      );
      await expectLater(
        api.putPersonaProfile(const []),
        throwsA(
          isA<ApiRequestError>()
              .having((e) => e.status, 'status', 503)
              .having((e) => e.code, 'code', 'persona_no_store'),
        ),
      );
    });
  });

  group('the controller', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    Future<ProviderContainer> start() async {
      final c = env.container();
      c
        ..listen(sessionProvider, (_, _) {})
        ..listen(personaProvider, (_, _) {});
      await pumpEventQueue(times: 200);
      return c;
    }

    test('loading keeps the part for General on the phone', () async {
      env = TestEnv(credentials: pairedCredentials());
      final c = await start();
      expect(c.read(personaProvider).persona, isNull);
      await c.read(personaProvider.notifier).refresh();
      final view = c.read(personaProvider);
      expect(view.error, isNull);
      expect(view.persona!.sections, hasLength(3));
      expect(
        await env.general.meta(GeneralMetaKeys.personaGeneral),
        view.persona!.generalText,
      );
    });

    test('nothing marked for General: the copy is removed', () async {
      env = TestEnv(credentials: pairedCredentials());
      await env.general.setMeta(GeneralMetaKeys.personaGeneral, 'old');
      env.server.json('GET', '/api/v1/persona', {
        ...sample(),
        'general_text': '',
      });
      final c = await start();
      await c.read(personaProvider.notifier).refresh();
      expect(await env.general.meta(GeneralMetaKeys.personaGeneral), isNull);
    });

    test('a failed load keeps what was shown and the phone\'s copy', () async {
      env = TestEnv(credentials: pairedCredentials());
      final c = await start();
      await c.read(personaProvider.notifier).refresh();
      env.server.unreachable = true;
      await c.read(personaProvider.notifier).refresh();
      final view = c.read(personaProvider);
      expect(view.error, isA<ApiUnreachable>());
      expect(view.persona, isNotNull);
      expect(await env.general.meta(GeneralMetaKeys.personaGeneral), isNotNull);
    });

    test('an edit takes the server\'s answer; a refused one throws', () async {
      env = TestEnv(credentials: pairedCredentials());
      final c = await start();
      final answer = {...sample(), 'general_text': 'only this'};
      env.server.json('PUT', '/api/v1/persona/topics/books', answer);
      await c
          .read(personaProvider.notifier)
          .saveTopic(
            const PersonaTopic(name: 'books', title: 'Books', text: 'x'),
          );
      expect(c.read(personaProvider).persona!.generalText, 'only this');
      expect(
        await env.general.meta(GeneralMetaKeys.personaGeneral),
        'only this',
      );
      env.server.json(
        'DELETE',
        '/api/v1/persona/topics/books',
        FakeServer.detail('topic_not_found', 'no such topic'),
        status: 404,
      );
      await expectLater(
        c.read(personaProvider.notifier).deleteTopic('books'),
        throwsA(isA<ApiRequestError>()),
      );
      expect(c.read(personaProvider).persona!.generalText, 'only this');
    });
  });

  group('More → About me', () {
    Future<TestEnv> open(
      WidgetTester t, {
      void Function(TestEnv env)? before,
    }) async {
      final env = await pumpDelve(
        t,
        before: before == null ? null : (env) async => before(env),
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('About me'));
      await t.pumpAndSettle();
      await frames(t);
      return env;
    }

    Switch toggle(WidgetTester t, String key) =>
        t.widget<Switch>(find.byKey(Key(key)));

    testWidgets('shows the core and the topic files; a switch marks a section '
        'for General', (t) async {
      final env = await open(t);
      for (final text in ['Basics', 'Answering', 'Books', 'Machines']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Name: Minta Bence. Lives in Győr.'), findsOneWidget);
      expect(find.text('what he reads'), findsOneWidget);
      expect(toggle(t, 'persona.section.0.general').value, isFalse);
      expect(toggle(t, 'persona.section.1.general').value, isTrue);
      expect(toggle(t, 'persona.topic.books.general').value, isTrue);

      env.server.json('PUT', '/api/v1/persona/profile', sample());
      await t.tap(find.byKey(const Key('persona.section.0.general')));
      await frames(t);
      expect(env.server.calls.last, 'PUT /api/v1/persona/profile');
      final sent =
          (env.server.requests.last.data as Map<String, Object?>)['sections']!
              as List<Object?>;
      expect(sent, hasLength(3));
      expect(sent.first, {
        'title': 'Basics',
        'text': '- Name: Minta Bence. Lives in Győr.\n- Dog: Zsömle, a vizsla.',
        'general': true,
      });
    });

    testWidgets('what is sent can be looked at', (t) async {
      await open(t);
      await t.dragUntilVisible(
        find.byKey(const Key('persona.toGeneral')),
        find.byKey(const Key('persona.list')),
        const Offset(0, -200),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('persona.toGeneral')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('persona.preview')), findsOneWidget);
      final shown = t.widget<SelectableText>(find.byType(SelectableText)).data!;
      expect(shown, contains('### Answering'));
      expect(shown, isNot(contains('Minta Bence')));
    });

    testWidgets('a new topic file is named after its title; a taken name is '
        'refused', (t) async {
      final env = await open(t);
      await t.dragUntilVisible(
        find.byKey(const Key('persona.addTopic')),
        find.byKey(const Key('persona.list')),
        const Offset(0, -200),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('persona.addTopic')));
      await t.pumpAndSettle();
      expect(find.text('New topic file'), findsOneWidget);

      await t.enterText(find.byKey(const Key('persona.field.title')), 'Books');
      await t.enterText(find.byKey(const Key('persona.field.text')), '- x');
      await t.pump();
      await t.tap(find.byKey(const Key('persona.save')));
      await frames(t);
      expect(
        find.text('A topic file with this name exists already'),
        findsOneWidget,
      );
      expect(env.server.calls.where((c) => c.startsWith('PUT')), isEmpty);

      env.server.json('PUT', '/api/v1/persona/topics/sailing-notes', sample());
      await t.enterText(
        find.byKey(const Key('persona.field.title')),
        'Sailing notes',
      );
      await t.enterText(
        find.byKey(const Key('persona.field.summary')),
        'boats and races',
      );
      await t.pump();
      expect(find.text('File: sailing-notes.md'), findsOneWidget);
      await t.tap(find.byKey(const Key('persona.save')));
      await t.pumpAndSettle();
      await frames(t);
      expect(env.server.calls.last, 'PUT /api/v1/persona/topics/sailing-notes');
      expect(env.server.requests.last.data, {
        'title': 'Sailing notes',
        'summary': 'boats and races',
        'text': '- x',
        'general': false,
      });
      // saved: back on the page
      expect(find.text('New topic file'), findsNothing);
      expect(find.byKey(const Key('persona.list')), findsOneWidget);
    });

    testWidgets('a save the server refuses leaves the editor open', (t) async {
      final env = await open(t);
      await t.tap(find.byKey(const Key('persona.section.0')));
      await t.pumpAndSettle();
      expect(find.text('Section'), findsOneWidget);
      env.server.json(
        'PUT',
        '/api/v1/persona/profile',
        FakeServer.detail(
          'persona_not_writable',
          'the profile cannot be written',
        ),
        status: 503,
      );
      await t.tap(find.byKey(const Key('persona.save')));
      await frames(t);
      expect(find.textContaining("Couldn't save"), findsOneWidget);
      expect(find.byKey(const Key('persona.field.text')), findsOneWidget);
    });

    testWidgets('a desktop without a profile directory says so', (t) async {
      await open(
        t,
        before: (env) => env.server.json('GET', '/api/v1/persona', {
          'available': false,
          'revision': null,
          'block': '',
          'block_chars': 0,
          'general_text': '',
          'sections': <Object?>[],
          'topics': <Object?>[],
        }),
      );
      expect(find.byKey(const Key('persona.noStore')), findsOneWidget);
      expect(find.byKey(const Key('persona.noSections')), findsOneWidget);
      expect(
        t.widget<ListTile>(find.byKey(const Key('persona.addSection'))).enabled,
        isFalse,
      );
    });

    testWidgets('a failed load can be retried', (t) async {
      final env = await open(
        t,
        before: (env) => env.server.json(
          'GET',
          '/api/v1/persona',
          FakeServer.detail('boom'),
          status: 500,
        ),
      );
      expect(find.byKey(const Key('persona.loadFailed')), findsOneWidget);
      env.server.json('GET', '/api/v1/persona', sample());
      await t.tap(find.widgetWithText(TextButton, 'Retry'));
      await frames(t);
      expect(find.text('Basics'), findsOneWidget);
    });
  });
}
