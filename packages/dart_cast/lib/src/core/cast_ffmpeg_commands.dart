/// FFmpeg command builders for prepared casting.
class CastFfmpegCommands {
  static List<String> transcodeVideo({
    required String input,
    required String outputDir,
    required int audioStreamIndex,
    required String videoEncoder,
  }) {
    final args = <String>[
      '-nostdin',
      '-i',
      input,
      '-map',
      '0:v:0',
      '-map',
      '0:a:$audioStreamIndex',
      '-c:v',
      videoEncoder,
      '-pix_fmt',
      'yuv420p',
      '-vf',
      "scale=-2:min(1080,ih)",
      '-b:v',
      '5M',
      '-maxrate',
      '6M',
      '-bufsize',
      '10M',
      '-g',
      '48',
      '-sc_threshold',
      '0',
    ];
    if (videoEncoder == 'libx264') {
      args.addAll(['-preset', 'veryfast']);
    }
    args.addAll([
      '-c:a',
      'aac',
      '-ac',
      '2',
      '-b:a',
      '192k',
      '-f',
      'hls',
      '-hls_time',
      '6',
      '-hls_playlist_type',
      'event',
      '-hls_flags',
      'independent_segments',
      '-hls_segment_filename',
      '$outputDir/seg_%05d.ts',
      '$outputDir/index.m3u8',
    ]);
    return args;
  }

  static List<String> transcodeVideoMediacodec({
    required String input,
    required String outputDir,
    required int audioStreamIndex,
  }) => [
    '-nostdin',
    '-i',
    input,
    '-map',
    '0:v:0',
    '-map',
    '0:a:$audioStreamIndex',
    '-c:v',
    'h264_mediacodec',
    '-b:v',
    '5M',
    '-pix_fmt',
    'nv12',
    '-vf',
    "scale=-2:min(1080,ih)",
    '-g',
    '48',
    '-c:a',
    'aac',
    '-ac',
    '2',
    '-b:a',
    '192k',
    '-f',
    'hls',
    '-hls_time',
    '6',
    '-hls_playlist_type',
    'event',
    '-hls_flags',
    'independent_segments',
    '-hls_segment_filename',
    '$outputDir/seg_%05d.ts',
    '$outputDir/index.m3u8',
  ];

  /// Remuxes [input] into a fast-start MP4 at [output].
  ///
  /// Video is always copied. Audio is copied when [transcodeAudio] is false,
  /// otherwise it is converted to stereo AAC. [audioStreamIndex] is the
  /// 0-based index among audio streams (`0:a:N`).
  static List<String> remuxMp4({
    required String input,
    required String output,
    required int audioStreamIndex,
    bool transcodeAudio = false,
  }) => [
    '-nostdin',
    '-i',
    input,
    '-map',
    '0:v:0',
    '-map',
    '0:a:$audioStreamIndex',
    '-c:v',
    'copy',
    if (transcodeAudio) ...[
      '-c:a',
      'aac',
      '-ac',
      '2',
      '-b:a',
      '192k',
    ] else ...[
      '-c:a',
      'copy',
    ],
    '-movflags',
    '+faststart',
    '-f',
    'mp4',
    output,
  ];

  /// Transcodes [input] into an H.264/AAC MP4 at [output].
  ///
  /// Unlike the HLS builders this writes one MP4 file, which is the cheapest
  /// AirPlay path when only the video codec is incompatible.
  static List<String> transcodeMp4({
    required String input,
    required String output,
    required int audioStreamIndex,
    required String videoEncoder,
  }) {
    final args = <String>[
      '-nostdin',
      '-i',
      input,
      '-map',
      '0:v:0',
      '-map',
      '0:a:$audioStreamIndex',
      '-c:v',
      videoEncoder,
      '-pix_fmt',
      'yuv420p',
      '-vf',
      'scale=-2:min(1080,ih)',
      '-b:v',
      '5M',
      '-maxrate',
      '6M',
      '-bufsize',
      '10M',
      '-g',
      '48',
      '-sc_threshold',
      '0',
    ];
    if (videoEncoder == 'libx264') {
      args.addAll(['-preset', 'veryfast']);
    }
    args.addAll([
      '-c:a',
      'aac',
      '-ac',
      '2',
      '-b:a',
      '192k',
      '-movflags',
      '+faststart',
      '-f',
      'mp4',
      output,
    ]);
    return args;
  }

  /// Builds the video-only variant of a VOD HLS directory.
  ///
  /// The playlist is written as `video.m3u8`; audio is delivered through
  /// separate renditions so a master playlist can expose every track. With
  /// [transcodeVideo] false the video stream is copied untouched.
  static List<String> hlsVideo({
    required String input,
    required String outputDir,
    required bool transcodeVideo,
    String videoEncoder = 'libx264',
    String name = 'video',
  }) {
    final args = <String>['-nostdin', '-i', input, '-map', '0:v:0', '-an'];
    if (transcodeVideo) {
      args.addAll([
        '-c:v',
        videoEncoder,
        '-pix_fmt',
        'yuv420p',
        '-vf',
        'scale=-2:min(1080,ih)',
        '-b:v',
        '5M',
        '-maxrate',
        '6M',
        '-bufsize',
        '10M',
        '-g',
        '48',
        '-sc_threshold',
        '0',
      ]);
      if (videoEncoder == 'libx264') {
        args.addAll(['-preset', 'veryfast']);
      }
    } else {
      args.addAll(['-c:v', 'copy']);
    }
    args.addAll([
      '-f',
      'hls',
      '-hls_time',
      '6',
      '-hls_playlist_type',
      'vod',
      '-hls_flags',
      'independent_segments',
      '-hls_segment_filename',
      '$outputDir/${name}_%05d.ts',
      '$outputDir/$name.m3u8',
    ]);
    return args;
  }

  /// Builds one audio-only rendition for a VOD HLS directory.
  ///
  /// Each rendition is converted to stereo AAC and written as `<name>.m3u8`
  /// with matching segments, ready to be referenced by an `EXT-X-MEDIA`
  /// audio group.
  static List<String> hlsAudio({
    required String input,
    required String outputDir,
    required int audioStreamIndex,
    String name = 'audio',
  }) => [
    '-nostdin',
    '-i',
    input,
    '-map',
    '0:a:$audioStreamIndex',
    '-vn',
    '-c:a',
    'aac',
    '-ac',
    '2',
    '-b:a',
    '192k',
    '-f',
    'hls',
    '-hls_time',
    '6',
    '-hls_playlist_type',
    'vod',
    '-hls_flags',
    'independent_segments',
    '-hls_segment_filename',
    '$outputDir/${name}_%05d.ts',
    '$outputDir/$name.m3u8',
  ];

  static List<String> liveMkv({
    required String input,
    required int audioStreamIndex,
    required String output,
    double? startSeconds,
  }) => [
    '-nostdin',
    if (startSeconds != null && startSeconds > 0) ...['-ss', '$startSeconds'],
    '-i',
    input,
    '-map',
    '0:v:0',
    '-map',
    '0:a:$audioStreamIndex',
    '-c:v',
    'copy',
    '-c:a',
    'aac',
    '-ac',
    '2',
    '-b:a',
    '192k',
    '-live',
    '1',
    '-f',
    'matroska',
    output,
  ];
}
