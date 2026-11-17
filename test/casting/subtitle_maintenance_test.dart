import 'dart:io';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_extraction_service.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_maintenance.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_metadata_cache.dart';

class _FakeMetadataCache extends SubtitleMetadataCache {
  final List<String> events;
  int calls = 0;
  Object? error;

  _FakeMetadataCache(this.events);

  @override
  Future<int> removeOlderThan(Duration maxAge, {DateTime? now}) async {
    calls++;
    events.add('metadata');
    if (error != null) throw error!;
    return 0;
  }
}

class _FakeExtractionService extends SubtitleExtractionService {
  final List<String> events;
  int calls = 0;
  Object? error;

  _FakeExtractionService(this.events) : super(SubtitleMetadataCache());

  @override
  Future<dart_cast.SubtitleCacheCleanupResult> cleanupExtractionCache() async {
    calls++;
    events.add('extraction');
    if (error != null) throw error!;
    return const dart_cast.SubtitleCacheCleanupResult(
      deletedFiles: 0,
      deletedBytes: 0,
      remainingFiles: 0,
      remainingBytes: 0,
    );
  }
}

void main() {
  group('SubtitleMaintenance', () {
    late Directory temp;
    late Directory legacyCache;
    late Directory legacySubtitles;
    late Directory currentCache;
    late Directory unrelated;
    late List<String> events;
    late _FakeMetadataCache metadataCache;
    late _FakeExtractionService extractionService;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp(
        'subtitle_maintenance_test_',
      );
      legacyCache = Directory('${temp.path}/pure_cast_subtitle_cache');
      legacySubtitles = Directory('${temp.path}/pure_cast_subtitles');
      currentCache = Directory('${temp.path}/pure_cast_subtitle_cache_v2');
      unrelated = Directory('${temp.path}/unrelated');
      await legacyCache.create(recursive: true);
      await legacySubtitles.create(recursive: true);
      await currentCache.create(recursive: true);
      await unrelated.create(recursive: true);
      await File('${legacyCache.path}/old.srt').writeAsString('legacy');
      await File('${legacySubtitles.path}/old.vtt').writeAsString('legacy');
      await File('${currentCache.path}/current.vtt').writeAsString('current');
      await File('${unrelated.path}/keep.txt').writeAsString('unrelated');
      events = <String>[];
      metadataCache = _FakeMetadataCache(events);
      extractionService = _FakeExtractionService(events);
    });

    tearDown(() async {
      try {
        await temp.delete(recursive: true);
      } on FileSystemException {
        // Best effort cleanup.
      }
    });

    SubtitleMaintenance maintenance() => SubtitleMaintenance(
      metadataCache: metadataCache,
      extractionService: extractionService,
      appSupportDirectory: () async => temp,
    );

    test('removes both legacy directories but keeps the current *_v2 cache, '
        'unrelated siblings and every later step', () async {
      await maintenance().run();

      expect(await legacyCache.exists(), isFalse);
      expect(await legacySubtitles.exists(), isFalse);
      expect(await currentCache.exists(), isTrue);
      expect(
        await File('${currentCache.path}/current.vtt').readAsString(),
        'current',
      );
      expect(await unrelated.exists(), isTrue);
      expect(
        await File('${unrelated.path}/keep.txt').readAsString(),
        'unrelated',
      );
      expect(extractionService.calls, 1);
      expect(metadataCache.calls, 1);
      expect(events, ['extraction', 'metadata']);
    });

    test('running twice does not throw and leaves the current cache alone',
        () async {
      await maintenance().run();
      await maintenance().run();

      expect(await legacyCache.exists(), isFalse);
      expect(await legacySubtitles.exists(), isFalse);
      expect(await currentCache.exists(), isTrue);
      expect(extractionService.calls, 2);
      expect(metadataCache.calls, 2);
    });

    test('a legacy path that is a regular file and a throwing cache step do '
        'not stop the remaining steps', () async {
      await legacyCache.delete(recursive: true);
      await File(legacyCache.path).writeAsString('regular file');
      extractionService.error = StateError('cache cleanup failed');

      await maintenance().run();

      // The file was not treated as a directory, and the later steps ran.
      expect(await File(legacyCache.path).exists(), isTrue);
      expect(await legacySubtitles.exists(), isFalse);
      expect(extractionService.calls, 1);
      expect(metadataCache.calls, 1);
      expect(events, ['extraction', 'metadata']);
    });

    test('a throwing metadata step does not escape', () async {
      metadataCache.error = StateError('metadata cleanup failed');

      await expectLater(maintenance().run(), completes);
      expect(metadataCache.calls, 1);
    });
  });
}
