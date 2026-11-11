import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/subtitle/subtitle_extraction_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/queue_manager_screen.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_controls.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_section.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_utils.dart';

class MediaControllerScreen extends StatefulWidget {
  const MediaControllerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.surfaceLight,
      builder: (sheetContext) => const MediaControllerScreen(),
    );
  }

  @override
  State<MediaControllerScreen> createState() => _MediaControllerScreenState();
}

class _MediaControllerScreenState extends State<MediaControllerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sessionBloc = context.read<CastSessionBloc>();
      final media = sessionBloc.state.activeMedia;
      if (media != null && media.isLocalFile) {
        final file = File(media.uri);
        file.length().then((fileSize) {
          file.lastModified().then((lastModified) {
            if (!mounted) return;
            context.read<SubtitleExtractionBloc>().add(
              SubtitleExtractionEvent.inspectSubtitles(
                filePath: media.uri,
                fileSize: fileSize,
                lastModified: lastModified,
              ),
            );
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [Header(), Body()]);
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionBloc = context.read<CastSessionBloc>();
    final state = sessionBloc.state;
    return SliverAppBar(
      expandedHeight: 360,
      centerTitle: true,
      pinned: true,
      stretch: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 20,
      leading: BackButton(),
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () {
            QueueManagerScreen.show(context);
          },
          icon: Icon(Icons.queue_music),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            centerTitle: true,
            background: CurrentlyPlayingBG(sessionState: state),
          );
        },
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionBloc = context.read<CastSessionBloc>();
    final state = sessionBloc.state;
    final colors = context.appColors;
    final typo = context.appTypography;
    final media = state.activeMedia;
    final device = state.activeDevice;
    final subtitle = state.activeSubtitle;
    final position = state.position;
    final duration = state.duration;

    return SliverPadding(
      padding: .symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            SizedBox(height: 16),
            Text(
              media?.title ?? 'Unknown Title',
              style: typo.titleLarge.copyWith(color: colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
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
                  formatDuration(position),
                  style: typo.labelSmall.copyWith(color: colors.white),
                ),
                Text(
                  formatDuration(duration),
                  style: typo.labelSmall.copyWith(color: colors.white),
                ),
              ],
            ),
            SizedBox(height: 20),
            PlayerControls(),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: .circular(22),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: .symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Audio',
                              style: typo.titleMedium.copyWith(
                                color: colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'N/A',
                            style: typo.labelMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  GestureDetector(
                    onTap: () {
                      final extractionState = context
                          .read<SubtitleExtractionBloc>()
                          .state;
                      final discoveredSubtitles = extractionState.streams.map((
                        stream,
                      ) {
                        return PureCastSubtitleTrack(
                          id: '${media!.uri}:${stream.streamIndex}',
                          label: stream.displayLabel,
                          language: stream.language ?? '',
                          url: media.uri,
                          format: stream.codecName.toLowerCase(),
                        );
                      }).toList();
                      print(extractionState);
                      SubtitleSwitcher.show(
                        context,
                        activeSubtitle: subtitle,
                        subtitles: discoveredSubtitles.isNotEmpty
                            ? discoveredSubtitles
                            : (media?.subtitles ?? []),
                      );
                    },
                    child: Padding(
                      padding: .symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Subtitles',
                              style: typo.titleMedium.copyWith(
                                color: colors.white,
                              ),
                            ),
                          ),
                          Text(
                            subtitle != null ? subtitle.label : 'Off',
                            style: typo.labelMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: .symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Device',
                            style: typo.titleMedium.copyWith(
                              color: colors.white,
                            ),
                          ),
                        ),
                        Text(
                          device?.name ?? 'No Device',
                          style: typo.labelMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: colors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubtitleSwitcher extends StatefulWidget {
  const SubtitleSwitcher({
    super.key,
    this.activeSubtitle,
    required this.subtitles,
  });

  final PureCastSubtitleTrack? activeSubtitle;
  final List<PureCastSubtitleTrack> subtitles;

  static Future<void> show(
    BuildContext context, {
    PureCastSubtitleTrack? activeSubtitle,
    required List<PureCastSubtitleTrack> subtitles,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surfaceLight,
      builder: (sheetContext) => SubtitleSwitcher(
        activeSubtitle: activeSubtitle,
        subtitles: subtitles,
      ),
    );
  }

  @override
  State<SubtitleSwitcher> createState() => _SubtitleSwitcherState();
}

class _SubtitleSwitcherState extends State<SubtitleSwitcher> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Off'),
              trailing: widget.activeSubtitle == null
                  ? Icon(Icons.check, color: context.appColors.primary)
                  : null,
              onTap: () {
                context.read<CastSessionBloc>().add(SetSubtitleEvent(null));
                Navigator.of(context).pop();
              },
            ),
            ...widget.subtitles.map(
              (subtitle) => ListTile(
                title: Text(subtitle.label),
                trailing: widget.activeSubtitle?.id == subtitle.id
                    ? Icon(Icons.check, color: context.appColors.primary)
                    : null,
                onTap: () {
                  context.read<CastSessionBloc>().add(
                    SetSubtitleEvent(subtitle),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
