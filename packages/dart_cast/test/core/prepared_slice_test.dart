import 'dart:convert';
import 'package:dart_cast/src/core/cast_decision.dart';
import 'package:dart_cast/src/core/cast_ffmpeg_commands.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:test/test.dart';

void main() {
  test('decide H264 AAC MKV -> direct', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"matroska","duration":"10"},"streams":[{"codec_type":"video","codec_name":"h264","level":41},{"codec_type":"audio","index":1,"codec_name":"aac","disposition":{"default":1}}]}',
          )
          as Map<String, dynamic>,
    );
    expect(decide(p, const CastDeviceCaps()), isA<DirectPlan>());
  });
  test('decide H264 DTS MKV -> remuxAudio', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"matroska","duration":"10"},"streams":[{"codec_type":"video","codec_name":"h264","level":41},{"codec_type":"audio","index":1,"codec_name":"dts","disposition":{"default":1}}]}',
          )
          as Map<String, dynamic>,
    );
    expect(decide(p, const CastDeviceCaps()), isA<RemuxAudioPlan>());
  });
  test('decide HEVC 10-bit no encoder -> unsupported', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"matroska","duration":"10"},"streams":[{"codec_type":"video","codec_name":"hevc","level":120,"pix_fmt":"yuv420p10le"},{"codec_type":"audio","index":1,"codec_name":"aac","disposition":{"default":1}}]}',
          )
          as Map<String, dynamic>,
    );
    expect(
      decide(p, const CastDeviceCaps(hasH264Encoder: false)),
      isA<UnsupportedPlan>(),
    );
  });
  test('decide XviD AVI -> unsupported without encoder', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"avi","duration":"10"},"streams":[{"codec_type":"video","codec_name":"mpeg4"},{"codec_type":"audio","index":1,"codec_name":"mp3","disposition":{"default":1}}]}',
          )
          as Map<String, dynamic>,
    );
    final plan = decide(p, const CastDeviceCaps(hasH264Encoder: false));
    expect(plan, isA<UnsupportedPlan>());
  });
  test('decide H264 AAC MOV -> direct', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"mov","duration":"10"},"streams":[{"codec_type":"video","codec_name":"h264","level":41},{"codec_type":"audio","index":1,"codec_name":"aac","disposition":{"default":1}}]}',
          )
          as Map<String, dynamic>,
    );
    expect(decide(p, const CastDeviceCaps()), isA<DirectPlan>());
  });
  test('decide ProRes MOV -> unsupported without encoder', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"mov","duration":"10"},"streams":[{"codec_type":"video","codec_name":"prores"},{"codec_type":"audio","index":1,"codec_name":"aac","disposition":{"default":1}}]}',
          )
          as Map<String, dynamic>,
    );
    expect(
      decide(p, const CastDeviceCaps(hasH264Encoder: false)),
      isA<UnsupportedPlan>(),
    );
  });
  test('decide no audio file', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"mp4","duration":"10"},"streams":[{"codec_type":"video","codec_name":"h264","level":41}]}',
          )
          as Map<String, dynamic>,
    );
    expect(decide(p, const CastDeviceCaps()), isA<DirectPlan>());
  });
  test('mediaTypeForContainer', () {
    expect(CastCompat.mediaTypeForContainer('matroska'), isNotNull);
    expect(CastCompat.mediaTypeForContainer('mp4').name, 'mp4');
  });
  test('command builders include audioStreamIndex', () {
    final a = CastFfmpegCommands.remuxAudio(
      input: 'in.mkv',
      outputDir: '/tmp/out',
      audioStreamIndex: 2,
    );
    expect(a.join(' '), contains('0:a:2'));
    final c = CastFfmpegCommands.remuxContainer(
      input: 'in.avi',
      outputDir: '/tmp/out',
      audioStreamIndex: 1,
    );
    expect(c.join(' '), contains('0:a:1'));
  });
  test('probe parsing multiple audio streams', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"mkv","duration":"10"},"streams":[{"codec_type":"video","codec_name":"h264"},{"codec_type":"audio","index":1,"codec_name":"aac","disposition":{"default":1}},{"codec_type":"audio","index":2,"codec_name":"dts","disposition":{"default":0}}]}',
          )
          as Map<String, dynamic>,
    );
    expect(p.audio.length, 2);
  });
  test('probe parsing no audio', () {
    final p = MediaProbe.fromJson(
      jsonDecode(
            '{"format":{"format_name":"mp4","duration":"10"},"streams":[{"codec_type":"video","codec_name":"h264"}]}',
          )
          as Map<String, dynamic>,
    );
    expect(p.audio, isEmpty);
  });
}

// audio index mapping sanity
void _audioIndexSanity() {}
