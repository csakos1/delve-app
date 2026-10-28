import 'package:delve/app/app.dart';
import 'package:delve/app/chat.dart';
import 'package:delve/app/providers.dart';
import 'package:delve/app/session.dart';
import 'package:delve/attachments/attachment_store.dart';
import 'package:delve/attachments/image_prep.dart';
import 'package:delve/attachments/picker.dart';
import 'package:delve/data/credentials.dart';
import 'package:delve/data/db/database.dart';
import 'package:delve/push/push_controller.dart';
import 'package:delve/push/push_providers.dart';
import 'package:delve/share/share_channel.dart';
import 'package:delve/sync/connection_status.dart';
import 'package:delve/sync/sync_providers.dart';
import 'package:delve/ui/links.dart';
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
  TestEnv({
    Credentials? credentials,
    this.status,
    this.actions,
    this.push,
    this.attachments,
    this.share,
  }) : db = memoryDb(),
       store = MemoryCredentialStore(credentials),
       server = FakeServer();

  final AppDatabase db;
  final MemoryCredentialStore store;
  final FakeServer server;

  /// Links the app opened (url_launcher is off in tests).
  final LinkLog links = LinkLog();

  /// Connection state the screens see (the socket itself is off in tests).
  final ConnectionStatus? status;

  /// What the chat screen sends (the socket is off in tests).
  final ChatActions? actions;

  /// Push on this phone as Settings sees it (push itself is off in tests).
  final PushState? push;

  /// Pickers, resizing and uploads of attachments (plugins are off in tests).
  final AttachmentFakes? attachments;

  /// Shares from other apps (the platform channel is off in tests).
  final ShareSource? share;

  // (The override list is written out twice: its element type lives in a
  // different library across Riverpod versions.)
  ProviderScope app(Widget child) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      credentialStoreProvider.overrideWithValue(store),
      httpAdapterProvider.overrideWithValue(server),
      appInfoProvider.overrideWith((ref) async => testAppInfo),
      syncEnabledProvider.overrideWithValue(false), // no socket here
      pushEnabledProvider.overrideWithValue(false), // no Firebase here
      shareSourceProvider.overrideWithValue(share), // no platform channel
      linkOpenerProvider.overrideWithValue(links.open), // no browser
      if (push case final p?)
        pushStateProvider.overrideWith((ref) => Stream.value(p)),
      if (status case final s?)
        connectionStatusProvider.overrideWith((ref) => Stream.value(s)),
      if (actions case final a?) chatActionsProvider.overrideWithValue(a),
      if (attachments case final f?) ...[
        attachmentApiProvider.overrideWithValue(f.api),
        attachmentPickerProvider.overrideWithValue(f.picker),
        imagePrepProvider.overrideWithValue(f.prep),
      ],
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
        syncEnabledProvider.overrideWithValue(false), // no socket here
        pushEnabledProvider.overrideWithValue(false), // no Firebase here
        shareSourceProvider.overrideWithValue(share), // no platform channel
        linkOpenerProvider.overrideWithValue(links.open), // no browser
        if (push case final p?)
          pushStateProvider.overrideWith((ref) => Stream.value(p)),
        if (status case final s?)
          connectionStatusProvider.overrideWith((ref) => Stream.value(s)),
        if (actions case final a?) chatActionsProvider.overrideWithValue(a),
        if (attachments case final f?) ...[
          attachmentApiProvider.overrideWithValue(f.api),
          attachmentPickerProvider.overrideWithValue(f.picker),
          imagePrepProvider.overrideWithValue(f.prep),
        ],
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
Future<TestEnv> pumpDelve(
  WidgetTester tester, {
  bool paired = true,
  ConnectionStatus? status,
  ChatActions? actions,
  PushState? push,
  AttachmentFakes? attachments,
  ShareSource? share,
  Future<void> Function(TestEnv env)? before,
  bool settle = true,
}) async {
  final env = TestEnv(
    credentials: paired ? pairedCredentials() : null,
    status: status,
    actions: actions,
    push: push,
    attachments: attachments,
    share: share,
  );
  addTearDown(env.dispose);
  setDesignSize(tester);
  if (before != null) await tester.runAsync(() => before(env));
  await tester.pumpWidget(env.app(const DelveApp()));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  return env;
}

/// The attachment plugins and uploads for a test.
class AttachmentFakes {
  AttachmentFakes({
    required this.api,
    required this.picker,
    required this.prep,
  });
  final AttachmentApi api;
  final AttachmentPicker picker;
  final ImagePrep prep;
}

/// The links a test's app opened; [result] is what the "browser" answers.
class LinkLog {
  final List<Uri> opened = [];
  bool result = true;

  Future<bool> open(Uri url) async {
    opened.add(url);
    return result;
  }
}
