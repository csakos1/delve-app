import 'package:delve/data/db/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  testWidgets('starts on Chats with the four top-level destinations', (
    tester,
  ) async {
    await pumpDelve(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Chats', 'Dashboard', 'Approvals', 'More']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('New chat'), findsOneWidget);
  });

  testWidgets('More opens sub-pages without bottom navigation', (tester) async {
    await pumpDelve(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('new chat is a detail screen without bottom navigation', (
    tester,
  ) async {
    await pumpDelve(tester);
    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Approvals badge follows the database', (tester) async {
    final env = await pumpDelve(tester);
    final db = env.db;
    expect(find.byType(Badge), findsNothing);

    final t0 = DateTime.utc(2026, 10, 20, 8);
    await tester.runAsync(
      () => db
          .into(db.approvals)
          .insert(
            ApprovalsCompanion.insert(
              requestId: 'a1',
              runId: 'run_1',
              conversationId: 'c_1',
              command: 'paru -Syu',
              patternKeys: const [],
              actionClass: 'pkg_upgrade',
              status: 'pending',
              choices: const ['once', 'session', 'deny'],
              createdAt: t0,
              hermesDeadline: t0.add(const Duration(minutes: 5)),
              expiresAt: t0.add(const Duration(hours: 24)),
            ),
          ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsNWidgets(1));
    expect(find.text('1'), findsWidgets);
  });
}
