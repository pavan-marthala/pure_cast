import '../../core/cast_decision.dart';
import '../../core/media_probe.dart';

/// Strategy chosen for playing a local file on an AirPlay receiver.
sealed class AirPlayMediaPlan {
  /// Human-readable reason for the choice (used in logs and errors).
  final String reason;

  const AirPlayMediaPlan(this.reason);
}

/// The original file is a container/codec combination AirPlay plays as-is.
class AirPlayDirectPlan extends AirPlayMediaPlan {
  const AirPlayDirectPlan(super.reason);
}

/// Video is copied and the file is rewrapped as MP4. Audio is copied too
/// because the selected track is already compatible.
class AirPlayContainerRemuxPlan extends AirPlayMediaPlan {
  /// 0-based index among audio streams (`0:a:N`).
  final int audioIndex;

  const AirPlayContainerRemuxPlan(super.reason, {required this.audioIndex});
}

/// Video and container are fine, but the selected audio track needs AAC.
class AirPlayAudioRemuxPlan extends AirPlayMediaPlan {
  /// 0-based index among audio streams (`0:a:N`).
  final int audioIndex;

  const AirPlayAudioRemuxPlan(super.reason, {required this.audioIndex});
}

/// Video needs an H.264 transcode (and, if needed, AAC audio), written as MP4.
class AirPlayTranscodePlan extends AirPlayMediaPlan {
  /// 0-based index among audio streams (`0:a:N`).
  final int audioIndex;

  const AirPlayTranscodePlan(super.reason, {required this.audioIndex});
}

/// Seekable VOD HLS is prepared. Audio is exposed as renditions so it can be
/// selected without re-encoding, and subtitles are exposed as WebVTT
/// renditions.
class AirPlayHlsPlan extends AirPlayMediaPlan {
  /// 0-based index among audio streams (`0:a:N`) to use as the default.
  final int audioIndex;

  /// Whether the video variant itself must be re-encoded.
  final bool transcodeVideo;

  const AirPlayHlsPlan(
    super.reason, {
    required this.audioIndex,
    this.transcodeVideo = false,
  });
}

/// No usable plan exists (for example, no video stream or no encoder).
class AirPlayUnsupportedPlan extends AirPlayMediaPlan {
  const AirPlayUnsupportedPlan(super.reason);
}

/// AirPlay-compatible containers (first `format_name` component).
const Set<String> airPlayDirectContainers = {
  'mp4',
  'mov',
  'm4v',
  'mov,mp4,m4a,3gp,3g2,mj2',
};

/// AirPlay-compatible video codecs.
const Set<String> airPlayVideoCodecs = {'h264', 'avc', 'avc1'};

/// AirPlay-compatible audio codecs for a direct MP4.
///
/// AC-3 is deliberately excluded: only some receivers decode it, and the
/// shared Chromecast/DLNA decision treats it as universally safe.
const Set<String> airPlayAudioCodecs = {'aac', 'mp3', 'mp2'};

/// Whether [probe]'s video can be copied into an MP4 without re-encoding.
bool isAirPlayVideoCompatible(VideoStream video) {
  if (!airPlayVideoCodecs.contains(video.codec.toLowerCase())) return false;
  if (bitDepthOf(video.pixFmt) >= 10) return false;
  final level = video.level;
  return level == null || level <= 42;
}

/// Whether [probe]'s container can be handed to AirPlay directly.
bool isAirPlayContainerCompatible(String container) {
  return airPlayDirectContainers.contains(
    container.split(',').first.trim().toLowerCase(),
  );
}

/// Picks the cheapest way to play a probed local file on an AirPlay receiver.
///
/// [audioIndex] is the requested 0-based index among audio streams. When it is
/// out of range the default/first audio stream is used instead.
///
/// [subtitlesRequested] and [forceHls] both select seekable VOD HLS: subtitles
/// need an HLS rendition, and a track switch rebuilds the stream as HLS so the
/// audio group can hold every track.
///
/// Transcoding is only chosen when [caps] reports an H.264 encoder and
/// `transcodeEnabled`.
AirPlayMediaPlan planAirPlayMedia(
  MediaProbe probe, {
  int audioIndex = 0,
  bool subtitlesRequested = false,
  bool forceHls = false,
  CastDeviceCaps caps = const CastDeviceCaps(),
}) {
  final video = probe.video;
  if (video == null) {
    return const AirPlayUnsupportedPlan('no video stream');
  }

  final selectedAudio = _selectAudio(probe.audio, audioIndex);
  final effectiveIndex = selectedAudio?.trackIndex ?? 0;
  final videoOk = isAirPlayVideoCompatible(video);
  final containerOk = isAirPlayContainerCompatible(probe.container);
  final audioOk =
      selectedAudio == null ||
      airPlayAudioCodecs.contains(selectedAudio.codec.toLowerCase());
  final canTranscode =
      caps.transcodeEnabled &&
      (caps.hasH264Encoder || caps.hasLibx264 || caps.hasH264Mediacodec);

  if (subtitlesRequested || forceHls) {
    if (!videoOk && !canTranscode) {
      return AirPlayUnsupportedPlan(
        'video codec ${video.codec} needs a transcode, but no usable '
        'H.264 encoder is available',
      );
    }
    return AirPlayHlsPlan(
      subtitlesRequested
          ? 'subtitles need a seekable HLS rendition'
          : 'track switching needs a seekable HLS rendition',
      audioIndex: effectiveIndex,
      transcodeVideo: !videoOk,
    );
  }

  if (!videoOk) {
    if (!canTranscode) {
      return AirPlayUnsupportedPlan(
        'video codec ${video.codec} needs a transcode, but no usable '
        'H.264 encoder is available',
      );
    }
    return AirPlayTranscodePlan(
      'video codec ${video.codec} needs an H.264 transcode',
      audioIndex: effectiveIndex,
    );
  }

  if (!containerOk) {
    return AirPlayContainerRemuxPlan(
      'container ${probe.container} needs an MP4 remux',
      audioIndex: effectiveIndex,
    );
  }

  if (!audioOk) {
    return AirPlayAudioRemuxPlan(
      'audio codec ${selectedAudio.codec} needs an AAC remux',
      audioIndex: effectiveIndex,
    );
  }

  return const AirPlayDirectPlan('direct play compatible');
}

AudioStream? _selectAudio(List<AudioStream> audio, int requested) {
  if (audio.isEmpty) return null;
  if (requested >= 0 && requested < audio.length) return audio[requested];
  for (final stream in audio) {
    if (stream.isDefault) return stream;
  }
  return audio.first;
}
