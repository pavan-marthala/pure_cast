import 'package:dart_cast/src/core/media_probe.dart';
import 'package:test/test.dart';

Map<String, dynamic> _probeJson() => {
  'format': {'format_name': 'matroska,webm', 'duration': '123.456000'},
  'streams': [
    {
      'codec_type': 'video',
      'codec_name': 'h264',
      'profile': 'High',
      'level': 41,
      'pix_fmt': 'yuv420p',
      'width': 1920,
      'height': 1080,
      'r_frame_rate': '24/1',
      'index': 0,
    },
    {
      'codec_type': 'audio',
      'codec_name': 'aac',
      'channels': 6,
      'index': 1,
      'tags': {'language': 'eng', 'title': 'English 5.1'},
      'disposition': {'default': 1},
    },
    {
      'codec_type': 'subtitle',
      'codec_name': 'subrip',
      'index': 2,
      'tags': {'language': 'eng', 'title': 'English SDH'},
    },
    {
      'codec_type': 'audio',
      'codec_name': 'ac3',
      'channels': 2,
      'index': 3,
      'tags': {'language': 'spa'},
      'disposition': {'default': 0},
    },
    {'codec_type': 'subtitle', 'codec_name': 'hdmv_pgs_subtitle', 'index': 4},
    {
      'codec_type': 'subtitle',
      'codec_name': 'ass',
      'index': 5,
      'tags': {'title': 'Signs only'},
    },
  ],
};

void main() {
  group('MediaProbe.fromJson', () {
    test('assigns absolute index and 0-based trackIndex per stream type', () {
      final probe = MediaProbe.fromJson(_probeJson());

      expect(probe.container, 'matroska,webm');
      expect(probe.durationSeconds, 123.456);
      expect(probe.duration, const Duration(microseconds: 123456000));
      expect(probe.hasSubtitles, isTrue);

      expect(probe.audio, hasLength(2));
      expect(probe.audio[0].index, 1);
      expect(probe.audio[0].trackIndex, 0);
      expect(probe.audio[0].codec, 'aac');
      expect(probe.audio[0].channels, 6);
      expect(probe.audio[0].language, 'eng');
      expect(probe.audio[0].title, 'English 5.1');
      expect(probe.audio[0].isDefault, isTrue);

      expect(probe.audio[1].index, 3);
      expect(probe.audio[1].trackIndex, 1);
      expect(probe.audio[1].codec, 'ac3');
      expect(probe.audio[1].channels, 2);
      expect(probe.audio[1].language, 'spa');
      expect(probe.audio[1].title, isNull);
      expect(probe.audio[1].isDefault, isFalse);

      expect(probe.subtitles, hasLength(3));
      expect(probe.subtitles.map((s) => s.index), [2, 4, 5]);
      expect(probe.subtitles.map((s) => s.trackIndex), [0, 1, 2]);
    });

    test('reads subtitle codec, language, title and image-based flag', () {
      final probe = MediaProbe.fromJson(_probeJson());

      final subrip = probe.subtitles[0];
      expect(subrip.codec, 'subrip');
      expect(subrip.language, 'eng');
      expect(subrip.title, 'English SDH');
      expect(subrip.isImageBased, isFalse);
      expect(subrip.displayLabel, 'ENG (SUBRIP)');

      final pgs = probe.subtitles[1];
      expect(pgs.codec, 'hdmv_pgs_subtitle');
      expect(pgs.language, isNull);
      expect(pgs.title, isNull);
      expect(pgs.isImageBased, isTrue);
      expect(pgs.displayLabel, 'Unknown (HDMV_PGS_SUBTITLE)');

      final ass = probe.subtitles[2];
      expect(ass.codec, 'ass');
      expect(ass.language, isNull);
      expect(ass.title, 'Signs only');
      expect(ass.isImageBased, isFalse);
      expect(ass.displayLabel, 'Unknown (ASS)');
    });

    test('is tolerant of missing tags, disposition, index and codec', () {
      final probe = MediaProbe.fromJson({
        'streams': [
          {'codec_type': 'audio'},
          {'codec_type': 'subtitle', 'index': 7},
        ],
      });

      expect(probe.container, '');
      expect(probe.durationSeconds, isNull);
      expect(probe.duration, isNull);

      expect(probe.audio.single.index, -1);
      expect(probe.audio.single.trackIndex, 0);
      expect(probe.audio.single.codec, 'unknown');
      expect(probe.audio.single.channels, 2);
      expect(probe.audio.single.language, isNull);
      expect(probe.audio.single.title, isNull);
      expect(probe.audio.single.isDefault, isFalse);

      expect(probe.subtitles.single.index, 7);
      expect(probe.subtitles.single.trackIndex, 0);
      expect(probe.subtitles.single.codec, 'unknown');
      expect(probe.subtitles.single.isImageBased, isFalse);
      expect(probe.subtitles.single.displayLabel, 'Unknown (UNKNOWN)');
    });

    test('handles an empty map and no streams', () {
      final probe = MediaProbe.fromJson(const {});

      expect(probe.container, '');
      expect(probe.video, isNull);
      expect(probe.audio, isEmpty);
      expect(probe.subtitles, isEmpty);
      expect(probe.hasSubtitles, isFalse);
      expect(probe.duration, isNull);
    });

    test('direct constructors keep working without the new fields', () {
      const audio = AudioStream(index: 2, codec: 'ac3');
      const subtitle = SubtitleStream(index: 3, codec: 'subrip');
      const probe = MediaProbe(container: 'mp4', audio: [audio]);

      expect(audio.trackIndex, -1);
      expect(audio.title, isNull);
      expect(subtitle.trackIndex, -1);
      expect(subtitle.isImageBased, isFalse);
      expect(subtitle.displayLabel, 'Unknown (SUBRIP)');
      expect(probe.hasSubtitles, isFalse);
    });
  });
}
