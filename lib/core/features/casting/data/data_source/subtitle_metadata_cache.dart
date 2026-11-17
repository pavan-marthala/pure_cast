import 'dart:convert' as convert;
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import 'subtitle_extraction_service.dart';

/// Cache entry for FFprobe subtitle inspection results.
///
/// Stores subtitle stream metadata alongside file identity information
/// so that repeated inspection of the same media can reuse cached results
/// instead of re-running FFprobe.
class SubtitleMetadataCacheEntry {
  final String filePath;
  final int fileSize;
  final DateTime lastModified;
  final List<SubtitleStreamInfo> streams;
  final DateTime probedAt;

  const SubtitleMetadataCacheEntry({
    required this.filePath,
    required this.fileSize,
    required this.lastModified,
    required this.streams,
    required this.probedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileSize': fileSize,
      'lastModified': lastModified.toIso8601String(),
      'streams': streams.map((s) => _streamToJson(s)).toList(),
      'probedAt': probedAt.toIso8601String(),
    };
  }

  static SubtitleMetadataCacheEntry fromJson(Map<String, dynamic> json) {
    return SubtitleMetadataCacheEntry(
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      lastModified: DateTime.parse(json['lastModified'] as String),
      streams: (json['streams'] as List)
          .map((s) => _streamFromJson(s as Map<String, dynamic>))
          .toList(),
      probedAt: DateTime.parse(json['probedAt'] as String),
    );
  }

  static Map<String, dynamic> _streamToJson(SubtitleStreamInfo s) {
    return {
      'streamIndex': s.streamIndex,
      'trackIndex': s.trackIndex,
      'codecName': s.codecName,
      'language': s.language,
      'title': s.title,
      'isImageBased': s.isImageBased,
    };
  }

  static SubtitleStreamInfo _streamFromJson(Map<String, dynamic> json) {
    return SubtitleStreamInfo(
      streamIndex: json['streamIndex'] as int,
      trackIndex: json['trackIndex'] as int,
      codecName: json['codecName'] as String,
      language: json['language'] as String?,
      title: json['title'] as String?,
      isImageBased: json['isImageBased'] as bool,
    );
  }

  /// Returns true if the cache entry is still valid (file unchanged).
  bool isValid(int currentFileSize, DateTime currentLastModified) {
    return fileSize == currentFileSize && lastModified == currentLastModified;
  }
}

/// Persistent cache for FFprobe subtitle inspection results.
///
/// Stores subtitle stream metadata per media file so that repeated
/// inspection of the same media reuses cached results instead of
/// re-running FFprobe.
///
/// Cache validity is determined by file size and last modified timestamp.
/// If either changes, the cache entry is considered stale and FFprobe
/// is re-run.
///
/// Files are stored as individual JSON files in the app documents directory
/// under `pure_cast_subtitle_metadata/`, keyed by a hash of the file path.
@lazySingleton
class SubtitleMetadataCache {
  Directory? _cacheDir;
  bool _disposed = false;
  final Future<Directory> Function()? directoryOverride;

  /// Creates the cache.
  ///
  /// [directoryOverride] is for tests; production callers use the app
  /// documents directory.
  SubtitleMetadataCache({this.directoryOverride});

  /// The cache directory path, without creating it.
  Future<Directory> _resolveCacheDir() async {
    final override = directoryOverride;
    if (override != null) return override();
    final baseDir = await getApplicationDocumentsDirectory();
    return Directory('${baseDir.path}/pure_cast_subtitle_metadata');
  }

  /// Ensures the cache directory exists.
  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final dir = await _resolveCacheDir();
    _cacheDir = dir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// The cache directory, or null when it does not exist yet.
  Future<Directory?> _existingCacheDir() async {
    if (_cacheDir != null) {
      return await _cacheDir!.exists() ? _cacheDir : null;
    }
    final dir = await _resolveCacheDir();
    if (!await dir.exists()) return null;
    _cacheDir = dir;
    return dir;
  }

  /// Generates a cache key from the file path.
  String _cacheKey(String filePath) {
    // Use a simple hash of the path for the filename
    final bytes = convert.utf8.encode(filePath);
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash) + bytes[i];
      hash = hash & hash; // Convert to 32-bit integer
    }
    return '${hash.abs().toRadixString(16)}.json';
  }

  /// Reads cached subtitle metadata for [filePath].
  ///
  /// Returns null if no cache entry exists, or if the cached entry is
  /// stale (file size or last modified timestamp changed).
  Future<List<SubtitleStreamInfo>?> getCachedSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
  }) async {
    if (_disposed) return null;

    final dir = await _getCacheDir();
    final key = _cacheKey(filePath);
    final cacheFile = File('${dir.path}/$key');

    if (!await cacheFile.exists()) return null;

    try {
      final json = await cacheFile.readAsString();
      final entry = SubtitleMetadataCacheEntry.fromJson(
        convert.jsonDecode(json) as Map<String, dynamic>,
      );

      if (!entry.isValid(fileSize, lastModified)) {
        // Cache entry is stale — remove it
        await cacheFile.delete();
        return null;
      }

      return entry.streams;
    } catch (_) {
      return null;
    }
  }

  /// Caches subtitle inspection results for [filePath].
  Future<void> cacheSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
    required List<SubtitleStreamInfo> streams,
  }) async {
    if (_disposed) return;

    final dir = await _getCacheDir();
    final key = _cacheKey(filePath);
    final cacheFile = File('${dir.path}/$key');

    final entry = SubtitleMetadataCacheEntry(
      filePath: filePath,
      fileSize: fileSize,
      lastModified: lastModified,
      streams: streams,
      probedAt: DateTime.now(),
    );

    await cacheFile.writeAsString(convert.jsonEncode(entry.toJson()));
  }

  /// Removes the cache entry for [filePath], if any.
  Future<void> removeCache(String filePath) async {
    if (_disposed) return;

    final dir = await _getCacheDir();
    final key = _cacheKey(filePath);
    final cacheFile = File('${dir.path}/$key');

    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }
  }

  static final RegExp _entryFileNamePattern = RegExp(r'^[0-9a-f]+\.json$');

  /// Deletes cache entries probed longer than [maxAge] ago.
  ///
  /// Only files named like this cache's own entries are considered, and a
  /// missing directory is a no-op. The entry's `probedAt` is preferred; when
  /// the file cannot be read or parsed, its modification time is used instead.
  /// Foreign files and subdirectories are ignored. Returns the number of
  /// deleted entries and never throws.
  Future<int> removeOlderThan(Duration maxAge, {DateTime? now}) async {
    if (_disposed) return 0;
    final reference = now ?? DateTime.now();
    var deleted = 0;

    try {
      final dir = await _existingCacheDir();
      if (dir == null) return 0;

      for (final entity in await dir.list().toList()) {
        if (entity is! File) continue;
        if (!_entryFileNamePattern.hasMatch(entity.uri.pathSegments.last)) {
          continue;
        }

        final probedAt = await _probedAtOrModified(entity);
        if (probedAt == null) continue;
        if (reference.difference(probedAt) <= maxAge) continue;

        try {
          await entity.delete();
          deleted++;
        } catch (_) {
          // A file that cannot be deleted is left for the next run.
        }
      }
    } catch (_) {
      // Maintenance must never throw.
    }

    return deleted;
  }

  /// The entry's [SubtitleMetadataCacheEntry.probedAt], or the file's
  /// modification time when the entry cannot be read or parsed.
  Future<DateTime?> _probedAtOrModified(File file) async {
    try {
      final json = await file.readAsString();
      final entry = SubtitleMetadataCacheEntry.fromJson(
        convert.jsonDecode(json) as Map<String, dynamic>,
      );
      return entry.probedAt;
    } catch (_) {
      try {
        return await file.lastModified();
      } catch (_) {
        return null;
      }
    }
  }

  /// Removes all cache entries whose source media file no longer exists.
  ///
  /// Call this periodically to clean up orphaned cache files.
  Future<void> cleanupOrphanedFiles(List<String> activeMediaPaths) async {
    if (_disposed) return;

    final dir = await _getCacheDir();
    if (!await dir.exists()) return;

    final files = await dir.list().toList();
    for (final file in files) {
      if (file is! File) continue;

      try {
        final json = await file.readAsString();
        final entry = SubtitleMetadataCacheEntry.fromJson(
          convert.jsonDecode(json) as Map<String, dynamic>,
        );

        // If the cached file path is not in the active list, delete it
        if (!activeMediaPaths.contains(entry.filePath)) {
          await file.delete();
        }
      } catch (_) {
        // If we can't parse the file, delete it
        await file.delete();
      }
    }
  }

  /// Returns the total size of all cached metadata files in bytes.
  Future<int> getCacheSize() async {
    if (_disposed) return 0;

    final dir = await _getCacheDir();
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

  /// Removes all cached metadata entries.
  Future<void> clearCache() async {
    if (_disposed) return;

    final dir = await _getCacheDir();
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

  /// Disposes the cache.
  Future<void> dispose() async {
    _disposed = true;
    _cacheDir = null;
  }
}
