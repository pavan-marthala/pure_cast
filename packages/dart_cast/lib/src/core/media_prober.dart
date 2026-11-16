import 'cast_exceptions.dart';
import 'ffprobe_runner.dart';
import 'media_probe.dart';

/// Probes media files and returns package-owned [MediaProbe] values.
///
/// Implement this to replace FFprobe in tests. The default production
/// implementation is [FfprobeMediaProber].
abstract interface class MediaProber {
  /// Probes [inputPath] and returns its streams and container information.
  ///
  /// [inputPath] may be an absolute filesystem path or a `file://` URI.
  /// [timeout] bounds the whole probe; on timeout, missing media information
  /// or any FFprobe error a [ProbeFailedException] is thrown.
  Future<MediaProbe> probe(
    String inputPath, {
    Duration timeout = const Duration(seconds: 8),
  });
}

/// Default [MediaProber] backed by an [FfprobeRunner].
class FfprobeMediaProber implements MediaProber {
  /// Creates a prober.
  ///
  /// [runner] defaults to [FFmpegKitFfprobeRunner].
  const FfprobeMediaProber({FfprobeRunner? runner})
    : _runner = runner ?? const FFmpegKitFfprobeRunner();

  final FfprobeRunner _runner;

  @override
  Future<MediaProbe> probe(
    String inputPath, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var input = inputPath;
    if (input.startsWith('file://')) {
      input = Uri.parse(input).toFilePath();
    }
    try {
      final raw = await _runner.probeRaw(input).timeout(timeout);
      if (raw == null) {
        throw ProbeFailedException('Probe failed: no media information');
      }
      return MediaProbe.fromJson(raw);
    } on ProbeFailedException {
      rethrow;
    } catch (e) {
      throw ProbeFailedException('Probe failed: $e', e);
    }
  }
}
