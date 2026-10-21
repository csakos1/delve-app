import 'dart:async';
import 'dart:math';

import 'package:delve/api/protocol.dart';
import 'package:delve/api/rest_client.dart';
import 'package:delve/data/credentials.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/sync/backoff.dart';
import 'package:delve/sync/connection_status.dart';
import 'package:delve/sync/sync_engine.dart';
import 'package:delve/sync/transport.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/fake_ws_server.dart';
import 'support/harness.dart';
import 'support/ws_fixtures.dart';

const fast = SyncTiming(
  helloTimeout: Duration(milliseconds: 400),
  silence: Duration(milliseconds: 600),
  backoffMin: Duration(milliseconds: 10),
  backoffMax: Duration(milliseconds: 40),
  pauseGrace: Duration(milliseconds: 100),
  batchWindow: Duration(milliseconds: 5),
  ackTimeout: Duration(seconds: 2),
);

/// Polls [cond] until it holds (real sockets need real time).
Future<void> eventually(
  FutureOr<bool> Function() cond, {
  Duration timeout = const Duration(seconds: 5),
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (!await cond()) {
    if (DateTime.now().isAfter(end)) {
      fail('timed out waiting for ${reason ?? 'condition'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late FakeWsServer ws;
  late AppDatabase db;
  late FakeServer rest;
  late SyncEngine engine;
  late int unauthorized;

  SyncEngine makeEngine({
    Uri? server,
    StreamController<void>? network,
    SyncTiming timing = fast,
  }) {
    final origin = server ?? ws.origin;
    final creds = Credentials(
      server: origin,
      token: 'dlv_test-token',
      deviceId: '0f5e2c3a-1b2d-4e6f-8a9b-0c1d2e3f4a5b',
      deviceName: 'pixel',
      pairedAt: DateTime.utc(2026, 10, 12),
    );
    final api = DelveApi(server: origin, token: creds.token, adapter: rest);
    addTearDown(api.close);
    return SyncEngine(
      db: db,
      credentials: creds,
      api: api,
      transport: const IoWsTransport(connectTimeout: Duration(seconds: 2)),
      onUnauthorized: () => unauthorized++,
      timing: timing,
      random: Random(1),
      networkChanges: network?.stream,
    );
  }

  setUp(() async {
    ws = await FakeWsServer.start();
    db = memoryDb();
    rest = FakeServer();
    unauthorized = 0;
    engine = makeEngine();
  });

  tearDown(() async {
    await engine.dispose();
    await ws.close();
    await db.close();
  });

  Future<List<String>> logKinds() async => [
    for (final r in (await db.select(db.connectionLog).get())) r.kind,
  ];

  int restCalls(String call) => rest.calls.where((c) => c == call).length;

  Map<String, Object?> conversation(String id, {String? title}) =>
      sample('conversation', {'id': id, 'title': title});

  Future<void> live() => eventually(
    () => engine.status.isLive && !engine.status.resyncing,
    reason: 'live',
  );

  test('pings while live, so the server knows the phone is there', () async {
    await engine.dispose();
    engine = makeEngine(
      timing: const SyncTiming(
        helloTimeout: Duration(milliseconds: 400),
        silence: Duration(milliseconds: 600),
        backoffMin: Duration(milliseconds: 10),
        backoffMax: Duration(milliseconds: 40),
        pauseGrace: Duration(milliseconds: 100),
        batchWindow: Duration(milliseconds: 5),
        ackTimeout: Duration(seconds: 2),
        pingInterval: Duration(milliseconds: 30),
      ),
    );
    await engine.start();
    final conn = await ws.nextConnection();
    await live();
    await eventually(() => conn.all('ping').length >= 3, reason: 'pings');
    expect(engine.status.isLive, isTrue);
    expect(conn.all('ping').first['id'], 'ping');
  });

  test('the default pause grace closes the socket before Android cuts it', () {
    expect(
      const SyncTiming().pauseGrace,
      lessThan(const Duration(seconds: 10)),
    );
    expect(const SyncTiming().pingInterval, const Duration(seconds: 20));
  });

  test(
    'first connection: hello without a position, reload over REST, live',
    () async {
      await engine.start();
      final conn = await ws.nextConnection();
      expect(conn.path, '/api/v1/ws');
      final hello = (await conn.next('hello'))['data']! as Map<String, Object?>;
      expect(hello, {'device_token': 'dlv_test-token'});
      await live();

      expect(restCalls('GET /api/v1/conversations'), 1);
      expect(restCalls('GET /api/v1/runs/open'), 1);
      expect(restCalls('GET /api/v1/approvals'), 1);
      final sync = await db.readSyncState();
      expect((sync.epoch, sync.lastSeq), ('epoch-1', 0));
      expect(
        await logKinds(),
        containsAllInOrder(['connecting', 'connected', 'resync']),
      );
    },
  );

  test(
    'events are stored with their seq; a reconnect resumes from it',
    () async {
      await engine.start();
      await live();
      ws.broadcast('conversation.created', conversation('c_1'));
      ws.broadcast(
        'conversation.updated',
        conversation('c_1', title: 'Uptime'),
      );
      await eventually(() async => (await db.readSyncState()).lastSeq == 2);
      final c = await db.select(db.conversations).getSingle();
      expect(c.title, 'Uptime');

      await ws.connections.first.close(1011, 'restart');
      final second = await ws.nextConnection(index: 1);
      final hello =
          (await second.next('hello'))['data']! as Map<String, Object?>;
      expect(hello['last_seq'], 2);
      expect(hello['epoch'], 'epoch-1');
      await live();
      expect(
        restCalls('GET /api/v1/conversations'),
        1,
        reason: 'resumed, not reloaded',
      );
      expect(engine.status.attempt, 0);
    },
  );

  test('system.updated is handed on, not stored (B3)', () async {
    await engine.start();
    await live();
    final next = engine.systemUpdates.first;
    ws.broadcast('system.updated', sample('system'));
    final s = await next.timeout(const Duration(seconds: 5));
    expect((s.llama.status, s.hermes.status), ('running', 'degraded'));
    await eventually(() async => (await db.readSyncState()).lastSeq == 1);
  });

  test('events up to the stored position are not applied twice', () async {
    await engine.start();
    await live();
    ws.broadcast('conversation.created', conversation('c_1', title: 'first'));
    await eventually(() async => (await db.readSyncState()).lastSeq == 1);
    // a replay that overlaps what is stored (seq 1 again, now different)
    ws.connections.first.event(
      1,
      'conversation.updated',
      conversation('c_1', title: 'stale'),
    );
    ws.broadcast(
      'conversation.updated',
      conversation('c_1', title: 'second'),
    ); // seq 2
    await eventually(() async => (await db.readSyncState()).lastSeq == 2);
    expect((await db.select(db.conversations).getSingle()).title, 'second');
  });

  test('a new epoch (server restart) reloads', () async {
    await engine.start();
    await live();
    ws.epoch = 'epoch-2';
    await ws.connections.first.close(4000, 'restart');
    await ws.nextConnection(index: 1);
    await eventually(() async => (await db.readSyncState()).epoch == 'epoch-2');
    await live();
    expect(restCalls('GET /api/v1/conversations'), 2);
  });

  test('resync_required reloads even with the same epoch', () async {
    await engine.start();
    await live();
    ws.resyncRequired = true;
    await ws.connections.first.close(1011);
    await ws.nextConnection(index: 1);
    await eventually(() => restCalls('GET /api/v1/conversations') == 2);
  });

  test('4401: the token is gone, no more attempts', () async {
    ws.autoHello = false;
    await engine.start();
    final conn = await ws.nextConnection();
    await conn.next('hello');
    await conn.close(WsClose.unauthorized, 'unauthorized');
    await eventually(() => engine.status.phase == ConnectionPhase.authFailed);
    expect(unauthorized, 1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(ws.connections, hasLength(1));
    expect(await logKinds(), contains('authFailed'));
  });

  test(
    'backend down behind the proxy: backoff, then live once it is back',
    () async {
      ws.refuse = true;
      await engine.start();
      await eventually(() => engine.status.attempt >= 3);
      expect(engine.status.problem, ConnectionProblem.rejected);
      expect(
        engine.status.phase,
        anyOf(ConnectionPhase.backoff, ConnectionPhase.connecting),
      );
      ws.refuse = false;
      await live();
      expect(engine.status.attempt, 0);
      expect(await logKinds(), contains('failed'));
    },
  );

  test('nothing listening: unreachable', () async {
    await engine.dispose();
    final closed = await FakeWsServer.start();
    final port = closed.origin.port;
    await closed.close();
    engine = makeEngine(server: Uri.parse('http://127.0.0.1:$port'));
    await engine.start();
    await eventually(() => engine.status.phase == ConnectionPhase.backoff);
    expect(engine.status.problem, ConnectionProblem.unreachable);
  });

  test('a network change retries at once instead of waiting', () async {
    await engine.dispose();
    final network = StreamController<void>();
    addTearDown(network.close);
    engine = SyncEngine(
      db: db,
      credentials: Credentials(
        server: ws.origin,
        token: 't',
        deviceId: 'd',
        deviceName: 'pixel',
        pairedAt: DateTime.utc(2026),
      ),
      api: DelveApi(server: ws.origin, token: 't', adapter: rest),
      transport: const IoWsTransport(),
      onUnauthorized: () {},
      networkChanges: network.stream,
      timing: const SyncTiming(
        backoffMin: Duration(seconds: 20),
        backoffMax: Duration(seconds: 20),
        batchWindow: Duration(milliseconds: 5),
      ),
    );
    ws.refuse = true;
    await engine.start();
    await eventually(() => engine.status.phase == ConnectionPhase.backoff);
    ws.refuse = false;
    network.add(null);
    await live();
  });

  test('silence: no frame for the window means a dead socket', () async {
    await engine.start();
    await live();
    await ws.nextConnection(index: 1); // after the silence window
    expect(await logKinds(), contains('closed'));
    final closed = (await db.select(db.connectionLog).get()).firstWhere(
      (r) => r.kind == 'closed',
    );
    expect(closed.detail, contains('silent'));
  });

  test('keepalives keep a quiet socket open', () async {
    await engine.start();
    await live();
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      ws.connections.first.sendRaw({
        'type': 'keepalive',
        'data': {'ts': 0},
      });
    }
    expect(ws.connections, hasLength(1));
  });

  test('no hello.ok in time: reconnect', () async {
    ws.autoHello = false;
    await engine.start();
    await ws.nextConnection(index: 1);
    final closed = (await db.select(db.connectionLog).get()).firstWhere(
      (r) => r.kind == 'closed',
    );
    expect(closed.detail, contains('helloTimeout'));
  });

  test('4408 (slow consumer): resumes right away', () async {
    await engine.start();
    await live();
    await ws.connections.first.close(WsClose.timeoutOrSlow, 'slow consumer');
    final second = await ws.nextConnection(index: 1);
    expect(
      ((await second.next('hello'))['data']!
          as Map<String, Object?>)['last_seq'],
      0,
    );
  });

  group('outbox', () {
    test(
      'written offline, sent after hello with the same id, resent after a drop',
      () async {
        ws.refuse = true;
        await engine.start();
        final id = await engine.sendMessage('hello there', thinking: true);
        final row = await db.select(db.outbox).getSingle();
        expect(
          (row.clientMsgId, row.state, row.conversationId),
          (id, 'pending', null),
        );

        ws.autoAck = false;
        ws.refuse = false;
        final conn = await ws.nextConnection();
        final send = await conn.next('chat.send');
        expect(send['data'], {
          'text': 'hello there',
          'client_msg_id': id,
          'thinking': true,
        });
        await eventually(
          () async =>
              (await db.select(db.outbox).getSingle()).state == 'sending',
        );

        await conn.close(1011); // no ack: did the server get it? send again
        await eventually(
          () async =>
              (await db.select(db.outbox).getSingle()).state == 'pending',
        );
        ws.autoAck = true;
        final again = await (await ws.nextConnection(
          index: 1,
        )).next('chat.send');
        expect((again['data']! as Map<String, Object?>)['client_msg_id'], id);
        await eventually(
          () async => (await db.select(db.outbox).get()).isEmpty,
        );
        expect(
          (await db.select(db.connectionLog).get()).map((r) => r.kind),
          isNot(contains('protocol')),
        );
      },
    );

    test('several queued messages go out in order', () async {
      ws.refuse = true;
      await engine.start();
      await engine.sendMessage('one', conversationId: 'c_1');
      await engine.sendMessage('two', conversationId: 'c_1');
      ws.refuse = false;
      final conn = await ws.nextConnection();
      await eventually(() async => (await db.select(db.outbox).get()).isEmpty);
      expect(
        [
          for (final f in conn.all('chat.send'))
            (f['data']! as Map<String, Object?>)['text'],
        ],
        ['one', 'two'],
      );
    });

    test('a refused message is marked failed, and can be retried', () async {
      ws.autoAck = false;
      await engine.start();
      await live();
      final id = await engine.sendMessage('x', conversationId: 'c_gone');
      final conn = ws.connections.first;
      conn.replyError(await conn.next('chat.send'), 'not_found');
      await eventually(
        () async => (await db.select(db.outbox).getSingle()).state == 'failed',
      );
      expect((await db.select(db.outbox).getSingle()).lastError, 'not_found');

      ws.autoAck = true;
      await engine.retryMessage(id);
      await eventually(() async => (await db.select(db.outbox).get()).isEmpty);
    });

    test(
      'rows left sending by a killed app go back to pending at start',
      () async {
        await db
            .into(db.outbox)
            .insert(
              OutboxCompanion.insert(
                clientMsgId: '3b2f8a8e-1111-4c1e-9a7b-000000000002',
                body: 'b',
                createdAt: DateTime.utc(2026),
                state: const Value('sending'),
              ),
            );
        ws.autoAck = false;
        await engine.start();
        final send = await (await ws.nextConnection()).next('chat.send');
        expect(
          (send['data']! as Map<String, Object?>)['client_msg_id'],
          '3b2f8a8e-1111-4c1e-9a7b-000000000002',
        );
      },
    );
  });

  group('requests', () {
    test('approval answers are never queued', () async {
      ws.refuse = true;
      await engine.start();
      await expectLater(
        engine.respondApproval('apr_1', ApprovalChoice.once),
        throwsA(isA<NotConnected>()),
      );
      expect(await db.select(db.outbox).get(), isEmpty);
    });

    test(
      'approval answer over the socket updates the stored approval',
      () async {
        await engine.start();
        await live();
        final conn = ws.connections.first;
        final answer = engine.respondApproval(
          'apr_3c9d1e2f',
          ApprovalChoice.deny,
        );
        final req = await conn.next('approval.respond');
        expect(req['data'], {'request_id': 'apr_3c9d1e2f', 'choice': 'deny'});
        conn.reply(req, {
          'approval': sample('approval', {
            'status': 'denied',
            'choice': 'deny',
            'decided_by': 'pixel',
          }),
        });
        expect((await answer).status, 'denied');
        expect((await db.select(db.approvals).getSingle()).status, 'denied');
      },
    );

    test(
      'a request without an answer before the socket drops fails as NoAnswer',
      () async {
        await engine.start();
        await live();
        final stop = expectLater(
          engine.stopRun('run_1'),
          throwsA(isA<NoAnswer>()),
        );
        final conn = ws.connections.first;
        await conn.next('run.stop');
        await conn.close(1011);
        await stop;
      },
    );

    test('server errors come back as RequestRejected', () async {
      await engine.start();
      await live();
      final set = engine.setConversation('c_x', thinking: true);
      final conn = ws.connections.first;
      conn.replyError(await conn.next('conversation.set'), 'not_found');
      await expectLater(
        set,
        throwsA(
          isA<RequestRejected>().having((e) => e.code, 'code', 'not_found'),
        ),
      );
    });

    test('sync stores the conversation and its messages', () async {
      await engine.start();
      await live();
      final more = engine.syncConversation('c_5f2a9e1b7c3d4e6f');
      final conn = ws.connections.first;
      final req = await conn.next('sync');
      conn.reply(req, {
        'conversation': sample('conversation'),
        'messages': [
          sample('message', {'id': 1, 'role': 'user', 'status': 'final'}),
          {
            ...sample('message', {
              'id': 2,
              'role': 'assistant',
              'status': 'final',
            }),
            'tool_steps': [sample('tool_step')],
          },
        ],
        'has_more': false,
      });
      expect(await more, isFalse);
      expect(await db.select(db.messages).get(), hasLength(2));
      expect(await db.select(db.toolSteps).get(), hasLength(1));
    });
  });

  group('lifecycle', () {
    test('background: closes after the grace period, back: resumes', () async {
      await engine.start();
      await live();
      engine.setForeground(false);
      await ws.connections.first.done;
      await eventually(() => engine.status.phase == ConnectionPhase.offline);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        ws.connections,
        hasLength(1),
        reason: 'no attempts in the background',
      );

      engine.setForeground(true);
      final hello = await (await ws.nextConnection(index: 1)).next('hello');
      expect((hello['data']! as Map<String, Object?>)['last_seq'], 0);
      await live();
      expect(await logKinds(), containsAllInOrder(['paused', 'resumed']));
    });

    test(
      'a socket the system cuts in the background counts as a pause',
      () async {
        await engine.start();

        await live();

        engine.setForeground(false);

        await ws.connections.first.close(1011, 'network cut');

        await eventually(() => engine.status.phase == ConnectionPhase.offline);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(
          ws.connections,
          hasLength(1),
          reason: 'no retries in the background',
        );

        engine.setForeground(true);

        final hello = await (await ws.nextConnection(index: 1)).next('hello');

        expect((hello['data']! as Map<String, Object?>)['last_seq'], 0);

        await live();

        final kinds = await logKinds();

        expect(kinds, containsAllInOrder(['paused', 'resumed', 'connected']));

        expect(kinds, isNot(contains('closed')));
      },
    );

    test('a short trip to the background keeps the socket', () async {
      await engine.start();
      await live();
      engine.setForeground(false);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      engine.setForeground(true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(ws.connections, hasLength(1));
      expect(engine.status.isLive, isTrue);
    });
  });

  test(
    'a recorded run applied through the socket ends like the reducer test',
    () async {
      final rec = Recording('tool');
      ws.epoch = rec.epoch;
      await engine.start();
      await live();
      final conn = ws.connections.first;
      for (final e in rec.incoming.where((f) => f['seq'] is int)) {
        conn.sendRaw({
          ...e,
          'seq': (e['seq']! as int) - rec.events.first.seq + 1,
        });
      }
      await eventually(
        () async => (await db.readSyncState()).lastSeq == rec.events.length,
        reason: 'all events stored',
      );
      await engine.settle();
      final run = await db.select(db.runs).getSingle();
      expect(run.status, 'completed');
      expect(engine.live.snapshot(), isEmpty);
    },
  );

  group('backoff', () {
    test('doubles from the minimum, capped, jittered over the upper half', () {
      final r = Random(7);
      for (var attempt = 1; attempt <= 10; attempt++) {
        final base = min(1000 * pow(2, attempt - 1), 30000).toInt();
        for (var i = 0; i < 50; i++) {
          final d = backoffDelay(attempt, random: r).inMilliseconds;
          expect(
            d,
            inInclusiveRange(base ~/ 2, base),
            reason: 'attempt $attempt',
          );
        }
      }
      expect(
        backoffDelay(50, random: r),
        lessThanOrEqualTo(const Duration(seconds: 30)),
      );
    });
  });

  test('webSocketUri maps the scheme and keeps the port', () {
    expect(
      webSocketUri(
        Uri.parse('https://archlinux.example.ts.net'),
        '/api/v1/ws',
      ).toString(),
      'wss://archlinux.example.ts.net/api/v1/ws',
    );
    expect(
      webSocketUri(Uri.parse('http://127.0.0.1:8701'), '/x').toString(),
      'ws://127.0.0.1:8701/x',
    );
  });
}
