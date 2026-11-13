/// FFmpeg command builders for prepared casting.
class CastFfmpegCommands {
  static List<String> remuxAudio({
    required String input,
    required String outputDir,
    required int audioStreamIndex,
    String streams = 'both',
    String segments = 'ts',
  }) {
    final isFmp4 = segments == 'fmp4';
    final segExt = isFmp4 ? 'm4s' : 'ts';
    final segName = isFmp4 ? 'seg_%05d.m4s' : 'seg_%05d.ts';
    final args = <String>['-nostdin'];
    if (streams == 'video') {
      args.addAll(['-i', input, '-map', '0:v:0', '-c:v', 'copy', '-an']);
    } else if (streams == 'audio') {
      args.addAll([
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
      ]);
    } else {
      args.addAll([
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
      ]);
    }
    args.addAll([
      '-f',
      'hls',
      '-hls_time',
      '6',
      '-hls_playlist_type',
      'event',
      '-hls_flags',
      'independent_segments',
    ]);
    if (isFmp4) {
      args.addAll([
        '-hls_segment_type',
        'fmp4',
        '-hls_fmp4_init_filename',
        'init.mp4',
      ]);
    }
    args.addAll([
      '-hls_segment_filename',
      '$outputDir/$segName',
      '$outputDir/index.m3u8',
    ]);
    return args;
  }

  static List<String> remuxContainer({
    required String input,
    required String outputDir,
    required int audioStreamIndex,
    String streams = 'both',
    String segments = 'ts',
  }) {
    final isFmp4 = segments == 'fmp4';
    final segName = isFmp4 ? 'seg_%05d.m4s' : 'seg_%05d.ts';
    final args = <String>['-nostdin', '-fflags', '+genpts'];
    if (streams == 'video') {
      args.addAll([
        '-i',
        input,
        '-map',
        '0:v:0',
        '-c:v',
        'copy',
        '-an',
        '-avoid_negative_ts',
        'make_zero',
      ]);
    } else if (streams == 'audio') {
      args.addAll([
        '-i',
        input,
        '-map',
        '0:a:$audioStreamIndex',
        '-vn',
        '-c:a',
        'copy',
        '-avoid_negative_ts',
        'make_zero',
      ]);
    } else {
      args.addAll([
        '-i',
        input,
        '-map',
        '0:v:0',
        '-map',
        '0:a:$audioStreamIndex',
        '-c',
        'copy',
        '-avoid_negative_ts',
        'make_zero',
      ]);
    }
    args.addAll([
      '-f',
      'hls',
      '-hls_time',
      '6',
      '-hls_playlist_type',
      'event',
      '-hls_flags',
      'independent_segments',
    ]);
    if (isFmp4) {
      args.addAll([
        '-hls_segment_type',
        'fmp4',
        '-hls_fmp4_init_filename',
        'init.mp4',
      ]);
    }
    args.addAll([
      '-hls_segment_filename',
      '$outputDir/$segName',
      '$outputDir/index.m3u8',
    ]);
    return args;
  }

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
      "scale=-2:min(1080\,ih)",
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
    "scale=-2:min(1080\,ih)",
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
}

// extension
