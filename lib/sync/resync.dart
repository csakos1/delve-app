import 'package:drift/drift.dart';

import '../api/api_error.dart';
import '../api/models/models.dart';
import '../api/rest_client.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';

/// Every approval status the backend knows (resync reads them all, so an
/// approval answered elsewhere does not stay "pending" here).
const List<String> allApprovalStatuses = [
  'pending',
  'approved_once',
  'approved_session',
  'denied',
  'expired_in_hermes',
  'late_approved',
  'followup_started',
  'executed',
  'superseded',
  'expired',
  'cancelled',
];

/// What a resync loaded (for the connection log).
class ResyncReport {
  const ResyncReport({
    required this.conversations,
    required this.openRuns,
    required this.approvals,
    required this.reloaded,
  });

  final int conversations;
  final int openRuns;
  final int approvals;

  /// Conversations whose messages and runs were reloaded.
  final int reloaded;

  @override
  String toString() =>
      '$conversations conversations, $openRuns open runs, '
      '$approvals approvals, $reloaded reloaded';
}

/// Reloads the server state over REST after a restart of the server, a gap
/// in the event stream or the first connection (decision 169): the first
/// page of conversations, the run queue, recent approvals, and messages and
/// runs of every conversation that looks unfinished here (plus [focus], the
/// chat on screen). Everything is written in one transaction together with
/// the new stream position, so events after [seq] apply on top of it.
Future<ResyncReport> resync({
  required DelveApi api,
  required AppDatabase db,
  required String epoch,
  required int seq,
  String? focus,
  int reloadLimit = 10,
}) async {
  // sequential on purpose: a failure is a plain ApiError for the engine
  final page = await api.conversations();
  final open = await api.openRuns();
  final approvals = await api.approvals(
    statuses: allApprovalStatuses,
    limit: 200,
  );

  final openIds = {for (final r in open) r.runId};
  final staleRuns =
      await (db.select(db.runs)..where(
            (t) => t.status.isIn(openRunStatuses) & t.runId.isNotIn(openIds),
          ))
          .get();
  final streaming = await (db.select(
    db.messages,
  )..where((t) => t.status.equals('streaming'))).get();
  final reload = <String>{
    ?focus,
    for (final r in staleRuns) r.conversationId,
    for (final m in streaming) m.conversationId,
  }.take(reloadLimit).toList();

  final histories = <_History>[];
  for (final id in reload) {
    final h = await _history(api, id);
    if (h != null) histories.add(h);
  }

  await db.transaction(() async {
    for (final c in page.conversations) {
      await db.putConversation(c);
    }
    for (final h in histories) {
      await db.putConversation(h.conversation);
      for (final m in h.messages) {
        await db.putHistoryMessage(m);
      }
      for (final r in h.runs) {
        await db.putRun(r);
      }
    }
    // the queue: positions only for runs that are really open
    await db.customUpdate(
      'UPDATE runs SET position = NULL WHERE position IS NOT NULL',
      updates: {db.runs},
    );
    for (final r in open) {
      await db.putOpenRun(r);
    }
    // runs that ended while the app was away and were not reloaded above
    await (db.update(db.runs)..where(
          (t) => t.status.isIn(openRunStatuses) & t.runId.isNotIn(openIds),
        ))
        .write(
          const RunsCompanion(
            status: Value('cancelled'),
            error: Value('unknown'),
          ),
        );
    await (db.update(db.messages)..where(
          (t) => t.status.equals('streaming') & t.runId.isNotIn(openIds),
        ))
        .write(const MessagesCompanion(status: Value('cancelled')));

    final known = {for (final a in approvals) a.requestId};
    for (final a in approvals) {
      await db.putApproval(a);
    }
    await (db.update(db.approvals)..where(
          (t) =>
              t.status.isIn(answerableApprovalStatuses) &
              t.requestId.isNotIn(known),
        ))
        .write(const ApprovalsCompanion(status: Value('expired')));

    await db.writeSyncState(epoch: epoch, lastSeq: seq);
  });

  return ResyncReport(
    conversations: page.conversations.length,
    openRuns: open.length,
    approvals: approvals.length,
    reloaded: histories.length,
  );
}

class _History {
  const _History(this.conversation, this.messages, this.runs);
  final Conversation conversation;
  final List<HistoryMessage> messages;
  final List<Run> runs;
}

/// null when the conversation no longer exists on the server.
Future<_History?> _history(DelveApi api, String id) async {
  try {
    final conversation = await api.conversation(id);
    final page = await api.messages(id);
    final usage = await api.usage(id);
    return _History(conversation, page.messages, usage.runs);
  } on ApiRequestError catch (e) {
    if (e.status == 404) return null;
    rethrow;
  }
}
