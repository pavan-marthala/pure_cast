import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/device_manager_screen.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/queue_manager_screen.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_section.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_utils.dart';
import 'package:pure_cast/core/utils/sized_context.dart';
import 'package:pure_cast/core/utils/state_status.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MediaBloc>().add(
      MediaEvent.loadMediaItems(filterType: .video),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pure Cast",
          style: TextStyle(fontSize: 24, fontWeight: .w700),
        ),
        actions: [
          BlocSelector<
            CastSessionBloc,
            CastSessionState,
            (StateStatus, PureCastDevice?)
          >(
            selector: (state) {
              return (state.connectionStatus, state.activeDevice);
            },
            builder: (context, state) {
              final (status, device) = state;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  DeviceManagerScreen.show(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border.all(
                      color: status == .loaded ? colors.primary : colors.border,
                    ),
                    borderRadius: .circular(40),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.cast,
                        size: 18,
                        color: status == .loaded
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      Text(
                        status == .loaded ? device?.name ?? "NA" : "Cast",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              QueueManagerScreen.show(context);
            },
            icon: Icon(Icons.queue_music),
          ),
          // IconButton(onPressed: () {}, icon: Icon(Icons.settings)),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text("All Videos", style: typo.titleMedium),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<QueueBloc>().add(PicFilesEvent());
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.background,
                            border: Border.all(color: colors.border),
                            borderRadius: .circular(12),
                          ),
                          child: Row(
                            spacing: 8,
                            children: [
                              Icon(Icons.add, size: 18),
                              Text(
                                "Pick Files",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  MediaBuilder(),
                ],
              ),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: PlayerSection()),
          ],
        ),
      ),
    );
  }
}

class MediaBuilder extends StatelessWidget {
  const MediaBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        final isLoading = state.status == .loading || state.status == .initial;
        final isError = state.status == .error;
        if (isError) {
          return Expanded(
            child: Center(child: Text(state.error ?? "Error loading media")),
          );
        }
        final mediaItems = isLoading
            ? List.generate(6, (_) => PureCastMedia.skeleton())
            : state.mediaItems;

        return Expanded(
          child: Skeletonizer(
            enabled: isLoading,
            effect: ShimmerEffect(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              duration: Duration(seconds: 1),
            ),
            ignoreContainers: false,
            child: MasonryGridView.count(
              primary: false,
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                final media = mediaItems[index];
                return context.isMobile
                    ? MediaWidgetList(media: media)
                    : MediaWidgetGrid(media: media);
              },
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: mediaItems.length,
              crossAxisCount: context.isMobile ? 1 : 2,
            ),
          ),
        );
      },
    );
  }
}

class MediaWidgetList extends StatelessWidget {
  const new({super.key, required this.media});
  final PureCastMedia media;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () {
        context.read<QueueBloc>().add(QueueEvent.addToQueue(media));
      },
      child: Row(
        spacing: 12,
        children: [
          ClipRRect(
            borderRadius: .circular(8),
            child: Skeleton.replace(
              height: 80,
              width: 140,
              child: Container(
                height: 80,
                width: 140,
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
                    ? Skeleton.shade(
                        child: Icon(
                          media.type == .video
                              ? Icons.videocam_outlined
                              : Icons.audiotrack,
                          size: 40,
                          color: colors.textSecondary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Skeleton.unite(
                  child: Row(
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
                        style: context.appTypography.titleSmall,
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  media.duration?.toFormattedString() ?? "00:00",
                  style: context.appTypography.titleSmall,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MediaWidgetGrid extends StatelessWidget {
  const new({super.key, required this.media});
  final PureCastMedia media;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () {
        context.read<QueueBloc>().add(QueueEvent.addToQueue(media));
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: .circular(8),
            child: Skeleton.replace(
              height: 260,
              width: double.infinity,
              child: Container(
                height: 260,
                width: double.infinity,
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
                    ? Skeleton.shade(
                        child: Icon(
                          media.type == .video
                              ? Icons.videocam_outlined
                              : Icons.audiotrack,
                          size: 40,
                          color: colors.textSecondary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Skeleton.unite(
            child: Row(
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
                  style: context.appTypography.titleSmall,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

(String name, String extension) separateFileNameAndExtension(String fileName) {
  // Trim extra spaces and find the last dot or space
  final trimmed = fileName.trim();
  final lastSeparatorIndex = trimmed.lastIndexOf(RegExp(r'[.\s]'));

  // If no separator is found, or it's a hidden file like ".gitignore"
  if (lastSeparatorIndex <= 0) {
    return (trimmed, '');
  }

  final name = trimmed.substring(0, lastSeparatorIndex);
  final extension = trimmed.substring(lastSeparatorIndex + 1);

  return (name, extension);
}
