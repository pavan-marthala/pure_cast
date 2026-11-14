import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

/// Human-readable label for an audio track, e.g. `Hindi · AC3 5.1`.
///
/// Falls back to `Track N` when the container has no language tag.
String audioTrackLabel(PureCastAudioTrack track) {
  final language = _languageName(track.language);
  if (language == null) return 'Track ${track.index + 1}';

  final codec = track.codec.trim().toUpperCase();
  final channels = _channelLayout(track.channels);
  final format = [
    if (codec.isNotEmpty && codec != 'UNKNOWN') codec,
    ?channels,
  ].join(' ');

  return format.isEmpty ? language : '$language · $format';
}

String? _languageName(String raw) {
  final code = raw.trim().toLowerCase();
  if (code.isEmpty || code == 'und' || code == 'unknown' || code == 'unk') {
    return null;
  }
  const names = <String, String>{
    'eng': 'English',
    'en': 'English',
    'hin': 'Hindi',
    'hi': 'Hindi',
    'tam': 'Tamil',
    'ta': 'Tamil',
    'tel': 'Telugu',
    'te': 'Telugu',
    'mal': 'Malayalam',
    'ml': 'Malayalam',
    'kan': 'Kannada',
    'kn': 'Kannada',
    'mar': 'Marathi',
    'mr': 'Marathi',
    'ben': 'Bengali',
    'bn': 'Bengali',
    'guj': 'Gujarati',
    'gu': 'Gujarati',
    'pan': 'Punjabi',
    'pa': 'Punjabi',
    'urd': 'Urdu',
    'ur': 'Urdu',
    'spa': 'Spanish',
    'es': 'Spanish',
    'fra': 'French',
    'fre': 'French',
    'fr': 'French',
    'deu': 'German',
    'ger': 'German',
    'de': 'German',
    'ita': 'Italian',
    'it': 'Italian',
    'jpn': 'Japanese',
    'ja': 'Japanese',
    'kor': 'Korean',
    'ko': 'Korean',
    'zho': 'Chinese',
    'chi': 'Chinese',
    'zh': 'Chinese',
    'ara': 'Arabic',
    'ar': 'Arabic',
    'rus': 'Russian',
    'ru': 'Russian',
    'por': 'Portuguese',
    'pt': 'Portuguese',
  };
  final known = names[code];
  if (known != null) return known;
  return code.toUpperCase();
}

String? _channelLayout(int channels) {
  switch (channels) {
    case 1:
      return 'Mono';
    case 2:
      return '2.0';
    case 6:
      return '5.1';
    case 8:
      return '7.1';
    default:
      return channels > 0 ? '$channels ch' : null;
  }
}

/// Audio row shown in the media controller.
///
/// The row stays visible for layout stability and shows `N/A` when the device
/// cannot change audio tracks or the file has no known tracks. It is only
/// tappable when there is more than one track to pick from.
class AudioTrackRow extends StatelessWidget {
  const AudioTrackRow({
    super.key,
    required this.tracks,
    required this.activeIndex,
    required this.canChange,
    required this.restarting,
  });

  final List<PureCastAudioTrack> tracks;
  final int? activeIndex;
  final bool canChange;
  final bool restarting;

  bool get _canOpen => canChange && !restarting && tracks.length > 1;

  PureCastAudioTrack? get _activeTrack {
    if (tracks.isEmpty) return null;
    for (final track in tracks) {
      if (track.index == activeIndex) return track;
    }
    return tracks.length == 1 ? tracks.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    final active = _activeTrack;
    final label = canChange && active != null ? audioTrackLabel(active) : 'N/A';

    return GestureDetector(
      onTap:
          _canOpen
              ? () => AudioTrackSwitcher.show(
                context,
                tracks: tracks,
                activeIndex: activeIndex,
              )
              : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Audio',
                style: typo.titleMedium.copyWith(color: colors.white),
              ),
            ),
            if (restarting)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colors.white,
                ),
              )
            else
              Text(
                label,
                style: typo.labelMedium.copyWith(color: colors.textSecondary),
              ),
            if (!restarting && _canOpen)
              Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the audio tracks, mirroring [SubtitleSwitcher].
class AudioTrackSwitcher extends StatelessWidget {
  const AudioTrackSwitcher({
    super.key,
    required this.tracks,
    required this.activeIndex,
  });

  final List<PureCastAudioTrack> tracks;
  final int? activeIndex;

  static Future<void> show(
    BuildContext context, {
    required List<PureCastAudioTrack> tracks,
    required int? activeIndex,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surfaceLight,
      builder:
          (sheetContext) => AudioTrackSwitcher(
            tracks: tracks,
            activeIndex: activeIndex,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final track in tracks)
              ListTile(
                title: Text(audioTrackLabel(track)),
                trailing:
                    activeIndex == track.index
                        ? Icon(Icons.check, color: context.appColors.primary)
                        : null,
                onTap: () {
                  context.read<CastSessionBloc>().add(
                    SelectAudioEvent(track.index),
                  );
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
