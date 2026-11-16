import 'cast_exceptions.dart';

/// Base class for failures while extracting a subtitle track.
///
/// This hierarchy covers source, codec, FFmpeg, cache, cancellation, timeout
/// and empty-output failures, so every failure thrown by `SubtitleExtractor`
/// is a [MediaTrackException]. `SubtitleCache`'s own API still throws
/// [SubtitleCacheException] directly; the extractor wraps those in
/// [SubtitleCacheFailure].
///
/// Messages never contain file paths or URLs.
sealed class MediaTrackException extends CastException {
  /// Creates a media-track exception.
  MediaTrackException(super.message, [super.cause]);
}

/// The source file could not be read, or its path is empty.
final class SubtitleSourceUnreadable extends MediaTrackException {
  /// Creates a source failure.
  SubtitleSourceUnreadable(super.message, [super.cause]);
}

/// The track's codec cannot produce the requested output format.
final class SubtitleUnsupportedCodec extends MediaTrackException {
  /// Creates an unsupported-codec failure.
  SubtitleUnsupportedCodec(super.message, [super.cause]);
}

/// FFmpeg finished without producing the subtitle track.
final class SubtitleFfmpegFailed extends MediaTrackException {
  /// FFmpeg's return code, when available.
  final int? returnCode;

  /// The last 2000 characters of FFmpeg output, when available.
  ///
  /// FFmpeg logs can contain file paths. Do not show them to end users.
  final String? logs;

  /// Creates an FFmpeg failure, keeping only the last 2000 characters of
  /// [logs].
  SubtitleFfmpegFailed(
    String message, {
    this.returnCode,
    String? logs,
    Object? cause,
  }) : logs = _truncateLogs(logs),
       super(message, cause);
}

/// The extraction was cancelled.
final class SubtitleExtractionCancelled extends MediaTrackException {
  /// Creates a cancellation failure.
  SubtitleExtractionCancelled(super.message, [super.cause]);
}

/// The extraction exceeded its caller-supplied timeout.
final class SubtitleExtractionTimedOut extends MediaTrackException {
  /// Creates a timeout failure.
  SubtitleExtractionTimedOut(super.message, [super.cause]);
}

/// FFmpeg reported success but produced no bytes.
final class SubtitleEmptyOutput extends MediaTrackException {
  /// Creates an empty-output failure.
  SubtitleEmptyOutput(super.message, [super.cause]);
}

/// The subtitle cache could not be read or written.
///
/// For example the disk is full or the cache directory is not writable.
/// [cause] holds the underlying [SubtitleCacheException].
final class SubtitleCacheFailure extends MediaTrackException {
  /// Creates a cache failure.
  SubtitleCacheFailure(super.message, [super.cause]);
}

String? _truncateLogs(String? logs) =>
    logs == null || logs.length <= 2000
        ? logs
        : logs.substring(logs.length - 2000);
