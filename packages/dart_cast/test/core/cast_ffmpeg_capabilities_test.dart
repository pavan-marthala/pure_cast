import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/cast_ffmpeg_capabilities.dart';
import 'package:test/test.dart';

void main() {
  group('CastFfmpegCapabilities.parseCapabilities', () {
    test('h264_mediacodec present -> hasH264Mediacodec=true, hasH264Encoder=true, transcodeEnabled=true', () {
      final caps = CastFfmpegCapabilities.parseCapabilities(
        'V..... libx264\nV..... h264_mediacodec\nA..... aac',
        'D..... h264\nD..... h264_mediacodec',
        'E muxer hls\nE muxer mpegts\nE muxer mp4',
        'scale  V->V',
      );
      expect(caps.hasH264Mediacodec, isTrue);
      expect(caps.hasH264Encoder, isTrue);
      expect(caps.transcodeEnabled, isTrue);
    });

    test('no H.264 encoder -> all false', () {
      final caps = CastFfmpegCapabilities.parseCapabilities(
        'A..... aac\nA..... eac3',
        'D..... h264',
        'E muxer hls\nE muxer mpegts',
        'scale  V->V',
      );
      expect(caps.hasH264Encoder, isFalse);
      expect(caps.hasH264Mediacodec, isFalse);
      expect(caps.transcodeEnabled, isFalse);
    });

    test('libx264 present (no mediacodec) -> hasH264Encoder=true', () {
      final caps = CastFfmpegCapabilities.parseCapabilities(
        'V..... libx264\nA..... aac',
        'D..... h264',
        'E muxer hls',
        'scale  V->V',
      );
      expect(caps.hasH264Encoder, isTrue);
      expect(caps.hasH264Mediacodec, isFalse);
      expect(caps.transcodeEnabled, isTrue);
    });

    test('supportsHevc always false (receiver knowledge)', () {
      final caps = CastFfmpegCapabilities.parseCapabilities(
        'V..... libx264',
        'D..... h264',
        'E muxer hls',
        'scale  V->V',
      );
      expect(caps.supportsHevc, isFalse);
    });
  });

  group('CastFfmpegCapabilities.detect', () {
    test('detection failure -> conservative fallback (all false)', () async {
      CastFfmpegCapabilities.clearCache();
      final caps = await CastFfmpegCapabilities.detect(
        query: (cmd) async => throw Exception('FFmpegKit unavailable'),
      );
      expect(caps.hasH264Encoder, isFalse);
      expect(caps.hasH264Mediacodec, isFalse);
      expect(caps.transcodeEnabled, isFalse);
      CastFfmpegCapabilities.clearCache();
    });

    test('caching -> detect called twice, query only once', () async {
      CastFfmpegCapabilities.clearCache();
      int callCount = 0;
      Future<String> fakeQuery(String cmd) async {
        callCount++;
        return 'V..... h264_mediacodec\nA..... aac';
      }
      final caps1 = await CastFfmpegCapabilities.detect(query: fakeQuery);
      final caps2 = await CastFfmpegCapabilities.detect(query: fakeQuery);
      expect(identical(caps1, caps2), isTrue);
      expect(callCount, 4);
      CastFfmpegCapabilities.clearCache();
    });
  });
}
