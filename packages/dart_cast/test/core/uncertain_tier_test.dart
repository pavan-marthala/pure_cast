import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:dart_cast/src/core/cast_ffmpeg_commands.dart';
import 'package:test/test.dart';

void main() {
  test('HEVC 8-bit -> uncertain direct', () {
    final p = MediaProbe.fromJson({
      'format': {'format_name': 'mp4', 'duration': '10'},
      'streams': [
        {
          'codec_type': 'video',
          'codec_name': 'hevc',
          'pix_fmt': 'yuv420p',
          'level': 120,
        },
        {
          'codec_type': 'audio',
          'index': 1,
          'codec_name': 'aac',
          'disposition': {'default': 1},
        },
      ],
    });
    final plan = decide(p, const CastDeviceCaps(supportsHevc: true));
    expect(plan, isA<UncertainDirectPlan>());
  });

  test('AV1 -> transcode-required (unsupported without encoder)', () {
    final p = MediaProbe.fromJson({
      'format': {'format_name': 'mkv', 'duration': '10'},
      'streams': [
        {'codec_type': 'video', 'codec_name': 'av1', 'pix_fmt': 'yuv420p10le'},
        {
          'codec_type': 'audio',
          'index': 1,
          'codec_name': 'aac',
          'disposition': {'default': 1},
        },
      ],
    });
    final plan = decide(p, const CastDeviceCaps());
    expect(plan, isA<UnsupportedPlan>());
  });

  test('yuvj420p bit depth is 8', () {
    expect(bitDepthOf('yuvj420p'), 8);
    expect(bitDepthOf('yuv420p10le'), 10);
    expect(bitDepthOf('p010le'), 10);
  });

  test('filter quoting in builders', () {
    final a = CastFfmpegCommands.transcodeVideo(
      input: 'in.mkv',
      outputDir: '/tmp/out',
      audioStreamIndex: 0,
      videoEncoder: 'libx264',
    );
    expect(a.join(' '), contains('min(1080'));
  });
}
