// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'general_database.dart';

// ignore_for_file: type=lint
class $GeneralChatsTable extends GeneralChats
    with TableInfo<$GeneralChatsTable, GeneralChatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneralChatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleSetMeta = const VerificationMeta(
    'titleSet',
  );
  @override
  late final GeneratedColumn<bool> titleSet = GeneratedColumn<bool>(
    'title_set',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("title_set" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningMeta = const VerificationMeta(
    'reasoning',
  );
  @override
  late final GeneratedColumn<bool> reasoning = GeneratedColumn<bool>(
    'reasoning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reasoning" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reasoningEffortMeta = const VerificationMeta(
    'reasoningEffort',
  );
  @override
  late final GeneratedColumn<String> reasoningEffort = GeneratedColumn<String>(
    'reasoning_effort',
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
  static const VerificationMeta _costUsdMeta = const VerificationMeta(
    'costUsd',
  );
  @override
  late final GeneratedColumn<double> costUsd = GeneratedColumn<double>(
    'cost_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPromptTokensMeta = const VerificationMeta(
    'lastPromptTokens',
  );
  @override
  late final GeneratedColumn<int> lastPromptTokens = GeneratedColumn<int>(
    'last_prompt_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastContextLengthMeta = const VerificationMeta(
    'lastContextLength',
  );
  @override
  late final GeneratedColumn<int> lastContextLength = GeneratedColumn<int>(
    'last_context_length',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    titleSet,
    preview,
    modelId,
    reasoning,
    reasoningEffort,
    createdAt,
    updatedAt,
    archived,
    tokensIn,
    tokensOut,
    costUsd,
    lastPromptTokens,
    lastContextLength,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'general_chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeneralChatRow> instance, {
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
    if (data.containsKey('title_set')) {
      context.handle(
        _titleSetMeta,
        titleSet.isAcceptableOrUnknown(data['title_set']!, _titleSetMeta),
      );
    }
    if (data.containsKey('preview')) {
      context.handle(
        _previewMeta,
        preview.isAcceptableOrUnknown(data['preview']!, _previewMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('reasoning')) {
      context.handle(
        _reasoningMeta,
        reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta),
      );
    }
    if (data.containsKey('reasoning_effort')) {
      context.handle(
        _reasoningEffortMeta,
        reasoningEffort.isAcceptableOrUnknown(
          data['reasoning_effort']!,
          _reasoningEffortMeta,
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
    if (data.containsKey('cost_usd')) {
      context.handle(
        _costUsdMeta,
        costUsd.isAcceptableOrUnknown(data['cost_usd']!, _costUsdMeta),
      );
    }
    if (data.containsKey('last_prompt_tokens')) {
      context.handle(
        _lastPromptTokensMeta,
        lastPromptTokens.isAcceptableOrUnknown(
          data['last_prompt_tokens']!,
          _lastPromptTokensMeta,
        ),
      );
    }
    if (data.containsKey('last_context_length')) {
      context.handle(
        _lastContextLengthMeta,
        lastContextLength.isAcceptableOrUnknown(
          data['last_context_length']!,
          _lastContextLengthMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneralChatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneralChatRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      titleSet: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}title_set'],
      )!,
      preview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      reasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reasoning'],
      )!,
      reasoningEffort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning_effort'],
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
      tokensIn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_in'],
      )!,
      tokensOut: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_out'],
      )!,
      costUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_usd'],
      )!,
      lastPromptTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_prompt_tokens'],
      ),
      lastContextLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_context_length'],
      ),
    );
  }

  @override
  $GeneralChatsTable createAlias(String alias) {
    return $GeneralChatsTable(attachedDatabase, alias);
  }
}

class GeneralChatRow extends DataClass implements Insertable<GeneralChatRow> {
  final String id;
  final String? title;

  /// The user renamed the chat; the first message no longer sets the title.
  final bool titleSet;

  /// The latest text, for the Chats list row.
  final String? preview;

  /// The active model; switchable at any time.
  final String modelId;

  /// Thinking for the next message (ignored where the model always thinks
  /// or cannot think).
  final bool reasoning;

  /// Thinking effort for the next message (one of the model's
  /// `supported_efforts`, never `none`); null: the model's default. Schema 2.
  final String? reasoningEffort;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final int tokensIn;
  final int tokensOut;
  final double costUsd;

  /// `usage.prompt_tokens` of the last answer and the model's context
  /// length then: the model chip's ring.
  final int? lastPromptTokens;
  final int? lastContextLength;
  const GeneralChatRow({
    required this.id,
    this.title,
    required this.titleSet,
    this.preview,
    required this.modelId,
    required this.reasoning,
    this.reasoningEffort,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.tokensIn,
    required this.tokensOut,
    required this.costUsd,
    this.lastPromptTokens,
    this.lastContextLength,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['title_set'] = Variable<bool>(titleSet);
    if (!nullToAbsent || preview != null) {
      map['preview'] = Variable<String>(preview);
    }
    map['model_id'] = Variable<String>(modelId);
    map['reasoning'] = Variable<bool>(reasoning);
    if (!nullToAbsent || reasoningEffort != null) {
      map['reasoning_effort'] = Variable<String>(reasoningEffort);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['archived'] = Variable<bool>(archived);
    map['tokens_in'] = Variable<int>(tokensIn);
    map['tokens_out'] = Variable<int>(tokensOut);
    map['cost_usd'] = Variable<double>(costUsd);
    if (!nullToAbsent || lastPromptTokens != null) {
      map['last_prompt_tokens'] = Variable<int>(lastPromptTokens);
    }
    if (!nullToAbsent || lastContextLength != null) {
      map['last_context_length'] = Variable<int>(lastContextLength);
    }
    return map;
  }

  GeneralChatsCompanion toCompanion(bool nullToAbsent) {
    return GeneralChatsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      titleSet: Value(titleSet),
      preview: preview == null && nullToAbsent
          ? const Value.absent()
          : Value(preview),
      modelId: Value(modelId),
      reasoning: Value(reasoning),
      reasoningEffort: reasoningEffort == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoningEffort),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archived: Value(archived),
      tokensIn: Value(tokensIn),
      tokensOut: Value(tokensOut),
      costUsd: Value(costUsd),
      lastPromptTokens: lastPromptTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPromptTokens),
      lastContextLength: lastContextLength == null && nullToAbsent
          ? const Value.absent()
          : Value(lastContextLength),
    );
  }

  factory GeneralChatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneralChatRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      titleSet: serializer.fromJson<bool>(json['titleSet']),
      preview: serializer.fromJson<String?>(json['preview']),
      modelId: serializer.fromJson<String>(json['modelId']),
      reasoning: serializer.fromJson<bool>(json['reasoning']),
      reasoningEffort: serializer.fromJson<String?>(json['reasoningEffort']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archived: serializer.fromJson<bool>(json['archived']),
      tokensIn: serializer.fromJson<int>(json['tokensIn']),
      tokensOut: serializer.fromJson<int>(json['tokensOut']),
      costUsd: serializer.fromJson<double>(json['costUsd']),
      lastPromptTokens: serializer.fromJson<int?>(json['lastPromptTokens']),
      lastContextLength: serializer.fromJson<int?>(json['lastContextLength']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'titleSet': serializer.toJson<bool>(titleSet),
      'preview': serializer.toJson<String?>(preview),
      'modelId': serializer.toJson<String>(modelId),
      'reasoning': serializer.toJson<bool>(reasoning),
      'reasoningEffort': serializer.toJson<String?>(reasoningEffort),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archived': serializer.toJson<bool>(archived),
      'tokensIn': serializer.toJson<int>(tokensIn),
      'tokensOut': serializer.toJson<int>(tokensOut),
      'costUsd': serializer.toJson<double>(costUsd),
      'lastPromptTokens': serializer.toJson<int?>(lastPromptTokens),
      'lastContextLength': serializer.toJson<int?>(lastContextLength),
    };
  }

  GeneralChatRow copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    bool? titleSet,
    Value<String?> preview = const Value.absent(),
    String? modelId,
    bool? reasoning,
    Value<String?> reasoningEffort = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    int? tokensIn,
    int? tokensOut,
    double? costUsd,
    Value<int?> lastPromptTokens = const Value.absent(),
    Value<int?> lastContextLength = const Value.absent(),
  }) => GeneralChatRow(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    titleSet: titleSet ?? this.titleSet,
    preview: preview.present ? preview.value : this.preview,
    modelId: modelId ?? this.modelId,
    reasoning: reasoning ?? this.reasoning,
    reasoningEffort: reasoningEffort.present
        ? reasoningEffort.value
        : this.reasoningEffort,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archived: archived ?? this.archived,
    tokensIn: tokensIn ?? this.tokensIn,
    tokensOut: tokensOut ?? this.tokensOut,
    costUsd: costUsd ?? this.costUsd,
    lastPromptTokens: lastPromptTokens.present
        ? lastPromptTokens.value
        : this.lastPromptTokens,
    lastContextLength: lastContextLength.present
        ? lastContextLength.value
        : this.lastContextLength,
  );
  GeneralChatRow copyWithCompanion(GeneralChatsCompanion data) {
    return GeneralChatRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleSet: data.titleSet.present ? data.titleSet.value : this.titleSet,
      preview: data.preview.present ? data.preview.value : this.preview,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      reasoningEffort: data.reasoningEffort.present
          ? data.reasoningEffort.value
          : this.reasoningEffort,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archived: data.archived.present ? data.archived.value : this.archived,
      tokensIn: data.tokensIn.present ? data.tokensIn.value : this.tokensIn,
      tokensOut: data.tokensOut.present ? data.tokensOut.value : this.tokensOut,
      costUsd: data.costUsd.present ? data.costUsd.value : this.costUsd,
      lastPromptTokens: data.lastPromptTokens.present
          ? data.lastPromptTokens.value
          : this.lastPromptTokens,
      lastContextLength: data.lastContextLength.present
          ? data.lastContextLength.value
          : this.lastContextLength,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneralChatRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleSet: $titleSet, ')
          ..write('preview: $preview, ')
          ..write('modelId: $modelId, ')
          ..write('reasoning: $reasoning, ')
          ..write('reasoningEffort: $reasoningEffort, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('costUsd: $costUsd, ')
          ..write('lastPromptTokens: $lastPromptTokens, ')
          ..write('lastContextLength: $lastContextLength')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    titleSet,
    preview,
    modelId,
    reasoning,
    reasoningEffort,
    createdAt,
    updatedAt,
    archived,
    tokensIn,
    tokensOut,
    costUsd,
    lastPromptTokens,
    lastContextLength,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneralChatRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleSet == this.titleSet &&
          other.preview == this.preview &&
          other.modelId == this.modelId &&
          other.reasoning == this.reasoning &&
          other.reasoningEffort == this.reasoningEffort &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archived == this.archived &&
          other.tokensIn == this.tokensIn &&
          other.tokensOut == this.tokensOut &&
          other.costUsd == this.costUsd &&
          other.lastPromptTokens == this.lastPromptTokens &&
          other.lastContextLength == this.lastContextLength);
}

class GeneralChatsCompanion extends UpdateCompanion<GeneralChatRow> {
  final Value<String> id;
  final Value<String?> title;
  final Value<bool> titleSet;
  final Value<String?> preview;
  final Value<String> modelId;
  final Value<bool> reasoning;
  final Value<String?> reasoningEffort;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> archived;
  final Value<int> tokensIn;
  final Value<int> tokensOut;
  final Value<double> costUsd;
  final Value<int?> lastPromptTokens;
  final Value<int?> lastContextLength;
  final Value<int> rowid;
  const GeneralChatsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.titleSet = const Value.absent(),
    this.preview = const Value.absent(),
    this.modelId = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.reasoningEffort = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.lastPromptTokens = const Value.absent(),
    this.lastContextLength = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneralChatsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.titleSet = const Value.absent(),
    this.preview = const Value.absent(),
    required String modelId,
    this.reasoning = const Value.absent(),
    this.reasoningEffort = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archived = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.lastPromptTokens = const Value.absent(),
    this.lastContextLength = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       modelId = Value(modelId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GeneralChatRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? titleSet,
    Expression<String>? preview,
    Expression<String>? modelId,
    Expression<bool>? reasoning,
    Expression<String>? reasoningEffort,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? archived,
    Expression<int>? tokensIn,
    Expression<int>? tokensOut,
    Expression<double>? costUsd,
    Expression<int>? lastPromptTokens,
    Expression<int>? lastContextLength,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleSet != null) 'title_set': titleSet,
      if (preview != null) 'preview': preview,
      if (modelId != null) 'model_id': modelId,
      if (reasoning != null) 'reasoning': reasoning,
      if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archived != null) 'archived': archived,
      if (tokensIn != null) 'tokens_in': tokensIn,
      if (tokensOut != null) 'tokens_out': tokensOut,
      if (costUsd != null) 'cost_usd': costUsd,
      if (lastPromptTokens != null) 'last_prompt_tokens': lastPromptTokens,
      if (lastContextLength != null) 'last_context_length': lastContextLength,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneralChatsCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<bool>? titleSet,
    Value<String?>? preview,
    Value<String>? modelId,
    Value<bool>? reasoning,
    Value<String?>? reasoningEffort,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? archived,
    Value<int>? tokensIn,
    Value<int>? tokensOut,
    Value<double>? costUsd,
    Value<int?>? lastPromptTokens,
    Value<int?>? lastContextLength,
    Value<int>? rowid,
  }) {
    return GeneralChatsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleSet: titleSet ?? this.titleSet,
      preview: preview ?? this.preview,
      modelId: modelId ?? this.modelId,
      reasoning: reasoning ?? this.reasoning,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      costUsd: costUsd ?? this.costUsd,
      lastPromptTokens: lastPromptTokens ?? this.lastPromptTokens,
      lastContextLength: lastContextLength ?? this.lastContextLength,
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
    if (titleSet.present) {
      map['title_set'] = Variable<bool>(titleSet.value);
    }
    if (preview.present) {
      map['preview'] = Variable<String>(preview.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<bool>(reasoning.value);
    }
    if (reasoningEffort.present) {
      map['reasoning_effort'] = Variable<String>(reasoningEffort.value);
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
    if (tokensIn.present) {
      map['tokens_in'] = Variable<int>(tokensIn.value);
    }
    if (tokensOut.present) {
      map['tokens_out'] = Variable<int>(tokensOut.value);
    }
    if (costUsd.present) {
      map['cost_usd'] = Variable<double>(costUsd.value);
    }
    if (lastPromptTokens.present) {
      map['last_prompt_tokens'] = Variable<int>(lastPromptTokens.value);
    }
    if (lastContextLength.present) {
      map['last_context_length'] = Variable<int>(lastContextLength.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneralChatsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleSet: $titleSet, ')
          ..write('preview: $preview, ')
          ..write('modelId: $modelId, ')
          ..write('reasoning: $reasoning, ')
          ..write('reasoningEffort: $reasoningEffort, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('costUsd: $costUsd, ')
          ..write('lastPromptTokens: $lastPromptTokens, ')
          ..write('lastContextLength: $lastContextLength, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeneralMessagesTable extends GeneralMessages
    with TableInfo<$GeneralMessagesTable, GeneralMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneralMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
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
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryAfterSMeta = const VerificationMeta(
    'retryAfterS',
  );
  @override
  late final GeneratedColumn<int> retryAfterS = GeneratedColumn<int>(
    'retry_after_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishReasonMeta = const VerificationMeta(
    'finishReason',
  );
  @override
  late final GeneratedColumn<String> finishReason = GeneratedColumn<String>(
    'finish_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensInMeta = const VerificationMeta(
    'tokensIn',
  );
  @override
  late final GeneratedColumn<int> tokensIn = GeneratedColumn<int>(
    'tokens_in',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensOutMeta = const VerificationMeta(
    'tokensOut',
  );
  @override
  late final GeneratedColumn<int> tokensOut = GeneratedColumn<int>(
    'tokens_out',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensReasoningMeta = const VerificationMeta(
    'tokensReasoning',
  );
  @override
  late final GeneratedColumn<int> tokensReasoning = GeneratedColumn<int>(
    'tokens_reasoning',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costUsdMeta = const VerificationMeta(
    'costUsd',
  );
  @override
  late final GeneratedColumn<double> costUsd = GeneratedColumn<double>(
    'cost_usd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _generationIdMeta = const VerificationMeta(
    'generationId',
  );
  @override
  late final GeneratedColumn<String> generationId = GeneratedColumn<String>(
    'generation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerWarningMeta = const VerificationMeta(
    'providerWarning',
  );
  @override
  late final GeneratedColumn<String> providerWarning = GeneratedColumn<String>(
    'provider_warning',
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
  List<GeneratedColumn> get $columns => [
    id,
    chatId,
    seq,
    role,
    content,
    reasoning,
    modelId,
    provider,
    status,
    errorCode,
    errorMessage,
    retryAfterS,
    finishReason,
    tokensIn,
    tokensOut,
    tokensReasoning,
    costUsd,
    generationId,
    providerWarning,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'general_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeneralMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
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
    }
    if (data.containsKey('reasoning')) {
      context.handle(
        _reasoningMeta,
        reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
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
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_after_s')) {
      context.handle(
        _retryAfterSMeta,
        retryAfterS.isAcceptableOrUnknown(
          data['retry_after_s']!,
          _retryAfterSMeta,
        ),
      );
    }
    if (data.containsKey('finish_reason')) {
      context.handle(
        _finishReasonMeta,
        finishReason.isAcceptableOrUnknown(
          data['finish_reason']!,
          _finishReasonMeta,
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
    if (data.containsKey('tokens_reasoning')) {
      context.handle(
        _tokensReasoningMeta,
        tokensReasoning.isAcceptableOrUnknown(
          data['tokens_reasoning']!,
          _tokensReasoningMeta,
        ),
      );
    }
    if (data.containsKey('cost_usd')) {
      context.handle(
        _costUsdMeta,
        costUsd.isAcceptableOrUnknown(data['cost_usd']!, _costUsdMeta),
      );
    }
    if (data.containsKey('generation_id')) {
      context.handle(
        _generationIdMeta,
        generationId.isAcceptableOrUnknown(
          data['generation_id']!,
          _generationIdMeta,
        ),
      );
    }
    if (data.containsKey('provider_warning')) {
      context.handle(
        _providerWarningMeta,
        providerWarning.isAcceptableOrUnknown(
          data['provider_warning']!,
          _providerWarningMeta,
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
  GeneralMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneralMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      reasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryAfterS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_after_s'],
      ),
      finishReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finish_reason'],
      ),
      tokensIn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_in'],
      ),
      tokensOut: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_out'],
      ),
      tokensReasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_reasoning'],
      ),
      costUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_usd'],
      ),
      generationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generation_id'],
      ),
      providerWarning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_warning'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GeneralMessagesTable createAlias(String alias) {
    return $GeneralMessagesTable(attachedDatabase, alias);
  }
}

class GeneralMessageRow extends DataClass
    implements Insertable<GeneralMessageRow> {
  final String id;
  final String chatId;

  /// Order inside the chat (1, 2, 3 …).
  final int seq;

  /// `user`, `assistant`, or `switch` (the “Switched to …” marker; never
  /// sent to the model).
  final String role;
  final String content;
  final String? reasoning;

  /// Assistant: the model that answered. Switch: the new model.
  final String? modelId;

  /// The inference provider OpenRouter routed to (from the stream).
  final String? provider;

  /// `streaming`, `final`, `stopped`, `failed` (assistant); `final` otherwise.
  final String status;

  /// [GeneralFailure.code] of a failed answer, and its message.
  final String? errorCode;
  final String? errorMessage;

  /// Seconds to wait before Retry (429).
  final int? retryAfterS;
  final String? finishReason;
  final int? tokensIn;
  final int? tokensOut;
  final int? tokensReasoning;
  final double? costUsd;

  /// OpenRouter's generation id (`x-generation-id`): the cost of a stopped
  /// answer is looked up with it.
  final String? generationId;

  /// The answer came from a provider that is not on the model's
  /// zero-retention list: `pending` until the user acknowledges it,
  /// then `acknowledged`.
  final String? providerWarning;
  final DateTime createdAt;
  const GeneralMessageRow({
    required this.id,
    required this.chatId,
    required this.seq,
    required this.role,
    required this.content,
    this.reasoning,
    this.modelId,
    this.provider,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.retryAfterS,
    this.finishReason,
    this.tokensIn,
    this.tokensOut,
    this.tokensReasoning,
    this.costUsd,
    this.generationId,
    this.providerWarning,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chat_id'] = Variable<String>(chatId);
    map['seq'] = Variable<int>(seq);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || reasoning != null) {
      map['reasoning'] = Variable<String>(reasoning);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || retryAfterS != null) {
      map['retry_after_s'] = Variable<int>(retryAfterS);
    }
    if (!nullToAbsent || finishReason != null) {
      map['finish_reason'] = Variable<String>(finishReason);
    }
    if (!nullToAbsent || tokensIn != null) {
      map['tokens_in'] = Variable<int>(tokensIn);
    }
    if (!nullToAbsent || tokensOut != null) {
      map['tokens_out'] = Variable<int>(tokensOut);
    }
    if (!nullToAbsent || tokensReasoning != null) {
      map['tokens_reasoning'] = Variable<int>(tokensReasoning);
    }
    if (!nullToAbsent || costUsd != null) {
      map['cost_usd'] = Variable<double>(costUsd);
    }
    if (!nullToAbsent || generationId != null) {
      map['generation_id'] = Variable<String>(generationId);
    }
    if (!nullToAbsent || providerWarning != null) {
      map['provider_warning'] = Variable<String>(providerWarning);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GeneralMessagesCompanion toCompanion(bool nullToAbsent) {
    return GeneralMessagesCompanion(
      id: Value(id),
      chatId: Value(chatId),
      seq: Value(seq),
      role: Value(role),
      content: Value(content),
      reasoning: reasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoning),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      status: Value(status),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryAfterS: retryAfterS == null && nullToAbsent
          ? const Value.absent()
          : Value(retryAfterS),
      finishReason: finishReason == null && nullToAbsent
          ? const Value.absent()
          : Value(finishReason),
      tokensIn: tokensIn == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensIn),
      tokensOut: tokensOut == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensOut),
      tokensReasoning: tokensReasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensReasoning),
      costUsd: costUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(costUsd),
      generationId: generationId == null && nullToAbsent
          ? const Value.absent()
          : Value(generationId),
      providerWarning: providerWarning == null && nullToAbsent
          ? const Value.absent()
          : Value(providerWarning),
      createdAt: Value(createdAt),
    );
  }

  factory GeneralMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneralMessageRow(
      id: serializer.fromJson<String>(json['id']),
      chatId: serializer.fromJson<String>(json['chatId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      reasoning: serializer.fromJson<String?>(json['reasoning']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      provider: serializer.fromJson<String?>(json['provider']),
      status: serializer.fromJson<String>(json['status']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryAfterS: serializer.fromJson<int?>(json['retryAfterS']),
      finishReason: serializer.fromJson<String?>(json['finishReason']),
      tokensIn: serializer.fromJson<int?>(json['tokensIn']),
      tokensOut: serializer.fromJson<int?>(json['tokensOut']),
      tokensReasoning: serializer.fromJson<int?>(json['tokensReasoning']),
      costUsd: serializer.fromJson<double?>(json['costUsd']),
      generationId: serializer.fromJson<String?>(json['generationId']),
      providerWarning: serializer.fromJson<String?>(json['providerWarning']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chatId': serializer.toJson<String>(chatId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'reasoning': serializer.toJson<String?>(reasoning),
      'modelId': serializer.toJson<String?>(modelId),
      'provider': serializer.toJson<String?>(provider),
      'status': serializer.toJson<String>(status),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryAfterS': serializer.toJson<int?>(retryAfterS),
      'finishReason': serializer.toJson<String?>(finishReason),
      'tokensIn': serializer.toJson<int?>(tokensIn),
      'tokensOut': serializer.toJson<int?>(tokensOut),
      'tokensReasoning': serializer.toJson<int?>(tokensReasoning),
      'costUsd': serializer.toJson<double?>(costUsd),
      'generationId': serializer.toJson<String?>(generationId),
      'providerWarning': serializer.toJson<String?>(providerWarning),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GeneralMessageRow copyWith({
    String? id,
    String? chatId,
    int? seq,
    String? role,
    String? content,
    Value<String?> reasoning = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    Value<String?> provider = const Value.absent(),
    String? status,
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    Value<int?> retryAfterS = const Value.absent(),
    Value<String?> finishReason = const Value.absent(),
    Value<int?> tokensIn = const Value.absent(),
    Value<int?> tokensOut = const Value.absent(),
    Value<int?> tokensReasoning = const Value.absent(),
    Value<double?> costUsd = const Value.absent(),
    Value<String?> generationId = const Value.absent(),
    Value<String?> providerWarning = const Value.absent(),
    DateTime? createdAt,
  }) => GeneralMessageRow(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    content: content ?? this.content,
    reasoning: reasoning.present ? reasoning.value : this.reasoning,
    modelId: modelId.present ? modelId.value : this.modelId,
    provider: provider.present ? provider.value : this.provider,
    status: status ?? this.status,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryAfterS: retryAfterS.present ? retryAfterS.value : this.retryAfterS,
    finishReason: finishReason.present ? finishReason.value : this.finishReason,
    tokensIn: tokensIn.present ? tokensIn.value : this.tokensIn,
    tokensOut: tokensOut.present ? tokensOut.value : this.tokensOut,
    tokensReasoning: tokensReasoning.present
        ? tokensReasoning.value
        : this.tokensReasoning,
    costUsd: costUsd.present ? costUsd.value : this.costUsd,
    generationId: generationId.present ? generationId.value : this.generationId,
    providerWarning: providerWarning.present
        ? providerWarning.value
        : this.providerWarning,
    createdAt: createdAt ?? this.createdAt,
  );
  GeneralMessageRow copyWithCompanion(GeneralMessagesCompanion data) {
    return GeneralMessageRow(
      id: data.id.present ? data.id.value : this.id,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      provider: data.provider.present ? data.provider.value : this.provider,
      status: data.status.present ? data.status.value : this.status,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryAfterS: data.retryAfterS.present
          ? data.retryAfterS.value
          : this.retryAfterS,
      finishReason: data.finishReason.present
          ? data.finishReason.value
          : this.finishReason,
      tokensIn: data.tokensIn.present ? data.tokensIn.value : this.tokensIn,
      tokensOut: data.tokensOut.present ? data.tokensOut.value : this.tokensOut,
      tokensReasoning: data.tokensReasoning.present
          ? data.tokensReasoning.value
          : this.tokensReasoning,
      costUsd: data.costUsd.present ? data.costUsd.value : this.costUsd,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
      providerWarning: data.providerWarning.present
          ? data.providerWarning.value
          : this.providerWarning,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneralMessageRow(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('reasoning: $reasoning, ')
          ..write('modelId: $modelId, ')
          ..write('provider: $provider, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryAfterS: $retryAfterS, ')
          ..write('finishReason: $finishReason, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('tokensReasoning: $tokensReasoning, ')
          ..write('costUsd: $costUsd, ')
          ..write('generationId: $generationId, ')
          ..write('providerWarning: $providerWarning, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chatId,
    seq,
    role,
    content,
    reasoning,
    modelId,
    provider,
    status,
    errorCode,
    errorMessage,
    retryAfterS,
    finishReason,
    tokensIn,
    tokensOut,
    tokensReasoning,
    costUsd,
    generationId,
    providerWarning,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneralMessageRow &&
          other.id == this.id &&
          other.chatId == this.chatId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.content == this.content &&
          other.reasoning == this.reasoning &&
          other.modelId == this.modelId &&
          other.provider == this.provider &&
          other.status == this.status &&
          other.errorCode == this.errorCode &&
          other.errorMessage == this.errorMessage &&
          other.retryAfterS == this.retryAfterS &&
          other.finishReason == this.finishReason &&
          other.tokensIn == this.tokensIn &&
          other.tokensOut == this.tokensOut &&
          other.tokensReasoning == this.tokensReasoning &&
          other.costUsd == this.costUsd &&
          other.generationId == this.generationId &&
          other.providerWarning == this.providerWarning &&
          other.createdAt == this.createdAt);
}

class GeneralMessagesCompanion extends UpdateCompanion<GeneralMessageRow> {
  final Value<String> id;
  final Value<String> chatId;
  final Value<int> seq;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> reasoning;
  final Value<String?> modelId;
  final Value<String?> provider;
  final Value<String> status;
  final Value<String?> errorCode;
  final Value<String?> errorMessage;
  final Value<int?> retryAfterS;
  final Value<String?> finishReason;
  final Value<int?> tokensIn;
  final Value<int?> tokensOut;
  final Value<int?> tokensReasoning;
  final Value<double?> costUsd;
  final Value<String?> generationId;
  final Value<String?> providerWarning;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GeneralMessagesCompanion({
    this.id = const Value.absent(),
    this.chatId = const Value.absent(),
    this.seq = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.modelId = const Value.absent(),
    this.provider = const Value.absent(),
    this.status = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryAfterS = const Value.absent(),
    this.finishReason = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.tokensReasoning = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.generationId = const Value.absent(),
    this.providerWarning = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneralMessagesCompanion.insert({
    required String id,
    required String chatId,
    required int seq,
    required String role,
    this.content = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.modelId = const Value.absent(),
    this.provider = const Value.absent(),
    required String status,
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryAfterS = const Value.absent(),
    this.finishReason = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.tokensReasoning = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.generationId = const Value.absent(),
    this.providerWarning = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chatId = Value(chatId),
       seq = Value(seq),
       role = Value(role),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<GeneralMessageRow> custom({
    Expression<String>? id,
    Expression<String>? chatId,
    Expression<int>? seq,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? reasoning,
    Expression<String>? modelId,
    Expression<String>? provider,
    Expression<String>? status,
    Expression<String>? errorCode,
    Expression<String>? errorMessage,
    Expression<int>? retryAfterS,
    Expression<String>? finishReason,
    Expression<int>? tokensIn,
    Expression<int>? tokensOut,
    Expression<int>? tokensReasoning,
    Expression<double>? costUsd,
    Expression<String>? generationId,
    Expression<String>? providerWarning,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (reasoning != null) 'reasoning': reasoning,
      if (modelId != null) 'model_id': modelId,
      if (provider != null) 'provider': provider,
      if (status != null) 'status': status,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryAfterS != null) 'retry_after_s': retryAfterS,
      if (finishReason != null) 'finish_reason': finishReason,
      if (tokensIn != null) 'tokens_in': tokensIn,
      if (tokensOut != null) 'tokens_out': tokensOut,
      if (tokensReasoning != null) 'tokens_reasoning': tokensReasoning,
      if (costUsd != null) 'cost_usd': costUsd,
      if (generationId != null) 'generation_id': generationId,
      if (providerWarning != null) 'provider_warning': providerWarning,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneralMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? chatId,
    Value<int>? seq,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? reasoning,
    Value<String?>? modelId,
    Value<String?>? provider,
    Value<String>? status,
    Value<String?>? errorCode,
    Value<String?>? errorMessage,
    Value<int?>? retryAfterS,
    Value<String?>? finishReason,
    Value<int?>? tokensIn,
    Value<int?>? tokensOut,
    Value<int?>? tokensReasoning,
    Value<double?>? costUsd,
    Value<String?>? generationId,
    Value<String?>? providerWarning,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GeneralMessagesCompanion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      content: content ?? this.content,
      reasoning: reasoning ?? this.reasoning,
      modelId: modelId ?? this.modelId,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      retryAfterS: retryAfterS ?? this.retryAfterS,
      finishReason: finishReason ?? this.finishReason,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      costUsd: costUsd ?? this.costUsd,
      generationId: generationId ?? this.generationId,
      providerWarning: providerWarning ?? this.providerWarning,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<String>(reasoning.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryAfterS.present) {
      map['retry_after_s'] = Variable<int>(retryAfterS.value);
    }
    if (finishReason.present) {
      map['finish_reason'] = Variable<String>(finishReason.value);
    }
    if (tokensIn.present) {
      map['tokens_in'] = Variable<int>(tokensIn.value);
    }
    if (tokensOut.present) {
      map['tokens_out'] = Variable<int>(tokensOut.value);
    }
    if (tokensReasoning.present) {
      map['tokens_reasoning'] = Variable<int>(tokensReasoning.value);
    }
    if (costUsd.present) {
      map['cost_usd'] = Variable<double>(costUsd.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<String>(generationId.value);
    }
    if (providerWarning.present) {
      map['provider_warning'] = Variable<String>(providerWarning.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneralMessagesCompanion(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('reasoning: $reasoning, ')
          ..write('modelId: $modelId, ')
          ..write('provider: $provider, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryAfterS: $retryAfterS, ')
          ..write('finishReason: $finishReason, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('tokensReasoning: $tokensReasoning, ')
          ..write('costUsd: $costUsd, ')
          ..write('generationId: $generationId, ')
          ..write('providerWarning: $providerWarning, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeneralAttachmentsTable extends GeneralAttachments
    with TableInfo<$GeneralAttachmentsTable, GeneralAttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneralAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordMeta = const VerificationMeta('ord');
  @override
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, messageId, ord, mime, bytes, size];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'general_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeneralAttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('ord')) {
      context.handle(
        _ordMeta,
        ord.isAcceptableOrUnknown(data['ord']!, _ordMeta),
      );
    } else if (isInserting) {
      context.missing(_ordMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneralAttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneralAttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
    );
  }

  @override
  $GeneralAttachmentsTable createAlias(String alias) {
    return $GeneralAttachmentsTable(attachedDatabase, alias);
  }
}

class GeneralAttachmentRow extends DataClass
    implements Insertable<GeneralAttachmentRow> {
  final String id;
  final String messageId;
  final int ord;
  final String mime;
  final Uint8List bytes;
  final int size;
  const GeneralAttachmentRow({
    required this.id,
    required this.messageId,
    required this.ord,
    required this.mime,
    required this.bytes,
    required this.size,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['ord'] = Variable<int>(ord);
    map['mime'] = Variable<String>(mime);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['size'] = Variable<int>(size);
    return map;
  }

  GeneralAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return GeneralAttachmentsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      ord: Value(ord),
      mime: Value(mime),
      bytes: Value(bytes),
      size: Value(size),
    );
  }

  factory GeneralAttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneralAttachmentRow(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      ord: serializer.fromJson<int>(json['ord']),
      mime: serializer.fromJson<String>(json['mime']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      size: serializer.fromJson<int>(json['size']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'ord': serializer.toJson<int>(ord),
      'mime': serializer.toJson<String>(mime),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'size': serializer.toJson<int>(size),
    };
  }

  GeneralAttachmentRow copyWith({
    String? id,
    String? messageId,
    int? ord,
    String? mime,
    Uint8List? bytes,
    int? size,
  }) => GeneralAttachmentRow(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    ord: ord ?? this.ord,
    mime: mime ?? this.mime,
    bytes: bytes ?? this.bytes,
    size: size ?? this.size,
  );
  GeneralAttachmentRow copyWithCompanion(GeneralAttachmentsCompanion data) {
    return GeneralAttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      ord: data.ord.present ? data.ord.value : this.ord,
      mime: data.mime.present ? data.mime.value : this.mime,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      size: data.size.present ? data.size.value : this.size,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneralAttachmentRow(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('ord: $ord, ')
          ..write('mime: $mime, ')
          ..write('bytes: $bytes, ')
          ..write('size: $size')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    ord,
    mime,
    $driftBlobEquality.hash(bytes),
    size,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneralAttachmentRow &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.ord == this.ord &&
          other.mime == this.mime &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.size == this.size);
}

class GeneralAttachmentsCompanion
    extends UpdateCompanion<GeneralAttachmentRow> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<int> ord;
  final Value<String> mime;
  final Value<Uint8List> bytes;
  final Value<int> size;
  final Value<int> rowid;
  const GeneralAttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.ord = const Value.absent(),
    this.mime = const Value.absent(),
    this.bytes = const Value.absent(),
    this.size = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneralAttachmentsCompanion.insert({
    required String id,
    required String messageId,
    required int ord,
    required String mime,
    required Uint8List bytes,
    required int size,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messageId = Value(messageId),
       ord = Value(ord),
       mime = Value(mime),
       bytes = Value(bytes),
       size = Value(size);
  static Insertable<GeneralAttachmentRow> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<int>? ord,
    Expression<String>? mime,
    Expression<Uint8List>? bytes,
    Expression<int>? size,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (ord != null) 'ord': ord,
      if (mime != null) 'mime': mime,
      if (bytes != null) 'bytes': bytes,
      if (size != null) 'size': size,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneralAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? messageId,
    Value<int>? ord,
    Value<String>? mime,
    Value<Uint8List>? bytes,
    Value<int>? size,
    Value<int>? rowid,
  }) {
    return GeneralAttachmentsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      ord: ord ?? this.ord,
      mime: mime ?? this.mime,
      bytes: bytes ?? this.bytes,
      size: size ?? this.size,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneralAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('ord: $ord, ')
          ..write('mime: $mime, ')
          ..write('bytes: $bytes, ')
          ..write('size: $size, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrModelsTable extends OrModels
    with TableInfo<$OrModelsTable, OrModelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextLengthMeta = const VerificationMeta(
    'contextLength',
  );
  @override
  late final GeneratedColumn<int> contextLength = GeneratedColumn<int>(
    'context_length',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  inputModalities = GeneratedColumn<String>(
    'input_modalities',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($OrModelsTable.$converterinputModalities);
  static const VerificationMeta _pricePromptMeta = const VerificationMeta(
    'pricePrompt',
  );
  @override
  late final GeneratedColumn<double> pricePrompt = GeneratedColumn<double>(
    'price_prompt',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceCompletionMeta = const VerificationMeta(
    'priceCompletion',
  );
  @override
  late final GeneratedColumn<double> priceCompletion = GeneratedColumn<double>(
    'price_completion',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceCacheReadMeta = const VerificationMeta(
    'priceCacheRead',
  );
  @override
  late final GeneratedColumn<double> priceCacheRead = GeneratedColumn<double>(
    'price_cache_read',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasoningSupportedMeta =
      const VerificationMeta('reasoningSupported');
  @override
  late final GeneratedColumn<bool> reasoningSupported = GeneratedColumn<bool>(
    'reasoning_supported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reasoning_supported" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reasoningMandatoryMeta =
      const VerificationMeta('reasoningMandatory');
  @override
  late final GeneratedColumn<bool> reasoningMandatory = GeneratedColumn<bool>(
    'reasoning_mandatory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reasoning_mandatory" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  reasoningEfforts = GeneratedColumn<String>(
    'reasoning_efforts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($OrModelsTable.$converterreasoningEfforts);
  static const VerificationMeta _reasoningDefaultEffortMeta =
      const VerificationMeta('reasoningDefaultEffort');
  @override
  late final GeneratedColumn<String> reasoningDefaultEffort =
      GeneratedColumn<String>(
        'reasoning_default_effort',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  zdrProviders = GeneratedColumn<String>(
    'zdr_providers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($OrModelsTable.$converterzdrProviders);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    contextLength,
    inputModalities,
    pricePrompt,
    priceCompletion,
    priceCacheRead,
    reasoningSupported,
    reasoningMandatory,
    reasoningEfforts,
    reasoningDefaultEffort,
    zdrProviders,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'or_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrModelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('context_length')) {
      context.handle(
        _contextLengthMeta,
        contextLength.isAcceptableOrUnknown(
          data['context_length']!,
          _contextLengthMeta,
        ),
      );
    }
    if (data.containsKey('price_prompt')) {
      context.handle(
        _pricePromptMeta,
        pricePrompt.isAcceptableOrUnknown(
          data['price_prompt']!,
          _pricePromptMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePromptMeta);
    }
    if (data.containsKey('price_completion')) {
      context.handle(
        _priceCompletionMeta,
        priceCompletion.isAcceptableOrUnknown(
          data['price_completion']!,
          _priceCompletionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceCompletionMeta);
    }
    if (data.containsKey('price_cache_read')) {
      context.handle(
        _priceCacheReadMeta,
        priceCacheRead.isAcceptableOrUnknown(
          data['price_cache_read']!,
          _priceCacheReadMeta,
        ),
      );
    }
    if (data.containsKey('reasoning_supported')) {
      context.handle(
        _reasoningSupportedMeta,
        reasoningSupported.isAcceptableOrUnknown(
          data['reasoning_supported']!,
          _reasoningSupportedMeta,
        ),
      );
    }
    if (data.containsKey('reasoning_mandatory')) {
      context.handle(
        _reasoningMandatoryMeta,
        reasoningMandatory.isAcceptableOrUnknown(
          data['reasoning_mandatory']!,
          _reasoningMandatoryMeta,
        ),
      );
    }
    if (data.containsKey('reasoning_default_effort')) {
      context.handle(
        _reasoningDefaultEffortMeta,
        reasoningDefaultEffort.isAcceptableOrUnknown(
          data['reasoning_default_effort']!,
          _reasoningDefaultEffortMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrModelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrModelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contextLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_length'],
      ),
      inputModalities: $OrModelsTable.$converterinputModalities.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}input_modalities'],
        )!,
      ),
      pricePrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_prompt'],
      )!,
      priceCompletion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_completion'],
      )!,
      priceCacheRead: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_cache_read'],
      ),
      reasoningSupported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reasoning_supported'],
      )!,
      reasoningMandatory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reasoning_mandatory'],
      )!,
      reasoningEfforts: $OrModelsTable.$converterreasoningEfforts.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reasoning_efforts'],
        )!,
      ),
      reasoningDefaultEffort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning_default_effort'],
      ),
      zdrProviders: $OrModelsTable.$converterzdrProviders.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}zdr_providers'],
        )!,
      ),
    );
  }

  @override
  $OrModelsTable createAlias(String alias) {
    return $OrModelsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterinputModalities =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterreasoningEfforts =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterzdrProviders =
      const StringListConverter();
}

class OrModelRow extends DataClass implements Insertable<OrModelRow> {
  final String id;
  final String name;
  final int? contextLength;
  final List<String> inputModalities;

  /// USD per token.
  final double pricePrompt;
  final double priceCompletion;
  final double? priceCacheRead;
  final bool reasoningSupported;
  final bool reasoningMandatory;
  final List<String> reasoningEfforts;
  final String? reasoningDefaultEffort;

  /// Providers with a strict zero-retention endpoint for this model (no
  /// Safety Retention). Empty: the model cannot be chosen.
  final List<String> zdrProviders;
  const OrModelRow({
    required this.id,
    required this.name,
    this.contextLength,
    required this.inputModalities,
    required this.pricePrompt,
    required this.priceCompletion,
    this.priceCacheRead,
    required this.reasoningSupported,
    required this.reasoningMandatory,
    required this.reasoningEfforts,
    this.reasoningDefaultEffort,
    required this.zdrProviders,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || contextLength != null) {
      map['context_length'] = Variable<int>(contextLength);
    }
    {
      map['input_modalities'] = Variable<String>(
        $OrModelsTable.$converterinputModalities.toSql(inputModalities),
      );
    }
    map['price_prompt'] = Variable<double>(pricePrompt);
    map['price_completion'] = Variable<double>(priceCompletion);
    if (!nullToAbsent || priceCacheRead != null) {
      map['price_cache_read'] = Variable<double>(priceCacheRead);
    }
    map['reasoning_supported'] = Variable<bool>(reasoningSupported);
    map['reasoning_mandatory'] = Variable<bool>(reasoningMandatory);
    {
      map['reasoning_efforts'] = Variable<String>(
        $OrModelsTable.$converterreasoningEfforts.toSql(reasoningEfforts),
      );
    }
    if (!nullToAbsent || reasoningDefaultEffort != null) {
      map['reasoning_default_effort'] = Variable<String>(
        reasoningDefaultEffort,
      );
    }
    {
      map['zdr_providers'] = Variable<String>(
        $OrModelsTable.$converterzdrProviders.toSql(zdrProviders),
      );
    }
    return map;
  }

  OrModelsCompanion toCompanion(bool nullToAbsent) {
    return OrModelsCompanion(
      id: Value(id),
      name: Value(name),
      contextLength: contextLength == null && nullToAbsent
          ? const Value.absent()
          : Value(contextLength),
      inputModalities: Value(inputModalities),
      pricePrompt: Value(pricePrompt),
      priceCompletion: Value(priceCompletion),
      priceCacheRead: priceCacheRead == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCacheRead),
      reasoningSupported: Value(reasoningSupported),
      reasoningMandatory: Value(reasoningMandatory),
      reasoningEfforts: Value(reasoningEfforts),
      reasoningDefaultEffort: reasoningDefaultEffort == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoningDefaultEffort),
      zdrProviders: Value(zdrProviders),
    );
  }

  factory OrModelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrModelRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      contextLength: serializer.fromJson<int?>(json['contextLength']),
      inputModalities: serializer.fromJson<List<String>>(
        json['inputModalities'],
      ),
      pricePrompt: serializer.fromJson<double>(json['pricePrompt']),
      priceCompletion: serializer.fromJson<double>(json['priceCompletion']),
      priceCacheRead: serializer.fromJson<double?>(json['priceCacheRead']),
      reasoningSupported: serializer.fromJson<bool>(json['reasoningSupported']),
      reasoningMandatory: serializer.fromJson<bool>(json['reasoningMandatory']),
      reasoningEfforts: serializer.fromJson<List<String>>(
        json['reasoningEfforts'],
      ),
      reasoningDefaultEffort: serializer.fromJson<String?>(
        json['reasoningDefaultEffort'],
      ),
      zdrProviders: serializer.fromJson<List<String>>(json['zdrProviders']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'contextLength': serializer.toJson<int?>(contextLength),
      'inputModalities': serializer.toJson<List<String>>(inputModalities),
      'pricePrompt': serializer.toJson<double>(pricePrompt),
      'priceCompletion': serializer.toJson<double>(priceCompletion),
      'priceCacheRead': serializer.toJson<double?>(priceCacheRead),
      'reasoningSupported': serializer.toJson<bool>(reasoningSupported),
      'reasoningMandatory': serializer.toJson<bool>(reasoningMandatory),
      'reasoningEfforts': serializer.toJson<List<String>>(reasoningEfforts),
      'reasoningDefaultEffort': serializer.toJson<String?>(
        reasoningDefaultEffort,
      ),
      'zdrProviders': serializer.toJson<List<String>>(zdrProviders),
    };
  }

  OrModelRow copyWith({
    String? id,
    String? name,
    Value<int?> contextLength = const Value.absent(),
    List<String>? inputModalities,
    double? pricePrompt,
    double? priceCompletion,
    Value<double?> priceCacheRead = const Value.absent(),
    bool? reasoningSupported,
    bool? reasoningMandatory,
    List<String>? reasoningEfforts,
    Value<String?> reasoningDefaultEffort = const Value.absent(),
    List<String>? zdrProviders,
  }) => OrModelRow(
    id: id ?? this.id,
    name: name ?? this.name,
    contextLength: contextLength.present
        ? contextLength.value
        : this.contextLength,
    inputModalities: inputModalities ?? this.inputModalities,
    pricePrompt: pricePrompt ?? this.pricePrompt,
    priceCompletion: priceCompletion ?? this.priceCompletion,
    priceCacheRead: priceCacheRead.present
        ? priceCacheRead.value
        : this.priceCacheRead,
    reasoningSupported: reasoningSupported ?? this.reasoningSupported,
    reasoningMandatory: reasoningMandatory ?? this.reasoningMandatory,
    reasoningEfforts: reasoningEfforts ?? this.reasoningEfforts,
    reasoningDefaultEffort: reasoningDefaultEffort.present
        ? reasoningDefaultEffort.value
        : this.reasoningDefaultEffort,
    zdrProviders: zdrProviders ?? this.zdrProviders,
  );
  OrModelRow copyWithCompanion(OrModelsCompanion data) {
    return OrModelRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      contextLength: data.contextLength.present
          ? data.contextLength.value
          : this.contextLength,
      inputModalities: data.inputModalities.present
          ? data.inputModalities.value
          : this.inputModalities,
      pricePrompt: data.pricePrompt.present
          ? data.pricePrompt.value
          : this.pricePrompt,
      priceCompletion: data.priceCompletion.present
          ? data.priceCompletion.value
          : this.priceCompletion,
      priceCacheRead: data.priceCacheRead.present
          ? data.priceCacheRead.value
          : this.priceCacheRead,
      reasoningSupported: data.reasoningSupported.present
          ? data.reasoningSupported.value
          : this.reasoningSupported,
      reasoningMandatory: data.reasoningMandatory.present
          ? data.reasoningMandatory.value
          : this.reasoningMandatory,
      reasoningEfforts: data.reasoningEfforts.present
          ? data.reasoningEfforts.value
          : this.reasoningEfforts,
      reasoningDefaultEffort: data.reasoningDefaultEffort.present
          ? data.reasoningDefaultEffort.value
          : this.reasoningDefaultEffort,
      zdrProviders: data.zdrProviders.present
          ? data.zdrProviders.value
          : this.zdrProviders,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrModelRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contextLength: $contextLength, ')
          ..write('inputModalities: $inputModalities, ')
          ..write('pricePrompt: $pricePrompt, ')
          ..write('priceCompletion: $priceCompletion, ')
          ..write('priceCacheRead: $priceCacheRead, ')
          ..write('reasoningSupported: $reasoningSupported, ')
          ..write('reasoningMandatory: $reasoningMandatory, ')
          ..write('reasoningEfforts: $reasoningEfforts, ')
          ..write('reasoningDefaultEffort: $reasoningDefaultEffort, ')
          ..write('zdrProviders: $zdrProviders')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    contextLength,
    inputModalities,
    pricePrompt,
    priceCompletion,
    priceCacheRead,
    reasoningSupported,
    reasoningMandatory,
    reasoningEfforts,
    reasoningDefaultEffort,
    zdrProviders,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrModelRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.contextLength == this.contextLength &&
          other.inputModalities == this.inputModalities &&
          other.pricePrompt == this.pricePrompt &&
          other.priceCompletion == this.priceCompletion &&
          other.priceCacheRead == this.priceCacheRead &&
          other.reasoningSupported == this.reasoningSupported &&
          other.reasoningMandatory == this.reasoningMandatory &&
          other.reasoningEfforts == this.reasoningEfforts &&
          other.reasoningDefaultEffort == this.reasoningDefaultEffort &&
          other.zdrProviders == this.zdrProviders);
}

class OrModelsCompanion extends UpdateCompanion<OrModelRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> contextLength;
  final Value<List<String>> inputModalities;
  final Value<double> pricePrompt;
  final Value<double> priceCompletion;
  final Value<double?> priceCacheRead;
  final Value<bool> reasoningSupported;
  final Value<bool> reasoningMandatory;
  final Value<List<String>> reasoningEfforts;
  final Value<String?> reasoningDefaultEffort;
  final Value<List<String>> zdrProviders;
  final Value<int> rowid;
  const OrModelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.contextLength = const Value.absent(),
    this.inputModalities = const Value.absent(),
    this.pricePrompt = const Value.absent(),
    this.priceCompletion = const Value.absent(),
    this.priceCacheRead = const Value.absent(),
    this.reasoningSupported = const Value.absent(),
    this.reasoningMandatory = const Value.absent(),
    this.reasoningEfforts = const Value.absent(),
    this.reasoningDefaultEffort = const Value.absent(),
    this.zdrProviders = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrModelsCompanion.insert({
    required String id,
    required String name,
    this.contextLength = const Value.absent(),
    required List<String> inputModalities,
    required double pricePrompt,
    required double priceCompletion,
    this.priceCacheRead = const Value.absent(),
    this.reasoningSupported = const Value.absent(),
    this.reasoningMandatory = const Value.absent(),
    this.reasoningEfforts = const Value.absent(),
    this.reasoningDefaultEffort = const Value.absent(),
    this.zdrProviders = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       inputModalities = Value(inputModalities),
       pricePrompt = Value(pricePrompt),
       priceCompletion = Value(priceCompletion);
  static Insertable<OrModelRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? contextLength,
    Expression<String>? inputModalities,
    Expression<double>? pricePrompt,
    Expression<double>? priceCompletion,
    Expression<double>? priceCacheRead,
    Expression<bool>? reasoningSupported,
    Expression<bool>? reasoningMandatory,
    Expression<String>? reasoningEfforts,
    Expression<String>? reasoningDefaultEffort,
    Expression<String>? zdrProviders,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (contextLength != null) 'context_length': contextLength,
      if (inputModalities != null) 'input_modalities': inputModalities,
      if (pricePrompt != null) 'price_prompt': pricePrompt,
      if (priceCompletion != null) 'price_completion': priceCompletion,
      if (priceCacheRead != null) 'price_cache_read': priceCacheRead,
      if (reasoningSupported != null) 'reasoning_supported': reasoningSupported,
      if (reasoningMandatory != null) 'reasoning_mandatory': reasoningMandatory,
      if (reasoningEfforts != null) 'reasoning_efforts': reasoningEfforts,
      if (reasoningDefaultEffort != null)
        'reasoning_default_effort': reasoningDefaultEffort,
      if (zdrProviders != null) 'zdr_providers': zdrProviders,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrModelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? contextLength,
    Value<List<String>>? inputModalities,
    Value<double>? pricePrompt,
    Value<double>? priceCompletion,
    Value<double?>? priceCacheRead,
    Value<bool>? reasoningSupported,
    Value<bool>? reasoningMandatory,
    Value<List<String>>? reasoningEfforts,
    Value<String?>? reasoningDefaultEffort,
    Value<List<String>>? zdrProviders,
    Value<int>? rowid,
  }) {
    return OrModelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      contextLength: contextLength ?? this.contextLength,
      inputModalities: inputModalities ?? this.inputModalities,
      pricePrompt: pricePrompt ?? this.pricePrompt,
      priceCompletion: priceCompletion ?? this.priceCompletion,
      priceCacheRead: priceCacheRead ?? this.priceCacheRead,
      reasoningSupported: reasoningSupported ?? this.reasoningSupported,
      reasoningMandatory: reasoningMandatory ?? this.reasoningMandatory,
      reasoningEfforts: reasoningEfforts ?? this.reasoningEfforts,
      reasoningDefaultEffort:
          reasoningDefaultEffort ?? this.reasoningDefaultEffort,
      zdrProviders: zdrProviders ?? this.zdrProviders,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contextLength.present) {
      map['context_length'] = Variable<int>(contextLength.value);
    }
    if (inputModalities.present) {
      map['input_modalities'] = Variable<String>(
        $OrModelsTable.$converterinputModalities.toSql(inputModalities.value),
      );
    }
    if (pricePrompt.present) {
      map['price_prompt'] = Variable<double>(pricePrompt.value);
    }
    if (priceCompletion.present) {
      map['price_completion'] = Variable<double>(priceCompletion.value);
    }
    if (priceCacheRead.present) {
      map['price_cache_read'] = Variable<double>(priceCacheRead.value);
    }
    if (reasoningSupported.present) {
      map['reasoning_supported'] = Variable<bool>(reasoningSupported.value);
    }
    if (reasoningMandatory.present) {
      map['reasoning_mandatory'] = Variable<bool>(reasoningMandatory.value);
    }
    if (reasoningEfforts.present) {
      map['reasoning_efforts'] = Variable<String>(
        $OrModelsTable.$converterreasoningEfforts.toSql(reasoningEfforts.value),
      );
    }
    if (reasoningDefaultEffort.present) {
      map['reasoning_default_effort'] = Variable<String>(
        reasoningDefaultEffort.value,
      );
    }
    if (zdrProviders.present) {
      map['zdr_providers'] = Variable<String>(
        $OrModelsTable.$converterzdrProviders.toSql(zdrProviders.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrModelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contextLength: $contextLength, ')
          ..write('inputModalities: $inputModalities, ')
          ..write('pricePrompt: $pricePrompt, ')
          ..write('priceCompletion: $priceCompletion, ')
          ..write('priceCacheRead: $priceCacheRead, ')
          ..write('reasoningSupported: $reasoningSupported, ')
          ..write('reasoningMandatory: $reasoningMandatory, ')
          ..write('reasoningEfforts: $reasoningEfforts, ')
          ..write('reasoningDefaultEffort: $reasoningDefaultEffort, ')
          ..write('zdrProviders: $zdrProviders, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeneralMetaTable extends GeneralMeta
    with TableInfo<$GeneralMetaTable, GeneralMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneralMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'general_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeneralMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  GeneralMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneralMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $GeneralMetaTable createAlias(String alias) {
    return $GeneralMetaTable(attachedDatabase, alias);
  }
}

class GeneralMetaRow extends DataClass implements Insertable<GeneralMetaRow> {
  final String key;
  final String value;
  const GeneralMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  GeneralMetaCompanion toCompanion(bool nullToAbsent) {
    return GeneralMetaCompanion(key: Value(key), value: Value(value));
  }

  factory GeneralMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneralMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  GeneralMetaRow copyWith({String? key, String? value}) =>
      GeneralMetaRow(key: key ?? this.key, value: value ?? this.value);
  GeneralMetaRow copyWithCompanion(GeneralMetaCompanion data) {
    return GeneralMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneralMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneralMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class GeneralMetaCompanion extends UpdateCompanion<GeneralMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const GeneralMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneralMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<GeneralMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneralMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return GeneralMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneralMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GeneralDatabase extends GeneratedDatabase {
  _$GeneralDatabase(QueryExecutor e) : super(e);
  $GeneralDatabaseManager get managers => $GeneralDatabaseManager(this);
  late final $GeneralChatsTable generalChats = $GeneralChatsTable(this);
  late final $GeneralMessagesTable generalMessages = $GeneralMessagesTable(
    this,
  );
  late final $GeneralAttachmentsTable generalAttachments =
      $GeneralAttachmentsTable(this);
  late final $OrModelsTable orModels = $OrModelsTable(this);
  late final $GeneralMetaTable generalMeta = $GeneralMetaTable(this);
  late final Index generalMessagesByChat = Index(
    'general_messages_by_chat',
    'CREATE INDEX general_messages_by_chat ON general_messages (chat_id, seq)',
  );
  late final Index generalAttachmentsByMessage = Index(
    'general_attachments_by_message',
    'CREATE INDEX general_attachments_by_message ON general_attachments (message_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    generalChats,
    generalMessages,
    generalAttachments,
    orModels,
    generalMeta,
    generalMessagesByChat,
    generalAttachmentsByMessage,
  ];
}

typedef $$GeneralChatsTableCreateCompanionBuilder =
    GeneralChatsCompanion Function({
      required String id,
      Value<String?> title,
      Value<bool> titleSet,
      Value<String?> preview,
      required String modelId,
      Value<bool> reasoning,
      Value<String?> reasoningEffort,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> archived,
      Value<int> tokensIn,
      Value<int> tokensOut,
      Value<double> costUsd,
      Value<int?> lastPromptTokens,
      Value<int?> lastContextLength,
      Value<int> rowid,
    });
typedef $$GeneralChatsTableUpdateCompanionBuilder =
    GeneralChatsCompanion Function({
      Value<String> id,
      Value<String?> title,
      Value<bool> titleSet,
      Value<String?> preview,
      Value<String> modelId,
      Value<bool> reasoning,
      Value<String?> reasoningEffort,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> archived,
      Value<int> tokensIn,
      Value<int> tokensOut,
      Value<double> costUsd,
      Value<int?> lastPromptTokens,
      Value<int?> lastContextLength,
      Value<int> rowid,
    });

class $$GeneralChatsTableFilterComposer
    extends Composer<_$GeneralDatabase, $GeneralChatsTable> {
  $$GeneralChatsTableFilterComposer({
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

  ColumnFilters<bool> get titleSet => $composableBuilder(
    column: $table.titleSet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoningEffort => $composableBuilder(
    column: $table.reasoningEffort,
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

  ColumnFilters<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPromptTokens => $composableBuilder(
    column: $table.lastPromptTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastContextLength => $composableBuilder(
    column: $table.lastContextLength,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeneralChatsTableOrderingComposer
    extends Composer<_$GeneralDatabase, $GeneralChatsTable> {
  $$GeneralChatsTableOrderingComposer({
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

  ColumnOrderings<bool> get titleSet => $composableBuilder(
    column: $table.titleSet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoningEffort => $composableBuilder(
    column: $table.reasoningEffort,
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

  ColumnOrderings<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPromptTokens => $composableBuilder(
    column: $table.lastPromptTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastContextLength => $composableBuilder(
    column: $table.lastContextLength,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeneralChatsTableAnnotationComposer
    extends Composer<_$GeneralDatabase, $GeneralChatsTable> {
  $$GeneralChatsTableAnnotationComposer({
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

  GeneratedColumn<bool> get titleSet =>
      $composableBuilder(column: $table.titleSet, builder: (column) => column);

  GeneratedColumn<String> get preview =>
      $composableBuilder(column: $table.preview, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<bool> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<String> get reasoningEffort => $composableBuilder(
    column: $table.reasoningEffort,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get tokensIn =>
      $composableBuilder(column: $table.tokensIn, builder: (column) => column);

  GeneratedColumn<int> get tokensOut =>
      $composableBuilder(column: $table.tokensOut, builder: (column) => column);

  GeneratedColumn<double> get costUsd =>
      $composableBuilder(column: $table.costUsd, builder: (column) => column);

  GeneratedColumn<int> get lastPromptTokens => $composableBuilder(
    column: $table.lastPromptTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastContextLength => $composableBuilder(
    column: $table.lastContextLength,
    builder: (column) => column,
  );
}

class $$GeneralChatsTableTableManager
    extends
        RootTableManager<
          _$GeneralDatabase,
          $GeneralChatsTable,
          GeneralChatRow,
          $$GeneralChatsTableFilterComposer,
          $$GeneralChatsTableOrderingComposer,
          $$GeneralChatsTableAnnotationComposer,
          $$GeneralChatsTableCreateCompanionBuilder,
          $$GeneralChatsTableUpdateCompanionBuilder,
          (
            GeneralChatRow,
            BaseReferences<
              _$GeneralDatabase,
              $GeneralChatsTable,
              GeneralChatRow
            >,
          ),
          GeneralChatRow,
          PrefetchHooks Function()
        > {
  $$GeneralChatsTableTableManager(
    _$GeneralDatabase db,
    $GeneralChatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneralChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneralChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneralChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<bool> titleSet = const Value.absent(),
                Value<String?> preview = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<bool> reasoning = const Value.absent(),
                Value<String?> reasoningEffort = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> tokensIn = const Value.absent(),
                Value<int> tokensOut = const Value.absent(),
                Value<double> costUsd = const Value.absent(),
                Value<int?> lastPromptTokens = const Value.absent(),
                Value<int?> lastContextLength = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeneralChatsCompanion(
                id: id,
                title: title,
                titleSet: titleSet,
                preview: preview,
                modelId: modelId,
                reasoning: reasoning,
                reasoningEffort: reasoningEffort,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                costUsd: costUsd,
                lastPromptTokens: lastPromptTokens,
                lastContextLength: lastContextLength,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> title = const Value.absent(),
                Value<bool> titleSet = const Value.absent(),
                Value<String?> preview = const Value.absent(),
                required String modelId,
                Value<bool> reasoning = const Value.absent(),
                Value<String?> reasoningEffort = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> archived = const Value.absent(),
                Value<int> tokensIn = const Value.absent(),
                Value<int> tokensOut = const Value.absent(),
                Value<double> costUsd = const Value.absent(),
                Value<int?> lastPromptTokens = const Value.absent(),
                Value<int?> lastContextLength = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeneralChatsCompanion.insert(
                id: id,
                title: title,
                titleSet: titleSet,
                preview: preview,
                modelId: modelId,
                reasoning: reasoning,
                reasoningEffort: reasoningEffort,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                costUsd: costUsd,
                lastPromptTokens: lastPromptTokens,
                lastContextLength: lastContextLength,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeneralChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$GeneralDatabase,
      $GeneralChatsTable,
      GeneralChatRow,
      $$GeneralChatsTableFilterComposer,
      $$GeneralChatsTableOrderingComposer,
      $$GeneralChatsTableAnnotationComposer,
      $$GeneralChatsTableCreateCompanionBuilder,
      $$GeneralChatsTableUpdateCompanionBuilder,
      (
        GeneralChatRow,
        BaseReferences<_$GeneralDatabase, $GeneralChatsTable, GeneralChatRow>,
      ),
      GeneralChatRow,
      PrefetchHooks Function()
    >;
typedef $$GeneralMessagesTableCreateCompanionBuilder =
    GeneralMessagesCompanion Function({
      required String id,
      required String chatId,
      required int seq,
      required String role,
      Value<String> content,
      Value<String?> reasoning,
      Value<String?> modelId,
      Value<String?> provider,
      required String status,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int?> retryAfterS,
      Value<String?> finishReason,
      Value<int?> tokensIn,
      Value<int?> tokensOut,
      Value<int?> tokensReasoning,
      Value<double?> costUsd,
      Value<String?> generationId,
      Value<String?> providerWarning,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$GeneralMessagesTableUpdateCompanionBuilder =
    GeneralMessagesCompanion Function({
      Value<String> id,
      Value<String> chatId,
      Value<int> seq,
      Value<String> role,
      Value<String> content,
      Value<String?> reasoning,
      Value<String?> modelId,
      Value<String?> provider,
      Value<String> status,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int?> retryAfterS,
      Value<String?> finishReason,
      Value<int?> tokensIn,
      Value<int?> tokensOut,
      Value<int?> tokensReasoning,
      Value<double?> costUsd,
      Value<String?> generationId,
      Value<String?> providerWarning,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$GeneralMessagesTableFilterComposer
    extends Composer<_$GeneralDatabase, $GeneralMessagesTable> {
  $$GeneralMessagesTableFilterComposer({
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

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
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

  ColumnFilters<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryAfterS => $composableBuilder(
    column: $table.retryAfterS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishReason => $composableBuilder(
    column: $table.finishReason,
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

  ColumnFilters<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get generationId => $composableBuilder(
    column: $table.generationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerWarning => $composableBuilder(
    column: $table.providerWarning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeneralMessagesTableOrderingComposer
    extends Composer<_$GeneralDatabase, $GeneralMessagesTable> {
  $$GeneralMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
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

  ColumnOrderings<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryAfterS => $composableBuilder(
    column: $table.retryAfterS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishReason => $composableBuilder(
    column: $table.finishReason,
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

  ColumnOrderings<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generationId => $composableBuilder(
    column: $table.generationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerWarning => $composableBuilder(
    column: $table.providerWarning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeneralMessagesTableAnnotationComposer
    extends Composer<_$GeneralDatabase, $GeneralMessagesTable> {
  $$GeneralMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryAfterS => $composableBuilder(
    column: $table.retryAfterS,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finishReason => $composableBuilder(
    column: $table.finishReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensIn =>
      $composableBuilder(column: $table.tokensIn, builder: (column) => column);

  GeneratedColumn<int> get tokensOut =>
      $composableBuilder(column: $table.tokensOut, builder: (column) => column);

  GeneratedColumn<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costUsd =>
      $composableBuilder(column: $table.costUsd, builder: (column) => column);

  GeneratedColumn<String> get generationId => $composableBuilder(
    column: $table.generationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerWarning => $composableBuilder(
    column: $table.providerWarning,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GeneralMessagesTableTableManager
    extends
        RootTableManager<
          _$GeneralDatabase,
          $GeneralMessagesTable,
          GeneralMessageRow,
          $$GeneralMessagesTableFilterComposer,
          $$GeneralMessagesTableOrderingComposer,
          $$GeneralMessagesTableAnnotationComposer,
          $$GeneralMessagesTableCreateCompanionBuilder,
          $$GeneralMessagesTableUpdateCompanionBuilder,
          (
            GeneralMessageRow,
            BaseReferences<
              _$GeneralDatabase,
              $GeneralMessagesTable,
              GeneralMessageRow
            >,
          ),
          GeneralMessageRow,
          PrefetchHooks Function()
        > {
  $$GeneralMessagesTableTableManager(
    _$GeneralDatabase db,
    $GeneralMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneralMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneralMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneralMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int?> retryAfterS = const Value.absent(),
                Value<String?> finishReason = const Value.absent(),
                Value<int?> tokensIn = const Value.absent(),
                Value<int?> tokensOut = const Value.absent(),
                Value<int?> tokensReasoning = const Value.absent(),
                Value<double?> costUsd = const Value.absent(),
                Value<String?> generationId = const Value.absent(),
                Value<String?> providerWarning = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeneralMessagesCompanion(
                id: id,
                chatId: chatId,
                seq: seq,
                role: role,
                content: content,
                reasoning: reasoning,
                modelId: modelId,
                provider: provider,
                status: status,
                errorCode: errorCode,
                errorMessage: errorMessage,
                retryAfterS: retryAfterS,
                finishReason: finishReason,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                tokensReasoning: tokensReasoning,
                costUsd: costUsd,
                generationId: generationId,
                providerWarning: providerWarning,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chatId,
                required int seq,
                required String role,
                Value<String> content = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                required String status,
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int?> retryAfterS = const Value.absent(),
                Value<String?> finishReason = const Value.absent(),
                Value<int?> tokensIn = const Value.absent(),
                Value<int?> tokensOut = const Value.absent(),
                Value<int?> tokensReasoning = const Value.absent(),
                Value<double?> costUsd = const Value.absent(),
                Value<String?> generationId = const Value.absent(),
                Value<String?> providerWarning = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GeneralMessagesCompanion.insert(
                id: id,
                chatId: chatId,
                seq: seq,
                role: role,
                content: content,
                reasoning: reasoning,
                modelId: modelId,
                provider: provider,
                status: status,
                errorCode: errorCode,
                errorMessage: errorMessage,
                retryAfterS: retryAfterS,
                finishReason: finishReason,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                tokensReasoning: tokensReasoning,
                costUsd: costUsd,
                generationId: generationId,
                providerWarning: providerWarning,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeneralMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$GeneralDatabase,
      $GeneralMessagesTable,
      GeneralMessageRow,
      $$GeneralMessagesTableFilterComposer,
      $$GeneralMessagesTableOrderingComposer,
      $$GeneralMessagesTableAnnotationComposer,
      $$GeneralMessagesTableCreateCompanionBuilder,
      $$GeneralMessagesTableUpdateCompanionBuilder,
      (
        GeneralMessageRow,
        BaseReferences<
          _$GeneralDatabase,
          $GeneralMessagesTable,
          GeneralMessageRow
        >,
      ),
      GeneralMessageRow,
      PrefetchHooks Function()
    >;
typedef $$GeneralAttachmentsTableCreateCompanionBuilder =
    GeneralAttachmentsCompanion Function({
      required String id,
      required String messageId,
      required int ord,
      required String mime,
      required Uint8List bytes,
      required int size,
      Value<int> rowid,
    });
typedef $$GeneralAttachmentsTableUpdateCompanionBuilder =
    GeneralAttachmentsCompanion Function({
      Value<String> id,
      Value<String> messageId,
      Value<int> ord,
      Value<String> mime,
      Value<Uint8List> bytes,
      Value<int> size,
      Value<int> rowid,
    });

class $$GeneralAttachmentsTableFilterComposer
    extends Composer<_$GeneralDatabase, $GeneralAttachmentsTable> {
  $$GeneralAttachmentsTableFilterComposer({
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

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeneralAttachmentsTableOrderingComposer
    extends Composer<_$GeneralDatabase, $GeneralAttachmentsTable> {
  $$GeneralAttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeneralAttachmentsTableAnnotationComposer
    extends Composer<_$GeneralDatabase, $GeneralAttachmentsTable> {
  $$GeneralAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get ord =>
      $composableBuilder(column: $table.ord, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);
}

class $$GeneralAttachmentsTableTableManager
    extends
        RootTableManager<
          _$GeneralDatabase,
          $GeneralAttachmentsTable,
          GeneralAttachmentRow,
          $$GeneralAttachmentsTableFilterComposer,
          $$GeneralAttachmentsTableOrderingComposer,
          $$GeneralAttachmentsTableAnnotationComposer,
          $$GeneralAttachmentsTableCreateCompanionBuilder,
          $$GeneralAttachmentsTableUpdateCompanionBuilder,
          (
            GeneralAttachmentRow,
            BaseReferences<
              _$GeneralDatabase,
              $GeneralAttachmentsTable,
              GeneralAttachmentRow
            >,
          ),
          GeneralAttachmentRow,
          PrefetchHooks Function()
        > {
  $$GeneralAttachmentsTableTableManager(
    _$GeneralDatabase db,
    $GeneralAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneralAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneralAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneralAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> ord = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeneralAttachmentsCompanion(
                id: id,
                messageId: messageId,
                ord: ord,
                mime: mime,
                bytes: bytes,
                size: size,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String messageId,
                required int ord,
                required String mime,
                required Uint8List bytes,
                required int size,
                Value<int> rowid = const Value.absent(),
              }) => GeneralAttachmentsCompanion.insert(
                id: id,
                messageId: messageId,
                ord: ord,
                mime: mime,
                bytes: bytes,
                size: size,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeneralAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$GeneralDatabase,
      $GeneralAttachmentsTable,
      GeneralAttachmentRow,
      $$GeneralAttachmentsTableFilterComposer,
      $$GeneralAttachmentsTableOrderingComposer,
      $$GeneralAttachmentsTableAnnotationComposer,
      $$GeneralAttachmentsTableCreateCompanionBuilder,
      $$GeneralAttachmentsTableUpdateCompanionBuilder,
      (
        GeneralAttachmentRow,
        BaseReferences<
          _$GeneralDatabase,
          $GeneralAttachmentsTable,
          GeneralAttachmentRow
        >,
      ),
      GeneralAttachmentRow,
      PrefetchHooks Function()
    >;
typedef $$OrModelsTableCreateCompanionBuilder =
    OrModelsCompanion Function({
      required String id,
      required String name,
      Value<int?> contextLength,
      required List<String> inputModalities,
      required double pricePrompt,
      required double priceCompletion,
      Value<double?> priceCacheRead,
      Value<bool> reasoningSupported,
      Value<bool> reasoningMandatory,
      Value<List<String>> reasoningEfforts,
      Value<String?> reasoningDefaultEffort,
      Value<List<String>> zdrProviders,
      Value<int> rowid,
    });
typedef $$OrModelsTableUpdateCompanionBuilder =
    OrModelsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> contextLength,
      Value<List<String>> inputModalities,
      Value<double> pricePrompt,
      Value<double> priceCompletion,
      Value<double?> priceCacheRead,
      Value<bool> reasoningSupported,
      Value<bool> reasoningMandatory,
      Value<List<String>> reasoningEfforts,
      Value<String?> reasoningDefaultEffort,
      Value<List<String>> zdrProviders,
      Value<int> rowid,
    });

class $$OrModelsTableFilterComposer
    extends Composer<_$GeneralDatabase, $OrModelsTable> {
  $$OrModelsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextLength => $composableBuilder(
    column: $table.contextLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get inputModalities => $composableBuilder(
    column: $table.inputModalities,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get pricePrompt => $composableBuilder(
    column: $table.pricePrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceCompletion => $composableBuilder(
    column: $table.priceCompletion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceCacheRead => $composableBuilder(
    column: $table.priceCacheRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reasoningSupported => $composableBuilder(
    column: $table.reasoningSupported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reasoningMandatory => $composableBuilder(
    column: $table.reasoningMandatory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get reasoningEfforts => $composableBuilder(
    column: $table.reasoningEfforts,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reasoningDefaultEffort => $composableBuilder(
    column: $table.reasoningDefaultEffort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get zdrProviders => $composableBuilder(
    column: $table.zdrProviders,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$OrModelsTableOrderingComposer
    extends Composer<_$GeneralDatabase, $OrModelsTable> {
  $$OrModelsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextLength => $composableBuilder(
    column: $table.contextLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputModalities => $composableBuilder(
    column: $table.inputModalities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePrompt => $composableBuilder(
    column: $table.pricePrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceCompletion => $composableBuilder(
    column: $table.priceCompletion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceCacheRead => $composableBuilder(
    column: $table.priceCacheRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reasoningSupported => $composableBuilder(
    column: $table.reasoningSupported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reasoningMandatory => $composableBuilder(
    column: $table.reasoningMandatory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoningEfforts => $composableBuilder(
    column: $table.reasoningEfforts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoningDefaultEffort => $composableBuilder(
    column: $table.reasoningDefaultEffort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zdrProviders => $composableBuilder(
    column: $table.zdrProviders,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrModelsTableAnnotationComposer
    extends Composer<_$GeneralDatabase, $OrModelsTable> {
  $$OrModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get contextLength => $composableBuilder(
    column: $table.contextLength,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get inputModalities =>
      $composableBuilder(
        column: $table.inputModalities,
        builder: (column) => column,
      );

  GeneratedColumn<double> get pricePrompt => $composableBuilder(
    column: $table.pricePrompt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get priceCompletion => $composableBuilder(
    column: $table.priceCompletion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get priceCacheRead => $composableBuilder(
    column: $table.priceCacheRead,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reasoningSupported => $composableBuilder(
    column: $table.reasoningSupported,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reasoningMandatory => $composableBuilder(
    column: $table.reasoningMandatory,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get reasoningEfforts =>
      $composableBuilder(
        column: $table.reasoningEfforts,
        builder: (column) => column,
      );

  GeneratedColumn<String> get reasoningDefaultEffort => $composableBuilder(
    column: $table.reasoningDefaultEffort,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get zdrProviders =>
      $composableBuilder(
        column: $table.zdrProviders,
        builder: (column) => column,
      );
}

class $$OrModelsTableTableManager
    extends
        RootTableManager<
          _$GeneralDatabase,
          $OrModelsTable,
          OrModelRow,
          $$OrModelsTableFilterComposer,
          $$OrModelsTableOrderingComposer,
          $$OrModelsTableAnnotationComposer,
          $$OrModelsTableCreateCompanionBuilder,
          $$OrModelsTableUpdateCompanionBuilder,
          (
            OrModelRow,
            BaseReferences<_$GeneralDatabase, $OrModelsTable, OrModelRow>,
          ),
          OrModelRow,
          PrefetchHooks Function()
        > {
  $$OrModelsTableTableManager(_$GeneralDatabase db, $OrModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> contextLength = const Value.absent(),
                Value<List<String>> inputModalities = const Value.absent(),
                Value<double> pricePrompt = const Value.absent(),
                Value<double> priceCompletion = const Value.absent(),
                Value<double?> priceCacheRead = const Value.absent(),
                Value<bool> reasoningSupported = const Value.absent(),
                Value<bool> reasoningMandatory = const Value.absent(),
                Value<List<String>> reasoningEfforts = const Value.absent(),
                Value<String?> reasoningDefaultEffort = const Value.absent(),
                Value<List<String>> zdrProviders = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrModelsCompanion(
                id: id,
                name: name,
                contextLength: contextLength,
                inputModalities: inputModalities,
                pricePrompt: pricePrompt,
                priceCompletion: priceCompletion,
                priceCacheRead: priceCacheRead,
                reasoningSupported: reasoningSupported,
                reasoningMandatory: reasoningMandatory,
                reasoningEfforts: reasoningEfforts,
                reasoningDefaultEffort: reasoningDefaultEffort,
                zdrProviders: zdrProviders,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int?> contextLength = const Value.absent(),
                required List<String> inputModalities,
                required double pricePrompt,
                required double priceCompletion,
                Value<double?> priceCacheRead = const Value.absent(),
                Value<bool> reasoningSupported = const Value.absent(),
                Value<bool> reasoningMandatory = const Value.absent(),
                Value<List<String>> reasoningEfforts = const Value.absent(),
                Value<String?> reasoningDefaultEffort = const Value.absent(),
                Value<List<String>> zdrProviders = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrModelsCompanion.insert(
                id: id,
                name: name,
                contextLength: contextLength,
                inputModalities: inputModalities,
                pricePrompt: pricePrompt,
                priceCompletion: priceCompletion,
                priceCacheRead: priceCacheRead,
                reasoningSupported: reasoningSupported,
                reasoningMandatory: reasoningMandatory,
                reasoningEfforts: reasoningEfforts,
                reasoningDefaultEffort: reasoningDefaultEffort,
                zdrProviders: zdrProviders,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$GeneralDatabase,
      $OrModelsTable,
      OrModelRow,
      $$OrModelsTableFilterComposer,
      $$OrModelsTableOrderingComposer,
      $$OrModelsTableAnnotationComposer,
      $$OrModelsTableCreateCompanionBuilder,
      $$OrModelsTableUpdateCompanionBuilder,
      (
        OrModelRow,
        BaseReferences<_$GeneralDatabase, $OrModelsTable, OrModelRow>,
      ),
      OrModelRow,
      PrefetchHooks Function()
    >;
typedef $$GeneralMetaTableCreateCompanionBuilder =
    GeneralMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$GeneralMetaTableUpdateCompanionBuilder =
    GeneralMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$GeneralMetaTableFilterComposer
    extends Composer<_$GeneralDatabase, $GeneralMetaTable> {
  $$GeneralMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeneralMetaTableOrderingComposer
    extends Composer<_$GeneralDatabase, $GeneralMetaTable> {
  $$GeneralMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeneralMetaTableAnnotationComposer
    extends Composer<_$GeneralDatabase, $GeneralMetaTable> {
  $$GeneralMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$GeneralMetaTableTableManager
    extends
        RootTableManager<
          _$GeneralDatabase,
          $GeneralMetaTable,
          GeneralMetaRow,
          $$GeneralMetaTableFilterComposer,
          $$GeneralMetaTableOrderingComposer,
          $$GeneralMetaTableAnnotationComposer,
          $$GeneralMetaTableCreateCompanionBuilder,
          $$GeneralMetaTableUpdateCompanionBuilder,
          (
            GeneralMetaRow,
            BaseReferences<
              _$GeneralDatabase,
              $GeneralMetaTable,
              GeneralMetaRow
            >,
          ),
          GeneralMetaRow,
          PrefetchHooks Function()
        > {
  $$GeneralMetaTableTableManager(_$GeneralDatabase db, $GeneralMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneralMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneralMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneralMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeneralMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => GeneralMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeneralMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$GeneralDatabase,
      $GeneralMetaTable,
      GeneralMetaRow,
      $$GeneralMetaTableFilterComposer,
      $$GeneralMetaTableOrderingComposer,
      $$GeneralMetaTableAnnotationComposer,
      $$GeneralMetaTableCreateCompanionBuilder,
      $$GeneralMetaTableUpdateCompanionBuilder,
      (
        GeneralMetaRow,
        BaseReferences<_$GeneralDatabase, $GeneralMetaTable, GeneralMetaRow>,
      ),
      GeneralMetaRow,
      PrefetchHooks Function()
    >;

class $GeneralDatabaseManager {
  final _$GeneralDatabase _db;
  $GeneralDatabaseManager(this._db);
  $$GeneralChatsTableTableManager get generalChats =>
      $$GeneralChatsTableTableManager(_db, _db.generalChats);
  $$GeneralMessagesTableTableManager get generalMessages =>
      $$GeneralMessagesTableTableManager(_db, _db.generalMessages);
  $$GeneralAttachmentsTableTableManager get generalAttachments =>
      $$GeneralAttachmentsTableTableManager(_db, _db.generalAttachments);
  $$OrModelsTableTableManager get orModels =>
      $$OrModelsTableTableManager(_db, _db.orModels);
  $$GeneralMetaTableTableManager get generalMeta =>
      $$GeneralMetaTableTableManager(_db, _db.generalMeta);
}
