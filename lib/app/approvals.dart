import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';
import '../sync/resync.dart' show allApprovalStatuses;
import 'providers.dart';
import 'session.dart';

/// An approval with the title of its chat (null while the chat is not
/// stored here or has no title yet).
class InboxApproval {
  const InboxApproval(this.approval, this.chatTitle);

  final ApprovalRow approval;
  final String? chatTitle;
}

/// 11 Approvals: what the agent still waits for, what it stopped waiting
/// for (still approvable late), and the latest answered ones.
class ApprovalInbox {
  const ApprovalInbox({
    required this.pending,
    required this.expired,
    required this.recent,
  });

  /// `pending`, the nearest agent deadline first.
  final List<InboxApproval> pending;

  /// `expired_in_hermes`, the nearest late-approval deadline first.
  final List<InboxApproval> expired;

  /// Everything else, the latest answer (or request) first.
  final List<InboxApproval> recent;

  bool get isEmpty => pending.isEmpty && expired.isEmpty && recent.isEmpty;
}

extension ApprovalInboxQueries on AppDatabase {
  /// The inbox, again on every change of the approvals or the chats.
  Stream<ApprovalInbox> watchApprovalInbox({int recentLimit = 20}) {
    final query = select(approvals).join([
      leftOuterJoin(
        conversations,
        conversations.id.equalsExp(approvals.conversationId),
      ),
    ]);
    return query.watch().map((rows) {
      final pending = <InboxApproval>[];
      final expired = <InboxApproval>[];
      final recent = <InboxApproval>[];
      for (final row in rows) {
        final a = row.readTable(approvals);
        final item = InboxApproval(
          a,
          row.readTableOrNull(conversations)?.title,
        );
        switch (a.status) {
          case 'pending':
            pending.add(item);
          case 'expired_in_hermes':
            expired.add(item);
          default:
            recent.add(item);
        }
      }
      DateTime answered(InboxApproval i) =>
          i.approval.respondedAt ?? i.approval.createdAt;
      pending.sort(
        (x, y) =>
            x.approval.hermesDeadline.compareTo(y.approval.hermesDeadline),
      );
      expired.sort(
        (x, y) => x.approval.expiresAt.compareTo(y.approval.expiresAt),
      );
      recent.sort((x, y) => answered(y).compareTo(answered(x)));
      return ApprovalInbox(
        pending: pending,
        expired: expired,
        recent: recent.take(recentLimit).toList(),
      );
    });
  }
}

final approvalInboxProvider = StreamProvider<ApprovalInbox>(
  (ref) => ref.watch(databaseProvider).watchApprovalInbox(),
);

/// The inbox talks REST (decision 246): it works whether or not the socket
/// is live, and an answer is never queued.
class ApprovalInboxService {
  ApprovalInboxService({required this.api, required this.db});

  final DelveApi api;
  final AppDatabase db;

  /// Reloads the approvals (every status, the newest 200).
  Future<void> refresh() async {
    final list = await api.approvals(statuses: allApprovalStatuses, limit: 200);
    await db.transaction(() async {
      for (final a in list) {
        await db.putApproval(a);
      }
    });
  }

  /// Answers [requestId] and stores what the server made of it (a late
  /// `once` comes back as `late_approved`: Delve runs it in a follow-up).
  Future<Approval> answer(String requestId, ApprovalChoice choice) async {
    final a = await api.answerApproval(requestId, choice);
    await db.putApproval(a);
    return a;
  }
}

final approvalInboxServiceProvider = Provider<ApprovalInboxService?>((ref) {
  final api = ref.watch(apiProvider);
  if (api == null) return null;
  return ApprovalInboxService(api: api, db: ref.watch(databaseProvider));
});
