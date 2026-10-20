import 'package:delve/api/api_error.dart';
import 'package:delve/api/rest_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  DelveApi api({String? token, void Function()? onUnauthorized}) => DelveApi(
    server: testServer,
    token: token,
    adapter: server,
    onUnauthorized: onUnauthorized,
  );

  test('meta needs no token and parses', () async {
    final meta = await api().meta();
    expect((meta.apiRevision, meta.serverVersion), (2, '0.1.0'));
    expect(server.requests.single.headers['Authorization'], isNull);
    expect(server.requests.single.uri.toString(), '$testServer/api/v1/meta');
  });

  test('authenticated calls send the bearer token', () async {
    final status = await api(token: 'dlv_x').status();
    expect(status.thinkingRoute!.ok, isTrue);
    expect(server.requests.single.headers['Authorization'], 'Bearer dlv_x');
  });

  test('register sends code, name and version; returns the token', () async {
    server.on(
      'POST',
      '/api/v1/devices/register',
      (r) => FakeReply(201, {
        'device_id': 'd1',
        'name': (r.data as Map<String, Object?>)['name'],
        'token': 'dlv_new',
      }),
    );
    final dev = await api().register(
      '4821-0937',
      name: 'pixel',
      appVersion: '0.1.0',
    );
    expect((dev.deviceId, dev.name, dev.token), ('d1', 'pixel', 'dlv_new'));
    expect(server.requests.single.data, {
      'code': '4821-0937',
      'name': 'pixel',
      'app_version': '0.1.0',
    });
  });

  test('backend error codes are kept', () async {
    server.json(
      'POST',
      '/api/v1/devices/register',
      FakeServer.detail('invalid_code', 'unknown, used or expired code'),
      status: 400,
    );
    await expectLater(
      api().register('0000-0000'),
      throwsA(
        isA<ApiRequestError>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.code, 'code', 'invalid_code'),
      ),
    );
  });

  test('429 carries Retry-After', () async {
    server.on(
      'POST',
      '/api/v1/devices/register',
      (_) => FakeReply(429, FakeServer.detail('too_many_attempts'), {
        'retry-after': '42',
      }),
    );
    await expectLater(
      api().register('0000-0000'),
      throwsA(
        isA<ApiRateLimited>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 42),
        ),
      ),
    );
  });

  test('401 on an authenticated call reports it', () async {
    var told = 0;
    server.json(
      'GET',
      '/api/v1/status',
      FakeServer.detail('unauthorized'),
      status: 401,
    );
    await expectLater(
      api(token: 'dlv_old', onUnauthorized: () => told++).status(),
      throwsA(isA<ApiUnauthorized>()),
    );
    expect(told, 1);
  });

  test('no answer is "unreachable"', () async {
    server.unreachable = true;
    await expectLater(
      api().meta(),
      throwsA(
        isA<ApiUnreachable>().having(
          (e) => e.host,
          'host',
          'archlinux.example.ts.net',
        ),
      ),
    );
  });

  test('a body that is not the contract is a bad response', () async {
    server.json('GET', '/api/v1/meta', {'hello': 'world'});
    await expectLater(api().meta(), throwsA(isA<ApiBadResponse>()));
    server.json('GET', '/api/v1/meta', [1, 2, 3]);
    await expectLater(api().meta(), throwsA(isA<ApiBadResponse>()));
  });

  test('unpair is a DELETE with the token and accepts 204', () async {
    await api(token: 'dlv_x').unpair();
    expect(server.calls, ['DELETE /api/v1/devices/me']);
    expect(server.requests.single.headers['Authorization'], 'Bearer dlv_x');
  });
}
