import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/cast_exceptions.dart';
import '../../core/cast_decision.dart';
import '../../core/cast_ffmpeg_commands.dart';
import '../../core/cast_media.dart';
import '../../core/ffmpeg_runner.dart';
import '../../core/hls_master_playlist.dart';
import '../../core/media_probe.dart';
import '../../core/webvtt_hls_segmenter.dart';
import '../../utils/logger.dart';

/// A local file prepared for AirPlay playback.
///
/// Exactly one of [path] refers to an MP4 file or an HLS master playlist,
/// selected by [type]. The whole [directory] is temporary and is deleted by
/// [dispose].
class AirPlayPreparedMedia {
  /// Name of the temporary directory (also used as the HLS route id).
  final String sessionId;

  /// Temporary directory holding the prepared output.
  final Directory directory;

  /// Absolute path of the MP4 file or HLS master playlist.
  final String path;

  /// What [path] points at.
  final CastMediaType type;

  /// Source duration, when known.
  final Duration? duration;

  /// Audio tracks that were prepared, in source order.
  final List<AudioStream> audioTracks;

  /// 0-based audio index selected in the output.
  final int audioIndex;

  /// Subtitle embedded as an HLS rendition, when any.
  final CastSubtitle? subtitle;

  const AirPlayPreparedMedia({
    required this.sessionId,
    required this.directory,
    required this.path,
    required this.type,
    required this.duration,
    required this.audioTracks,
    required this.audioIndex,
    required this.subtitle,
  });

  /// Deletes the prepared directory. Never throws.
  Future<void> dispose() async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      CastLogger.debug(
        'AirPlay prepare: could not delete ${directory.path}: $e',
      );
    }
  }
}

/// Prepares local media for an AirPlay receiver.
///
/// The default implementation runs FFmpeg. Tests inject a fake so planning and
/// session behaviour can be verified without starting FFmpeg.
abstract interface class AirPlayMediaPreparer {
  /// Remuxes or transcodes [inputPath] into a single fast-start MP4.
  Future<AirPlayPreparedMedia> prepareMp4({
    required String inputPath,
    required int audioIndex,
    required List<AudioStream> audioTracks,
    required bool transcodeVideo,
    required bool transcodeAudio,
    CastDeviceCaps caps = const CastDeviceCaps(),
    Duration? duration,
    CastSubtitle? subtitle,
  });

  /// Builds a VOD HLS directory with video, audio and subtitle renditions.
  Future<AirPlayPreparedMedia> prepareHls({
    required String inputPath,
    required int audioIndex,
    required List<AudioStream> audioTracks,
    required bool transcodeVideo,
    CastDeviceCaps caps = const CastDeviceCaps(),
    Duration? duration,
    CastSubtitle? subtitle,
  });
}

/// FFmpeg-backed [AirPlayMediaPreparer].
class FfmpegAirPlayPreparer implements AirPlayMediaPreparer {
  final FfmpegRunner _runner;

  const FfmpegAirPlayPreparer({FfmpegRunner? runner})
    : _runner = runner ?? const FFmpegKitRunner();

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
    final directory = await _newDirectory();
    try {
      final output = '${directory.path}/media.mp4';
      final args =
          transcodeVideo
              ? CastFfmpegCommands.transcodeMp4(
                input: inputPath,
                output: output,
                audioStreamIndex: audioIndex,
                videoEncoder: _videoEncoder(caps),
              )
              : CastFfmpegCommands.remuxMp4(
                input: inputPath,
                output: output,
                audioStreamIndex: audioIndex,
                transcodeAudio: transcodeAudio,
              );
      await _run(args, label: 'mp4');
      return AirPlayPreparedMedia(
        sessionId: _leaf(directory),
        directory: directory,
        path: output,
        type: CastMediaType.mp4,
        duration: duration,
        audioTracks: audioTracks,
        audioIndex: audioIndex,
        subtitle: subtitle,
      );
    } catch (_) {
      await _delete(directory);
      rethrow;
    }
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
    final directory = await _newDirectory();
    try {
      await _run(
        CastFfmpegCommands.hlsVideo(
          input: inputPath,
          outputDir: directory.path,
          transcodeVideo: transcodeVideo,
          videoEncoder: _videoEncoder(caps),
        ),
        label: 'hls video',
      );

      final audioRenditions = <HlsAudioRendition>[];
      for (var i = 0; i < audioTracks.length; i++) {
        final name = 'audio_$i';
        await _run(
          CastFfmpegCommands.hlsAudio(
            input: inputPath,
            outputDir: directory.path,
            audioStreamIndex: i,
            name: name,
          ),
          label: 'hls audio $i',
        );
        audioRenditions.add(
          HlsAudioRendition(
            name: _audioName(audioTracks[i], i),
            language: _language(audioTracks[i].language),
            uri: '$name.m3u8',
            isDefault: i == audioIndex,
            channels: audioTracks[i].channels,
          ),
        );
      }

      final subtitleRenditions = <HlsSubtitleRendition>[];
      if (subtitle != null) {
        final vtt = await _readText(subtitle.url);
        final result = WebVttHlsSegmenter.segment(
          vtt,
          durationSeconds:
              duration == null ? null : duration.inMilliseconds / 1000.0,
          fileNamePrefix: 'sub_0',
        );
        for (final segment in result.segments) {
          await File(
            '${directory.path}/${segment.name}',
          ).writeAsString(segment.content);
        }
        await File(
          '${directory.path}/sub_0.m3u8',
        ).writeAsString(result.playlist);
        subtitleRenditions.add(
          HlsSubtitleRendition(
            name: subtitle.label,
            language: _language(subtitle.language),
            uri: 'sub_0.m3u8',
            isDefault: true,
          ),
        );
      }

      final master = HlsMasterPlaylistWriter.build(
        videoUri: 'video.m3u8',
        audio: audioRenditions,
        subtitles: subtitleRenditions,
      );
      final masterPath = '${directory.path}/index.m3u8';
      await File(masterPath).writeAsString(master);

      return AirPlayPreparedMedia(
        sessionId: _leaf(directory),
        directory: directory,
        path: masterPath,
        type: CastMediaType.hls,
        duration: duration,
        audioTracks: audioTracks,
        audioIndex: audioIndex,
        subtitle: subtitle,
      );
    } catch (_) {
      await _delete(directory);
      rethrow;
    }
  }

  Future<Directory> _newDirectory() async {
    final root = await getTemporaryDirectory();
    final dir = Directory(
      '${root.path}/airplay_prepare_${DateTime.now().microsecondsSinceEpoch}',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _run(List<String> args, {required String label}) async {
    CastLogger.info('AirPlay prepare: $label');
    final job = await _runner.start(args);
    final result = await job.done;
    if (!result.success) {
      final logs = result.logs ?? '';
      final tail =
          logs.length > 1200 ? logs.substring(logs.length - 1200) : logs;
      CastLogger.error(
        'AirPlay prepare: $label failed '
        '(code=${result.returnCode})\n$tail',
      );
      throw PrepareFailedException(
        'AirPlay $label preparation failed'
        '${result.returnCode == null ? '' : ' (code ${result.returnCode})'}',
      );
    }
  }

  static String _videoEncoder(CastDeviceCaps caps) {
    if (caps.hasH264Mediacodec) return 'h264_mediacodec';
    return 'libx264';
  }

  static String _audioName(AudioStream stream, int index) {
    final title = stream.title;
    if (title != null && title.isNotEmpty) return title;
    final language = stream.language;
    if (language != null && language.isNotEmpty && language != 'und') {
      return language.toUpperCase();
    }
    return 'Audio ${index + 1}';
  }

  static String? _language(String? language) {
    if (language == null || language.isEmpty || language == 'und') return null;
    return language;
  }

  static String _leaf(Directory directory) =>
      directory.path.split(Platform.pathSeparator).last;

  static Future<void> _delete(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } catch (_) {}
  }

  static Future<String> _readText(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException('subtitle returned ${response.statusCode}');
        }
        return await response.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    }
    final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
    return File(path).readAsString();
  }
}
