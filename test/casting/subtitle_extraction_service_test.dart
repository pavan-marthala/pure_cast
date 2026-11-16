import 'dart:async';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_extraction_service.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_metadata_cache.dart';

class FakeMetadataCache extends SubtitleMetadataCache {
  final Map<String, List<SubtitleStreamInfo>> entries =
      <String, List<SubtitleStreamInfo>>{};
  int getCalls = 0;
  int cacheCalls = 0;
  bool disposed = false;

  @override
  Future<List<SubtitleStreamInfo>?> getCachedSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
  }) async {
    getCalls++;
    return entries[filePath];
  }

  @override
  Future<void> cacheSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
    required List<SubtitleStreamInfo> streams,
  }) async {
    cacheCalls++;
    entries[filePath] = streams;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeProber implements dart_cast.MediaProber {
  FakeProber({this.probeResult, this.error});

  dart_cast.MediaProbe? probeResult;
  Object? error;
  final List<String> probedPaths = <String>[];
  final List<Duration> timeouts = <Duration>[];

  @override
  Future<dart_cast.MediaProbe> probe(
    String inputPath, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    probedPaths.add(inputPath);
    timeouts.add(timeout);
    final e = error;
    if (e != null) throw e;
    final result = probeResult;
    if (result == null) throw dart_cast.ProbeFailedException('no probe');
    return result;
  }
}

class FakeJob implements dart_cast.FfmpegJob {
  FakeJob({required this.sessionId, required this.arguments});

  @override
  final String? sessionId;

  final List<String> arguments;
  final Completer<dart_cast.FfmpegResult> _done =
      Completer<dart_cast.FfmpegResult>();
  final List<String?> cancelledSessionIds = <String?>[];

  @override
  Future<dart_cast.FfmpegResult> get done => _done.future;

  bool get isDone => _done.isCompleted;

  Future<void> complete({
    int? returnCode = 0,
    String? logs,
    bool writeOutput = true,
    List<int> bytes = const [1, 2, 3],
    bool cancelled = false,
  }) async {
    if (writeOutput) {
      final output = File(arguments.last);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes, flush: true);
    }
    if (!_done.isCompleted) {
      _done.complete(
        dart_cast.FfmpegResult(
          returnCode: returnCode,
          logs: logs,
          success: returnCode == 0 && !cancelled,
          cancelled: cancelled,
        ),
      );
    }
  }

  @override
  Future<void> cancel() async {
    cancelledSessionIds.add(sessionId);
    if (!_done.isCompleted) {
      _done.complete(
        const dart_cast.FfmpegResult(
          returnCode: 255,
          logs: null,
          success: false,
          cancelled: true,
        ),
      );
    }
  }
}

class FakeRunner implements dart_cast.FfmpegRunner {
  FakeRunner({
    this.autoComplete = true,
    this.writeOutput = true,
    this.returnCode = 0,
    this.logs,
    this.outputBytes = const [1, 2, 3],
    this.failStreamIndex,
    this.startError,
    this.startGate,
    this.resolvedContentPath,
    this.resolveInputError,
  });

  bool autoComplete;
  bool writeOutput;
  int returnCode;
  String? logs;
  List<int> outputBytes;
  int? failStreamIndex;
  Object? startError;
  final Completer<void>? startGate;
  String? resolvedContentPath;
  Object? resolveInputError;

  final List<List<String>> startedArguments = <List<String>>[];
  final List<FakeJob> jobs = <FakeJob>[];
  final List<String> resolvedInputs = <String>[];
  final Completer<void> startCalled = Completer<void>();

  int _nextSessionId = 1;

  @override
  Future<dart_cast.FfmpegJob> start(List<String> arguments) async {
    if (!startCalled.isCompleted) {
      startCalled.complete();
    }
    final error = startError;
    if (error != null) throw error;
    final gate = startGate;
    if (gate != null) {
      await gate.future;
    }
    final job = FakeJob(
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
    final error = resolveInputError;
    if (error != null) throw error;
    if (path.startsWith('content://')) {
      return resolvedContentPath ?? path;
    }
    return path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
  }

  int? _streamIndex(List<String> args) {
    final mapIndex = args.indexOf('-map');
    if (mapIndex == -1 || mapIndex + 1 >= args.length) return null;
    return int.tryParse(args[mapIndex + 1].split(':').last);
  }
}

dart_cast.MediaProbe _probe({List<dart_cast.SubtitleStream>? subtitles}) {
  return dart_cast.MediaProbe(
    container: 'matroska,webm',
    durationSeconds: 60,
    video: const dart_cast.VideoStream(codec: 'h264'),
    audio: const [dart_cast.AudioStream(index: 1, codec: 'aac', channels: 2)],
    subtitles: subtitles ?? const [],
  );
}

SubtitleStreamInfo _info({
  int streamIndex = 2,
  int trackIndex = 0,
  String codec = 'subrip',
  String? language = 'eng',
  String? title,
  bool image = false,
}) {
  return SubtitleStreamInfo(
    streamIndex: streamIndex,
    trackIndex: trackIndex,
    codecName: codec,
    language: language,
    title: title,
    isImageBased: image,
  );
}

void main() {
  late Directory temp;
  late File sourceFile;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('subtitle_service_test_');
    sourceFile = File('${temp.path}/movie.mkv');
    await sourceFile.writeAsBytes(const [1, 2, 3, 4], flush: true);
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } on FileSystemException {
      // Best effort cleanup.
    }
  });

  Directory cacheDir() =>
      Directory('${temp.path}/pure_cast_subtitle_cache_v2');

  SubtitleExtractionService serviceFor({
    FakeProber? prober,
    FakeRunner? runner,
    Directory? directory,
    FakeMetadataCache? metadata,
  }) {
    return SubtitleExtractionService.withDependencies(
      metadataCache: metadata ?? FakeMetadataCache(),
      prober: prober ?? FakeProber(),
      runner: runner ?? FakeRunner(),
      cacheDirectory: () async => directory ?? cacheDir(),
    );
  }

  group('probeSubtitleStreams', () {
    test('maps subtitle streams and keeps their absolute/track indices',
        () async {
      final prober = FakeProber(
        probeResult: _probe(
          subtitles: const [
            dart_cast.SubtitleStream(
              index: 2,
              trackIndex: 0,
              codec: 'subrip',
              language: 'eng',
              title: 'English',
            ),
            dart_cast.SubtitleStream(
              index: 5,
              trackIndex: 1,
              codec: 'hdmv_pgs_subtitle',
              isImageBased: true,
            ),
          ],
        ),
      );
      final service = serviceFor(prober: prober);

      final result = await service.probeSubtitleStreams(sourceFile.path);

      expect(result.hasSubtitles, isTrue);
      expect(result.streams, hasLength(2));
      final first = result.streams[0];
      expect(first.streamIndex, 2);
      expect(first.trackIndex, 0);
      expect(first.codecName, 'subrip');
      expect(first.language, 'eng');
      expect(first.title, 'English');
      expect(first.isImageBased, isFalse);
      expect(first.displayLabel, 'ENG (SUBRIP)');

      final second = result.streams[1];
      expect(second.streamIndex, 5);
      expect(second.trackIndex, 1);
      expect(second.codecName, 'hdmv_pgs_subtitle');
      expect(second.language, isNull);
      expect(second.isImageBased, isTrue);
      expect(second.displayLabel, 'Unknown (HDMV_PGS_SUBTITLE)');

      expect(prober.probedPaths, [sourceFile.path]);
      expect(prober.timeouts.single, const Duration(seconds: 30));
    });

    test('resolves a file:// path before probing', () async {
      final prober = FakeProber(
        probeResult: _probe(
          subtitles: const [
            dart_cast.SubtitleStream(
              index: 2,
              trackIndex: 0,
              codec: 'subrip',
            ),
          ],
        ),
      );
      final service = serviceFor(prober: prober);

      final result = await service.probeSubtitleStreams(
        'file://${sourceFile.path}',
      );

      expect(result.hasSubtitles, isTrue);
      expect(prober.probedPaths, [sourceFile.path]);
    });

    test('lowercases the codec name', () async {
      final prober = FakeProber(
        probeResult: _probe(
          subtitles: const [
            dart_cast.SubtitleStream(
              index: 2,
              trackIndex: 0,
              codec: 'SUBRIP',
            ),
          ],
        ),
      );
      final service = serviceFor(prober: prober);

      final result = await service.probeSubtitleStreams(sourceFile.path);

      expect(result.streams.single.codecName, 'subrip');
      expect(result.streams.single.displayLabel, 'Unknown (SUBRIP)');
    });

    test('returns empty when the prober throws', () async {
      final prober = FakeProber(
        error: dart_cast.ProbeFailedException('probe failed'),
      );
      final service = serviceFor(prober: prober);

      expect((await service.probeSubtitleStreams(sourceFile.path)).streams,
          isEmpty);
    });

    test('returns empty when the prober throws any other error', () async {
      final prober = FakeProber(error: Exception('boom'));
      final service = serviceFor(prober: prober);

      expect((await service.probeSubtitleStreams(sourceFile.path)).streams,
          isEmpty);
    });

    test('returns empty when the source file is missing', () async {
      final prober = FakeProber(probeResult: _probe());
      final service = serviceFor(prober: prober);

      final result = await service.probeSubtitleStreams(
        '${temp.path}/missing.mkv',
      );

      expect(result.streams, isEmpty);
      expect(prober.probedPaths, isEmpty);
    });

    test('returns empty when a content:// URI cannot be resolved', () async {
      final prober = FakeProber(probeResult: _probe());
      final service = serviceFor(prober: prober);

      final result = await service.probeSubtitleStreams(
        'content://media/external/video/42',
      );

      expect(result.streams, isEmpty);
      expect(prober.probedPaths, isEmpty);
    });

    test('probes a resolved content:// URI', () async {
      final prober = FakeProber(
        probeResult: _probe(
          subtitles: const [
            dart_cast.SubtitleStream(
              index: 2,
              trackIndex: 0,
              codec: 'subrip',
            ),
          ],
        ),
      );
      final runner = FakeRunner(
        resolvedContentPath: '/proc/saf/external/video/42',
      );
      final service = serviceFor(prober: prober, runner: runner);

      final result = await service.probeSubtitleStreams(
        'content://media/external/video/42',
      );

      expect(result.hasSubtitles, isTrue);
      expect(prober.probedPaths, ['/proc/saf/external/video/42']);
    });

    test('returns empty when disposed', () async {
      final prober = FakeProber(probeResult: _probe());
      final service = serviceFor(prober: prober);
      await service.dispose();

      expect((await service.probeSubtitleStreams(sourceFile.path)).streams,
          isEmpty);
      expect(prober.probedPaths, isEmpty);
    });
  });

  group('probeAndCacheSubtitles', () {
    test('reuses cached streams instead of probing again', () async {
      final prober = FakeProber(
        probeResult: _probe(
          subtitles: const [
            dart_cast.SubtitleStream(
              index: 2,
              trackIndex: 0,
              codec: 'subrip',
            ),
          ],
        ),
      );
      final metadata = FakeMetadataCache();
      final service = serviceFor(prober: prober, metadata: metadata);
      final stat = await sourceFile.stat();

      final first = await service.probeAndCacheSubtitles(
        filePath: sourceFile.path,
        fileSize: stat.size,
        lastModified: stat.modified,
      );
      final second = await service.probeAndCacheSubtitles(
        filePath: sourceFile.path,
        fileSize: stat.size,
        lastModified: stat.modified,
      );

      expect(first.streams, hasLength(1));
      expect(second.streams, hasLength(1));
      expect(prober.probedPaths, hasLength(1));
      expect(metadata.cacheCalls, 1);
      expect(metadata.getCalls, 2);
    });
  });

  group('extractSubtitle', () {
    test('extracts with the old argument list and then hits the cache',
        () async {
      final runner = FakeRunner();
      final service = serviceFor(runner: runner);
      final stream = _info();

      final first = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: stream,
      );

      expect(first.isSuccess, isTrue);
      expect(first.outputPath, isNotNull);
      final output = File(first.outputPath!);
      expect(await output.exists(), isTrue);
      expect(output.parent.path, cacheDir().path);
      expect(first.outputPath, contains('pure_cast_subtitle_cache'));

      final arguments = runner.startedArguments.single;
      expect(arguments.sublist(0, arguments.length - 1), [
        '-y',
        '-hide_banner',
        '-nostdin',
        '-i',
        sourceFile.path,
        '-map',
        '0:2',
        '-vn',
        '-an',
        '-dn',
        '-c:s',
        'copy',
      ]);
      expect(arguments.last.split('.').last, 'srt');

      final second = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: stream,
      );

      expect(second.isSuccess, isTrue);
      expect(second.outputPath, first.outputPath);
      expect(runner.startedArguments, hasLength(1));
    });

    test('missing source returns Cannot resolve source without starting FFmpeg',
        () async {
      final runner = FakeRunner();
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: '${temp.path}/missing.mkv',
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Cannot resolve source');
      expect(runner.startedArguments, isEmpty);
    });

    test('FFmpeg failure maps to FFmpeg failed with logs and return code',
        () async {
      final runner = FakeRunner(
        returnCode: 1,
        logs: 'boom',
        writeOutput: false,
      );
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'FFmpeg failed');
      expect(result.error?.returnCode, 1);
      expect(result.error?.ffmpegLogs, 'boom');
    });

    test('empty output maps to Empty output', () async {
      final runner = FakeRunner(outputBytes: const []);
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Empty output');
    });

    test('a cancelled job maps to Cancelled', () async {
      final runner = FakeRunner(autoComplete: false);
      final service = serviceFor(runner: runner);

      final future = service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );
      await runner.startCalled.future;
      await runner.jobs.single.cancel();

      final result = await future;

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Cancelled');
    });

    test('a runner start error maps to FFmpeg failed', () async {
      final runner = FakeRunner(startError: StateError('no session'));
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'FFmpeg failed');
      expect(result.error?.ffmpegLogs, isNull);
      expect(result.error?.returnCode, isNull);
    });

    test('a cache failure maps to Cache error', () async {
      final notADirectory = File('${temp.path}/not_a_directory');
      await notADirectory.writeAsString('x');
      final service = serviceFor(
        directory: Directory(notADirectory.path),
      );

      final result = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Cache error');
    });

    test('an unresolved content:// source maps to Cannot resolve source',
        () async {
      final runner = FakeRunner();
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: 'content://media/external/video/42',
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Cannot resolve source');
      expect(runner.startedArguments, isEmpty);
    });

    test('a resolved content:// source extracts using the resolved input',
        () async {
      final runner = FakeRunner(
        resolvedContentPath: '/proc/saf/external/video/42',
      );
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: 'content://media/external/video/42',
        stream: _info(),
      );

      expect(result.isSuccess, isTrue);
      expect(runner.startedArguments.single[4], '/proc/saf/external/video/42');
    });

    test('disposed service returns Service disposed', () async {
      final service = serviceFor();
      await service.dispose();

      final result = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Service disposed');
    });
  });

  group('extractCastSubtitle', () {
    test('extracts WebVTT with the old argument list', () async {
      final runner = FakeRunner();
      final service = serviceFor(runner: runner);

      final result = await service.extractCastSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isSuccess, isTrue);
      expect(result.outputPath, isNotNull);
      expect(result.outputPath!.split('.').last, 'vtt');
      expect(await File(result.outputPath!).exists(), isTrue);

      final arguments = runner.startedArguments.single;
      expect(arguments.sublist(0, arguments.length - 1), [
        '-y',
        '-hide_banner',
        '-nostdin',
        '-i',
        sourceFile.path,
        '-map',
        '0:2',
        '-vn',
        '-an',
        '-dn',
        '-c:s',
        'webvtt',
      ]);
    });

    test('rejects image-based tracks before touching the cache', () async {
      final runner = FakeRunner();
      final service = serviceFor(runner: runner);

      final result = await service.extractCastSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(codec: 'hdmv_pgs_subtitle', image: true),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, "Image-based subtitles can't be cast");
      expect(runner.startedArguments, isEmpty);
      expect(await cacheDir().exists(), isFalse);
    });

    test('disposed service returns Service disposed', () async {
      final service = serviceFor();
      await service.dispose();

      final result = await service.extractCastSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'Service disposed');
    });
  });

  group('concurrent requests', () {
    test('identical requests share one FFmpeg run and both succeed', () async {
      final runner = FakeRunner(autoComplete: false);
      final service = serviceFor(runner: runner);
      final stream = _info();

      final first = service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: stream,
      );
      await runner.startCalled.future;
      final second = service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: stream,
      );
      await Future<void>.delayed(Duration.zero);

      expect(runner.startedArguments, hasLength(1));
      await runner.jobs.single.complete();

      final results = await Future.wait([first, second]);

      expect(results[0].isSuccess, isTrue);
      expect(results[1].isSuccess, isTrue);
      expect(results[0].outputPath, results[1].outputPath);
      expect(runner.startedArguments, hasLength(1));
    });
  });

  group('extractAllSubtitles', () {
    test('reports results and progress in order and keeps going after failure',
        () async {
      final prober = FakeProber(
        probeResult: _probe(
          subtitles: const [
            dart_cast.SubtitleStream(index: 2, trackIndex: 0, codec: 'subrip'),
            dart_cast.SubtitleStream(index: 3, trackIndex: 1, codec: 'subrip'),
            dart_cast.SubtitleStream(index: 4, trackIndex: 2, codec: 'subrip'),
          ],
        ),
      );
      final runner = FakeRunner(failStreamIndex: 3);
      final service = serviceFor(prober: prober, runner: runner);
      final progress = <int>[];

      final batch = await service.extractAllSubtitles(
        sourcePath: sourceFile.path,
        onProgress: (result) => progress.add(result.stream.streamIndex),
      );

      expect(batch.results, hasLength(3));
      expect(batch.results.map((r) => r.stream.streamIndex), [2, 3, 4]);
      expect(batch.results[0].isSuccess, isTrue);
      expect(batch.results[1].isFailure, isTrue);
      expect(batch.results[1].error?.message, 'FFmpeg failed');
      expect(batch.results[2].isSuccess, isTrue);
      expect(batch.successCount, 2);
      expect(batch.failureCount, 1);
      expect(progress, [2, 3, 4]);
      expect(runner.startedArguments, hasLength(3));
    });

    test('returns an empty batch when there are no subtitles', () async {
      final prober = FakeProber(probeResult: _probe());
      final service = serviceFor(prober: prober);

      final batch = await service.extractAllSubtitles(
        sourcePath: sourceFile.path,
      );

      expect(batch.results, isEmpty);
      expect(batch.cancelled, isFalse);
    });

    test('returns a cancelled empty batch when disposed', () async {
      final service = serviceFor();
      await service.dispose();

      final batch = await service.extractAllSubtitles(
        sourcePath: sourceFile.path,
      );

      expect(batch.results, isEmpty);
      expect(batch.cancelled, isTrue);
    });
  });

  group('cache maintenance', () {
    test('size, clear and cleanup use the package cache', () async {
      final runner = FakeRunner();
      final service = serviceFor(runner: runner);

      final result = await service.extractSubtitle(
        sourcePath: sourceFile.path,
        stream: _info(),
      );
      expect(result.isSuccess, isTrue);
      expect(await service.getExtractionCacheSize(), greaterThan(0));

      final cleanup = await service.cleanupExtractionCache();
      expect(cleanup.deletedFiles, 0);

      await service.clearExtractionCache();
      expect(await service.getExtractionCacheSize(), 0);
      expect(await File(result.outputPath!).exists(), isFalse);
    });
  });
}
