import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dart_cast/dart_cast.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/subtitle/subtitle_extraction_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/coordinator/playback_coordinator.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/home_screen.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_bloc.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/recently_played/recently_played_bloc.dart';
import 'package:pure_cast/core/features/splash/presentation/splash_screen/ui/splash_screen.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_routes.dart';
import 'package:pure_cast/core/utils/check_platforms.dart';
import 'package:pure_cast/core/utils/state_status.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: "app_config.env");
  await configureDependencies();
  await CastPrepareSession.cleanupLeftovers();
  if (kDebugMode) {
    CastFfmpegDiagnostics.dumpCapabilities();
  }
  if (PlatformChecker.isAndroid() || PlatformChecker.isIOS()) {
    _initBackgroundService();
  }
  runApp(const MyApp());
}

void _initBackgroundService() {
  final service = FlutterBackgroundService();
  service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      foregroundServiceTypes: [AndroidForegroundType.mediaPlayback],
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  // Required entry point for background service on Android
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _goRouter;
  bool _isCasting = false;
  late final StreamSubscription _sessionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    _listenToSessionState();
  }

  void _listenToSessionState() {
    final sessionBloc = getIt<CastSessionBloc>();
    _sessionSubscription = sessionBloc.stream.listen((state) {
      final wasCasting = _isCasting;
      _isCasting = state.isCasting;

      // Start background service + wakelock when casting starts
      if (_isCasting && !wasCasting) {
        _startBackgroundService();
      }

      // Stop background service + wakelock when casting stops
      if (!_isCasting && wasCasting) {
        _stopBackgroundService();
      }
    });
  }

  void _startBackgroundService() {
    final service = FlutterBackgroundService();
    service.startService();
    if (PlatformChecker.isAndroid()) {
      WakelockPlus.enable();
    }
  }

  void _stopBackgroundService() {
    // Background service keeps running with foreground notification.
    // User can stop it via the notification if needed.
    if (PlatformChecker.isAndroid()) {
      WakelockPlus.disable();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Keep the background service running even when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isCasting) {
        _startBackgroundService();
      }
    }
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 1st in Load file event need to chack there iis any active event or not
  /// 2nd
  @override
  Widget build(BuildContext context) {
    final MediaBloc mediaBloc = getIt<MediaBloc>();
    if (PlatformChecker.isAndroid()) {
      mediaBloc.add(MediaEvent.requestPermission());
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<CastDiscoveryBloc>()..add(const StartDiscoveryEvent()),
        ),
        BlocProvider(create: (context) => getIt<CastSessionBloc>()),
        BlocProvider(create: (context) => mediaBloc, lazy: false),
        BlocProvider(
          create: (context) => getIt<QueueBloc>()..add(const LoadQueueEvent()),
          lazy: false,
        ),
        BlocProvider(
          create: (context) =>
              getIt<RecentlyPlayedBloc>()..add(const LoadRecentlyPlayedEvent()),
          lazy: false,
        ),
        BlocProvider(create: (context) => getIt<SubtitleExtractionBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final queueBloc = BlocProvider.of<QueueBloc>(context);
          final sessionBloc = BlocProvider.of<CastSessionBloc>(context);
          final discoveryBloc = BlocProvider.of<CastDiscoveryBloc>(context);

          discoveryBloc.stream.listen((discoveryState) {
            final autoDevice = discoveryState.autoReconnectDevice;
            if (autoDevice != null &&
                sessionBloc.state.activeDevice == null &&
                sessionBloc.state.connectionStatus != StateStatus.loading) {
              sessionBloc.add(ConnectDeviceEvent(autoDevice));
            }
          });

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
