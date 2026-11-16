/// Result of probing a media file with FFprobe.
class MediaProbe {
  /// Container/format name reported by FFprobe (for example `matroska,webm`).
  final String container;

  /// Duration reported by FFprobe, in seconds, when available.
  final double? durationSeconds;

  /// First video stream, or null when the file has no video.
  final VideoStream? video;

  /// Audio streams in the order FFprobe reported them.
  final List<AudioStream> audio;

  /// Subtitle streams in the order FFprobe reported them.
  final List<SubtitleStream> subtitles;

  const MediaProbe({
    required this.container,
    this.durationSeconds,
    this.video,
    this.audio = const [],
    this.subtitles = const [],
  });

  /// [durationSeconds] as a [Duration], or null when FFprobe reported none.
  Duration? get duration =>
      durationSeconds == null
          ? null
          : Duration(microseconds: (durationSeconds! * 1000000).round());

  /// Whether the file contains at least one subtitle stream.
  bool get hasSubtitles => subtitles.isNotEmpty;

  factory MediaProbe.fromJson(Map<String, dynamic> json) {
    final format =
        (json['format'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final streams = (json['streams'] as List?) ?? const [];
    VideoStream? video;
    final audio = <AudioStream>[];
    final subs = <SubtitleStream>[];
    for (final s in streams) {
      if (s is! Map) continue;
      final type = s['codec_type'] as String?;
      if (type == 'video' && video == null) {
        video = VideoStream.fromJson(s.cast<String, dynamic>());
      } else if (type == 'audio') {
        audio.add(
          AudioStream.fromJson(
            s.cast<String, dynamic>(),
            trackIndex: audio.length,
          ),
        );
      } else if (type == 'subtitle') {
        subs.add(
          SubtitleStream.fromJson(
            s.cast<String, dynamic>(),
            trackIndex: subs.length,
          ),
        );
      }
    }
    final dur = format['duration'];
    return MediaProbe(
      container: (format['format_name'] as String?) ?? '',
      durationSeconds:
          dur is String ? double.tryParse(dur) : (dur as num?)?.toDouble(),
      video: video,
      audio: audio,
      subtitles: subs,
    );
  }
}

class VideoStream {
  final String codec;
  final String? profile;
  final int? level;
  final String? pixFmt;
  final int? width;
  final int? height;
  final double? fps;

  const VideoStream({
    required this.codec,
    this.profile,
    this.level,
    this.pixFmt,
    this.width,
    this.height,
    this.fps,
  });

  factory VideoStream.fromJson(Map<String, dynamic> j) => VideoStream(
    codec: (j['codec_name'] as String?) ?? 'unknown',
    profile: j['profile'] as String?,
    level: (j['level'] as num?)?.toInt(),
    pixFmt: j['pix_fmt'] as String?,
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
    fps: _parseFps(j['r_frame_rate'] as String?),
  );

  static double? _parseFps(String? r) {
    if (r == null) return null;
    final parts = r.split('/');
    if (parts.length == 2) {
      final a = double.tryParse(parts[0]);
      final b = double.tryParse(parts[1]);
      if (a != null && b != null && b != 0) return a / b;
    }
    return double.tryParse(r);
  }
}

class AudioStream {
  /// Absolute stream index in the container (use with `-map 0:N`).
  final int index;

  /// 0-based position among audio streams (use with `-map 0:a:N`).
  final int trackIndex;

  final String codec;
  final int channels;
  final String? language;

  /// Human-readable title from stream metadata, when available.
  final String? title;

  final bool isDefault;

  const AudioStream({
    required this.index,
    this.trackIndex = -1,
    required this.codec,
    this.channels = 2,
    this.language,
    this.title,
    this.isDefault = false,
  });

  factory AudioStream.fromJson(
    Map<String, dynamic> j, {
    int trackIndex = -1,
  }) => AudioStream(
    index: (j['index'] as num?)?.toInt() ?? -1,
    trackIndex: trackIndex,
    codec: (j['codec_name'] as String?) ?? 'unknown',
    channels: (j['channels'] as num?)?.toInt() ?? 2,
    language: (j['tags'] is Map) ? (j['tags']['language'] as String?) : null,
    title: (j['tags'] is Map) ? (j['tags']['title'] as String?) : null,
    isDefault: j['disposition'] is Map && (j['disposition']['default'] == 1),
  );
}

class SubtitleStream {
  /// Absolute stream index in the container (use with `-map 0:N`).
  final int index;

  /// 0-based position among subtitle streams (use with `-map 0:s:N`).
  final int trackIndex;

  final String codec;
  final String? language;

  /// Human-readable title from stream metadata, when available.
  final String? title;

  /// True for image-based codecs (PGS, VobSub/DVB) that cannot be converted
  /// to text.
  ///
  /// Populated by [SubtitleStream.fromJson]; pass it explicitly when
  /// constructing a [SubtitleStream] directly.
  final bool isImageBased;

  const SubtitleStream({
    required this.index,
    this.trackIndex = -1,
    required this.codec,
    this.language,
    this.title,
    this.isImageBased = false,
  });

  /// Human-readable label for UI display (for example `EN (SUBRIP)`).
  String get displayLabel {
    final lang =
        (language?.isNotEmpty == true) ? language!.toUpperCase() : 'Unknown';
    final fmt = codec.toUpperCase();
    return '$lang ($fmt)';
  }

  factory SubtitleStream.fromJson(
    Map<String, dynamic> j, {
    int trackIndex = -1,
  }) {
    final codec = (j['codec_name'] as String?) ?? 'unknown';
    return SubtitleStream(
      index: (j['index'] as num?)?.toInt() ?? -1,
      trackIndex: trackIndex,
      codec: codec,
      language: (j['tags'] is Map) ? (j['tags']['language'] as String?) : null,
      title: (j['tags'] is Map) ? (j['tags']['title'] as String?) : null,
      isImageBased: _imageBasedCodecs.contains(codec.toLowerCase()),
    );
  }
}

/// Codecs that carry bitmap subtitles and cannot be converted to text.
const Set<String> _imageBasedCodecs = {
  'dvd_subtitle',
  'hdmv_pgs_subtitle',
  'dvb_subtitle',
  'xsub',
};
