import 'package:delve/api/models/models.dart';
import 'package:delve/app/cron_preset.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/ui/schedule_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

final l = lookupAppLocalizations(const Locale('en'));

/// A schedule from `samples.json` with [changes] applied.
Map<String, Object?> sched(
  String shape, [
  Map<String, Object?> changes = const {},
]) => {...FakeServer.sample(shape), ...changes};

Schedule model(String shape, [Map<String, Object?> changes = const {}]) =>
    Schedule.fromJson(sched(shape, changes));

void main() {
  group('cron presets', () {
    test('daily, weekly, anything else', () {
      final d = CronPreset.parse('52 8,12,20 * * *') as DailyCron;
      expect([for (final t in d.times) t.text], ['08:52', '12:52', '20:52']);
      expect(d.toCron(), '52 8,12,20 * * *');

      final w = CronPreset.parse('0 18 * * 0') as WeeklyCron;
      expect(w.days, {7});
      expect(w.time.text, '18:00');
      expect(w.toCron(), '0 18 * * 0');
      final wd = CronPreset.parse('15 7 * * 1-5') as WeeklyCron;
      expect(wd.sortedDays, [1, 2, 3, 4, 5]);
      expect(wd.toCron(), '15 7 * * 1,2,3,4,5');

      for (final c in [
        '*/15 * * * *',
        '0 9 1 * *',
        '0 8,9 * * 1',
        '00 9 * * *',
        '0 9 * *',
      ]) {
        expect(CronPreset.parse(c), isA<CustomCron>(), reason: c);
      }
      expect(const CustomCron(' 0  9 1 * * ').toCron(), '0 9 1 * *');
      expect(const CustomCron('0 9 1 *').toCron(), isNull);
    });

    test('daily times must share their minute; empty sets are no cron', () {
      const mixed = DailyCron([ClockTime(8, 30), ClockTime(12, 15)]);
      expect((mixed.sharesMinute, mixed.toCron()), (false, null));
      expect(const DailyCron([]).toCron(), isNull);
      expect(const WeeklyCron({}, ClockTime(9, 0)).toCron(), isNull);
    });

    test('in words', () {
      String text(String cron) => presetText(l, CronPreset.parse(cron), cron);
      expect(text('52 8,12,20 * * *'), 'Every day at 08:52, 12:52 and 20:52');
      expect(text('30 7 * * *'), 'Every day at 07:30');
      expect(text('0 18 * * 0'), 'Sundays at 18:00');
      expect(text('0 9 * * 1-5'), 'Weekdays at 09:00');
      expect(text('0 10 * * 6,0'), 'Weekends at 10:00');
      expect(text('15 7 * * 1,3,5'), 'Mon, Wed and Fri at 07:15');
      expect(text('0 9 * * 0-6'), 'Every day at 09:00');
      expect(text('*/15 * * * *'), '*/15 * * * *'); // the server's reading
    });

    test('next and last run', () {
      final now = DateTime(2026, 10, 21, 23, 41);
      final s = model('schedule_prompt', {
        'enabled': true,
        'next_run_at': DateTime(2026, 10, 22, 8, 52).toUtc().toIso8601String(),
        'last_run_at': DateTime(2026, 10, 21, 20, 52).toUtc().toIso8601String(),
        'last_status': 'completed',
      });
      expect(nextRunText(l, s, now), 'Next run in 9 h · tomorrow 08:52');
      expect(lastRunText(l, s, now), 'Last run 20:52 · OK');
      final far = s.copyWith(nextRunAt: DateTime(2026, 10, 25, 18));
      expect(nextRunText(l, far, now), 'Next run Sun 18:00');
      expect(
        nextRunText(l, s.copyWith(enabled: false, nextRunAt: null), now),
        'Paused',
      );
      expect(
        lastRunText(l, s.copyWith(lastStatus: 'failed'), now),
        'Last run 20:52 · Failed',
      );
      expect(
        lastRunText(l, s.copyWith(lastStatus: 'waiting_for_approval'), now),
        'Last run 20:52 · Running',
      );
      expect(
        lastRunText(l, s.copyWith(lastRunAt: null, lastStatus: null), now),
        'Not run yet',
      );
    });
  });

  group('Schedules (14a)', () {
    final briefId = FakeServer.sample('schedule')['id']! as String;
    final promptId = FakeServer.sample('schedule_prompt')['id']! as String;

    Future<TestEnv> openSchedules(WidgetTester t) async {
      final env = await pumpDelve(t);
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Schedules'));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('the brief first, timing in words, next and last run', (
      t,
    ) async {
      final env = await openSchedules(t);
      expect(env.server.calls, contains('GET /api/v1/schedules'));
      expect(find.text('Morning brief'), findsOneWidget);
      expect(find.text('Arch news digest'), findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(Key('schedule.$briefId.timing'))).data,
        'Every day at 07:30',
      );
      expect(
        t.widget<Text>(find.byKey(Key('schedule.$promptId.timing'))).data,
        'Every day at 08:52, 12:52 and 20:52',
      );
      expect(
        t.widget<Text>(find.byKey(Key('schedule.$briefId.last'))).data,
        startsWith('Last run '),
      );
      expect(find.text('Run now'), findsNWidgets(2));
      expect(find.byKey(const Key('schedules.empty')), findsNothing);
      expect(
        t.getTopLeft(find.text('Morning brief')).dy,
        lessThan(t.getTopLeft(find.text('Arch news digest')).dy),
      );
    });

    testWidgets('the switch turns a schedule off on the server', (t) async {
      final env = await openSchedules(t);
      env.server.on(
        'PATCH',
        '/api/v1/schedules/$promptId',
        (_) => FakeReply(
          200,
          sched('schedule_prompt', {'enabled': false, 'next_run_at': null}),
        ),
      );
      await t.tap(find.byKey(Key('schedule.$promptId.switch')));
      await t.pumpAndSettle();
      final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'enabled': false});
      expect(
        t.widget<Text>(find.byKey(Key('schedule.$promptId.next'))).data,
        'Paused',
      );
      expect(
        t.widget<Switch>(find.byKey(Key('schedule.$promptId.switch'))).value,
        isFalse,
      );
    });

    testWidgets('a failed switch goes back and says why', (t) async {
      final env = await openSchedules(t);
      env.server.json(
        'PATCH',
        '/api/v1/schedules/$promptId',
        FakeServer.detail('boom', 'boom'),
        status: 500,
      );
      await t.tap(find.byKey(Key('schedule.$promptId.switch')));
      await t.pumpAndSettle();
      expect(find.textContaining("Couldn't save"), findsOneWidget);
      expect(
        t.widget<Switch>(find.byKey(Key('schedule.$promptId.switch'))).value,
        isTrue,
      );
    });

    testWidgets('run now: the brief is written, a prompt queued', (t) async {
      final env = await openSchedules(t);
      env.server.on(
        'POST',
        '/api/v1/schedules/$briefId/run',
        (_) => FakeReply(200, {
          'schedule': sched('schedule'),
          'run_id': null,
          'card_id': '3e69fb78e25c4d45bfdbe18b3e3da170',
        }),
      );
      env.server.on(
        'POST',
        '/api/v1/schedules/$promptId/run',
        (_) => FakeReply(200, {
          'schedule': sched('schedule_prompt', {'last_status': 'queued'}),
          'run_id': 'q_1',
          'card_id': null,
        }),
      );
      await t.tap(find.byKey(Key('schedule.$briefId.run')));
      await t.pumpAndSettle();
      expect(find.textContaining('Morning brief written'), findsOneWidget);
      ScaffoldMessenger.of(
        t.element(find.byType(Scaffold).last),
      ).clearSnackBars();
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key('schedule.$promptId.run')));
      await t.pumpAndSettle();
      expect(find.textContaining('Queued — the answer'), findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(Key('schedule.$promptId.last'))).data,
        endsWith('· Queued'),
      );
    });

    testWidgets('a new schedule: daily 09:00 in a new chat', (t) async {
      final env = await openSchedules(t);
      Object? body;
      env.server.on('POST', '/api/v1/schedules', (r) {
        body = r.data;
        return FakeReply(
          201,
          sched('schedule_prompt', {
            'id': '0a1b2c3d-0000-4000-8000-000000000001',
            'name': 'Uptime',
            'cron': '0 9 * * *',
            'conversation_mode': 'new',
            'conversation_id': null,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }),
        );
      });
      await t.tap(find.byKey(const Key('schedules.new')));
      await t.pumpAndSettle();
      expect(find.text('New schedule'), findsWidgets);
      expect(
        t.widget<Text>(find.byKey(const Key('schedule.summary'))).data,
        'Every day at 09:00',
      );
      expect(
        t.widget<Text>(find.byKey(const Key('schedule.cronText'))).data,
        '0 9 * * *',
      );

      await t.tap(find.byKey(const Key('schedule.save')));
      await t.pumpAndSettle();
      expect(
        find.text('Give it a name (at most 64 characters).'),
        findsOneWidget,
      );
      expect(find.text('Write a prompt.'), findsOneWidget);
      expect(body, isNull);

      await t.enterText(find.byKey(const Key('schedule.name')), 'Uptime');
      await t.enterText(find.byKey(const Key('schedule.prompt')), 'uptime?');
      await t.tap(find.byKey(const Key('schedule.save')));
      await t.pumpAndSettle();
      expect(body, {
        'name': 'Uptime',
        'cron': '0 9 * * *',
        'prompt': 'uptime?',
        'conversation_mode': 'new',
        'thinking': false,
        'enabled': true,
      });
      expect(find.text('Uptime'), findsOneWidget); // back on the list
      expect(find.byKey(const Key('schedule.save')), findsNothing);
    });

    testWidgets('the server\'s reason lands under the timing', (t) async {
      final env = await openSchedules(t);
      env.server.json(
        'PATCH',
        '/api/v1/schedules/$promptId',
        FakeServer.detail('too_frequent', 'x'),
        status: 422,
      );
      await t.tap(find.text('Arch news digest'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cron'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('schedule.cron')), '*/30 * * * *');
      await t.pump();
      await t.tap(find.byKey(const Key('schedule.save')));
      await t.pumpAndSettle();
      final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'cron': '*/30 * * * *'});
      expect(
        t.widget<Text>(find.byKey(const Key('schedule.timingError'))).data,
        'A schedule may run at most every 10 minutes.',
      );
    });

    testWidgets('edit: weekly on weekdays, the same chat', (t) async {
      final env = await openSchedules(t);
      env.server.on(
        'PATCH',
        '/api/v1/schedules/$promptId',
        (r) => FakeReply(
          200,
          sched('schedule_prompt', {'cron': '52 8 * * 1,2,3,4,5'}),
        ),
      );
      await t.tap(find.text('Arch news digest'));
      await t.pumpAndSettle();
      expect(find.text('Edit schedule'), findsOneWidget);
      expect(find.byKey(const Key('schedule.time.12:52')), findsOneWidget);
      await t.tap(find.text('Weekly'));
      await t.pumpAndSettle();
      expect(
        t.widget<Text>(find.byKey(const Key('schedule.summary'))).data,
        'Weekdays at 08:52',
      );
      await t.tap(find.byKey(const Key('schedule.save')));
      await t.pumpAndSettle();
      final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'cron': '52 8 * * 1,2,3,4,5'});
      expect(
        t.widget<Text>(find.byKey(Key('schedule.$promptId.timing'))).data,
        'Weekdays at 08:52',
      );
    });

    testWidgets('the brief only takes its timing', (t) async {
      final env = await openSchedules(t);
      env.server.on(
        'PATCH',
        '/api/v1/schedules/$briefId',
        (r) => FakeReply(200, sched('schedule', {'cron': '0 7 * * *'})),
      );
      await t.tap(find.text('Morning brief'));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byKey(const Key('schedule.name'))).enabled,
        isFalse,
      );
      expect(find.byKey(const Key('schedule.prompt')), findsNothing);
      expect(find.byKey(const Key('schedule.thinking')), findsNothing);
      expect(find.byKey(const Key('schedule.delete')), findsNothing);
      expect(find.textContaining('without the model'), findsOneWidget);
      await t.tap(find.text('Cron'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('schedule.cron')), '0 7 * * *');
      await t.tap(find.byKey(const Key('schedule.save')));
      await t.pumpAndSettle();
      final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'cron': '0 7 * * *'});
    });

    testWidgets('delete asks first', (t) async {
      final env = await openSchedules(t);
      env.server.on(
        'DELETE',
        '/api/v1/schedules/$promptId',
        (_) => const FakeReply(204),
      );
      await t.tap(find.text('Arch news digest'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const Key('schedule.delete')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(find.byKey(const Key('schedule.delete')));
      await t.pumpAndSettle();
      expect(find.text('Delete “Arch news digest”?'), findsOneWidget);
      await t.tap(find.byKey(const Key('schedule.delete.confirm')));
      await t.pumpAndSettle();
      expect(env.server.calls, contains('DELETE /api/v1/schedules/$promptId'));
      expect(find.text('Arch news digest'), findsNothing);
      expect(find.byKey(const Key('schedules.empty')), findsOneWidget);
    });

    testWidgets('a big text size does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openSchedules(t);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Arch news digest'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });
}
