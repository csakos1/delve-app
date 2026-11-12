import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/push/background.dart';
import 'package:delve/push/notification_spec.dart';
import 'package:delve/push/push_message.dart';
import 'package:delve/theme/delve_colors.dart';
import 'package:delve/ui/format.dart';
import 'package:delve/ui/screens/settings_screen.dart';
import 'package:delve/ui/widgets/status_ui.dart';
import 'package:delve/ui/widgets/system_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'push_test.dart' show FakeNotifications;
import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/layout.dart';

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

/// The system view with its llama part changed ([queue]: the run queue).
Map<String, Object?> withLlama(
  Map<String, Object?> llama, {
  Map<String, Object?>? base,
  Map<String, int>? queue,
}) {
  final s = base ?? FakeServer.sample('system');
  return {
    ...s,
    'llama': {...s['llama']! as Map<String, Object?>, ...llama},
    'queue': ?queue,
  };
}

/// Nothing runs and nothing waits.
Map<String, Object?> idle() =>
    withLlama(const {}, queue: const {'active': 0, 'queued': 0});

/// The sample's presets with [name] as the one the desktop points to.
List<Object?> presetsWith(String name) {
  final llama = FakeServer.sample('system')['llama']! as Map<String, Object?>;
  return [
    for (final m
        in (llama['models']! as List<Object?>).cast<Map<String, Object?>>())
      {...m, 'active': m['name'] == name},
  ];
}

const q6k = 'qwen38-27b-q6k';

/// A switch to the Q6 preset that the desktop started 14 s ago.
Map<String, Object?> switching({int queued = 0}) => withLlama(
  {
    'status': 'loading',
    'intent': 'starting',
    'model': null,
    'quant': null,
    'ctx': null,
    'slots_busy': null,
    'preset': q6k,
    'models': presetsWith(q6k),
    'switch': {
      'state': 'switching',
      'from': 'qwen38-27b-iq4xs',
      'to': q6k,
      'by': 'Pixel 9 Pro XL',
      'at': DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 14))
          .toIso8601String(),
      'error': null,
      'elapsed_s': null,
    },
  },
  queue: {'active': 0, 'queued': queued},
);

/// A switch to the Reasoner preset that failed ([state]: failed | down).
Map<String, Object?> failedSwitch({
  String state = 'failed',
  String error = 'exited',
  int elapsed = 34,
}) => withLlama({
  'switch': {
    'state': state,
    'from': 'qwen38-27b-iq4xs',
    'to': 'reasoner-32b',
    'by': 'Pixel 9 Pro XL',
    'at': '2026-10-19T21:37:00+00:00',
    'error': error,
    'elapsed_s': elapsed,
  },
}, base: state == 'down' ? stopped(queued: 0) : idle());

/// A few short frames: for views that never settle (the switching state
/// turns its icon and runs its bar).
Future<void> frames(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

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
      // states are coloured words, not chips
      expect(find.byType(StatusChip), findsNothing);
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

      // values, notes and chips end on the card's right edge
      Finder cardOf(Finder f) =>
          find.ancestor(of: f, matching: find.byType(SurfaceCard)).first;
      for (final f in [
        find.textContaining('checked '),
        find.byKey(const Key('system.hermes.status')),
        find.text('96% used'),
        find.text('v0.22.2'),
        find.text('1 run active · 1 queued'),
        find.textContaining('since '),
        find.text('1 / 1 busy'),
        find.text('21.4 tok/s'),
      ]) {
        expectOnRightEdge(t, f, cardOf(f));
      }

      await t.scrollUntilVisible(find.text('RTX 3050'), 200);
      expect(find.text('GPUs'), findsOneWidget);
      expect(find.text('RTX 4070 SUPER'), findsOneWidget);
      expect(find.text('51 °C · 40 W · 11.1 / 12 GB'), findsOneWidget);
      expect(find.text('49 °C · 15 W · 6.5 / 8 GB'), findsOneWidget);
      for (final f in [
        find.textContaining('nvidia-smi'),
        find.text('51 °C · 40 W · 11.1 / 12 GB'),
        find.text('49 °C · 15 W · 6.5 / 8 GB'),
      ]) {
        expectOnRightEdge(t, f, cardOf(f));
      }
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
      // the Model row now names the preset that Start loads
      expect(find.text('Qwen3.8-27B · IQ4_XS'), findsOneWidget);
      expect(find.text('loads on Start'), findsOneWidget);
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
    Map<String, Object?> lastPost(TestEnv env) =>
        env.server.requests
                .lastWhere((r) => r.uri.path == '/api/v1/system/llama')
                .data
            as Map<String, Object?>;

    Future<void> openPicker(WidgetTester t) async {
      await t.tap(find.byKey(const Key('system.model')));
      await t.pumpAndSettle();
    }

    testWidgets('25c: the Model row opens the presets', (t) async {
      final env = await openSystem(t, system: idle());
      expect(text(t, const Key('system.model.value')), 'Qwen3.8-27B · IQ4_XS');
      expect(find.byKey(const Key('system.model.onStart')), findsNothing);

      await openPicker(t);
      expect(find.text('Local models'), findsOneWidget);
      expect(
        text(t, const Key('model.picker.subtitle')),
        'One model is loaded at a time.',
      );
      // the loaded one is checked; name and quantization stay together
      expect(
        find.byKey(const Key('model.row.qwen38-27b-iq4xs.check')),
        findsOneWidget,
      );
      expect(find.text('Qwen3.8-27B · Q6_K'), findsOneWidget);
      expect(find.text('65,536 tok · 22.1 GB'), findsOneWidget);
      expect(find.text('Q6 since the RTX 3060'), findsOneWidget);
      // two markers per row: image input, thinking
      expect(find.text('Images'), findsNWidgets(4));
      expect(find.text('Text only'), findsNWidgets(2));
      expect(find.text('Thinking'), findsNWidgets(5));
      expect(find.text('Always thinks'), findsOneWidget);
      // what cannot be loaded says why, and comes last
      expect(find.text('32,768 tok · 9.7 GB'), findsOneWidget);
      expect(
        find.text('Needs 65,536 tok of context for the agent'),
        findsOneWidget,
      );
      expect(find.text('Model file not found'), findsOneWidget);
      double top(String name) =>
          t.getTopLeft(find.byKey(Key('model.row.$name'))).dy;
      expect(top('qwen38-9b'), greaterThan(top('reasoner-32b')));
      expect(top('test-broken'), greaterThan(top('qwen38-9b')));
      expect(t.takeException(), isNull);

      await t.tap(find.byKey(const Key('model.row.qwen38-9b')));
      await t.pumpAndSettle();
      expect(find.text('Local models'), findsOneWidget);

      // the loaded one only closes the sheet
      await t.tap(find.byKey(const Key('model.row.qwen38-27b-iq4xs')));
      await t.pumpAndSettle();
      expect(find.text('Local models'), findsNothing);
      expect(find.textContaining('Switch to'), findsNothing);
      expect(env.server.calls, isNot(contains('POST /api/v1/system/llama')));
    });

    testWidgets('25d1, 25e1: confirm, then the new model loads', (t) async {
      final env = await openSystem(t, system: idle());
      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(200, switching()),
      );
      await openPicker(t);
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      expect(find.text('Local models'), findsNothing);
      expect(find.text('Switch to Qwen3.8-27B · Q6_K?'), findsOneWidget);
      expect(
        text(t, const Key('model.confirm.facts')),
        'qwen38-27b-q6k · 65,536 tok · 22.1 GB',
      );
      expect(find.byKey(const Key('model.confirm.run')), findsNothing);
      expect(find.byKey(const Key('model.confirm.queued')), findsNothing);
      expect(find.text('Stop run and switch'), findsNothing);

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(env.server.calls, isNot(contains('POST /api/v1/system/llama')));

      await openPicker(t);
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('model.confirm.ok')));
      await frames(t);
      expect(lastPost(env), {'action': 'switch', 'model': q6k});

      expect(find.text('switching'), findsOneWidget);
      expect(
        text(t, const Key('system.switch.line')),
        'Loading Qwen3.8-27B · Q6_K…',
      );
      expect(
        text(t, const Key('system.switch.elapsed')),
        anyOf('0:14', '0:15', '0:16'),
      );
      expect(
        text(t, const Key('system.switch.starter')),
        startsWith('Started from Pixel 9 Pro XL · '),
      );
      // the row names what loads and cannot be opened; no stop meanwhile
      expect(text(t, const Key('system.model.value')), 'Qwen3.8-27B · Q6_K');
      expect(
        t
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(const Key('system.model')),
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNull,
      );
      expect(
        t
            .widget<OutlinedButton>(find.byKey(const Key('system.llama.stop')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('system.llama.start')), findsNothing);
      expect(find.text('65,536 tok'), findsNothing);
      expect(find.byKey(const Key('system.waiting')), findsNothing);
      expect(find.byKey(const Key('system.switch.queue')), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('25d2: an active run is stopped, queued messages wait', (
      t,
    ) async {
      final env = await openSystem(t);
      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(200, switching(queued: 1)),
      );
      await openPicker(t);
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('model.confirm.run')),
          matching: find.text('The active run will be stopped.'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('1 queued message runs on the new model.'),
        findsOneWidget,
      );
      expect(find.text('Stop run and switch'), findsOneWidget);
      await t.tap(find.byKey(const Key('model.confirm.ok')));
      await frames(t);
      expect(lastPost(env), {'action': 'switch', 'model': q6k, 'force': true});
      expect(
        find.descendant(
          of: find.byKey(const Key('system.switch.queue')),
          matching: find.text('1 message waits for the new model.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a run that started meanwhile: ask again, then force', (
      t,
    ) async {
      final env = await openSystem(t, system: idle());
      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (r) => (r.data as Map<String, Object?>)['force'] == true
            ? FakeReply(200, switching())
            : FakeReply(
                409,
                FakeServer.detail('run_active', 'a run is active'),
              ),
      );
      await openPicker(t);
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      expect(find.text('Stop run and switch'), findsNothing);
      await t.tap(find.byKey(const Key('model.confirm.ok')));
      await t.pumpAndSettle();
      expect(lastPost(env), {'action': 'switch', 'model': q6k});
      // the second dialog says what the first could not know
      expect(find.byKey(const Key('model.confirm.run')), findsOneWidget);
      expect(find.text('Stop run and switch'), findsOneWidget);
      await t.tap(find.byKey(const Key('model.confirm.ok')));
      await frames(t);
      expect(lastPost(env), {'action': 'switch', 'model': q6k, 'force': true});
      expect(find.text('switching'), findsOneWidget);
    });

    testWidgets('a preset that is gone: say so and reload', (t) async {
      final env = await openSystem(t, system: idle());
      env.server.json(
        'POST',
        '/api/v1/system/llama',
        FakeServer.detail('unknown_model', 'no model preset named x'),
        status: 404,
      );
      final loads = env.server.calls
          .where((c) => c == 'GET /api/v1/system')
          .length;
      await openPicker(t);
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('model.confirm.ok')));
      await t.pumpAndSettle();
      expect(
        find.text('That preset is no longer on the desktop.'),
        findsOneWidget,
      );
      expect(
        env.server.calls.where((c) => c == 'GET /api/v1/system').length,
        loads + 1,
      );
    });

    testWidgets('stopped: a pick only changes what Start loads', (t) async {
      final env = await openSystem(t, system: stopped(queued: 0));
      expect(find.byKey(const Key('system.model.onStart')), findsOneWidget);
      expect(text(t, const Key('system.model.value')), 'Qwen3.8-27B · IQ4_XS');
      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(
          200,
          withLlama({
            'preset': q6k,
            'models': presetsWith(q6k),
          }, base: stopped(queued: 0)),
        ),
      );
      await openPicker(t);
      expect(
        text(t, const Key('model.picker.subtitle')),
        'llama-server is stopped. Start loads the model you pick.',
      );
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      expect(find.textContaining('Switch to'), findsNothing); // no dialog
      expect(lastPost(env), {'action': 'switch', 'model': q6k});
      expect(text(t, const Key('system.model.value')), 'Qwen3.8-27B · Q6_K');
      expect(find.text('loads on Start'), findsOneWidget);
      expect(find.byKey(const Key('system.llama.start')), findsOneWidget);
    });

    testWidgets('25f1: a failed switch says why until it is dismissed', (
      t,
    ) async {
      final env = await openSystem(t, system: failedSwitch());
      expect(
        text(t, const Key('system.switch.failed')),
        "Couldn't load Reasoner-32B · Q4_K_M. "
        'Back on Qwen3.8-27B · IQ4_XS.',
      );
      expect(
        text(t, const Key('system.switch.why')),
        'llama-server exited after 0:34',
      );
      expect(
        find.text('journalctl --user -u llama-server -n 50'),
        findsOneWidget,
      );
      expect(find.text('running'), findsOneWidget);

      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await t.tap(find.byKey(const Key('system.switch.copy')));
      await t.pumpAndSettle();
      expect(copied, 'journalctl --user -u llama-server -n 50');
      expect(find.text('Copied'), findsOneWidget);

      env.server.on(
        'POST',
        '/api/v1/system/llama',
        (_) => FakeReply(200, idle()),
      );
      await t.tap(find.byKey(const Key('system.switch.dismiss')));
      await t.pumpAndSettle();
      expect(lastPost(env), {'action': 'dismiss'});
      expect(find.byKey(const Key('system.switch.failed')), findsNothing);
    });

    testWidgets('25f2: going back failed too - no dismiss, Start below', (
      t,
    ) async {
      await openSystem(
        t,
        system: failedSwitch(state: 'down', error: 'timeout', elapsed: 180),
      );
      expect(
        text(t, const Key('system.switch.failed')),
        "Couldn't load Reasoner-32B · Q4_K_M and couldn't go back to "
        'Qwen3.8-27B · IQ4_XS. llama-server is down.',
      );
      expect(text(t, const Key('system.switch.why')), 'Not ready after 3:00');
      expect(find.byKey(const Key('system.switch.dismiss')), findsNothing);
      expect(find.byKey(const Key('system.llama.start')), findsOneWidget);
      expect(find.text('loads on Start'), findsOneWidget);
    });

    testWidgets('an older helper lists no presets: a plain Model row', (
      t,
    ) async {
      await openSystem(
        t,
        system: withLlama(const {
          'preset': null,
          'vision': null,
          'thinking': null,
          'models': null,
        }),
      );
      expect(find.byKey(const Key('system.model')), findsNothing);
      final model = find.text('Qwen3.8-27B · IQ4_XS');
      expectOnRightEdge(
        t,
        model,
        find.ancestor(of: model, matching: find.byType(SurfaceCard)).first,
      );
    });

    testWidgets('the picker and the dialog at a big text size', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openSystem(t);
      await openPicker(t);
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const Key('model.row.$q6k')));
      await t.pumpAndSettle();
      expect(find.text('Stop run and switch'), findsOneWidget);
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
      expect(inCard(find.text('Qwen3.8-27B · IQ4_XS')), findsOneWidget);
      expect(inCard(find.byKey(const Key('system.model'))), findsOneWidget);
      expect(inCard(find.textContaining('since ')), findsOneWidget);
      expect(inCard(find.text('51 °C · 11.1 / 12 GB')), findsOneWidget);
      // the state is the last thing in its row, after the version or model
      for (final f in [
        find.text('2 GPUs'),
        find.text('degraded'),
        find.text('running'),
        find.text('51 °C · 11.1 / 12 GB'),
      ]) {
        expectOnRightEdge(t, inCard(f), card);
      }
      for (final (before, state) in [
        (find.text('v0.22.2'), 'degraded'),
        (find.textContaining('since '), 'running'),
      ]) {
        // right of it on the same line, or on a line below when the row wraps
        final b = t.getRect(inCard(before));
        final st = t.getRect(inCard(find.text(state)));
        expect(
          st.left >= b.right || st.top >= b.bottom,
          isTrue,
          reason: '$before before $state: $b, $st',
        );
      }
      // states are coloured words, not chips
      expect(inCard(find.byType(StatusChip)), findsNothing);
      expect(
        t.widget<Text>(inCard(find.text('degraded'))).style!.color,
        DelveColors.dark.warnFg,
      );
      expect(
        t.widget<Text>(inCard(find.text('running'))).style!.color,
        DelveColors.dark.okFg,
      );

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

    testWidgets('25e2: a switch in short, with who waits', (t) async {
      await pumpDelve(
        t,
        before: (env) async =>
            env.server.json('GET', '/api/v1/system', switching(queued: 2)),
      );
      await t.tap(find.text('Dashboard').last);
      await frames(t);
      final card = find.byKey(const Key('dashboard.system'));
      await t.scrollUntilVisible(
        find.byKey(const Key('dashboard.switch.queue')),
        200,
      );
      Finder inCard(Finder f) => find.descendant(of: card, matching: f);
      expect(inCard(find.text('switching')), findsOneWidget);
      expect(inCard(find.text('Loading Qwen3.8-27B · Q6_K…')), findsOneWidget);
      expect(find.byKey(const Key('system.switch.starter')), findsNothing);
      expect(
        inCard(find.text('2 messages wait for the new model.')),
        findsOneWidget,
      );
      expect(
        t
            .widget<OutlinedButton>(
              inCard(find.byKey(const Key('system.llama.stop'))),
            )
            .onPressed,
        isNull,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('a failed switch is one line that leads to System', (t) async {
      await openDashboard(t, system: failedSwitch());
      final line = find.byKey(const Key('dashboard.switch.failed'));
      await t.scrollUntilVisible(line, 200);
      expect(
        find.descendant(
          of: line,
          matching: find.text(
            "Couldn't load Reasoner-32B · Q4_K_M · back on IQ4_XS",
          ),
        ),
        findsOneWidget,
      );
      await t.tap(line);
      await t.pumpAndSettle();
      expect(find.text('Hermes Agent'), findsOneWidget);
      expect(find.byKey(const Key('system.switch.failed')), findsOneWidget);
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

  group('a failed switch is pushed', () {
    final l = lookupAppLocalizations(const Locale('en'));
    Map<String, Object?> data({
      String event = 'switch_failed',
      String back = 'Qwen3.8-27B · IQ4_XS',
    }) => {
      'kind': 'system',
      'event': event,
      'to': 'Reasoner-32B · Q4_K_M',
      'back': back,
      'at': '2026-11-12T21:02:00+00:00',
    };

    test('on the System channel; Open leads to System', () {
      final p = PushMessage.parse(data())! as ModelSwitchPush;
      expect((p.down, p.back), (false, 'Qwen3.8-27B · IQ4_XS'));
      final n = modelSwitchNotification(l, p);
      expect(n.channel, NotifyChannel.system);
      expect(
        (n.title, n.body),
        ("Couldn't load Reasoner-32B · Q4_K_M", 'Back on Qwen3.8-27B · IQ4_XS'),
      );
      expect([for (final a in n.actions) a.id], [NotifyActions.open]);
      final target = PushTarget.decode(n.payload)!;
      expect((target.kind, target.conversationId), ('system', null));

      // llama-server is down: the same notification, saying so
      final down = modelSwitchNotification(
        l,
        PushMessage.parse(data(event: 'switch_down', back: ''))!
            as ModelSwitchPush,
      );
      expect(down.body, 'llama-server is stopped');
      expect(down.id, n.id);

      expect(PushMessage.parse({...data(), 'event': 'switched'}), isNull);
      expect(PushMessage.parse({...data()}..remove('to')), isNull);
    });

    test('shown in the foreground too', () async {
      final n = FakeNotifications();
      await handlePush(data(), n, now: DateTime.now(), foreground: true);
      expect(n.shown, hasLength(1));
    });
  });

  testWidgets('Settings → Model switch failed saves on the server', (t) async {
    final env = await pumpDelve(t);
    env.server.on(
      'PATCH',
      '/api/v1/devices/me',
      (_) => FakeReply(200, {
        ...FakeServer.device,
        'notify': {
          ...(FakeServer.device['notify']! as Map<String, Object?>),
          'system': false,
        },
      }),
    );
    await t.tap(find.text('More'));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    final key = find.byKey(const Key('settings.notify.system'));
    await t.scrollUntilVisible(
      key,
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(t.widget<Switch>(key).value, isTrue);
    expect(find.text('Model switch failed'), findsOneWidget);
    await t.ensureVisible(key);
    await t.pumpAndSettle();
    await t.tap(key);
    await t.pumpAndSettle();
    final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
    expect(patch.data, {
      'notify': {'system': false},
    });
  });
}
