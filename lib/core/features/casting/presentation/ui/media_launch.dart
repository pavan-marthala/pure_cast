import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/ui/resume_playback_dialog.dart';

/// Starts playback for an explicit user tap on a media item.
///
/// When a resumable checkpoint exists, the user is asked whether to continue
/// or start over. The media is then queued (or its existing queue entry is
/// re-selected) and played through the playback coordinator.
class MediaLaunch {
  MediaLaunch._();

  /// Prevents a double tap from stacking two resume dialogs or two plays.
  static bool _isLaunching = false;

  static Future<void> play(
    BuildContext context,
    PureCastMedia media, {
    PlaybackHistoryRepository? historyRepository,
  }) async {
    if (_isLaunching) return;
    _isLaunching = true;
    try {
      final repository =
          historyRepository ?? getIt<PlaybackHistoryRepository>();
      Duration? startPosition;

      ResumeInfo? resume;
      try {
        resume = await repository.getResumeInfo(media.uri);
      } catch (_) {
        // A history read failure must never block playback.
        resume = null;
      }
      if (resume != null && resume.canResume) {
        if (!context.mounted) return;
        final choice = await showResumePlaybackDialog(
          context,
          media: media,
          resume: resume,
        );
        if (choice == null) return; // Dismissed without choosing.
        if (choice == Duration.zero) {
          unawaited(repository.clearResumePosition(media.uri));
        } else {
          startPosition = choice;
        }
      }

      if (!context.mounted) return;
      context.read<QueueBloc>().add(
        QueueEvent.playMedia(media, startPosition: startPosition),
      );
    } finally {
      _isLaunching = false;
    }
  }
}
