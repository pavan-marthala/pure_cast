import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:path_provider/path_provider.dart';

import 'subtitle_extraction_service.dart';
import 'subtitle_metadata_cache.dart';

/// Startup housekeeping for subtitle state left behind by earlier installs.
///
/// Call [run] after dependency setup and keep it off the startup path with
/// `unawaited`. Every step is independent and swallows its own errors, so a
/// slow or failing step can never block the app or the next step.
class SubtitleMaintenance {
  SubtitleMaintenance({
    required this.metadataCache,
    required this.extractionService,
    Future<Directory> Function()? appSupportDirectory,
    this.legacyDirectoryNames = const [
      'pure_cast_subtitle_cache',
      'pure_cast_subtitles',
    ],
    this.metadataMaxAge = const Duration(days: 30),
  }) : _appSupportDirectory =
           appSupportDirectory ?? getApplicationSupportDirectory;

  final SubtitleMetadataCache metadataCache;
  final SubtitleExtractionService extractionService;
  final Future<Directory> Function() _appSupportDirectory;

  /// Directory names that only earlier app versions used. They are matched as
  /// exact directory names, so the current `..._cache_v2` directory is never
  /// deleted by a prefix match.
  final List<String> legacyDirectoryNames;

  /// Age after which an unused subtitle metadata entry is deleted.
  final Duration metadataMaxAge;

  /// Removes legacy directories, trims the extraction cache and prunes old
  /// metadata entries. Never throws.
  Future<void> run() async {
    final removedDirectories = await _removeLegacyDirectories();

    var removedCacheFiles = 0;
    try {
      removedCacheFiles =
          (await extractionService.cleanupExtractionCache()).deletedFiles;
    } catch (_) {
      // A partially cleaned cache is harmless; keep going.
    }

    var removedMetadataEntries = 0;
    try {
      removedMetadataEntries = await metadataCache.removeOlderThan(
        metadataMaxAge,
      );
    } catch (_) {
      // Metadata pruning must not affect startup.
    }

    CastLogger.debug(
      'Subtitle maintenance: $removedDirectories legacy dir(s), '
      '$removedCacheFiles cache file(s), '
      '$removedMetadataEntries metadata entry(ies) removed',
    );
  }

  Future<int> _removeLegacyDirectories() async {
    var removed = 0;
    for (final name in legacyDirectoryNames) {
      try {
        if (await _removeLegacyDirectory(name)) removed++;
      } catch (_) {
        // One bad path must not skip the remaining directories or steps.
      }
    }
    return removed;
  }

  Future<bool> _removeLegacyDirectory(String name) async {
    final base = await _appSupportDirectory();
    final directory = Directory('${base.path}/$name');
    if (!await directory.exists()) return false;
    await directory.delete(recursive: true);
    return true;
  }
}
