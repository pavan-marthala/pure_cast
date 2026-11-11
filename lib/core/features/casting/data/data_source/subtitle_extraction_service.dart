import 'dart:convert' as convert;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
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

/// Service for detecting embedded subtitle streams and extracting them using FFmpeg/FFprobe.
@lazySingleton
class SubtitleExtractionService {
  static const _imageBasedCodecs = {
    'dvd_subtitle',
    'hdmv_pgs_subtitle',
    'dvb_subtitle',
    'xsub',
  };

  static ({String ext, List<String> codecArgs}) _outputPlan(SubtitleStreamInfo s) {
    switch (s.codecName.toLowerCase()) {
      case 'subrip':
        return (ext: 'srt', codecArgs: ['-c:s', 'copy']);
      case 'webvtt':
        return (ext: 'vtt', codecArgs: ['-c:s', 'copy']);
      case 'ass':
        return (ext: 'ass', codecArgs: ['-c:s', 'copy']);
      case 'ssa':
        return (ext: 'ssa', codecArgs: ['-c:s', 'copy']);
      case 'hdmv_pgs_subtitle':
        return (ext: 'sup', codecArgs: ['-c:s', 'copy']);
      default:
        if (s.isImageBased) {
          return (ext: 'mks', codecArgs: ['-c:s', 'copy']);
        }
        return (ext: 'srt', codecArgs: ['-c:s', 'srt']);
    }
  }

  Directory? _tempDir;
  final Set<String> _activeExtractions = {};
  bool _disposed = false;
  final SubtitleMetadataCache _metadataCache;

  SubtitleExtractionService(this._metadataCache);

  Future<Directory> getTempDir() async {
    if (_tempDir != null) return _tempDir!;
    final baseDir = await getApplicationSupportDirectory();
    final subtitlesDir = Directory('${baseDir.path}/pure_cast_subtitles');
    if (!await subtitlesDir.exists()) {
      await subtitlesDir.create(recursive: true);
    }
    _tempDir = subtitlesDir;
    return subtitlesDir;
  }

  Future<void> clearTempFiles() async {
    final dir = _tempDir;
    if (dir == null) return;
    try {
      final files = await dir.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (_) {}
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

    final input = await _resolveInputPath(filePath);
    if (input == null) {
      return const SubtitleProbeResult([]);
    }

    try {
      final session = await FFprobeKit.getMediaInformation(input);
      final info = session.getMediaInformation();
      if (info == null) {
        return const SubtitleProbeResult([]);
      }

      final result = <SubtitleStreamInfo>[];
      var track = 0;
      for (final s in info.getStreams()) {
        if (s.getType() != 'subtitle') continue;
        final codec = (s.getCodec() ?? 'unknown').toLowerCase();
        final tags = s.getTags() ?? const {};
        result.add(SubtitleStreamInfo(
          streamIndex: s.getIndex() ?? -1,
          trackIndex: track++,
          codecName: codec,
          language: tags['language'] as String?,
          title: tags['title'] as String?,
          isImageBased: _imageBasedCodecs.contains(codec),
        ));
      }
      return SubtitleProbeResult(result);
    } catch (_) {
      return const SubtitleProbeResult([]);
    }
  }

  Future<String?> _resolveInputPath(String path) async {
    if (path.startsWith('content://')) {
      if (!Platform.isAndroid) return null;
      return await FFmpegKitConfig.getSafParameterForRead(path);
    }
    final clean = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
    return await File(clean).exists() ? clean : null;
  }

  String _keyPrefix(String path) =>
      sha1.convert(convert.utf8.encode(path)).toString().substring(0, 16);

  Future<String> _cachePathFor(String sourcePath, SubtitleStreamInfo s) async {
    final dir = await _getExtractionCacheDir();
    final plan = _outputPlan(s);
    return '${dir.path}/${_keyPrefix(sourcePath)}_${s.streamIndex}.${plan.ext}';
  }

  Future<SubtitleExtractionResult> extractSubtitle({
    required String sourcePath,
    required SubtitleStreamInfo stream,
  }) async {
    if (_disposed) {
      return SubtitleExtractionResult.failure(
          stream, const SubtitleExtractionError(message: 'Service disposed'));
    }

    final outPath = await _cachePathFor(sourcePath, stream);
    final outFile = File(outPath);
    if (await outFile.exists() && await outFile.length() > 0) {
      return SubtitleExtractionResult.success(stream, outPath);
    }

    final input = await _resolveInputPath(sourcePath);
    if (input == null) {
      return SubtitleExtractionResult.failure(
          stream, const SubtitleExtractionError(message: 'Cannot resolve source'));
    }

    final key = '$sourcePath:${stream.streamIndex}';
    if (!_activeExtractions.add(key)) {
      return SubtitleExtractionResult.failure(
          stream, const SubtitleExtractionError(message: 'Already in progress'));
    }

    final plan = _outputPlan(stream);
    final tmpPath = '$outPath.part.${plan.ext}';
    try {
      final args = [
        '-y', '-hide_banner', '-nostdin',
        '-i', input,
        '-map', '0:${stream.streamIndex}',
        '-vn', '-an', '-dn',
        ...plan.codecArgs,
        tmpPath,
      ];

      final session = await FFmpegKit.executeWithArguments(args);
      final rc = await session.getReturnCode();

      if (!ReturnCode.isSuccess(rc)) {
        final logs = await session.getAllLogsAsString();
        return SubtitleExtractionResult.failure(
          stream,
          SubtitleExtractionError(
            message: ReturnCode.isCancel(rc) ? 'Cancelled' : 'FFmpeg failed',
            ffmpegLogs: logs,
            returnCode: rc?.getValue(),
          ),
        );
      }

      final tmp = File(tmpPath);
      if (!await tmp.exists() || await tmp.length() == 0) {
        return SubtitleExtractionResult.failure(
            stream, const SubtitleExtractionError(message: 'Empty output'));
      }

      await tmp.rename(outPath);
      return SubtitleExtractionResult.success(stream, outPath);
    } catch (e) {
      return SubtitleExtractionResult.failure(
          stream, SubtitleExtractionError(message: 'Exception: $e'));
    } finally {
      _activeExtractions.remove(key);
      final tmp = File(tmpPath);
      if (await tmp.exists()) await tmp.delete();
    }
  }

  Future<SubtitleExtractionResult> extractSubtitleTrackFromPath({
    required String sourcePath,
    required SubtitleStreamInfo stream,
    required String outputPath,
  }) async {
    return extractSubtitle(sourcePath: sourcePath, stream: stream);
  }

  Future<void> cancelAllExtractions() async {
    await FFmpegKit.cancel();
    _activeExtractions.clear();
  }

  Future<void> cleanupOrphanedCache(List<String> activeMediaPaths) async {
    if (_disposed) return;
    final active = activeMediaPaths.map(_keyPrefix).toSet();
    final dir = await _getExtractionCacheDir();
    if (!await dir.exists()) return;
    await for (final f in dir.list()) {
      if (f is! File) continue;
      final prefix = f.uri.pathSegments.last.split('_').first;
      if (!active.contains(prefix)) await f.delete();
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

  Future<String?> getCachedExtractionPath(
    String sourcePath,
    SubtitleStreamInfo stream,
  ) async {
    final path = await _cachePathFor(sourcePath, stream);
    final f = File(path);
    if (await f.exists() && await f.length() > 0) {
      return path;
    }
    return null;
  }

  Future<Directory> _getExtractionCacheDir() async {
    final baseDir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${baseDir.path}/pure_cast_subtitle_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<int> getExtractionCacheSize() async {
    if (_disposed) return 0;
    final dir = await _getExtractionCacheDir();
    if (!await dir.exists()) return 0;
    final files = await dir.list().toList();
    int total = 0;
    for (final file in files) {
      if (file is File) {
        try {
          total += await file.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> clearExtractionCache() async {
    if (_disposed) return;
    final dir = await _getExtractionCacheDir();
    if (!await dir.exists()) return;
    final files = await dir.list().toList();
    for (final file in files) {
      if (file is File) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _activeExtractions.clear();
    await _metadataCache.dispose();
  }
}
