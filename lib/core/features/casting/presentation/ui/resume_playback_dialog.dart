import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';
import 'package:pure_cast/core/utils/app_utils.dart';

import '../../../home/presentation/home_screen/ui/home_screen.dart';

/// Asks whether [media] should continue from its saved position.
///
/// Returns the position to start from, [Duration.zero] when the user chose to
/// start over, or `null` when the dialog was dismissed without a choice.
Future<Duration?> showResumePlaybackDialog(
  BuildContext context, {
  required PureCastMedia media,
  required ResumeInfo resume,
}) {
  final colors = context.appColors;
  final typo = context.appTypography;
  final progress = resumeProgress(media, resume.position);

  return showDialog<Duration?>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (dialogContext) {
      return Dialog(
        alignment: .bottomCenter,
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        insetPadding: EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: .min,
              spacing: 12,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    ClipRRect(
                      borderRadius: .circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 70,
                            width: 120,
                            padding: .all(8),
                            decoration: BoxDecoration(
                              color: colors.surfaceDark,
                              image: media.thumbnailBytes == null
                                  ? null
                                  : DecorationImage(
                                      image: MemoryImage(media.thumbnailBytes!),
                                      fit: .cover,
                                    ),
                            ),
                            alignment: .center,
                            child: media.thumbnailBytes == null
                                ? Icon(
                                    media.type == .video
                                        ? Icons.videocam_outlined
                                        : Icons.audiotrack,
                                    size: 40,
                                    color: colors.textSecondary,
                                  )
                                : null,
                          ),
                          if (progress != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                color: colors.primary,
                                backgroundColor: colors.surfaceDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  separateFileNameAndExtension(media.title).$1,
                                  style: context.appTypography.titleSmall,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                              ),
                              Text(
                                ".${separateFileNameAndExtension(media.title).$2}",
                                style: context.appTypography.titleMedium,
                                maxLines: 1,
                                overflow: .ellipsis,
                              ),
                            ],
                          ),
                          Text(
                            'You stopped at ${resume.position.toFormattedString()} '
                            'of ${resume.duration.toFormattedString()}.',
                            style: context.appTypography.labelSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text('Continue to where you left off?', style: typo.titleLarge),
                AppButton(
                  text: "Resume form ${resume.position.toFormattedString()}",
                  color: colors.primary,
                  icon: Icon(Icons.play_arrow),
                  width: double.infinity,
                  onPressed: () {
                    context.pop(resume.position);
                  },
                ),
                AppButton(
                  text: "Start Over",
                  color: colors.background,
                  side: Border.all(color: colors.border),
                  icon: Icon(Icons.refresh),
                  width: double.infinity,
                  onPressed: () {
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
      // return AlertDialog(
      //   backgroundColor: colors.surfaceLight,
      //   title: Text('Resume playback?', style: typo.titleMedium),
      //   content: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       if (media.thumbnailBytes != null)
      //         ClipRRect(
      //           borderRadius: .circular(8),
      //           child: Image.memory(
      //             media.thumbnailBytes!,
      //             height: 120,
      //             width: context.widthPx * .9,
      //             fit: BoxFit.cover,
      //           ),
      //         ),
      //       if (media.thumbnailBytes != null) const SizedBox(height: 12),
      //       Text(
      //         media.title,
      //         style: typo.titleSmall,
      //         maxLines: 2,
      //         overflow: TextOverflow.ellipsis,
      //       ),
      //       const SizedBox(height: 6),
      // Text(
      //   'You stopped at ${formatDuration(resume.position)} '
      //   'of ${formatDuration(resume.duration)}.',
      //   style: typo.labelMedium.copyWith(color: colors.textSecondary),
      // ),
      //     ],
      //   ),
      //   actions: [
      //     TextButton(
      //       onPressed: () => Navigator.of(dialogContext).pop(Duration.zero),
      //       child: const Text('Start from beginning'),
      //     ),
      //     FilledButton(
      //       onPressed: () => Navigator.of(dialogContext).pop(resume.position),
      //       child: const Text('Resume'),
      //     ),
      //   ],
      // );
    },
  );
}
