import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'cast_exceptions.dart';

/// Final cache file names: 20 hex hash chars, stream index, extension.
final RegExp _finalNamePattern = RegExp(r'^[0-9a-f]{20}_\d+\.[a-z0-9]{1,8}$');

/// In-flight temp file names: a final name plus `.part.<suffix>.<ext>`.
///
/// The trailing extension is the real output extension so FFmpeg can pick a
/// muxer from the temp file name.
final RegExp _partNamePattern = RegExp(
  r'^[0-9a-f]{20}_\d+\.[a-z0-9]{1,8}\.part\.[0-9_]+\.[a-z0-9]{1,8}$',
);

/// Lowercase extension rule used by [SubtitleCacheKey].
final RegExp _extensionPattern = RegExp(r'^[a-z0-9]{1,8}$');

/// Identity of the source video file that a cached subtitle belongs to.
///
/// Two files at the same [path] with different [sizeBytes] or [modified] are
/// different identities, so replacing a video invalidates its cached
/// subtitles without any explicit eviction.
class MediaFileIdentity {
  /// Absolute or app-provided path of the source video.
  final String path;

  /// Size of the source video in bytes.
  final int sizeBytes;

  /// Last modification time of the source video.
  final DateTime modified;

  /// Creates an identity from already-known file metadata.
  const MediaFileIdentity({
    required this.path,
    required this.sizeBytes,
    required this.modified,
  });

  /// Reads [file]'s size and modification time and returns its identity.
  ///
  /// Throws [FileSystemException] when the file cannot be read.
  static Future<MediaFileIdentity> fromFile(File file) async {
    final stat = await file.stat();
    return MediaFileIdentity(
      path: file.path,
      sizeBytes: stat.size,
      modified: stat.modified,
    );
  }

  /// Two identities are equal when path, size and modification time match.
  @override
  bool operator ==(Object other) =>
      other is MediaFileIdentity &&
      other.path == path &&
      other.sizeBytes == sizeBytes &&
      other.modified == modified;

  /// Hashes [path], [sizeBytes] and [modified].
  @override
  int get hashCode => Object.hash(path, sizeBytes, modified);
}

/// Cache key for one subtitle stream of one source video.
///
/// [fileName] is `<20 hex chars>_<streamIndex>.<extension>`, where the hash is
/// the first 20 hex characters of the SHA-1 of
/// `path|sizeBytes|modifiedMillisecondsSinceEpoch`.
class SubtitleCacheKey {
  /// Identity of the source video file.
  final MediaFileIdentity source;

  /// Absolute container stream index (the index used with `-map 0:N`).
  final int streamIndex;

  /// Lowercase output extension without a dot, for example `srt` or `sup`.
  final String extension;

  /// Creates a key and validates [streamIndex] and [extension].
  ///
  /// Throws [ArgumentError] when [streamIndex] is negative or [extension] is
  /// not 1–8 lowercase alphanumeric characters.
  SubtitleCacheKey({
    required this.source,
    required this.streamIndex,
    required this.extension,
  }) {
    if (streamIndex < 0) {
      throw ArgumentError.value(
        streamIndex,
        'streamIndex',
        'must be zero or greater',
      );
    }
    if (!_extensionPattern.hasMatch(extension)) {
      throw ArgumentError.value(
        extension,
        'extension',
        r'must be 1-8 lowercase letters or digits',
      );
    }
  }

  /// File name this key maps to inside the cache directory.
  String get fileName {
    final identity =
        '${source.path}|${source.sizeBytes}|'
        '${source.modified.millisecondsSinceEpoch}';
    final hash = sha1
        .convert(utf8.encode(identity))
        .toString()
        .substring(0, 20);
    return '${hash}_$streamIndex.$extension';
  }
}

/// Age and size limits applied by [SubtitleCache.cleanup].
class SubtitleCacheLimits {
  /// Maximum age of an unused cache entry before cleanup deletes it.
  final Duration maxAge;

  /// Maximum combined size of cache entries before cleanup deletes the
  /// oldest-used entries.
  final int maxTotalBytes;

  /// Minimum age of a `.part` temp file before cleanup may delete it.
  ///
  /// This keeps temp files that another extraction is still writing.
  final Duration orphanPartAge;

  /// Creates limits.
  ///
  /// [maxTotalBytes] is asserted to be positive. Dart cannot evaluate
  /// [Duration] comparisons in a `const` constructor assert, so
  /// [SubtitleCache] validates [maxAge] and [orphanPartAge] when it is
  /// constructed.
  const SubtitleCacheLimits({
    this.maxAge = const Duration(days: 7),
    this.maxTotalBytes = 512 * 1024 * 1024,
    this.orphanPartAge = const Duration(hours: 1),
  }) : assert(maxTotalBytes > 0, 'maxTotalBytes must be positive');
}

/// A cached subtitle file returned by [SubtitleCache.lookup] and
/// [SubtitleCache.commit].
class SubtitleCacheEntry {
  /// The cached subtitle file.
  final File file;

  /// Size of [file] in bytes.
  final int sizeBytes;

  /// When this entry was last used or written.
  final DateTime lastUsed;

  /// Creates an entry.
  const SubtitleCacheEntry({
    required this.file,
    required this.sizeBytes,
    required this.lastUsed,
  });
}

/// Aggregate information about the final cache files in a [SubtitleCache].
class SubtitleCacheStats {
  /// Number of final cache files.
  final int fileCount;

  /// Combined size of the final cache files, in bytes.
  final int totalBytes;

  /// Modification time of the least recently used final cache file, or null
  /// when the cache is empty.
  final DateTime? oldest;

  /// Creates stats.
  const SubtitleCacheStats({
    required this.fileCount,
    required this.totalBytes,
    this.oldest,
  });
}

/// Outcome of [SubtitleCache.cleanup] or [SubtitleCache.clear].
class SubtitleCacheCleanupResult {
  /// Number of files deleted by the operation.
  final int deletedFiles;

  /// Combined size of the deleted files, in bytes.
  final int deletedBytes;

  /// Number of final cache files that remain.
  final int remainingFiles;

  /// Combined size of the remaining final cache files, in bytes.
  final int remainingBytes;

  /// Creates a cleanup result.
  const SubtitleCacheCleanupResult({
    required this.deletedFiles,
    required this.deletedBytes,
    required this.remainingFiles,
    required this.remainingBytes,
  });
}

/// File-backed cache for extracted subtitle tracks.
///
/// The cache directory is injected by the caller; this class never resolves
/// platform directories itself and never logs file paths. It only ever
/// considers files whose names match its own patterns, so unrelated files that
/// share the directory are left untouched.
class SubtitleCache {
  /// Directory that holds all cache files.
  final Directory directory;

  /// Age and size limits used by [cleanup].
  final SubtitleCacheLimits limits;

  int _partCounter = 0;

  /// Creates a cache rooted at [directory].
  ///
  /// The directory is created lazily by [partFileFor] and [commit]. All
  /// durations in [limits] must be positive; this constructor throws
  /// [ArgumentError] otherwise.
  SubtitleCache({
    required this.directory,
    this.limits = const SubtitleCacheLimits(),
  }) {
    if (limits.maxAge <= Duration.zero) {
      throw ArgumentError.value(limits.maxAge, 'limits.maxAge');
    }
    if (limits.orphanPartAge <= Duration.zero) {
      throw ArgumentError.value(limits.orphanPartAge, 'limits.orphanPartAge');
    }
    if (limits.maxTotalBytes <= 0) {
      throw ArgumentError.value(limits.maxTotalBytes, 'limits.maxTotalBytes');
    }
  }

  /// Returns the cached file for [key], or null when it is absent or empty.
  ///
  /// A hit refreshes the file's modification time so frequently used tracks
  /// are not evicted by [cleanup]. The refresh is best effort: a cache hit is
  /// still returned when the timestamp cannot be updated. A missing cache
  /// directory is a miss, not an error.
  Future<SubtitleCacheEntry?> lookup(SubtitleCacheKey key) async {
    final file = File(_pathForName(key.fileName));
    try {
      if (!await file.exists()) return null;
      final length = await file.length();
      if (length <= 0) return null;
      final now = DateTime.now();
      try {
        await file.setLastModified(now);
      } on FileSystemException {
        // A timestamp refresh is an optimisation; the entry is still valid.
      }
      return SubtitleCacheEntry(file: file, sizeBytes: length, lastUsed: now);
    } on FileSystemException {
      return null;
    }
  }

  /// Returns a new, unique temp file path for writing [key]'s output.
  ///
  /// The returned file is inside [directory] and named
  /// `<fileName>.part.<suffix>.<extension>`. The trailing extension is the
  /// real output extension so FFmpeg can select a muxer from the temp name.
  /// The suffix makes concurrent extractions of the same key use different
  /// temp files. The directory is created when needed, but the temp file
  /// itself is not created.
  Future<File> partFileFor(SubtitleCacheKey key) async {
    try {
      await directory.create(recursive: true);
    } on FileSystemException catch (e) {
      throw SubtitleCacheException('Cannot create subtitle cache directory', e);
    }
    final suffix = '${DateTime.now().microsecondsSinceEpoch}_${_partCounter++}';
    return File(_pathForName('${key.fileName}.part.$suffix.${key.extension}'));
  }

  /// Moves a finished [partFile] to its final name for [key].
  ///
  /// [partFile] must have a cache temp-file name, exist, be non-empty and be
  /// inside [directory]; otherwise a [SubtitleCacheException] is thrown and an
  /// empty part file is deleted. Rejecting other names means a caller cannot
  /// rename a final cache file (or any foreign file) into place.
  /// The rename happens within the cache directory, so it is atomic, and any
  /// existing final file for [key] is replaced.
  Future<SubtitleCacheEntry> commit(SubtitleCacheKey key, File partFile) async {
    final directoryPath = _normalizePath(directory.path);
    final partPath = _normalizePath(partFile.path);
    if (!_isInside(directoryPath, partPath)) {
      throw SubtitleCacheException(
        'Subtitle part file is outside the cache directory',
      );
    }
    if (!_partNamePattern.hasMatch(_baseName(partFile.path))) {
      throw SubtitleCacheException(
        'Subtitle part file name is not a cache temp name',
      );
    }

    final int length;
    try {
      if (!await partFile.exists()) {
        throw SubtitleCacheException('Subtitle part file does not exist');
      }
      length = await partFile.length();
    } on SubtitleCacheException {
      rethrow;
    } on FileSystemException catch (e) {
      throw SubtitleCacheException('Cannot read subtitle part file', e);
    }

    if (length <= 0) {
      try {
        await partFile.delete();
      } on FileSystemException {
        // Best effort: the empty part file is unusable either way.
      }
      throw SubtitleCacheException('Subtitle output is empty');
    }

    final target = File(_pathForName(key.fileName));
    final now = DateTime.now();
    try {
      await directory.create(recursive: true);
      await partFile.rename(target.path);
    } on FileSystemException catch (e) {
      throw SubtitleCacheException('Cannot commit subtitle cache entry', e);
    }
    try {
      await target.setLastModified(now);
    } on FileSystemException {
      // The entry is still valid; the commit timestamp is best effort.
    }
    return SubtitleCacheEntry(file: target, sizeBytes: length, lastUsed: now);
  }

  /// Deletes [partFile] if it exists. Never throws.
  Future<void> discard(File partFile) async {
    try {
      if (await partFile.exists()) {
        await partFile.delete();
      }
    } on FileSystemException {
      // Discarding a temp file is best effort.
    }
  }

  /// Counts and sums the final cache files in [directory].
  ///
  /// Only files named like cache entries are considered; `.part` temp files,
  /// foreign files and subdirectories are ignored. A missing directory yields
  /// empty stats.
  Future<SubtitleCacheStats> stats() async {
    final files = await _finalFiles();
    var totalBytes = 0;
    DateTime? oldest;
    for (final file in files) {
      totalBytes += file.stat.size;
      final modified = file.stat.modified;
      if (oldest == null || modified.isBefore(oldest)) {
        oldest = modified;
      }
    }
    return SubtitleCacheStats(
      fileCount: files.length,
      totalBytes: totalBytes,
      oldest: oldest,
    );
  }

  /// Removes orphan temp files, expired entries and excess bytes.
  ///
  /// Order of operations:
  /// 1. `.part` files older than [SubtitleCacheLimits.orphanPartAge] are
  ///    deleted.
  /// 2. Final files unused for longer than [SubtitleCacheLimits.maxAge] are
  ///    deleted.
  /// 3. While the remaining total exceeds
  ///    [SubtitleCacheLimits.maxTotalBytes], the least recently used final
  ///    files are deleted first.
  ///
  /// [now] is the reference time for age checks (defaults to the current
  /// time). Paths in [protectedPaths] are never deleted, compared as
  /// normalized absolute paths.
  ///
  /// Only files whose names match this cache's patterns are considered;
  /// foreign files and subdirectories are never touched, and a missing
  /// directory is a no-op. A file that fails to delete does not abort the
  /// rest of the cleanup.
  Future<SubtitleCacheCleanupResult> cleanup({
    DateTime? now,
    Set<String> protectedPaths = const {},
  }) async {
    final reference = now ?? DateTime.now();
    final protected = protectedPaths.map(_normalizePath).toSet();
    var deletedFiles = 0;
    var deletedBytes = 0;
    final remaining = <_CacheFile>[];

    for (final entity in await _listCacheCandidates()) {
      final name = _baseName(entity.path);
      final isPart = _partNamePattern.hasMatch(name);
      final isFinal = !isPart && _finalNamePattern.hasMatch(name);
      if (!isPart && !isFinal) continue;

      final path = _normalizePath(entity.path);
      final isProtected = protected.contains(path);
      final stat = await _statFile(entity);
      if (stat == null) continue;

      if (isPart) {
        if (isProtected) continue;
        if (reference.difference(stat.modified) > limits.orphanPartAge) {
          if (await _delete(entity)) {
            deletedFiles++;
            deletedBytes += stat.size;
          }
        }
        continue;
      }

      if (!isProtected && reference.difference(stat.modified) > limits.maxAge) {
        if (await _delete(entity)) {
          deletedFiles++;
          deletedBytes += stat.size;
          continue;
        }
      }
      remaining.add(_CacheFile(entity, stat));
    }

    var totalBytes = remaining.fold<int>(0, (sum, f) => sum + f.stat.size);
    if (totalBytes > limits.maxTotalBytes) {
      remaining.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
      for (final file in remaining) {
        if (totalBytes <= limits.maxTotalBytes) break;
        if (protected.contains(_normalizePath(file.entity.path))) continue;
        if (await _delete(file.entity)) {
          totalBytes -= file.stat.size;
          deletedFiles++;
          deletedBytes += file.stat.size;
        }
      }
    }

    final current = await stats();
    return SubtitleCacheCleanupResult(
      deletedFiles: deletedFiles,
      deletedBytes: deletedBytes,
      remainingFiles: current.fileCount,
      remainingBytes: current.totalBytes,
    );
  }

  /// Deletes every cache file (including `.part` temp files).
  ///
  /// Paths in [protectedPaths] are kept, compared as normalized absolute
  /// paths. Foreign files and subdirectories are never touched, and a missing
  /// directory is a no-op.
  Future<SubtitleCacheCleanupResult> clear({
    Set<String> protectedPaths = const {},
  }) async {
    final protected = protectedPaths.map(_normalizePath).toSet();
    var deletedFiles = 0;
    var deletedBytes = 0;

    for (final entity in await _listCacheCandidates()) {
      final name = _baseName(entity.path);
      if (!_finalNamePattern.hasMatch(name) &&
          !_partNamePattern.hasMatch(name)) {
        continue;
      }
      if (protected.contains(_normalizePath(entity.path))) continue;

      final stat = await _statFile(entity);
      if (stat == null) continue;
      if (await _delete(entity)) {
        deletedFiles++;
        deletedBytes += stat.size;
      }
    }

    final current = await stats();
    return SubtitleCacheCleanupResult(
      deletedFiles: deletedFiles,
      deletedBytes: deletedBytes,
      remainingFiles: current.fileCount,
      remainingBytes: current.totalBytes,
    );
  }

  String _pathForName(String name) {
    final base = directory.path;
    final separator = Platform.pathSeparator;
    return base.endsWith(separator) ? '$base$name' : '$base$separator$name';
  }

  Future<List<File>> _listCacheCandidates() async {
    try {
      if (!await directory.exists()) return const [];
      final entities = await directory.list(followLinks: false).toList();
      return entities.whereType<File>().toList(growable: false);
    } on FileSystemException {
      return const [];
    }
  }

  Future<List<_CacheFile>> _finalFiles() async {
    final result = <_CacheFile>[];
    for (final file in await _listCacheCandidates()) {
      if (!_finalNamePattern.hasMatch(_baseName(file.path))) continue;
      final stat = await _statFile(file);
      if (stat != null) result.add(_CacheFile(file, stat));
    }
    return result;
  }

  Future<FileStat?> _statFile(File file) async {
    try {
      final stat = await file.stat();
      return stat.type == FileSystemEntityType.file ? stat : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<bool> _delete(File file) async {
    try {
      await file.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }
}

class _CacheFile {
  const _CacheFile(this.entity, this.stat);

  final File entity;
  final FileStat stat;
}

String _baseName(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  final index = slash > backslash ? slash : backslash;
  return index == -1 ? path : path.substring(index + 1);
}

String _normalizePath(String path) =>
    Uri.file(File(path).absolute.path).normalizePath().toFilePath();

bool _isInside(String parent, String child) {
  if (child == parent) return true;
  final separator = Platform.pathSeparator;
  final prefix = parent.endsWith(separator) ? parent : '$parent$separator';
  return child.startsWith(prefix);
}
