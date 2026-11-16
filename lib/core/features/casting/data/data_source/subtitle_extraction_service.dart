import 'dart:io';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import 'subtitle_metadata_cache.dart';

/// Information about a subtitle stream discovered by FFprobe.
class SubtitleStreamInfo {
  /// Absolute stream index in the container (used with -map 0:N).
  final int streamIndex;

  /// Relative subtitle track index (0-based among subtitle streams only).
  final int trackIndex;

  /// FFmpeg codec name (e.g., subrip, webvtt, ass, ssa, dvd_subtitle, hdmv_pgs_subtitle).
  final String codecName;

  /// ISO 639 language code, when available.
  final String? language;

  /// Human-readable title from stream metadata, when available.
  final String? title;

  /// True if the subtitle is image-based (PGS, VobSub/DVB).
  final bool isImageBased;

  SubtitleStreamInfo({
    required this.streamIndex,
    required this.trackIndex,
    required this.codecName,
    this.language,
    this.title,
    required this.isImageBased,
  });

  /// Human-readable label for UI display (e.g., "English (SRT)").
  String get displayLabel {
    final lang = (language?.isNotEmpty == true) ? language!.toUpperCase() : 'Unknown';
    final fmt = codecName.toUpperCase();
    return '$lang ($fmt)';
  }

  SubtitleStreamInfo copyWith({
    int? streamIndex,
    int? trackIndex,
    String? codecName,
    String? language,
    String? title,
    bool? isImageBased,
  }) {
    return SubtitleStreamInfo(
      streamIndex: streamIndex ?? this.streamIndex,
      trackIndex: trackIndex ?? this.trackIndex,
      codecName: codecName ?? this.codecName,
      language: language ?? this.language,
      title: title ?? this.title,
      isImageBased: isImageBased ?? this.isImageBased,
    );
  }
}

/// Result of probing a video file for subtitle streams.
class SubtitleProbeResult {
  final List<SubtitleStreamInfo> streams;

  const SubtitleProbeResult(this.streams);

  bool get hasSubtitles => streams.isNotEmpty;
}

/// Result of extracting a single subtitle track.
class SubtitleExtractionResult {
  final SubtitleStreamInfo stream;
  final String? outputPath;
  final SubtitleExtractionError? error;

  const SubtitleExtractionResult._({
    required this.stream,
    this.outputPath,
    this.error,
  });

  const SubtitleExtractionResult.success(SubtitleStreamInfo stream, String outputPath)
      : this._(stream: stream, outputPath: outputPath, error: null);

  const SubtitleExtractionResult.failure(SubtitleStreamInfo stream, SubtitleExtractionError error)
      : this._(stream: stream, outputPath: null, error: error);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// Error information for a failed subtitle extraction.
class SubtitleExtractionError {
  final String message;
  final String? ffmpegLogs;
  final int? returnCode;

  const SubtitleExtractionError({
    required this.message,
    this.ffmpegLogs,
    this.returnCode,
  });
}

/// Result of extracting all subtitle tracks from a video.
class SubtitleBatchExtractionResult {
  final List<SubtitleExtractionResult> results;
  final bool cancelled;

  const SubtitleBatchExtractionResult({
    required this.results,
    this.cancelled = false,
  });

  int get successCount => results.where((r) => r.isSuccess).length;
  int get failureCount => results.where((r) => r.isFailure).length;
  bool get allSucceeded => results.isNotEmpty && results.every((r) => r.isSuccess);
  bool get allFailed => results.isNotEmpty && results.every((r) => r.isFailure);
  bool get partialSuccess => results.isNotEmpty && successCount > 0 && failureCount > 0;
}

/// Service for detecting embedded subtitle streams and extracting them using
/// the `dart_cast` package.
@lazySingleton
class SubtitleExtractionService {
  final SubtitleMetadataCache _metadataCache;
  final dart_cast.MediaProber _prober;
  final dart_cast.FfmpegRunner _runner;
  final Future<Directory> Function() _cacheDirectory;

  Future<dart_cast.SubtitleCache>? _cacheFuture;
  Future<dart_cast.SubtitleExtractor>? _extractorFuture;
  bool _disposed = false;

  SubtitleExtractionService(this._metadataCache)
    : _prober = const dart_cast.FfprobeMediaProber(),
      _runner = const dart_cast.FFmpegKitRunner(),
      _cacheDirectory = _defaultCacheDirectory;

  /// Creates a service with injected dependencies.
  @visibleForTesting
  SubtitleExtractionService.withDependencies({
    required SubtitleMetadataCache metadataCache,
    required dart_cast.MediaProber prober,
    required dart_cast.FfmpegRunner runner,
    required Future<Directory> Function() cacheDirectory,
  }) : this._(metadataCache, prober, runner, cacheDirectory);

  SubtitleExtractionService._(
    this._metadataCache,
    this._prober,
    this._runner,
    this._cacheDirectory,
  );

  static Future<Directory> _defaultCacheDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${baseDir.path}/pure_cast_subtitle_cache_v2');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<dart_cast.SubtitleCache> get _cache =>
      _cacheFuture ??= _createCache();

  Future<dart_cast.SubtitleCache> _createCache() async {
    return dart_cast.SubtitleCache(directory: await _cacheDirectory());
  }

  Future<dart_cast.SubtitleExtractor> get _extractor =>
      _extractorFuture ??= _createExtractor();

  Future<dart_cast.SubtitleExtractor> _createExtractor() async {
    return dart_cast.SubtitleExtractor(runner: _runner, cache: await _cache);
  }

  Future<SubtitleProbeResult> probeAndCacheSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
  }) async {
    if (_disposed) {
      return const SubtitleProbeResult([]);
    }

    final cached = await _metadataCache.getCachedSubtitles(
      filePath: filePath,
      fileSize: fileSize,
      lastModified: lastModified,
    );
    if (cached != null && cached.isNotEmpty) {
      return SubtitleProbeResult(cached);
    }

    final probeResult = await probeSubtitleStreams(filePath);

    if (probeResult.hasSubtitles) {
      await _metadataCache.cacheSubtitles(
        filePath: filePath,
        fileSize: fileSize,
        lastModified: lastModified,
        streams: probeResult.streams,
      );
    }

    return probeResult;
  }

  Future<SubtitleProbeResult> probeSubtitleStreams(String filePath) async {
    if (_disposed) {
      return const SubtitleProbeResult([]);
    }

    final String input;
    try {
      input = await _runner.resolveInput(filePath);
    } catch (_) {
      return const SubtitleProbeResult([]);
    }

    if (filePath.startsWith('content://')) {
      if (input == filePath) {
        return const SubtitleProbeResult([]);
      }
    } else if (!await _sourceExists(filePath)) {
      return const SubtitleProbeResult([]);
    }

    try {
      final probe = await _prober.probe(
        input,
        timeout: const Duration(seconds: 30),
      );
      return SubtitleProbeResult([
        for (final s in probe.subtitles)
          SubtitleStreamInfo(
            streamIndex: s.index,
            trackIndex: s.trackIndex,
            codecName: s.codec.toLowerCase(),
            language: s.language,
            title: s.title,
            isImageBased: s.isImageBased,
          ),
      ]);
    } catch (_) {
      return const SubtitleProbeResult([]);
    }
  }

  Future<bool> _sourceExists(String path) {
    final clean = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
    return File(clean).exists();
  }

  Future<dart_cast.MediaFileIdentity?> _identityFor(String sourcePath) async {
    if (sourcePath.startsWith('content://')) {
      // content:// sources are not stat-able, so their cache entries are never
      // invalidated by source changes. Known limitation: the UI only reaches
      // extraction for plain local files today.
      return dart_cast.MediaFileIdentity(
        path: sourcePath,
        sizeBytes: 0,
        modified: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    final clean = sourcePath.startsWith('file://')
        ? Uri.parse(sourcePath).toFilePath()
        : sourcePath;
    final file = File(clean);
    if (!await file.exists()) return null;
    final stat = await file.stat();
    return dart_cast.MediaFileIdentity(
      path: clean,
      sizeBytes: stat.size,
      modified: stat.modified,
    );
  }

  dart_cast.SubtitleStream _toPackageStream(SubtitleStreamInfo stream) {
    return dart_cast.SubtitleStream(
      index: stream.streamIndex,
      trackIndex: stream.trackIndex,
      codec: stream.codecName,
      language: stream.language,
      title: stream.title,
      isImageBased: stream.isImageBased,
    );
  }

  Future<SubtitleExtractionResult> extractSubtitle({
    required String sourcePath,
    required SubtitleStreamInfo stream,
  }) async {
    if (_disposed) {
      return SubtitleExtractionResult.failure(
          stream, const SubtitleExtractionError(message: 'Service disposed'));
    }

    try {
      final identity = await _identityFor(sourcePath);
      if (identity == null) {
        return SubtitleExtractionResult.failure(
            stream, const SubtitleExtractionError(message: 'Cannot resolve source'));
      }
      final extractor = await _extractor;
      final result = await extractor.extract(
        source: identity,
        track: _toPackageStream(stream),
      );
      return SubtitleExtractionResult.success(stream, result.file.path);
    } on dart_cast.MediaTrackException catch (error) {
      return SubtitleExtractionResult.failure(stream, _errorFor(error));
    } catch (e) {
      return SubtitleExtractionResult.failure(
          stream, SubtitleExtractionError(message: 'Exception: $e'));
    }
  }

  Future<SubtitleBatchExtractionResult> extractAllSubtitles({
    required String sourcePath,
    void Function(SubtitleExtractionResult)? onProgress,
  }) async {
    if (_disposed) {
      return const SubtitleBatchExtractionResult(results: [], cancelled: true);
    }

    final probeResult = await probeSubtitleStreams(sourcePath);

    if (!probeResult.hasSubtitles) {
      return const SubtitleBatchExtractionResult(results: []);
    }

    final results = <SubtitleExtractionResult>[];

    for (final stream in probeResult.streams) {
      final result = await extractSubtitle(sourcePath: sourcePath, stream: stream);
      results.add(result);
      onProgress?.call(result);
    }

    return SubtitleBatchExtractionResult(results: results);
  }

  Future<int> getExtractionCacheSize() async {
    if (_disposed) return 0;
    final cache = await _cache;
    final stats = await cache.stats();
    return stats.totalBytes;
  }

  Future<void> clearExtractionCache() async {
    if (_disposed) return;
    final cache = await _cache;
    final extractor = await _extractor;
    await cache.clear(protectedPaths: extractor.inFlightPaths);
  }

  /// Deletes expired and over-limit cache files, keeping in-flight extractions.
  ///
  /// Not called by the app yet; Stage 6 wires it at startup.
  Future<dart_cast.SubtitleCacheCleanupResult> cleanupExtractionCache() async {
    final cache = await _cache;
    final extractor = await _extractor;
    return cache.cleanup(protectedPaths: extractor.inFlightPaths);
  }

  /// Extracts a cast-ready WebVTT subtitle for a stream.
  ///
  /// Produces a `.vtt` file usable by the Default Media Receiver.
  /// Image-based codecs (PGS, VobSub, DVB) are not convertible and fail.
  Future<SubtitleExtractionResult> extractCastSubtitle({
    required String sourcePath,
    required SubtitleStreamInfo stream,
  }) async {
    if (_disposed) {
      return SubtitleExtractionResult.failure(
          stream, const SubtitleExtractionError(message: 'Service disposed'));
    }
    if (stream.isImageBased) {
      return SubtitleExtractionResult.failure(
          stream,
          const SubtitleExtractionError(
              message: 'Image-based subtitles can\'t be cast'));
    }

    try {
      final identity = await _identityFor(sourcePath);
      if (identity == null) {
        return SubtitleExtractionResult.failure(
            stream, const SubtitleExtractionError(message: 'Cannot resolve source'));
      }
      final extractor = await _extractor;
      final result = await extractor.extract(
        source: identity,
        track: _toPackageStream(stream),
        format: dart_cast.SubtitleOutputFormat.webVtt,
      );
      return SubtitleExtractionResult.success(stream, result.file.path);
    } on dart_cast.MediaTrackException catch (error) {
      return SubtitleExtractionResult.failure(stream, _errorFor(error));
    } catch (e) {
      return SubtitleExtractionResult.failure(
          stream, SubtitleExtractionError(message: 'Exception: $e'));
    }
  }

  /// Maps a package extraction failure to the app's existing messages.
  SubtitleExtractionError _errorFor(dart_cast.MediaTrackException error) {
    return switch (error) {
      dart_cast.SubtitleSourceUnreadable() =>
        const SubtitleExtractionError(message: 'Cannot resolve source'),
      dart_cast.SubtitleUnsupportedCodec() =>
        const SubtitleExtractionError(
            message: 'Image-based subtitles can\'t be cast'),
      dart_cast.SubtitleFfmpegFailed(:final returnCode, :final logs) =>
        SubtitleExtractionError(
          message: 'FFmpeg failed',
          ffmpegLogs: logs,
          returnCode: returnCode,
        ),
      dart_cast.SubtitleExtractionCancelled() =>
        const SubtitleExtractionError(message: 'Cancelled'),
      dart_cast.SubtitleExtractionTimedOut() =>
        const SubtitleExtractionError(message: 'Timed out'),
      dart_cast.SubtitleEmptyOutput() =>
        const SubtitleExtractionError(message: 'Empty output'),
      dart_cast.SubtitleCacheFailure() =>
        const SubtitleExtractionError(message: 'Cache error'),
    };
  }

  Future<void> dispose() async {
    _disposed = true;
    final extractorFuture = _extractorFuture;
    if (extractorFuture != null) {
      try {
        await (await extractorFuture).cancelAll();
      } catch (_) {
        // Disposal must not throw.
      }
    }
    await _metadataCache.dispose();
  }
}
