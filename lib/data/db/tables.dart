import 'package:drift/drift.dart';

import 'converters.dart';

// The local mirror of the backend (decision 168): the WebSocket reducer and
// REST loads only write here, the UI only watches here. Server ids are the
// primary keys, so every write is an idempotent upsert.

@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();

  /// The server's list preview (schema 3): the latest text, also for chats
  /// whose messages were never loaded here.
  TextColumn get preview => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get thinking => boolean().withDefault(const Constant(false))();
  TextColumn get origin => text().withDefault(const Constant('app'))();
  TextColumn get lastRunId => text().nullable()();
  IntColumn get contextTokens => integer().nullable()();
  IntColumn get contextMax => integer().nullable()();
  RealColumn get contextPct => real().nullable()();
  BoolColumn get contextWarn => boolean().withDefault(const Constant(false))();
  DateTimeColumn get contextMeasuredAt => dateTime().nullable()();
  IntColumn get tokensIn => integer().withDefault(const Constant(0))();
  IntColumn get tokensOut => integer().withDefault(const Constant(0))();
  IntColumn get tokensCacheRead => integer().withDefault(const Constant(0))();
  IntColumn get tokensTotal => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MessageRow')
@TableIndex(name: 'messages_by_conversation', columns: {#conversationId, #id})
class Messages extends Table {
  IntColumn get id => integer()(); // server id, not autoincrement
  TextColumn get conversationId => text()();
  TextColumn get runId => text().nullable()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get interim => text().nullable()();
  TextColumn get reasoning => text().nullable()();
  TextColumn get status => text()();
  TextColumn get clientMsgId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Runs the app has seen; `position` is the queue place from `run.queued` or
/// `GET /runs/open` (null once the run has left the queue).
@DataClassName('RunRow')
@TableIndex(name: 'runs_by_conversation', columns: {#conversationId})
class Runs extends Table {
  TextColumn get runId => text()();
  TextColumn get queuedId => text().nullable()();
  TextColumn get conversationId => text()();
  TextColumn get status => text()();
  BoolColumn get thinking => boolean().withDefault(const Constant(false))();
  TextColumn get origin => text().withDefault(const Constant('app'))();
  DateTimeColumn get queuedAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get usage => text().map(const JsonMapConverter()).nullable()();
  TextColumn get perf => text().map(const JsonMapConverter()).nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get position => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {runId};
}

@DataClassName('ToolStepRow')
@TableIndex(name: 'tool_steps_by_run', columns: {#runId})
class ToolSteps extends Table {
  IntColumn get id => integer()(); // server id
  TextColumn get runId => text()();
  TextColumn get tool => text()();
  TextColumn get status => text()();
  TextColumn get preview => text().nullable()();
  TextColumn get result => text().map(const JsonMapConverter()).nullable()();
  TextColumn get resultRaw => text().nullable()();
  TextColumn get userSummary => text().nullable()();
  RealColumn get durationS => real().nullable()();
  IntColumn get seqStarted => integer().nullable()();
  IntColumn get seqCompleted => integer().nullable()();
  TextColumn get approvalRequestId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ApprovalRow')
@TableIndex(name: 'approvals_by_status', columns: {#status})
class Approvals extends Table {
  TextColumn get requestId => text()();
  TextColumn get runId => text()();
  TextColumn get conversationId => text()();
  TextColumn get command => text()();
  TextColumn get description => text().nullable()();
  TextColumn get patternKeys => text().map(const StringListConverter())();
  TextColumn get actionClass => text()();
  TextColumn get status => text()();
  TextColumn get choice => text().nullable()();
  TextColumn get choices => text().map(const StringListConverter())();
  TextColumn get decidedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get hermesDeadline => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get respondedAt => dateTime().nullable()();
  IntColumn get stepId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {requestId};
}

/// Messages typed while offline or not yet acknowledged (decision 170).
/// Approval answers never go here.
@DataClassName('OutboxRow')
class Outbox extends Table {
  TextColumn get clientMsgId => text()(); // UUIDv4, the idempotency key
  TextColumn get conversationId => text().nullable()(); // null: new chat
  TextColumn get body => text()();
  BoolColumn get thinking => boolean().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// pending | sending | failed
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientMsgId};
}

/// Single row: where the event stream stands. Written in the same
/// transaction as the events it covers (decision 168).
@DataClassName('SyncStateRow')
class SyncState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get epoch => text().nullable()();
  IntColumn get lastSeq => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

/// What the WebSocket connection did (Settings → Connection log). Kept to the
/// newest 500 entries and kept across unpairing (it holds no server data).
@DataClassName('ConnectionLogRow')
class ConnectionLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();

  /// A `LogKind` name (lib/sync/connection_log.dart).
  TextColumn get kind => text()();
  TextColumn get detail => text().nullable()();
}
