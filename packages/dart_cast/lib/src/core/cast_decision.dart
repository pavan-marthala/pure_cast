import 'media_probe.dart';
import 'cast_media.dart';
sealed class CastPlan {}

class DirectPlan extends CastPlan {
  final String reason;
  DirectPlan(this.reason);
}

class RemuxAudioPlan extends CastPlan {
  final String reason;
  final int audioStreamIndex;
  RemuxAudioPlan(this.reason, {this.audioStreamIndex = 0});
}

class RemuxContainerPlan extends CastPlan {
  final String reason;
  final int audioStreamIndex;
  RemuxContainerPlan(this.reason, {this.audioStreamIndex = 0});
}

class TranscodeVideoPlan extends CastPlan {
  final String reason;
  final int audioStreamIndex;
  TranscodeVideoPlan(this.reason, {this.audioStreamIndex = 0});
}

class UnsupportedPlan extends CastPlan {
  final String reason;
  UnsupportedPlan(this.reason);
}

class CastDeviceCaps {
  final bool supportsHevc;
  final bool hasH264Encoder;
  final bool hasH264Mediacodec;
  final String? modelName;
  const CastDeviceCaps({
    this.supportsHevc = false,
    this.hasH264Encoder = false,
    this.hasH264Mediacodec = false,
    this.modelName,
  });
}

class CastCompat {
  static const h264Codecs = {'h264', 'avc', 'avc1'};
  static const vp9Codecs = {'vp9', 'vp09'};
  static const hevcCodecs = {'hevc', 'hvc1', 'hev1'};
  static const compatibleAudio = {'aac', 'mp3', 'ac3', 'mp2'};
  static const incompatibleAudio = {'dts', 'truehd', 'eac3', 'flac', 'vorbis', 'opus'};
  static const directContainers = {'mp4', 'webm', 'mkv', 'mov', 'matroska', 'mov,mp4,m4a,3gp,3g2,mj2'};
  static const remuxContainers = {'avi', 'ts', 'm2ts', 'wmv', 'flv'};

  static CastMediaType mediaTypeForContainer(String container) {
    final c = container.split(',').first.trim().toLowerCase();
    switch (c) {
      case 'matroska':
      case 'mkv':
        return CastMediaType.mkv;
      case 'webm':
      case 'mp4':
      case 'mov':
      default:
        return CastMediaType.mp4;
    }
  }
}

CastPlan decide(MediaProbe probe, CastDeviceCaps caps) {
  final v = probe.video;
  if (v == null) return UnsupportedPlan('no video stream');
  final audioIdx = _defaultAudioIndex(probe.audio);
  final vCodec = v.codec.toLowerCase();
  final isH264 = CastCompat.h264Codecs.contains(vCodec);
  final isVp9 = CastCompat.vp9Codecs.contains(vCodec);
  final isHevc = CastCompat.hevcCodecs.contains(vCodec);
  final videoCompatible = (isH264 && (v.level == null || v.level! <= 42)) ||
      isVp9 ||
      (isHevc && caps.supportsHevc);
  AudioStream? audio;
  if (probe.audio.isNotEmpty) {
    final idx = audioIdx < probe.audio.length ? audioIdx : 0;
    audio = probe.audio[idx];
  }
  final audioCompatible = audio == null || CastCompat.compatibleAudio.contains(audio.codec.toLowerCase());
  final audioIncompatible = audio != null && CastCompat.incompatibleAudio.contains(audio.codec.toLowerCase());
  final containerOk = CastCompat.directContainers.contains(probe.container.split(',').first.trim().toLowerCase());

  if (!videoCompatible) {
    if (!caps.hasH264Encoder) return UnsupportedPlan('video codec ${v.codec} not supported and no H.264 encoder');
    return TranscodeVideoPlan('video codec ${v.codec} needs transcode', audioStreamIndex: audioIdx);
  }
  if (audioIncompatible) {
    return RemuxAudioPlan('audio codec ${audio!.codec} needs remux to AAC', audioStreamIndex: audioIdx);
  }
  if (!containerOk) {
    return RemuxContainerPlan('container ${probe.container} needs remux', audioStreamIndex: audioIdx);
  }
  if (!audioCompatible && !audioIncompatible) {
    return RemuxAudioPlan('unknown audio codec ${audio?.codec}', audioStreamIndex: audioIdx);
  }
  return DirectPlan('direct play compatible');
}

int _defaultAudioIndex(List<AudioStream> audio) {
  for (var i = 0; i < audio.length; i++) {
    if (audio[i].isDefault) return i;
  }
  return 0;
}
