import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';

/// The one local database. Tests override it with an in-memory one.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Pending + expired-in-agent approvals (bottom-nav badge).
final answerableApprovalCountProvider = StreamProvider<int>(
  (ref) => ref.watch(databaseProvider).watchAnswerableApprovalCount(),
);

/// Active conversations, newest first.
final conversationsProvider = StreamProvider<List<ConversationRow>>(
  (ref) => ref.watch(databaseProvider).watchConversations(),
);
