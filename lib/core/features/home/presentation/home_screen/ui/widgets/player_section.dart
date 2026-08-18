import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/media_crontroller_screen.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_utils.dart';

class PlayerSection extends StatelessWidget {
  const PlayerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CastSessionBloc, CastSessionState, bool>(
      selector: (state) {
        return state.isCasting;
      },
      builder: (context, isCasting) {
        return isCasting ? CurrentlyPlaying() : NothingPlayingSection();
      },
    );
  }
}

class CurrentlyPlaying extends StatelessWidget {
  const CurrentlyPlaying({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<CastSessionBloc>().state;
    final media = sessionState.activeMedia;
    final colors = context.appColors;
    final typo = context.appTypography;

    return GestureDetector(
      onTap: () {
        MediaControllerScreen.show(context);
      },
      child: ClipRRect(
        borderRadius: .circular(12),
        child: SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            children: [
              const CurrentlyPlayingBG(),
              Padding(
                padding: .all(20),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Align(
                      alignment: .centerRight,
                      child: Container(
                        padding: .symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: .circular(18),
                          border: Border.all(color: colors.text4),
                        ),
                        child: Row(
                          mainAxisSize: .min,
                          spacing: 6,
                          children: [
                            Icon(
                              Icons.cast_sharp,
                              color: colors.primary,
                              size: 12,
                            ),
                            Text(
                              sessionState.activeDevice?.name ??
                                  "Casting Device",
                              style: typo.labelSmall.copyWith(
                                color: colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      spacing: 6,
                      children: [
                        if (sessionState.sessionState == .buffering)
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        if (sessionState.sessionState == .paused)
                        IconButton(
                          onPressed: () {
                            context.read<CastSessionBloc>().add(
                              CastSessionEvent.playMedia(),
                            );
                          },
                          icon: Icon(Icons.play_arrow),
                        ),
                        if (sessionState.sessionState == .playing)
                        IconButton(
                          onPressed: () {
                            context.read<CastSessionBloc>().add(
                              CastSessionEvent.pauseMedia(),
                            );
                          },
                          icon: Icon(Icons.pause),
                        ),
                        Text(
                          media?.title ?? "Unknown Title",
                          style: typo.titleLarge.copyWith(color: colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: sessionState.duration.inMilliseconds > 0
                          ? sessionState.position.inMilliseconds /
                                sessionState.duration.inMilliseconds
                          : 0.0,
                      backgroundColor: colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.white),
                      minHeight: 4,
                      borderRadius: .circular(2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(sessionState.position),
                          style: typo.labelSmall.copyWith(color: colors.white),
                        ),
                        Text(
                          formatDuration(sessionState.duration),
                          style: typo.labelSmall.copyWith(color: colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrentlyPlayingBG extends StatelessWidget {
  const CurrentlyPlayingBG({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: context.appGradients.surface),
    );
  }
}

class NothingPlayingSection extends StatelessWidget {
  const NothingPlayingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return Container(
      padding: .all(14),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: .circular(12),
      ),
      child: Row(
        spacing: 14,
        children: [
          Container(
            padding: .all(8),
            decoration: BoxDecoration(
              color: colors.surfaceDark,
              borderRadius: .circular(8),
            ),
            child: Icon(Icons.tv, size: 20, color: colors.textTertiary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text("Nothing Playing right now", style: typo.titleSmall),
                Text("Pick something form your media to start casting"),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<QueueBloc>().add(PicFilesEvent());
            },
            child: Text(
              "Browse Files",
              style: typo.titleSmall.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
