import 'package:dart_cast/src/core/cast_ffmpeg_commands.dart';
import 'package:test/test.dart';

void main() {
  group('CastFfmpegCommands.liveMkv', () {
    test('builds a live matroska stream with the requested audio track', () {
      final args = CastFfmpegCommands.liveMkv(
        input: '/videos/movie.mkv',
        audioStreamIndex: 3,
        output: 'tcp://127.0.0.1:4567',
      );

      expect(args, containsAllInOrder(['-live', '1']));
      expect(args, containsAllInOrder(['-f', 'matroska']));
      expect(args, containsAllInOrder(['-map', '0:a:3']));
      expect(args, containsAllInOrder(['-map', '0:v:0']));
      expect(args, containsAllInOrder(['-c:v', 'copy']));
      expect(args, containsAllInOrder(['-c:a', 'aac']));
      expect(args, containsAllInOrder(['-i', '/videos/movie.mkv']));
      expect(args.last, 'tcp://127.0.0.1:4567');
    });
  });
}
