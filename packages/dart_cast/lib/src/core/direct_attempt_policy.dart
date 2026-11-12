/// Pure policy for deciding whether a direct playback attempt's failure
/// should be recorded as a known-incompatible result.
///
/// Records `directFailed` only when ALL of:
///   - The exception is a [MediaLoadFailedException] (receiver rejection),
///     NOT a network error, timeout, probe error, or ffmpeg failure.
///   - The codec is HEVC or VP9 (uncertain codecs that may or may not
///     be supported by the receiver).
///   - No subtitle track was attached (subtitles can cause false
///     rejections unrelated to codec support).
///   - It was a direct attempt (not a remux/transcode attempt).
///
/// Never records for H.264 (always compatible) or AV1/10-bit (always
/// transcode-required, not a direct attempt).
class DirectAttemptPolicy {
  /// Returns true if the failure should be recorded as `directFailed`.
  static bool shouldRecordDirectFailed({
    required bool isMediaLoadFailed,
    required String codec,
    required bool hasSubtitle,
    required bool isDirectAttempt,
  }) {
    if (!isMediaLoadFailed) return false;
    if (!isDirectAttempt) return false;
    if (hasSubtitle) return false;
    final c = codec.toLowerCase();
    if (c != 'hevc' &&
        c != 'hvc1' &&
        c != 'hev1' &&
        c != 'vp9' &&
        c != 'vp09') {
      return false;
    }
    return true;
  }
}
