import 'dart:async';
import 'dart:io';

import 'ffmpeg_runner.dart';
import 'media_probe.dart';
import 'media_track_exceptions.dart';
import 'subtitle_cache.dart';

/// Output flavour requested from [SubtitleExtractor].
enum SubtitleOutputFormat {
  /// Keep the source codec where possible, using the app's native table
  /// (for example SubRip becomes `.srt` with `-c:s copy`).
  native,

  /// Convert text subtitles to WebVTT for casting.
  ///
  /// Image-based tracks cannot be converted and fail with
  /// [SubtitleUnsupportedCodec].
  webVtt,
}

/// Output file extension and the FFmpeg arguments that select its codec.
class SubtitleOutputPlan {
  /// Output file extension without a dot, for example `srt` or `vtt`.
  final String extension;

  /// FFmpeg arguments that set the subtitle codec, for example
  /// `['-c:s', 'copy']`.
  final List<String> codecArgs;

  /// Creates a plan.
  const SubtitleOutputPlan({required this.extension, required this.codecArgs});
}

/// One successfully extracted subtitle track.
class SubtitleExtractionResult {
  /// The track that was extracted.
  final SubtitleStream track;

  /// The final cache file.
  final File file;

  /// True when the result came from the cache without starting FFmpeg.
  final bool fromCache;

  /// True when this call joined an extraction that was already in flight.
  final bool deduplicated;

  /// Creates a result.
  const SubtitleExtractionResult({
    required this.track,
    required this.file,
    required this.fromCache,
    required this.deduplicated,
  });
}

/// Outcome of [SubtitleExtractor.extractAll].
class SubtitleBatchResult {
  /// Successful extractions, in input track order.
  final List<SubtitleExtractionResult> succeeded;

  /// Failures keyed by [SubtitleStream.index] (the absolute stream index).
  final Map<int, MediaTrackException> failed;

  /// Creates a batch result.
  const SubtitleBatchResult({required this.succeeded, required this.failed});

  /// True when every requested track succeeded.
  bool get isComplete => failed.isEmpty;
}

/// Extracts embedded subtitle tracks into a [SubtitleCache].
///
/// The caller supplies the tracks (normally from `MediaProber`); this class
/// never probes. It owns only in-flight coordination and delegates the actual
/// FFmpeg process to the injected [FfmpegRunner].
class SubtitleExtractor {
  /// Runs FFmpeg processes.
  final FfmpegRunner runner;

  /// Stores extracted subtitle files.
  final SubtitleCache cache;

  final Map<String, _InFlightExtraction> _inFlight =
      <String, _InFlightExtraction>{};
  final Set<String> _inFlightPaths = <String>{};

  /// Creates an extractor.
  SubtitleExtractor({required this.runner, required this.cache});

  /// Absolute temp-file paths currently being written.
  ///
  /// Callers can pass this set as `protectedPaths` to
  /// [SubtitleCache.cleanup] so an in-progress extraction is never deleted.
  Set<String> get inFlightPaths => Set<String>.unmodifiable(_inFlightPaths);

  /// Returns the output plan for [track] and [format] without doing any I/O.
  ///
  /// Throws [SubtitleUnsupportedCodec] when [format] is
  /// [SubtitleOutputFormat.webVtt] and the track is image-based.
  static SubtitleOutputPlan planFor(
    SubtitleStream track,
    SubtitleOutputFormat format,
  ) {
    switch (format) {
      case SubtitleOutputFormat.webVtt:
        if (track.isImageBased) {
          throw SubtitleUnsupportedCodec(
            'Image-based subtitles cannot be converted to WebVTT',
          );
        }
        return const SubtitleOutputPlan(
          extension: 'vtt',
          codecArgs: ['-c:s', 'webvtt'],
        );
      case SubtitleOutputFormat.native:
        switch (track.codec.toLowerCase()) {
          case 'subrip':
            return const SubtitleOutputPlan(
              extension: 'srt',
              codecArgs: ['-c:s', 'copy'],
            );
          case 'webvtt':
            return const SubtitleOutputPlan(
              extension: 'vtt',
              codecArgs: ['-c:s', 'copy'],
            );
          case 'ass':
            return const SubtitleOutputPlan(
              extension: 'ass',
              codecArgs: ['-c:s', 'copy'],
            );
          case 'ssa':
            return const SubtitleOutputPlan(
              extension: 'ssa',
              codecArgs: ['-c:s', 'copy'],
            );
          case 'hdmv_pgs_subtitle':
            return const SubtitleOutputPlan(
              extension: 'sup',
              codecArgs: ['-c:s', 'copy'],
            );
          default:
            if (track.isImageBased) {
              return const SubtitleOutputPlan(
                extension: 'mks',
                codecArgs: ['-c:s', 'copy'],
              );
            }
            return const SubtitleOutputPlan(
              extension: 'srt',
              codecArgs: ['-c:s', 'srt'],
            );
        }
    }
  }

  /// Extracts [track] from [source] and returns its cached file.
  ///
  /// Returns immediately on a cache hit. When an extraction for the same cache
  /// key is already running, this call joins it and returns the same file with
  /// [SubtitleExtractionResult.deduplicated] set.
  ///
  /// [timeout] bounds the FFmpeg run; on expiry the process is cancelled by
  /// session id and [SubtitleExtractionTimedOut] is thrown.
  ///
  /// Throws [SubtitleSourceUnreadable] when [source] is empty or a plain source
  /// path does not exist, [SubtitleUnsupportedCodec] when the track cannot
  /// produce [format], [SubtitleFfmpegFailed] when FFmpeg fails,
  /// [SubtitleEmptyOutput] when FFmpeg writes nothing, and
  /// [SubtitleExtractionCancelled] when cancellation wins.
  Future<SubtitleExtractionResult> extract({
    required MediaFileIdentity source,
    required SubtitleStream track,
    SubtitleOutputFormat format = SubtitleOutputFormat.native,
    Duration? timeout,
  }) async {
    if (source.path.isEmpty) {
      throw SubtitleSourceUnreadable('Subtitle source path is empty');
    }
    final plan = planFor(track, format);
    final key = SubtitleCacheKey(
      source: source,
      streamIndex: track.index,
      extension: plan.extension,
    );

    final cached = await cache.lookup(key);
    if (cached != null) {
      return SubtitleExtractionResult(
        track: track,
        file: cached.file,
        fromCache: true,
        deduplicated: false,
      );
    }

    final existing = _inFlight[key.fileName];
    if (existing != null) {
      final result = await existing.result.future;
      return SubtitleExtractionResult(
        track: track,
        file: result.file,
        fromCache: result.fromCache,
        deduplicated: true,
      );
    }

    final entry = _InFlightExtraction();
    // The owner reports its own failure through the returned future; this
    // listener keeps a failure unhandled when no joiner ever attaches.
    entry.result.future.ignore();
    _inFlight[key.fileName] = entry;

    try {
      final result = await _runOwner(
        source: source,
        track: track,
        key: key,
        plan: plan,
        entry: entry,
        timeout: timeout,
      );
      if (!entry.result.isCompleted) {
        entry.result.complete(result);
      }
      return result;
    } catch (error, stackTrace) {
      if (!entry.result.isCompleted) {
        entry.result.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      _inFlight.remove(key.fileName);
    }
  }

  /// Cancels the in-flight extraction for [source] / [track] / [format].
  ///
  /// All callers awaiting that extraction receive
  /// [SubtitleExtractionCancelled]. Does nothing when no matching extraction is
  /// running, including when [format] rejects the track.
  Future<void> cancel({
    required MediaFileIdentity source,
    required SubtitleStream track,
    SubtitleOutputFormat format = SubtitleOutputFormat.native,
  }) async {
    final SubtitleOutputPlan plan;
    try {
      plan = planFor(track, format);
    } on SubtitleUnsupportedCodec {
      return;
    }
    final key = SubtitleCacheKey(
      source: source,
      streamIndex: track.index,
      extension: plan.extension,
    );
    final entry = _inFlight[key.fileName];
    if (entry == null) return;
    await _cancelEntry(entry);
  }

  /// Cancels every in-flight extraction.
  Future<void> cancelAll() async {
    final entries = _inFlight.values.toList(growable: false);
    for (final entry in entries) {
      entry.cancelRequested = true;
      if (!entry.cancellation.isCompleted) {
        entry.cancellation.complete();
      }
    }
    for (final entry in entries) {
      final job = entry.job;
      if (job != null) {
        try {
          await job.cancel();
        } on Object {
          // Cancellation is best effort.
        }
      }
    }
  }

  /// Extracts every track in [tracks], sequentially, in input order.
  ///
  /// A failing track is recorded in [SubtitleBatchResult.failed] and does not
  /// stop later tracks. Only [MediaTrackException]s are recorded; other
  /// failures (for example cache I/O errors) propagate.
  ///
  /// [onProgress] is called after each successful extraction, in track order.
  Future<SubtitleBatchResult> extractAll({
    required MediaFileIdentity source,
    required List<SubtitleStream> tracks,
    SubtitleOutputFormat format = SubtitleOutputFormat.native,
    void Function(SubtitleExtractionResult)? onProgress,
    Duration? timeout,
  }) async {
    final succeeded = <SubtitleExtractionResult>[];
    final failed = <int, MediaTrackException>{};
    for (final track in tracks) {
      try {
        final result = await extract(
          source: source,
          track: track,
          format: format,
          timeout: timeout,
        );
        succeeded.add(result);
        onProgress?.call(result);
      } on MediaTrackException catch (error) {
        failed[track.index] = error;
      }
    }
    return SubtitleBatchResult(succeeded: succeeded, failed: failed);
  }

  Future<void> _cancelEntry(_InFlightExtraction entry) async {
    entry.cancelRequested = true;
    if (!entry.cancellation.isCompleted) {
      entry.cancellation.complete();
    }
    final job = entry.job;
    if (job != null) {
      try {
        await job.cancel();
      } on Object {
        // Cancellation is best effort.
      }
    }
  }

  Future<SubtitleExtractionResult> _runOwner({
    required MediaFileIdentity source,
    required SubtitleStream track,
    required SubtitleCacheKey key,
    required SubtitleOutputPlan plan,
    required _InFlightExtraction entry,
    required Duration? timeout,
  }) async {
    await _ensureSourceReadable(source);

    final part = await cache.partFileFor(key);
    _inFlightPaths.add(part.path);
    try {
      final input = await runner.resolveInput(source.path);
      final arguments = <String>[
        '-y',
        '-hide_banner',
        '-nostdin',
        '-i',
        input,
        '-map',
        '0:${track.index}',
        '-vn',
        '-an',
        '-dn',
        ...plan.codecArgs,
        part.path,
      ];

      final job = await runner.start(arguments);
      entry.job = job;
      if (entry.cancelRequested) {
        try {
          await job.cancel();
        } on Object {
          // Cancellation is best effort.
        }
        throw SubtitleExtractionCancelled('Subtitle extraction was cancelled');
      }

      final outcome = await _awaitJob(job, entry, timeout);

      if (entry.cancelRequested || outcome.cancelled) {
        throw SubtitleExtractionCancelled('Subtitle extraction was cancelled');
      }
      if (!outcome.success) {
        throw SubtitleFfmpegFailed(
          'FFmpeg failed to extract the subtitle track',
          returnCode: outcome.returnCode,
          logs: outcome.logs,
        );
      }
      if (!await part.exists() || await part.length() == 0) {
        throw SubtitleEmptyOutput('FFmpeg produced an empty subtitle file');
      }

      final committed = await cache.commit(key, part);
      return SubtitleExtractionResult(
        track: track,
        file: committed.file,
        fromCache: false,
        deduplicated: false,
      );
    } finally {
      _inFlightPaths.remove(part.path);
      await cache.discard(part);
    }
  }

  Future<FfmpegResult> _awaitJob(
    FfmpegJob job,
    _InFlightExtraction entry,
    Duration? timeout,
  ) async {
    final done = job.done;
    // If cancellation or timeout wins the race, a late error from the job must
    // not surface as an unhandled asynchronous error.
    done.ignore();
    final raced = Future.any<FfmpegResult?>(<Future<FfmpegResult?>>[
      done,
      entry.cancellation.future.then<FfmpegResult?>((_) => null),
    ]);
    try {
      final outcome =
          timeout == null ? await raced : await raced.timeout(timeout);
      if (outcome == null || entry.cancelRequested) {
        throw SubtitleExtractionCancelled('Subtitle extraction was cancelled');
      }
      return outcome;
    } on TimeoutException {
      try {
        await job.cancel();
      } on Object {
        // Cancellation is best effort.
      }
      throw SubtitleExtractionTimedOut('Subtitle extraction timed out');
    }
  }

  Future<void> _ensureSourceReadable(MediaFileIdentity source) async {
    if (source.path.startsWith('content://')) return;
    final path =
        source.path.startsWith('file://')
            ? Uri.parse(source.path).toFilePath()
            : source.path;
    if (!await File(path).exists()) {
      throw SubtitleSourceUnreadable('Subtitle source file does not exist');
    }
  }
}

class _InFlightExtraction {
  final Completer<SubtitleExtractionResult> result =
      Completer<SubtitleExtractionResult>();
  final Completer<void> cancellation = Completer<void>();
  FfmpegJob? job;
  bool cancelRequested = false;
}
