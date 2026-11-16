import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/media_information.dart';

/// Runs FFprobe and returns the raw stream/format map consumed by
/// `MediaProbe.fromJson`.
///
/// Implement this to replace FFmpegKit in tests or to back probing with a
/// different FFprobe integration. The default production implementation is
/// [FFmpegKitFfprobeRunner].
abstract interface class FfprobeRunner {
  /// Probes [input] and returns an FFprobe-shaped JSON map.
  ///
  /// [input] must already be a value FFprobe can open (a filesystem path, a
  /// `file://` path resolved by the caller, or an Android SAF parameter).
  /// Returns null when FFprobe reports no media information.
  Future<Map<String, dynamic>?> probeRaw(String input);
}

/// Default [FfprobeRunner] backed by FFmpegKit's FFprobe.
class FFmpegKitFfprobeRunner implements FfprobeRunner {
  /// Creates a runner that calls [FFprobeKit.getMediaInformation].
  const FFmpegKitFfprobeRunner();

  @override
  Future<Map<String, dynamic>?> probeRaw(String input) async {
    final session = await FFprobeKit.getMediaInformation(input);
    final info = session.getMediaInformation();
    if (info == null) return null;
    return _mediaInfoToJson(info);
  }
}

Map<String, dynamic> _mediaInfoToJson(MediaInformation? info) {
  if (info == null) return const {};
  // Build a minimal JSON map compatible with MediaProbe.fromJson
  final streams = <Map<String, dynamic>>[];
  for (final s in info.getStreams()) {
    final tags = s.getTags();
    // Try to read disposition from getAllProperties if available.
    // FFprobeKit's StreamInformation does not expose a getDisposition()
    // method, but getAllProperties() returns the raw JSON map which may
    // contain a 'disposition' key with 'default' field.
    final allProps = s.getAllProperties();
    final disp =
        (allProps != null && allProps['disposition'] is Map)
            ? (allProps['disposition'] as Map)['default']
            : null;
    final isDefault = disp == 1;
    final profile = allProps != null ? allProps['profile'] as String? : null;
    final channels =
        allProps != null ? (allProps['channels'] as num?)?.toInt() : null;
    streams.add({
      'codec_type': s.getType(),
      'codec_name': s.getCodec(),
      'profile': profile,
      'level': s.getNumberProperty('level'),
      'pix_fmt': s.getStringProperty('pix_fmt'),
      'width': s.getWidth(),
      'height': s.getHeight(),
      'r_frame_rate': s.getAverageFrameRate(),
      'index': s.getIndex(),
      'channels': channels,
      'tags': tags,
      'disposition': {'default': isDefault ? 1 : 0},
    });
  }
  return {
    'format': {'format_name': info.getFormat(), 'duration': info.getDuration()},
    'streams': streams,
  };
}
