import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_extraction_service.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_metadata_cache.dart';

Map<String, dynamic> _entryJson({required DateTime probedAt}) {
  return SubtitleMetadataCacheEntry(
    filePath: '/videos/movie.mkv',
    fileSize: 10,
    lastModified: DateTime.utc(2026, 1, 1),
    streams: [
      SubtitleStreamInfo(
        streamIndex: 2,
        trackIndex: 0,
        codecName: 'subrip',
        isImageBased: false,
      ),
    ],
    probedAt: probedAt,
  ).toJson();
}

Future<File> _writeEntry(
  Directory dir,
  String name, {
  required DateTime probedAt,
}) {
  final file = File('${dir.path}/$name');
  return file.writeAsString(jsonEncode(_entryJson(probedAt: probedAt)));
}

void main() {
  group('SubtitleMetadataCache.removeOlderThan', () {
    late Directory temp;
    late Directory cacheDir;
    late SubtitleMetadataCache cache;
    final now = DateTime.utc(2026, 11, 17, 12);

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('subtitle_metadata_test_');
      cacheDir = Directory('${temp.path}/pure_cast_subtitle_metadata');
      await cacheDir.create(recursive: true);
      cache = SubtitleMetadataCache(directoryOverride: () async => cacheDir);
    });

    tearDown(() async {
      try {
        await temp.delete(recursive: true);
      } on FileSystemException {
        // Best effort cleanup.
      }
    });

    test('deletes only old entries and keeps recent ones', () async {
      final old = await _writeEntry(
        cacheDir,
        'aa11.json',
        probedAt: now.subtract(const Duration(days: 31)),
      );
      // A recent file mtime must not save an entry whose probedAt is old.
      await old.setLastModified(now);
      final recent = await _writeEntry(
        cacheDir,
        'bb22.json',
        probedAt: now.subtract(const Duration(days: 1)),
      );

      final deleted = await cache.removeOlderThan(
        const Duration(days: 30),
        now: now,
      );

      expect(deleted, 1);
      expect(await old.exists(), isFalse);
      expect(await recent.exists(), isTrue);
    });

    test('ignores foreign files, other extensions and subdirectories',
        () async {
      final foreign = File('${cacheDir.path}/notes.txt')
        ..writeAsStringSync('keep me');
      final uppercase = await _writeEntry(
        cacheDir,
        'cc33.JSON',
        probedAt: now.subtract(const Duration(days: 31)),
      );
      final notHex = await _writeEntry(
        cacheDir,
        'nothex.json',
        probedAt: now.subtract(const Duration(days: 31)),
      );
      final nestedDir = Directory('${cacheDir.path}/nested');
      await nestedDir.create();
      final nested = await _writeEntry(
        nestedDir,
        'dd44.json',
        probedAt: now.subtract(const Duration(days: 31)),
      );

      final deleted = await cache.removeOlderThan(
        const Duration(days: 30),
        now: now,
      );

      expect(deleted, 0);
      expect(await foreign.exists(), isTrue);
      expect(await uppercase.exists(), isTrue);
      expect(await notHex.exists(), isTrue);
      expect(await nested.exists(), isTrue);
    });

    test('a corrupt entry falls back to its modification time', () async {
      final oldCorrupt = File('${cacheDir.path}/ee55.json')
        ..writeAsStringSync('not json');
      await oldCorrupt.setLastModified(
        now.subtract(const Duration(days: 31)),
      );
      final recentCorrupt = File('${cacheDir.path}/ff66.json')
        ..writeAsStringSync('{"unexpected": true}');
      await recentCorrupt.setLastModified(
        now.subtract(const Duration(days: 1)),
      );

      final deleted = await cache.removeOlderThan(
        const Duration(days: 30),
        now: now,
      );

      expect(deleted, 1);
      expect(await oldCorrupt.exists(), isFalse);
      expect(await recentCorrupt.exists(), isTrue);
    });

    test('a missing directory is a no-op and is not created', () async {
      final missing = Directory('${temp.path}/does_not_exist');
      final missingCache = SubtitleMetadataCache(
        directoryOverride: () async => missing,
      );

      final deleted = await missingCache.removeOlderThan(
        const Duration(days: 30),
        now: now,
      );

      expect(deleted, 0);
      expect(await missing.exists(), isFalse);
    });

    test('entries written through the cache round-trip in the injected '
        'directory', () async {
      final lastModified = DateTime.utc(2026, 11, 1);
      await cache.cacheSubtitles(
        filePath: '/videos/other.mkv',
        fileSize: 42,
        lastModified: lastModified,
        streams: [
          SubtitleStreamInfo(
            streamIndex: 3,
            trackIndex: 0,
            codecName: 'ass',
            isImageBased: false,
          ),
        ],
      );

      final cached = await cache.getCachedSubtitles(
        filePath: '/videos/other.mkv',
        fileSize: 42,
        lastModified: lastModified,
      );

      expect(cached, isNotNull);
      expect(cached!.single.streamIndex, 3);
      expect(await cacheDir.list().toList(), hasLength(1));
    });
  });
}
