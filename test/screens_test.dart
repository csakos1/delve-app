import 'package:delve/app/app.dart';
import 'package:delve/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

void main() {
  group('pairing screen', () {
    Future<TestEnv> start(WidgetTester tester) =>
        pumpDelve(tester, paired: false);

    Finder submit() => find.byKey(const Key('pair.submit'));
    bool enabled(WidgetTester t) =>
        t.widget<FilledButton>(submit()).onPressed != null;

    Future<void> fill(WidgetTester t, String url, String code) async {
      await t.enterText(find.byKey(const Key('pair.url')), url);
      await t.enterText(find.byKey(const Key('pair.code')), code);
      await t.pump();
    }

    testWidgets('unpaired app opens on pairing; Pair waits for a full code', (
      t,
    ) async {
      await start(t);
      expect(find.text('Pair this phone'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(enabled(t), isFalse);
      await fill(t, 'archlinux.example.ts.net', '4821093');
      expect(enabled(t), isFalse);
      await fill(t, 'archlinux.example.ts.net', '48210937');
      expect(find.text('4821-0937'), findsOneWidget);
      expect(enabled(t), isTrue);
    });

    testWidgets('success lands on Chats with the token stored', (t) async {
      final env = await start(t);
      env.server.on(
        'POST',
        '/api/v1/devices/register',
        (_) => const FakeReply(201, {
          'device_id': 'd1',
          'name': 'pixel',
          'token': 'dlv_new',
        }),
      );
      await fill(t, 'archlinux.example.ts.net', '48210937');
      await t.tap(submit());
      await t.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect((await env.store.read())?.token, 'dlv_new');
    });

    testWidgets('invalid code is shown on the field', (t) async {
      final env = await start(t);
      env.server.json(
        'POST',
        '/api/v1/devices/register',
        FakeServer.detail('invalid_code'),
        status: 400,
      );
      await fill(t, 'archlinux.example.ts.net', '48210937');
      await t.tap(submit());
      await t.pumpAndSettle();
      expect(find.text('Invalid or expired code'), findsOneWidget);
    });

    testWidgets('rate limit counts down and blocks Pair', (t) async {
      final env = await start(t);
      env.server.on(
        'POST',
        '/api/v1/devices/register',
        (_) => FakeReply(429, FakeServer.detail('too_many_attempts'), {
          'retry-after': '3',
        }),
      );
      await fill(t, 'archlinux.example.ts.net', '48210937');
      await t.tap(submit());
      final banner = find.text('Too many attempts — try again in 3 s');
      for (var i = 0; i < 50 && banner.evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 10));
      }
      expect(find.text('Too many attempts — try again in 3 s'), findsOneWidget);
      expect(find.text('Pair · 3 s'), findsOneWidget);
      expect(enabled(t), isFalse);
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Pair · 2 s'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pump();
      expect(find.text('Pair'), findsOneWidget);
      expect(enabled(t), isTrue);
    });

    testWidgets('unreachable server asks about Tailscale', (t) async {
      final env = await start(t);
      env.server.unreachable = true;
      await fill(t, 'archlinux.example.ts.net', '48210937');
      await t.tap(submit());
      await t.pumpAndSettle();
      expect(
        find.text("Can't reach the server — is Tailscale on?"),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a non-tailnet URL is refused before any request', (t) async {
      final env = await start(t);
      await fill(t, 'https://example.com', '48210937');
      await t.tap(submit());
      await t.pumpAndSettle();
      expect(
        find.text("Use the desktop's Tailscale name (….ts.net)"),
        findsOneWidget,
      );
      expect(env.server.calls, isEmpty);
    });
  });

  group('settings', () {
    Future<TestEnv> openSettings(WidgetTester t) async {
      final env = await pumpDelve(t);
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('shows server, device, route and versions', (t) async {
      await openSettings(t);
      expect(find.text('https://archlinux.example.ts.net'), findsOneWidget);
      expect(find.text('pixel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('0.1.0 (1)'), findsOneWidget);
      expect(find.text('0.1.0 · revision eb4045e'), findsOneWidget);
      expect(find.text('0.22.2'), findsOneWidget);
    });

    testWidgets('a failed thinking route is called out', (t) async {
      final env = await pumpDelve(t);
      env.server.json('GET', '/api/v1/status', {
        ...FakeServer.status,
        'thinking_route': {
          'ok': false,
          'run_id': 'run_1',
          'at': '2026-10-19T21:30:00+00:00',
        },
      });
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();
      expect(find.text('Check failed'), findsOneWidget);
    });

    testWidgets('unpair asks, revokes and returns to pairing', (t) async {
      final env = await openSettings(t);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings.unpair')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(find.byKey(const Key('settings.unpair')));
      await t.pumpAndSettle();
      expect(find.text('Unpair this device?'), findsOneWidget);
      await t.tap(find.byKey(const Key('unpair.confirm')));
      await t.pumpAndSettle();
      expect(find.text('Pair this phone'), findsOneWidget);
      expect(
        find.text('This phone was unpaired. Pair again with a new code.'),
        findsOneWidget,
      );
      expect(env.server.calls, contains('DELETE /api/v1/devices/me'));
      expect(await env.store.read(), isNull);
    });
  });

  group('server too old', () {
    testWidgets('blocks until the server is updated', (t) async {
      final env = TestEnv(credentials: pairedCredentials());
      addTearDown(env.dispose);
      env.server.json('GET', '/api/v1/meta', {
        ...FakeServer.meta,
        'api_revision': 1,
      });
      setDesignSize(t);
      await t.pumpWidget(env.app(const DelveApp()));
      await t.pumpAndSettle();
      expect(find.text('Server version too old for this app'), findsOneWidget);
      expect(find.text('0.1.0 · API 1'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await t.tap(find.text('Check again'));
      await t.pumpAndSettle();
      expect(
        find.text('The server still reports API revision 1'),
        findsOneWidget,
      );

      env.server.reset();
      await t.tap(find.text('Check again'));
      await t.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
