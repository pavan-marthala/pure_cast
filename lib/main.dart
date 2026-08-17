import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/coordinator/playback_coordinator.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_event.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_event.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/home_screen.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_bloc.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_event.dart';
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
          await Future.delayed(const Duration(seconds: 2));
          return AppRoutes.home;
        }
        return null;
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<CastDiscoveryBloc>()..add(const StartDiscoveryEvent()),
        ),
        BlocProvider(create: (context) => getIt<CastSessionBloc>()),
        BlocProvider(
          create: (context) =>
              getIt<MediaBloc>()..add(RequestPermissionMediaEvent()),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => getIt<QueueBloc>()..add(const LoadQueueEvent()),
          lazy: false,
        ),
      ],
      child: Builder(
        builder: (context) {
          final queueBloc = BlocProvider.of<QueueBloc>(context);
          final sessionBloc = BlocProvider.of<CastSessionBloc>(context);
          getIt<PlaybackCoordinator>().start(queueBloc, sessionBloc);

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
        },
      ),
    );
  }
}
