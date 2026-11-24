import 'dart:io';

import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/cast_device.dart';
import 'package:dart_cast/src/core/cast_exceptions.dart';
import 'package:dart_cast/src/core/cast_media.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:dart_cast/src/core/media_prober.dart';
import 'package:dart_cast/src/protocols/airplay/airplay_media_preparer.dart';
import 'package:dart_cast/src/protocols/airplay/airplay_session.dart';
import 'package:test/test.dart';

import 'mock_airplay_server.dart';

const _h264 = VideoStream(codec: 'h264', level: 41, pixFmt: 'yuv420p');
const _aac = AudioStream(
  index: 1,
  trackIndex: 0,
  codec: 'aac',
  isDefault: true,
);
const _ac3 = AudioStream(index: 2, trackIndex: 0, codec: 'ac3');
const _hevc = VideoStream(codec: 'hevc', level: 120, pixFmt: 'yuv420p');

/// AirPlay 1 video (bit 0) plus HLS (bit 4).
const _hlsFeatures = '0x11';

/// AirPlay 1 video (bit 0) plus HLS and video volume control (bit 3).
const _volumeFeatures = '0x19';

class _FakeProber implements MediaProber {
  MediaProbe result;
  String? lastInput;

  _FakeProber(this.result);

  @override
  Future<MediaProbe> probe(
    String inputPath, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    lastInput = inputPath;
    return result;
  }
}

class _Call {
  final String kind;
  final int audioIndex;
  final bool transcodeVideo;
  final bool transcodeAudio;
  final CastSubtitle? subtitle;

  const _Call(
    this.kind, {
    required this.audioIndex,
    this.transcodeVideo = false,
    this.transcodeAudio = false,
    this.subtitle,
  });

  @override
  String toString() =>
      '$kind(audio=$audioIndex, tv=$transcodeVideo, ta=$transcodeAudio, '
      'sub=${subtitle?.label})';
}

class _FakePreparer implements AirPlayMediaPreparer {
  final List<_Call> calls = [];
  final List<AirPlayPreparedMedia> prepared = [];

  int _counter = 0;

  List<AirPlayPreparedMedia> get mp4Calls =>
      prepared.where((p) => p.type == CastMediaType.mp4).toList();

  List<AirPlayPreparedMedia> get hlsCalls =>
      prepared.where((p) => p.type == CastMediaType.hls).toList();

  @override
  Future<AirPlayPreparedMedia> prepareMp4({
    required String inputPath,
    required int audioIndex,
    required List<AudioStream> audioTracks,
    required bool transcodeVideo,
    required bool transcodeAudio,
    CastDeviceCaps caps = const CastDeviceCaps(),
    Duration? duration,
    CastSubtitle? subtitle,
  }) async {
    calls.add(
      _Call(
        'mp4',
        audioIndex: audioIndex,
        transcodeVideo: transcodeVideo,
        transcodeAudio: transcodeAudio,
        subtitle: subtitle,
      ),
    );
    return _create(
      type: CastMediaType.mp4,
      fileName: 'media.mp4',
      audioIndex: audioIndex,
      audioTracks: audioTracks,
      duration: duration,
      subtitle: subtitle,
    );
  }

  @override
  Future<AirPlayPreparedMedia> prepareHls({
    required String inputPath,
    required int audioIndex,
    required List<AudioStream> audioTracks,
    required bool transcodeVideo,
    CastDeviceCaps caps = const CastDeviceCaps(),
    Duration? duration,
    CastSubtitle? subtitle,
  }) async {
    calls.add(
      _Call(
        'hls',
        audioIndex: audioIndex,
        transcodeVideo: transcodeVideo,
        subtitle: subtitle,
      ),
    );
    return _create(
      type: CastMediaType.hls,
      fileName: 'index.m3u8',
      audioIndex: audioIndex,
      audioTracks: audioTracks,
      duration: duration,
      subtitle: subtitle,
    );
  }

  AirPlayPreparedMedia _create({
    required CastMediaType type,
    required String fileName,
    required int audioIndex,
    required List<AudioStream> audioTracks,
    required Duration? duration,
    required CastSubtitle? subtitle,
  }) {
    final directory = Directory.systemTemp.createTempSync('airplay_prep_');
    final path = '${directory.path}/$fileName';
    File(path).writeAsStringSync('#EXTM3U\n');
    final media = AirPlayPreparedMedia(
      sessionId: 'session_${_counter++}',
      directory: directory,
      path: path,
      type: type,
      duration: duration,
      audioTracks: audioTracks,
      audioIndex: audioIndex,
      subtitle: subtitle,
    );
    prepared.add(media);
    return media;
  }
}

MediaProbe _probe({
  String container = 'mp4',
  VideoStream? video = _h264,
  List<AudioStream> audio = const [_aac],
  double? duration = 120,
}) => MediaProbe(
  container: container,
  durationSeconds: duration,
  video: video,
  audio: audio,
);

const _caps = CastDeviceCaps(
  hasH264Encoder: true,
  hasLibx264: true,
  transcodeEnabled: true,
);

void main() {
  late MockAirPlayServer server;
  late AirPlaySession session;
  late _FakeProber prober;
  late _FakePreparer preparer;

  Future<AirPlaySession> start({
    MediaProbe? probe,
    List<AudioStream>? audio,
    String features = _hlsFeatures,
  }) async {
    server = MockAirPlayServer();
    await server.start();
    prober = _FakeProber(probe ?? _probe(audio: audio ?? const [_aac]));
    preparer = _FakePreparer();
    final device = CastDevice(
      id: 'local-airplay',
      name: 'Local AirPlay',
      protocol: CastProtocol.airplay,
      address: InternetAddress.loopbackIPv4,
      port: server.port,
      metadata: {'features': features},
    );
    session = AirPlaySession(device, prober: prober, preparer: preparer);
    await session.connect();
    return session;
  }

  tearDown(() async {
    session.dispose();
    await server.stop();
    for (final media in preparer.prepared) {
      await media.dispose();
    }
  });

  group('loadLocalFile planning', () {
    test('direct play needs no preparation and exposes tracks', () async {
      await start();

      await session.loadLocalFile('/media/movie.mp4', caps: _caps);

      expect(preparer.calls, isEmpty);
      expect(server.lastPath, '/play');
      expect(server.lastPlayStartPosition, closeTo(0.0, 0.0001));
      expect(session.audioTracks, hasLength(1));
      expect(session.activeAudioIndex, 0);
      expect(session.hasPreparedLocalMedia, isFalse);
    });

    test('container remux prepares an MP4 and copies audio', () async {
      await start(probe: _probe(container: 'matroska'));

      await session.loadLocalFile('/media/movie.mkv', caps: _caps);

      expect(preparer.calls, hasLength(1));
      expect(preparer.calls.single.kind, 'mp4');
      expect(preparer.calls.single.transcodeVideo, isFalse);
      expect(preparer.calls.single.transcodeAudio, isFalse);
      expect(session.hasPreparedLocalMedia, isTrue);
      expect(server.lastPlayStartPosition, closeTo(0.0, 0.0001));
    });

    test('AC-3 audio remux transcodes only the audio', () async {
      await start(probe: _probe(audio: const [_ac3]));

      await session.loadLocalFile('/media/movie.mp4', caps: _caps);

      expect(preparer.calls.single.kind, 'mp4');
      expect(preparer.calls.single.transcodeVideo, isFalse);
      expect(preparer.calls.single.transcodeAudio, isTrue);
    });

    test('HEVC prepares an H.264 transcode when an encoder exists', () async {
      await start(probe: _probe(video: _hevc));

      await session.loadLocalFile('/media/movie.mkv', caps: _caps);

      expect(preparer.calls.single.kind, 'mp4');
      expect(preparer.calls.single.transcodeVideo, isTrue);
    });

    test('an incompatible codec without an encoder is rejected', () async {
      await start(probe: _probe(video: _hevc));

      await expectLater(
        session.loadLocalFile('/media/movie.mkv'),
        throwsA(isA<UnsupportedMediaException>()),
      );
      expect(preparer.calls, isEmpty);
      expect(server.lastPath, isNot('/play'));
    });

    test('a subtitle request prepares VOD HLS with renditions', () async {
      await start();

      await session.loadLocalFile(
        '/media/movie.mp4',
        caps: _caps,
        subtitle: const CastSubtitle(
          url: '/media/sub.vtt',
          label: 'English',
          language: 'en',
          format: 'vtt',
        ),
      );

      expect(preparer.calls.single.kind, 'hls');
      expect(preparer.calls.single.subtitle?.label, 'English');
      expect(session.hasPreparedLocalMedia, isTrue);
      expect(server.lastPlayLocation, contains('/hls/'));
    });

    test('a subtitle request without HLS support is rejected', () async {
      await start(features: '0x1');

      await expectLater(
        session.loadLocalFile(
          '/media/movie.mp4',
          subtitle: const CastSubtitle(
            url: '/media/sub.vtt',
            label: 'English',
            language: 'en',
            format: 'vtt',
          ),
        ),
        throwsA(isA<UnsupportedFeatureException>()),
      );
      expect(preparer.calls, isEmpty);
    });

    test('the requested audio index is used and reported', () async {
      await start(
        probe: _probe(
          audio: const [
            AudioStream(index: 1, trackIndex: 0, codec: 'aac'),
            AudioStream(index: 2, trackIndex: 1, codec: 'aac'),
          ],
        ),
      );

      await session.loadLocalFile(
        '/media/movie.mp4',
        audioStreamIndex: 1,
        caps: _caps,
      );

      expect(session.activeAudioIndex, 1);
      expect(session.audioTracks, hasLength(2));
    });

    test('a repeated load deletes the previous prepared directory', () async {
      await start(probe: _probe(container: 'matroska'));

      await session.loadLocalFile('/media/one.mkv', caps: _caps);
      final first = preparer.prepared.single.directory;
      expect(await first.exists(), isTrue);

      await session.loadLocalFile('/media/two.mkv', caps: _caps);
      expect(preparer.prepared, hasLength(2));
      expect(await first.exists(), isFalse);
      expect(await preparer.prepared.last.directory.exists(), isTrue);
    });
  });

  group('switchLiveAudio', () {
    test('rebuilds HLS at the requested position and changes audio', () async {
      await start(
        probe: _probe(
          container: 'matroska',
          audio: const [
            AudioStream(index: 1, trackIndex: 0, codec: 'aac', isDefault: true),
            AudioStream(index: 2, trackIndex: 1, codec: 'aac'),
          ],
        ),
      );
      await session.loadLocalFile('/media/movie.mkv', caps: _caps);
      expect(preparer.calls.single.kind, 'mp4');

      await session.switchLiveAudio(
        filePath: '/media/movie.mkv',
        audioIndex: 1,
        position: const Duration(seconds: 60),
        streamType: 'BUFFERED',
      );

      expect(preparer.calls, hasLength(2));
      expect(preparer.calls.last.kind, 'hls');
      expect(preparer.calls.last.audioIndex, 1);
      expect(session.activeAudioIndex, 1);
      // 60 s of a 120 s file is the AirPlay 1 fraction 0.5.
      expect(server.lastPlayStartPosition, closeTo(0.5, 0.0001));
    });

    test(
      'rejects an out-of-range audio index without touching the stream',
      () async {
        await start(probe: _probe(container: 'matroska'));
        await session.loadLocalFile('/media/movie.mkv', caps: _caps);

        await expectLater(
          session.switchLiveAudio(
            filePath: '/media/movie.mkv',
            audioIndex: 4,
            position: Duration.zero,
            streamType: 'BUFFERED',
          ),
          throwsArgumentError,
        );
        expect(preparer.calls, hasLength(1));
      },
    );

    test('rejects receivers without HLS support', () async {
      await start(probe: _probe(container: 'matroska'), features: '0x1');
      await session.loadLocalFile('/media/movie.mkv', caps: _caps);

      await expectLater(
        session.switchLiveAudio(
          filePath: '/media/movie.mkv',
          audioIndex: 0,
          position: Duration.zero,
          streamType: 'BUFFERED',
        ),
        throwsA(isA<UnsupportedFeatureException>()),
      );
    });
  });

  group('switchLiveSubtitle', () {
    test('attaches a subtitle and reloads at the current position', () async {
      await start();
      await session.loadLocalFile(
        '/media/movie.mp4',
        caps: _caps,
        subtitle: const CastSubtitle(
          url: '/media/one.vtt',
          label: 'English',
          language: 'en',
          format: 'vtt',
        ),
      );

      await session.switchLiveSubtitle(
        subtitle: const CastSubtitle(
          url: '/media/two.vtt',
          label: 'Spanish',
          language: 'es',
          format: 'vtt',
        ),
        position: const Duration(seconds: 30),
      );

      expect(preparer.calls, hasLength(2));
      expect(preparer.calls.last.kind, 'hls');
      expect(preparer.calls.last.subtitle?.label, 'Spanish');
      expect(server.lastPlayStartPosition, closeTo(0.25, 0.0001));
    });

    test('clears the subtitle by rebuilding without a rendition', () async {
      await start();
      await session.loadLocalFile(
        '/media/movie.mp4',
        caps: _caps,
        subtitle: const CastSubtitle(
          url: '/media/one.vtt',
          label: 'English',
          language: 'en',
          format: 'vtt',
        ),
      );

      await session.switchLiveSubtitle(
        subtitle: null,
        position: const Duration(seconds: 10),
      );

      expect(preparer.calls.last.subtitle, isNull);
      expect(server.lastPlayStartPosition, isNotNull);
    });

    test('reports unsupported without HLS support', () async {
      await start(features: '0x1');
      await session.loadLocalFile('/media/movie.mp4', caps: _caps);

      await expectLater(
        session.switchLiveSubtitle(
          subtitle: const CastSubtitle(
            url: '/media/one.vtt',
            label: 'English',
            language: 'en',
            format: 'vtt',
          ),
          position: Duration.zero,
        ),
        throwsA(isA<UnsupportedFeatureException>()),
      );
    });
  });

  group('volume', () {
    test('sends /volume when the receiver advertises bit 3', () async {
      await start(features: _volumeFeatures);

      await session.setVolume(0.4);

      expect(server.lastPath, '/volume');
      expect(server.volume, closeTo(0.4, 0.001));
      expect(session.volume, closeTo(0.4, 0.001));
    });
  });

  group('playback reporting', () {
    test('a duration-less report does not erase the probed duration', () async {
      await start();
      server.includePlaybackDuration = false;
      server.playbackPosition = 12;

      await session.loadLocalFile('/media/movie.mp4', caps: _caps);
      final duration = await session.durationStream
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 5));

      expect(duration, const Duration(seconds: 120));
    });

    test('a stale poll from a replaced load is discarded', () async {
      await start();
      server.playbackPosition = 500;
      server.playbackInfoDelaySeconds = 0.3;

      await session.loadLocalFile('/media/one.mp4', caps: _caps);
      while (server.playbackInfoRequests == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Replace the load while the first poll is still in flight.
      server.playbackPosition = 10;
      await session.loadLocalFile('/media/two.mp4', caps: _caps);

      // Let the in-flight poll from load one answer.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(session.position, isNot(const Duration(seconds: 500)));
    });
  });
}
