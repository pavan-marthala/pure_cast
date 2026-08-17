import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ── 1. Last Casted Device Table ─────────────────────────────
class LastCastedDeviceTable extends Table {
  @override
  String get tableName => 'last_casted_device';

  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get protocol => text()(); // 'chromecast' | 'dlna'
  DateTimeColumn get lastCastAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

// ── 2. Playback Queue Table ──────────────────────────────────
class PlaybackQueueTable extends Table {
  @override
  String get tableName => 'playback_queue';

  TextColumn get id => text()();
  TextColumn get mediaUri => text()();
  TextColumn get mediaType => text()(); // 'video' | 'audio' | 'hls' | 'mp4' | 'mkv'
  TextColumn get title => text()();
  TextColumn get thumbnail => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get isLocalFile => boolean().withDefault(const Constant(false))();
  IntColumn get queueOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── 3. Playback History Table ────────────────────────────────
class PlaybackHistoryTable extends Table {
  @override
  String get tableName => 'playback_history';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get mediaUri => text()();
  TextColumn get mediaType => text()();
  BoolColumn get isLocalFile => boolean().withDefault(const Constant(false))();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get lastPositionMs => integer().withDefault(const Constant(0))();
  IntColumn get totalDurationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── 4. User Preferences Table ────────────────────────────────
class UserPreferencesTable extends Table {
  @override
  String get tableName => 'user_preferences';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get preferredAudioLanguage => text().withDefault(const Constant('en'))();
  TextColumn get preferredSubtitleLanguage => text().withDefault(const Constant('en'))();
  BoolColumn get autoPlayNext => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database Class ───────────────────────────────────────────
@lazySingleton
@DriftDatabase(tables: [
  LastCastedDeviceTable,
  PlaybackQueueTable,
  PlaybackHistoryTable,
  UserPreferencesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Last Casted Device Queries ──
  Future<LastCastedDeviceTableData?> getLastCastedDevice() async {
    final list = await (select(lastCastedDeviceTable)
          ..orderBy([(t) => OrderingTerm.desc(t.lastCastAt)])
          ..limit(1))
        .get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> setLastCastedDevice({
    required String deviceId,
    required String deviceName,
    required String protocol,
  }) async {
    await into(lastCastedDeviceTable).insertOnConflictUpdate(
      LastCastedDeviceTableCompanion.insert(
        deviceId: deviceId,
        deviceName: deviceName,
        protocol: protocol,
        lastCastAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearLastCastedDevice() async {
    await delete(lastCastedDeviceTable).go();
  }

  // ── Playback Queue Queries ──
  Future<List<PlaybackQueueTableData>> getQueue() async {
    return (select(playbackQueueTable)
          ..orderBy([(t) => OrderingTerm.asc(t.queueOrder)]))
        .get();
  }

  Future<void> saveQueue(List<PlaybackQueueTableCompanion> items) async {
    await transaction(() async {
      await delete(playbackQueueTable).go();
      for (final item in items) {
        await into(playbackQueueTable).insert(item);
      }
    });
  }

  Future<void> addToQueue(PlaybackQueueTableCompanion item) async {
    await into(playbackQueueTable).insertOnConflictUpdate(item);
  }

  Future<void> removeFromQueue(String id) async {
    await (delete(playbackQueueTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearQueue() async {
    await delete(playbackQueueTable).go();
  }

  // ── Playback History Queries ──
  Future<List<PlaybackHistoryTableData>> getRecentHistory({int limit = 20}) async {
    return (select(playbackHistoryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
          ..limit(limit))
        .get();
  }

  Future<PlaybackHistoryTableData?> getMostRecentHistory() async {
    final list = await (select(playbackHistoryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
          ..limit(1))
        .get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> recordPlaybackHistory(PlaybackHistoryTableCompanion entry) async {
    await into(playbackHistoryTable).insertOnConflictUpdate(entry);
  }

  Future<void> removePlaybackHistory(String id) async {
    await (delete(playbackHistoryTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearPlaybackHistory() async {
    await delete(playbackHistoryTable).go();
  }

  // ── User Preferences Queries ──
  Future<UserPreferencesTableData> getPreferences() async {
    final list = await select(userPreferencesTable).get();
    if (list.isNotEmpty) return list.first;

    const defaultPrefs = UserPreferencesTableCompanion(
      id: Value(1),
      preferredAudioLanguage: Value('en'),
      preferredSubtitleLanguage: Value('en'),
      autoPlayNext: Value(true),
    );
    await into(userPreferencesTable).insert(defaultPrefs);
    return (await select(userPreferencesTable).get()).first;
  }

  Future<void> updatePreferences(UserPreferencesTableCompanion prefs) async {
    await into(userPreferencesTable).insertOnConflictUpdate(prefs);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pure_cast.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
