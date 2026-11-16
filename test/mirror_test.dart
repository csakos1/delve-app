import 'package:delve/api/rest_client.dart';
import 'package:delve/app/session.dart';
import 'package:delve/mirror/mirror_controller.dart';
import 'package:delve/mirror/mirror_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/mirror_fakes.dart';

Future<void> frames(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

MirrorApp viber({bool selected = false}) => MirrorApp(
  package: 'com.viber.voip',
  label: 'Viber',
  selected: selected,
  last: DateTime(2026, 11, 16, 19, 2),
);

void main() {
  group('what the Android side reports', () {
    test('a full answer', () {
      final s = MirrorState.fromMap({
        'granted': true,
        'connected': true,
        'enabled': true,
        'credentials': true,
        'batteryExempt': false,
        'okAt': 1794852000000,
        'failAt': 1794852060000,
        'failure': 'HTTP 502',
        'desk': false,
        'apps': [
          {
            'package': 'com.viber.voip',
            'label': 'Viber',
            'last': 1794852000000,
            'selected': true,
          },
          {'package': 'org.example', 'label': 'Example', 'last': 0},
          {'label': 'no package'},
          'not a map',
        ],
      });
      expect(
        (s.granted, s.connected, s.enabled, s.credentials, s.batteryExempt),
        (true, true, true, true, false),
      );
      expect(s.okAt, DateTime.fromMillisecondsSinceEpoch(1794852000000));
      expect(s.failAt, DateTime.fromMillisecondsSinceEpoch(1794852060000));
      expect((s.failure, s.desk), ('HTTP 502', false));
      expect(
        [for (final a in s.apps) (a.package, a.label, a.selected)],
        [('com.viber.voip', 'Viber', true), ('org.example', 'Example', false)],
      );
      expect(s.apps.first.last, isNotNull);
      expect(s.apps.last.last, isNull);
    });

    test('an empty answer is everything off', () {
      final s = MirrorState.fromMap(const {});
      expect(
        (s.granted, s.connected, s.enabled, s.credentials, s.batteryExempt),
        (false, false, false, false, true),
      );
      expect((s.okAt, s.failAt, s.failure, s.desk), (null, null, null, null));
      expect(s.apps, isEmpty);
    });
  });

  group('the method channel', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('hu.csakos.delve/mirror');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('without the platform side there is no mirroring', () async {
      const mirror = ChannelMirror();
      expect(await mirror.state(), isNull);
      expect(await mirror.setEnabled(on: true), isNull);
      expect(
        await mirror.setCredentials(Uri.parse('https://x.example'), 't'),
        isFalse,
      );
      expect(await mirror.openAccess(), isFalse);
      await mirror.wipe();
    });

    test('the calls and what they carry', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'state' || 'setEnabled' || 'setSelected' => <String, Object?>{
            'granted': true,
            'enabled': call.method == 'setEnabled',
          },
          'setCredentials' || 'openAccess' || 'requestBatteryExempt' => true,
          _ => null,
        };
      });
      const mirror = ChannelMirror();
      expect((await mirror.state())!.granted, isTrue);
      expect((await mirror.setEnabled(on: true))!.enabled, isTrue);
      expect(await mirror.setSelected('com.viber.voip', on: true), isNotNull);
      expect(await mirror.setCredentials(testServer, 'dlv_test-token'), isTrue);
      expect(await mirror.openAccess(), isTrue);
      expect(await mirror.requestBatteryExempt(), isTrue);
      await mirror.wipe();
      expect(
        [for (final c in calls) c.method],
        [
          'state',
          'setEnabled',
          'setSelected',
          'setCredentials',
          'openAccess',
          'requestBatteryExempt',
          'wipe',
        ],
      );
      expect(
        [for (final c in calls) c.arguments],
        [
          null,
          {'on': true},
          {'package': 'com.viber.voip', 'on': true},
          {'server': '$testServer', 'token': 'dlv_test-token'},
          null,
          null,
          null,
        ],
      );
    });

    test('a platform error is a quiet no', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'mirror'),
      );
      const mirror = ChannelMirror();
      expect(await mirror.state(), isNull);
      expect(await mirror.setCredentials(testServer, 't'), isFalse);
    });
  });

  group('the controller', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    /// The controller as the app's root keeps it, once the session and the
    /// Android side have answered.
    Future<ProviderContainer> start() async {
      final c = env.container();
      c.listen(mirrorProvider, (_, _) {});
      await pumpEventQueue(times: 200);
      return c;
    }

    test('paired, mirroring off: the token stays in the app', () async {
      env = TestEnv(credentials: pairedCredentials());
      final c = await start();
      final view = c.read(mirrorProvider);
      expect((view.loaded, view.state?.enabled), (true, false));
      expect(env.mirror.credentials, isNull);
      expect(env.mirror.calls, isNot(contains('setCredentials')));
      expect(env.mirror.calls, isNot(contains('wipe')));
    });

    test('turning on hands the server and the token over first, turning off '
        'takes them back', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(state: const MirrorState(granted: true)),
      );
      final c = await start();
      env.mirror.calls.clear();
      expect(
        await c.read(mirrorProvider.notifier).setEnabled(on: true),
        isTrue,
      );
      expect(env.mirror.calls, ['setCredentials', 'setEnabled true']);
      expect(env.mirror.credentials, (testServer, 'dlv_test-token'));
      final on = c.read(mirrorProvider).state!;
      expect((on.enabled, on.credentials), (true, true));

      expect(
        await c.read(mirrorProvider.notifier).setEnabled(on: false),
        isTrue,
      );
      expect(env.mirror.credentials, isNull);
      final off = c.read(mirrorProvider).state!;
      expect((off.enabled, off.credentials), (false, false));
    });

    test('the phone cannot keep the token: mirroring stays off', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(state: const MirrorState(granted: true))
          ..refuseCredentials = true,
      );
      final c = await start();
      expect(
        await c.read(mirrorProvider.notifier).setEnabled(on: true),
        isFalse,
      );
      expect(env.mirror.current.enabled, isFalse);
      expect(env.mirror.calls, isNot(contains('setEnabled true')));
    });

    test('on, but the copy of the token is gone: handed over again at '
        'start', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(
          state: const MirrorState(granted: true, enabled: true),
        ),
      );
      final c = await start();
      expect(env.mirror.credentials, (testServer, 'dlv_test-token'));
      expect(c.read(mirrorProvider).state!.credentials, isTrue);
    });

    test('choosing an app', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(state: MirrorState(granted: true, apps: [viber()])),
      );
      final c = await start();
      await c
          .read(mirrorProvider.notifier)
          .setSelected('com.viber.voip', on: true);
      expect(c.read(mirrorProvider).state!.apps.single.selected, isTrue);
    });

    test('unpairing wipes the Android side', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(
          state: MirrorState(
            granted: true,
            enabled: true,
            credentials: true,
            apps: [viber(selected: true)],
          ),
        )..credentials = (testServer, 'dlv_test-token'),
      );
      final c = await start();
      expect(env.mirror.calls, isNot(contains('wipe')));
      await c.read(sessionProvider.notifier).unpair();
      await pumpEventQueue(times: 200);
      expect(env.mirror.calls, contains('wipe'));
      expect(env.mirror.credentials, isNull);
      final s = c.read(mirrorProvider).state!;
      expect((s.enabled, s.credentials), (false, false));
      expect(s.apps, isEmpty);
    });

    test('a revoked token (401) wipes it too', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(
          state: const MirrorState(
            granted: true,
            enabled: true,
            credentials: true,
          ),
        )..credentials = (testServer, 'dlv_test-token'),
      );
      final c = await start();
      c.read(sessionProvider.notifier).handleUnauthorized();
      await pumpEventQueue(times: 200);
      expect(env.mirror.calls, contains('wipe'));
      expect(env.mirror.credentials, isNull);
    });

    test('not paired: what an earlier pairing left is wiped', () async {
      env = TestEnv(
        mirror: FakeMirror(state: MirrorState(granted: true, apps: [viber()])),
      );
      await start();
      expect(env.mirror.calls, contains('wipe'));
      expect(env.mirror.current.apps, isEmpty);
    });

    test('not paired, nothing kept: nothing to wipe', () async {
      env = TestEnv();
      final c = await start();
      expect(env.mirror.calls, isNot(contains('wipe')));
      expect(c.read(mirrorProvider).loaded, isTrue);
    });

    test('a platform without mirroring', () async {
      env = TestEnv(
        credentials: pairedCredentials(),
        mirror: FakeMirror(available: false),
      );
      final c = await start();
      final view = c.read(mirrorProvider);
      expect((view.loaded, view.state), (true, null));
      expect(
        await c.read(mirrorProvider.notifier).setEnabled(on: true),
        isFalse,
      );
    });
  });

  test('REST: GET /mirror says whether the desktop agent is there', () async {
    final server = FakeServer();
    final api = DelveApi(server: testServer, token: 'dlv_x', adapter: server);
    addTearDown(api.close);
    final status = await api.mirror();
    expect((status.desk.connected, status.desk.lastSeenS), (true, 3));
    expect(server.calls, ['GET /api/v1/mirror']);
    server.json('GET', '/api/v1/mirror', {
      'desk': {'connected': false, 'last_seen_s': null},
    });
    final away = await api.mirror();
    expect((away.desk.connected, away.desk.lastSeenS), (false, null));
  });

  group('More → Mirroring', () {
    Future<TestEnv> open(WidgetTester t, FakeMirror mirror) async {
      final env = await pumpDelve(t, mirror: mirror);
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Mirroring'));
      await t.pumpAndSettle();
      await frames(t);
      return env;
    }

    SwitchListTile tile(WidgetTester t, String key) =>
        t.widget<SwitchListTile>(find.byKey(Key(key)));

    testWidgets('without notification access: says so, the switch rests, '
        'Settings opens the system page', (t) async {
      final env = await open(t, FakeMirror());
      expect(find.byKey(const Key('mirror.noAccess')), findsOneWidget);
      expect(find.text('not allowed'), findsOneWidget);
      expect(tile(t, 'mirror.enabled').onChanged, isNull);
      expect(find.byKey(const Key('mirror.noApps')), findsOneWidget);

      await t.tap(find.widgetWithText(TextButton, 'Settings'));
      await frames(t);
      expect(env.mirror.calls, contains('openAccess'));
      expect(find.text("Couldn't open the system settings"), findsNothing);

      env.mirror.accessOpens = false;
      await t.tap(find.widgetWithText(TextButton, 'Settings'));
      await frames(t);
      expect(find.text("Couldn't open the system settings"), findsOneWidget);
    });

    testWidgets('with access: the switch turns mirroring on with the token, '
        'an app is chosen with its own', (t) async {
      final env = await open(
        t,
        FakeMirror(
          state: MirrorState(granted: true, connected: true, apps: [viber()]),
        ),
      );
      expect(find.byKey(const Key('mirror.noAccess')), findsNothing);
      expect(find.text('allowed'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      // the fake server's agent asked three seconds ago
      expect(
        t
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('mirror.desk')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'connected',
      );
      expect(find.text('nothing yet'), findsOneWidget);
      expect(env.server.calls, contains('GET /api/v1/mirror'));

      expect(tile(t, 'mirror.enabled').value, isFalse);
      await t.tap(find.byKey(const Key('mirror.enabled')));
      await frames(t);
      expect(tile(t, 'mirror.enabled').value, isTrue);
      expect(env.mirror.credentials, (testServer, 'dlv_test-token'));

      expect(find.text('Viber'), findsOneWidget);
      expect(tile(t, 'mirror.app.com.viber.voip').value, isFalse);
      await t.tap(find.byKey(const Key('mirror.app.com.viber.voip')));
      await frames(t);
      expect(tile(t, 'mirror.app.com.viber.voip').value, isTrue);
      expect(env.mirror.current.apps.single.selected, isTrue);

      await t.tap(find.byKey(const Key('mirror.enabled')));
      await frames(t);
      expect(tile(t, 'mirror.enabled').value, isFalse);
      expect(env.mirror.credentials, isNull);
    });

    testWidgets('a failed request and a missing battery exemption show; the '
        'desktop agent away', (t) async {
      final mirror = FakeMirror(
        state: MirrorState(
          granted: true,
          connected: true,
          enabled: true,
          credentials: true,
          batteryExempt: false,
          okAt: DateTime(2026, 11, 16, 19),
          failAt: DateTime(2026, 11, 16, 19, 5),
          failure: 'HTTP 502',
        ),
      );
      final env = await pumpDelve(
        t,
        mirror: mirror,
        before: (env) async => env.server.json('GET', '/api/v1/mirror', {
          'desk': {'connected': false, 'last_seen_s': 400},
        }),
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Mirroring'));
      await t.pumpAndSettle();
      await frames(t);

      expect(find.textContaining('HTTP 502 · '), findsOneWidget);
      expect(find.text('not connected'), findsOneWidget);
      await t.tap(find.byKey(const Key('mirror.battery')));
      await frames(t);
      expect(env.mirror.calls, contains('requestBatteryExempt'));
    });

    testWidgets('the refresh button asks the phone and the server '
        'again', (t) async {
      final env = await open(
        t,
        FakeMirror(state: const MirrorState(granted: true)),
      );
      expect(find.text('not running'), findsOneWidget);
      env.mirror.current = MirrorState(
        granted: true,
        connected: true,
        apps: [viber()],
      );
      final asked = env.server.calls
          .where((c) => c == 'GET /api/v1/mirror')
          .length;
      await t.tap(find.byKey(const Key('mirror.refresh')));
      await frames(t);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('Viber'), findsOneWidget);
      expect(
        env.server.calls.where((c) => c == 'GET /api/v1/mirror').length,
        asked + 1,
      );
    });

    testWidgets('a phone without mirroring says so', (t) async {
      await open(t, FakeMirror(available: false));
      expect(find.byKey(const Key('mirror.unavailable')), findsOneWidget);
      expect(find.byKey(const Key('mirror.enabled')), findsNothing);
    });
  });
}
