import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:dart_cast/src/protocols/airplay/airplay_media_plan.dart';
import 'package:test/test.dart';

const h264 = VideoStream(codec: 'h264', level: 41, pixFmt: 'yuv420p');
const aac = AudioStream(index: 1, trackIndex: 0, codec: 'aac', isDefault: true);
const ac3 = AudioStream(index: 2, trackIndex: 0, codec: 'ac3', isDefault: true);
const hevc = VideoStream(codec: 'hevc', level: 120, pixFmt: 'yuv420p');

const caps = CastDeviceCaps(
  hasH264Encoder: true,
  hasLibx264: true,
  transcodeEnabled: true,
);

MediaProbe probe({
  String container = 'mp4',
  VideoStream? video = h264,
  List<AudioStream> audio = const [aac],
}) => MediaProbe(
  container: container,
  durationSeconds: 120,
  video: video,
  audio: audio,
);

void main() {
  group('planAirPlayMedia', () {
    test('direct play for H.264/AAC MP4', () {
      final plan = planAirPlayMedia(probe());
      expect(plan, isA<AirPlayDirectPlan>());
    });

    test('direct play ignores multi-audio until a switch is requested', () {
      final plan = planAirPlayMedia(
        probe(
          audio: const [
            AudioStream(index: 1, trackIndex: 0, codec: 'aac'),
            AudioStream(index: 2, trackIndex: 1, codec: 'aac'),
          ],
        ),
      );
      expect(plan, isA<AirPlayDirectPlan>());
    });

    test('container remux for MKV with compatible audio', () {
      final plan = planAirPlayMedia(probe(container: 'matroska'));
      expect(plan, isA<AirPlayContainerRemuxPlan>());
      expect((plan as AirPlayContainerRemuxPlan).audioIndex, 0);
    });

    test('audio remux for AC-3 without re-encoding video', () {
      final plan = planAirPlayMedia(probe(audio: const [ac3]));
      expect(plan, isA<AirPlayAudioRemuxPlan>());
      expect((plan as AirPlayAudioRemuxPlan).audioIndex, 0);
    });

    test('transcode for HEVC when an encoder is available', () {
      final plan = planAirPlayMedia(probe(video: hevc), caps: caps);
      expect(plan, isA<AirPlayTranscodePlan>());
    });

    test('transcode for H.264 above level 4.2', () {
      final plan = planAirPlayMedia(
        probe(
          video: const VideoStream(codec: 'h264', level: 51, pixFmt: 'yuv420p'),
        ),
        caps: caps,
      );
      expect(plan, isA<AirPlayTranscodePlan>());
    });

    test('transcode for 10-bit H.264', () {
      final plan = planAirPlayMedia(
        probe(
          video: const VideoStream(
            codec: 'h264',
            level: 41,
            pixFmt: 'yuv420p10le',
          ),
        ),
        caps: caps,
      );
      expect(plan, isA<AirPlayTranscodePlan>());
    });

    test('unsupported when video needs a transcode and none is enabled', () {
      final plan = planAirPlayMedia(
        probe(video: hevc),
        caps: const CastDeviceCaps(hasH264Encoder: true),
      );
      expect(plan, isA<AirPlayUnsupportedPlan>());
    });

    test('unsupported when there is no video stream', () {
      final plan = planAirPlayMedia(probe(video: null));
      expect(plan, isA<AirPlayUnsupportedPlan>());
    });

    test('subtitle request selects HLS even for a compatible MP4', () {
      final plan = planAirPlayMedia(probe(), subtitlesRequested: true);
      expect(plan, isA<AirPlayHlsPlan>());
      expect((plan as AirPlayHlsPlan).transcodeVideo, isFalse);
    });

    test('forced HLS keeps video copy for compatible video', () {
      final plan = planAirPlayMedia(
        probe(container: 'matroska'),
        forceHls: true,
      );
      expect(plan, isA<AirPlayHlsPlan>());
      expect((plan as AirPlayHlsPlan).transcodeVideo, isFalse);
    });

    test('forced HLS transcodes incompatible video', () {
      final plan = planAirPlayMedia(
        probe(video: hevc),
        forceHls: true,
        caps: caps,
      );
      expect(plan, isA<AirPlayHlsPlan>());
      expect((plan as AirPlayHlsPlan).transcodeVideo, isTrue);
    });

    test('forced HLS fails without an encoder for incompatible video', () {
      final plan = planAirPlayMedia(
        probe(video: hevc),
        forceHls: true,
        caps: const CastDeviceCaps(),
      );
      expect(plan, isA<AirPlayUnsupportedPlan>());
    });

    test('honours the requested audio index', () {
      final plan = planAirPlayMedia(
        probe(
          audio: const [
            AudioStream(index: 1, trackIndex: 0, codec: 'aac'),
            AudioStream(index: 2, trackIndex: 1, codec: 'ac3'),
          ],
        ),
        audioIndex: 1,
      );
      expect(plan, isA<AirPlayAudioRemuxPlan>());
      expect((plan as AirPlayAudioRemuxPlan).audioIndex, 1);
    });

    test('out-of-range audio index falls back to the first track', () {
      final plan = planAirPlayMedia(probe(audio: const [ac3]), audioIndex: 9);
      expect(plan, isA<AirPlayAudioRemuxPlan>());
      expect((plan as AirPlayAudioRemuxPlan).audioIndex, 0);
    });
  });
}
