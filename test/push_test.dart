import 'dart:async';

import 'package:delve/api/rest_client.dart';
import 'package:delve/data/credentials.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/push/background.dart';
import 'package:delve/push/local_notifications.dart';
import 'package:delve/push/notification_spec.dart';
import 'package:delve/push/push_controller.dart';
import 'package:delve/push/push_message.dart';
import 'package:delve/push/push_transport.dart';
import 'package:delve/ui/format.dart';
import 'package:delve/ui/widgets/status_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/harness.dart';

final l = lookupAppLocalizations(const Locale('en'));
final now = DateTime.utc(2026, 10, 21, 10);

Map<String, Object?> approvalData({
  String status = 'pending',
  String title = 'Kernel and CPU count',
}) => {
  'kind': 'approval',
  'request_id': 'apr_3c9d1e2f',
  'conversation_id': 'c_1',
  'title': title,
  'action_class': 'delete_kill',
  'command': 'rm -r /tmp/x',
  'status': status,
  'hermes_deadline': now.add(const Duration(minutes: 4)).toIso8601String(),
  'expires_at': now.add(const Duration(minutes: 30)).toIso8601String(),
};

Map<String, Object?> approvalJson(String requestId, String status) => {
  'request_id': requestId,
  'run_id': 'run_1',
  'conversation_id': 'c_1',
  'command': 'rm -r /tmp/x',
  'description': null,
  'pattern_keys': <String>[],
  'action_class': 'delete_kill',
  'status': status,
  'choice': status == 'denied' ? 'deny' : 'once',
  'choices': ['once', 'session', 'deny'],
  'decided_by': 'pixel',
  'created_at': now.toIso8601String(),
  'hermes_deadline': now.add(const Duration(minutes: 5)).toIso8601String(),
  'expires_at': now.add(const Duration(minutes: 30)).toIso8601String(),
  'responded_at': now.toIso8601String(),
};

Map<String, Object?> runDoneData({String status = 'completed'}) => {
  'kind': 'run_done',
  'conversation_id': 'c_1',
  'run_id': 'run_1',
  'title': 'Kernel and CPU count',
  'status': status,
  'preview': 'Kernel 7.2.11, 24 CPUs.',
};

class FakeNotifications implements PhoneNotifications {
  final shown = <NotificationSpec>[];
  final cancelled = <int>[];
  int cancelAllCalls = 0;
  bool isEnabled = true;
  bool grantOnRequest = true;
  int permissionRequests = 0;
  NotificationTap? launch;
  final _taps = StreamController<NotificationTap>.broadcast();

  void tap(NotificationTap t) => _taps.add(t);

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  Future<NotificationTap?> launchTap() async => launch;

  @override
  Future<bool> enabled() async => isEnabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    isEnabled = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<void> show(NotificationSpec spec) async => shown.add(spec);

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelAll() async => cancelAllCalls++;
}

class FakeTransport implements PushTransport {
  FakeTransport({this.available = true, this.initialToken = 'tok1'});
  final bool available;
  final String? initialToken;

  /// Tokens FCM hands out: the first after register(), later ones on refresh.
  final refresh = StreamController<String>.broadcast();
  final incoming = StreamController<Map<String, Object?>>.broadcast();

  @override
  Future<bool> init() async => available;

  bool failRegister = false;

  @override
  Future<void> register() async {
    if (failRegister) throw StateError('API disabled');
    if (initialToken case final t?) refresh.add(t);
  }

  @override
  Stream<String> get tokens => refresh.stream;

  @override
  Stream<Map<String, Object?>> get messages => incoming.stream;

  Future<void> close() async {
    await refresh.close();
    await incoming.close();
  }
}

Future<void> flush() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('messages', () {
    test('parse every kind; malformed ones are ignored', () {
      final a = PushMessage.parse(approvalData())! as ApprovalPush;
      expect(
        (a.requestId, a.conversationId, a.actionClass, a.stoppedWaiting),
        ('apr_3c9d1e2f', 'c_1', 'delete_kill', false),
      );
      expect(a.hermesDeadline, now.add(const Duration(minutes: 4)));
      final r = PushMessage.parse({
        'kind': 'approval_resolved',
        'request_id': 'apr_1',
        'status': 'denied',
      });
      expect((r! as ApprovalResolvedPush).requestId, 'apr_1');
      final d =
          PushMessage.parse(runDoneData(status: 'failed'))! as RunDonePush;
      expect((d.runId, d.failed), ('run_1', true));

      expect(PushMessage.parse({}), isNull);
      expect(PushMessage.parse({'kind': 'water'}), isNull);
      expect(PushMessage.parse({...approvalData(), 'command': null}), isNull);
      expect(PushMessage.parse({'kind': 'run_done', 'run_id': 'r'}), isNull);
    });

    test('notification ids are stable and positive', () {
      expect(notificationId('apr_3c9d1e2f'), 1774532170);
      expect(notificationId('run_1'), 1339197210);
    });

    test('a target survives the payload round trip', () {
      const t = PushTarget(
        kind: 'approval',
        conversationId: 'c_1',
        requestId: 'apr_1',
      );
      final back = PushTarget.decode(t.encode())!;
      expect(
        (back.kind, back.conversationId, back.requestId),
        ('approval', 'c_1', 'apr_1'),
      );
      expect(PushTarget.decode('nonsense'), isNull);
      expect(PushTarget.decode(null), isNull);
    });
  });

  group('notifications (design 18)', () {
    test('approval: class, command, chat, countdown, three actions', () {
      final p = PushMessage.parse(approvalData())! as ApprovalPush;
      final n = approvalNotification(l, p, now);
      expect(n.id, notificationId('apr_3c9d1e2f'));
      expect(n.channel, NotifyChannel.approvals);
      expect(n.title, 'Approval needed · delete / kill');
      expect(n.body, 'rm -r /tmp/x\nAgent waits · Kernel and CPU count');
      expect(n.countdownTo, p.hermesDeadline);
      expect(n.timeoutAt, p.expiresAt);
      expect(
        [for (final a in n.actions) (a.id, a.label, a.opensApp)],
        [
          ('allow_once', 'Allow once', true), // unlock first
          ('deny', 'Deny', false), // also from the lock screen
          ('open', 'Open', true),
        ],
      );
      final target = PushTarget.decode(n.payload)!;
      expect((target.kind, target.requestId), ('approval', 'apr_3c9d1e2f'));
    });

    test('approval after the agent stopped waiting', () {
      final p =
          PushMessage.parse(approvalData(status: 'expired_in_hermes'))!
              as ApprovalPush;
      final n = approvalNotification(l, p, now);
      expect(n.title, 'Agent stopped waiting · delete / kill');
      final until = clockTime(p.expiresAt!, now);
      expect(
        n.body,
        'rm -r /tmp/x\nApprovable until $until · Kernel and CPU count',
      );
      expect(n.countdownTo, isNull);
      expect(n.actions, hasLength(3));
    });

    test('approval of a chat without a title yet', () {
      final p = PushMessage.parse(approvalData(title: ''))! as ApprovalPush;
      expect(approvalNotification(l, p, now).body, 'rm -r /tmp/x\nAgent waits');
    });

    test('finished and failed runs', () {
      final done = runDoneNotification(
        l,
        PushMessage.parse(runDoneData())! as RunDonePush,
      );
      expect(done.title, 'Run finished · Kernel and CPU count');
      expect(done.body, 'Kernel 7.2.11, 24 CPUs.');
      expect(done.channel, NotifyChannel.runs);
      expect([for (final a in done.actions) a.id], ['open']);
      expect(PushTarget.decode(done.payload)!.kind, 'run_done');
      final failed = runDoneNotification(
        l,
        PushMessage.parse(runDoneData(status: 'failed'))! as RunDonePush,
      );
      expect(failed.title, 'Run failed · Kernel and CPU count');
    });
  });

  group('handlePush', () {
    test('shows, replaces and removes', () async {
      final n = FakeNotifications();
      await handlePush(approvalData(), n, now: now);
      await handlePush(
        {
          'kind': 'approval_resolved',
          'request_id': 'apr_3c9d1e2f',
          'status': 'approved_once',
        },
        n,
        now: now,
      );
      await handlePush(runDoneData(), n, now: now);
      await handlePush({'kind': 'nope'}, n, now: now);
      expect(
        [for (final s in n.shown) s.id],
        [notificationId('apr_3c9d1e2f'), notificationId('run_1')],
      );
      expect(n.cancelled, [notificationId('apr_3c9d1e2f')]);
    });

    test(
      'in the foreground: no finished run, no approval of the open chat',
      () async {
        final n = FakeNotifications();
        await handlePush(runDoneData(), n, now: now, foreground: true);
        await handlePush(
          approvalData(),
          n,
          now: now,
          foreground: true,
          visibleChat: 'c_1',
        );
        expect(n.shown, isEmpty);
        await handlePush(
          approvalData(),
          n,
          now: now,
          foreground: true,
          visibleChat: 'c_2',
        );
        expect(n.shown, hasLength(1));
      },
    );
  });

  group('Deny from the notification', () {
    late FakeServer server;
    late FakeNotifications n;
    late MemoryCredentialStore store;
    final payload = const PushTarget(
      kind: 'approval',
      conversationId: 'c_1',
      requestId: 'apr_1',
    ).encode();

    setUp(() {
      server = FakeServer();
      n = FakeNotifications();
      store = MemoryCredentialStore(pairedCredentials());
    });

    Future<bool> deny([String? action = 'deny']) => denyFromNotification(
      action,
      payload,
      store: store,
      notifications: n,
      adapter: server,
    );

    test('answers deny over REST and removes the notification', () async {
      server.json(
        'POST',
        '/api/v1/approvals/apr_1',
        approvalJson('apr_1', 'denied'),
      );
      expect(await deny(), isTrue);
      expect(server.calls, ['POST /api/v1/approvals/apr_1']);
      expect(server.requests.single.data, {'choice': 'deny'});
      expect(
        server.requests.single.headers['Authorization'],
        'Bearer dlv_test-token',
      );
      expect(n.cancelled, [notificationId('apr_1')]);
    });

    test('already answered elsewhere: just removed', () async {
      server.json(
        'POST',
        '/api/v1/approvals/apr_1',
        FakeServer.detail('not_answerable'),
        status: 409,
      );
      expect(await deny(), isFalse);
      expect(n.cancelled, [notificationId('apr_1')]);
      expect(n.shown, isEmpty);
    });

    test('a failure replaces it with the reason and Open', () async {
      server.json(
        'POST',
        '/api/v1/approvals/apr_1',
        FakeServer.detail('hermes_unavailable', 'Hermes is down'),
        status: 503,
      );
      expect(await deny(), isFalse);
      final s = n.shown.single;
      expect(s.id, notificationId('apr_1'));
      expect(s.title, startsWith("Couldn't answer: "));
      expect([for (final a in s.actions) a.id], ['open']);
      expect(n.cancelled, isEmpty);
    });

    test('other actions and unpaired phones do nothing', () async {
      expect(await deny('open'), isFalse);
      await store.clear();
      expect(await deny(), isFalse);
      expect(server.calls, isEmpty);
      expect(n.cancelled, [notificationId('apr_1')]);
    });
  });

  group('PushController', () {
    late FakeServer server;
    late FakeNotifications n;
    late FakeTransport transport;
    late PushController c;
    String? visible;

    PushController make({bool available = true}) {
      transport = FakeTransport(available: available);
      addTearDown(transport.close);
      c = PushController(
        api: DelveApi(
          server: testServer,
          token: 'dlv_test-token',
          adapter: server,
        ),
        transport: transport,
        notifications: n,
        visibleChat: () => visible,
        clock: () => now,
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      server = FakeServer();
      n = FakeNotifications();
      visible = null;
    });

    test('registers the token, again only when it changes', () async {
      await make().start();
      await flush(); // the token arrives on the stream
      expect(server.calls, ['PUT /api/v1/devices/me/fcm']);
      expect(server.requests.single.data, {'token': 'tok1'});
      transport.refresh
        ..add('tok1')
        ..add('tok2');
      await flush();
      expect(server.calls, hasLength(2));
      expect(server.requests.last.data, {'token': 'tok2'});
      expect((c.state.available, c.state.permitted), (true, true));
    });

    test(
      'a failed FCM registration leaves push off, no error escapes',
      () async {
        make();
        transport.failRegister = true;
        await c.start();
        expect(server.calls, isEmpty);
        expect(c.state.available, isFalse);
      },
    );

    test('without Firebase: nothing registered, Settings is told', () async {
      await make(available: false).start();
      expect(server.calls, isEmpty);
      expect(c.state.available, isFalse);
    });

    test('asks for the permission when it is off', () async {
      n
        ..isEnabled = false
        ..grantOnRequest = false;
      await make().start();
      expect(n.permissionRequests, 1);
      expect(c.state.permitted, isFalse);
      n.grantOnRequest = true;
      expect(await c.requestPermission(), isTrue);
      expect(c.state.permitted, isTrue);
    });

    test('foreground pushes skip the chat on screen', () async {
      await make().start();
      visible = 'c_1';
      transport.incoming.add(approvalData());
      await flush();
      expect(n.shown, isEmpty);
      visible = null;
      transport.incoming.add(approvalData());
      transport.incoming.add(runDoneData());
      await flush();
      expect([for (final s in n.shown) s.channel], [NotifyChannel.approvals]);
    });

    test('a tap opens the chat; the launch tap counts too', () async {
      n.launch = NotificationTap(
        payload: const PushTarget(
          kind: 'run_done',
          conversationId: 'c_9',
        ).encode(),
      );
      make();
      final events = <PushEvent>[];
      c.events.listen(events.add);
      await c.start();
      n.tap(
        NotificationTap(
          actionId: 'open',
          payload: PushTarget.decode(
            approvalNotification(
              l,
              PushMessage.parse(approvalData())! as ApprovalPush,
              now,
            ).payload,
          )!.encode(),
        ),
      );
      await flush();
      expect(
        [for (final e in events) (e is PushOpen, e.target.conversationId)],
        [(true, 'c_9'), (true, 'c_1')],
      );
    });

    test('Allow once answers once over REST', () async {
      server.json(
        'POST',
        '/api/v1/approvals/apr_1',
        approvalJson('apr_1', 'approved_once'),
      );
      make();
      final events = <PushEvent>[];
      c.events.listen(events.add);
      await c.start();
      n.tap(
        NotificationTap(
          actionId: 'allow_once',
          payload: const PushTarget(
            kind: 'approval',
            conversationId: 'c_1',
            requestId: 'apr_1',
          ).encode(),
        ),
      );
      await flush();
      expect(server.requests.lastWhere((r) => r.method == 'POST').data, {
        'choice': 'once',
      });
      expect(n.cancelled, [notificationId('apr_1')]);
      final e = events.single as PushAnswered;
      expect(e.approval.status, 'approved_once');
    });

    test('a failed Allow once is reported', () async {
      server.json(
        'POST',
        '/api/v1/approvals/apr_1',
        FakeServer.detail('expired'),
        status: 409,
      );
      make();
      final events = <PushEvent>[];
      c.events.listen(events.add);
      await c.start();
      n.tap(
        NotificationTap(
          actionId: 'allow_once',
          payload: const PushTarget(
            kind: 'approval',
            conversationId: 'c_1',
            requestId: 'apr_1',
          ).encode(),
        ),
      );
      await flush();
      expect(events.single, isA<PushAnswerFailed>());
      expect(n.cancelled, isEmpty);
    });
  });

  group('Settings → Notifications', () {
    Future<TestEnv> openSettings(WidgetTester t, {PushState? push}) async {
      final env = await pumpDelve(
        t,
        push: push ?? const PushState(available: true, permitted: true),
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();
      return env;
    }

    bool switchOn(WidgetTester t, String key) =>
        t.widget<Switch>(find.byKey(Key('settings.notify.$key'))).value;

    bool switchEnabled(WidgetTester t, String key) =>
        t.widget<Switch>(find.byKey(Key('settings.notify.$key'))).onChanged !=
        null;

    testWidgets('four switches from the server; the brief arrives later', (
      t,
    ) async {
      await openSettings(t);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(switchOn(t, 'approvals'), isTrue);
      expect(switchOn(t, 'run_done'), isTrue);
      expect(switchOn(t, 'water'), isFalse);
      expect(switchEnabled(t, 'approvals'), isTrue);
      expect(switchEnabled(t, 'water'), isTrue);
      expect(switchEnabled(t, 'brief'), isFalse);
      expect(find.text('After each scheduled reading'), findsOneWidget);
      expect(find.text('Comes with schedules'), findsOneWidget);
      expect(find.byType(StatusBanner), findsNothing);
    });

    testWidgets('a switch saves on the server', (t) async {
      final env = await openSettings(t);
      env.server.on('PATCH', '/api/v1/devices/me', (r) {
        env.server.json('GET', '/api/v1/devices/me', {
          ...FakeServer.device,
          'notify': {
            'approvals': true,
            'run_done': false,
            'water': false,
            'brief': false,
          },
        });
        return FakeReply(200, {
          ...FakeServer.device,
          'notify': {
            'approvals': true,
            'run_done': false,
            'water': false,
            'brief': false,
          },
        });
      });
      await t.tap(find.byKey(const Key('settings.notify.run_done')));
      await t.pumpAndSettle();
      final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
      expect(patch.data, {
        'notify': {'run_done': false},
      });
      expect(switchOn(t, 'run_done'), isFalse);
    });

    testWidgets('a failed save flips back and says why', (t) async {
      final env = await openSettings(t);
      env.server.json(
        'PATCH',
        '/api/v1/devices/me',
        FakeServer.detail('boom', 'boom'),
        status: 500,
      );
      await t.tap(find.byKey(const Key('settings.notify.approvals')));
      await t.pumpAndSettle();
      expect(switchOn(t, 'approvals'), isTrue);
      expect(find.textContaining("Couldn't save"), findsOneWidget);
    });

    testWidgets('banners: no permission, no Firebase, server cannot push', (
      t,
    ) async {
      await openSettings(
        t,
        push: const PushState(available: true, permitted: false),
      );
      expect(
        find.text('Notifications are off for Delve on this phone.'),
        findsOneWidget,
      );
      expect(find.text('Allow'), findsOneWidget);
    });

    testWidgets('a build without Firebase says so', (t) async {
      await openSettings(t, push: const PushState(available: false));
      expect(
        find.text(
          "This build can't receive notifications (no Firebase configuration).",
        ),
        findsOneWidget,
      );
    });

    testWidgets('a server without a Firebase key says so', (t) async {
      final env = await pumpDelve(
        t,
        push: const PushState(available: true, permitted: true),
      );
      env.server.json('GET', '/api/v1/devices/me', {
        ...FakeServer.device,
        'push': false,
      });
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();
      expect(
        find.text("The server can't send notifications yet (no Firebase key)."),
        findsOneWidget,
      );
    });
  });

  group('water level', () {
    Map<String, Object?> waterData({String trend = '-2'}) => {
      'kind': 'card',
      'card_id': 'k1',
      'type': 'water',
      'severity': 'info',
      'station': 'Siófok',
      'level_cm': '98',
      'lake_avg_cm': '101',
      'trend_cm_24h': trend,
      'lake_avg_trend_cm_24h': '',
      'measured_at': '2026-10-20T18:00:00+00:00',
    };

    test('parses; other card types and broken ones are ignored', () {
      final w = PushMessage.parse(waterData())! as WaterPush;
      expect(
        (w.station, w.levelCm, w.lakeAvgCm, w.trendCm),
        ('Siófok', 98.0, 101.0, -2.0),
      );
      expect(PushMessage.parse({...waterData(), 'type': 'disk'}), isNull);
      expect(PushMessage.parse({...waterData(), 'level_cm': ''}), isNull);
    });

    test('one notification, replaced by the next reading', () {
      final n = waterNotification(
        l,
        PushMessage.parse(waterData())! as WaterPush,
      );
      expect(n.title, 'Water level · Siófok 98 cm');
      expect(n.body, 'Lake average 101 cm · \u22122 cm vs yesterday');
      expect(n.channel, NotifyChannel.cards);
      expect(n.id, notificationId('card:water'));
      final target = PushTarget.decode(n.payload)!;
      expect((target.kind, target.conversationId), ('card', null));
      final rising = waterNotification(
        l,
        PushMessage.parse(waterData(trend: '1'))! as WaterPush,
      );
      expect(rising.body, endsWith('+1 cm vs yesterday'));
    });

    test('shown in the background only', () async {
      final n = FakeNotifications();
      await handlePush(waterData(), n, now: now, foreground: true);
      expect(n.shown, isEmpty);
      await handlePush(waterData(), n, now: now);
      expect(n.shown.single.channel, NotifyChannel.cards);
    });
  });
}
