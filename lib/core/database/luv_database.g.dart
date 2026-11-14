// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'luv_database.dart';

// ignore_for_file: type=lint
class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final int id;
  final String nodeId;
  final String sender;
  final String content;
  final String? originalContent;
  final bool isRetracted;
  final bool isVoiceNote;
  final String? ghostOverlayText;
  final DateTime timestamp;
  final double corruptionAtSend;

  const ChatMessage({
    required this.id,
    required this.nodeId,
    required this.sender,
    required this.content,
    this.originalContent,
    required this.isRetracted,
    required this.isVoiceNote,
    this.ghostOverlayText,
    required this.timestamp,
    required this.corruptionAtSend,
  });

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    map['id'] = Variable<int>(id);
    map['node_id'] = Variable<String>(nodeId);
    map['sender'] = Variable<String>(sender);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || originalContent != null) {
      map['original_content'] = Variable<String>(originalContent);
    }
    map['is_retracted'] = Variable<bool>(isRetracted);
    map['is_voice_note'] = Variable<bool>(isVoiceNote);
    if (!nullToAbsent || ghostOverlayText != null) {
      map['ghost_overlay_text'] = Variable<String>(ghostOverlayText);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['corruption_at_send'] = Variable<double>(corruptionAtSend);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      nodeId: Value(nodeId),
      sender: Value(sender),
      content: Value(content),
      originalContent: originalContent == null && nullToAbsent
          ? const Value.absent()
          : Value(originalContent),
      isRetracted: Value(isRetracted),
      isVoiceNote: Value(isVoiceNote),
      ghostOverlayText: ghostOverlayText == null && nullToAbsent
          ? const Value.absent()
          : Value(ghostOverlayText),
      timestamp: Value(timestamp),
      corruptionAtSend: Value(corruptionAtSend),
    );
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<int>(json['id']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      sender: serializer.fromJson<String>(json['sender']),
      content: serializer.fromJson<String>(json['content']),
      originalContent: serializer.fromJson<String?>(json['originalContent']),
      isRetracted: serializer.fromJson<bool>(json['isRetracted']),
      isVoiceNote: serializer.fromJson<bool>(json['isVoiceNote']),
      ghostOverlayText: serializer.fromJson<String?>(json['ghostOverlayText']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      corruptionAtSend: serializer.fromJson<double>(json['corruptionAtSend']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nodeId': serializer.toJson<String>(nodeId),
      'sender': serializer.toJson<String>(sender),
      'content': serializer.toJson<String>(content),
      'originalContent': serializer.toJson<String?>(originalContent),
      'isRetracted': serializer.toJson<bool>(isRetracted),
      'isVoiceNote': serializer.toJson<bool>(isVoiceNote),
      'ghostOverlayText': serializer.toJson<String?>(ghostOverlayText),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'corruptionAtSend': serializer.toJson<double>(corruptionAtSend),
    };
  }

  ChatMessage copyWith({
    int? id,
    String? nodeId,
    String? sender,
    String? content,
    Value<String?> originalContent = const Value.absent(),
    bool? isRetracted,
    bool? isVoiceNote,
    Value<String?> ghostOverlayText = const Value.absent(),
    DateTime? timestamp,
    double? corruptionAtSend,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        nodeId: nodeId ?? this.nodeId,
        sender: sender ?? this.sender,
        content: content ?? this.content,
        originalContent: originalContent.present
            ? originalContent.value
            : this.originalContent,
        isRetracted: isRetracted ?? this.isRetracted,
        isVoiceNote: isVoiceNote ?? this.isVoiceNote,
        ghostOverlayText: ghostOverlayText.present
            ? ghostOverlayText.value
            : this.ghostOverlayText,
        timestamp: timestamp ?? this.timestamp,
        corruptionAtSend: corruptionAtSend ?? this.corruptionAtSend,
      );

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('sender: $sender, ')
          ..write('content: $content, ')
          ..write('originalContent: $originalContent, ')
          ..write('isRetracted: $isRetracted, ')
          ..write('isVoiceNote: $isVoiceNote, ')
          ..write('ghostOverlayText: $ghostOverlayText, ')
          ..write('timestamp: $timestamp, ')
          ..write('corruptionAtSend: $corruptionAtSend')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
        id,
        nodeId,
        sender,
        content,
        originalContent,
        isRetracted,
        isVoiceNote,
        ghostOverlayText,
        timestamp,
        corruptionAtSend,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.sender == this.sender &&
          other.content == this.content &&
          other.originalContent == this.originalContent &&
          other.isRetracted == this.isRetracted &&
          other.isVoiceNote == this.isVoiceNote &&
          other.ghostOverlayText == this.ghostOverlayText &&
          other.timestamp == this.timestamp &&
          other.corruptionAtSend == this.corruptionAtSend);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<int> id;
  final Value<String> nodeId;
  final Value<String> sender;
  final Value<String> content;
  final Value<String?> originalContent;
  final Value<bool> isRetracted;
  final Value<bool> isVoiceNote;
  final Value<String?> ghostOverlayText;
  final Value<DateTime> timestamp;
  final Value<double> corruptionAtSend;

  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.sender = const Value.absent(),
    this.content = const Value.absent(),
    this.originalContent = const Value.absent(),
    this.isRetracted = const Value.absent(),
    this.isVoiceNote = const Value.absent(),
    this.ghostOverlayText = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.corruptionAtSend = const Value.absent(),
  });

  ChatMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String nodeId,
    required String sender,
    required String content,
    this.originalContent = const Value.absent(),
    this.isRetracted = const Value.absent(),
    this.isVoiceNote = const Value.absent(),
    this.ghostOverlayText = const Value.absent(),
    required DateTime timestamp,
    this.corruptionAtSend = const Value.absent(),
  })  : nodeId = Value(nodeId),
        sender = Value(sender),
        content = Value(content),
        timestamp = Value(timestamp);

  static Insertable<ChatMessage> custom({
    Expression<int>? id,
    Expression<String>? nodeId,
    Expression<String>? sender,
    Expression<String>? content,
    Expression<String>? originalContent,
    Expression<bool>? isRetracted,
    Expression<bool>? isVoiceNote,
    Expression<String>? ghostOverlayText,
    Expression<DateTime>? timestamp,
    Expression<double>? corruptionAtSend,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (sender != null) 'sender': sender,
      if (content != null) 'content': content,
      if (originalContent != null) 'original_content': originalContent,
      if (isRetracted != null) 'is_retracted': isRetracted,
      if (isVoiceNote != null) 'is_voice_note': isVoiceNote,
      if (ghostOverlayText != null) 'ghost_overlay_text': ghostOverlayText,
      if (timestamp != null) 'timestamp': timestamp,
      if (corruptionAtSend != null) 'corruption_at_send': corruptionAtSend,
    });
  }

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (nodeId.present) map['node_id'] = Variable<String>(nodeId.value);
    if (sender.present) map['sender'] = Variable<String>(sender.value);
    if (content.present) map['content'] = Variable<String>(content.value);
    if (originalContent.present) {
      map['original_content'] = Variable<String>(originalContent.value);
    }
    if (isRetracted.present) {
      map['is_retracted'] = Variable<bool>(isRetracted.value);
    }
    if (isVoiceNote.present) {
      map['is_voice_note'] = Variable<bool>(isVoiceNote.value);
    }
    if (ghostOverlayText.present) {
      map['ghost_overlay_text'] = Variable<String>(ghostOverlayText.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (corruptionAtSend.present) {
      map['corruption_at_send'] = Variable<double>(corruptionAtSend.value);
    }
    return map;
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> originalContent = GeneratedColumn<String>(
    'original_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> isRetracted = GeneratedColumn<bool>(
    'is_retracted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('CHECK ("is_retracted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  late final GeneratedColumn<bool> isVoiceNote = GeneratedColumn<bool>(
    'is_voice_note',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('CHECK ("is_voice_note" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  late final GeneratedColumn<String> ghostOverlayText = GeneratedColumn<String>(
    'ghost_overlay_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<double> corruptionAtSend = GeneratedColumn<double>(
    'corruption_at_send',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );

  @override
  List<GeneratedColumn> get $columns => [
        id,
        nodeId,
        sender,
        content,
        originalContent,
        isRetracted,
        isVoiceNote,
        ghostOverlayText,
        timestamp,
        corruptionAtSend,
      ];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_id'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      originalContent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_content']),
      isRetracted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_retracted'])!,
      isVoiceNote: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_voice_note'])!,
      ghostOverlayText: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ghost_overlay_text']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      corruptionAtSend: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}corruption_at_send'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class DiaryEntry extends DataClass implements Insertable<DiaryEntry> {
  final int id;
  final String title;
  final String body;
  final String triggerType;
  final DateTime createdAt;
  final double corruptionSnap;
  final String? hiddenClue;

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerType,
    required this.createdAt,
    required this.corruptionSnap,
    this.hiddenClue,
  });

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['trigger_type'] = Variable<String>(triggerType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['corruption_snap'] = Variable<double>(corruptionSnap);
    if (!nullToAbsent || hiddenClue != null) {
      map['hidden_clue'] = Variable<String>(hiddenClue);
    }
    return map;
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'triggerType': serializer.toJson<String>(triggerType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'corruptionSnap': serializer.toJson<double>(corruptionSnap),
      'hiddenClue': serializer.toJson<String?>(hiddenClue),
    };
  }
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntry> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String> triggerType;
  final Value<DateTime> createdAt;
  final Value<double> corruptionSnap;
  final Value<String?> hiddenClue;

  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.triggerType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.corruptionSnap = const Value.absent(),
    this.hiddenClue = const Value.absent(),
  });

  DiaryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String body,
    required String triggerType,
    required DateTime createdAt,
    this.corruptionSnap = const Value.absent(),
    this.hiddenClue = const Value.absent(),
  })  : title = Value(title),
        body = Value(body),
        triggerType = Value(triggerType),
        createdAt = Value(createdAt);

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (title.present) map['title'] = Variable<String>(title.value);
    if (body.present) map['body'] = Variable<String>(body.value);
    if (triggerType.present) {
      map['trigger_type'] = Variable<String>(triggerType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (corruptionSnap.present) {
      map['corruption_snap'] = Variable<double>(corruptionSnap.value);
    }
    if (hiddenClue.present) {
      map['hidden_clue'] = Variable<String>(hiddenClue.value);
    }
    return map;
  }
}

class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> triggerType = GeneratedColumn<String>(
    'trigger_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<double> corruptionSnap = GeneratedColumn<double>(
    'corruption_snap',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  late final GeneratedColumn<String> hiddenClue = GeneratedColumn<String>(
    'hidden_clue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );

  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        body,
        triggerType,
        createdAt,
        corruptionSnap,
        hiddenClue,
      ];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  DiaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      triggerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trigger_type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      corruptionSnap: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}corruption_snap'])!,
      hiddenClue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hidden_clue']),
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }
}

class SystemLog extends DataClass implements Insertable<SystemLog> {
  final int id;
  final String eventCode;
  final String details;
  final DateTime loggedAt;
  final int severity;

  const SystemLog({
    required this.id,
    required this.eventCode,
    required this.details,
    required this.loggedAt,
    required this.severity,
  });

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    return {
      'id': Variable<int>(id),
      'event_code': Variable<String>(eventCode),
      'details': Variable<String>(details),
      'logged_at': Variable<DateTime>(loggedAt),
      'severity': Variable<int>(severity),
    };
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventCode': serializer.toJson<String>(eventCode),
      'details': serializer.toJson<String>(details),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'severity': serializer.toJson<int>(severity),
    };
  }
}

class SystemLogsCompanion extends UpdateCompanion<SystemLog> {
  final Value<int> id;
  final Value<String> eventCode;
  final Value<String> details;
  final Value<DateTime> loggedAt;
  final Value<int> severity;

  const SystemLogsCompanion({
    this.id = const Value.absent(),
    this.eventCode = const Value.absent(),
    this.details = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.severity = const Value.absent(),
  });

  SystemLogsCompanion.insert({
    this.id = const Value.absent(),
    required String eventCode,
    required String details,
    required DateTime loggedAt,
    this.severity = const Value.absent(),
  })  : eventCode = Value(eventCode),
        details = Value(details),
        loggedAt = Value(loggedAt);

  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final map = <String, Expression<Object>>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (eventCode.present) map['event_code'] = Variable<String>(eventCode.value);
    if (details.present) map['details'] = Variable<String>(details.value);
    if (loggedAt.present) map['logged_at'] = Variable<DateTime>(loggedAt.value);
    if (severity.present) map['severity'] = Variable<int>(severity.value);
    return map;
  }
}

class $SystemLogsTable extends SystemLogs
    with TableInfo<$SystemLogsTable, SystemLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SystemLogsTable(this.attachedDatabase, [this._alias]);

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  late final GeneratedColumn<String> eventCode = GeneratedColumn<String>(
    'event_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );

  @override
  List<GeneratedColumn> get $columns =>
      [id, eventCode, details, loggedAt, severity];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'system_logs';

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  SystemLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SystemLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_code'])!,
      details: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details'])!,
      loggedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}logged_at'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}severity'])!,
    );
  }

  @override
  $SystemLogsTable createAlias(String alias) {
    return $SystemLogsTable(attachedDatabase, alias);
  }
}

abstract class _$LuvDatabase extends GeneratedDatabase {
  _$LuvDatabase(QueryExecutor e) : super(e);

  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final $SystemLogsTable systemLogs = $SystemLogsTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [chatMessages, diaryEntries, systemLogs];
}
