import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:injectable/injectable.dart';

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

/// Service for detecting embedded subtitle streams in video files using FFprobe.
///
/// Discovers subtitle streams via FFprobe only — does not extract subtitle files.
/// Results are cached per media file using file size and last modified timestamp
/// to avoid repeated FFprobe invocations.
@lazySingleton
class SubtitleExtractionService {
  static const _subtitleCodecNames = {
    'subrip',
    'webvtt',
    'ass',
    'ssa',
    'dvd_subtitle',
    'hdmv_pgs_subtitle',
    'mov_text',
    'dvbsub',
    'xsub',
  };

  static const _imageBasedCodecs = {
    'dvd_subtitle',
    'hdmv_pgs_subtitle',
    'dvbsub',
    'xsub',
  };

  final SubtitleMetadataCache _metadataCache;
  bool _disposed = false;

  SubtitleExtractionService(this._metadataCache);

  /// Probes a video file for embedded subtitle streams using FFprobe.
  ///
  /// Checks the metadata cache first. If a valid cached entry exists (file size
  /// and last modified match), returns cached results without running FFprobe.
  /// Otherwise runs FFprobe and caches the result.
  Future<SubtitleProbeResult> probeAndCacheSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
  }) async {
    if (_disposed) {
      return const SubtitleProbeResult([]);
    }

    // Check cache first
    final cached = await _metadataCache.getCachedSubtitles(
      filePath: filePath,
      fileSize: fileSize,
      lastModified: lastModified,
    );
    if (cached != null && cached.isNotEmpty) {
      return SubtitleProbeResult(cached);
    }

    // Cache miss — run FFprobe
    final probeResult = await probeSubtitleStreams(filePath);

    // Cache the result
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

  /// Probes a video file for embedded subtitle streams using FFprobe.
  ///
  /// Runs FFprobe with `-select_streams s` to inspect subtitle streams only.
  /// Returns an empty result if no subtitles are found or if probing fails.
  Future<SubtitleProbeResult> probeSubtitleStreams(String filePath) async {
    if (_disposed) {
      return const SubtitleProbeResult([]);
    }

    final resolvedPath = await _resolveFilePath(filePath);
    if (resolvedPath == null) {
      return const SubtitleProbeResult([]);
    }

    final command =
        '-hide_banner -v error -select_streams s -show_entries stream=index,codec_name:stream_tags=language,title -of json "$resolvedPath"';

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (returnCode == null || !ReturnCode.isSuccess(returnCode)) {
        return const SubtitleProbeResult([]);
      }

      final output = await session.getOutput();
      if (output == null || output.isEmpty) {
        return const SubtitleProbeResult([]);
      }

      return _parseProbeOutput(output);
    } catch (_) {
      return const SubtitleProbeResult([]);
    }
  }

  /// Parses FFprobe JSON output into [SubtitleStreamInfo] objects.
  SubtitleProbeResult _parseProbeOutput(String jsonOutput) {
    try {
      final data = convert.jsonDecode(jsonOutput) as Map<String, dynamic>;
      final streams = data['streams'] as List?;

      if (streams == null || streams.isEmpty) {
        return const SubtitleProbeResult([]);
      }

      final subtitleStreams = <SubtitleStreamInfo>[];
      int subtitleTrackIndex = 0;

      for (final stream in streams) {
        if (stream is! Map) continue;

        final codecName = (stream['codec_name'] as String?) ?? 'unknown';
        final streamIndex = (stream['index'] as int?) ?? -1;

        // Only process known subtitle codecs
        if (!_subtitleCodecNames.contains(codecName.toLowerCase())) continue;

        final tags = stream['tags'] as Map? ?? {};
        final language = tags['language'] as String?;
        final title = tags['title'] as String?;
        final isImageBased = _imageBasedCodecs.contains(codecName.toLowerCase());

        subtitleStreams.add(
          SubtitleStreamInfo(
            streamIndex: streamIndex,
            trackIndex: subtitleTrackIndex++,
            codecName: codecName,
            language: language,
            title: title,
            isImageBased: isImageBased,
          ),
        );
      }

      return SubtitleProbeResult(subtitleStreams);
    } catch (_) {
      return const SubtitleProbeResult([]);
    }
  }

  /// Resolves a file path for FFmpeg/FFprobe consumption.
  ///
  /// On Android, SAF content:// URIs can be passed directly to FFmpegKit.
  /// On iOS, file:// URIs are stripped to plain paths.
  /// Returns null if the path cannot be resolved.
  Future<String?> _resolveFilePath(String path) async {
    // Android SAF content:// URIs — FFmpegKit supports them directly
    if (path.startsWith('content://')) {
      return path;
    }

    // File:// URIs — strip the scheme
    if (path.startsWith('file://')) {
      return path.substring(7);
    }

    // Regular file paths — use as-is
    final file = File(path);
    if (await file.exists()) {
      return path;
    }

    return null;
  }

  /// Cleans up orphaned cache entries whose source media no longer exists.
  Future<void> cleanupOrphanedCache(List<String> activeMediaPaths) async {
    if (_disposed) return;

    await _metadataCache.cleanupOrphanedFiles(activeMediaPaths);
  }

  /// Disposes the service.
  Future<void> dispose() async {
    _disposed = true;
    await _metadataCache.dispose();
  }
}
