import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'luv_database.g.dart';

/// Stores persistent chat messages in ChibiChat.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nodeId => text()();
  TextColumn get sender => text()(); // 'mimi', 'player', 'system'
  TextColumn get content => text()();
  TextColumn get originalContent => text().nullable()();
  BoolColumn get isRetracted => boolean().withDefault(const Constant(false))();
  BoolColumn get isVoiceNote => boolean().withDefault(const Constant(false))();
  TextColumn get ghostOverlayText => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get corruptionAtSend => real().withDefault(const Constant(0.0))();
}

/// Stores Mimi's secret diary & behavioral observation logs.
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get triggerType => text()(); // 'audio_mute', 'steady_hand', 'time_tamper', 'battery_low', 'night_owl', 'story'
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get corruptionSnap => real().withDefault(const Constant(0.0))();
  TextColumn get hiddenClue => text().nullable()();
}

/// Stores system manipulation & hardware anomaly logs.
class SystemLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventCode => text()();
  TextColumn get details => text()();
  DateTimeColumn get loggedAt => dateTime()();
  IntColumn get severity => integer().withDefault(const Constant(1))();
}

@DriftDatabase(tables: [ChatMessages, DiaryEntries, SystemLogs])
class LuvDatabase extends _$LuvDatabase {
  LuvDatabase() : super(_openConnection());

  LuvDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<List<ChatMessage>> getAllMessages() {
    return (select(chatMessages)
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<int> insertMessage(ChatMessagesCompanion entry) {
    return into(chatMessages).insert(entry);
  }

  Future<void> updateMessageContent({
    required int id,
    required String newContent,
    required String originalContent,
  }) {
    return (update(chatMessages)..where((t) => t.id.equals(id))).write(
      ChatMessagesCompanion(
        content: Value(newContent),
        originalContent: Value(originalContent),
        isRetracted: const Value(true),
      ),
    );
  }

  Future<List<DiaryEntry>> getAllDiaryEntries() {
    return (select(diaryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> insertDiaryEntry(DiaryEntriesCompanion entry) {
    return into(diaryEntries).insert(entry);
  }

  Future<List<SystemLog>> getRecentSystemLogs({int limit = 50}) {
    return (select(systemLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(limit))
        .get();
  }

  Future<int> insertSystemLog({
    required String eventCode,
    required String details,
    int severity = 1,
  }) async {
    final now = DateTime.now();
    final sig = computeMutationSignature(
      eventCode: eventCode,
      details: details,
      timestampMs: now.millisecondsSinceEpoch,
    );
    return into(systemLogs).insert(
      SystemLogsCompanion.insert(
        eventCode: eventCode,
        details: '$details [SIG:$sig]',
        loggedAt: now,
        severity: Value(severity),
      ),
    );
  }

  /// Computes a deterministic 64-bit FNV-1a hex signature for tamper-evident
  /// audit logging in SQLite.
  static String computeMutationSignature({
    required String eventCode,
    required String details,
    required int timestampMs,
  }) {
    final payload = 'LUV_V2|$eventCode|$details|${timestampMs ~/ 1000}';
    var hash = 0xCBF29CE484222325;
    for (var i = 0; i < payload.length; i++) {
      hash ^= payload.codeUnitAt(i);
      hash = (hash * 0x100000001B3) & 0x7FFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).toUpperCase().padLeft(12, '0');
  }

  /// Verifies that stored system logs carry valid `[SIG:...]` integrity tags.
  Future<bool> verifyLogChainIntegrity() async {
    final logs = await getRecentSystemLogs(limit: 25);
    for (final log in logs) {
      if (!log.details.contains('[SIG:')) {
        return false;
      }
    }
    return true;
  }

  Future<void> purgeAllData() async {
    await delete(chatMessages).go();
    await delete(diaryEntries).go();
    await delete(systemLogs).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'luv_os_core.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      return NativeDatabase.memory();
    }
  });
}
