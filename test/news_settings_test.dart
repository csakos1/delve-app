import 'dart:convert';

import 'package:delve/ui/widgets/news_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

Map<String, Object?> _bodyOf(RequestOptions r) =>
    (r.data is String ? jsonDecode(r.data as String) : r.data)
        as Map<String, Object?>;

Map<String, Object?> _lastBody(FakeServer server, String method, String path) =>
    _bodyOf(
      server.requests.lastWhere(
        (r) => r.method == method && r.uri.path == path,
      ),
    );

final _topics = <Map<String, Object?>>[
  FakeServer.sample('news_topic'),
  {
    'id': 'local_ai',
    'name': 'Local AI',
    'description': '',
    'position': 1,
    'enabled': true,
    'sources': 3,
    'items_24h': 12,
  },
  {
    'id': 'astronomy',
    'name': 'Astronomy',
    'description': 'Launches and eclipses.',
    'position': 2,
    'enabled': false,
    'sources': 1,
    'items_24h': 0,
  },
];

Map<String, Object?> _source(Map<String, Object?> overrides) => {
  ...FakeServer.sample('news_source'),
  ...overrides,
};

final _sources = <Map<String, Object?>>[
  // ok first in the server's order: the failing one must still lead
  _source({
    'id': 'reddit.com-r-localllama',
    'topic': 'local_ai',
    'url': 'https://www.reddit.com/r/LocalLLaMA/.rss',
    'last_status': 'ok',
    'last_http': 200,
    'last_error_code': null,
    'last_error': null,
    'last_items': 25,
    'last_new': 4,
    'errors_in_row': 0,
  }),
  FakeServer.sample('news_source'), // sail-world.com: HTTP 503, 3 in a row
  _source({
    'id': 'news.google.com-sailgp',
    'url': 'https://news.google.com/rss/search?q=sailgp',
    'last_status': 'not_modified',
    'last_http': 304,
    'last_error_code': null,
    'last_error': null,
    'errors_in_row': 0,
    'last_item_at': null,
  }),
];

void _serve(FakeServer server) {
  server
    ..json('GET', '/api/v1/news', FakeServer.sample('news_digest'))
    ..json('GET', '/api/v1/news/sections', {
      'data': [
        {...FakeServer.sample('news_section'), 'top': <Object?>[]},
      ],
    })
    ..json('GET', '/api/v1/news/topics', {'data': _topics})
    ..json('GET', '/api/v1/news/sources', {'data': _sources})
    ..json('GET', '/api/v1/news/settings', FakeServer.sample('news_settings'))
    ..on(
      'PATCH',
      '/api/v1/news/settings',
      (r) => FakeReply(200, {
        ...FakeServer.sample('news_settings'),
        ..._bodyOf(r),
      }),
    );
  for (final t in _topics) {
    server.on(
      'PATCH',
      '/api/v1/news/topics/${t['id']}',
      (r) => FakeReply(200, {...t, ..._bodyOf(r)}),
    );
  }
  for (final s in _sources) {
    server
      ..on(
        'PATCH',
        '/api/v1/news/sources/${s['id']}',
        (r) => FakeReply(200, {...s, ..._bodyOf(r)}),
      )
      ..on(
        'DELETE',
        '/api/v1/news/sources/${s['id']}',
        (_) => const FakeReply(204),
      );
  }
}

Future<TestEnv> _openSettings(WidgetTester t) async {
  final env = await pumpDelve(t, before: (env) async => _serve(env.server));
  await t.tap(find.text('More'));
  await t.pumpAndSettle();
  await t.tap(find.text('News'));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('news.settings')));
  await t.pumpAndSettle();
  return env;
}

Color? _iconColor(WidgetTester t, Finder within, IconData icon) => t
    .widget<Icon>(find.descendant(of: within, matching: find.byIcon(icon)))
    .color;

String _plain(WidgetTester t, Key key) =>
    t.widget<Text>(find.byKey(key)).textSpan!.toPlainText();

void main() {
  group('News settings (D3-e)', () {
    testWidgets('topics, feeds (failing first), digest and push', (t) async {
      final env = await _openSettings(t);
      expect(
        env.server.calls,
        containsAll([
          'GET /api/v1/news/topics',
          'GET /api/v1/news/sources',
          'GET /api/v1/news/settings',
        ]),
      );
      expect(find.text('News settings'), findsOneWidget);
      expect(find.text('TOPICS'), findsOneWidget);
      expect(
        find.text('drag to reorder · tap for the description'),
        findsOneWidget,
      );

      // the glyph in the topic's colour; a topic that is off: disabled
      final sailing = find.byKey(const Key('newsSettings.topic.open.sailing'));
      expect(
        _iconColor(t, sailing, TopicStyle.of('sailing').glyph),
        const Color(0xFF8FB4E8),
      );
      expect(
        find.descendant(
          of: sailing,
          matching: find.text('7 sources · 5 stories in 24 h'),
        ),
        findsOneWidget,
      );
      final astronomy = find.byKey(
        const Key('newsSettings.topic.open.astronomy'),
      );
      // an id the app does not know: the fallback glyph
      expect(
        _iconColor(t, astronomy, TopicStyle.fallback.glyph),
        const Color(0xFF5C5F65),
      );
      expect(
        find.descendant(
          of: astronomy,
          matching: find.text('1 source · 0 stories in 24 h'),
        ),
        findsOneWidget,
      );

      // feeds: the count with the failing ones, the failing feed first
      await t.ensureVisible(find.text('FEEDS'));
      expect(find.text('3 · 1 failing'), findsOneWidget);
      final failing = find.byKey(const Key('newsSettings.feed.sail-world.com'));
      final ok = find.byKey(
        const Key('newsSettings.feed.reddit.com-r-localllama'),
      );
      expect(t.getTopLeft(failing).dy, lessThan(t.getTopLeft(ok).dy));
      expect(
        _plain(t, const Key('newsSettings.feed.status.sail-world.com')),
        contains('error · HTTP 503 · 3 in a row · Sailing · RSS · checked'),
      );
      expect(
        _plain(
          t,
          const Key('newsSettings.feed.status.reddit.com-r-localllama'),
        ),
        contains('ok · Local AI · RSS'),
      );
      expect(
        _plain(t, const Key('newsSettings.feed.status.news.google.com-sailgp')),
        contains('not modified · Sailing · Google News'),
      );
      expect(find.text('www.sail-world.com/rss'), findsOneWidget);

      // digest and push; this phone's News switch is off: a note says so
      await t.ensureVisible(find.byKey(const Key('newsSettings.pushMax.more')));
      await t.pumpAndSettle();
      expect(find.text('07:00'), findsOneWidget);
      expect(
        find.text('Score 9 only · between 07:00 and 22:00'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('newsSettings.pushMax.value')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('newsSettings.phoneOff')), findsOneWidget);
    });

    testWidgets('a topic off, the push off, its limit up', (t) async {
      final env = await _openSettings(t);
      await t.tap(find.byKey(const Key('newsSettings.topic.switch.local_ai')));
      await t.pumpAndSettle();
      expect(_lastBody(env.server, 'PATCH', '/api/v1/news/topics/local_ai'), {
        'enabled': false,
      });
      expect(
        t
            .widget<Switch>(
              find.byKey(const Key('newsSettings.topic.switch.local_ai')),
            )
            .value,
        isFalse,
      );
      // the News page's sections follow
      expect(
        env.server.calls.where((c) => c == 'GET /api/v1/news/sections').length,
        greaterThan(1),
      );

      await t.ensureVisible(find.byKey(const Key('newsSettings.pushMax.more')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('newsSettings.push')));
      await t.pumpAndSettle();
      expect(_lastBody(env.server, 'PATCH', '/api/v1/news/settings'), {
        'push': false,
      });
      expect(
        t.widget<Switch>(find.byKey(const Key('newsSettings.push'))).value,
        isFalse,
      );
      await t.tap(find.byKey(const Key('newsSettings.pushMax.more')));
      await t.pumpAndSettle();
      expect(_lastBody(env.server, 'PATCH', '/api/v1/news/settings'), {
        'push_max': 3,
      });
      expect(
        t
            .widget<Text>(find.byKey(const Key('newsSettings.pushMax.value')))
            .data,
        '3',
      );
    });

    testWidgets('drag to reorder: the moved topics get their place', (t) async {
      final env = await _openSettings(t);
      t
          .widget<ReorderableListView>(
            find.byKey(const Key('newsSettings.topics')),
          )
          .onReorder(0, 2);
      await t.pumpAndSettle();
      final patches = [
        for (final r in env.server.requests)
          if (r.method == 'PATCH') '${r.uri.path} ${jsonEncode(_bodyOf(r))}',
      ];
      expect(patches, [
        '/api/v1/news/topics/local_ai {"position":0}',
        '/api/v1/news/topics/sailing {"position":1}',
      ]);
      final localAi = find.byKey(const Key('newsSettings.topic.open.local_ai'));
      final sailing = find.byKey(const Key('newsSettings.topic.open.sailing'));
      expect(t.getTopLeft(localAi).dy, lessThan(t.getTopLeft(sailing).dy));
    });

    testWidgets('the description editor saves what changed', (t) async {
      final env = await _openSettings(t);
      await t.tap(find.text('Sailing'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsSettings.editor')), findsOneWidget);
      expect(find.text('What you care about'), findsOneWidget);
      expect(find.text("America's Cup, SailGP, the Balaton."), findsOneWidget);
      expect(find.text('35 / 1500'), findsOneWidget);
      await t.enterText(
        find.byKey(const Key('newsSettings.editor.text')),
        'Only the AC and SailGP.',
      );
      await t.pump();
      expect(find.text('23 / 1500'), findsOneWidget);
      await t.tap(find.byKey(const Key('newsSettings.editor.save')));
      await t.pumpAndSettle();
      expect(_lastBody(env.server, 'PATCH', '/api/v1/news/topics/sailing'), {
        'description': 'Only the AC and SailGP.',
      });
      expect(find.byKey(const Key('newsSettings.editor')), findsNothing);
    });

    testWidgets('a failing feed: its answer, off, deleted', (t) async {
      final env = await _openSettings(t);
      await t.ensureVisible(
        find.byKey(const Key('newsSettings.feed.sail-world.com')),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('www.sail-world.com/rss'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsFeed')), findsOneWidget);
      expect(
        find.text('This feed has failed 3 rounds in a row'),
        findsOneWidget,
      );
      expect(
        t
            .widget<SelectableText>(find.byKey(const Key('newsFeed.address')))
            .data,
        'https://www.sail-world.com/rss',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('newsFeed.answer'))).data,
        'HTTP 503 · Service Unavailable',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('newsFeed.lastStory'))).data,
        isNot('none yet'),
      );
      expect(find.text('SAILING'), findsOneWidget);
      expect(find.text('Check now'), findsNothing);

      await t.tap(find.byKey(const Key('newsFeed.collect')));
      await t.pumpAndSettle();
      expect(
        _lastBody(env.server, 'PATCH', '/api/v1/news/sources/sail-world.com'),
        {'enabled': false},
      );

      await t.ensureVisible(find.byKey(const Key('newsFeed.delete')));
      await t.tap(find.byKey(const Key('newsFeed.delete')));
      await t.pumpAndSettle();
      expect(find.text('Delete this feed?'), findsOneWidget);
      await t.tap(find.byKey(const Key('newsFeed.delete.confirm')));
      await t.pumpAndSettle();
      expect(
        env.server.calls,
        contains('DELETE /api/v1/news/sources/sail-world.com'),
      );
      expect(find.byKey(const Key('newsFeed')), findsNothing);
      expect(find.text('Feed deleted'), findsOneWidget);
      expect(
        find.byKey(const Key('newsSettings.feed.sail-world.com')),
        findsNothing,
      );
    });

    testWidgets("a feed's newest story is unknown: none yet", (t) async {
      await _openSettings(t);
      await t.ensureVisible(
        find.byKey(const Key('newsSettings.feed.news.google.com-sailgp')),
      );
      await t.pumpAndSettle();
      await t.tap(
        find.byKey(const Key('newsSettings.feed.news.google.com-sailgp')),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsFeed.failing')), findsNothing);
      expect(
        t.widget<Text>(find.byKey(const Key('newsFeed.lastStory'))).data,
        'none yet',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('newsFeed.answer'))).data,
        'HTTP 304',
      );
      expect(find.text('Google News'), findsOneWidget);
    });

    testWidgets('a load error has Retry', (t) async {
      final env = await pumpDelve(t, before: (env) async => _serve(env.server));
      env.server.json(
        'GET',
        '/api/v1/news/topics',
        FakeServer.detail('internal'),
        status: 500,
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('News'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('news.settings')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsSettings.error')), findsOneWidget);
      env.server.json('GET', '/api/v1/news/topics', {'data': _topics});
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsSettings')), findsOneWidget);
    });

    testWidgets("the Dashboard's failing feeds open News settings", (t) async {
      await pumpDelve(t, before: (env) async => _serve(env.server));
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      final row = find.byKey(const Key('dashboard.news.failing'));
      await t.ensureVisible(row);
      await t.pumpAndSettle();
      expect(
        find.descendant(of: row, matching: find.text('Feeds')),
        findsOneWidget,
      );
      await t.tap(row);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsSettings')), findsOneWidget);
    });

    testWidgets('every topic off: the empty News page opens the settings', (
      t,
    ) async {
      await pumpDelve(
        t,
        before: (env) async {
          _serve(env.server);
          env.server.json('GET', '/api/v1/news/sections', {
            'data': <Object?>[],
          });
        },
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('News'));
      await t.pumpAndSettle();
      expect(find.text('Every topic is off'), findsOneWidget);
      await t.tap(find.byKey(const Key('news.empty.settings')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('newsSettings')), findsOneWidget);
    });
  });
}
