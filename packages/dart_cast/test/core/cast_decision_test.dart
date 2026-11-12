import 'dart:convert';
import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:test/test.dart';

void main() {
  test('H264 AAC MKV -> direct', () {
    final probe = MediaProbe.fromJson(
      jsonDecode('''
    {"format":{"format_name":"matroska","duration":"10.0"},"streams":[
      {"codec_type":"video","codec_name":"h264","profile":"High","level":41,"pix_fmt":"yuv420p","width":1920,"height":1080,"r_frame_rate":"24/1"},
      {"codec_type":"audio","index":1,"codec_name":"aac","channels":2,"tags":{"language":"eng"},"disposition":{"default":1}}
    ]}''')
          as Map<String, dynamic>,
    );
    final plan = decide(probe, const CastDeviceCaps());
    expect(plan, isA<DirectPlan>());
  });

  test('H264 DTS MKV -> remux audio', () {
    final probe = MediaProbe.fromJson(
      jsonDecode('''
    {"format":{"format_name":"matroska","duration":"10.0"},"streams":[
      {"codec_type":"video","codec_name":"h264","profile":"High","level":41,"pix_fmt":"yuv420p","width":1920,"height":1080,"r_frame_rate":"24/1"},
      {"codec_type":"audio","index":1,"codec_name":"dts","channels":6,"tags":{"language":"eng"},"disposition":{"default":1}}
    ]}''')
          as Map<String, dynamic>,
    );
    final plan = decide(probe, const CastDeviceCaps());
    expect(plan, isA<RemuxAudioPlan>());
  });

  test('HEVC 10-bit without caps -> unsupported (no encoder)', () {
    final probe = MediaProbe.fromJson(
      jsonDecode('''
    {"format":{"format_name":"matroska","duration":"10.0"},"streams":[
      {"codec_type":"video","codec_name":"hevc","profile":"Main 10","level":120,"pix_fmt":"yuv420p10le","width":1920,"height":1080,"r_frame_rate":"24/1"},
      {"codec_type":"audio","index":1,"codec_name":"aac","channels":2,"tags":{"language":"eng"},"disposition":{"default":1}}
    ]}''')
          as Map<String, dynamic>,
    );
    final plan = decide(probe, const CastDeviceCaps(hasH264Encoder: false));
    expect(plan, isA<UnsupportedPlan>());
  });

  test('AVI H264 AAC -> remux container', () {
    final probe = MediaProbe.fromJson(
      jsonDecode('''
    {"format":{"format_name":"avi","duration":"10.0"},"streams":[
      {"codec_type":"video","codec_name":"h264","profile":"High","level":41,"pix_fmt":"yuv420p","width":1920,"height":1080,"r_frame_rate":"24/1"},
      {"codec_type":"audio","index":1,"codec_name":"aac","channels":2,"tags":{"language":"eng"},"disposition":{"default":1}}
    ]}''')
          as Map<String, dynamic>,
    );
    final plan = decide(probe, const CastDeviceCaps());
    expect(plan, isA<RemuxContainerPlan>());
  });
}
