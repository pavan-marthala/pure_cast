import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/home_screen.dart';
import 'package:pure_cast/core/features/splash/presentation/splash_screen/ui/splash_screen.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "app_config.env");
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _goRouter;

  @override
  void initState() {
    _goRouter = GoRouter(
      initialLocation: AppRoutes.splash,
      navigatorKey: rootNavigatorKey,
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        final path = state.matchedLocation;
        final isOnSplash = path == AppRoutes.splash;
        if (isOnSplash) {
          await Future.delayed(Duration(seconds: 2));
          return AppRoutes.home;
        }
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _goRouter,
      title: 'Pure Cast',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return child ?? const Scaffold();
      },
    );
  }
}
