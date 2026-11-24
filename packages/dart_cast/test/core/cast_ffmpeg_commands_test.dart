import 'package:dart_cast/src/core/cast_ffmpeg_commands.dart';
import 'package:test/test.dart';

void main() {
  group('CastFfmpegCommands.remuxMp4', () {
    test('copies video and audio by default', () {
      final args = CastFfmpegCommands.remuxMp4(
        input: '/in.mkv',
        output: '/out.mp4',
        audioStreamIndex: 1,
      );
      expect(args, containsAllInOrder(['-i', '/in.mkv', '-map', '0:v:0']));
      expect(args, containsAllInOrder(['-map', '0:a:1']));
      expect(args, containsAllInOrder(['-c:v', 'copy']));
      expect(args, containsAllInOrder(['-c:a', 'copy']));
      expect(args, containsAllInOrder(['-movflags', '+faststart']));
      expect(args.last, '/out.mp4');
    });

    test('converts audio to stereo AAC when requested', () {
      final args = CastFfmpegCommands.remuxMp4(
        input: '/in.mkv',
        output: '/out.mp4',
        audioStreamIndex: 0,
        transcodeAudio: true,
      );
      expect(args, containsAllInOrder(['-c:a', 'aac', '-ac', '2']));
      expect(args, isNot(containsAllInOrder(['-c:a', 'copy'])));
    });
  });

  group('CastFfmpegCommands.transcodeMp4', () {
    test('uses the requested encoder and AAC audio', () {
      final args = CastFfmpegCommands.transcodeMp4(
        input: '/in.mkv',
        output: '/out.mp4',
        audioStreamIndex: 2,
        videoEncoder: 'libx264',
      );
      expect(args, containsAllInOrder(['-map', '0:a:2']));
      expect(args, containsAllInOrder(['-c:v', 'libx264']));
      expect(args, containsAllInOrder(['-preset', 'veryfast']));
      expect(args, containsAllInOrder(['-c:a', 'aac']));
      expect(args.last, '/out.mp4');
    });
  });

  group('CastFfmpegCommands.hlsVideo', () {
    test('copies video and writes a VOD playlist', () {
      final args = CastFfmpegCommands.hlsVideo(
        input: '/in.mkv',
        outputDir: '/tmp/out',
        transcodeVideo: false,
      );
      expect(args, containsAllInOrder(['-c:v', 'copy']));
      expect(args, contains('-an'));
      expect(args, containsAllInOrder(['-hls_playlist_type', 'vod']));
      expect(args, contains('/tmp/out/video.m3u8'));
      expect(args, contains('/tmp/out/video_%05d.ts'));
    });

    test('encodes video when transcoding is requested', () {
      final args = CastFfmpegCommands.hlsVideo(
        input: '/in.mkv',
        outputDir: '/tmp/out',
        transcodeVideo: true,
        videoEncoder: 'h264_mediacodec',
      );
      expect(args, containsAllInOrder(['-c:v', 'h264_mediacodec']));
      expect(args, isNot(contains('copy')));
    });
  });

  group('CastFfmpegCommands.hlsAudio', () {
    test('maps one audio stream, drops video and writes AAC VOD', () {
      final args = CastFfmpegCommands.hlsAudio(
        input: '/in.mkv',
        outputDir: '/tmp/out',
        audioStreamIndex: 3,
        name: 'audio_3',
      );
      expect(args, containsAllInOrder(['-map', '0:a:3']));
      expect(args, contains('-vn'));
      expect(args, containsAllInOrder(['-c:a', 'aac']));
      expect(args, contains('/tmp/out/audio_3.m3u8'));
      expect(args, contains('/tmp/out/audio_3_%05d.ts'));
    });
  });
}
