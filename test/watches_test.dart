import 'package:delve/api/models/models.dart';
import 'package:delve/l10n/app_localizations.dart';
import 'package:delve/push/background.dart';
import 'package:delve/push/notification_spec.dart';
import 'package:delve/push/push_message.dart';
import 'package:delve/theme/delve_colors.dart';
import 'package:delve/ui/screens/settings_screen.dart';
import 'package:delve/ui/watch_text.dart';
import 'package:delve/ui/widgets/status_ui.dart';
import 'package:delve/ui/widgets/watch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'push_test.dart' show FakeNotifications;
import 'support/fake_server.dart';
import 'support/harness.dart';

final l = lookupAppLocalizations(const Locale('en'));

/// A watch from `samples.json` with [overrides] (snake_case keys).
Map<String, Object?> watchJson([Map<String, Object?> overrides = const {}]) => {
  ...FakeServer.sample('watch'),
  ...overrides,
};

Map<String, Object?> itemJson(
  int id, [
  Map<String, Object?> overrides = const {},
]) => {
  ...FakeServer.sample('watch_item'),
  'id': id,
  'item_id': 'ha:$id',
  'url': 'https://hardverapro.hu/apro/x$id/friss.html',
  ...overrides,
};

Watch watch([Map<String, Object?> overrides = const {}]) =>
    Watch.fromJson(watchJson(overrides));

final _now = DateTime.now().toUtc();
String _ago(Duration d) => _now.subtract(d).toIso8601String();

/// The four watches of design 21a.
List<Map<String, Object?>> fourWatches() => [
  watchJson({
    'last_check_at': _ago(const Duration(minutes: 10)),
    'next_run_at': _now.add(const Duration(hours: 5)).toIso8601String(),
  }),
  watchJson({
    'slug': 'doom',
    'name': 'Dr. Doom tickets',
    'source': 'cinemacity',
    'criteria': null,
    'hits': 0,
    'hits_24h': 0,
    'rejected': 0,
    'pending': 0,
  }),
  watchJson({
    'slug': 'bambu',
    'name': 'Bambu Lab P1S ár',
    'source': 'page',
    'schedule': 'every 360m',
    'last_status': 'error',
    'last_error_code': 'http_404',
    'last_error': 'Page not found (HTTP 404)',
    'errors_in_row': 3,
    'hits': 0,
    'hits_24h': 0,
  }),
  watchJson({
    'slug': 'deck',
    'name': 'Steam Deck OLED ≤140k',
    'state': 'paused',
    'stop_after_hit': true,
    'stopped_at': _ago(const Duration(days: 1)),
    'hits_24h': 0,
  }),
];

/// The detail's list (other pages stay in the tree under it).
final detailScroll = find.descendant(
  of: find.byKey(const Key('watch.detail')),
  matching: find.byType(Scrollable),
);

void main() {
  group('words', () {
    test('schedule, price, keywords, item meta', () {
      expect(
        watchScheduleText(l, '15 8,13,19 * * *'),
        'Every day at 08:15, 13:15 and 19:15',
      );
      expect(watchScheduleText(l, 'every 480m'), 'Every 8 hours');
      expect(watchScheduleText(l, 'every 60m'), 'Every hour');
      expect(watchScheduleText(l, 'every 45m'), 'Every 45 minutes');
      expect(priceText(watch()), '≤ 180 000 Ft');
      expect(
        priceText(watch({'min_price': 50000, 'max_price': null})),
        '≥ 50 000 Ft',
      );
      expect(priceText(watch({'max_price': null})), isNull);
      expect(
        keywordsText(
          l,
          watch({
            'any': ['gigabyte', 'asus'],
          }),
        ),
        '4070 super · any of gigabyte, asus · not bánya',
      );
      final item = WatchItem.fromJson(itemJson(1));
      expect(itemMeta(item), '165 000 Ft · Budapest XI.');
      expect(
        itemMeta(WatchItem.fromJson(itemJson(2, {'location': null}))),
        '165 000 Ft',
      );
    });

    test('a watch row says Error over the rest', () {
      final failing = watch({'last_status': 'error', 'state': 'paused'});
      expect(watchStatus(l, failing).label, 'Error');
      final stopped = watch({
        'state': 'paused',
        'stop_after_hit': true,
        'stopped_at': _ago(const Duration(hours: 2)),
      });
      expect(watchStatus(l, stopped).label, 'Stopped after hit');
      expect(watchStatus(l, watch({'state': 'paused'})).label, 'Paused');
      expect(watchStatus(l, watch()).label, 'Active');
    });

    test('item markers', () {
      String? word(Map<String, Object?> o) =>
          (itemMarker(l, WatchItem.fromJson(itemJson(1, o))) as StatusText?)
              ?.label;
      expect(word({}), isNull);
      expect(word({'reserved': true}), 'On hold');
      expect(word({'available_at': _ago(Duration.zero)}), 'Now available');
      expect(word({'verdict': 'error'}), "Couldn't judge");
      expect(word({'verdict': 'pending'}), 'Waiting for judge');
    });
  });

  test('the sample watch and item read as the server wrote them', () {
    final w = watch();
    expect((w.hits, w.hits24h, w.pending, w.rejected), (3, 2, 1, 2));
    expect(w.include, ['4070 super']);
    expect(w.exclude, ['bánya']);
    expect(w.maxPrice, 180000);
    expect((w.failing, w.paused, w.stoppedAfterHit), (false, false, false));
    final i = WatchItem.fromJson(itemJson(17));
    expect(
      (i.verdict, i.isHit, i.reserved, i.availableAgain),
      ('match', true, false, false),
    );
  });

  group('push', () {
    Map<String, Object?> data({String change = 'hit'}) => {
      'kind': 'watch',
      'change': change,
      'slug': 'rtx-4070-super-180k',
      'name': 'RTX 4070 Super ≤180k',
      'item': '17',
      'item_id': 'ha:8231467',
      'title': 'Gigabyte RTX 4070 Super Gaming OC 12G',
      'price': '165 000 Ft',
      'reason': 'Nem említ bányászást.',
      'url': 'https://hardverapro.hu/apro/x/friss.html',
      'reserved': 'false',
    };

    test('parsed into a notification on the Watches channel', () {
      final p = PushMessage.parse(data())! as WatchPush;
      expect(
        (p.slug, p.item, p.available, p.reserved),
        ('rtx-4070-super-180k', 17, false, false),
      );
      final n = watchNotification(l, p);
      expect(n.channel, NotifyChannel.watches);
      expect(n.title, 'Watch · RTX 4070 Super ≤180k');
      expect(
        n.body,
        'Gigabyte RTX 4070 Super Gaming OC 12G · 165 000 Ft\n'
        'Nem említ bányászást.',
      );
      expect(
        [for (final a in n.actions) a.id],
        [NotifyActions.openLink, NotifyActions.open],
      );
      expect(n.actions.every((a) => a.opensApp), isTrue);
      final target = PushTarget.decode(n.payload)!;
      expect(
        (target.kind, target.slug, target.url),
        (
          'watch',
          'rtx-4070-super-180k',
          'https://hardverapro.hu/apro/x/friss.html',
        ),
      );

      // "now available" replaces the hit's notification
      final a = watchNotification(
        l,
        PushMessage.parse(data(change: 'available'))! as WatchPush,
      );
      expect(a.title, 'Now available · RTX 4070 Super ≤180k');
      expect(a.id, n.id);
    });

    test(
      'a hit shows in the foreground too; broken ones are ignored',
      () async {
        final n = FakeNotifications();
        await handlePush(data(), n, now: DateTime.now(), foreground: true);
        expect(n.shown, hasLength(1));
        expect(PushMessage.parse({...data()}..remove('url')), isNull);
        expect(PushMessage.parse({...data(), 'item': 'x'}), isNull);
      },
    );
  });

  group('Watches (21a)', () {
    Future<TestEnv> openWatches(
      WidgetTester t, {
      List<Map<String, Object?>>? watches,
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async => env.server.json('GET', '/api/v1/watches', {
          'data': watches ?? fourWatches(),
        }),
      );
      env.server.json('GET', '/api/v1/watches/rtx-4070-super-180k/items', {
        'data': <Object?>[],
        'next_before': null,
      });
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Watches'));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('rows: name, source and schedule, state, new hits, error', (
      t,
    ) async {
      final env = await openWatches(t);
      expect(env.server.calls, contains('GET /api/v1/watches'));
      expect(find.text('RTX 4070 Super ≤180k'), findsOneWidget);
      expect(
        find.text('Hardverapró · Every day at 08:15, 13:15 and 19:15'),
        findsNWidgets(2),
      );
      expect(find.text('Web page · Every 6 hours'), findsOneWidget);
      expect(find.text('Active'), findsNWidgets(2));
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Stopped after hit'), findsOneWidget);
      expect(find.text('2 new'), findsOneWidget);
      expect(
        find.text('Page not found (HTTP 404) · 3 errors in a row'),
        findsOneWidget,
      );
      // states are coloured words on the right edge
      final row = find.byKey(const Key('watch.row.bambu'));
      expect(
        t.widget<Text>(find.text('Error')).style!.color,
        DelveColors.dark.alertFg,
      );
      final state = find.byKey(const Key('watch.state.bambu'));
      expect(t.getTopRight(state).dx, t.getTopRight(row).dx - 16);
      expect(find.byKey(const Key('watches.new')), findsOneWidget);
    });

    testWidgets('empty: New watch opens a chat with the hint', (t) async {
      await openWatches(t, watches: []);
      expect(find.text('No watches yet'), findsOneWidget);
      expect(find.byKey(const Key('watches.new')), findsNothing);
      await t.tap(find.byKey(const Key('watches.emptyNew')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chat.watchHint')), findsOneWidget);
      await t.tap(find.byKey(const Key('chat.watchExample.1')));
      await t.pump();
      final field = t.widget<TextField>(
        find.byKey(const Key('composer.field')),
      );
      expect(
        field.controller!.text,
        'Tell me when tickets for <film> are on sale at Cinema City.',
      );
      expect(
        field.controller!.selection.textInside(field.controller!.text),
        '<film>',
      );
      // the hint goes once there is text
      expect(find.byKey(const Key('chat.watchHint')), findsNothing);
    });

    testWidgets('a big text size does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openWatches(t);
      expect(t.takeException(), isNull);
    });
  });

  group('Watch detail (21b)', () {
    Future<TestEnv> openDetail(
      WidgetTester t, {
      Map<String, Object?> overrides = const {},
      List<Map<String, Object?>>? hits,
      List<Map<String, Object?>>? rejects,
    }) async {
      final env = await pumpDelve(
        t,
        before: (env) async {
          env.server
            ..json('GET', '/api/v1/watches', {
              'data': [watchJson(overrides)],
            })
            ..on('GET', '/api/v1/watches/rtx-4070-super-180k/items', (r) {
              final v = r.uri.queryParameters['verdict'];
              return FakeReply(200, {
                'data': v == 'hits'
                    ? hits ??
                          [
                            itemJson(17),
                            itemJson(16, {
                              'title': 'MSI RTX 4070 Super Ventus 2X',
                              'available_at': _ago(Duration.zero),
                            }),
                            itemJson(15, {
                              'title': 'ASUS Dual RTX 4070 Super EVO',
                              'reserved': true,
                            }),
                          ]
                    : rejects ??
                          [
                            itemJson(14, {
                              'title': 'Zotac RTX 4070 Super – bányából',
                              'verdict': 'reject',
                              'reason': 'A hirdetés szerint bányában futott.',
                            }),
                          ],
                'next_before': null,
              });
            });
        },
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      await t.tap(find.text('Watches'));
      await t.pumpAndSettle();
      await t.tap(find.text('RTX 4070 Super ≤180k'));
      await t.pumpAndSettle();
      return env;
    }

    testWidgets('condition, facts, hits with markers, rejected collapsed', (
      t,
    ) async {
      final env = await openDetail(t);
      expect(
        {
          for (final r in env.server.requests)
            if (r.uri.path.endsWith('/items')) r.uri.queryParameters['verdict'],
        },
        {'hits', 'reject,error'},
      );
      expect(
        find.text(
          'Semmi nem utal rá, hogy a videokártyát bányászásra használták.',
        ),
        findsOneWidget,
      );
      expect(find.text('≤ 180 000 Ft'), findsOneWidget);
      expect(find.text('1 listing waits for the judge'), findsOneWidget);
      expect(find.text('HITS · 3'), findsOneWidget);
      expect(find.text('2 in the last 24 h'), findsOneWidget);
      await t.scrollUntilVisible(
        find.byKey(const Key('watch.item.15')),
        200,
        scrollable: detailScroll,
      );
      expect(
        find.text('Nem említ bányászást; garanciális, számlával.'),
        findsWidgets,
      );
      expect(find.text('Now available'), findsOneWidget);
      expect(find.text('On hold'), findsOneWidget);
      // collapsed: the reject is not built until opened
      expect(find.text('A hirdetés szerint bányában futott.'), findsNothing);
      await t.scrollUntilVisible(
        find.byKey(const Key('watch.rejectedToggle')),
        200,
        scrollable: detailScroll,
      );
      expect(find.text('Rejected (2)'), findsOneWidget);
      await t.tap(find.byKey(const Key('watch.rejectedToggle')));
      await t.pumpAndSettle();
      expect(find.text('A hirdetés szerint bányában futott.'), findsOneWidget);
    });

    testWidgets('a hit opens its link; long-press copies it', (t) async {
      final env = await openDetail(t);
      await t.scrollUntilVisible(
        find.byKey(const Key('watch.item.open.17')),
        200,
        scrollable: detailScroll,
      );
      await t.tap(find.byKey(const Key('watch.item.open.17')));
      await t.pumpAndSettle();
      expect(env.links.opened, [
        Uri.parse('https://hardverapro.hu/apro/x17/friss.html'),
      ]);
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
      await t.longPress(find.byKey(const Key('watch.item.17')));
      await t.pumpAndSettle();
      expect(copied, 'https://hardverapro.hu/apro/x17/friss.html');
      expect(find.text('Link copied'), findsOneWidget);
      // the browser does not take it: copied, and said so
      env.links.result = false;
      await t.tap(find.byKey(const Key('watch.item.open.17')));
      await t.pumpAndSettle();
      expect(find.textContaining("Couldn't open the link"), findsOneWidget);
    });

    testWidgets('Pause goes to the server; Change in chat opens a draft', (
      t,
    ) async {
      final env = await openDetail(t);
      env.server.on(
        'POST',
        '/api/v1/watches/rtx-4070-super-180k/pause',
        (_) => FakeReply(200, watchJson({'state': 'paused'})),
      );
      await t.tap(find.byKey(const Key('watch.pause')));
      await t.pumpAndSettle();
      expect(
        env.server.calls,
        contains('POST /api/v1/watches/rtx-4070-super-180k/pause'),
      );
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('— paused'), findsOneWidget);

      await t.tap(find.byKey(const Key('watch.change')));
      await t.pumpAndSettle();
      final field = t.widget<TextField>(
        find.byKey(const Key('composer.field')),
      );
      expect(
        field.controller!.text,
        'Change the watch “RTX 4070 Super ≤180k”: ',
      );
      expect(find.byKey(const Key('chat.watchHint')), findsNothing);
    });

    testWidgets('an error: the banner with Fix in chat, last check in alert', (
      t,
    ) async {
      await openDetail(
        t,
        overrides: {
          'last_status': 'error',
          'last_error': 'Page not found (HTTP 404)',
          'errors_in_row': 3,
        },
        hits: [],
        rejects: [],
      );
      expect(
        find.text('Page not found (HTTP 404) · 3 errors in a row'),
        findsOneWidget,
      );
      expect(find.text('No hits yet.'), findsOneWidget);
      await t.tap(find.text('Fix in chat'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const Key('composer.field')))
            .controller!
            .text,
        'The watch “RTX 4070 Super ≤180k” keeps failing '
        '(Page not found (HTTP 404)). Check it and fix it.',
      );
    });

    testWidgets('stopped after its first hit: the banner resumes it', (
      t,
    ) async {
      final env = await openDetail(
        t,
        overrides: {
          'state': 'paused',
          'stop_after_hit': true,
          'stopped_at': _ago(const Duration(hours: 3)),
        },
      );
      expect(find.byKey(const Key('watch.stoppedBanner')), findsOneWidget);
      env.server.on(
        'POST',
        '/api/v1/watches/rtx-4070-super-180k/resume',
        (_) => FakeReply(200, watchJson()),
      );
      await t.tap(find.text('Resume').first);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('watch.stoppedBanner')), findsNothing);
      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets('a big text size does not overflow', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openDetail(t);
      expect(t.takeException(), isNull);
    });
  });

  group('Dashboard card (21d)', () {
    testWidgets('the newest hits, Open link, the header opens the list', (
      t,
    ) async {
      final env = await pumpDelve(
        t,
        before: (env) async {
          env.server
            ..json('GET', '/api/v1/watches', {'data': fourWatches()})
            ..json('GET', '/api/v1/watches/rtx-4070-super-180k/items', {
              'data': [
                itemJson(17, {'seen_at': _ago(const Duration(minutes: 5))}),
                itemJson(16, {
                  'title': 'MSI RTX 4070 Super Ventus 2X',
                  'seen_at': _ago(const Duration(minutes: 10)),
                  'available_at': _ago(Duration.zero),
                }),
              ],
              'next_before': null,
            })
            ..json('GET', '/api/v1/watches/deck/items', {
              'data': [
                itemJson(9, {
                  'title': 'Steam Deck OLED 512 GB',
                  'seen_at': _ago(const Duration(days: 1)),
                }),
              ],
              'next_before': null,
            });
        },
      );
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      final card = find.byKey(const Key('dashboard.watches'));
      await t.scrollUntilVisible(card, 200);
      Finder inCard(Finder f) => find.descendant(of: card, matching: f);
      // active = not paused (the failing one is still checked)
      expect(inCard(find.text('3 active')), findsOneWidget);
      expect(
        inCard(find.textContaining('Now available', findRichText: true)),
        findsOneWidget,
      );
      expect(inCard(find.text('Steam Deck OLED 512 GB')), findsOneWidget);
      // newest first
      expect(
        t.getTopLeft(inCard(find.textContaining('Gigabyte'))).dy,
        lessThan(t.getTopLeft(inCard(find.text('Steam Deck OLED 512 GB'))).dy),
      );
      await t.tap(inCard(find.byKey(const Key('dashboard.watches.hit.17'))));
      await t.pumpAndSettle();
      expect(env.links.opened.single.path, '/apro/x17/friss.html');
      await t.tap(find.byKey(const Key('dashboard.watches.open')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('watch.row.doom')), findsOneWidget);
    });

    testWidgets('no watches, no card', (t) async {
      await pumpDelve(t);
      await t.tap(find.text('Dashboard').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('dashboard.watches')), findsNothing);
    });
  });

  testWidgets('Settings → Watch hits saves on the server', (t) async {
    final env = await pumpDelve(t);
    env.server.on(
      'PATCH',
      '/api/v1/devices/me',
      (_) => FakeReply(200, {
        ...FakeServer.device,
        'notify': {
          ...(FakeServer.device['notify']! as Map<String, Object?>),
          'watches': false,
        },
      }),
    );
    await t.tap(find.text('More'));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    final key = find.byKey(const Key('settings.notify.watches'));
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
    expect(find.text('Watch hits'), findsOneWidget);
    await t.tap(key);
    await t.pumpAndSettle();
    final patch = env.server.requests.lastWhere((r) => r.method == 'PATCH');
    expect(patch.data, {
      'notify': {'watches': false},
    });
  });
}
