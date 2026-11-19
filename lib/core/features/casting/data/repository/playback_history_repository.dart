import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

/// A saved playback checkpoint that playback can resume from.
class ResumeInfo {
  /// Minimum watched position before resuming is worth offering.
  static const Duration minWatched = Duration(seconds: 10);

  /// Minimum remaining time; near the end resuming is not useful.
  static const Duration minRemaining = Duration(seconds: 30);

  final Duration position;
  final Duration duration;
  final bool completed;

  const ResumeInfo({
    required this.position,
    required this.duration,
    required this.completed,
  });

  /// Whether resuming should be offered.
  ///
  /// This deliberately ignores [completed]: receivers report "completed" when
  /// they go idle, which includes a manual stop. Whether there is anything
  /// left to watch is decided by the remaining time instead.
  bool get canResume =>
      position >= minWatched &&
      duration > Duration.zero &&
      duration - position >= minRemaining;
}

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

  /// Saved progress for [mediaUri], or `null` when the media was never played.
  Future<ResumeInfo?> getResumeInfo(String mediaUri) async {
    final row = await _db.getHistoryFor(mediaUri);
    if (row == null) return null;
    return ResumeInfo(
      position: Duration(milliseconds: row.lastPositionMs),
      duration: Duration(milliseconds: row.totalDurationMs),
      completed: row.completed,
    );
  }

  /// Positions that are worth resuming, keyed by media URI.
  ///
  /// Used by the media library to show a "continue watching" progress bar.
  Future<Map<String, Duration>> getResumablePositions({
    int limit = 500,
  }) async {
    final rows = await _db.getRecentHistory(limit: limit);
    final result = <String, Duration>{};
    for (final row in rows) {
      final info = ResumeInfo(
        position: Duration(milliseconds: row.lastPositionMs),
        duration: Duration(milliseconds: row.totalDurationMs),
        completed: row.completed,
      );
      if (info.canResume) {
        result[row.mediaUri] = info.position;
      }
    }
    return result;
  }

  /// Forgets the saved position but keeps the row in the recent history.
  Future<void> clearResumePosition(String mediaUri) async {
    await _db.clearPlaybackPosition(mediaUri);
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
      thumbnailBytes: drift.Value(media.thumbnailBytes),
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
