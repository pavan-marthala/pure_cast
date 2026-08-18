import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
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
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [Header(), Body()]);
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
      (PureCastMedia?, PureCastDevice?, Duration, Duration)
    >(
      selector: (state) {
        return (
          state.activeMedia,
          state.activeDevice,
          state.position,
          state.duration,
        );
      },
      builder: (context, state) {
        final (media, device, position, duration) = state;
        return SliverPadding(
          padding: .symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  media?.title ?? "Unknown Title",
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
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
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            centerTitle: true,
            background: CurrentlyPlayingBG(),
          );
        },
      ),
    );
  }
}
