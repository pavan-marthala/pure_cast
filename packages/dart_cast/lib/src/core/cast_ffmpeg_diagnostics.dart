import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';

class CastFfmpegDiagnostics {
  static Future<void> dumpCapabilities() async {
    final muxers = await _run('-hide_banner -muxers');
    final demuxers = await _run('-hide_banner -demuxers');
    final filters = await _run('-hide_banner -filters');
    final bsfs = await _run('-hide_banner -bsfs');
    final encoders = await _run('-hide_banner -encoders');

    final wantedMuxers = ['hls', 'mpegts', 'mp4', 'mov', 'matroska', 'webm', 'segment', 'dash', 'mpeg', 'h264'];
    final wantedDemuxers = ['matroska', 'avi', 'mov', 'mp4', 'mpegts', 'webm'];
    final wantedFilters = ['scale', 'overlay', 'format', 'aresample'];
    final wantedBsfs = ['h264_mp4toannexb'];
    final wantedEncoders = ['libx264', 'h264_mediacodec', 'aac', 'eac3', 'hevc_mediacodec'];

    for (final m in wantedMuxers) {
      debugPrint('[FFDBG] muxer $m: ${_contains(muxers, m) ? 'YES' : 'NO'}');
    }
    for (final d in wantedDemuxers) {
      debugPrint('[FFDBG] demuxer $d: ${_contains(demuxers, d) ? 'YES' : 'NO'}');
    }
    for (final f in wantedFilters) {
      debugPrint('[FFDBG] filter $f: ${_contains(filters, f) ? 'YES' : 'NO'}');
    }
    for (final b in wantedBsfs) {
      debugPrint('[FFDBG] bsf $b: ${_contains(bsfs, b) ? 'YES' : 'NO'}');
    }
    for (final e in wantedEncoders) {
      debugPrint('[FFDBG] encoder $e: ${_contains(encoders, e) ? 'YES' : 'NO'}');
    }
  }

  static Future<String> _run(String cmd) async {
    try {
      final session = await FFmpegKit.execute(cmd);
      return (await session.getOutput()) ?? '';
    } catch (e) {
      return '';
    }
  }

  static bool _contains(String haystack, String needle) {
    return haystack.toLowerCase().contains(needle.toLowerCase());
  }

  static Future<void> selfTest(String path) async {
    debugPrint('[PREPDBG] selftest (a) demux check');
    try {
      final sess = await FFmpegKit.execute('-hide_banner -loglevel error -i $path -t 5 -c copy -f null -');
      final rc = await sess.getReturnCode();
      final logs = await sess.getAllLogsAsString();
      debugPrint('[PREPDBG] (a) rc=${rc?.getValue()}');
      _chunk(logs);
    } catch (e) {
      debugPrint('[PREPDBG] (a) error: $e');
    }
    // probe
    try {
      final session = await FFprobeKit.getMediaInformation(path.startsWith('file://') ? Uri.parse(path).toFilePath() : path);
      final info = session.getMediaInformation();
      debugPrint('[PREPDBG] probe container=${info?.getFormat()}');
    } catch (e) {
      debugPrint('[PREPDBG] probe error: $e');
    }
  }

  static void _chunk(String? text) {
    if (text == null) return;
    final lines = text.split('\n');
    final tail = lines.length > 40 ? lines.sublist(lines.length - 40) : lines;
    final joined = tail.join('\n');
    for (var i = 0; i < joined.length; i += 800) {
      final end = (i + 800 < joined.length) ? i + 800 : joined.length;
      debugPrint('[PREPDBG] ${joined.substring(i, end)}');
    }
  }
    }
