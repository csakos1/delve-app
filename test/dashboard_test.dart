import 'package:delve/api/models/models.dart';
import 'package:delve/app/dashboard.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/data/db/store.dart';
import 'package:delve/ui/format.dart';
import 'package:delve/ui/widgets/water_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

AgentCard water(
  String id,
  DateTime ts, {
  double level = 98,
  double? lake = 101,
  double? trend = -2,
  String origin = 'script',
  String type = 'water',
  String station = 'Siófok',
}) => AgentCard(
  id: id,
  type: type,
  severity: 'info',
  ts: ts.toUtc(),
  origin: origin,
  payload: {
    'station': station,
    'level_cm': level,
    'measured_at': ts
        .subtract(const Duration(hours: 2))
        .toUtc()
        .toIso8601String(),
    'lake_avg_cm': ?lake,
    'trend_cm_24h': ?trend,
  },
  receivedAt: ts.toUtc(),
);

Map<String, Object?> json(AgentCard c) => Map<String, Object?>.from(c.toJson())
  ..['ts'] = c.ts.toIso8601String()
  ..['received_at'] = c.receivedAt.toIso8601String();

CardRow row(AgentCard c) => CardRow(
  id: c.id,
  type: c.type,
  severity: c.severity,
  ts: c.ts,
  origin: c.origin,
  payload: c.payload,
  receivedAt: c.receivedAt,
);

void main() {
  final now = DateTime(2026, 10, 20, 21); // a Tuesday evening, local

  group('water readings', () {
    test('lenient payload reading; other cards are not readings', () {
      final r = WaterReading.of(row(water('a', now)))!;
      expect(
        (r.station, r.levelCm, r.lakeAvgCm, r.trendCm),
        ('Siófok', 98.0, 101.0, -2.0),
      );
      expect(r.at, now.subtract(const Duration(hours: 2)).toUtc());
      expect(WaterReading.of(row(water('b', now, type: 'disk'))), isNull);
      final noLake = WaterReading.of(row(water('c', now, lake: null)))!;
      expect(noLake.lakeAvgCm, isNull);
    });

    test('a week ending today, each day its last reading, gaps stay', () {
      WaterReading at(DateTime t, double level) =>
          WaterReading.of(row(water('$t', t, level: level)))!;
      final days = waterDays([
        at(DateTime(2026, 10, 12, 12), 90), // too old
        at(DateTime(2026, 10, 14, 10), 101),
        at(DateTime(2026, 10, 14, 22), 102), // later the same day wins
        at(DateTime(2026, 10, 16, 10), 100),
        at(DateTime(2026, 10, 20, 20), 98),
      ], now);
      expect(days, hasLength(7));
      expect(days.first.day, DateTime(2026, 10, 14));
      expect(days.last.day, DateTime(2026, 10, 20));
      expect(
        [for (final d in days) d.levelCm],
        [102.0, null, 100.0, null, null, null, 98.0],
      );
    });

    test('chart scale: even, at least 8 cm, room for a middle line', () {
      expect(waterScale([98, 101, 104]), (lo: 98.0, hi: 106.0));
      expect(waterScale([100, 100.5]), (lo: 98.0, hi: 106.0));
      expect(waterScale([]), (lo: 0.0, hi: 8.0));
    });

    test('signed centimetres', () {
      expect(signedCm(-2.4), '−2');
      expect(signedCm(1.6), '+2');
      expect(signedCm(0.2), '0');
    });
  });

  group('database', () {
    test('cards upsert by id; filtered by type, origin and time', () async {
      final db = memoryDb();
      addTearDown(db.close);
      await db.putCard(water('a', now.subtract(const Duration(days: 9))));
      await db.putCard(water('b', now.subtract(const Duration(days: 1))));
      await db.putCard(water('c', now, origin: 'agent'));
      await db.putCard(water('d', now));
      await db.putCard(water('d', now, level: 97)); // the same card again
      final rows = await db
          .watchCards(type: 'water', origin: 'script', since: waterSince(now))
          .first;
      expect([for (final r in rows) r.id], ['b', 'd']);
      expect(rows.last.payload['level_cm'], 97);
    });
  });

  group('Dashboard (12)', () {
    Future<TestEnv> openDashboard(
      WidgetTester t, {
      List<AgentCard> cards = const [],
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async => env.server.json('GET', '/api/v1/cards', {
          'data': [for (final c in cards.reversed) json(c)],
        }),
      );
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('the latest reading, its change and the week', (t) async {
      final today = DateTime.now();
      final env = await openDashboard(
        t,
        cards: [
          water('y', today.subtract(const Duration(days: 1)), level: 100),
          water('t', today, level: 98.4, lake: 101.2, trend: -2),
        ],
      );
      final call = env.server.requests.lastWhere(
        (r) => r.uri.path == '/api/v1/cards',
      );
      expect(call.uri.queryParameters['type'], 'water');
      expect(call.uri.queryParameters['since'], isNotNull);

      expect(find.text('Lake Balaton water level'), findsOneWidget);
      expect(find.text('98 cm', findRichText: true), findsOneWidget);
      expect(find.text('101 cm', findRichText: true), findsOneWidget);
      expect(find.text('Siófok'), findsNWidgets(2)); // label + legend
      expect(find.text('Lake average'), findsNWidgets(2));
      expect(
        t.widget<Text>(find.byKey(const Key('water.trend'))).data,
        '−2 cm',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('water.time'))).data,
        'today ${DateFormat('HH:mm').format(today)}',
      );
      expect(find.byType(WaterChart), findsOneWidget);
      expect(find.byKey(const Key('dashboard.updated')), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget); // no socket in widget tests
    });

    testWidgets('the agent\'s own water cards stay out', (t) async {
      await openDashboard(
        t,
        cards: [water('a', DateTime.now(), origin: 'agent')],
      );
      expect(find.textContaining('No water reading yet'), findsOneWidget);
    });

    testWidgets('empty, and a failed reload says why', (t) async {
      final env = await openDashboard(t);
      expect(find.textContaining('No water reading yet'), findsOneWidget);
      env.server.json(
        'GET',
        '/api/v1/cards',
        FakeServer.detail('boom', 'boom'),
        status: 500,
      );
      await t.drag(find.byType(ListView).last, const Offset(0, 400));
      await t.pumpAndSettle();
      expect(find.textContaining("Couldn't reload"), findsOneWidget);
    });

    testWidgets('a big text size does not overflow the card', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openDashboard(
        t,
        cards: [water('t', DateTime.now(), station: 'Balatonfüred')],
      );
      expect(t.takeException(), isNull);
      expect(find.text('Lake Balaton water level'), findsOneWidget);
    });
  });
}
