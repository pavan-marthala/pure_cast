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

    test('omits -ss when startSeconds is null or not positive', () {
      final nullStart = CastFfmpegCommands.liveMkv(
        input: '/videos/movie.mkv',
        audioStreamIndex: 0,
        output: 'tcp://127.0.0.1:4567',
      );
      expect(nullStart, isNot(contains('-ss')));

      final zeroStart = CastFfmpegCommands.liveMkv(
        input: '/videos/movie.mkv',
        audioStreamIndex: 0,
        output: 'tcp://127.0.0.1:4567',
        startSeconds: 0,
      );
      expect(zeroStart, isNot(contains('-ss')));
    });

    test('puts -ss before -i and keeps the other arguments', () {
      final args = CastFfmpegCommands.liveMkv(
        input: '/videos/movie.mkv',
        audioStreamIndex: 2,
        output: 'tcp://127.0.0.1:4567',
        startSeconds: 61.5,
      );

      expect(args, containsAllInOrder(['-ss', '61.5', '-i', '/videos/movie.mkv']));
      expect(
        args.indexOf('-ss'),
        lessThan(args.indexOf('-i')),
        reason: '-ss must be an input seek (before -i)',
      );
      // Only the input seek changed; the rest of the command is unchanged.
      expect(args, containsAllInOrder(['-map', '0:v:0']));
      expect(args, containsAllInOrder(['-map', '0:a:2']));
      expect(args, containsAllInOrder(['-c:v', 'copy']));
      expect(args, containsAllInOrder(['-c:a', 'aac']));
      expect(args, containsAllInOrder(['-live', '1']));
      expect(args, containsAllInOrder(['-f', 'matroska']));
      expect(args.last, 'tcp://127.0.0.1:4567');
    });
  });
}
