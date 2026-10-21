import 'package:delve/ui/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

/// The system view with llama-server stopped from Delve ([queued] waiting).
Map<String, Object?> stopped({int queued = 2}) {
  final s = FakeServer.sample('system');
  return {
    ...s,
    'llama': {
      ...s['llama']! as Map<String, Object?>,
      'status': 'stopped',
      'intent': 'stopped',
      'since': '2026-10-20T22:34:28+00:00',
      'model': null,
      'quant': null,
      'ctx': null,
      'slots_busy': 0,
    },
    'queue': {'active': 0, 'queued': queued},
  };
}

Map<String, Object?> withoutHelper() => {
  ...FakeServer.sample('system'),
  'helper': {'ok': false, 'error': 'helper_unavailable'},
  'gpus': null,
};

void main() {
  group('formatting', () {
    test('uptime', () {
      expect(uptimeText(const Duration(seconds: 30)), '< 1 min');
      expect(uptimeText(const Duration(minutes: 12)), '12 min');
      expect(uptimeText(const Duration(hours: 5)), '5 h');
      expect(uptimeText(const Duration(hours: 5, minutes: 12)), '5 h 12 min');
      expect(
        uptimeText(const Duration(days: 3, hours: 20, minutes: 5)),
        '3 d 20 h',
      );
      expect(uptimeText(const Duration(days: 2)), '2 d');
    });

    test('age, memory and GPU names', () {
      expect(ageText(const Duration(seconds: 5)), '5 s');
      expect(ageText(const Duration(seconds: -2)), '0 s');
      expect(ageText(const Duration(minutes: 3)), '3 min');
      expect(ageText(const Duration(hours: 2)), '2 h');
      expect(gbText(11381), '11.1');
      expect(gbText(12282, total: true), '12');
      expect(gbText(8192, total: true), '8');
      expect(gbText(15), '0.0');
      expect(gbText(6693, total: true), '6.5');
      expect(gpuName('NVIDIA GeForce RTX 4070 SUPER'), 'RTX 4070 SUPER');
      expect(gpuName('NVIDIA RTX A2000'), 'RTX A2000');
      expect(gpuName('Tesla T4'), 'Tesla T4');
    });
  });

  group('System (13a–c)', () {
    Future<TestEnv> openSystem(
      WidgetTester t, {
      Map<String, Object?>? system,
      int? status,
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async {
          if (system != null || status != null) {
            env.server.json(
              'GET',
              '/api/v1/system',
              system ?? FakeServer.detail('boom', 'boom'),
              status: status ?? 200,
            );
          }
        },
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('System'));
      await t.pumpAndSettle();
      return env;
    }

    String text(WidgetTester t, Key key) {
      final w = t.widget(find.byKey(key));
      return switch (w) {
        Text(:final data?) => data,
        _ => throw StateError('not a Text: $w'),
      };
    }

    testWidgets('running: Hermes degraded by the disk, the model, the GPUs', (
      t,
    ) async {
      final env = await openSystem(t);
      expect(env.server.calls, contains('GET /api/v1/system'));

      expect(find.text('Hermes Agent'), findsOneWidget);
      expect(find.text('degraded'), findsOneWidget);
      expect(find.text('Disk'), findsOneWidget);
      expect(find.text('96% used'), findsOneWidget);
      expect(find.text('v0.22.2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('system.queue')),
          matching: find.text('1 run active · 1 queued'),
        ),
        findsOneWidget,
      );

      expect(find.text('llama-server'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('Qwen3.8-27B · IQ4_XS'), findsOneWidget);
      expect(find.text('65,536 tok'), findsOneWidget);
      expect(find.text('1 / 1 busy'), findsOneWidget);
      expect(find.text('21.4 tok/s'), findsOneWidget);
      expect(find.byKey(const Key('system.waiting')), findsNothing);

      await t.scrollUntilVisible(find.text('RTX 3050'), 200);
      expect(find.text('GPUs'), findsOneWidget);
      expect(find.text('RTX 4070 SUPER'), findsOneWidget);
      expect(find.text('51 °C · 40 W · 11.1 / 12 GB'), findsOneWidget);
      expect(find.text('49 °C · 15 W · 6.5 / 8 GB'), findsOneWidget);
      expect(find.byKey(const Key('system.helper')), findsNothing);
    });

    testWidgets('stop: the dialog says what happens, then stopped', (t) async {
      final env = await openSystem(t);
      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(200, stopped()),
      );

      await t.tap(find.byKey(const Key('system.llama.stop')));
      await t.pumpAndSettle();
      expect(find.text('Stop llama-server?'), findsOneWidget);
      expect(
        text(t, const Key('system.stop.body')),
        'The active run will be stopped. 1 queued message waits until you '
        'start it again. Hermes keeps running, and you can start '
        'llama-server again from here.',
      );

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(env.server.calls, isNot(contains('POST /api/v1/system/llama')));

      await t.tap(find.byKey(const Key('system.llama.stop')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('system.stop.confirm')));
      await t.pumpAndSettle();
      final post = env.server.requests.lastWhere(
        (r) => r.uri.path == '/api/v1/system/llama',
      );
      expect(post.method, 'POST');
      expect(post.data, {'action': 'stop', 'force': true});

      expect(find.text('stopped'), findsOneWidget);
      expect(find.byKey(const Key('system.llama.start')), findsOneWidget);
      expect(find.byKey(const Key('system.llama.stop')), findsNothing);
      expect(
        find.text('2 messages wait until llama-server is back.'),
        findsOneWidget,
      );
      expect(find.text('Qwen3.8-27B · IQ4_XS'), findsNothing);
      expect(find.text('0 / 1'), findsOneWidget);
      expect(find.text('21.4 tok/s'), findsNothing);
    });

    testWidgets('stop without a run active does not force', (t) async {
      final idle = {
        ...FakeServer.sample('system'),
        'queue': {'active': 0, 'queued': 0},
      };
      final env = await openSystem(t, system: idle);
      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(200, stopped(queued: 0)),
      );
      await t.tap(find.byKey(const Key('system.llama.stop')));
      await t.pumpAndSettle();
      expect(
        text(t, const Key('system.stop.body')),
        'Hermes keeps running, and you can start llama-server again from '
        'here.',
      );
      await t.tap(find.byKey(const Key('system.stop.confirm')));
      await t.pumpAndSettle();
      final post = env.server.requests.lastWhere(
        (r) => r.uri.path == '/api/v1/system/llama',
      );
      expect(post.data, {'action': 'stop'});
      expect(
        find.text('Messages you send wait until llama-server is back.'),
        findsOneWidget,
      );
    });

    testWidgets('a run that started meanwhile: 409, say so and reload', (
      t,
    ) async {
      final idle = {
        ...FakeServer.sample('system'),
        'queue': {'active': 0, 'queued': 0},
      };
      final env = await openSystem(t, system: idle);
      env.server.json(
        'POST',
        '/api/v1/system/llama',
        FakeServer.detail('run_active', 'a run is active'),
        status: 409,
      );
      final before = env.server.calls.where((c) => c == 'GET /api/v1/system');
      final loads = before.length;
      await t.tap(find.byKey(const Key('system.llama.stop')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('system.stop.confirm')));
      await t.pumpAndSettle();
      expect(
        find.text('A run just started. Check the queue and try again.'),
        findsOneWidget,
      );
      expect(
        env.server.calls.where((c) => c == 'GET /api/v1/system').length,
        loads + 1,
      );
      expect(find.byKey(const Key('system.llama.stop')), findsOneWidget);
    });

    testWidgets('start from stopped, and a failed start says why', (t) async {
      final env = await openSystem(t, system: stopped());
      env.server.json(
        'POST',
        '/api/v1/system/llama',
        FakeServer.detail('helper_failed', 'Failed to connect to bus'),
        status: 502,
      );
      await t.tap(find.byKey(const Key('system.llama.start')));
      await t.pumpAndSettle();
      expect(find.text('Stop llama-server?'), findsNothing); // no dialog
      expect(
        find.textContaining("Couldn't start llama-server: Failed to connect"),
        findsOneWidget,
      );

      final loading = {
        ...FakeServer.sample('system'),
        'llama': {
          ...FakeServer.sample('system')['llama']! as Map<String, Object?>,
          'status': 'loading',
          'intent': 'starting',
          'model': null,
        },
      };
      env.server.json('POST', '/api/v1/system/llama', loading);
      await t.tap(find.byKey(const Key('system.llama.start')));
      await t.pumpAndSettle();
      final post = env.server.requests.lastWhere(
        (r) => r.uri.path == '/api/v1/system/llama',
      );
      expect(post.data, {'action': 'start'});
      expect(find.text('loading'), findsOneWidget);
      expect(
        find.text('Waiting messages start once the model is loaded.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('system.llama.stop')), findsOneWidget);
    });

    testWidgets('without the helper: say so, no GPUs, no stop', (t) async {
      await openSystem(t, system: withoutHelper());
      expect(find.byKey(const Key('system.helper')), findsOneWidget);
      expect(
        find.textContaining("can't reach its system helper"),
        findsOneWidget,
      );
      expect(find.text('GPUs'), findsNothing);
      final stop = t.widget<OutlinedButton>(
        find.byKey(const Key('system.llama.stop')),
      );
      expect(stop.onPressed, isNull);
    });

    testWidgets('a failed load says why and retries', (t) async {
      final env = await openSystem(t, status: 500);
      expect(
        find.textContaining("Couldn't load the system view"),
        findsOneWidget,
      );
      env.server.json('GET', '/api/v1/system', FakeServer.system);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Hermes Agent'), findsOneWidget);
    });

    testWidgets('a big text size does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openSystem(t);
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(find.text('RTX 3050'), 200);
      expect(t.takeException(), isNull);
    });
  });

  group('Dashboard System card (12)', () {
    Future<TestEnv> openDashboard(
      WidgetTester t, {
      Map<String, Object?>? system,
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async {
          if (system != null) env.server.json('GET', '/api/v1/system', system);
        },
      );
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('Hermes, llama-server, GPUs without power, stop', (t) async {
      final env = await openDashboard(t);
      final card = find.byKey(const Key('dashboard.system'));
      await t.scrollUntilVisible(card, 200);
      Finder inCard(Finder f) => find.descendant(of: card, matching: f);
      expect(inCard(find.text('System')), findsOneWidget);
      expect(inCard(find.text('2 GPUs')), findsOneWidget);
      expect(inCard(find.text('degraded')), findsOneWidget);
      expect(inCard(find.text('v0.22.2')), findsOneWidget);
      expect(inCard(find.text('running')), findsOneWidget);
      expect(inCard(find.text('Qwen3.8-27B')), findsOneWidget);
      expect(inCard(find.text('51 °C · 11.1 / 12 GB')), findsOneWidget);

      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(200, stopped()),
      );
      await t.scrollUntilVisible(
        inCard(find.byKey(const Key('system.llama.stop'))),
        200,
      );
      await t.tap(inCard(find.byKey(const Key('system.llama.stop'))));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('system.stop.confirm')));
      await t.pumpAndSettle();
      expect(inCard(find.text('stopped')), findsOneWidget);
      expect(
        inCard(find.text('2 messages wait until llama-server is back.')),
        findsOneWidget,
      );
    });

    testWidgets('no system view yet: no card, the rest still loads', (t) async {
      final env = await pumpDelve(
        t,
        before: (env) async => env.server.json(
          'GET',
          '/api/v1/system',
          FakeServer.detail('boom', 'boom'),
          status: 500,
        ),
      );
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(
        find.textContaining("Couldn't load the system view"),
        findsOneWidget,
      );
      expect(
        find.textContaining("Couldn't reload"),
        findsNothing,
      ); // no snackbar
      expect(env.server.calls, contains('GET /api/v1/cards'));
    });
  });
}
