import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';

dart_cast.CastService _castService() => dart_cast.CastService(
  sessionFactory: (_) => throw UnimplementedError('no session in probe test'),
);

void main() {
  test('probeAudioTracks maps audio streams to 0-based track indices', () async {
    late String probedPath;
    final adapter = DartCastAdapter(
      castService: _castService(),
      mediaProbe: (path) async {
        probedPath = path;
        return const dart_cast.MediaProbe(
          container: 'matroska,webm',
          durationSeconds: 5400,
          audio: [
            dart_cast.AudioStream(
              index: 1,
              codec: 'ac3',
              channels: 6,
              language: 'eng',
              isDefault: true,
            ),
            dart_cast.AudioStream(
              index: 3,
              codec: 'aac',
              channels: 2,
            ),
          ],
        );
      },
    );

    final tracks = await adapter.probeAudioTracks('/videos/movie.mkv');

    expect(probedPath, '/videos/movie.mkv');
    expect(tracks, const [
      PureCastAudioTrack(
        index: 0,
        language: 'eng',
        codec: 'ac3',
        channels: 6,
        isDefault: true,
      ),
      PureCastAudioTrack(
        index: 1,
        language: '',
        codec: 'aac',
        channels: 2,
      ),
    ]);

    await adapter.dispose();
  });

  test('probeAudioTracks returns no tracks when the probe has no info', () async {
    final adapter = DartCastAdapter(
      castService: _castService(),
      mediaProbe: (_) async => null,
    );

    expect(await adapter.probeAudioTracks('/videos/movie.mkv'), isEmpty);

    await adapter.dispose();
  });

  test('probeAudioTracks surfaces probe errors to the caller', () async {
    final adapter = DartCastAdapter(
      castService: _castService(),
      mediaProbe: (_) async => throw Exception('ffprobe failed'),
    );

    await expectLater(
      adapter.probeAudioTracks('/videos/movie.mkv'),
      throwsA(isA<Exception>()),
    );

    await adapter.dispose();
  });
}
