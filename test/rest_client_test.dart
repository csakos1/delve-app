import 'package:delve/api/api_error.dart';
import 'package:delve/api/protocol.dart';
import 'package:delve/api/rest_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';
import 'support/ws_fixtures.dart';

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
    expect((meta.apiRevision, meta.serverVersion), (5, '0.1.0'));
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

  group('A3 endpoints', () {
    test('conversations: page, cursor and archived as query', () async {
      server.json('GET', '/api/v1/conversations', {
        'data': [sample('conversation')],
        'next_cursor': 'abc',
      });
      final page = await api(
        token: 't',
      ).conversations(limit: 20, cursor: 'xyz');
      expect(page.conversations.single.id, sample('conversation')['id']);
      expect(page.nextCursor, 'abc');
      expect(server.requests.single.uri.queryParameters, {
        'limit': '20',
        'cursor': 'xyz',
        'archived': 'false',
      });
    });

    test('messages carry their tool steps', () async {
      server.json('GET', '/api/v1/conversations/c_1/messages', {
        'data': [
          sample('message', {'id': 1, 'role': 'user'}),
          {
            ...sample('message', {'id': 2, 'role': 'assistant'}),
            'tool_steps': [sample('tool_step')],
          },
        ],
        'has_more': true,
      });
      final page = await api(token: 't').messages('c_1', before: 9);
      expect(page.hasMore, isTrue);
      expect(page.messages.map((m) => m.toolSteps.length), [0, 1]);
      expect(server.requests.single.uri.queryParameters, {
        'before': '9',
        'limit': '100',
      });
    });

    test('open runs, usage, approvals', () async {
      server.json('GET', '/api/v1/runs/open', {
        'data': [sample('open_run')],
      });
      server.json('GET', '/api/v1/conversations/c_1/usage', {
        'conversation_id': 'c_1',
        'totals': sample('conversation')['totals'],
        'context': sample('conversation')['context'],
        'runs': [sample('run')],
      });
      server.json('GET', '/api/v1/approvals', {
        'data': [sample('approval')],
      });
      final a = api(token: 't');
      expect(
        (await a.openRuns()).single.position,
        sample('open_run')['position'],
      );
      expect((await a.usage('c_1')).runs, hasLength(1));
      expect(
        (await a.approvals()).single.requestId,
        sample('approval')['request_id'],
      );
      expect(
        server.requests.last.uri.queryParameters['status'],
        'pending,expired_in_hermes',
      );
    });

    test('answer and patch send exactly the fields asked for', () async {
      server.on(
        'POST',
        '/api/v1/approvals/apr_1',
        (_) => FakeReply(200, sample('approval', {'status': 'approved_once'})),
      );
      server.on(
        'PATCH',
        '/api/v1/conversations/c_1',
        (_) => FakeReply(200, sample('conversation', {'thinking': true})),
      );
      final a = api(token: 't');
      expect(
        (await a.answerApproval('apr_1', ApprovalChoice.once)).status,
        'approved_once',
      );
      expect(server.requests.last.data, {'choice': 'once'});
      expect(
        (await a.patchConversation('c_1', thinking: true)).thinking,
        isTrue,
      );
      expect(server.requests.last.data, {'thinking': true});
    });

    test('a 409 keeps the backend code', () async {
      server.json(
        'POST',
        '/api/v1/approvals/apr_1',
        FakeServer.detail('approval_already_decided'),
        status: 409,
      );
      await expectLater(
        api(token: 't').answerApproval('apr_1', ApprovalChoice.deny),
        throwsA(
          isA<ApiRequestError>().having(
            (e) => e.code,
            'code',
            'approval_already_decided',
          ),
        ),
      );
    });
  });
}
