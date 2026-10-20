import 'package:delve/app/app.dart';
import 'package:delve/app/providers.dart';
import 'package:delve/app/session.dart';
import 'package:delve/data/credentials.dart';
import 'package:delve/data/db/database.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

final testServer = Uri.parse('https://archlinux.example.ts.net');

Credentials pairedCredentials() => Credentials(
  server: testServer,
  token: 'dlv_test-token',
  deviceId: '0f5e2c3a-1b2d-4e6f-8a9b-0c1d2e3f4a5b',
  deviceName: 'pixel',
  pairedAt: DateTime.utc(2026, 10, 12, 18),
);

const testAppInfo = AppInfo('0.1.0', '1');

/// Everything a test needs to drive the app and look behind it.
class TestEnv {
  TestEnv({Credentials? credentials})
    : db = memoryDb(),
      store = MemoryCredentialStore(credentials),
      server = FakeServer();

  final AppDatabase db;
  final MemoryCredentialStore store;
  final FakeServer server;

  // (The override list is written out twice: its element type lives in a
  // different library across Riverpod versions.)
  ProviderScope app(Widget child) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      credentialStoreProvider.overrideWithValue(store),
      httpAdapterProvider.overrideWithValue(server),
      appInfoProvider.overrideWith((ref) async => testAppInfo),
    ],
    child: child,
  );

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        credentialStoreProvider.overrideWithValue(store),
        httpAdapterProvider.overrideWithValue(server),
        appInfoProvider.overrideWith((ref) async => testAppInfo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> dispose() => db.close();
}

/// The design's phone (448 × 998 dp) instead of the 800 × 600 default.
void setDesignSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(448 * 3, 998 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps the whole app; [paired] starts with stored credentials.
Future<TestEnv> pumpDelve(WidgetTester tester, {bool paired = true}) async {
  final env = TestEnv(credentials: paired ? pairedCredentials() : null);
  addTearDown(env.dispose);
  setDesignSize(tester);
  await tester.pumpWidget(env.app(const DelveApp()));
  await tester.pumpAndSettle();
  return env;
}
