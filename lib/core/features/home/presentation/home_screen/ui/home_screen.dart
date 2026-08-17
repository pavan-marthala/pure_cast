import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/device_manager_screen.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_section.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

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
            icon: Icon(Icons.tv),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.settings)),
        ],
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 2),
          child: Divider(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: .all(16),
          child: Column(children: [PlayerSection()]),
        ),
      ),
    );
  }
}
