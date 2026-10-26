// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previewMeta = const VerificationMeta(
    'preview',
  );
  @override
  late final GeneratedColumn<String> preview = GeneratedColumn<String>(
    'preview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thinkingMeta = const VerificationMeta(
    'thinking',
  );
  @override
  late final GeneratedColumn<bool> thinking = GeneratedColumn<bool>(
    'thinking',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("thinking" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('app'),
  );
  static const VerificationMeta _lastRunIdMeta = const VerificationMeta(
    'lastRunId',
  );
  @override
  late final GeneratedColumn<String> lastRunId = GeneratedColumn<String>(
    'last_run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextTokensMeta = const VerificationMeta(
    'contextTokens',
  );
  @override
  late final GeneratedColumn<int> contextTokens = GeneratedColumn<int>(
    'context_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMaxMeta = const VerificationMeta(
    'contextMax',
  );
  @override
  late final GeneratedColumn<int> contextMax = GeneratedColumn<int>(
    'context_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextPctMeta = const VerificationMeta(
    'contextPct',
  );
  @override
  late final GeneratedColumn<double> contextPct = GeneratedColumn<double>(
    'context_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextWarnMeta = const VerificationMeta(
    'contextWarn',
  );
  @override
  late final GeneratedColumn<bool> contextWarn = GeneratedColumn<bool>(
    'context_warn',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("context_warn" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contextMeasuredAtMeta = const VerificationMeta(
    'contextMeasuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> contextMeasuredAt =
      GeneratedColumn<DateTime>(
        'context_measured_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tokensInMeta = const VerificationMeta(
    'tokensIn',
  );
  @override
  late final GeneratedColumn<int> tokensIn = GeneratedColumn<int>(
    'tokens_in',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensOutMeta = const VerificationMeta(
    'tokensOut',
  );
  @override
  late final GeneratedColumn<int> tokensOut = GeneratedColumn<int>(
    'tokens_out',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensCacheReadMeta = const VerificationMeta(
    'tokensCacheRead',
  );
  @override
  late final GeneratedColumn<int> tokensCacheRead = GeneratedColumn<int>(
    'tokens_cache_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensTotalMeta = const VerificationMeta(
    'tokensTotal',
  );
  @override
  late final GeneratedColumn<int> tokensTotal = GeneratedColumn<int>(
    'tokens_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    preview,
    createdAt,
    updatedAt,
    archived,
    thinking,
    origin,
    lastRunId,
    contextTokens,
    contextMax,
    contextPct,
    contextWarn,
    contextMeasuredAt,
    tokensIn,
    tokensOut,
    tokensCacheRead,
    tokensTotal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('preview')) {
      context.handle(
        _previewMeta,
        preview.isAcceptableOrUnknown(data['preview']!, _previewMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('thinking')) {
      context.handle(
        _thinkingMeta,
        thinking.isAcceptableOrUnknown(data['thinking']!, _thinkingMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('last_run_id')) {
      context.handle(
        _lastRunIdMeta,
        lastRunId.isAcceptableOrUnknown(data['last_run_id']!, _lastRunIdMeta),
      );
    }
    if (data.containsKey('context_tokens')) {
      context.handle(
        _contextTokensMeta,
        contextTokens.isAcceptableOrUnknown(
          data['context_tokens']!,
          _contextTokensMeta,
        ),
      );
    }
    if (data.containsKey('context_max')) {
      context.handle(
        _contextMaxMeta,
        contextMax.isAcceptableOrUnknown(data['context_max']!, _contextMaxMeta),
      );
    }
    if (data.containsKey('context_pct')) {
      context.handle(
        _contextPctMeta,
        contextPct.isAcceptableOrUnknown(data['context_pct']!, _contextPctMeta),
      );
    }
    if (data.containsKey('context_warn')) {
      context.handle(
        _contextWarnMeta,
        contextWarn.isAcceptableOrUnknown(
          data['context_warn']!,
          _contextWarnMeta,
        ),
      );
    }
    if (data.containsKey('context_measured_at')) {
      context.handle(
        _contextMeasuredAtMeta,
        contextMeasuredAt.isAcceptableOrUnknown(
          data['context_measured_at']!,
          _contextMeasuredAtMeta,
        ),
      );
    }
    if (data.containsKey('tokens_in')) {
      context.handle(
        _tokensInMeta,
        tokensIn.isAcceptableOrUnknown(data['tokens_in']!, _tokensInMeta),
      );
    }
    if (data.containsKey('tokens_out')) {
      context.handle(
        _tokensOutMeta,
        tokensOut.isAcceptableOrUnknown(data['tokens_out']!, _tokensOutMeta),
      );
    }
    if (data.containsKey('tokens_cache_read')) {
      context.handle(
        _tokensCacheReadMeta,
        tokensCacheRead.isAcceptableOrUnknown(
          data['tokens_cache_read']!,
          _tokensCacheReadMeta,
        ),
      );
    }
    if (data.containsKey('tokens_total')) {
      context.handle(
        _tokensTotalMeta,
        tokensTotal.isAcceptableOrUnknown(
          data['tokens_total']!,
          _tokensTotalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      preview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      thinking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}thinking'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      lastRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_run_id'],
      ),
      contextTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_tokens'],
      ),
      contextMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_max'],
      ),
      contextPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}context_pct'],
      ),
      contextWarn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}context_warn'],
      )!,
      contextMeasuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}context_measured_at'],
      ),
      tokensIn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_in'],
      )!,
      tokensOut: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_out'],
      )!,
      tokensCacheRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_cache_read'],
      )!,
      tokensTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_total'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationRow extends DataClass implements Insertable<ConversationRow> {
  final String id;
  final String? title;

  /// The server's list preview (schema 3): the latest text, also for chats
  /// whose messages were never loaded here.
  final String? preview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final bool thinking;
  final String origin;
  final String? lastRunId;
  final int? contextTokens;
  final int? contextMax;
  final double? contextPct;
  final bool contextWarn;
  final DateTime? contextMeasuredAt;
  final int tokensIn;
  final int tokensOut;
  final int tokensCacheRead;
  final int tokensTotal;
  const ConversationRow({
    required this.id,
    this.title,
    this.preview,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.thinking,
    required this.origin,
    this.lastRunId,
    this.contextTokens,
    this.contextMax,
    this.contextPct,
    required this.contextWarn,
    this.contextMeasuredAt,
    required this.tokensIn,
    required this.tokensOut,
    required this.tokensCacheRead,
    required this.tokensTotal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || preview != null) {
      map['preview'] = Variable<String>(preview);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['archived'] = Variable<bool>(archived);
    map['thinking'] = Variable<bool>(thinking);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || lastRunId != null) {
      map['last_run_id'] = Variable<String>(lastRunId);
    }
    if (!nullToAbsent || contextTokens != null) {
      map['context_tokens'] = Variable<int>(contextTokens);
    }
    if (!nullToAbsent || contextMax != null) {
      map['context_max'] = Variable<int>(contextMax);
    }
    if (!nullToAbsent || contextPct != null) {
      map['context_pct'] = Variable<double>(contextPct);
    }
    map['context_warn'] = Variable<bool>(contextWarn);
    if (!nullToAbsent || contextMeasuredAt != null) {
      map['context_measured_at'] = Variable<DateTime>(contextMeasuredAt);
    }
    map['tokens_in'] = Variable<int>(tokensIn);
    map['tokens_out'] = Variable<int>(tokensOut);
    map['tokens_cache_read'] = Variable<int>(tokensCacheRead);
    map['tokens_total'] = Variable<int>(tokensTotal);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      preview: preview == null && nullToAbsent
          ? const Value.absent()
          : Value(preview),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archived: Value(archived),
      thinking: Value(thinking),
      origin: Value(origin),
      lastRunId: lastRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRunId),
      contextTokens: contextTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(contextTokens),
      contextMax: contextMax == null && nullToAbsent
          ? const Value.absent()
          : Value(contextMax),
      contextPct: contextPct == null && nullToAbsent
          ? const Value.absent()
          : Value(contextPct),
      contextWarn: Value(contextWarn),
      contextMeasuredAt: contextMeasuredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(contextMeasuredAt),
      tokensIn: Value(tokensIn),
      tokensOut: Value(tokensOut),
      tokensCacheRead: Value(tokensCacheRead),
      tokensTotal: Value(tokensTotal),
    );
  }

  factory ConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      preview: serializer.fromJson<String?>(json['preview']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archived: serializer.fromJson<bool>(json['archived']),
      thinking: serializer.fromJson<bool>(json['thinking']),
      origin: serializer.fromJson<String>(json['origin']),
      lastRunId: serializer.fromJson<String?>(json['lastRunId']),
      contextTokens: serializer.fromJson<int?>(json['contextTokens']),
      contextMax: serializer.fromJson<int?>(json['contextMax']),
      contextPct: serializer.fromJson<double?>(json['contextPct']),
      contextWarn: serializer.fromJson<bool>(json['contextWarn']),
      contextMeasuredAt: serializer.fromJson<DateTime?>(
        json['contextMeasuredAt'],
      ),
      tokensIn: serializer.fromJson<int>(json['tokensIn']),
      tokensOut: serializer.fromJson<int>(json['tokensOut']),
      tokensCacheRead: serializer.fromJson<int>(json['tokensCacheRead']),
      tokensTotal: serializer.fromJson<int>(json['tokensTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'preview': serializer.toJson<String?>(preview),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archived': serializer.toJson<bool>(archived),
      'thinking': serializer.toJson<bool>(thinking),
      'origin': serializer.toJson<String>(origin),
      'lastRunId': serializer.toJson<String?>(lastRunId),
      'contextTokens': serializer.toJson<int?>(contextTokens),
      'contextMax': serializer.toJson<int?>(contextMax),
      'contextPct': serializer.toJson<double?>(contextPct),
      'contextWarn': serializer.toJson<bool>(contextWarn),
      'contextMeasuredAt': serializer.toJson<DateTime?>(contextMeasuredAt),
      'tokensIn': serializer.toJson<int>(tokensIn),
      'tokensOut': serializer.toJson<int>(tokensOut),
      'tokensCacheRead': serializer.toJson<int>(tokensCacheRead),
      'tokensTotal': serializer.toJson<int>(tokensTotal),
    };
  }

  ConversationRow copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    Value<String?> preview = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    bool? thinking,
    String? origin,
    Value<String?> lastRunId = const Value.absent(),
    Value<int?> contextTokens = const Value.absent(),
    Value<int?> contextMax = const Value.absent(),
    Value<double?> contextPct = const Value.absent(),
    bool? contextWarn,
    Value<DateTime?> contextMeasuredAt = const Value.absent(),
    int? tokensIn,
    int? tokensOut,
    int? tokensCacheRead,
    int? tokensTotal,
  }) => ConversationRow(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    preview: preview.present ? preview.value : this.preview,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archived: archived ?? this.archived,
    thinking: thinking ?? this.thinking,
    origin: origin ?? this.origin,
    lastRunId: lastRunId.present ? lastRunId.value : this.lastRunId,
    contextTokens: contextTokens.present
        ? contextTokens.value
        : this.contextTokens,
    contextMax: contextMax.present ? contextMax.value : this.contextMax,
    contextPct: contextPct.present ? contextPct.value : this.contextPct,
    contextWarn: contextWarn ?? this.contextWarn,
    contextMeasuredAt: contextMeasuredAt.present
        ? contextMeasuredAt.value
        : this.contextMeasuredAt,
    tokensIn: tokensIn ?? this.tokensIn,
    tokensOut: tokensOut ?? this.tokensOut,
    tokensCacheRead: tokensCacheRead ?? this.tokensCacheRead,
    tokensTotal: tokensTotal ?? this.tokensTotal,
  );
  ConversationRow copyWithCompanion(ConversationsCompanion data) {
    return ConversationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      preview: data.preview.present ? data.preview.value : this.preview,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archived: data.archived.present ? data.archived.value : this.archived,
      thinking: data.thinking.present ? data.thinking.value : this.thinking,
      origin: data.origin.present ? data.origin.value : this.origin,
      lastRunId: data.lastRunId.present ? data.lastRunId.value : this.lastRunId,
      contextTokens: data.contextTokens.present
          ? data.contextTokens.value
          : this.contextTokens,
      contextMax: data.contextMax.present
          ? data.contextMax.value
          : this.contextMax,
      contextPct: data.contextPct.present
          ? data.contextPct.value
          : this.contextPct,
      contextWarn: data.contextWarn.present
          ? data.contextWarn.value
          : this.contextWarn,
      contextMeasuredAt: data.contextMeasuredAt.present
          ? data.contextMeasuredAt.value
          : this.contextMeasuredAt,
      tokensIn: data.tokensIn.present ? data.tokensIn.value : this.tokensIn,
      tokensOut: data.tokensOut.present ? data.tokensOut.value : this.tokensOut,
      tokensCacheRead: data.tokensCacheRead.present
          ? data.tokensCacheRead.value
          : this.tokensCacheRead,
      tokensTotal: data.tokensTotal.present
          ? data.tokensTotal.value
          : this.tokensTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('preview: $preview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('thinking: $thinking, ')
          ..write('origin: $origin, ')
          ..write('lastRunId: $lastRunId, ')
          ..write('contextTokens: $contextTokens, ')
          ..write('contextMax: $contextMax, ')
          ..write('contextPct: $contextPct, ')
          ..write('contextWarn: $contextWarn, ')
          ..write('contextMeasuredAt: $contextMeasuredAt, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('tokensCacheRead: $tokensCacheRead, ')
          ..write('tokensTotal: $tokensTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    preview,
    createdAt,
    updatedAt,
    archived,
    thinking,
    origin,
    lastRunId,
    contextTokens,
    contextMax,
    contextPct,
    contextWarn,
    contextMeasuredAt,
    tokensIn,
    tokensOut,
    tokensCacheRead,
    tokensTotal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.preview == this.preview &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archived == this.archived &&
          other.thinking == this.thinking &&
          other.origin == this.origin &&
          other.lastRunId == this.lastRunId &&
          other.contextTokens == this.contextTokens &&
          other.contextMax == this.contextMax &&
          other.contextPct == this.contextPct &&
          other.contextWarn == this.contextWarn &&
          other.contextMeasuredAt == this.contextMeasuredAt &&
          other.tokensIn == this.tokensIn &&
          other.tokensOut == this.tokensOut &&
          other.tokensCacheRead == this.tokensCacheRead &&
          other.tokensTotal == this.tokensTotal);
}

class ConversationsCompanion extends UpdateCompanion<ConversationRow> {
  final Value<String> id;
  final Value<String?> title;
  final Value<String?> preview;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> archived;
  final Value<bool> thinking;
  final Value<String> origin;
  final Value<String?> lastRunId;
  final Value<int?> contextTokens;
  final Value<int?> contextMax;
  final Value<double?> contextPct;
  final Value<bool> contextWarn;
  final Value<DateTime?> contextMeasuredAt;
  final Value<int> tokensIn;
  final Value<int> tokensOut;
  final Value<int> tokensCacheRead;
  final Value<int> tokensTotal;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.preview = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.thinking = const Value.absent(),
    this.origin = const Value.absent(),
    this.lastRunId = const Value.absent(),
    this.contextTokens = const Value.absent(),
    this.contextMax = const Value.absent(),
    this.contextPct = const Value.absent(),
    this.contextWarn = const Value.absent(),
    this.contextMeasuredAt = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.tokensCacheRead = const Value.absent(),
    this.tokensTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.preview = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archived = const Value.absent(),
    this.thinking = const Value.absent(),
    this.origin = const Value.absent(),
    this.lastRunId = const Value.absent(),
    this.contextTokens = const Value.absent(),
    this.contextMax = const Value.absent(),
    this.contextPct = const Value.absent(),
    this.contextWarn = const Value.absent(),
    this.contextMeasuredAt = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.tokensCacheRead = const Value.absent(),
    this.tokensTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConversationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? preview,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? archived,
    Expression<bool>? thinking,
    Expression<String>? origin,
    Expression<String>? lastRunId,
    Expression<int>? contextTokens,
    Expression<int>? contextMax,
    Expression<double>? contextPct,
    Expression<bool>? contextWarn,
    Expression<DateTime>? contextMeasuredAt,
    Expression<int>? tokensIn,
    Expression<int>? tokensOut,
    Expression<int>? tokensCacheRead,
    Expression<int>? tokensTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (preview != null) 'preview': preview,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archived != null) 'archived': archived,
      if (thinking != null) 'thinking': thinking,
      if (origin != null) 'origin': origin,
      if (lastRunId != null) 'last_run_id': lastRunId,
      if (contextTokens != null) 'context_tokens': contextTokens,
      if (contextMax != null) 'context_max': contextMax,
      if (contextPct != null) 'context_pct': contextPct,
      if (contextWarn != null) 'context_warn': contextWarn,
      if (contextMeasuredAt != null) 'context_measured_at': contextMeasuredAt,
      if (tokensIn != null) 'tokens_in': tokensIn,
      if (tokensOut != null) 'tokens_out': tokensOut,
      if (tokensCacheRead != null) 'tokens_cache_read': tokensCacheRead,
      if (tokensTotal != null) 'tokens_total': tokensTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<String?>? preview,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? archived,
    Value<bool>? thinking,
    Value<String>? origin,
    Value<String?>? lastRunId,
    Value<int?>? contextTokens,
    Value<int?>? contextMax,
    Value<double?>? contextPct,
    Value<bool>? contextWarn,
    Value<DateTime?>? contextMeasuredAt,
    Value<int>? tokensIn,
    Value<int>? tokensOut,
    Value<int>? tokensCacheRead,
    Value<int>? tokensTotal,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      thinking: thinking ?? this.thinking,
      origin: origin ?? this.origin,
      lastRunId: lastRunId ?? this.lastRunId,
      contextTokens: contextTokens ?? this.contextTokens,
      contextMax: contextMax ?? this.contextMax,
      contextPct: contextPct ?? this.contextPct,
      contextWarn: contextWarn ?? this.contextWarn,
      contextMeasuredAt: contextMeasuredAt ?? this.contextMeasuredAt,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      tokensCacheRead: tokensCacheRead ?? this.tokensCacheRead,
      tokensTotal: tokensTotal ?? this.tokensTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (preview.present) {
      map['preview'] = Variable<String>(preview.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (thinking.present) {
      map['thinking'] = Variable<bool>(thinking.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (lastRunId.present) {
      map['last_run_id'] = Variable<String>(lastRunId.value);
    }
    if (contextTokens.present) {
      map['context_tokens'] = Variable<int>(contextTokens.value);
    }
    if (contextMax.present) {
      map['context_max'] = Variable<int>(contextMax.value);
    }
    if (contextPct.present) {
      map['context_pct'] = Variable<double>(contextPct.value);
    }
    if (contextWarn.present) {
      map['context_warn'] = Variable<bool>(contextWarn.value);
    }
    if (contextMeasuredAt.present) {
      map['context_measured_at'] = Variable<DateTime>(contextMeasuredAt.value);
    }
    if (tokensIn.present) {
      map['tokens_in'] = Variable<int>(tokensIn.value);
    }
    if (tokensOut.present) {
      map['tokens_out'] = Variable<int>(tokensOut.value);
    }
    if (tokensCacheRead.present) {
      map['tokens_cache_read'] = Variable<int>(tokensCacheRead.value);
    }
    if (tokensTotal.present) {
      map['tokens_total'] = Variable<int>(tokensTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('preview: $preview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('thinking: $thinking, ')
          ..write('origin: $origin, ')
          ..write('lastRunId: $lastRunId, ')
          ..write('contextTokens: $contextTokens, ')
          ..write('contextMax: $contextMax, ')
          ..write('contextPct: $contextPct, ')
          ..write('contextWarn: $contextWarn, ')
          ..write('contextMeasuredAt: $contextMeasuredAt, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('tokensCacheRead: $tokensCacheRead, ')
          ..write('tokensTotal: $tokensTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interimMeta = const VerificationMeta(
    'interim',
  );
  @override
  late final GeneratedColumn<String> interim = GeneratedColumn<String>(
    'interim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasoningMeta = const VerificationMeta(
    'reasoning',
  );
  @override
  late final GeneratedColumn<String> reasoning = GeneratedColumn<String>(
    'reasoning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientMsgIdMeta = const VerificationMeta(
    'clientMsgId',
  );
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
    'client_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<Attachment>, String>
  attachments = GeneratedColumn<String>(
    'attachments',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<Attachment>>($MessagesTable.$converterattachments);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    runId,
    role,
    content,
    interim,
    reasoning,
    status,
    clientMsgId,
    createdAt,
    attachments,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('interim')) {
      context.handle(
        _interimMeta,
        interim.isAcceptableOrUnknown(data['interim']!, _interimMeta),
      );
    }
    if (data.containsKey('reasoning')) {
      context.handle(
        _reasoningMeta,
        reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('client_msg_id')) {
      context.handle(
        _clientMsgIdMeta,
        clientMsgId.isAcceptableOrUnknown(
          data['client_msg_id']!,
          _clientMsgIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      interim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interim'],
      ),
      reasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      clientMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_msg_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attachments: $MessagesTable.$converterattachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attachments'],
        )!,
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Attachment>, String> $converterattachments =
      const AttachmentListConverter();
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final int id;
  final String conversationId;
  final String? runId;
  final String role;
  final String content;
  final String? interim;
  final String? reasoning;
  final String status;
  final String? clientMsgId;
  final DateTime createdAt;

  /// The user's photos and files (schema 5, B6).
  final List<Attachment> attachments;
  const MessageRow({
    required this.id,
    required this.conversationId,
    this.runId,
    required this.role,
    required this.content,
    this.interim,
    this.reasoning,
    required this.status,
    this.clientMsgId,
    required this.createdAt,
    required this.attachments,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || runId != null) {
      map['run_id'] = Variable<String>(runId);
    }
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || interim != null) {
      map['interim'] = Variable<String>(interim);
    }
    if (!nullToAbsent || reasoning != null) {
      map['reasoning'] = Variable<String>(reasoning);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || clientMsgId != null) {
      map['client_msg_id'] = Variable<String>(clientMsgId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['attachments'] = Variable<String>(
        $MessagesTable.$converterattachments.toSql(attachments),
      );
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      runId: runId == null && nullToAbsent
          ? const Value.absent()
          : Value(runId),
      role: Value(role),
      content: Value(content),
      interim: interim == null && nullToAbsent
          ? const Value.absent()
          : Value(interim),
      reasoning: reasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoning),
      status: Value(status),
      clientMsgId: clientMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMsgId),
      createdAt: Value(createdAt),
      attachments: Value(attachments),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      runId: serializer.fromJson<String?>(json['runId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      interim: serializer.fromJson<String?>(json['interim']),
      reasoning: serializer.fromJson<String?>(json['reasoning']),
      status: serializer.fromJson<String>(json['status']),
      clientMsgId: serializer.fromJson<String?>(json['clientMsgId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attachments: serializer.fromJson<List<Attachment>>(json['attachments']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'runId': serializer.toJson<String?>(runId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'interim': serializer.toJson<String?>(interim),
      'reasoning': serializer.toJson<String?>(reasoning),
      'status': serializer.toJson<String>(status),
      'clientMsgId': serializer.toJson<String?>(clientMsgId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attachments': serializer.toJson<List<Attachment>>(attachments),
    };
  }

  MessageRow copyWith({
    int? id,
    String? conversationId,
    Value<String?> runId = const Value.absent(),
    String? role,
    String? content,
    Value<String?> interim = const Value.absent(),
    Value<String?> reasoning = const Value.absent(),
    String? status,
    Value<String?> clientMsgId = const Value.absent(),
    DateTime? createdAt,
    List<Attachment>? attachments,
  }) => MessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    runId: runId.present ? runId.value : this.runId,
    role: role ?? this.role,
    content: content ?? this.content,
    interim: interim.present ? interim.value : this.interim,
    reasoning: reasoning.present ? reasoning.value : this.reasoning,
    status: status ?? this.status,
    clientMsgId: clientMsgId.present ? clientMsgId.value : this.clientMsgId,
    createdAt: createdAt ?? this.createdAt,
    attachments: attachments ?? this.attachments,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      runId: data.runId.present ? data.runId.value : this.runId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      interim: data.interim.present ? data.interim.value : this.interim,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      status: data.status.present ? data.status.value : this.status,
      clientMsgId: data.clientMsgId.present
          ? data.clientMsgId.value
          : this.clientMsgId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('runId: $runId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('interim: $interim, ')
          ..write('reasoning: $reasoning, ')
          ..write('status: $status, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('createdAt: $createdAt, ')
          ..write('attachments: $attachments')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    runId,
    role,
    content,
    interim,
    reasoning,
    status,
    clientMsgId,
    createdAt,
    attachments,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.runId == this.runId &&
          other.role == this.role &&
          other.content == this.content &&
          other.interim == this.interim &&
          other.reasoning == this.reasoning &&
          other.status == this.status &&
          other.clientMsgId == this.clientMsgId &&
          other.createdAt == this.createdAt &&
          other.attachments == this.attachments);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<int> id;
  final Value<String> conversationId;
  final Value<String?> runId;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> interim;
  final Value<String?> reasoning;
  final Value<String> status;
  final Value<String?> clientMsgId;
  final Value<DateTime> createdAt;
  final Value<List<Attachment>> attachments;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.runId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.interim = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.status = const Value.absent(),
    this.clientMsgId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attachments = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required String conversationId,
    this.runId = const Value.absent(),
    required String role,
    required String content,
    this.interim = const Value.absent(),
    this.reasoning = const Value.absent(),
    required String status,
    this.clientMsgId = const Value.absent(),
    required DateTime createdAt,
    this.attachments = const Value.absent(),
  }) : conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<MessageRow> custom({
    Expression<int>? id,
    Expression<String>? conversationId,
    Expression<String>? runId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? interim,
    Expression<String>? reasoning,
    Expression<String>? status,
    Expression<String>? clientMsgId,
    Expression<DateTime>? createdAt,
    Expression<String>? attachments,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (runId != null) 'run_id': runId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (interim != null) 'interim': interim,
      if (reasoning != null) 'reasoning': reasoning,
      if (status != null) 'status': status,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
      if (createdAt != null) 'created_at': createdAt,
      if (attachments != null) 'attachments': attachments,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? conversationId,
    Value<String?>? runId,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? interim,
    Value<String?>? reasoning,
    Value<String>? status,
    Value<String?>? clientMsgId,
    Value<DateTime>? createdAt,
    Value<List<Attachment>>? attachments,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      runId: runId ?? this.runId,
      role: role ?? this.role,
      content: content ?? this.content,
      interim: interim ?? this.interim,
      reasoning: reasoning ?? this.reasoning,
      status: status ?? this.status,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (interim.present) {
      map['interim'] = Variable<String>(interim.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<String>(reasoning.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(
        $MessagesTable.$converterattachments.toSql(attachments.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('runId: $runId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('interim: $interim, ')
          ..write('reasoning: $reasoning, ')
          ..write('status: $status, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('createdAt: $createdAt, ')
          ..write('attachments: $attachments')
          ..write(')'))
        .toString();
  }
}

class $RunsTable extends Runs with TableInfo<$RunsTable, RunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedIdMeta = const VerificationMeta(
    'queuedId',
  );
  @override
  late final GeneratedColumn<String> queuedId = GeneratedColumn<String>(
    'queued_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thinkingMeta = const VerificationMeta(
    'thinking',
  );
  @override
  late final GeneratedColumn<bool> thinking = GeneratedColumn<bool>(
    'thinking',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("thinking" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('app'),
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, Object?>?, String>
  usage = GeneratedColumn<String>(
    'usage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Map<String, Object?>?>($RunsTable.$converterusagen);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, Object?>?, String>
  perf = GeneratedColumn<String>(
    'perf',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Map<String, Object?>?>($RunsTable.$converterperfn);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    runId,
    queuedId,
    conversationId,
    status,
    thinking,
    origin,
    queuedAt,
    startedAt,
    endedAt,
    usage,
    perf,
    error,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('queued_id')) {
      context.handle(
        _queuedIdMeta,
        queuedId.isAcceptableOrUnknown(data['queued_id']!, _queuedIdMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('thinking')) {
      context.handle(
        _thinkingMeta,
        thinking.isAcceptableOrUnknown(data['thinking']!, _thinkingMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId};
  @override
  RunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunRow(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      queuedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queued_id'],
      ),
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      thinking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}thinking'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      usage: $RunsTable.$converterusagen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}usage'],
        ),
      ),
      perf: $RunsTable.$converterperfn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}perf'],
        ),
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      ),
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, Object?>, String> $converterusage =
      const JsonMapConverter();
  static TypeConverter<Map<String, Object?>?, String?> $converterusagen =
      NullAwareTypeConverter.wrap($converterusage);
  static TypeConverter<Map<String, Object?>, String> $converterperf =
      const JsonMapConverter();
  static TypeConverter<Map<String, Object?>?, String?> $converterperfn =
      NullAwareTypeConverter.wrap($converterperf);
}

class RunRow extends DataClass implements Insertable<RunRow> {
  final String runId;
  final String? queuedId;
  final String conversationId;
  final String status;
  final bool thinking;
  final String origin;
  final DateTime? queuedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, Object?>? usage;
  final Map<String, Object?>? perf;
  final String? error;
  final int? position;
  const RunRow({
    required this.runId,
    this.queuedId,
    required this.conversationId,
    required this.status,
    required this.thinking,
    required this.origin,
    this.queuedAt,
    this.startedAt,
    this.endedAt,
    this.usage,
    this.perf,
    this.error,
    this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    if (!nullToAbsent || queuedId != null) {
      map['queued_id'] = Variable<String>(queuedId);
    }
    map['conversation_id'] = Variable<String>(conversationId);
    map['status'] = Variable<String>(status);
    map['thinking'] = Variable<bool>(thinking);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || queuedAt != null) {
      map['queued_at'] = Variable<DateTime>(queuedAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || usage != null) {
      map['usage'] = Variable<String>($RunsTable.$converterusagen.toSql(usage));
    }
    if (!nullToAbsent || perf != null) {
      map['perf'] = Variable<String>($RunsTable.$converterperfn.toSql(perf));
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<int>(position);
    }
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      runId: Value(runId),
      queuedId: queuedId == null && nullToAbsent
          ? const Value.absent()
          : Value(queuedId),
      conversationId: Value(conversationId),
      status: Value(status),
      thinking: Value(thinking),
      origin: Value(origin),
      queuedAt: queuedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(queuedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      usage: usage == null && nullToAbsent
          ? const Value.absent()
          : Value(usage),
      perf: perf == null && nullToAbsent ? const Value.absent() : Value(perf),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
    );
  }

  factory RunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunRow(
      runId: serializer.fromJson<String>(json['runId']),
      queuedId: serializer.fromJson<String?>(json['queuedId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      status: serializer.fromJson<String>(json['status']),
      thinking: serializer.fromJson<bool>(json['thinking']),
      origin: serializer.fromJson<String>(json['origin']),
      queuedAt: serializer.fromJson<DateTime?>(json['queuedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      usage: serializer.fromJson<Map<String, Object?>?>(json['usage']),
      perf: serializer.fromJson<Map<String, Object?>?>(json['perf']),
      error: serializer.fromJson<String?>(json['error']),
      position: serializer.fromJson<int?>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'queuedId': serializer.toJson<String?>(queuedId),
      'conversationId': serializer.toJson<String>(conversationId),
      'status': serializer.toJson<String>(status),
      'thinking': serializer.toJson<bool>(thinking),
      'origin': serializer.toJson<String>(origin),
      'queuedAt': serializer.toJson<DateTime?>(queuedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'usage': serializer.toJson<Map<String, Object?>?>(usage),
      'perf': serializer.toJson<Map<String, Object?>?>(perf),
      'error': serializer.toJson<String?>(error),
      'position': serializer.toJson<int?>(position),
    };
  }

  RunRow copyWith({
    String? runId,
    Value<String?> queuedId = const Value.absent(),
    String? conversationId,
    String? status,
    bool? thinking,
    String? origin,
    Value<DateTime?> queuedAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<Map<String, Object?>?> usage = const Value.absent(),
    Value<Map<String, Object?>?> perf = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<int?> position = const Value.absent(),
  }) => RunRow(
    runId: runId ?? this.runId,
    queuedId: queuedId.present ? queuedId.value : this.queuedId,
    conversationId: conversationId ?? this.conversationId,
    status: status ?? this.status,
    thinking: thinking ?? this.thinking,
    origin: origin ?? this.origin,
    queuedAt: queuedAt.present ? queuedAt.value : this.queuedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    usage: usage.present ? usage.value : this.usage,
    perf: perf.present ? perf.value : this.perf,
    error: error.present ? error.value : this.error,
    position: position.present ? position.value : this.position,
  );
  RunRow copyWithCompanion(RunsCompanion data) {
    return RunRow(
      runId: data.runId.present ? data.runId.value : this.runId,
      queuedId: data.queuedId.present ? data.queuedId.value : this.queuedId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      status: data.status.present ? data.status.value : this.status,
      thinking: data.thinking.present ? data.thinking.value : this.thinking,
      origin: data.origin.present ? data.origin.value : this.origin,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      usage: data.usage.present ? data.usage.value : this.usage,
      perf: data.perf.present ? data.perf.value : this.perf,
      error: data.error.present ? data.error.value : this.error,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunRow(')
          ..write('runId: $runId, ')
          ..write('queuedId: $queuedId, ')
          ..write('conversationId: $conversationId, ')
          ..write('status: $status, ')
          ..write('thinking: $thinking, ')
          ..write('origin: $origin, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('usage: $usage, ')
          ..write('perf: $perf, ')
          ..write('error: $error, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    runId,
    queuedId,
    conversationId,
    status,
    thinking,
    origin,
    queuedAt,
    startedAt,
    endedAt,
    usage,
    perf,
    error,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunRow &&
          other.runId == this.runId &&
          other.queuedId == this.queuedId &&
          other.conversationId == this.conversationId &&
          other.status == this.status &&
          other.thinking == this.thinking &&
          other.origin == this.origin &&
          other.queuedAt == this.queuedAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.usage == this.usage &&
          other.perf == this.perf &&
          other.error == this.error &&
          other.position == this.position);
}

class RunsCompanion extends UpdateCompanion<RunRow> {
  final Value<String> runId;
  final Value<String?> queuedId;
  final Value<String> conversationId;
  final Value<String> status;
  final Value<bool> thinking;
  final Value<String> origin;
  final Value<DateTime?> queuedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<Map<String, Object?>?> usage;
  final Value<Map<String, Object?>?> perf;
  final Value<String?> error;
  final Value<int?> position;
  final Value<int> rowid;
  const RunsCompanion({
    this.runId = const Value.absent(),
    this.queuedId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.status = const Value.absent(),
    this.thinking = const Value.absent(),
    this.origin = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.usage = const Value.absent(),
    this.perf = const Value.absent(),
    this.error = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunsCompanion.insert({
    required String runId,
    this.queuedId = const Value.absent(),
    required String conversationId,
    required String status,
    this.thinking = const Value.absent(),
    this.origin = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.usage = const Value.absent(),
    this.perf = const Value.absent(),
    this.error = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       conversationId = Value(conversationId),
       status = Value(status);
  static Insertable<RunRow> custom({
    Expression<String>? runId,
    Expression<String>? queuedId,
    Expression<String>? conversationId,
    Expression<String>? status,
    Expression<bool>? thinking,
    Expression<String>? origin,
    Expression<DateTime>? queuedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? usage,
    Expression<String>? perf,
    Expression<String>? error,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (queuedId != null) 'queued_id': queuedId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (status != null) 'status': status,
      if (thinking != null) 'thinking': thinking,
      if (origin != null) 'origin': origin,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (usage != null) 'usage': usage,
      if (perf != null) 'perf': perf,
      if (error != null) 'error': error,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunsCompanion copyWith({
    Value<String>? runId,
    Value<String?>? queuedId,
    Value<String>? conversationId,
    Value<String>? status,
    Value<bool>? thinking,
    Value<String>? origin,
    Value<DateTime?>? queuedAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<Map<String, Object?>?>? usage,
    Value<Map<String, Object?>?>? perf,
    Value<String?>? error,
    Value<int?>? position,
    Value<int>? rowid,
  }) {
    return RunsCompanion(
      runId: runId ?? this.runId,
      queuedId: queuedId ?? this.queuedId,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      thinking: thinking ?? this.thinking,
      origin: origin ?? this.origin,
      queuedAt: queuedAt ?? this.queuedAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      usage: usage ?? this.usage,
      perf: perf ?? this.perf,
      error: error ?? this.error,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (queuedId.present) {
      map['queued_id'] = Variable<String>(queuedId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (thinking.present) {
      map['thinking'] = Variable<bool>(thinking.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (usage.present) {
      map['usage'] = Variable<String>(
        $RunsTable.$converterusagen.toSql(usage.value),
      );
    }
    if (perf.present) {
      map['perf'] = Variable<String>(
        $RunsTable.$converterperfn.toSql(perf.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('runId: $runId, ')
          ..write('queuedId: $queuedId, ')
          ..write('conversationId: $conversationId, ')
          ..write('status: $status, ')
          ..write('thinking: $thinking, ')
          ..write('origin: $origin, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('usage: $usage, ')
          ..write('perf: $perf, ')
          ..write('error: $error, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ToolStepsTable extends ToolSteps
    with TableInfo<$ToolStepsTable, ToolStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToolStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolMeta = const VerificationMeta('tool');
  @override
  late final GeneratedColumn<String> tool = GeneratedColumn<String>(
    'tool',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewMeta = const VerificationMeta(
    'preview',
  );
  @override
  late final GeneratedColumn<String> preview = GeneratedColumn<String>(
    'preview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, Object?>?, String>
  result = GeneratedColumn<String>(
    'result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Map<String, Object?>?>($ToolStepsTable.$converterresultn);
  static const VerificationMeta _resultRawMeta = const VerificationMeta(
    'resultRaw',
  );
  @override
  late final GeneratedColumn<String> resultRaw = GeneratedColumn<String>(
    'result_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userSummaryMeta = const VerificationMeta(
    'userSummary',
  );
  @override
  late final GeneratedColumn<String> userSummary = GeneratedColumn<String>(
    'user_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<double> durationS = GeneratedColumn<double>(
    'duration_s',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqStartedMeta = const VerificationMeta(
    'seqStarted',
  );
  @override
  late final GeneratedColumn<int> seqStarted = GeneratedColumn<int>(
    'seq_started',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqCompletedMeta = const VerificationMeta(
    'seqCompleted',
  );
  @override
  late final GeneratedColumn<int> seqCompleted = GeneratedColumn<int>(
    'seq_completed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvalRequestIdMeta = const VerificationMeta(
    'approvalRequestId',
  );
  @override
  late final GeneratedColumn<String> approvalRequestId =
      GeneratedColumn<String>(
        'approval_request_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    tool,
    status,
    preview,
    result,
    resultRaw,
    userSummary,
    durationS,
    seqStarted,
    seqCompleted,
    approvalRequestId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tool_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ToolStepRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('tool')) {
      context.handle(
        _toolMeta,
        tool.isAcceptableOrUnknown(data['tool']!, _toolMeta),
      );
    } else if (isInserting) {
      context.missing(_toolMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('preview')) {
      context.handle(
        _previewMeta,
        preview.isAcceptableOrUnknown(data['preview']!, _previewMeta),
      );
    }
    if (data.containsKey('result_raw')) {
      context.handle(
        _resultRawMeta,
        resultRaw.isAcceptableOrUnknown(data['result_raw']!, _resultRawMeta),
      );
    }
    if (data.containsKey('user_summary')) {
      context.handle(
        _userSummaryMeta,
        userSummary.isAcceptableOrUnknown(
          data['user_summary']!,
          _userSummaryMeta,
        ),
      );
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    }
    if (data.containsKey('seq_started')) {
      context.handle(
        _seqStartedMeta,
        seqStarted.isAcceptableOrUnknown(data['seq_started']!, _seqStartedMeta),
      );
    }
    if (data.containsKey('seq_completed')) {
      context.handle(
        _seqCompletedMeta,
        seqCompleted.isAcceptableOrUnknown(
          data['seq_completed']!,
          _seqCompletedMeta,
        ),
      );
    }
    if (data.containsKey('approval_request_id')) {
      context.handle(
        _approvalRequestIdMeta,
        approvalRequestId.isAcceptableOrUnknown(
          data['approval_request_id']!,
          _approvalRequestIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ToolStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToolStepRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      tool: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      preview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview'],
      ),
      result: $ToolStepsTable.$converterresultn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        ),
      ),
      resultRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_raw'],
      ),
      userSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_summary'],
      ),
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_s'],
      ),
      seqStarted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq_started'],
      ),
      seqCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq_completed'],
      ),
      approvalRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_request_id'],
      ),
    );
  }

  @override
  $ToolStepsTable createAlias(String alias) {
    return $ToolStepsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, Object?>, String> $converterresult =
      const JsonMapConverter();
  static TypeConverter<Map<String, Object?>?, String?> $converterresultn =
      NullAwareTypeConverter.wrap($converterresult);
}

class ToolStepRow extends DataClass implements Insertable<ToolStepRow> {
  final int id;
  final String runId;
  final String tool;
  final String status;
  final String? preview;
  final Map<String, Object?>? result;
  final String? resultRaw;
  final String? userSummary;
  final double? durationS;
  final int? seqStarted;
  final int? seqCompleted;
  final String? approvalRequestId;
  const ToolStepRow({
    required this.id,
    required this.runId,
    required this.tool,
    required this.status,
    this.preview,
    this.result,
    this.resultRaw,
    this.userSummary,
    this.durationS,
    this.seqStarted,
    this.seqCompleted,
    this.approvalRequestId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<String>(runId);
    map['tool'] = Variable<String>(tool);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || preview != null) {
      map['preview'] = Variable<String>(preview);
    }
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(
        $ToolStepsTable.$converterresultn.toSql(result),
      );
    }
    if (!nullToAbsent || resultRaw != null) {
      map['result_raw'] = Variable<String>(resultRaw);
    }
    if (!nullToAbsent || userSummary != null) {
      map['user_summary'] = Variable<String>(userSummary);
    }
    if (!nullToAbsent || durationS != null) {
      map['duration_s'] = Variable<double>(durationS);
    }
    if (!nullToAbsent || seqStarted != null) {
      map['seq_started'] = Variable<int>(seqStarted);
    }
    if (!nullToAbsent || seqCompleted != null) {
      map['seq_completed'] = Variable<int>(seqCompleted);
    }
    if (!nullToAbsent || approvalRequestId != null) {
      map['approval_request_id'] = Variable<String>(approvalRequestId);
    }
    return map;
  }

  ToolStepsCompanion toCompanion(bool nullToAbsent) {
    return ToolStepsCompanion(
      id: Value(id),
      runId: Value(runId),
      tool: Value(tool),
      status: Value(status),
      preview: preview == null && nullToAbsent
          ? const Value.absent()
          : Value(preview),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
      resultRaw: resultRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(resultRaw),
      userSummary: userSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(userSummary),
      durationS: durationS == null && nullToAbsent
          ? const Value.absent()
          : Value(durationS),
      seqStarted: seqStarted == null && nullToAbsent
          ? const Value.absent()
          : Value(seqStarted),
      seqCompleted: seqCompleted == null && nullToAbsent
          ? const Value.absent()
          : Value(seqCompleted),
      approvalRequestId: approvalRequestId == null && nullToAbsent
          ? const Value.absent()
          : Value(approvalRequestId),
    );
  }

  factory ToolStepRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToolStepRow(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      tool: serializer.fromJson<String>(json['tool']),
      status: serializer.fromJson<String>(json['status']),
      preview: serializer.fromJson<String?>(json['preview']),
      result: serializer.fromJson<Map<String, Object?>?>(json['result']),
      resultRaw: serializer.fromJson<String?>(json['resultRaw']),
      userSummary: serializer.fromJson<String?>(json['userSummary']),
      durationS: serializer.fromJson<double?>(json['durationS']),
      seqStarted: serializer.fromJson<int?>(json['seqStarted']),
      seqCompleted: serializer.fromJson<int?>(json['seqCompleted']),
      approvalRequestId: serializer.fromJson<String?>(
        json['approvalRequestId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<String>(runId),
      'tool': serializer.toJson<String>(tool),
      'status': serializer.toJson<String>(status),
      'preview': serializer.toJson<String?>(preview),
      'result': serializer.toJson<Map<String, Object?>?>(result),
      'resultRaw': serializer.toJson<String?>(resultRaw),
      'userSummary': serializer.toJson<String?>(userSummary),
      'durationS': serializer.toJson<double?>(durationS),
      'seqStarted': serializer.toJson<int?>(seqStarted),
      'seqCompleted': serializer.toJson<int?>(seqCompleted),
      'approvalRequestId': serializer.toJson<String?>(approvalRequestId),
    };
  }

  ToolStepRow copyWith({
    int? id,
    String? runId,
    String? tool,
    String? status,
    Value<String?> preview = const Value.absent(),
    Value<Map<String, Object?>?> result = const Value.absent(),
    Value<String?> resultRaw = const Value.absent(),
    Value<String?> userSummary = const Value.absent(),
    Value<double?> durationS = const Value.absent(),
    Value<int?> seqStarted = const Value.absent(),
    Value<int?> seqCompleted = const Value.absent(),
    Value<String?> approvalRequestId = const Value.absent(),
  }) => ToolStepRow(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    tool: tool ?? this.tool,
    status: status ?? this.status,
    preview: preview.present ? preview.value : this.preview,
    result: result.present ? result.value : this.result,
    resultRaw: resultRaw.present ? resultRaw.value : this.resultRaw,
    userSummary: userSummary.present ? userSummary.value : this.userSummary,
    durationS: durationS.present ? durationS.value : this.durationS,
    seqStarted: seqStarted.present ? seqStarted.value : this.seqStarted,
    seqCompleted: seqCompleted.present ? seqCompleted.value : this.seqCompleted,
    approvalRequestId: approvalRequestId.present
        ? approvalRequestId.value
        : this.approvalRequestId,
  );
  ToolStepRow copyWithCompanion(ToolStepsCompanion data) {
    return ToolStepRow(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      tool: data.tool.present ? data.tool.value : this.tool,
      status: data.status.present ? data.status.value : this.status,
      preview: data.preview.present ? data.preview.value : this.preview,
      result: data.result.present ? data.result.value : this.result,
      resultRaw: data.resultRaw.present ? data.resultRaw.value : this.resultRaw,
      userSummary: data.userSummary.present
          ? data.userSummary.value
          : this.userSummary,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      seqStarted: data.seqStarted.present
          ? data.seqStarted.value
          : this.seqStarted,
      seqCompleted: data.seqCompleted.present
          ? data.seqCompleted.value
          : this.seqCompleted,
      approvalRequestId: data.approvalRequestId.present
          ? data.approvalRequestId.value
          : this.approvalRequestId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToolStepRow(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('tool: $tool, ')
          ..write('status: $status, ')
          ..write('preview: $preview, ')
          ..write('result: $result, ')
          ..write('resultRaw: $resultRaw, ')
          ..write('userSummary: $userSummary, ')
          ..write('durationS: $durationS, ')
          ..write('seqStarted: $seqStarted, ')
          ..write('seqCompleted: $seqCompleted, ')
          ..write('approvalRequestId: $approvalRequestId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    tool,
    status,
    preview,
    result,
    resultRaw,
    userSummary,
    durationS,
    seqStarted,
    seqCompleted,
    approvalRequestId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolStepRow &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.tool == this.tool &&
          other.status == this.status &&
          other.preview == this.preview &&
          other.result == this.result &&
          other.resultRaw == this.resultRaw &&
          other.userSummary == this.userSummary &&
          other.durationS == this.durationS &&
          other.seqStarted == this.seqStarted &&
          other.seqCompleted == this.seqCompleted &&
          other.approvalRequestId == this.approvalRequestId);
}

class ToolStepsCompanion extends UpdateCompanion<ToolStepRow> {
  final Value<int> id;
  final Value<String> runId;
  final Value<String> tool;
  final Value<String> status;
  final Value<String?> preview;
  final Value<Map<String, Object?>?> result;
  final Value<String?> resultRaw;
  final Value<String?> userSummary;
  final Value<double?> durationS;
  final Value<int?> seqStarted;
  final Value<int?> seqCompleted;
  final Value<String?> approvalRequestId;
  const ToolStepsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.tool = const Value.absent(),
    this.status = const Value.absent(),
    this.preview = const Value.absent(),
    this.result = const Value.absent(),
    this.resultRaw = const Value.absent(),
    this.userSummary = const Value.absent(),
    this.durationS = const Value.absent(),
    this.seqStarted = const Value.absent(),
    this.seqCompleted = const Value.absent(),
    this.approvalRequestId = const Value.absent(),
  });
  ToolStepsCompanion.insert({
    this.id = const Value.absent(),
    required String runId,
    required String tool,
    required String status,
    this.preview = const Value.absent(),
    this.result = const Value.absent(),
    this.resultRaw = const Value.absent(),
    this.userSummary = const Value.absent(),
    this.durationS = const Value.absent(),
    this.seqStarted = const Value.absent(),
    this.seqCompleted = const Value.absent(),
    this.approvalRequestId = const Value.absent(),
  }) : runId = Value(runId),
       tool = Value(tool),
       status = Value(status);
  static Insertable<ToolStepRow> custom({
    Expression<int>? id,
    Expression<String>? runId,
    Expression<String>? tool,
    Expression<String>? status,
    Expression<String>? preview,
    Expression<String>? result,
    Expression<String>? resultRaw,
    Expression<String>? userSummary,
    Expression<double>? durationS,
    Expression<int>? seqStarted,
    Expression<int>? seqCompleted,
    Expression<String>? approvalRequestId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (tool != null) 'tool': tool,
      if (status != null) 'status': status,
      if (preview != null) 'preview': preview,
      if (result != null) 'result': result,
      if (resultRaw != null) 'result_raw': resultRaw,
      if (userSummary != null) 'user_summary': userSummary,
      if (durationS != null) 'duration_s': durationS,
      if (seqStarted != null) 'seq_started': seqStarted,
      if (seqCompleted != null) 'seq_completed': seqCompleted,
      if (approvalRequestId != null) 'approval_request_id': approvalRequestId,
    });
  }

  ToolStepsCompanion copyWith({
    Value<int>? id,
    Value<String>? runId,
    Value<String>? tool,
    Value<String>? status,
    Value<String?>? preview,
    Value<Map<String, Object?>?>? result,
    Value<String?>? resultRaw,
    Value<String?>? userSummary,
    Value<double?>? durationS,
    Value<int?>? seqStarted,
    Value<int?>? seqCompleted,
    Value<String?>? approvalRequestId,
  }) {
    return ToolStepsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      tool: tool ?? this.tool,
      status: status ?? this.status,
      preview: preview ?? this.preview,
      result: result ?? this.result,
      resultRaw: resultRaw ?? this.resultRaw,
      userSummary: userSummary ?? this.userSummary,
      durationS: durationS ?? this.durationS,
      seqStarted: seqStarted ?? this.seqStarted,
      seqCompleted: seqCompleted ?? this.seqCompleted,
      approvalRequestId: approvalRequestId ?? this.approvalRequestId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (tool.present) {
      map['tool'] = Variable<String>(tool.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (preview.present) {
      map['preview'] = Variable<String>(preview.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $ToolStepsTable.$converterresultn.toSql(result.value),
      );
    }
    if (resultRaw.present) {
      map['result_raw'] = Variable<String>(resultRaw.value);
    }
    if (userSummary.present) {
      map['user_summary'] = Variable<String>(userSummary.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<double>(durationS.value);
    }
    if (seqStarted.present) {
      map['seq_started'] = Variable<int>(seqStarted.value);
    }
    if (seqCompleted.present) {
      map['seq_completed'] = Variable<int>(seqCompleted.value);
    }
    if (approvalRequestId.present) {
      map['approval_request_id'] = Variable<String>(approvalRequestId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToolStepsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('tool: $tool, ')
          ..write('status: $status, ')
          ..write('preview: $preview, ')
          ..write('result: $result, ')
          ..write('resultRaw: $resultRaw, ')
          ..write('userSummary: $userSummary, ')
          ..write('durationS: $durationS, ')
          ..write('seqStarted: $seqStarted, ')
          ..write('seqCompleted: $seqCompleted, ')
          ..write('approvalRequestId: $approvalRequestId')
          ..write(')'))
        .toString();
  }
}

class $ApprovalsTable extends Approvals
    with TableInfo<$ApprovalsTable, ApprovalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApprovalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  patternKeys = GeneratedColumn<String>(
    'pattern_keys',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($ApprovalsTable.$converterpatternKeys);
  static const VerificationMeta _actionClassMeta = const VerificationMeta(
    'actionClass',
  );
  @override
  late final GeneratedColumn<String> actionClass = GeneratedColumn<String>(
    'action_class',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choiceMeta = const VerificationMeta('choice');
  @override
  late final GeneratedColumn<String> choice = GeneratedColumn<String>(
    'choice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> choices =
      GeneratedColumn<String>(
        'choices',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ApprovalsTable.$converterchoices);
  static const VerificationMeta _decidedByMeta = const VerificationMeta(
    'decidedBy',
  );
  @override
  late final GeneratedColumn<String> decidedBy = GeneratedColumn<String>(
    'decided_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hermesDeadlineMeta = const VerificationMeta(
    'hermesDeadline',
  );
  @override
  late final GeneratedColumn<DateTime> hermesDeadline =
      GeneratedColumn<DateTime>(
        'hermes_deadline',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<DateTime> respondedAt = GeneratedColumn<DateTime>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepIdMeta = const VerificationMeta('stepId');
  @override
  late final GeneratedColumn<int> stepId = GeneratedColumn<int>(
    'step_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    requestId,
    runId,
    conversationId,
    command,
    description,
    patternKeys,
    actionClass,
    status,
    choice,
    choices,
    decidedBy,
    createdAt,
    hermesDeadline,
    expiresAt,
    respondedAt,
    stepId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'approvals';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApprovalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('action_class')) {
      context.handle(
        _actionClassMeta,
        actionClass.isAcceptableOrUnknown(
          data['action_class']!,
          _actionClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actionClassMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('choice')) {
      context.handle(
        _choiceMeta,
        choice.isAcceptableOrUnknown(data['choice']!, _choiceMeta),
      );
    }
    if (data.containsKey('decided_by')) {
      context.handle(
        _decidedByMeta,
        decidedBy.isAcceptableOrUnknown(data['decided_by']!, _decidedByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('hermes_deadline')) {
      context.handle(
        _hermesDeadlineMeta,
        hermesDeadline.isAcceptableOrUnknown(
          data['hermes_deadline']!,
          _hermesDeadlineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hermesDeadlineMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    if (data.containsKey('step_id')) {
      context.handle(
        _stepIdMeta,
        stepId.isAcceptableOrUnknown(data['step_id']!, _stepIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestId};
  @override
  ApprovalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApprovalRow(
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      patternKeys: $ApprovalsTable.$converterpatternKeys.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pattern_keys'],
        )!,
      ),
      actionClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_class'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      choice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choice'],
      ),
      choices: $ApprovalsTable.$converterchoices.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}choices'],
        )!,
      ),
      decidedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      hermesDeadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hermes_deadline'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}responded_at'],
      ),
      stepId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_id'],
      ),
    );
  }

  @override
  $ApprovalsTable createAlias(String alias) {
    return $ApprovalsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterpatternKeys =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterchoices =
      const StringListConverter();
}

class ApprovalRow extends DataClass implements Insertable<ApprovalRow> {
  final String requestId;
  final String runId;
  final String conversationId;
  final String command;
  final String? description;
  final List<String> patternKeys;
  final String actionClass;
  final String status;
  final String? choice;
  final List<String> choices;
  final String? decidedBy;
  final DateTime createdAt;
  final DateTime hermesDeadline;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final int? stepId;
  const ApprovalRow({
    required this.requestId,
    required this.runId,
    required this.conversationId,
    required this.command,
    this.description,
    required this.patternKeys,
    required this.actionClass,
    required this.status,
    this.choice,
    required this.choices,
    this.decidedBy,
    required this.createdAt,
    required this.hermesDeadline,
    required this.expiresAt,
    this.respondedAt,
    this.stepId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_id'] = Variable<String>(requestId);
    map['run_id'] = Variable<String>(runId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['command'] = Variable<String>(command);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['pattern_keys'] = Variable<String>(
        $ApprovalsTable.$converterpatternKeys.toSql(patternKeys),
      );
    }
    map['action_class'] = Variable<String>(actionClass);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || choice != null) {
      map['choice'] = Variable<String>(choice);
    }
    {
      map['choices'] = Variable<String>(
        $ApprovalsTable.$converterchoices.toSql(choices),
      );
    }
    if (!nullToAbsent || decidedBy != null) {
      map['decided_by'] = Variable<String>(decidedBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['hermes_deadline'] = Variable<DateTime>(hermesDeadline);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<DateTime>(respondedAt);
    }
    if (!nullToAbsent || stepId != null) {
      map['step_id'] = Variable<int>(stepId);
    }
    return map;
  }

  ApprovalsCompanion toCompanion(bool nullToAbsent) {
    return ApprovalsCompanion(
      requestId: Value(requestId),
      runId: Value(runId),
      conversationId: Value(conversationId),
      command: Value(command),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      patternKeys: Value(patternKeys),
      actionClass: Value(actionClass),
      status: Value(status),
      choice: choice == null && nullToAbsent
          ? const Value.absent()
          : Value(choice),
      choices: Value(choices),
      decidedBy: decidedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedBy),
      createdAt: Value(createdAt),
      hermesDeadline: Value(hermesDeadline),
      expiresAt: Value(expiresAt),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
      stepId: stepId == null && nullToAbsent
          ? const Value.absent()
          : Value(stepId),
    );
  }

  factory ApprovalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApprovalRow(
      requestId: serializer.fromJson<String>(json['requestId']),
      runId: serializer.fromJson<String>(json['runId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      command: serializer.fromJson<String>(json['command']),
      description: serializer.fromJson<String?>(json['description']),
      patternKeys: serializer.fromJson<List<String>>(json['patternKeys']),
      actionClass: serializer.fromJson<String>(json['actionClass']),
      status: serializer.fromJson<String>(json['status']),
      choice: serializer.fromJson<String?>(json['choice']),
      choices: serializer.fromJson<List<String>>(json['choices']),
      decidedBy: serializer.fromJson<String?>(json['decidedBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      hermesDeadline: serializer.fromJson<DateTime>(json['hermesDeadline']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      respondedAt: serializer.fromJson<DateTime?>(json['respondedAt']),
      stepId: serializer.fromJson<int?>(json['stepId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestId': serializer.toJson<String>(requestId),
      'runId': serializer.toJson<String>(runId),
      'conversationId': serializer.toJson<String>(conversationId),
      'command': serializer.toJson<String>(command),
      'description': serializer.toJson<String?>(description),
      'patternKeys': serializer.toJson<List<String>>(patternKeys),
      'actionClass': serializer.toJson<String>(actionClass),
      'status': serializer.toJson<String>(status),
      'choice': serializer.toJson<String?>(choice),
      'choices': serializer.toJson<List<String>>(choices),
      'decidedBy': serializer.toJson<String?>(decidedBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'hermesDeadline': serializer.toJson<DateTime>(hermesDeadline),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'respondedAt': serializer.toJson<DateTime?>(respondedAt),
      'stepId': serializer.toJson<int?>(stepId),
    };
  }

  ApprovalRow copyWith({
    String? requestId,
    String? runId,
    String? conversationId,
    String? command,
    Value<String?> description = const Value.absent(),
    List<String>? patternKeys,
    String? actionClass,
    String? status,
    Value<String?> choice = const Value.absent(),
    List<String>? choices,
    Value<String?> decidedBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? hermesDeadline,
    DateTime? expiresAt,
    Value<DateTime?> respondedAt = const Value.absent(),
    Value<int?> stepId = const Value.absent(),
  }) => ApprovalRow(
    requestId: requestId ?? this.requestId,
    runId: runId ?? this.runId,
    conversationId: conversationId ?? this.conversationId,
    command: command ?? this.command,
    description: description.present ? description.value : this.description,
    patternKeys: patternKeys ?? this.patternKeys,
    actionClass: actionClass ?? this.actionClass,
    status: status ?? this.status,
    choice: choice.present ? choice.value : this.choice,
    choices: choices ?? this.choices,
    decidedBy: decidedBy.present ? decidedBy.value : this.decidedBy,
    createdAt: createdAt ?? this.createdAt,
    hermesDeadline: hermesDeadline ?? this.hermesDeadline,
    expiresAt: expiresAt ?? this.expiresAt,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
    stepId: stepId.present ? stepId.value : this.stepId,
  );
  ApprovalRow copyWithCompanion(ApprovalsCompanion data) {
    return ApprovalRow(
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      runId: data.runId.present ? data.runId.value : this.runId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      command: data.command.present ? data.command.value : this.command,
      description: data.description.present
          ? data.description.value
          : this.description,
      patternKeys: data.patternKeys.present
          ? data.patternKeys.value
          : this.patternKeys,
      actionClass: data.actionClass.present
          ? data.actionClass.value
          : this.actionClass,
      status: data.status.present ? data.status.value : this.status,
      choice: data.choice.present ? data.choice.value : this.choice,
      choices: data.choices.present ? data.choices.value : this.choices,
      decidedBy: data.decidedBy.present ? data.decidedBy.value : this.decidedBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      hermesDeadline: data.hermesDeadline.present
          ? data.hermesDeadline.value
          : this.hermesDeadline,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
      stepId: data.stepId.present ? data.stepId.value : this.stepId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApprovalRow(')
          ..write('requestId: $requestId, ')
          ..write('runId: $runId, ')
          ..write('conversationId: $conversationId, ')
          ..write('command: $command, ')
          ..write('description: $description, ')
          ..write('patternKeys: $patternKeys, ')
          ..write('actionClass: $actionClass, ')
          ..write('status: $status, ')
          ..write('choice: $choice, ')
          ..write('choices: $choices, ')
          ..write('decidedBy: $decidedBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('hermesDeadline: $hermesDeadline, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('stepId: $stepId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    requestId,
    runId,
    conversationId,
    command,
    description,
    patternKeys,
    actionClass,
    status,
    choice,
    choices,
    decidedBy,
    createdAt,
    hermesDeadline,
    expiresAt,
    respondedAt,
    stepId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApprovalRow &&
          other.requestId == this.requestId &&
          other.runId == this.runId &&
          other.conversationId == this.conversationId &&
          other.command == this.command &&
          other.description == this.description &&
          other.patternKeys == this.patternKeys &&
          other.actionClass == this.actionClass &&
          other.status == this.status &&
          other.choice == this.choice &&
          other.choices == this.choices &&
          other.decidedBy == this.decidedBy &&
          other.createdAt == this.createdAt &&
          other.hermesDeadline == this.hermesDeadline &&
          other.expiresAt == this.expiresAt &&
          other.respondedAt == this.respondedAt &&
          other.stepId == this.stepId);
}

class ApprovalsCompanion extends UpdateCompanion<ApprovalRow> {
  final Value<String> requestId;
  final Value<String> runId;
  final Value<String> conversationId;
  final Value<String> command;
  final Value<String?> description;
  final Value<List<String>> patternKeys;
  final Value<String> actionClass;
  final Value<String> status;
  final Value<String?> choice;
  final Value<List<String>> choices;
  final Value<String?> decidedBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> hermesDeadline;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> respondedAt;
  final Value<int?> stepId;
  final Value<int> rowid;
  const ApprovalsCompanion({
    this.requestId = const Value.absent(),
    this.runId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.command = const Value.absent(),
    this.description = const Value.absent(),
    this.patternKeys = const Value.absent(),
    this.actionClass = const Value.absent(),
    this.status = const Value.absent(),
    this.choice = const Value.absent(),
    this.choices = const Value.absent(),
    this.decidedBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.hermesDeadline = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.stepId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApprovalsCompanion.insert({
    required String requestId,
    required String runId,
    required String conversationId,
    required String command,
    this.description = const Value.absent(),
    required List<String> patternKeys,
    required String actionClass,
    required String status,
    this.choice = const Value.absent(),
    required List<String> choices,
    this.decidedBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime hermesDeadline,
    required DateTime expiresAt,
    this.respondedAt = const Value.absent(),
    this.stepId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : requestId = Value(requestId),
       runId = Value(runId),
       conversationId = Value(conversationId),
       command = Value(command),
       patternKeys = Value(patternKeys),
       actionClass = Value(actionClass),
       status = Value(status),
       choices = Value(choices),
       createdAt = Value(createdAt),
       hermesDeadline = Value(hermesDeadline),
       expiresAt = Value(expiresAt);
  static Insertable<ApprovalRow> custom({
    Expression<String>? requestId,
    Expression<String>? runId,
    Expression<String>? conversationId,
    Expression<String>? command,
    Expression<String>? description,
    Expression<String>? patternKeys,
    Expression<String>? actionClass,
    Expression<String>? status,
    Expression<String>? choice,
    Expression<String>? choices,
    Expression<String>? decidedBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? hermesDeadline,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? respondedAt,
    Expression<int>? stepId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestId != null) 'request_id': requestId,
      if (runId != null) 'run_id': runId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (command != null) 'command': command,
      if (description != null) 'description': description,
      if (patternKeys != null) 'pattern_keys': patternKeys,
      if (actionClass != null) 'action_class': actionClass,
      if (status != null) 'status': status,
      if (choice != null) 'choice': choice,
      if (choices != null) 'choices': choices,
      if (decidedBy != null) 'decided_by': decidedBy,
      if (createdAt != null) 'created_at': createdAt,
      if (hermesDeadline != null) 'hermes_deadline': hermesDeadline,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (stepId != null) 'step_id': stepId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApprovalsCompanion copyWith({
    Value<String>? requestId,
    Value<String>? runId,
    Value<String>? conversationId,
    Value<String>? command,
    Value<String?>? description,
    Value<List<String>>? patternKeys,
    Value<String>? actionClass,
    Value<String>? status,
    Value<String?>? choice,
    Value<List<String>>? choices,
    Value<String?>? decidedBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? hermesDeadline,
    Value<DateTime>? expiresAt,
    Value<DateTime?>? respondedAt,
    Value<int?>? stepId,
    Value<int>? rowid,
  }) {
    return ApprovalsCompanion(
      requestId: requestId ?? this.requestId,
      runId: runId ?? this.runId,
      conversationId: conversationId ?? this.conversationId,
      command: command ?? this.command,
      description: description ?? this.description,
      patternKeys: patternKeys ?? this.patternKeys,
      actionClass: actionClass ?? this.actionClass,
      status: status ?? this.status,
      choice: choice ?? this.choice,
      choices: choices ?? this.choices,
      decidedBy: decidedBy ?? this.decidedBy,
      createdAt: createdAt ?? this.createdAt,
      hermesDeadline: hermesDeadline ?? this.hermesDeadline,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      stepId: stepId ?? this.stepId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (patternKeys.present) {
      map['pattern_keys'] = Variable<String>(
        $ApprovalsTable.$converterpatternKeys.toSql(patternKeys.value),
      );
    }
    if (actionClass.present) {
      map['action_class'] = Variable<String>(actionClass.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (choice.present) {
      map['choice'] = Variable<String>(choice.value);
    }
    if (choices.present) {
      map['choices'] = Variable<String>(
        $ApprovalsTable.$converterchoices.toSql(choices.value),
      );
    }
    if (decidedBy.present) {
      map['decided_by'] = Variable<String>(decidedBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (hermesDeadline.present) {
      map['hermes_deadline'] = Variable<DateTime>(hermesDeadline.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<DateTime>(respondedAt.value);
    }
    if (stepId.present) {
      map['step_id'] = Variable<int>(stepId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApprovalsCompanion(')
          ..write('requestId: $requestId, ')
          ..write('runId: $runId, ')
          ..write('conversationId: $conversationId, ')
          ..write('command: $command, ')
          ..write('description: $description, ')
          ..write('patternKeys: $patternKeys, ')
          ..write('actionClass: $actionClass, ')
          ..write('status: $status, ')
          ..write('choice: $choice, ')
          ..write('choices: $choices, ')
          ..write('decidedBy: $decidedBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('hermesDeadline: $hermesDeadline, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('stepId: $stepId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientMsgIdMeta = const VerificationMeta(
    'clientMsgId',
  );
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
    'client_msg_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thinkingMeta = const VerificationMeta(
    'thinking',
  );
  @override
  late final GeneratedColumn<bool> thinking = GeneratedColumn<bool>(
    'thinking',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("thinking" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<Attachment>, String>
  attachments = GeneratedColumn<String>(
    'attachments',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<Attachment>>($OutboxTable.$converterattachments);
  @override
  List<GeneratedColumn> get $columns => [
    clientMsgId,
    conversationId,
    body,
    thinking,
    createdAt,
    state,
    attempts,
    lastError,
    attachments,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_msg_id')) {
      context.handle(
        _clientMsgIdMeta,
        clientMsgId.isAcceptableOrUnknown(
          data['client_msg_id']!,
          _clientMsgIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMsgIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('thinking')) {
      context.handle(
        _thinkingMeta,
        thinking.isAcceptableOrUnknown(data['thinking']!, _thinkingMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientMsgId};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      clientMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_msg_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      thinking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}thinking'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      attachments: $OutboxTable.$converterattachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attachments'],
        )!,
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Attachment>, String> $converterattachments =
      const AttachmentListConverter();
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String clientMsgId;
  final String? conversationId;
  final String body;
  final bool? thinking;
  final DateTime createdAt;

  /// pending | sending | failed
  final String state;
  final int attempts;
  final String? lastError;

  /// Uploaded photos and files sent with the message (schema 5, B6).
  final List<Attachment> attachments;
  const OutboxRow({
    required this.clientMsgId,
    this.conversationId,
    required this.body,
    this.thinking,
    required this.createdAt,
    required this.state,
    required this.attempts,
    this.lastError,
    required this.attachments,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_msg_id'] = Variable<String>(clientMsgId);
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || thinking != null) {
      map['thinking'] = Variable<bool>(thinking);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    {
      map['attachments'] = Variable<String>(
        $OutboxTable.$converterattachments.toSql(attachments),
      );
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      clientMsgId: Value(clientMsgId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      body: Value(body),
      thinking: thinking == null && nullToAbsent
          ? const Value.absent()
          : Value(thinking),
      createdAt: Value(createdAt),
      state: Value(state),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      attachments: Value(attachments),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      clientMsgId: serializer.fromJson<String>(json['clientMsgId']),
      conversationId: serializer.fromJson<String?>(json['conversationId']),
      body: serializer.fromJson<String>(json['body']),
      thinking: serializer.fromJson<bool?>(json['thinking']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      attachments: serializer.fromJson<List<Attachment>>(json['attachments']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientMsgId': serializer.toJson<String>(clientMsgId),
      'conversationId': serializer.toJson<String?>(conversationId),
      'body': serializer.toJson<String>(body),
      'thinking': serializer.toJson<bool?>(thinking),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'attachments': serializer.toJson<List<Attachment>>(attachments),
    };
  }

  OutboxRow copyWith({
    String? clientMsgId,
    Value<String?> conversationId = const Value.absent(),
    String? body,
    Value<bool?> thinking = const Value.absent(),
    DateTime? createdAt,
    String? state,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    List<Attachment>? attachments,
  }) => OutboxRow(
    clientMsgId: clientMsgId ?? this.clientMsgId,
    conversationId: conversationId.present
        ? conversationId.value
        : this.conversationId,
    body: body ?? this.body,
    thinking: thinking.present ? thinking.value : this.thinking,
    createdAt: createdAt ?? this.createdAt,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    attachments: attachments ?? this.attachments,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      clientMsgId: data.clientMsgId.present
          ? data.clientMsgId.value
          : this.clientMsgId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      body: data.body.present ? data.body.value : this.body,
      thinking: data.thinking.present ? data.thinking.value : this.thinking,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('conversationId: $conversationId, ')
          ..write('body: $body, ')
          ..write('thinking: $thinking, ')
          ..write('createdAt: $createdAt, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('attachments: $attachments')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientMsgId,
    conversationId,
    body,
    thinking,
    createdAt,
    state,
    attempts,
    lastError,
    attachments,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.clientMsgId == this.clientMsgId &&
          other.conversationId == this.conversationId &&
          other.body == this.body &&
          other.thinking == this.thinking &&
          other.createdAt == this.createdAt &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.attachments == this.attachments);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> clientMsgId;
  final Value<String?> conversationId;
  final Value<String> body;
  final Value<bool?> thinking;
  final Value<DateTime> createdAt;
  final Value<String> state;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<List<Attachment>> attachments;
  final Value<int> rowid;
  const OutboxCompanion({
    this.clientMsgId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.body = const Value.absent(),
    this.thinking = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.attachments = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String clientMsgId,
    this.conversationId = const Value.absent(),
    required String body,
    this.thinking = const Value.absent(),
    required DateTime createdAt,
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.attachments = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientMsgId = Value(clientMsgId),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<String>? clientMsgId,
    Expression<String>? conversationId,
    Expression<String>? body,
    Expression<bool>? thinking,
    Expression<DateTime>? createdAt,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? attachments,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (body != null) 'body': body,
      if (thinking != null) 'thinking': thinking,
      if (createdAt != null) 'created_at': createdAt,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (attachments != null) 'attachments': attachments,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? clientMsgId,
    Value<String?>? conversationId,
    Value<String>? body,
    Value<bool?>? thinking,
    Value<DateTime>? createdAt,
    Value<String>? state,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<List<Attachment>>? attachments,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      clientMsgId: clientMsgId ?? this.clientMsgId,
      conversationId: conversationId ?? this.conversationId,
      body: body ?? this.body,
      thinking: thinking ?? this.thinking,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      attachments: attachments ?? this.attachments,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (thinking.present) {
      map['thinking'] = Variable<bool>(thinking.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(
        $OutboxTable.$converterattachments.toSql(attachments.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('conversationId: $conversationId, ')
          ..write('body: $body, ')
          ..write('thinking: $thinking, ')
          ..write('createdAt: $createdAt, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('attachments: $attachments, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<String> epoch = GeneratedColumn<String>(
    'epoch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeqMeta = const VerificationMeta(
    'lastSeq',
  );
  @override
  late final GeneratedColumn<int> lastSeq = GeneratedColumn<int>(
    'last_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, epoch, lastSeq, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    }
    if (data.containsKey('last_seq')) {
      context.handle(
        _lastSeqMeta,
        lastSeq.isAcceptableOrUnknown(data['last_seq']!, _lastSeqMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epoch'],
      ),
      lastSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seq'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final int id;
  final String? epoch;
  final int? lastSeq;
  final DateTime? updatedAt;
  const SyncStateRow({
    required this.id,
    this.epoch,
    this.lastSeq,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || epoch != null) {
      map['epoch'] = Variable<String>(epoch);
    }
    if (!nullToAbsent || lastSeq != null) {
      map['last_seq'] = Variable<int>(lastSeq);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      epoch: epoch == null && nullToAbsent
          ? const Value.absent()
          : Value(epoch),
      lastSeq: lastSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeq),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      id: serializer.fromJson<int>(json['id']),
      epoch: serializer.fromJson<String?>(json['epoch']),
      lastSeq: serializer.fromJson<int?>(json['lastSeq']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'epoch': serializer.toJson<String?>(epoch),
      'lastSeq': serializer.toJson<int?>(lastSeq),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SyncStateRow copyWith({
    int? id,
    Value<String?> epoch = const Value.absent(),
    Value<int?> lastSeq = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => SyncStateRow(
    id: id ?? this.id,
    epoch: epoch.present ? epoch.value : this.epoch,
    lastSeq: lastSeq.present ? lastSeq.value : this.lastSeq,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      id: data.id.present ? data.id.value : this.id,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      lastSeq: data.lastSeq.present ? data.lastSeq.value : this.lastSeq,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('id: $id, ')
          ..write('epoch: $epoch, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, epoch, lastSeq, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.id == this.id &&
          other.epoch == this.epoch &&
          other.lastSeq == this.lastSeq &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<int> id;
  final Value<String?> epoch;
  final Value<int?> lastSeq;
  final Value<DateTime?> updatedAt;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.epoch = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    this.epoch = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<SyncStateRow> custom({
    Expression<int>? id,
    Expression<String>? epoch,
    Expression<int>? lastSeq,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epoch != null) 'epoch': epoch,
      if (lastSeq != null) 'last_seq': lastSeq,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<String?>? epoch,
    Value<int?>? lastSeq,
    Value<DateTime?>? updatedAt,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      epoch: epoch ?? this.epoch,
      lastSeq: lastSeq ?? this.lastSeq,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<String>(epoch.value);
    }
    if (lastSeq.present) {
      map['last_seq'] = Variable<int>(lastSeq.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('epoch: $epoch, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ConnectionLogTable extends ConnectionLog
    with TableInfo<$ConnectionLogTable, ConnectionLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, kind, detail];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectionLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
    );
  }

  @override
  $ConnectionLogTable createAlias(String alias) {
    return $ConnectionLogTable(attachedDatabase, alias);
  }
}

class ConnectionLogRow extends DataClass
    implements Insertable<ConnectionLogRow> {
  final int id;
  final DateTime at;

  /// A `LogKind` name (lib/sync/connection_log.dart).
  final String kind;
  final String? detail;
  const ConnectionLogRow({
    required this.id,
    required this.at,
    required this.kind,
    this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    return map;
  }

  ConnectionLogCompanion toCompanion(bool nullToAbsent) {
    return ConnectionLogCompanion(
      id: Value(id),
      at: Value(at),
      kind: Value(kind),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
    );
  }

  factory ConnectionLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionLogRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      kind: serializer.fromJson<String>(json['kind']),
      detail: serializer.fromJson<String?>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'kind': serializer.toJson<String>(kind),
      'detail': serializer.toJson<String?>(detail),
    };
  }

  ConnectionLogRow copyWith({
    int? id,
    DateTime? at,
    String? kind,
    Value<String?> detail = const Value.absent(),
  }) => ConnectionLogRow(
    id: id ?? this.id,
    at: at ?? this.at,
    kind: kind ?? this.kind,
    detail: detail.present ? detail.value : this.detail,
  );
  ConnectionLogRow copyWithCompanion(ConnectionLogCompanion data) {
    return ConnectionLogRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      kind: data.kind.present ? data.kind.value : this.kind,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionLogRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, kind, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionLogRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.kind == this.kind &&
          other.detail == this.detail);
}

class ConnectionLogCompanion extends UpdateCompanion<ConnectionLogRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> kind;
  final Value<String?> detail;
  const ConnectionLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.kind = const Value.absent(),
    this.detail = const Value.absent(),
  });
  ConnectionLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String kind,
    this.detail = const Value.absent(),
  }) : at = Value(at),
       kind = Value(kind);
  static Insertable<ConnectionLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? kind,
    Expression<String>? detail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (kind != null) 'kind': kind,
      if (detail != null) 'detail': detail,
    });
  }

  ConnectionLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? kind,
    Value<String?>? detail,
  }) {
    return ConnectionLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      kind: kind ?? this.kind,
      detail: detail ?? this.detail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, Object?>, String>
  payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Map<String, Object?>>($CardsTable.$converterpayload);
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    severity,
    ts,
    origin,
    payload,
    receivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      payload: $CardsTable.$converterpayload.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payload'],
        )!,
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, Object?>, String> $converterpayload =
      const JsonMapConverter();
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String type;
  final String severity;
  final DateTime ts;
  final String origin;
  final Map<String, Object?> payload;
  final DateTime receivedAt;
  const CardRow({
    required this.id,
    required this.type,
    required this.severity,
    required this.ts,
    required this.origin,
    required this.payload,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['severity'] = Variable<String>(severity);
    map['ts'] = Variable<DateTime>(ts);
    map['origin'] = Variable<String>(origin);
    {
      map['payload'] = Variable<String>(
        $CardsTable.$converterpayload.toSql(payload),
      );
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      type: Value(type),
      severity: Value(severity),
      ts: Value(ts),
      origin: Value(origin),
      payload: Value(payload),
      receivedAt: Value(receivedAt),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      severity: serializer.fromJson<String>(json['severity']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      origin: serializer.fromJson<String>(json['origin']),
      payload: serializer.fromJson<Map<String, Object?>>(json['payload']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'severity': serializer.toJson<String>(severity),
      'ts': serializer.toJson<DateTime>(ts),
      'origin': serializer.toJson<String>(origin),
      'payload': serializer.toJson<Map<String, Object?>>(payload),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
    };
  }

  CardRow copyWith({
    String? id,
    String? type,
    String? severity,
    DateTime? ts,
    String? origin,
    Map<String, Object?>? payload,
    DateTime? receivedAt,
  }) => CardRow(
    id: id ?? this.id,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    ts: ts ?? this.ts,
    origin: origin ?? this.origin,
    payload: payload ?? this.payload,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      severity: data.severity.present ? data.severity.value : this.severity,
      ts: data.ts.present ? data.ts.value : this.ts,
      origin: data.origin.present ? data.origin.value : this.origin,
      payload: data.payload.present ? data.payload.value : this.payload,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('ts: $ts, ')
          ..write('origin: $origin, ')
          ..write('payload: $payload, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, severity, ts, origin, payload, receivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.severity == this.severity &&
          other.ts == this.ts &&
          other.origin == this.origin &&
          other.payload == this.payload &&
          other.receivedAt == this.receivedAt);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> severity;
  final Value<DateTime> ts;
  final Value<String> origin;
  final Value<Map<String, Object?>> payload;
  final Value<DateTime> receivedAt;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.severity = const Value.absent(),
    this.ts = const Value.absent(),
    this.origin = const Value.absent(),
    this.payload = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String type,
    required String severity,
    required DateTime ts,
    required String origin,
    required Map<String, Object?> payload,
    required DateTime receivedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       severity = Value(severity),
       ts = Value(ts),
       origin = Value(origin),
       payload = Value(payload),
       receivedAt = Value(receivedAt);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? severity,
    Expression<DateTime>? ts,
    Expression<String>? origin,
    Expression<String>? payload,
    Expression<DateTime>? receivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (ts != null) 'ts': ts,
      if (origin != null) 'origin': origin,
      if (payload != null) 'payload': payload,
      if (receivedAt != null) 'received_at': receivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? severity,
    Value<DateTime>? ts,
    Value<String>? origin,
    Value<Map<String, Object?>>? payload,
    Value<DateTime>? receivedAt,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      ts: ts ?? this.ts,
      origin: origin ?? this.origin,
      payload: payload ?? this.payload,
      receivedAt: receivedAt ?? this.receivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(
        $CardsTable.$converterpayload.toSql(payload.value),
      );
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('ts: $ts, ')
          ..write('origin: $origin, ')
          ..write('payload: $payload, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $ToolStepsTable toolSteps = $ToolStepsTable(this);
  late final $ApprovalsTable approvals = $ApprovalsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $ConnectionLogTable connectionLog = $ConnectionLogTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final Index messagesByConversation = Index(
    'messages_by_conversation',
    'CREATE INDEX messages_by_conversation ON messages (conversation_id, id)',
  );
  late final Index runsByConversation = Index(
    'runs_by_conversation',
    'CREATE INDEX runs_by_conversation ON runs (conversation_id)',
  );
  late final Index toolStepsByRun = Index(
    'tool_steps_by_run',
    'CREATE INDEX tool_steps_by_run ON tool_steps (run_id)',
  );
  late final Index approvalsByStatus = Index(
    'approvals_by_status',
    'CREATE INDEX approvals_by_status ON approvals (status)',
  );
  late final Index cardsByType = Index(
    'cards_by_type',
    'CREATE INDEX cards_by_type ON cards (type, ts)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    messages,
    runs,
    toolSteps,
    approvals,
    outbox,
    syncState,
    connectionLog,
    cards,
    messagesByConversation,
    runsByConversation,
    toolStepsByRun,
    approvalsByStatus,
    cardsByType,
  ];
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String?> title,
      Value<String?> preview,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> archived,
      Value<bool> thinking,
      Value<String> origin,
      Value<String?> lastRunId,
      Value<int?> contextTokens,
      Value<int?> contextMax,
      Value<double?> contextPct,
      Value<bool> contextWarn,
      Value<DateTime?> contextMeasuredAt,
      Value<int> tokensIn,
      Value<int> tokensOut,
      Value<int> tokensCacheRead,
      Value<int> tokensTotal,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String?> title,
      Value<String?> preview,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> archived,
      Value<bool> thinking,
      Value<String> origin,
      Value<String?> lastRunId,
      Value<int?> contextTokens,
      Value<int?> contextMax,
      Value<double?> contextPct,
      Value<bool> contextWarn,
      Value<DateTime?> contextMeasuredAt,
      Value<int> tokensIn,
      Value<int> tokensOut,
      Value<int> tokensCacheRead,
      Value<int> tokensTotal,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get thinking => $composableBuilder(
    column: $table.thinking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastRunId => $composableBuilder(
    column: $table.lastRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextTokens => $composableBuilder(
    column: $table.contextTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextMax => $composableBuilder(
    column: $table.contextMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get contextPct => $composableBuilder(
    column: $table.contextPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get contextWarn => $composableBuilder(
    column: $table.contextWarn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get contextMeasuredAt => $composableBuilder(
    column: $table.contextMeasuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensCacheRead => $composableBuilder(
    column: $table.tokensCacheRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensTotal => $composableBuilder(
    column: $table.tokensTotal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get thinking => $composableBuilder(
    column: $table.thinking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastRunId => $composableBuilder(
    column: $table.lastRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextTokens => $composableBuilder(
    column: $table.contextTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextMax => $composableBuilder(
    column: $table.contextMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get contextPct => $composableBuilder(
    column: $table.contextPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get contextWarn => $composableBuilder(
    column: $table.contextWarn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get contextMeasuredAt => $composableBuilder(
    column: $table.contextMeasuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensCacheRead => $composableBuilder(
    column: $table.tokensCacheRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensTotal => $composableBuilder(
    column: $table.tokensTotal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get preview =>
      $composableBuilder(column: $table.preview, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get thinking =>
      $composableBuilder(column: $table.thinking, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get lastRunId =>
      $composableBuilder(column: $table.lastRunId, builder: (column) => column);

  GeneratedColumn<int> get contextTokens => $composableBuilder(
    column: $table.contextTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contextMax => $composableBuilder(
    column: $table.contextMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get contextPct => $composableBuilder(
    column: $table.contextPct,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get contextWarn => $composableBuilder(
    column: $table.contextWarn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get contextMeasuredAt => $composableBuilder(
    column: $table.contextMeasuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensIn =>
      $composableBuilder(column: $table.tokensIn, builder: (column) => column);

  GeneratedColumn<int> get tokensOut =>
      $composableBuilder(column: $table.tokensOut, builder: (column) => column);

  GeneratedColumn<int> get tokensCacheRead => $composableBuilder(
    column: $table.tokensCacheRead,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensTotal => $composableBuilder(
    column: $table.tokensTotal,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          ConversationRow,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            ConversationRow,
            BaseReferences<_$AppDatabase, $ConversationsTable, ConversationRow>,
          ),
          ConversationRow,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> preview = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<bool> thinking = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> lastRunId = const Value.absent(),
                Value<int?> contextTokens = const Value.absent(),
                Value<int?> contextMax = const Value.absent(),
                Value<double?> contextPct = const Value.absent(),
                Value<bool> contextWarn = const Value.absent(),
                Value<DateTime?> contextMeasuredAt = const Value.absent(),
                Value<int> tokensIn = const Value.absent(),
                Value<int> tokensOut = const Value.absent(),
                Value<int> tokensCacheRead = const Value.absent(),
                Value<int> tokensTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                preview: preview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                thinking: thinking,
                origin: origin,
                lastRunId: lastRunId,
                contextTokens: contextTokens,
                contextMax: contextMax,
                contextPct: contextPct,
                contextWarn: contextWarn,
                contextMeasuredAt: contextMeasuredAt,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                tokensCacheRead: tokensCacheRead,
                tokensTotal: tokensTotal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> title = const Value.absent(),
                Value<String?> preview = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> archived = const Value.absent(),
                Value<bool> thinking = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> lastRunId = const Value.absent(),
                Value<int?> contextTokens = const Value.absent(),
                Value<int?> contextMax = const Value.absent(),
                Value<double?> contextPct = const Value.absent(),
                Value<bool> contextWarn = const Value.absent(),
                Value<DateTime?> contextMeasuredAt = const Value.absent(),
                Value<int> tokensIn = const Value.absent(),
                Value<int> tokensOut = const Value.absent(),
                Value<int> tokensCacheRead = const Value.absent(),
                Value<int> tokensTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                preview: preview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                thinking: thinking,
                origin: origin,
                lastRunId: lastRunId,
                contextTokens: contextTokens,
                contextMax: contextMax,
                contextPct: contextPct,
                contextWarn: contextWarn,
                contextMeasuredAt: contextMeasuredAt,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                tokensCacheRead: tokensCacheRead,
                tokensTotal: tokensTotal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      ConversationRow,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        ConversationRow,
        BaseReferences<_$AppDatabase, $ConversationsTable, ConversationRow>,
      ),
      ConversationRow,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      required String conversationId,
      Value<String?> runId,
      required String role,
      required String content,
      Value<String?> interim,
      Value<String?> reasoning,
      required String status,
      Value<String?> clientMsgId,
      required DateTime createdAt,
      Value<List<Attachment>> attachments,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<String> conversationId,
      Value<String?> runId,
      Value<String> role,
      Value<String> content,
      Value<String?> interim,
      Value<String?> reasoning,
      Value<String> status,
      Value<String?> clientMsgId,
      Value<DateTime> createdAt,
      Value<List<Attachment>> attachments,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interim => $composableBuilder(
    column: $table.interim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<Attachment>, List<Attachment>, String>
  get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interim => $composableBuilder(
    column: $table.interim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get interim =>
      $composableBuilder(column: $table.interim, builder: (column) => column);

  GeneratedColumn<String> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Attachment>, String> get attachments =>
      $composableBuilder(
        column: $table.attachments,
        builder: (column) => column,
      );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String?> runId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> interim = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> clientMsgId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<List<Attachment>> attachments = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                runId: runId,
                role: role,
                content: content,
                interim: interim,
                reasoning: reasoning,
                status: status,
                clientMsgId: clientMsgId,
                createdAt: createdAt,
                attachments: attachments,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String conversationId,
                Value<String?> runId = const Value.absent(),
                required String role,
                required String content,
                Value<String?> interim = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                required String status,
                Value<String?> clientMsgId = const Value.absent(),
                required DateTime createdAt,
                Value<List<Attachment>> attachments = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                runId: runId,
                role: role,
                content: content,
                interim: interim,
                reasoning: reasoning,
                status: status,
                clientMsgId: clientMsgId,
                createdAt: createdAt,
                attachments: attachments,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$RunsTableCreateCompanionBuilder =
    RunsCompanion Function({
      required String runId,
      Value<String?> queuedId,
      required String conversationId,
      required String status,
      Value<bool> thinking,
      Value<String> origin,
      Value<DateTime?> queuedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<Map<String, Object?>?> usage,
      Value<Map<String, Object?>?> perf,
      Value<String?> error,
      Value<int?> position,
      Value<int> rowid,
    });
typedef $$RunsTableUpdateCompanionBuilder =
    RunsCompanion Function({
      Value<String> runId,
      Value<String?> queuedId,
      Value<String> conversationId,
      Value<String> status,
      Value<bool> thinking,
      Value<String> origin,
      Value<DateTime?> queuedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<Map<String, Object?>?> usage,
      Value<Map<String, Object?>?> perf,
      Value<String?> error,
      Value<int?> position,
      Value<int> rowid,
    });

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queuedId => $composableBuilder(
    column: $table.queuedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get thinking => $composableBuilder(
    column: $table.thinking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, Object?>?,
    Map<String, Object>?,
    String
  >
  get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, Object?>?,
    Map<String, Object>?,
    String
  >
  get perf => $composableBuilder(
    column: $table.perf,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queuedId => $composableBuilder(
    column: $table.queuedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get thinking => $composableBuilder(
    column: $table.thinking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perf => $composableBuilder(
    column: $table.perf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get queuedId =>
      $composableBuilder(column: $table.queuedId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get thinking =>
      $composableBuilder(column: $table.thinking, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, Object?>?, String> get usage =>
      $composableBuilder(column: $table.usage, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, Object?>?, String> get perf =>
      $composableBuilder(column: $table.perf, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          RunRow,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (RunRow, BaseReferences<_$AppDatabase, $RunsTable, RunRow>),
          RunRow,
          PrefetchHooks Function()
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<String?> queuedId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> thinking = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<DateTime?> queuedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<Map<String, Object?>?> usage = const Value.absent(),
                Value<Map<String, Object?>?> perf = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int?> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion(
                runId: runId,
                queuedId: queuedId,
                conversationId: conversationId,
                status: status,
                thinking: thinking,
                origin: origin,
                queuedAt: queuedAt,
                startedAt: startedAt,
                endedAt: endedAt,
                usage: usage,
                perf: perf,
                error: error,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                Value<String?> queuedId = const Value.absent(),
                required String conversationId,
                required String status,
                Value<bool> thinking = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<DateTime?> queuedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<Map<String, Object?>?> usage = const Value.absent(),
                Value<Map<String, Object?>?> perf = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int?> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion.insert(
                runId: runId,
                queuedId: queuedId,
                conversationId: conversationId,
                status: status,
                thinking: thinking,
                origin: origin,
                queuedAt: queuedAt,
                startedAt: startedAt,
                endedAt: endedAt,
                usage: usage,
                perf: perf,
                error: error,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      RunRow,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (RunRow, BaseReferences<_$AppDatabase, $RunsTable, RunRow>),
      RunRow,
      PrefetchHooks Function()
    >;
typedef $$ToolStepsTableCreateCompanionBuilder =
    ToolStepsCompanion Function({
      Value<int> id,
      required String runId,
      required String tool,
      required String status,
      Value<String?> preview,
      Value<Map<String, Object?>?> result,
      Value<String?> resultRaw,
      Value<String?> userSummary,
      Value<double?> durationS,
      Value<int?> seqStarted,
      Value<int?> seqCompleted,
      Value<String?> approvalRequestId,
    });
typedef $$ToolStepsTableUpdateCompanionBuilder =
    ToolStepsCompanion Function({
      Value<int> id,
      Value<String> runId,
      Value<String> tool,
      Value<String> status,
      Value<String?> preview,
      Value<Map<String, Object?>?> result,
      Value<String?> resultRaw,
      Value<String?> userSummary,
      Value<double?> durationS,
      Value<int?> seqStarted,
      Value<int?> seqCompleted,
      Value<String?> approvalRequestId,
    });

class $$ToolStepsTableFilterComposer
    extends Composer<_$AppDatabase, $ToolStepsTable> {
  $$ToolStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, Object?>?,
    Map<String, Object>?,
    String
  >
  get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get resultRaw => $composableBuilder(
    column: $table.resultRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userSummary => $composableBuilder(
    column: $table.userSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seqStarted => $composableBuilder(
    column: $table.seqStarted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seqCompleted => $composableBuilder(
    column: $table.seqCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvalRequestId => $composableBuilder(
    column: $table.approvalRequestId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ToolStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $ToolStepsTable> {
  $$ToolStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultRaw => $composableBuilder(
    column: $table.resultRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userSummary => $composableBuilder(
    column: $table.userSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seqStarted => $composableBuilder(
    column: $table.seqStarted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seqCompleted => $composableBuilder(
    column: $table.seqCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvalRequestId => $composableBuilder(
    column: $table.approvalRequestId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ToolStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToolStepsTable> {
  $$ToolStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get tool =>
      $composableBuilder(column: $table.tool, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get preview =>
      $composableBuilder(column: $table.preview, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, Object?>?, String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get resultRaw =>
      $composableBuilder(column: $table.resultRaw, builder: (column) => column);

  GeneratedColumn<String> get userSummary => $composableBuilder(
    column: $table.userSummary,
    builder: (column) => column,
  );

  GeneratedColumn<double> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<int> get seqStarted => $composableBuilder(
    column: $table.seqStarted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seqCompleted => $composableBuilder(
    column: $table.seqCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvalRequestId => $composableBuilder(
    column: $table.approvalRequestId,
    builder: (column) => column,
  );
}

class $$ToolStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ToolStepsTable,
          ToolStepRow,
          $$ToolStepsTableFilterComposer,
          $$ToolStepsTableOrderingComposer,
          $$ToolStepsTableAnnotationComposer,
          $$ToolStepsTableCreateCompanionBuilder,
          $$ToolStepsTableUpdateCompanionBuilder,
          (
            ToolStepRow,
            BaseReferences<_$AppDatabase, $ToolStepsTable, ToolStepRow>,
          ),
          ToolStepRow,
          PrefetchHooks Function()
        > {
  $$ToolStepsTableTableManager(_$AppDatabase db, $ToolStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToolStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToolStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToolStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> tool = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> preview = const Value.absent(),
                Value<Map<String, Object?>?> result = const Value.absent(),
                Value<String?> resultRaw = const Value.absent(),
                Value<String?> userSummary = const Value.absent(),
                Value<double?> durationS = const Value.absent(),
                Value<int?> seqStarted = const Value.absent(),
                Value<int?> seqCompleted = const Value.absent(),
                Value<String?> approvalRequestId = const Value.absent(),
              }) => ToolStepsCompanion(
                id: id,
                runId: runId,
                tool: tool,
                status: status,
                preview: preview,
                result: result,
                resultRaw: resultRaw,
                userSummary: userSummary,
                durationS: durationS,
                seqStarted: seqStarted,
                seqCompleted: seqCompleted,
                approvalRequestId: approvalRequestId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String runId,
                required String tool,
                required String status,
                Value<String?> preview = const Value.absent(),
                Value<Map<String, Object?>?> result = const Value.absent(),
                Value<String?> resultRaw = const Value.absent(),
                Value<String?> userSummary = const Value.absent(),
                Value<double?> durationS = const Value.absent(),
                Value<int?> seqStarted = const Value.absent(),
                Value<int?> seqCompleted = const Value.absent(),
                Value<String?> approvalRequestId = const Value.absent(),
              }) => ToolStepsCompanion.insert(
                id: id,
                runId: runId,
                tool: tool,
                status: status,
                preview: preview,
                result: result,
                resultRaw: resultRaw,
                userSummary: userSummary,
                durationS: durationS,
                seqStarted: seqStarted,
                seqCompleted: seqCompleted,
                approvalRequestId: approvalRequestId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ToolStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ToolStepsTable,
      ToolStepRow,
      $$ToolStepsTableFilterComposer,
      $$ToolStepsTableOrderingComposer,
      $$ToolStepsTableAnnotationComposer,
      $$ToolStepsTableCreateCompanionBuilder,
      $$ToolStepsTableUpdateCompanionBuilder,
      (
        ToolStepRow,
        BaseReferences<_$AppDatabase, $ToolStepsTable, ToolStepRow>,
      ),
      ToolStepRow,
      PrefetchHooks Function()
    >;
typedef $$ApprovalsTableCreateCompanionBuilder =
    ApprovalsCompanion Function({
      required String requestId,
      required String runId,
      required String conversationId,
      required String command,
      Value<String?> description,
      required List<String> patternKeys,
      required String actionClass,
      required String status,
      Value<String?> choice,
      required List<String> choices,
      Value<String?> decidedBy,
      required DateTime createdAt,
      required DateTime hermesDeadline,
      required DateTime expiresAt,
      Value<DateTime?> respondedAt,
      Value<int?> stepId,
      Value<int> rowid,
    });
typedef $$ApprovalsTableUpdateCompanionBuilder =
    ApprovalsCompanion Function({
      Value<String> requestId,
      Value<String> runId,
      Value<String> conversationId,
      Value<String> command,
      Value<String?> description,
      Value<List<String>> patternKeys,
      Value<String> actionClass,
      Value<String> status,
      Value<String?> choice,
      Value<List<String>> choices,
      Value<String?> decidedBy,
      Value<DateTime> createdAt,
      Value<DateTime> hermesDeadline,
      Value<DateTime> expiresAt,
      Value<DateTime?> respondedAt,
      Value<int?> stepId,
      Value<int> rowid,
    });

class $$ApprovalsTableFilterComposer
    extends Composer<_$AppDatabase, $ApprovalsTable> {
  $$ApprovalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get patternKeys => $composableBuilder(
    column: $table.patternKeys,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get actionClass => $composableBuilder(
    column: $table.actionClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choice => $composableBuilder(
    column: $table.choice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get decidedBy => $composableBuilder(
    column: $table.decidedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hermesDeadline => $composableBuilder(
    column: $table.hermesDeadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApprovalsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApprovalsTable> {
  $$ApprovalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternKeys => $composableBuilder(
    column: $table.patternKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionClass => $composableBuilder(
    column: $table.actionClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choice => $composableBuilder(
    column: $table.choice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedBy => $composableBuilder(
    column: $table.decidedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hermesDeadline => $composableBuilder(
    column: $table.hermesDeadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApprovalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApprovalsTable> {
  $$ApprovalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get patternKeys =>
      $composableBuilder(
        column: $table.patternKeys,
        builder: (column) => column,
      );

  GeneratedColumn<String> get actionClass => $composableBuilder(
    column: $table.actionClass,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get choice =>
      $composableBuilder(column: $table.choice, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get choices =>
      $composableBuilder(column: $table.choices, builder: (column) => column);

  GeneratedColumn<String> get decidedBy =>
      $composableBuilder(column: $table.decidedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get hermesDeadline => $composableBuilder(
    column: $table.hermesDeadline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stepId =>
      $composableBuilder(column: $table.stepId, builder: (column) => column);
}

class $$ApprovalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApprovalsTable,
          ApprovalRow,
          $$ApprovalsTableFilterComposer,
          $$ApprovalsTableOrderingComposer,
          $$ApprovalsTableAnnotationComposer,
          $$ApprovalsTableCreateCompanionBuilder,
          $$ApprovalsTableUpdateCompanionBuilder,
          (
            ApprovalRow,
            BaseReferences<_$AppDatabase, $ApprovalsTable, ApprovalRow>,
          ),
          ApprovalRow,
          PrefetchHooks Function()
        > {
  $$ApprovalsTableTableManager(_$AppDatabase db, $ApprovalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApprovalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApprovalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApprovalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> requestId = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<List<String>> patternKeys = const Value.absent(),
                Value<String> actionClass = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> choice = const Value.absent(),
                Value<List<String>> choices = const Value.absent(),
                Value<String?> decidedBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> hermesDeadline = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<int?> stepId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApprovalsCompanion(
                requestId: requestId,
                runId: runId,
                conversationId: conversationId,
                command: command,
                description: description,
                patternKeys: patternKeys,
                actionClass: actionClass,
                status: status,
                choice: choice,
                choices: choices,
                decidedBy: decidedBy,
                createdAt: createdAt,
                hermesDeadline: hermesDeadline,
                expiresAt: expiresAt,
                respondedAt: respondedAt,
                stepId: stepId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String requestId,
                required String runId,
                required String conversationId,
                required String command,
                Value<String?> description = const Value.absent(),
                required List<String> patternKeys,
                required String actionClass,
                required String status,
                Value<String?> choice = const Value.absent(),
                required List<String> choices,
                Value<String?> decidedBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime hermesDeadline,
                required DateTime expiresAt,
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<int?> stepId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApprovalsCompanion.insert(
                requestId: requestId,
                runId: runId,
                conversationId: conversationId,
                command: command,
                description: description,
                patternKeys: patternKeys,
                actionClass: actionClass,
                status: status,
                choice: choice,
                choices: choices,
                decidedBy: decidedBy,
                createdAt: createdAt,
                hermesDeadline: hermesDeadline,
                expiresAt: expiresAt,
                respondedAt: respondedAt,
                stepId: stepId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApprovalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApprovalsTable,
      ApprovalRow,
      $$ApprovalsTableFilterComposer,
      $$ApprovalsTableOrderingComposer,
      $$ApprovalsTableAnnotationComposer,
      $$ApprovalsTableCreateCompanionBuilder,
      $$ApprovalsTableUpdateCompanionBuilder,
      (
        ApprovalRow,
        BaseReferences<_$AppDatabase, $ApprovalsTable, ApprovalRow>,
      ),
      ApprovalRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      required String clientMsgId,
      Value<String?> conversationId,
      required String body,
      Value<bool?> thinking,
      required DateTime createdAt,
      Value<String> state,
      Value<int> attempts,
      Value<String?> lastError,
      Value<List<Attachment>> attachments,
      Value<int> rowid,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<String> clientMsgId,
      Value<String?> conversationId,
      Value<String> body,
      Value<bool?> thinking,
      Value<DateTime> createdAt,
      Value<String> state,
      Value<int> attempts,
      Value<String?> lastError,
      Value<List<Attachment>> attachments,
      Value<int> rowid,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get thinking => $composableBuilder(
    column: $table.thinking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<Attachment>, List<Attachment>, String>
  get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get thinking => $composableBuilder(
    column: $table.thinking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get thinking =>
      $composableBuilder(column: $table.thinking, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Attachment>, String> get attachments =>
      $composableBuilder(
        column: $table.attachments,
        builder: (column) => column,
      );
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientMsgId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool?> thinking = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<List<Attachment>> attachments = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                clientMsgId: clientMsgId,
                conversationId: conversationId,
                body: body,
                thinking: thinking,
                createdAt: createdAt,
                state: state,
                attempts: attempts,
                lastError: lastError,
                attachments: attachments,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientMsgId,
                Value<String?> conversationId = const Value.absent(),
                required String body,
                Value<bool?> thinking = const Value.absent(),
                required DateTime createdAt,
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<List<Attachment>> attachments = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                clientMsgId: clientMsgId,
                conversationId: conversationId,
                body: body,
                thinking: thinking,
                createdAt: createdAt,
                state: state,
                attempts: attempts,
                lastError: lastError,
                attachments: attachments,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String?> epoch,
      Value<int?> lastSeq,
      Value<DateTime?> updatedAt,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String?> epoch,
      Value<int?> lastSeq,
      Value<DateTime?> updatedAt,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<int> get lastSeq =>
      $composableBuilder(column: $table.lastSeq, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> epoch = const Value.absent(),
                Value<int?> lastSeq = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                epoch: epoch,
                lastSeq: lastSeq,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> epoch = const Value.absent(),
                Value<int?> lastSeq = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                epoch: epoch,
                lastSeq: lastSeq,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$ConnectionLogTableCreateCompanionBuilder =
    ConnectionLogCompanion Function({
      Value<int> id,
      required DateTime at,
      required String kind,
      Value<String?> detail,
    });
typedef $$ConnectionLogTableUpdateCompanionBuilder =
    ConnectionLogCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<String> kind,
      Value<String?> detail,
    });

class $$ConnectionLogTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionLogTable> {
  $$ConnectionLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConnectionLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionLogTable> {
  $$ConnectionLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionLogTable> {
  $$ConnectionLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$ConnectionLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionLogTable,
          ConnectionLogRow,
          $$ConnectionLogTableFilterComposer,
          $$ConnectionLogTableOrderingComposer,
          $$ConnectionLogTableAnnotationComposer,
          $$ConnectionLogTableCreateCompanionBuilder,
          $$ConnectionLogTableUpdateCompanionBuilder,
          (
            ConnectionLogRow,
            BaseReferences<
              _$AppDatabase,
              $ConnectionLogTable,
              ConnectionLogRow
            >,
          ),
          ConnectionLogRow,
          PrefetchHooks Function()
        > {
  $$ConnectionLogTableTableManager(_$AppDatabase db, $ConnectionLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> detail = const Value.absent(),
              }) => ConnectionLogCompanion(
                id: id,
                at: at,
                kind: kind,
                detail: detail,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String kind,
                Value<String?> detail = const Value.absent(),
              }) => ConnectionLogCompanion.insert(
                id: id,
                at: at,
                kind: kind,
                detail: detail,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConnectionLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionLogTable,
      ConnectionLogRow,
      $$ConnectionLogTableFilterComposer,
      $$ConnectionLogTableOrderingComposer,
      $$ConnectionLogTableAnnotationComposer,
      $$ConnectionLogTableCreateCompanionBuilder,
      $$ConnectionLogTableUpdateCompanionBuilder,
      (
        ConnectionLogRow,
        BaseReferences<_$AppDatabase, $ConnectionLogTable, ConnectionLogRow>,
      ),
      ConnectionLogRow,
      PrefetchHooks Function()
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String id,
      required String type,
      required String severity,
      required DateTime ts,
      required String origin,
      required Map<String, Object?> payload,
      required DateTime receivedAt,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> severity,
      Value<DateTime> ts,
      Value<String> origin,
      Value<Map<String, Object?>> payload,
      Value<DateTime> receivedAt,
      Value<int> rowid,
    });

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, Object?>,
    Map<String, Object>,
    String
  >
  get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, Object?>, String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          CardRow,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardRow, BaseReferences<_$AppDatabase, $CardsTable, CardRow>),
          CardRow,
          PrefetchHooks Function()
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<Map<String, Object?>> payload = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                type: type,
                severity: severity,
                ts: ts,
                origin: origin,
                payload: payload,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String severity,
                required DateTime ts,
                required String origin,
                required Map<String, Object?> payload,
                required DateTime receivedAt,
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                type: type,
                severity: severity,
                ts: ts,
                origin: origin,
                payload: payload,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      CardRow,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardRow, BaseReferences<_$AppDatabase, $CardsTable, CardRow>),
      CardRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$ToolStepsTableTableManager get toolSteps =>
      $$ToolStepsTableTableManager(_db, _db.toolSteps);
  $$ApprovalsTableTableManager get approvals =>
      $$ApprovalsTableTableManager(_db, _db.approvals);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$ConnectionLogTableTableManager get connectionLog =>
      $$ConnectionLogTableTableManager(_db, _db.connectionLog);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
}
