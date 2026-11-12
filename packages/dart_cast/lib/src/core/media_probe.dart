import 'dart:convert' as convert;

class MediaProbe {
  final String container;
  final double? durationSeconds;
  final VideoStream? video;
  final List<AudioStream> audio;
  final List<SubtitleStream> subtitles;

  const MediaProbe({
    required this.container,
    this.durationSeconds,
    this.video,
    this.audio = const [],
    this.subtitles = const [],
  });

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
        video = VideoStream.fromJson((s as Map).cast<String, dynamic>());
      } else if (type == 'audio') {
        audio.add(AudioStream.fromJson((s as Map).cast<String, dynamic>()));
      } else if (type == 'subtitle') {
        subs.add(SubtitleStream.fromJson((s as Map).cast<String, dynamic>()));
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
  final int index;
  final String codec;
  final int channels;
  final String? language;
  final bool isDefault;

  const AudioStream({
    required this.index,
    required this.codec,
    this.channels = 2,
    this.language,
    this.isDefault = false,
  });

  factory AudioStream.fromJson(Map<String, dynamic> j) => AudioStream(
    index: (j['index'] as num?)?.toInt() ?? -1,
    codec: (j['codec_name'] as String?) ?? 'unknown',
    channels: (j['channels'] as num?)?.toInt() ?? 2,
    language: (j['tags'] is Map) ? (j['tags']['language'] as String?) : null,
    isDefault: j['disposition'] is Map && (j['disposition']['default'] == 1),
  );
}

class SubtitleStream {
  final int index;
  final String codec;
  final String? language;

  const SubtitleStream({
    required this.index,
    required this.codec,
    this.language,
  });

  factory SubtitleStream.fromJson(Map<String, dynamic> j) => SubtitleStream(
    index: (j['index'] as num?)?.toInt() ?? -1,
    codec: (j['codec_name'] as String?) ?? 'unknown',
    language: (j['tags'] is Map) ? (j['tags']['language'] as String?) : null,
  );
}
