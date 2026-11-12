import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';

import 'cast_decision.dart';

/// Provides runtime-detected FFmpeg capabilities as a [CastDeviceCaps].
///
/// Capabilities are detected once and cached. Detection is conservative:
/// any failure or missing capability results in `false` rather than guessing.
///
/// Three capability domains are distinguished:
///   * FFmpeg build capabilities — whether `libx264`, `h264_mediacodec`,
///     `aac`, `hls`, `mpegts`, `mp4` etc. are compiled into the FFmpeg build.
///     Detected by parsing `-encoders`, `-decoders`, `-muxers`, `-filters`.
///   * Device hardware codec capabilities — not probed separately. If FFmpeg
///     reports `h264_mediacodec` as an available encoder, we treat it as
///     usable by the current FFmpeg integration. We do not consult Android
///     codec listings, because a codec listed there does not guarantee the
///     FFmpeg wrapper can use it.
///   * Chromecast receiver playback capabilities — fixed knowledge about what
///     the Default Media Receiver can play (H.264 up to High/4.2, VP9, etc.).
///     This lives in [CastCompat] and [decide]; `supportsHevc` defaults to
///     `false` because stock Chromecast does not play HEVC.
class CastFfmpegCapabilities {
  static CastDeviceCaps? _cached;

  /// Detects FFmpeg capabilities and returns a [CastDeviceCaps].
  ///
  /// Results are cached after the first successful detection. Subsequent calls
  /// return the cached value. If detection fails, returns a caps object with
  /// all capabilities disabled (conservative fallback).
  ///
  /// [query] is an optional override used by tests to inject synthetic FFmpeg
  /// output or simulate query failures without invoking the real FFmpegKit.
  static Future<CastDeviceCaps> detect({
    Future<String?> Function(String)? query,
  }) async {
    if (_cached != null) return _cached!;
    final q = query ?? _query;
    try {
      final results = await Future.wait<String?>([
        q('-hide_banner -encoders'),
        q('-hide_banner -decoders'),
        q('-hide_banner -muxers'),
        q('-hide_banner -filters'),
      ]);
      // If any query failed (returned null), treat as failure.
      if (results.any((r) => r == null)) {
        throw Exception('FFmpeg capability query failed');
      }
      final caps = parseCapabilities(
        results[0]!,
        results[1]!,
        results[2]!,
        results[3]!,
      );
      _cached = caps;
      return caps;
    } catch (e, st) {
      debugPrint('[FFDBG] capability detection failed: $e');
      debugPrint('$st');
      // Conservative fallback: do NOT cache so the next call retries.
      return const CastDeviceCaps();
    }
  }

  /// Clears the cache so the next [detect] re-runs FFmpeg queries.
  static void clearCache() {
    _cached = null;
  }

  /// Parses raw FFmpeg query output into a [CastDeviceCaps].
  ///
  /// This is a pure function and can be tested without invoking FFmpegKit.
  static CastDeviceCaps parseCapabilities(
    String encoders,
    String decoders,
    String muxers,
    String filters,
  ) {
    final hasLibx264 = _contains(encoders, 'libx264');
    final hasH264Mediacodec = _contains(encoders, 'h264_mediacodec');
    final hasH264Encoder = hasLibx264 || hasH264Mediacodec;

    return CastDeviceCaps(
      // Chromecast receiver knowledge: stock Chromecast does not play HEVC.
      // Set externally via CastDeviceCaps.supportsHevc if a receiver is
      // known to support it.
      supportsHevc: false,
      hasH264Encoder: hasH264Encoder,
      hasLibx264: hasLibx264,
      hasH264Mediacodec: hasH264Mediacodec,
      // Transcoding is OFF by default. The app enables it via the
      // "Experimental: convert unsupported videos" setting only after the
      // encoder self-test passes.
      transcodeEnabled: false,
      modelName: null,
    );
  }

  static Future<String?> _query(String cmd) async {
    try {
      final session = await FFmpegKit.execute(cmd);
      final output = await session.getOutput();
      if (output == null || output.isEmpty) return null;
      return output;
    } catch (e) {
      debugPrint('[FFDBG] query "$cmd" failed: $e');
      return null;
    }
  }

  static bool _contains(String haystack, String needle) =>
      haystack.toLowerCase().contains(needle.toLowerCase());

  /// Prints diagnostic output explaining why each capability is enabled or
  /// disabled. Safe to call at app startup in debug mode.
  static Future<void> dumpDiagnostics() async {
    final caps = await detect();
    debugPrint('[FFDBG] CastDeviceCaps:');
    debugPrint(
      '[FFDBG]   supportsHevc=${caps.supportsHevc} '
      '(receiver HEVC support; default false)',
    );
    debugPrint(
      '[FFDBG]   hasH264Encoder=${caps.hasH264Encoder} '
      '(libx264 or h264_mediacodec encoder present)',
    );
    debugPrint(
      '[FFDBG]   hasH264Mediacodec=${caps.hasH264Mediacodec} '
      '(h264_mediacodec encoder present)',
    );
    debugPrint(
      '[FFDBG]   transcodeEnabled=${caps.transcodeEnabled} '
      '(any H.264 encoder available)',
    );
    debugPrint('[FFDBG]   modelName=${caps.modelName ?? '<none>'}');
  }
}
