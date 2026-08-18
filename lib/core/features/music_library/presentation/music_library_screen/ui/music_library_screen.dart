import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key, required this.filterType});

  final RequestType filterType;

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  @override
  void initState() {
    context.read<MediaBloc>().add(
      MediaEvent.loadMediaItems(filterType: widget.filterType),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        final isLoading = state.status == .loading;
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : MasonryGridView.count(
                    padding: .all(16),
                    itemBuilder: (context, index) {
                      final media = state.mediaItems[index];
                      return Column(
                        children: [
                          Container(
                            height: 260,
                            width: double.infinity,
                            padding: .all(8),
                            decoration: BoxDecoration(
                              color: colors.surfaceDark,
                              borderRadius: .circular(8),
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
                          Text(
                            media.title,
                            style: context.appTypography.titleSmall,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ],
                      );
                    },
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: state.mediaItems.length,
                    crossAxisCount: 2,
                  ),
          ),
        );
      },
    );
  }
}
