import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

/// Clean repository for playback history and user preferences persistence.
@lazySingleton
class PlaybackHistoryRepository {
  final AppDatabase _db;

  PlaybackHistoryRepository(this._db);

  Future<PlaybackHistoryTableData?> getMostRecentHistory() async {
    return _db.getMostRecentHistory();
  }

  Future<List<PlaybackHistoryTableData>> getRecentHistory({int limit = 20}) async {
    return _db.getRecentHistory(limit: limit);
  }

  Future<void> recordHistoryCheckpoint({
    required PureCastMedia media,
    required Duration position,
    required Duration duration,
    required bool completed,
  }) async {
    final companion = PlaybackHistoryTableCompanion(
      id: drift.Value(media.uri),
      title: drift.Value(media.title),
      mediaUri: drift.Value(media.uri),
      mediaType: drift.Value(media.type.name),
      isLocalFile: drift.Value(media.isLocalFile),
      thumbnailUrl: drift.Value(media.thumbnailUrl),
      lastPositionMs: drift.Value(position.inMilliseconds),
      totalDurationMs: drift.Value(duration.inMilliseconds),
      lastPlayedAt: drift.Value(DateTime.now()),
      completed: drift.Value(completed),
    );

    await _db.recordPlaybackHistory(companion);
  }

  Future<void> removeHistory(String id) async {
    await _db.removePlaybackHistory(id);
  }

  Future<void> clearHistory() async {
    await _db.clearPlaybackHistory();
  }

  Future<UserPreferencesTableData> getPreferences() async {
    return _db.getPreferences();
  }

  Future<void> updatePreferences(UserPreferencesTableCompanion prefs) async {
    await _db.updatePreferences(prefs);
  }
}
