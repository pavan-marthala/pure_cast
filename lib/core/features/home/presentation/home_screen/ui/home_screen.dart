import 'package:material_ui/material_ui.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/device_manager_screen.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_section.dart';
import 'package:pure_cast/core/features/music_library/presentation/music_library_screen/ui/music_library_screen.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: .min,
          spacing: 6,
          children: [
            Container(
              padding: .all(6),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: .circular(8),
              ),
              child: Icon(Icons.cast_sharp, size: 18),
            ),
            Text("Pure Cast"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              DeviceManagerScreen.show(context);
            },
            icon: Icon(Icons.tv, color: colors.textSecondary),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings, color: colors.textSecondary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 2),
          child: Divider(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: .all(16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              PlayerSection(),
              SizedBox(height: 20),
              Row(
                spacing: 18,
                children: [
                  MediaBotton(filterType: .video),
                  MediaBotton(filterType: .audio),
                ],
              ),
              SizedBox(height: 20),
              Text("Recently Played", style: context.appTypography.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class MediaBotton extends StatelessWidget {
  const MediaBotton({super.key, required this.filterType});
  final RequestType filterType;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          builder: (context) {
            return MusicLibraryScreen(filterType: filterType);
          },
        );
      },
      child: Container(
        padding: .symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceLight,
          borderRadius: .circular(16),
        ),
        child: Row(
          spacing: 6,
          mainAxisSize: .min,
          children: [
            Icon(
              filterType == .video ? Icons.videocam_outlined : Icons.audiotrack,
              color: colors.primary,
            ),
            Text(filterType == .video ? "Videos" : "Audio"),
          ],
        ),
      ),
    );
  }
}
