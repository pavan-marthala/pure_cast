import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:test/test.dart';

void main() {
  test('default audio index picks default stream', () {
    final p = MediaProbe.fromJson({
      'format': {'format_name': 'mkv', 'duration': '10'},
      'streams': [
        {'codec_type': 'video', 'codec_name': 'h264', 'level': 41},
        {'codec_type': 'audio', 'index': 1, 'codec_name': 'dts', 'disposition': {'default': 1}},
        {'codec_type': 'audio', 'index': 2, 'codec_name': 'aac', 'disposition': {'default': 0}},
      ],
    });
    final plan = decide(p, const CastDeviceCaps());
    if (plan is RemuxAudioPlan) {
      expect(plan.audioStreamIndex, 0);
    } else {
      fail('expected remuxAudio got ${plan.runtimeType}');
    }
  });
}
