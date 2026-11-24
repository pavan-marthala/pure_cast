import 'package:dart_cast/src/core/hls_parser.dart';
import 'package:dart_cast/src/core/webvtt_hls_segmenter.dart';
import 'package:test/test.dart';

const _vtt = '''WEBVTT

00:00:01.000 --> 00:00:03.000
Hello

00:00:07.000 --> 00:00:09.500
World

00:00:12.000 --> 00:00:14.000
Bye
''';

void main() {
  group('WebVttHlsSegmenter', () {
    test('splits cues into segments on the media timeline', () {
      final result = WebVttHlsSegmenter.segment(_vtt, durationSeconds: 18);
      expect(result.segments, hasLength(3));
      expect(result.segments[0].content, contains('Hello'));
      expect(result.segments[0].content, isNot(contains('World')));
      expect(result.segments[1].content, contains('World'));
      expect(result.segments[2].content, contains('Bye'));
    });

    test('advertises a valid target duration instead of 99999', () {
      final result = WebVttHlsSegmenter.segment(_vtt, durationSeconds: 18);
      expect(result.targetDuration, 6);
      expect(result.playlist, contains('#EXT-X-TARGETDURATION:6'));
      expect(result.playlist, isNot(contains('99999')));
    });

    test('ends the playlist and lists every segment', () {
      final result = WebVttHlsSegmenter.segment(_vtt, durationSeconds: 18);
      expect(HlsParser.isMasterPlaylist(result.playlist), isFalse);
      expect(result.playlist, contains('#EXT-X-PLAYLIST-TYPE:VOD'));
      expect(result.playlist, contains('#EXT-X-ENDLIST'));
      for (final segment in result.segments) {
        expect(result.playlist, contains(segment.name));
        expect(segment.content, startsWith('WEBVTT'));
      }
    });

    test('derives duration from the last cue when none is supplied', () {
      final result = WebVttHlsSegmenter.segment(_vtt);
      expect(result.segments, hasLength(3));
      expect(result.playlist, contains('#EXT-X-TARGETDURATION:6'));
    });

    test('keeps the final segment shorter than the target', () {
      final result = WebVttHlsSegmenter.segment(_vtt, durationSeconds: 14);
      expect(result.segments.last.durationSeconds, closeTo(2, 0.001));
    });

    test('rejects a non-WebVTT source', () {
      expect(
        () => WebVttHlsSegmenter.segment('1\n00:00:01,000 --> 00:00:02,000'),
        throwsFormatException,
      );
    });

    test('uses the requested file prefix', () {
      final result = WebVttHlsSegmenter.segment(
        _vtt,
        durationSeconds: 18,
        fileNamePrefix: 'track_2',
      );
      expect(result.segments.first.name, 'track_2_00000.vtt');
    });
  });
}
