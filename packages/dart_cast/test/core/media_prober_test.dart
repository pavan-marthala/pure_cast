import 'dart:async';

import 'package:dart_cast/dart_cast.dart';
import 'package:test/test.dart';

class _FakeRunner implements FfprobeRunner {
  _FakeRunner(this._handler);

  final Future<Map<String, dynamic>?> Function(String input) _handler;
  final List<String> inputs = <String>[];

  @override
  Future<Map<String, dynamic>?> probeRaw(String input) {
    inputs.add(input);
    return _handler(input);
  }
}

Map<String, dynamic> _raw() => {
  'format': {'format_name': 'matroska,webm', 'duration': '10.0'},
  'streams': [
    {
      'codec_type': 'audio',
      'codec_name': 'aac',
      'channels': 2,
      'index': 1,
      'tags': {'language': 'eng'},
      'disposition': {'default': 1},
    },
    {
      'codec_type': 'subtitle',
      'codec_name': 'subrip',
      'index': 2,
      'tags': {'language': 'eng'},
    },
  ],
};

void main() {
  group('FfprobeMediaProber', () {
    test('returns a MediaProbe and passes plain paths through', () async {
      final runner = _FakeRunner((_) async => _raw());
      final prober = FfprobeMediaProber(runner: runner);

      final probe = await prober.probe('/videos/movie.mkv');

      expect(runner.inputs, ['/videos/movie.mkv']);
      expect(probe.container, 'matroska,webm');
      expect(probe.audio.single.trackIndex, 0);
      expect(probe.subtitles.single.displayLabel, 'ENG (SUBRIP)');
      expect(probe.hasSubtitles, isTrue);
    });

    test('converts a file:// URI to a plain path', () async {
      final runner = _FakeRunner((_) async => _raw());
      final prober = FfprobeMediaProber(runner: runner);

      await prober.probe('file:///videos/movie.mkv');

      expect(runner.inputs, ['/videos/movie.mkv']);
    });

    test('null media information throws ProbeFailedException', () async {
      final runner = _FakeRunner((_) async => null);
      final prober = FfprobeMediaProber(runner: runner);

      await expectLater(
        prober.probe('/videos/movie.mkv'),
        throwsA(isA<ProbeFailedException>()),
      );
    });

    test('runner errors are wrapped in ProbeFailedException', () async {
      final runner = _FakeRunner((_) async => throw StateError('boom'));
      final prober = FfprobeMediaProber(runner: runner);

      await expectLater(
        prober.probe('/videos/movie.mkv'),
        throwsA(isA<ProbeFailedException>()),
      );
    });

    test('timeout throws ProbeFailedException', () async {
      final runner = _FakeRunner(
        (_) => Completer<Map<String, dynamic>?>().future,
      );
      final prober = FfprobeMediaProber(runner: runner);

      await expectLater(
        prober.probe(
          '/videos/movie.mkv',
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<ProbeFailedException>()),
      );
    });
  });
}
