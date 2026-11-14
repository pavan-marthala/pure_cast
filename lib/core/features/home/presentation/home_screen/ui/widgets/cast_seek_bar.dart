import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_utils.dart';

/// Shared thin seek bar used by the mini player and the media controller.
///
/// It only dispatches [SeekMediaEvent] when the drag ends: dragging updates a
/// local value so the position label follows the finger.
class CastSeekBar extends StatefulWidget {
  const CastSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.canSeek,
    required this.restarting,
    this.seekPreview,
  });

  final Duration position;
  final Duration duration;
  final bool canSeek;

  /// True while a live restart (seek or audio switch) is in flight.
  final bool restarting;

  /// Pending relative-seek target shown instead of [position] until committed.
  final Duration? seekPreview;

  @override
  State<CastSeekBar> createState() => _CastSeekBarState();
}

class _CastSeekBarState extends State<CastSeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    final maxMs = widget.duration.inMilliseconds;
    final enabled = widget.canSeek && maxMs > 0;

    final currentMs =
        _dragValue ??
        (widget.seekPreview ?? widget.position).inMilliseconds.toDouble();
    final clampedMs = maxMs > 0 ? currentMs.clamp(0, maxMs).toDouble() : 0.0;
    final shownPosition = Duration(milliseconds: clampedMs.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: colors.white,
            inactiveTrackColor: colors.white.withValues(alpha: 0.2),
            thumbColor: colors.primary,
            overlayColor: colors.white.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: clampedMs,
            max: maxMs > 0 ? maxMs.toDouble() : 1.0,
            onChanged: enabled
                ? (value) => setState(() => _dragValue = value)
                : null,
            onChangeStart: enabled
                ? (value) => setState(() => _dragValue = value)
                : null,
            onChangeEnd: enabled
                ? (value) {
                    setState(() => _dragValue = null);
                    context.read<CastSessionBloc>().add(
                      CastSessionEvent.seekMedia(
                        Duration(milliseconds: value.round()),
                      ),
                    );
                  }
                : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Text(
                  formatDuration(shownPosition),
                  style: typo.labelSmall.copyWith(color: colors.white),
                ),
                if (widget.restarting)
                  SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colors.white,
                    ),
                  ),
              ],
            ),
            Text(
              formatDuration(widget.duration),
              style: typo.labelSmall.copyWith(color: colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
