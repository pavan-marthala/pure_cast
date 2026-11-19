import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';

void main() {
  late AppDatabase db;
  late PlaybackHistoryRepository repository;

  final media = PureCastMedia(
    uri: '/movies/example.mp4',
    type: PureCastMediaType.video,
    title: 'Example',
    duration: const Duration(minutes: 82),
    isLocalFile: true,
    thumbnailBytes: Uint8List.fromList([1, 2, 3]),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PlaybackHistoryRepository(db);
  });

  tearDown(() => db.close());

  test('saved progress is found again by media URI', () async {
    await repository.recordHistoryCheckpoint(
      media: media,
      position: const Duration(minutes: 10),
      duration: const Duration(minutes: 82),
      completed: false,
    );

    final resume = await repository.getResumeInfo(media.uri);

    expect(resume, isNotNull);
    expect(resume!.canResume, isTrue);
    expect(resume.position, equals(const Duration(minutes: 10)));
    expect(resume.duration, equals(const Duration(minutes: 82)));
    expect(resume.completed, isFalse);
  });

  test('a checkpoint also feeds the progress map for the library', () async {
    await repository.recordHistoryCheckpoint(
      media: media,
      position: const Duration(minutes: 10),
      duration: const Duration(minutes: 82),
      completed: false,
    );

    final positions = await repository.getResumablePositions();

    expect(positions[media.uri], equals(const Duration(minutes: 10)));
  });

  test('starting over clears progress but keeps the history row', () async {
    await repository.recordHistoryCheckpoint(
      media: media,
      position: const Duration(minutes: 10),
      duration: const Duration(minutes: 82),
      completed: false,
    );

    await repository.clearResumePosition(media.uri);

    final resume = await repository.getResumeInfo(media.uri);
    expect(resume, isNotNull);
    expect(resume!.canResume, isFalse);
    expect(resume.position, equals(Duration.zero));
    final rows = await db.getRecentHistory();
    expect(rows, hasLength(1));
    expect(rows.single.lastPositionMs, equals(0));
  });

  test('thumbnail bytes survive the round trip', () async {
    await repository.recordHistoryCheckpoint(
      media: media,
      position: const Duration(minutes: 10),
      duration: const Duration(minutes: 82),
      completed: false,
    );

    final rows = await db.getRecentHistory();

    expect(rows.single.thumbnailBytes, equals(Uint8List.fromList([1, 2, 3])));
  });
}
