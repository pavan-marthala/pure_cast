import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/subtitle/subtitle_extraction_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/cast_audio_controls.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/cast_seek_bar.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_controls.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_toast.dart';

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
    return CustomScrollView(slivers: [Body()]);
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return BlocSelector<
      CastSessionBloc,
      CastSessionState,
      (
        PureCastMedia?,
        PureCastDevice?,
        PureCastSubtitleTrack?,
        Duration,
        Duration,
        bool,
        bool,
        String?,
        String?,
        List<PureCastAudioTrack>,
        int?,
        bool,
        bool,
        Duration?,
      )
    >(
      selector: (state) {
        return (
          state.activeMedia,
          state.activeDevice,
          state.activeSubtitle,
          state.position,
          state.duration,
          state.preparing,
          state.preparingSubtitles,
          state.prepareError,
          state.prepareSubtitlesError,
          state.audioTracks,
          state.activeAudioIndex,
          state.isLive,
          state.restarting,
          state.seekPreview,
        );
      },
      builder: (context, state) {
        final (
          media,
          device,
          subtitle,
          position,
          duration,
          preparing,
          preparingSubtitles,
          prepareError,
          prepareSubtitlesError,
          audioTracks,
          activeAudioIndex,
          isLive,
          restarting,
          seekPreview,
        ) = state;
        if (preparing) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('Preparing video for Chromecast...')),
          );
        }
        if (prepareError != null) {
          return SliverToBoxAdapter(child: Center(child: Text(prepareError)));
        }
        return SliverPadding(
          padding: .symmetric(horizontal: 16, vertical: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.pop();
                      },
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: colors.white,
                        size: 28,
                      ),
                    ),

                    Expanded(
                      child: Text(
                        media?.title ?? 'Unknown Title',
                        style: typo.titleLarge.copyWith(
                          color: colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: .circular(12),
                    gradient: context.appGradients.surface,
                    image: media?.thumbnailBytes != null
                        ? DecorationImage(
                            fit: .cover,
                            image: MemoryImage(media!.thumbnailBytes!),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                CastSeekBar(
                  position: position,
                  duration: duration,
                  canSeek: device?.capabilities.canSeek ?? false,
                  restarting: restarting,
                  seekPreview: seekPreview,
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
                      AudioTrackRow(
                        tracks: audioTracks,
                        activeIndex: activeAudioIndex,
                        canChange:
                            device != null &&
                            device.protocol == PureCastProtocol.chromecast &&
                            device.capabilities.canChangeAudioTrack,
                        restarting: restarting,
                      ),
                      Divider(),
                      GestureDetector(
                        onTap: () {
                          final extractionState = context
                              .read<SubtitleExtractionBloc>()
                              .state;
                          final discoveredSubtitles = extractionState.streams
                              .map((stream) {
                                return PureCastSubtitleTrack(
                                  id: '${media!.uri}:${stream.streamIndex}',
                                  label: stream.displayLabel,
                                  language: stream.language ?? '',
                                  url: media.uri,
                                  format: stream.codecName.toLowerCase(),
                                );
                              })
                              .toList();
                          SubtitleSwitcher.show(
                            context,
                            activeSubtitle: subtitle,
                            subtitles: discoveredSubtitles.isNotEmpty
                                ? discoveredSubtitles
                                : (media?.subtitles ?? []),
                            isLive: isLive,
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
                              if (!preparingSubtitles)
                                Text(
                                  subtitle != null ? subtitle.label : 'Off',
                                  style: typo.labelMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              preparingSubtitles
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Icon(
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
                            Icon(
                              Icons.chevron_right,
                              color: colors.textSecondary,
                            ),
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
      },
    );
  }
}

class SubtitleSwitcher extends StatefulWidget {
  const SubtitleSwitcher({
    super.key,
    this.activeSubtitle,
    required this.subtitles,
    this.isLive = false,
  });

  final PureCastSubtitleTrack? activeSubtitle;
  final List<PureCastSubtitleTrack> subtitles;
  final bool isLive;

  static Future<void> show(
    BuildContext context, {
    PureCastSubtitleTrack? activeSubtitle,
    required List<PureCastSubtitleTrack> subtitles,
    bool isLive = false,
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
        isLive: isLive,
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
                  if (widget.isLive) {
                    showInfoToast(message: kLiveSubtitlesUnavailableMessage);
                    Navigator.of(context).pop();
                    return;
                  }
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
