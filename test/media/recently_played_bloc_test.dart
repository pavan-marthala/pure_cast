import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/recently_played/recently_played_bloc.dart';
import 'package:pure_cast/core/utils/state_status.dart';

class FakePlaybackHistoryRepository implements PlaybackHistoryRepository {
  List<PlaybackHistoryTableData> historyData = [];
  bool shouldFail = false;
  String? lastRemovedId;

  @override
  Future<List<PlaybackHistoryTableData>> getRecentHistory({int limit = 20}) async {
    if (shouldFail) {
      throw const PureCastException('Database failure');
    }
    return historyData.take(limit).toList();
  }

  @override
  Future<PlaybackHistoryTableData?> getMostRecentHistory() async {
    if (shouldFail) {
      throw const PureCastException('Database failure');
    }
    return historyData.isNotEmpty ? historyData.first : null;
  }

  @override
  Future<void> recordHistoryCheckpoint({
    required PureCastMedia media,
    required Duration position,
    required Duration duration,
    required bool completed,
  }) async {}

  @override
  Future<void> removeHistory(String id) async {
    if (shouldFail) {
      throw const PureCastException('Failed to remove history');
    }
    lastRemovedId = id;
    historyData.removeWhere((item) => item.id == id || item.mediaUri == id);
  }

  @override
  Future<void> clearHistory() async {
    if (shouldFail) {
      throw const PureCastException('Failed to clear history');
    }
    historyData.clear();
  }

  @override
  Future<UserPreferencesTableData> getPreferences() async {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePreferences(UserPreferencesTableCompanion prefs) async {}
}

void main() {
  late FakePlaybackHistoryRepository fakeRepository;
  late RecentlyPlayedBloc bloc;

  setUp(() {
    fakeRepository = FakePlaybackHistoryRepository();
    bloc = RecentlyPlayedBloc(fakeRepository);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('RecentlyPlayedBloc Tests', () {
    test('1. Initial state status is StateStatus.initial and media is empty', () {
      expect(bloc.state.status, equals(StateStatus.initial));
      expect(bloc.state.media, isEmpty);
      expect(bloc.state.error, isNull);
    });

    test('2. Loading history successfully updates status to loaded and populates media', () async {
      final now = DateTime.now();
      fakeRepository.historyData = [
        PlaybackHistoryTableData(
          id: 'uri1',
          title: 'Movie A',
          mediaUri: 'http://example.com/a.mp4',
          mediaType: 'mp4',
          isLocalFile: false,
          thumbnailUrl: 'http://example.com/a.jpg',
          lastPositionMs: 1000,
          totalDurationMs: 60000,
          lastPlayedAt: now,
          completed: true,
        ),
      ];

      bloc.add(const LoadRecentlyPlayedEvent());
      await pumpEventQueue();

      expect(bloc.state.status, equals(StateStatus.loaded));
      expect(bloc.state.media.length, equals(1));
      expect(bloc.state.media.first.title, equals('Movie A'));
      expect(bloc.state.media.first.uri, equals('http://example.com/a.mp4'));
      expect(bloc.state.media.first.type, equals(PureCastMediaType.mp4));
      expect(bloc.state.error, isNull);
    });

    test('3. Empty history results in StateStatus.empty status', () async {
      fakeRepository.historyData = [];

      bloc.add(const LoadRecentlyPlayedEvent());
      await pumpEventQueue();

      expect(bloc.state.status, equals(StateStatus.empty));
      expect(bloc.state.media, isEmpty);
      expect(bloc.state.error, isNull);
    });

    test('4. Repository/database failure sets status to StateStatus.error', () async {
      fakeRepository.shouldFail = true;

      bloc.add(const LoadRecentlyPlayedEvent());
      await pumpEventQueue();

      expect(bloc.state.status, equals(StateStatus.error));
      expect(bloc.state.media, isEmpty);
      expect(bloc.state.error, contains('Database failure'));
    });

    test('5. Multiple history records are returned ordered by lastPlayedAt DESC', () async {
      final now = DateTime.now();
      fakeRepository.historyData = [
        PlaybackHistoryTableData(
          id: 'uri_newest',
          title: 'Newest Video',
          mediaUri: 'http://example.com/newest.mp4',
          mediaType: 'mp4',
          isLocalFile: false,
          thumbnailUrl: null,
          lastPositionMs: 0,
          totalDurationMs: 120000,
          lastPlayedAt: now.add(const Duration(minutes: 10)),
          completed: false,
        ),
        PlaybackHistoryTableData(
          id: 'uri_older',
          title: 'Older Video',
          mediaUri: 'http://example.com/older.mp4',
          mediaType: 'mp4',
          isLocalFile: false,
          thumbnailUrl: null,
          lastPositionMs: 0,
          totalDurationMs: 90000,
          lastPlayedAt: now,
          completed: true,
        ),
      ];

      bloc.add(const LoadRecentlyPlayedEvent());
      await pumpEventQueue();

      expect(bloc.state.status, equals(StateStatus.loaded));
      expect(bloc.state.media.length, equals(2));
      expect(bloc.state.media[0].title, equals('Newest Video'));
      expect(bloc.state.media[1].title, equals('Older Video'));
    });

    test('6. Refresh reloads latest database data', () async {
      final now = DateTime.now();
      fakeRepository.historyData = [
        PlaybackHistoryTableData(
          id: 'uri1',
          title: 'Video 1',
          mediaUri: 'http://example.com/1.mp4',
          mediaType: 'mp4',
          isLocalFile: false,
          thumbnailUrl: null,
          lastPositionMs: 0,
          totalDurationMs: 60000,
          lastPlayedAt: now,
          completed: true,
        ),
      ];

      bloc.add(const LoadRecentlyPlayedEvent());
      await pumpEventQueue();
      expect(bloc.state.media.length, equals(1));

      // Update database with a second item
      fakeRepository.historyData.insert(
        0,
        PlaybackHistoryTableData(
          id: 'uri2',
          title: 'Video 2',
          mediaUri: 'http://example.com/2.mp4',
          mediaType: 'mp4',
          isLocalFile: false,
          thumbnailUrl: null,
          lastPositionMs: 0,
          totalDurationMs: 60000,
          lastPlayedAt: now.add(const Duration(minutes: 5)),
          completed: false,
        ),
      );

      bloc.add(const RefreshRecentlyPlayedEvent());
      await pumpEventQueue();

      expect(bloc.state.status, equals(StateStatus.loaded));
      expect(bloc.state.media.length, equals(2));
      expect(bloc.state.media.first.title, equals('Video 2'));
    });

    test('7. Remove history event delegates to repository and refreshes state', () async {
      final now = DateTime.now();
      fakeRepository.historyData = [
        PlaybackHistoryTableData(
          id: 'http://example.com/1.mp4',
          title: 'Video 1',
          mediaUri: 'http://example.com/1.mp4',
          mediaType: 'mp4',
          isLocalFile: false,
          thumbnailUrl: null,
          lastPositionMs: 0,
          totalDurationMs: 60000,
          lastPlayedAt: now,
          completed: true,
        ),
      ];

      bloc.add(const RemoveRecentlyPlayedEvent('http://example.com/1.mp4'));
      await pumpEventQueue();

      expect(fakeRepository.lastRemovedId, equals('http://example.com/1.mp4'));
      expect(bloc.state.status, equals(StateStatus.empty));
      expect(bloc.state.media, isEmpty);
    });
  });
}
