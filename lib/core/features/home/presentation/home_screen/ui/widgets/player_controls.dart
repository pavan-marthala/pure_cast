import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  /// Width the seven-button row is laid out for (fits a 360dp screen with the
  /// screen's 16dp side padding). Narrower screens scale the whole row down
  /// instead of overflowing.
  static const double _rowDesignWidth = 328;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocSelector<QueueBloc, QueueState, (int, int)>(
      selector: (state) {
        return (state.currentIndex, state.items.length);
      },
      builder: (context, state) {
        final (currentIndex, queueLength) = state;
        return BlocSelector<
          CastSessionBloc,
          CastSessionState,
          (PureCastSessionState, bool, bool)
        >(
          selector: (state) {
            final canSeek =
                state.activeMedia != null &&
                (state.activeDevice?.capabilities.canSeek ?? false) &&
                state.duration > Duration.zero;
            return (state.sessionState, canSeek, state.restarting);
          },
          builder: (context, state) {
            final (sessionState, canSeek, restarting) = state;
            final isLoading =
                sessionState == .loading || sessionState == .buffering;
            final isPlaying = sessionState == .playing;
            final ispreviousEnabled = currentIndex > 0;
            final isNextEnabled = currentIndex < queueLength - 1;
            final seekEnabled = canSeek && !restarting;

            VoidCallback? seekBy(int seconds) {
              if (!seekEnabled) return null;
              return () {
                context.read<CastSessionBloc>().add(
                  SeekRelativeEvent(Duration(seconds: seconds)),
                );
              };
            }

            Widget seekButton(IconData icon, int seconds) {
              return ControleButton(
                icon: Icon(
                  icon,
                  color: seekEnabled ? Colors.white : colors.textSecondary,
                ),
                size: 40,
                enabled: seekEnabled,
                onTap: seekBy(seconds),
              );
            }

            return SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: _rowDesignWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ControleButton(
                        icon: Icon(
                          Icons.skip_previous,
                          size: 28,
                          color: ispreviousEnabled
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                        enabled: ispreviousEnabled,
                        onTap: ispreviousEnabled
                            ? () {
                                context.read<QueueBloc>().add(
                                  PreviousQueueItemEvent(),
                                );
                              }
                            : null,
                      ),
                      // seekButton(Icons.replay_30, -30),
                      seekButton(Icons.replay_10, -10),
                      ControleButton(
                        icon: isLoading
                            ? CupertinoActivityIndicator(
                                radius: 14,
                                color: Colors.white,
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                        size: 64,
                        color: colors.primary.withValues(alpha: .8),
                        onTap: isLoading
                            ? null
                            : () {
                                context.read<CastSessionBloc>().add(
                                  isPlaying
                                      ? PauseMediaEvent()
                                      : PlayMediaEvent(),
                                );
                              },
                        enabled: true,
                      ),
                      seekButton(Icons.forward_10, 10),
                      // seekButton(Icons.forward_30, 30),
                      ControleButton(
                        icon: Icon(
                          Icons.skip_next,
                          color: isNextEnabled
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                        enabled: isNextEnabled,
                        onTap: isNextEnabled
                            ? () {
                                context.read<QueueBloc>().add(
                                  NextQueueItemEvent(),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ControleButton extends StatelessWidget {
  const ControleButton({
    super.key,
    this.size = 46,
    required this.icon,
    this.color,
    this.enabled = true,
    this.onTap,
  });

  final double size;
  final Widget icon;
  final Color? color;

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color ?? colors.secondary.withValues(alpha: .3),
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }
}
