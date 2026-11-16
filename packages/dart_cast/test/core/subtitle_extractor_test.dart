import 'dart:async';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:test/test.dart';

final RegExp _partPattern = RegExp(
  r'^[0-9a-f]{20}_\d+\.[a-z0-9]{1,8}\.part\.[0-9_]+\.[a-z0-9]{1,8}$',
);

SubtitleStream _track({
  int index = 2,
  int trackIndex = 0,
  String codec = 'subrip',
  String? language = 'eng',
  String? title,
  bool isImageBased = false,
}) => SubtitleStream(
  index: index,
  trackIndex: trackIndex,
  codec: codec,
  language: language,
  title: title,
  isImageBased: isImageBased,
);

MediaFileIdentity _identity(
  String path, {
  int sizeBytes = 10,
  DateTime? modified,
}) => MediaFileIdentity(
  path: path,
  sizeBytes: sizeBytes,
  modified: modified ?? DateTime.utc(2026, 1, 1),
);

class FakeFfmpegJob implements FfmpegJob {
  FakeFfmpegJob({required this.sessionId, required this.arguments});

  @override
  final String? sessionId;

  final List<String> arguments;
  final Completer<FfmpegResult> _done = Completer<FfmpegResult>();
  final List<String?> cancelSessionIds = <String?>[];

  @override
  Future<FfmpegResult> get done => _done.future;

  bool get isDone => _done.isCompleted;

  Future<void> complete({
    int? returnCode = 0,
    String? logs,
    bool writeOutput = true,
    List<int> bytes = const [1, 2, 3],
  }) async {
    if (writeOutput) {
      final output = File(arguments.last);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes, flush: true);
    }
    if (!_done.isCompleted) {
      _done.complete(
        FfmpegResult(
          returnCode: returnCode,
          logs: logs,
          success: returnCode == 0,
          cancelled: false,
        ),
      );
    }
  }

  Future<void> fail({int? returnCode = 1, String? logs}) async {
    if (!_done.isCompleted) {
      _done.complete(
        FfmpegResult(
          returnCode: returnCode,
          logs: logs,
          success: false,
          cancelled: false,
        ),
      );
    }
  }

  @override
  Future<void> cancel() async {
    cancelSessionIds.add(sessionId);
    if (!_done.isCompleted) {
      _done.complete(
        const FfmpegResult(
          returnCode: 255,
          logs: null,
          success: false,
          cancelled: true,
        ),
      );
    }
  }
}

class FakeFfmpegRunner implements FfmpegRunner {
  FakeFfmpegRunner({
    this.autoComplete = true,
    this.writeOutput = true,
    this.returnCode = 0,
    this.logs,
    this.outputBytes = const [1, 2, 3],
    this.startGate,
    this.failStreamIndex,
  });

  bool autoComplete;
  bool writeOutput;
  int returnCode;
  String? logs;
  List<int> outputBytes;
  final Completer<void>? startGate;
  int? failStreamIndex;

  final List<List<String>> startedArguments = <List<String>>[];
  final List<FakeFfmpegJob> jobs = <FakeFfmpegJob>[];
  final List<String> resolvedInputs = <String>[];
  final Completer<void> startCalled = Completer<void>();

  int _nextSessionId = 1;

  @override
  Future<FfmpegJob> start(List<String> arguments) async {
    if (!startCalled.isCompleted) {
      startCalled.complete();
    }
    final gate = startGate;
    if (gate != null) {
      await gate.future;
    }
    final job = FakeFfmpegJob(
      sessionId: '${_nextSessionId++}',
      arguments: List<String>.of(arguments),
    );
    startedArguments.add(List<String>.of(arguments));
    jobs.add(job);

    if (autoComplete) {
      final streamIndex = _streamIndex(arguments);
      final shouldFail =
          failStreamIndex != null && streamIndex == failStreamIndex;
      await job.complete(
        returnCode: shouldFail ? 1 : returnCode,
        logs: shouldFail ? 'fake failure' : logs,
        writeOutput: shouldFail ? false : writeOutput,
        bytes: outputBytes,
      );
    }
    return job;
  }

  @override
  Future<String> resolveInput(String path) async {
    resolvedInputs.add(path);
    return path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
  }

  Future<void> waitForStarts(int count) async {
    for (var i = 0; i < 1000 && startedArguments.length < count; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(startedArguments.length, count);
  }

  int? _streamIndex(List<String> args) {
    final mapIndex = args.indexOf('-map');
    if (mapIndex == -1 || mapIndex + 1 >= args.length) return null;
    return int.tryParse(args[mapIndex + 1].split(':').last);
  }
}

class CountingCache extends SubtitleCache {
  CountingCache({required super.directory});

  int completedLookups = 0;

  @override
  Future<SubtitleCacheEntry?> lookup(SubtitleCacheKey key) async {
    final result = await super.lookup(key);
    completedLookups++;
    return result;
  }
}

void main() {
  late Directory temp;
  late Directory cacheDir;
  late File sourceFile;
  late MediaFileIdentity source;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('subtitle_extractor_test_');
    cacheDir = Directory('${temp.path}/cache');
    sourceFile = File('${temp.path}/movie.mkv');
    await sourceFile.writeAsBytes(const [1, 2, 3, 4], flush: true);
    source = await MediaFileIdentity.fromFile(sourceFile);
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } on FileSystemException {
      // Best effort cleanup.
    }
  });

  SubtitleExtractor extractorFor(FakeFfmpegRunner runner) => SubtitleExtractor(
    runner: runner,
    cache: SubtitleCache(directory: cacheDir),
  );

  Future<List<File>> partFiles() async {
    if (!await cacheDir.exists()) return const [];
    return (await cacheDir.list().toList())
        .whereType<File>()
        .where((file) => file.path.contains('.part.'))
        .toList();
  }

  group('planFor', () {
    final nativeCases = <(String, bool, String, String)>[
      ('subrip', false, 'srt', 'copy'),
      ('webvtt', false, 'vtt', 'copy'),
      ('ass', false, 'ass', 'copy'),
      ('ssa', false, 'ssa', 'copy'),
      ('hdmv_pgs_subtitle', true, 'sup', 'copy'),
      ('dvd_subtitle', true, 'mks', 'copy'),
      ('dvb_subtitle', true, 'mks', 'copy'),
      ('xsub', true, 'mks', 'copy'),
      ('mov_text', false, 'srt', 'srt'),
    ];

    for (final (codec, imageBased, extension, codecArg) in nativeCases) {
      test('native $codec -> $extension ($codecArg)', () {
        final plan = SubtitleExtractor.planFor(
          _track(codec: codec, isImageBased: imageBased),
          SubtitleOutputFormat.native,
        );

        expect(plan.extension, extension);
        expect(plan.codecArgs, ['-c:s', codecArg]);
      });
    }

    test('native is case-insensitive', () {
      final plan = SubtitleExtractor.planFor(
        _track(codec: 'SubRip'),
        SubtitleOutputFormat.native,
      );

      expect(plan.extension, 'srt');
      expect(plan.codecArgs, ['-c:s', 'copy']);
    });

    for (final codec in ['subrip', 'ass', 'ssa', 'webvtt', 'mov_text']) {
      test('webVtt $codec -> vtt webvtt', () {
        final plan = SubtitleExtractor.planFor(
          _track(codec: codec),
          SubtitleOutputFormat.webVtt,
        );

        expect(plan.extension, 'vtt');
        expect(plan.codecArgs, ['-c:s', 'webvtt']);
      });
    }

    test('webVtt rejects image-based tracks', () {
      expect(
        () => SubtitleExtractor.planFor(
          _track(codec: 'hdmv_pgs_subtitle', isImageBased: true),
          SubtitleOutputFormat.webVtt,
        ),
        throwsA(isA<SubtitleUnsupportedCodec>()),
      );
    });
  });

  group('arguments', () {
    test(
      'matches the app argument list and uses the absolute stream index',
      () async {
        final runner = FakeFfmpegRunner();
        final extractor = extractorFor(runner);
        final track = _track(index: 7, trackIndex: 1);

        final result = await extractor.extract(
          source: MediaFileIdentity(
            path: 'file://${sourceFile.path}',
            sizeBytes: source.sizeBytes,
            modified: source.modified,
          ),
          track: track,
        );

        expect(runner.resolvedInputs, ['file://${sourceFile.path}']);
        final arguments = runner.startedArguments.single;
        expect(arguments.sublist(0, arguments.length - 1), [
          '-y',
          '-hide_banner',
          '-nostdin',
          '-i',
          sourceFile.path,
          '-map',
          '0:7',
          '-vn',
          '-an',
          '-dn',
          '-c:s',
          'copy',
        ]);

        final output = File(arguments.last);
        expect(output.parent.path, cacheDir.path);
        expect(output.path.split('.').last, 'srt');
        expect(_partPattern.hasMatch(output.path.split('/').last), isTrue);
        expect(result.file.path, isNot(output.path));
      },
    );
  });

  group('extract', () {
    test('writes, commits and then serves from cache', () async {
      final runner = FakeFfmpegRunner();
      final extractor = extractorFor(runner);
      final track = _track();

      final first = await extractor.extract(source: source, track: track);

      expect(first.fromCache, isFalse);
      expect(first.deduplicated, isFalse);
      expect(await first.file.exists(), isTrue);
      expect(await first.file.readAsBytes(), const [1, 2, 3]);
      expect(await partFiles(), isEmpty);

      final second = await extractor.extract(source: source, track: track);

      expect(second.fromCache, isTrue);
      expect(second.deduplicated, isFalse);
      expect(second.file.path, first.file.path);
      expect(runner.startedArguments, hasLength(1));
    });

    test(
      'empty output throws SubtitleEmptyOutput and leaves no part',
      () async {
        final runner = FakeFfmpegRunner(outputBytes: const []);
        final extractor = extractorFor(runner);

        await expectLater(
          extractor.extract(source: source, track: _track()),
          throwsA(isA<SubtitleEmptyOutput>()),
        );
        expect(await partFiles(), isEmpty);
        expect(extractor.inFlightPaths, isEmpty);
      },
    );

    test(
      'FFmpeg failure keeps the last 2000 log chars and can be retried',
      () async {
        final longLogs = List<String>.filled(5000, 'x').join();
        final runner = FakeFfmpegRunner(
          returnCode: 1,
          logs: longLogs,
          writeOutput: false,
        );
        final extractor = extractorFor(runner);
        final track = _track();

        await expectLater(
          extractor.extract(source: source, track: track),
          throwsA(
            isA<SubtitleFfmpegFailed>()
                .having((e) => e.returnCode, 'returnCode', 1)
                .having((e) => e.logs?.length, 'logs length', 2000)
                .having((e) => e.logs, 'logs tail', longLogs.substring(3000)),
          ),
        );
        expect(await partFiles(), isEmpty);
        expect(extractor.inFlightPaths, isEmpty);

        runner
          ..returnCode = 0
          ..writeOutput = true
          ..logs = null;
        final retry = await extractor.extract(source: source, track: track);

        expect(retry.fromCache, isFalse);
        expect(await retry.file.exists(), isTrue);
        expect(runner.startedArguments, hasLength(2));
      },
    );
  });

  group('dedupe', () {
    test('concurrent calls for the same key start FFmpeg once', () async {
      final runner = FakeFfmpegRunner(autoComplete: false);
      final extractor = extractorFor(runner);
      final track = _track();

      final first = extractor.extract(source: source, track: track);
      await runner.startCalled.future;
      final second = extractor.extract(source: source, track: track);
      await runner.waitForStarts(1);

      expect(runner.jobs, hasLength(1));
      await runner.jobs.single.complete(bytes: const [9, 9]);

      final results = await Future.wait([first, second]);

      expect(runner.startedArguments, hasLength(1));
      expect(results[0].deduplicated, isFalse);
      expect(results[1].deduplicated, isTrue);
      expect(results[0].file.path, results[1].file.path);
      expect(await results[0].file.readAsBytes(), const [9, 9]);
    });

    test('different formats do not share a key', () async {
      final runner = FakeFfmpegRunner(autoComplete: false);
      final extractor = extractorFor(runner);
      final track = _track();

      final nativeFuture = extractor.extract(source: source, track: track);
      await runner.startCalled.future;
      final vttFuture = extractor.extract(
        source: source,
        track: track,
        format: SubtitleOutputFormat.webVtt,
      );
      await runner.waitForStarts(2);

      expect(runner.jobs, hasLength(2));
      await runner.jobs[0].complete();
      await runner.jobs[1].complete();

      final results = await Future.wait([nativeFuture, vttFuture]);
      expect(results[0].file.path.split('.').last, 'srt');
      expect(results[1].file.path.split('.').last, 'vtt');
    });
  });

  group('cancel', () {
    test('cancels by session id and fails every joined caller', () async {
      final runner = FakeFfmpegRunner(autoComplete: false);
      final cache = CountingCache(directory: cacheDir);
      final extractor = SubtitleExtractor(runner: runner, cache: cache);
      final track = _track();

      final first = extractor.extract(source: source, track: track);
      await runner.startCalled.future;
      final second = extractor.extract(source: source, track: track);
      for (var i = 0; i < 1000 && cache.completedLookups < 2; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(Duration.zero);

      await extractor.cancel(source: source, track: track);

      await expectLater(first, throwsA(isA<SubtitleExtractionCancelled>()));
      await expectLater(second, throwsA(isA<SubtitleExtractionCancelled>()));
      expect(runner.jobs.single.cancelSessionIds, ['1']);
      expect(await partFiles(), isEmpty);
      expect(extractor.inFlightPaths, isEmpty);
    });

    test('cancel before the session id exists still cancels', () async {
      final gate = Completer<void>();
      final runner = FakeFfmpegRunner(autoComplete: false, startGate: gate);
      final extractor = extractorFor(runner);
      final track = _track();

      final future = extractor.extract(source: source, track: track);
      await runner.startCalled.future;

      // start() is still waiting on the gate, so no session id exists yet.
      await extractor.cancel(source: source, track: track);
      gate.complete();

      await expectLater(future, throwsA(isA<SubtitleExtractionCancelled>()));
      expect(runner.jobs.single.cancelSessionIds, ['1']);
      expect(await partFiles(), isEmpty);
    });

    test('cancelAll cancels every extraction', () async {
      final runner = FakeFfmpegRunner(autoComplete: false);
      final extractor = extractorFor(runner);

      final first = extractor.extract(source: source, track: _track(index: 2));
      await runner.startCalled.future;
      final second = extractor.extract(source: source, track: _track(index: 3));
      await runner.waitForStarts(2);

      await extractor.cancelAll();

      await expectLater(first, throwsA(isA<SubtitleExtractionCancelled>()));
      await expectLater(second, throwsA(isA<SubtitleExtractionCancelled>()));
      expect(runner.jobs[0].cancelSessionIds, ['1']);
      expect(runner.jobs[1].cancelSessionIds, ['2']);
      expect(extractor.inFlightPaths, isEmpty);
    });

    test('cancel with nothing in flight is a no-op', () async {
      final extractor = extractorFor(FakeFfmpegRunner());

      await extractor.cancel(source: source, track: _track(index: 9));
    });

    test('cancel for an image track under webVtt is a no-op', () async {
      final extractor = extractorFor(FakeFfmpegRunner());

      await extractor.cancel(
        source: source,
        track: _track(codec: 'hdmv_pgs_subtitle', isImageBased: true),
        format: SubtitleOutputFormat.webVtt,
      );
    });
  });

  group('timeout', () {
    test(
      'cancels by session id and throws SubtitleExtractionTimedOut',
      () async {
        final runner = FakeFfmpegRunner(autoComplete: false);
        final extractor = extractorFor(runner);

        final future = extractor.extract(
          source: source,
          track: _track(),
          timeout: const Duration(milliseconds: 10),
        );

        await expectLater(future, throwsA(isA<SubtitleExtractionTimedOut>()));
        expect(runner.jobs.single.cancelSessionIds, ['1']);
        expect(await partFiles(), isEmpty);
        expect(extractor.inFlightPaths, isEmpty);
      },
    );
  });

  group('source', () {
    test('missing plain path throws before starting FFmpeg', () async {
      final runner = FakeFfmpegRunner();
      final extractor = extractorFor(runner);

      await expectLater(
        extractor.extract(
          source: _identity('${temp.path}/missing.mkv'),
          track: _track(),
        ),
        throwsA(isA<SubtitleSourceUnreadable>()),
      );
      expect(runner.startedArguments, isEmpty);
      expect(runner.resolvedInputs, isEmpty);
    });

    test('empty path throws SubtitleSourceUnreadable', () async {
      final extractor = extractorFor(FakeFfmpegRunner());

      await expectLater(
        extractor.extract(source: _identity(''), track: _track()),
        throwsA(isA<SubtitleSourceUnreadable>()),
      );
    });

    test('content:// skips the existence check', () async {
      final runner = FakeFfmpegRunner();
      final extractor = extractorFor(runner);

      final result = await extractor.extract(
        source: _identity('content://media/external/video/42'),
        track: _track(),
      );

      expect(await result.file.exists(), isTrue);
      expect(runner.resolvedInputs, ['content://media/external/video/42']);
      expect(
        runner.startedArguments.single[4],
        'content://media/external/video/42',
      );
    });
  });

  group('extractAll', () {
    test(
      'runs sequentially, reports progress and keeps going after failure',
      () async {
        final runner = FakeFfmpegRunner(failStreamIndex: 3);
        final extractor = extractorFor(runner);
        final tracks = [_track(index: 2), _track(index: 3), _track(index: 4)];
        final progress = <int>[];

        final batch = await extractor.extractAll(
          source: source,
          tracks: tracks,
          onProgress: (result) => progress.add(result.track.index),
        );

        expect(batch.succeeded.map((r) => r.track.index), [2, 4]);
        expect(batch.failed.keys, [3]);
        expect(batch.failed[3], isA<SubtitleFfmpegFailed>());
        expect(batch.isComplete, isFalse);
        expect(progress, [2, 4]);
        expect(runner.startedArguments, hasLength(3));
      },
    );

    test('image-based tracks under webVtt are recorded as failed', () async {
      final runner = FakeFfmpegRunner();
      final extractor = extractorFor(runner);
      final tracks = [
        _track(index: 5, codec: 'hdmv_pgs_subtitle', isImageBased: true),
      ];

      final batch = await extractor.extractAll(
        source: source,
        tracks: tracks,
        format: SubtitleOutputFormat.webVtt,
      );

      expect(batch.succeeded, isEmpty);
      expect(batch.failed[5], isA<SubtitleUnsupportedCodec>());
      expect(batch.isComplete, isFalse);
      expect(runner.startedArguments, isEmpty);
    });

    test('isComplete is true when every track succeeds', () async {
      final extractor = extractorFor(FakeFfmpegRunner());
      final tracks = [_track(index: 2), _track(index: 3)];

      final batch = await extractor.extractAll(source: source, tracks: tracks);

      expect(batch.failed, isEmpty);
      expect(batch.isComplete, isTrue);
      expect(batch.succeeded, hasLength(2));
    });
  });

  group('inFlightPaths', () {
    test(
      'contains the part path during extraction and empties after success',
      () async {
        final runner = FakeFfmpegRunner(autoComplete: false);
        final extractor = extractorFor(runner);

        final future = extractor.extract(source: source, track: _track());
        await runner.startCalled.future;

        expect(extractor.inFlightPaths, hasLength(1));
        expect(
          extractor.inFlightPaths.single,
          runner.startedArguments.single.last,
        );
        expect(File(extractor.inFlightPaths.single).parent.path, cacheDir.path);

        await runner.jobs.single.complete();
        await future;

        expect(extractor.inFlightPaths, isEmpty);
      },
    );

    test('empties after failure', () async {
      final runner = FakeFfmpegRunner(autoComplete: false);
      final extractor = extractorFor(runner);

      final future = extractor.extract(source: source, track: _track());
      await runner.startCalled.future;
      expect(extractor.inFlightPaths, hasLength(1));

      await runner.jobs.single.fail();

      await expectLater(future, throwsA(isA<SubtitleFfmpegFailed>()));
      expect(extractor.inFlightPaths, isEmpty);
      expect(await partFiles(), isEmpty);
    });
  });
}
