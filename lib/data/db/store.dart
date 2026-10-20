import 'package:drift/drift.dart';

import '../../api/models/models.dart';
import 'database.dart';

/// Server objects → rows. Every write is an upsert on the server id, so the
/// reducer and the REST loads can apply the same object twice (replay,
/// resync) without harm. Call inside a transaction when several belong
/// together.
extension Store on AppDatabase {
  Future<void> putConversation(Conversation c) =>
      into(conversations).insertOnConflictUpdate(
        ConversationsCompanion.insert(
          id: c.id,
          title: Value(c.title),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          archived: Value(c.archived),
          thinking: Value(c.thinking),
          origin: Value(c.origin),
          lastRunId: Value(c.lastRunId),
          contextTokens: Value(c.context.tokens),
          contextMax: Value(c.context.max),
          contextPct: Value(c.context.pct),
          contextWarn: Value(c.context.warn),
          contextMeasuredAt: Value(c.context.measuredAt),
          tokensIn: Value(c.totals.inputTokens),
          tokensOut: Value(c.totals.outputTokens),
          tokensCacheRead: Value(c.totals.cacheReadTokens),
          tokensTotal: Value(c.totals.totalTokens),
        ),
      );

  Future<void> putMessage(Message m) => into(messages).insertOnConflictUpdate(
    MessagesCompanion.insert(
      id: Value(m.id),
      conversationId: m.conversationId,
      runId: Value(m.runId),
      role: m.role,
      content: m.content,
      interim: Value(m.interim),
      reasoning: Value(m.reasoning),
      status: m.status,
      clientMsgId: Value(m.clientMsgId),
      createdAt: m.createdAt,
    ),
  );

  /// A message with its run's tool steps (REST `messages`, WS `sync`).
  Future<void> putHistoryMessage(HistoryMessage h) async {
    await putMessage(h.message);
    for (final step in h.toolSteps) {
      await putToolStep(step);
    }
    final clientMsgId = h.message.clientMsgId;
    if (clientMsgId != null) await forgetOutbox(clientMsgId);
  }

  Future<void> putRun(Run r, {int? position}) =>
      into(runs).insertOnConflictUpdate(
        RunsCompanion.insert(
          runId: r.runId,
          conversationId: r.conversationId,
          status: r.status,
          thinking: Value(r.thinking),
          origin: Value(r.origin),
          queuedAt: Value(r.queuedAt),
          startedAt: Value(r.startedAt),
          endedAt: Value(r.endedAt),
          usage: Value(r.usage),
          perf: Value(r.perf),
          error: Value(r.error),
          position: Value(openRunStatuses.contains(r.status) ? position : null),
        ),
      );

  Future<void> putOpenRun(OpenRun r) => putRun(
    Run(
      runId: r.runId,
      conversationId: r.conversationId,
      status: r.status,
      thinking: r.thinking,
      origin: r.origin,
      queuedAt: r.queuedAt,
      startedAt: r.startedAt,
      endedAt: r.endedAt,
      usage: r.usage,
      perf: r.perf,
      error: r.error,
    ),
    position: r.position,
  );

  /// A tool step; its approval (REST history) is stored with the step link.
  Future<void> putToolStep(ToolStep s) async {
    await into(toolSteps).insertOnConflictUpdate(
      ToolStepsCompanion.insert(
        id: Value(s.id),
        runId: s.runId,
        tool: s.tool,
        status: s.status,
        preview: Value(s.preview),
        result: Value(s.result),
        resultRaw: Value(s.resultRaw),
        userSummary: Value(s.userSummary),
        durationS: Value(s.durationS),
        seqStarted: Value(s.seqStarted),
        seqCompleted: Value(s.seqCompleted),
        approvalRequestId: Value(s.approvalRequestId),
      ),
    );
    final approval = s.approval;
    if (approval != null) await putApproval(approval, stepId: s.id);
  }

  /// [stepId] is only known from `approval.request` and REST history; an
  /// `approval.updated` leaves the stored link alone.
  Future<void> putApproval(Approval a, {int? stepId}) =>
      into(approvals).insertOnConflictUpdate(
        ApprovalsCompanion.insert(
          requestId: a.requestId,
          runId: a.runId,
          conversationId: a.conversationId,
          command: a.command,
          description: Value(a.description),
          patternKeys: a.patternKeys,
          actionClass: a.actionClass,
          status: a.status,
          choice: Value(a.choice),
          choices: a.choices,
          decidedBy: Value(a.decidedBy),
          createdAt: a.createdAt,
          hermesDeadline: a.hermesDeadline,
          expiresAt: a.expiresAt,
          respondedAt: Value(a.respondedAt),
          stepId: stepId == null ? const Value.absent() : Value(stepId),
        ),
      );

  /// `run.started`: the queue id (`q_…`) becomes the Hermes id (`run_…`)
  /// everywhere it was stored. Applying it twice is a no-op.
  Future<void> renameRun(String queuedId, String runId) async {
    if (queuedId == runId) return;
    final already = await (select(
      runs,
    )..where((t) => t.runId.equals(runId))).getSingleOrNull();
    if (already == null) {
      await (update(runs)..where((t) => t.runId.equals(queuedId))).write(
        RunsCompanion(runId: Value(runId), queuedId: Value(queuedId)),
      );
    } else {
      await (delete(runs)..where((t) => t.runId.equals(queuedId))).go();
    }
    await (update(messages)..where((t) => t.runId.equals(queuedId))).write(
      MessagesCompanion(runId: Value(runId)),
    );
    await (update(conversations)..where((t) => t.lastRunId.equals(queuedId)))
        .write(ConversationsCompanion(lastRunId: Value(runId)));
  }

  Future<void> forgetOutbox(String clientMsgId) =>
      (delete(outbox)..where((t) => t.clientMsgId.equals(clientMsgId))).go();
}
