import 'package:delve/app/pairing.dart';
import 'package:delve/app/router.dart';
import 'package:delve/app/session.dart';
import 'package:delve/data/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

void main() {
  late TestEnv env;
  tearDown(() => env.dispose());

  /// Lets the session load from the store and talk to the fake server.
  Future<SessionState> settle(ProviderContainer c) async {
    c.read(sessionProvider);
    await pumpEventQueue(times: 200);
    return c.read(sessionProvider);
  }

  test('no credentials: unpaired', () async {
    env = TestEnv();
    final c = env.container();
    expect(c.read(sessionProvider), isA<SessionLoading>());
    expect(await settle(c), isA<SessionUnpaired>());
    expect(env.server.calls, isEmpty);
  });

  test('stored credentials: paired, then /meta fills in', () async {
    env = TestEnv(credentials: pairedCredentials());
    final c = env.container();
    final s = await settle(c);
    expect(s, isA<SessionPaired>());
    expect((s as SessionPaired).meta?.apiRevision, 2);
    expect(c.read(apiProvider)?.token, 'dlv_test-token');
  });

  test('server unreachable at start: stays paired (offline)', () async {
    env = TestEnv(credentials: pairedCredentials());
    env.server.unreachable = true;
    final s = await settle(env.container());
    expect(s, isA<SessionPaired>());
    expect((s as SessionPaired).meta, isNull);
  });

  test(
    'older server contract: blocking state, recovers after update',
    () async {
      env = TestEnv(credentials: pairedCredentials());
      env.server.json('GET', '/api/v1/meta', {
        ...FakeServer.meta,
        'api_revision': 1,
      });
      final c = env.container();
      expect(await settle(c), isA<SessionServerTooOld>());

      env.server.reset();
      expect(await c.read(sessionProvider.notifier).checkServer(), isNull);
      expect(c.read(sessionProvider), isA<SessionPaired>());
    },
  );

  test('a 401 anywhere forgets the token and the local data', () async {
    env = TestEnv(credentials: pairedCredentials());
    await env.db
        .into(env.db.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: 'c_1',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            title: const Value('old'),
          ),
        );
    final c = env.container();
    await settle(c);
    env.server.json(
      'GET',
      '/api/v1/status',
      FakeServer.detail('unauthorized'),
      status: 401,
    );
    await expectLater(c.read(serverStatusProvider.future), throwsA(anything));
    await pumpEventQueue(times: 200);

    final s = c.read(sessionProvider);
    expect(s, isA<SessionUnpaired>());
    expect((s as SessionUnpaired).reason, UnpairReason.revoked);
    expect(await env.store.read(), isNull);
    expect(await env.db.select(env.db.conversations).get(), isEmpty);
    expect(c.read(apiProvider), isNull);
  });

  test('unpair revokes on the server, then forgets', () async {
    env = TestEnv(credentials: pairedCredentials());
    final c = env.container();
    await settle(c);
    expect(await c.read(sessionProvider.notifier).unpair(), isTrue);
    expect(env.server.calls.last, 'DELETE /api/v1/devices/me');
    expect(
      env.server.requests.last.headers['Authorization'],
      'Bearer dlv_test-token',
    );
    expect(
      (c.read(sessionProvider) as SessionUnpaired).reason,
      UnpairReason.unpaired,
    );
    expect(await env.store.read(), isNull);
  });

  test('unpair while offline still forgets locally, and says so', () async {
    env = TestEnv(credentials: pairedCredentials());
    final c = env.container();
    await settle(c);
    env.server.unreachable = true;
    expect(await c.read(sessionProvider.notifier).unpair(), isFalse);
    expect(
      (c.read(sessionProvider) as SessionUnpaired).reason,
      UnpairReason.unpairedLocally,
    );
    expect(await env.store.read(), isNull);
  });

  group('pairing', () {
    late ProviderContainer c;
    setUp(() async {
      env = TestEnv();
      c = env.container();
      await settle(c);
      // keep the auto-dispose controller alive between calls
      c.listen(pairingProvider, (_, _) {});
    });

    Future<PairingState> pair(String url, String code) async {
      await c.read(pairingProvider.notifier).submit(url, code);
      return c.read(pairingProvider);
    }

    test('success stores the token and pairs', () async {
      env.server.on(
        'POST',
        '/api/v1/devices/register',
        (r) => FakeReply(201, {
          'device_id': 'd1',
          'name': (r.data as Map<String, Object?>)['name'],
          'token': 'dlv_new',
        }),
      );
      final p = await pair('archlinux.example.ts.net', '4821 0937');
      expect(p.problem, isNull);
      expect(env.server.calls, [
        'GET /api/v1/meta',
        'POST /api/v1/devices/register',
      ]);
      expect(env.server.requests.last.data, {
        'code': '4821-0937',
        'name': 'pixel',
        'app_version': '0.1.0',
      });
      final stored = await env.store.read();
      expect(
        (stored?.token, stored?.server, stored?.deviceId),
        ('dlv_new', testServer, 'd1'),
      );
      expect(c.read(sessionProvider), isA<SessionPaired>());
    });

    test('bad URL and short code never reach the network', () async {
      expect(
        (await pair('http://x.y.ts.net', '4821-0937')).problem,
        isA<PairingBadUrl>(),
      );
      expect(
        (await pair('archlinux.example.ts.net', '4821-09')).problem,
        isA<PairingBadCode>(),
      );
      expect(env.server.calls, isEmpty);
    });

    test('server answers map to problems', () async {
      env.server.json(
        'POST',
        '/api/v1/devices/register',
        FakeServer.detail('invalid_code'),
        status: 400,
      );
      expect(
        (await pair('archlinux.example.ts.net', '48210937')).problem,
        isA<PairingBadCode>(),
      );

      env.server.on(
        'POST',
        '/api/v1/devices/register',
        (_) => FakeReply(429, FakeServer.detail('too_many_attempts'), {
          'retry-after': '42',
        }),
      );
      final limited = (await pair(
        'archlinux.example.ts.net',
        '48210937',
      )).problem;
      expect(
        (limited! as PairingRateLimited).wait,
        const Duration(seconds: 42),
      );

      env.server.unreachable = true;
      expect(
        (await pair('archlinux.example.ts.net', '48210937')).problem,
        isA<PairingUnreachable>(),
      );

      env.server.reset();
      env.server.json('GET', '/api/v1/meta', {
        'detail': 'Not Found',
      }, status: 404);
      expect(
        (await pair('archlinux.example.ts.net', '48210937')).problem,
        isA<PairingNotDelve>(),
      );

      expect(c.read(sessionProvider), isA<SessionUnpaired>());
      expect(await env.store.read(), isNull);
    });
  });

  test('router redirects follow the session', () {
    final paired = SessionPaired(pairedCredentials());
    expect(
      sessionRedirect(const SessionLoading(), Routes.chats),
      Routes.splash,
    );
    expect(sessionRedirect(const SessionLoading(), Routes.splash), isNull);
    expect(
      sessionRedirect(const SessionUnpaired(), Routes.settings),
      Routes.pair,
    );
    expect(sessionRedirect(const SessionUnpaired(), Routes.pair), isNull);
    expect(sessionRedirect(paired, Routes.pair), Routes.chats);
    expect(sessionRedirect(paired, Routes.splash), Routes.chats);
    expect(sessionRedirect(paired, Routes.settings), isNull);
  });
}
