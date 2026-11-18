import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

/// A story from `samples.json` with [overrides] (snake_case keys).
Map<String, Object?> newsJson([Map<String, Object?> overrides = const {}]) => {
  ...FakeServer.sample('news_item'),
  'saved': false,
  'feedback': null,
  'published_at': DateTime.now()
      .toUtc()
      .subtract(const Duration(hours: 2))
      .toIso8601String(),
  ...overrides,
};

Map<String, Object?> storyJson([Map<String, Object?> overrides = const {}]) => {
  ...FakeServer.sample('news_story'),
  'saved': false,
  'feedback': null,
  ...overrides,
};

Map<String, Object?> _body(FakeServer server, String method, String path) {
  final r = server.requests.lastWhere(
    (r) => r.method == method && r.uri.path == path,
  );
  final data = r.data;
  return (data is String ? jsonDecode(data) : data) as Map<String, Object?>;
}

void main() {
  /// The Dashboard block, the sections, one story and its marks.
  void serve(FakeServer server, {Map<String, Object?>? story}) {
    final release = FakeServer.sample('news_item_release');
    server
      ..json('GET', '/api/v1/news', {
        ...FakeServer.sample('news_digest'),
        'top': [newsJson(), release],
      })
      ..json('GET', '/api/v1/news/sections', {
        'data': [
          {
            ...FakeServer.sample('news_section'),
            'top': [newsJson()],
          },
          {
            'topic': 'local_ai',
            'name': 'Local AI',
            'count': 1,
            'week': 3,
            'new': 1,
            'top': [release],
          },
        ],
      })
      ..json('GET', '/api/v1/news/items/8121', story ?? storyJson())
      ..on('PATCH', '/api/v1/news/items/8121', (req) {
        final body =
            (req.data is String ? jsonDecode(req.data as String) : req.data)
                as Map<String, Object?>;
        return FakeReply(200, {
          ...(story ?? storyJson()),
          if (body['read'] case final bool r) 'read': r,
          if (body['saved'] case final bool s) 'saved': s,
          if (body.containsKey('feedback')) 'feedback': body['feedback'],
        });
      });
  }

  group('Dashboard News block (26a)', () {
    testWidgets('the best stories, markers, last week, failing feeds', (
      t,
    ) async {
      final env = await pumpDelve(t, before: (env) async => serve(env.server));
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(env.server.calls, contains('GET /api/v1/news'));
      final card = find.byKey(const Key('dashboard.news'));
      await t.ensureVisible(card);
      await t.pumpAndSettle();
      Finder inCard(Finder f) => find.descendant(of: card, matching: f);
      expect(inCard(find.text('News')), findsOneWidget);
      expect(inCard(find.text('12 new')), findsOneWidget);
      expect(
        inCard(
          find.text(
            'Team USA launches its new AC75 ahead of the Naples regatta',
          ),
        ),
        findsOneWidget,
      );
      expect(inCard(find.text('Must read')), findsOneWidget);
      // the release row touches the reader's setup
      expect(inCard(find.text('Your setup')), findsOneWidget);
      // D3: the topic label in its colour, “publisher · age” on the right,
      // the why under the first row only
      expect(inCard(find.text('SAILING')), findsOneWidget);
      expect(
        t.widget<Text>(inCard(find.text('SAILING'))).style!.color,
        const Color(0xFF8FB4E8),
      );
      expect(inCard(find.text('Sail-World · ')), findsOneWidget);
      expect(inCard(find.byKey(const Key('news.why.8121'))), findsOneWidget);
      expect(inCard(find.byKey(const Key('news.why.8140'))), findsNothing);
      expect(
        inCard(find.byKey(const Key('dashboard.news.weekly'))),
        findsOneWidget,
      );
      expect(inCard(find.text('3 feeds are failing')), findsOneWidget);

      // a row opens the reading view and marks the story read
      await t.tap(inCard(find.byKey(const Key('news.row.8121'))));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('news.story')), findsOneWidget);
      expect(_body(env.server, 'PATCH', '/api/v1/news/items/8121'), {
        'read': true,
      });
    });

    testWidgets('no News on the server: no block', (t) async {
      await pumpDelve(t);
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('dashboard.news')), findsNothing);
    });

    testWidgets('before the first round', (t) async {
      await pumpDelve(
        t,
        before: (env) async => env.server.json('GET', '/api/v1/news', {
          'top': <Object?>[],
          'new': 0,
          'updated_at': null,
          'state': 'empty',
          'sources': 41,
          'failing': 0,
          'weekly': null,
        }),
      );
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('dashboard.news.first')), findsOneWidget);
    });
  });

  group('News page (26b)', () {
    Future<TestEnv> openNews(WidgetTester t) async {
      final env = await pumpDelve(t, before: (env) async => serve(env.server));
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('News'));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('All: a section a topic, chips, Show all opens the topic', (
      t,
    ) async {
      final env = await openNews(t);
      expect(env.server.calls, contains('GET /api/v1/news/sections'));
      expect(find.byKey(const Key('news.section.sailing')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('news.section.sailing')),
          matching: find.text('4 today'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('news.section.local_ai')), findsOneWidget);
      // All · Saved · the topics
      final all = t.getTopLeft(find.byKey(const Key('news.chip.all'))).dx;
      final saved = t.getTopLeft(find.byKey(const Key('news.chip.saved'))).dx;
      final sailing = t
          .getTopLeft(find.byKey(const Key('news.chip.sailing')))
          .dx;
      expect(all < saved && saved < sailing, isTrue);

      env.server.json('GET', '/api/v1/news/items', {
        'data': [
          newsJson({'id': 8200, 'title': 'An older sailing story'}),
        ],
        'next_before': 8200,
      });
      await t.tap(find.byKey(const Key('news.showAll.sailing')));
      await t.pumpAndSettle();
      final q = env.server.requests
          .lastWhere((r) => r.uri.path == '/api/v1/news/items')
          .uri
          .queryParameters;
      expect((q['topic'], q['min_score']), ('sailing', '5'));
      expect(find.text('An older sailing story'), findsOneWidget);
      expect(find.text('4 today · 14 this week'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.byKey(const Key('news.loadOlder')), findsOneWidget);
    });

    testWidgets('long press: the menu saves and gives feedback', (t) async {
      final env = await openNews(t);
      await t.longPress(find.byKey(const Key('news.row.8121')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('news.menu.hide')), findsOneWidget);
      expect(find.text('Hide Sail-World'), findsOneWidget);
      await t.tap(find.byKey(const Key('news.menu.save')));
      await t.pumpAndSettle();
      expect(_body(env.server, 'PATCH', '/api/v1/news/items/8121'), {
        'saved': true,
      });
      expect(find.byKey(const Key('news.saved.8121')), findsOneWidget);

      await t.longPress(find.byKey(const Key('news.row.8121')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('news.menu.less')));
      await t.pumpAndSettle();
      expect(_body(env.server, 'PATCH', '/api/v1/news/items/8121'), {
        'feedback': 'less',
      });
    });
  });

  group('Reading view (26d)', () {
    Future<TestEnv> openStory(
      WidgetTester t, {
      Map<String, Object?>? story,
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async => serve(env.server, story: story),
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('News'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('news.row.8121')));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('text, AI summary, sources, Open original, feedback', (
      t,
    ) async {
      final env = await openStory(t);
      expect(find.text('AI summary'), findsOneWidget);
      expect(find.textContaining('A Team USA vízre tette'), findsOneWidget);
      expect(find.text('WHY'), findsOneWidget);
      expect(find.byKey(const Key('news.story.why')), findsOneWidget);
      expect(find.byKey(const Key('news.story.sources')), findsOneWidget);
      expect(
        find.textContaining('text from here', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Testing starts next week.'), findsOneWidget);
      await t.scrollUntilVisible(
        find.byKey(const Key('news.story.more')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('news.story')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(find.byKey(const Key('news.story.more')));
      await t.pumpAndSettle();
      expect(_body(env.server, 'PATCH', '/api/v1/news/items/8121'), {
        'feedback': 'more',
      });
      expect(
        find.text('More like this · counts from the next round'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('news.story.original')));
      await t.pumpAndSettle();
      expect(env.links.opened.single.host, 'www.sail-world.com');
      await t.tap(find.byKey(const Key('news.story.save')));
      await t.pumpAndSettle();
      expect(_body(env.server, 'PATCH', '/api/v1/news/items/8121'), {
        'saved': true,
      });
    });

    testWidgets('failed: the reason and Try again queues it', (t) async {
      final failed = storyJson({
        'text_state': 'failed',
        'text': null,
        'text_at': null,
        'text_error': 'robots',
        'summary_hu': null,
      });
      final env = await openStory(t, story: failed);
      // no summary and no text: no AI block, the why stays as a quote
      expect(find.byKey(const Key('news.story.ai')), findsNothing);
      expect(find.byKey(const Key('news.story.why')), findsOneWidget);
      expect(find.text('No article text'), findsOneWidget);
      expect(
        find.text("The site doesn't allow automatic reading (robots.txt)."),
        findsOneWidget,
      );
      env.server.json('POST', '/api/v1/news/items/8121/text', {
        ...failed,
        'text_state': 'queued',
        'text_error': null,
      });
      await t.tap(find.byKey(const Key('news.story.fetch')));
      await t.pumpAndSettle();
      expect(env.server.calls, contains('POST /api/v1/news/items/8121/text'));
      expect(find.byKey(const Key('news.story.state.queued')), findsOneWidget);
      expect(find.text('Fetching text · within the hour'), findsOneWidget);
    });
  });
}
