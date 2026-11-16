import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:test/test.dart';

const String _hash = '0123456789abcdef0123';

MediaFileIdentity _identity({
  String path = '/videos/movie.mkv',
  int sizeBytes = 100,
  DateTime? modified,
}) => MediaFileIdentity(
  path: path,
  sizeBytes: sizeBytes,
  modified: modified ?? DateTime.utc(2026, 1, 2, 3, 4, 5),
);

SubtitleCacheKey _key({
  MediaFileIdentity? source,
  int streamIndex = 2,
  String extension = 'srt',
}) => SubtitleCacheKey(
  source: source ?? _identity(),
  streamIndex: streamIndex,
  extension: extension,
);

Future<File> _writeFile(
  String path, [
  List<int> bytes = const [1, 2, 3],
]) async {
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> _age(File file, Duration age, DateTime reference) =>
    file.setLastModified(reference.subtract(age));

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('subtitle_cache_test_');
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } on FileSystemException {
      // Best effort cleanup.
    }
  });

  group('MediaFileIdentity', () {
    test('fromFile reads size and modification time', () async {
      final file = await _writeFile('${temp.path}/source.mkv', const [
        1,
        2,
        3,
        4,
        5,
      ]);
      final modified = DateTime(2026, 2, 3, 4, 5, 6);
      await file.setLastModified(modified);

      final identity = await MediaFileIdentity.fromFile(file);

      expect(identity.path, file.path);
      expect(identity.sizeBytes, 5);
      expect(
        identity.modified.millisecondsSinceEpoch,
        modified.millisecondsSinceEpoch,
      );
    });

    test('value equality covers path, size and modified', () {
      expect(_identity(), _identity());
      expect(_identity().hashCode, _identity().hashCode);
      expect(_identity(), isNot(_identity(path: '/other.mkv')));
      expect(_identity(), isNot(_identity(sizeBytes: 101)));
      expect(
        _identity(),
        isNot(_identity(modified: DateTime.utc(2026, 1, 2, 3, 4, 6))),
      );
    });
  });

  group('SubtitleCacheKey', () {
    test('fileName is stable and has the documented shape', () {
      final first = _key().fileName;
      final second = _key().fileName;

      expect(first, second);
      expect(RegExp(r'^[0-9a-f]{20}_2\.srt$').hasMatch(first), isTrue);
      expect(first.substring(0, 20), hasLength(20));
    });

    test('fileName changes with every identity or plan input', () {
      final base = _key().fileName;

      expect(
        _key(source: _identity(path: '/videos/other.mkv')).fileName,
        isNot(base),
      );
      expect(_key(source: _identity(sizeBytes: 101)).fileName, isNot(base));
      expect(
        _key(
          source: _identity(modified: DateTime.utc(2026, 1, 2, 3, 4, 6)),
        ).fileName,
        isNot(base),
      );
      expect(_key(streamIndex: 3).fileName, isNot(base));
      expect(_key(extension: 'sup').fileName, isNot(base));
    });

    test('rejects invalid extensions and negative stream indexes', () {
      for (final extension in ['../x', 'SRT', '', 'toolongext1']) {
        expect(
          () => _key(extension: extension),
          throwsArgumentError,
          reason: extension,
        );
      }
      expect(() => _key(streamIndex: -1), throwsArgumentError);
    });
  });

  group('lookup', () {
    test('missing directory is a miss, not an error', () async {
      final cache = SubtitleCache(directory: Directory('${temp.path}/missing'));

      expect(await cache.lookup(_key()), isNull);
    });

    test('zero-length file is a miss', () async {
      final cache = SubtitleCache(directory: temp);
      await _writeFile('${temp.path}/${_key().fileName}', const []);

      expect(await cache.lookup(_key()), isNull);
    });

    test('hit returns size and refreshes the modification time', () async {
      final cache = SubtitleCache(directory: temp);
      final file = await _writeFile('${temp.path}/${_key().fileName}', const [
        1,
        2,
        3,
        4,
      ]);
      final old = DateTime.now().subtract(const Duration(hours: 3));
      await file.setLastModified(old);

      final entry = await cache.lookup(_key());

      expect(entry, isNotNull);
      expect(entry!.file.path, file.path);
      expect(entry.sizeBytes, 4);
      expect(entry.lastUsed.isAfter(old), isTrue);
      expect((await file.lastModified()).isAfter(old), isTrue);
    });
  });

  group('partFileFor', () {
    test('returns unique temp paths inside the cache directory', () async {
      final cache = SubtitleCache(directory: temp);
      final key = _key();

      final first = await cache.partFileFor(key);
      final second = await cache.partFileFor(key);

      expect(first.path, isNot(second.path));
      expect(first.parent.path, temp.path);
      expect(second.parent.path, temp.path);
      expect(first.path, contains('${key.fileName}.part.'));
      expect(second.path, contains('${key.fileName}.part.'));
      expect(await first.exists(), isFalse);
      expect(await second.exists(), isFalse);
    });

    test('creates the cache directory when missing', () async {
      final nested = Directory('${temp.path}/nested/deeper');
      final cache = SubtitleCache(directory: nested);

      final part = await cache.partFileFor(_key());

      expect(await nested.exists(), isTrue);
      expect(part.parent.path, nested.path);
    });
  });

  group('commit', () {
    test('renames the part file and lookup then hits', () async {
      final cache = SubtitleCache(directory: temp);
      final key = _key();
      final part = await cache.partFileFor(key);
      await _writeFile(part.path, const [1, 2, 3, 4, 5]);

      final entry = await cache.commit(key, part);

      expect(entry.file.path, '${temp.path}/${key.fileName}');
      expect(entry.file.path, endsWith(key.fileName));
      expect(entry.sizeBytes, 5);
      expect(await part.exists(), isFalse);
      expect(await entry.file.exists(), isTrue);
      expect((await cache.lookup(key))?.sizeBytes, 5);
    });

    test('rejects an empty part file and deletes it', () async {
      final cache = SubtitleCache(directory: temp);
      final key = _key();
      final part = await cache.partFileFor(key);
      await _writeFile(part.path, const []);

      await expectLater(
        cache.commit(key, part),
        throwsA(isA<SubtitleCacheException>()),
      );
      expect(await part.exists(), isFalse);
    });

    test(
      'rejects a part outside the cache directory without deleting it',
      () async {
        final outside = await Directory.systemTemp.createTemp(
          'subtitle_cache_outside_',
        );
        addTearDown(() async {
          try {
            await outside.delete(recursive: true);
          } on FileSystemException {
            // Best effort cleanup.
          }
        });
        final cache = SubtitleCache(directory: temp);
        final foreign = await _writeFile('${outside.path}/foreign.part', const [
          9,
        ]);

        await expectLater(
          cache.commit(_key(), foreign),
          throwsA(isA<SubtitleCacheException>()),
        );
        expect(await foreign.exists(), isTrue);
        expect(await foreign.readAsBytes(), const [9]);
      },
    );

    test('rejects a missing part file', () async {
      final cache = SubtitleCache(directory: temp);
      final part = File('${temp.path}/${_key().fileName}.part.missing');

      await expectLater(
        cache.commit(_key(), part),
        throwsA(isA<SubtitleCacheException>()),
      );
    });

    test('replaces an existing final file', () async {
      final cache = SubtitleCache(directory: temp);
      final key = _key();
      final existing = await _writeFile('${temp.path}/${key.fileName}', const [
        1,
        2,
        3,
      ]);

      final part = await cache.partFileFor(key);
      await _writeFile(part.path, const [4, 5, 6, 7]);
      await cache.commit(key, part);

      expect(await existing.exists(), isTrue);
      expect(await existing.readAsBytes(), const [4, 5, 6, 7]);
    });

    test(
      'two sequential commits of the same key leave one final file',
      () async {
        final cache = SubtitleCache(directory: temp);
        final key = _key();

        for (final bytes in [
          const [1],
          const [2, 3],
        ]) {
          final part = await cache.partFileFor(key);
          await _writeFile(part.path, bytes);
          await cache.commit(key, part);
        }

        final matches =
            (await temp.list().toList())
                .whereType<File>()
                .where((f) => f.path.endsWith(key.fileName))
                .toList();
        expect(matches, hasLength(1));
        expect(await matches.single.readAsBytes(), const [2, 3]);
      },
    );
  });

  group('discard', () {
    test('deletes an existing part file', () async {
      final cache = SubtitleCache(directory: temp);
      final part = await _writeFile('${temp.path}/a.part.1');

      await cache.discard(part);

      expect(await part.exists(), isFalse);
    });

    test('is silent for a missing file', () async {
      final cache = SubtitleCache(directory: temp);

      await cache.discard(File('${temp.path}/missing.part.1'));
    });
  });

  group('stats', () {
    test('counts only cache-pattern final files', () async {
      final cache = SubtitleCache(directory: temp);
      final first = await _writeFile('${temp.path}/${_hash}_0.srt', const [
        1,
        2,
        3,
      ]);
      final second = await _writeFile('${temp.path}/${_hash}_1.sup', const [
        4,
        5,
      ]);
      await _writeFile('${temp.path}/${_hash}_2.srt.part.abc', const [6]);
      await _writeFile('${temp.path}/foreign.txt', const [7, 8, 9, 10]);
      await Directory('${temp.path}/subdir').create();

      final older = DateTime(2026, 3, 1);
      final newer = DateTime(2026, 4, 1);
      await first.setLastModified(older);
      await second.setLastModified(newer);

      final stats = await cache.stats();

      expect(stats.fileCount, 2);
      expect(stats.totalBytes, 5);
      expect(stats.oldest, older);
    });

    test('empty or missing directory yields empty stats', () async {
      final empty = await SubtitleCache(directory: temp).stats();
      expect(empty.fileCount, 0);
      expect(empty.totalBytes, 0);
      expect(empty.oldest, isNull);

      final missing =
          await SubtitleCache(
            directory: Directory('${temp.path}/missing'),
          ).stats();
      expect(missing.fileCount, 0);
      expect(missing.totalBytes, 0);
      expect(missing.oldest, isNull);
    });
  });

  group('cleanup', () {
    final reference = DateTime.utc(2026, 6, 1, 12);

    SubtitleCache limitedCache({
      Duration maxAge = const Duration(days: 1),
      int maxTotalBytes = 1024,
      Duration orphanPartAge = const Duration(hours: 1),
    }) => SubtitleCache(
      directory: temp,
      limits: SubtitleCacheLimits(
        maxAge: maxAge,
        maxTotalBytes: maxTotalBytes,
        orphanPartAge: orphanPartAge,
      ),
    );

    test('deletes expired entries and keeps recent ones', () async {
      final cache = limitedCache();
      final expired = await _writeFile('${temp.path}/${_hash}_0.srt', const [
        1,
        2,
        3,
      ]);
      final recent = await _writeFile('${temp.path}/${_hash}_1.srt', const [
        4,
        5,
      ]);
      await _age(expired, const Duration(days: 2), reference);
      await _age(recent, const Duration(hours: 1), reference);

      final result = await cache.cleanup(now: reference);

      expect(await expired.exists(), isFalse);
      expect(await recent.exists(), isTrue);
      expect(result.deletedFiles, 1);
      expect(result.deletedBytes, 3);
      expect(result.remainingFiles, 1);
      expect(result.remainingBytes, 2);
    });

    test('deletes the oldest entries until the byte cap fits', () async {
      final cache = limitedCache(
        maxAge: const Duration(days: 100),
        maxTotalBytes: 10,
      );
      final oldest = await _writeFile('${temp.path}/${_hash}_0.srt', const [
        1,
        2,
        3,
        4,
      ]);
      final middle = await _writeFile('${temp.path}/${_hash}_1.srt', const [
        1,
        2,
        3,
        4,
      ]);
      final newest = await _writeFile('${temp.path}/${_hash}_2.srt', const [
        1,
        2,
        3,
        4,
      ]);
      await _age(oldest, const Duration(hours: 3), reference);
      await _age(middle, const Duration(hours: 2), reference);
      await _age(newest, const Duration(hours: 1), reference);

      final result = await cache.cleanup(now: reference);

      expect(await oldest.exists(), isFalse);
      expect(await middle.exists(), isTrue);
      expect(await newest.exists(), isTrue);
      expect(result.deletedFiles, 1);
      expect(result.deletedBytes, 4);
      expect(result.remainingFiles, 2);
      expect(result.remainingBytes, 8);
    });

    test('protected entries survive expiry and the byte cap', () async {
      final cache = limitedCache(
        maxAge: const Duration(hours: 1),
        maxTotalBytes: 4,
      );
      final protectedFile = await _writeFile(
        '${temp.path}/${_hash}_0.srt',
        const [1, 2, 3, 4],
      );
      final other = await _writeFile('${temp.path}/${_hash}_1.srt', const [
        1,
        2,
        3,
        4,
      ]);
      await _age(protectedFile, const Duration(days: 30), reference);
      await _age(other, const Duration(days: 30), reference);

      final result = await cache.cleanup(
        now: reference,
        protectedPaths: {protectedFile.path},
      );

      expect(await protectedFile.exists(), isTrue);
      expect(await other.exists(), isFalse);
      expect(result.remainingFiles, 1);
      expect(result.remainingBytes, 4);
    });

    test('deletes old orphan parts but keeps fresh ones', () async {
      final cache = limitedCache();
      final oldPart = await _writeFile(
        '${temp.path}/${_hash}_0.srt.part.100_1',
        const [1, 2],
      );
      final freshPart = await _writeFile(
        '${temp.path}/${_hash}_1.srt.part.100_2',
        const [3, 4, 5],
      );
      await _age(oldPart, const Duration(hours: 2), reference);
      await _age(freshPart, const Duration(minutes: 5), reference);

      final result = await cache.cleanup(now: reference);

      expect(await oldPart.exists(), isFalse);
      expect(await freshPart.exists(), isTrue);
      expect(result.deletedFiles, 1);
      expect(result.deletedBytes, 2);
    });

    test('leaves foreign files and subdirectories untouched', () async {
      final cache = limitedCache();
      final foreign = await _writeFile('${temp.path}/foreign.txt', const [
        1,
        2,
        3,
      ]);
      final subdir = await Directory('${temp.path}/subdir').create();
      final nested = await _writeFile('${subdir.path}/nested.srt', const [4]);
      await _age(foreign, const Duration(days: 30), reference);
      await _age(nested, const Duration(days: 30), reference);

      final result = await cache.cleanup(now: reference);

      expect(await foreign.exists(), isTrue);
      expect(await subdir.exists(), isTrue);
      expect(await nested.exists(), isTrue);
      expect(result.deletedFiles, 0);
      expect(result.remainingFiles, 0);
    });

    test('missing directory is a no-op', () async {
      final cache = SubtitleCache(directory: Directory('${temp.path}/missing'));

      final result = await cache.cleanup(now: reference);

      expect(result.deletedFiles, 0);
      expect(result.deletedBytes, 0);
      expect(result.remainingFiles, 0);
      expect(result.remainingBytes, 0);
    });

    test(
      'a non-file named like a cache entry is ignored, not deleted',
      () async {
        // A real cross-platform permission failure cannot be simulated here
        // without chmod (and root would bypass it), so the safety branch that
        // ignores non-files is covered instead: cleanup must not touch it and
        // must not abort.
        final cache = limitedCache();
        final directoryNamedLikeEntry =
            await Directory('${temp.path}/${_hash}_0.srt').create();
        final expired = await _writeFile('${temp.path}/${_hash}_1.srt', const [
          1,
        ]);
        await _age(expired, const Duration(days: 5), reference);

        final result = await cache.cleanup(now: reference);

        expect(await directoryNamedLikeEntry.exists(), isTrue);
        expect(await expired.exists(), isFalse);
        expect(result.deletedFiles, 1);
      },
    );
  });

  group('clear', () {
    test(
      'deletes final files and parts but keeps protected and foreign files',
      () async {
        final cache = SubtitleCache(directory: temp);
        final finalFile = await _writeFile(
          '${temp.path}/${_hash}_0.srt',
          const [1, 2, 3],
        );
        final partFile = await _writeFile(
          '${temp.path}/${_hash}_1.srt.part.200_0',
          const [4, 5],
        );
        final protectedFile = await _writeFile(
          '${temp.path}/${_hash}_2.srt',
          const [6, 7, 8, 9],
        );
        final foreign = await _writeFile('${temp.path}/notes.txt', const [1]);
        final subdir = await Directory('${temp.path}/subdir').create();

        final result = await cache.clear(protectedPaths: {protectedFile.path});

        expect(await finalFile.exists(), isFalse);
        expect(await partFile.exists(), isFalse);
        expect(await protectedFile.exists(), isTrue);
        expect(await foreign.exists(), isTrue);
        expect(await subdir.exists(), isTrue);
        expect(result.deletedFiles, 2);
        expect(result.deletedBytes, 5);
        expect(result.remainingFiles, 1);
        expect(result.remainingBytes, 4);
      },
    );

    test('missing directory is a no-op', () async {
      final cache = SubtitleCache(directory: Directory('${temp.path}/missing'));

      final result = await cache.clear();

      expect(result.deletedFiles, 0);
      expect(result.remainingFiles, 0);
    });
  });

  group('limits', () {
    test('SubtitleCache rejects non-positive durations', () async {
      expect(
        () => SubtitleCache(
          directory: temp,
          limits: const SubtitleCacheLimits(maxAge: Duration.zero),
        ),
        throwsArgumentError,
      );
      expect(
        () => SubtitleCache(
          directory: temp,
          limits: const SubtitleCacheLimits(orphanPartAge: Duration.zero),
        ),
        throwsArgumentError,
      );
    });

    test('SubtitleCacheException is a CastException', () {
      expect(SubtitleCacheException('x'), isA<CastException>());
    });
  });
}
