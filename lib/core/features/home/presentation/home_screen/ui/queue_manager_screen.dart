import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_utils.dart';

class QueueManagerScreen extends StatefulWidget {
  const QueueManagerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surfaceLight,
      builder: (sheetContext) => const QueueManagerScreen(),
    );
  }

  @override
  State<QueueManagerScreen> createState() => _QueueManagerScreenState();
}

class _QueueManagerScreenState extends State<QueueManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SafeArea(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      "Queue",
                      style: typo.titleMedium.copyWith(fontSize: 18),
                    ),
                    Text("${state.items.length} items"),
                    SizedBox(height: 20),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final queue = state.items[index];
                          final isPlaying = state.currentIndex == index;
                          return GestureDetector(
                            onTap: () {},
                            child: Row(
                              spacing: 12,
                              children: [
                                if (queue.thumbnailBytes == null)
                                  Container(
                                    padding: .all(8),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceDark,
                                      borderRadius: .circular(8),
                                    ),
                                    child: Icon(
                                      queue.type == .video
                                          ? Icons.videocam_outlined
                                          : Icons.audiotrack,
                                      size: 20,
                                      color: colors.textSecondary,
                                    ),
                                  )
                                else
                                  Image.memory(queue.thumbnailBytes!),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        queue.title,
                                        style: typo.titleSmall.copyWith(
                                          color: isPlaying
                                              ? colors.primary
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        formatDuration(
                                          queue.duration ?? Duration(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPlaying) ...[
                                  Text(
                                    "Now",
                                    style: typo.labelSmall.copyWith(
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          height: 16,
                          color: colors.borderLight,
                          thickness: 1.5,
                        ),
                        itemCount: state.items.length,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
