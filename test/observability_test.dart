import 'package:delve/ui/format.dart';
import 'package:delve/ui/widgets/stats_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/layout.dart';

void main() {
  group('scale and format', () {
    test('nice steps', () {
      expect(
        [
          for (final r in [0.3, 1.0, 1.2, 2.2, 4.0, 7.0, 60.0]) niceStep(r),
        ],
        [0.5, 1, 2, 2.5, 5, 10, 100],
      );
    });

    test('three grid lines around the values', () {
      expect(statsScale([20.8, 21.4, 22.0]), (lo: 20.0, hi: 22.0));
      expect(statsScale([620, 680], minSpan: 40), (lo: 600.0, hi: 700.0));
      expect(statsScale([0, 1, 2], zero: true, minSpan: 2), (lo: 0.0, hi: 2.0));
      expect(statsScale([30, 118], zero: true, minSpan: 60), (
        lo: 0.0,
        hi: 200.0,
      ));
      expect(statsScale([72, 84], minSpan: 20, max: 100), (lo: 70.0, hi: 90.0));
      expect(statsScale(const [], zero: true, minSpan: 60), (
        lo: 0.0,
        hi: 100.0,
      ));
      expect(statsScale([99], minSpan: 20, max: 100), (lo: 80.0, hi: 100.0));
      expect(statsScale(const []), (lo: 0.0, hi: 1.0));
      for (final values in [
        [3.0, 997.0],
        [0.1, 0.2],
        [45.0, 71.0],
        [8.0, 187.0],
      ]) {
        final s = statsScale(values);
        expect(s.lo, lessThanOrEqualTo(values.first), reason: '$values');
        expect(s.hi, greaterThanOrEqualTo(values.last), reason: '$values');
      }
    });

    test('waits', () {
      expect(
        [
          for (final s in [30.0, 89.4, 240.0, 7200.0]) secondsText(s),
        ],
        ['30 s', '89 s', '4 min', '2.0 h'],
      );
    });
  });

  group('Observability (15)', () {
    Future<TestEnv> openObs(
      WidgetTester t, {
      Map<String, Object?>? stats,
      int status = 200,
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async {
          if (stats != null || status != 200) {
            env.server.json(
              'GET',
              '/api/v1/stats',
              stats ?? FakeServer.detail('boom', 'boom'),
              status: status,
            );
          }
        },
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Observability'));
      await t.pumpAndSettle();
      return env;
    }

    Finder list() => find
        .descendant(
          of: find.byKey(const Key('obs.list')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<String> value(WidgetTester t, String card) async {
      final c = find.byKey(Key('obs.$card'));
      await t.scrollUntilVisible(c, 200, scrollable: list());
      final v = find.descendant(
        of: c,
        matching: find.byKey(const Key('obs.value')),
      );
      expectOnRightEdge(t, v, c);
      return t.widget<Text>(v).data!;
    }

    testWidgets('the day: eight cards with their headline values', (t) async {
      final env = await openObs(t);
      final req = env.server.requests.lastWhere(
        (r) => r.uri.path == '/api/v1/stats',
      );
      expect(req.uri.queryParameters, {'range': '24h'});
      expect(find.text('Generation'), findsOneWidget);
      expect(await value(t, 'generation'), '20.8 tok/s');
      expect(await value(t, 'prefill'), '666 tok/s');
      expect(
        find.textContaining('prompts ≥ 500 tok', findRichText: true),
        findsOneWidget,
      );
      expect(await value(t, 'queue'), '2');
      expect(await value(t, 'latency'), '30 s');
      expect(
        find.textContaining('median per hour', findRichText: true),
        findsOneWidget,
      );
      expect(await value(t, 'cache'), '78 %');
      expect(await value(t, 'tokens'), '300,600');
      expect(
        find.textContaining('last 7 d', findRichText: true),
        findsOneWidget,
      );
      expect(await value(t, 'gpuTemp'), '71 / 58 °C');
      expect(await value(t, 'gpuPower'), '187 / 62 W');
      expect(find.text('RTX 4070 SUPER'), findsWidgets); // the legends
      expect(find.text('RTX 3050'), findsWidgets);
      expect(find.byKey(const Key('obs.sampling')), findsNothing);
      expect(find.byKey(const Key('obs.error')), findsNothing);
    });

    testWidgets('a range chip asks for that range', (t) async {
      final env = await openObs(t);
      env.server.json('GET', '/api/v1/stats', {
        ...FakeServer.sample('stats'),
        'range': '7d',
      });
      await t.tap(find.byKey(const Key('obs.range.7d')));
      await t.pumpAndSettle();
      final req = env.server.requests.lastWhere(
        (r) => r.uri.path == '/api/v1/stats',
      );
      expect(req.uri.queryParameters, {'range': '7d'});
      expect(
        t.widget<ChoiceChip>(find.byKey(const Key('obs.range.7d'))).selected,
        isTrue,
      );
      expect(
        t.widget<ChoiceChip>(find.byKey(const Key('obs.range.24h'))).selected,
        isFalse,
      );
      await t.scrollUntilVisible(
        find.byKey(const Key('obs.latency')),
        200,
        scrollable: list(),
      );
      expect(
        find.textContaining('median per 6 h', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a failed load says why and retries', (t) async {
      final env = await openObs(t, status: 500);
      expect(find.byKey(const Key('obs.error')), findsOneWidget);
      expect(
        find.textContaining("Couldn't load the statistics"),
        findsOneWidget,
      );
      expect(find.text('Generation'), findsNothing);

      env.server.reset();
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('obs.error')), findsNothing);
      expect(find.text('Generation'), findsOneWidget);
    });

    testWidgets('GPU sampling failing: say so, no GPU values', (t) async {
      await openObs(
        t,
        stats: {
          ...FakeServer.sample('stats'),
          'gpus': <Object?>[],
          'sampling': {
            'interval_s': 60,
            'ok': false,
            'error': 'HelperUnavailable: /run/delve-helper.sock',
            'last_at': null,
          },
        },
      );
      await t.scrollUntilVisible(
        find.byKey(const Key('obs.sampling')),
        200,
        scrollable: list(),
      );
      expect(
        find.textContaining('GPU sampling fails: HelperUnavailable'),
        findsOneWidget,
      );
      expect(await value(t, 'gpuTemp'), '—');
      expect(find.text('RTX 3050'), findsNothing);
    });

    testWidgets('a big text size does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openObs(t);
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(
        find.byKey(const Key('obs.gpuPower')),
        300,
        scrollable: list(),
      );
      expect(t.takeException(), isNull);
    });
  });
}
