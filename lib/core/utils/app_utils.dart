import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  return "$twoDigitMinutes:$twoDigitSeconds";
}

double? resumeProgress(PureCastMedia media, Duration? position) {
  if (position == null) return null;
  final duration = media.duration;
  if (duration == null || duration <= Duration.zero) return null;
  final value = position.inMilliseconds / duration.inMilliseconds;
  if (value <= 0) return null;
  return value.clamp(0.0, 1.0);
}

const Color shimmerBase = Color(0xFF303030);
const Color shimmerHighlight = Color(0xFF505050);

extension DurationFormatting on Duration {
  String toFormattedString() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    if (inHours > 0) {
      return "${twoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
