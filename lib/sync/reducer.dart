import 'package:drift/drift.dart';

import '../api/events.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';
import 'live_runs.dart';

/// What a batch carried besides database changes (the engine logs these).
class ReduceOutcome {
  /// The last `health.status` in the batch.
  HealthStatus? health;
  final List<ServerError> errors = [];
  final List<UnknownEvent> unknown = [];
}

/// Applies server events to the database (decision 168): one transaction per
/// batch, together with the stream position (`sync_state`), so after a crash
/// no event is lost or applied twice. Every write is an idempotent upsert.
/// Text deltas, interim remarks and context samples only touch [live], after
/// the transaction has committed.
class EventReducer {
  EventReducer(this.db, this.live, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase db;
  final LiveRunsBuffer live;
  final DateTime Function() _now;

  Future<ReduceOutcome> apply(
    List<ServerEvent> events, {
    required String epoch,
  }) async {
    final outcome = ReduceOutcome();
    if (events.isEmpty) return outcome;
    final effects = <void Function()>[];
    await db.transaction(() async {
      for (final e in events) {
        await _apply(e, effects, outcome);
      }
      await db.writeSyncState(epoch: epoch, lastSeq: events.last.seq);
    });
    for (final effect in effects) {
      effect();
    }
    return outcome;
  }

  Future<void> _apply(
    ServerEvent e,
    List<void Function()> effects,
    ReduceOutcome outcome,
  ) async {
    final at = _now().toUtc();
    switch (e) {
      case ConversationCreated(:final conversation) ||
          ConversationUpdated(:final conversation):
        await db.putConversation(conversation);

      case MessageCreated(:final conversationId, :final message):
        await db.putMessage(message);
        final clientMsgId = message.clientMsgId;
        if (clientMsgId != null) await db.forgetOutbox(clientMsgId);
        final runId = message.runId;
        if (message.role == 'assistant' &&
            message.status == 'streaming' &&
            runId != null) {
          effects.add(
            () => live.messageCreated(conversationId, runId, message.id),
          );
        }

      case MessageUpdated(:final conversationId, :final message):
        await db.putMessage(message);
        final runId = message.runId;
        if (message.status != 'streaming' && runId != null) {
          effects.add(() => live.finished(conversationId, runId));
        }

      case MessageDelta(
        :final conversationId,
        :final runId,
        :final messageId,
        :final delta,
      ):
        effects.add(
          () => live.delta(
            conversationId: conversationId,
            runId: runId,
            messageId: messageId,
            text: delta,
            at: at,
          ),
        );

      case MessageInterim(:final conversationId, :final runId, :final text):
        effects.add(() => live.interim(conversationId, runId, text));

      case RunQueued(
        :final conversationId,
        :final runId,
        :final position,
        :final thinking,
        :final origin,
      ):
        final renamed = await (db.select(
          db.runs,
        )..where((t) => t.queuedId.equals(runId))).getSingleOrNull();
        if (renamed == null) {
          await db
              .into(db.runs)
              .insert(
                RunsCompanion.insert(
                  runId: runId,
                  conversationId: conversationId,
                  status: 'queued',
                  thinking: Value(thinking),
                  origin: Value(origin),
                  position: Value(position),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }

      case RunStarted(
        :final conversationId,
        :final runId,
        :final queuedId,
        :final thinking,
      ):
        if (queuedId != null) await db.renameRun(queuedId, runId);
        await db
            .into(db.runs)
            .insertOnConflictUpdate(
              RunsCompanion.insert(
                runId: runId,
                conversationId: conversationId,
                status: 'running',
                thinking: Value(thinking),
                startedAt: Value(at),
                position: const Value(0),
              ),
            );
        effects.add(
          () => live.started(
            conversationId: conversationId,
            runId: runId,
            thinking: thinking,
            at: at,
          ),
        );

      case RunUpdated(:final conversationId, :final runId, :final status):
        await db
            .into(db.runs)
            .insertOnConflictUpdate(
              RunsCompanion.insert(
                runId: runId,
                conversationId: conversationId,
                status: status,
              ),
            );

      case RunFinished(
        :final conversationId,
        :final runId,
        :final status,
        :final usage,
        :final error,
      ):
        final row = await (db.select(
          db.runs,
        )..where((t) => t.runId.equals(runId))).getSingleOrNull();
        await db
            .into(db.runs)
            .insertOnConflictUpdate(
              RunsCompanion.insert(
                runId: runId,
                conversationId: conversationId,
                status: status,
                endedAt: Value(at),
                usage: Value(usage),
                error: Value(error),
                position: const Value(null),
              ),
            );
        // everything behind it moves up one place
        final left =
            row?.position ?? (row == null || row.status == 'queued' ? null : 0);
        if (left != null) {
          await db.customUpdate(
            'UPDATE runs SET position = position - 1 WHERE position > ?1 AND run_id <> ?2',
            variables: [Variable.withInt(left), Variable.withString(runId)],
            updates: {db.runs},
          );
        }
        effects.add(() => live.finished(conversationId, runId));

      case ToolStarted(:final step) || ToolCompleted(:final step):
        await db.putToolStep(step);

      case ApprovalRequested(:final approval, :final stepId):
        await db.putApproval(approval, stepId: stepId);
        if (stepId != null) {
          await (db.update(
            db.toolSteps,
          )..where((t) => t.id.equals(stepId))).write(
            ToolStepsCompanion(approvalRequestId: Value(approval.requestId)),
          );
        }

      case ApprovalUpdated(:final approval):
        await db.putApproval(approval);

      case ReasoningFinal(:final messageId, :final text):
        await (db.update(db.messages)..where((t) => t.id.equals(messageId)))
            .write(MessagesCompanion(reasoning: Value(text)));

      case ContextUpdated(
        :final conversationId,
        :final runId,
        :final isFinal,
        :final tokens,
        :final max,
        :final pct,
        :final warn,
        :final source,
        :final measuredAt,
      ):
        // the final value reaches the database with conversation.updated
        if (!isFinal) {
          final sample = LiveContext(
            tokens: tokens,
            max: max,
            pct: pct,
            warn: warn,
            source: source,
            measuredAt: measuredAt,
          );
          effects.add(() => live.context(conversationId, runId, sample));
        }

      case CardNew(:final card):
        await db.putCard(card);

      case final HealthStatus health:
        outcome.health = health;

      case final ServerError error:
        outcome.errors.add(error);

      case final UnknownEvent unknown:
        outcome.unknown.add(unknown);
    }
  }
}
