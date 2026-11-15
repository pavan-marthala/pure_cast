import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';

class CastFfmpegDiagnostics {
  static Future<void> dumpCapabilities() async {
    await _run('-hide_banner -muxers');
    await _run('-hide_banner -demuxers');
    await _run('-hide_banner -filters');
    await _run('-hide_banner -bsfs');
    await _run('-hide_banner -encoders');
  }

  static Future<String> _run(String cmd) async {
    try {
      final session = await FFmpegKit.execute(cmd);
      return (await session.getOutput()) ?? '';
    } catch (e) {
      debugPrint('[FFDBG] capability query failed: $e');
      return '';
    }
  }

  static Future<void> selfTest(String path) async {
    try {
      final sess = await FFmpegKit.execute(
        '-hide_banner -loglevel error -i $path -t 5 -c copy -f null -',
      );
      await sess.getAllLogsAsString();
    } catch (_) {}
    // probe
    try {
      await FFprobeKit.getMediaInformation(
        path.startsWith('file://') ? Uri.parse(path).toFilePath() : path,
      );
    } catch (_) {}
  }
}
