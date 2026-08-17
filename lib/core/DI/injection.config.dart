// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dart_cast/dart_cast.dart' as _i869;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pure_cast/core/database/app_database.dart' as _i600;
import 'package:pure_cast/core/DI/injection.dart' as _i98;
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart'
    as _i1071;
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart'
    as _i187;
import 'package:pure_cast/core/features/casting/presentation/logic/coordinator/playback_coordinator.dart'
    as _i755;
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart'
    as _i619;
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart'
    as _i723;
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart'
    as _i445;
import 'package:pure_cast/core/features/music_library/data/data_source/photo_manager_media_source.dart'
    as _i50;
import 'package:pure_cast/core/features/music_library/data/repository/media_repository.dart'
    as _i270;
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_bloc.dart'
    as _i597;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final injectionModule = _$InjectionModule();
    gh.lazySingleton<_i869.CastService>(() => injectionModule.castService);
    gh.lazySingleton<_i600.AppDatabase>(() => _i600.AppDatabase());
    gh.lazySingleton<_i50.LocalMediaDataSource>(
      () => _i50.PhotoManagerMediaSource(),
    );
    gh.lazySingleton<_i270.MediaRepository>(
      () => _i270.MediaRepositoryImpl(gh<_i50.LocalMediaDataSource>()),
    );
    gh.factory<_i723.QueueBloc>(() => _i723.QueueBloc(gh<_i600.AppDatabase>()));
    gh.lazySingleton<_i187.PlaybackHistoryRepository>(
      () => _i187.PlaybackHistoryRepository(gh<_i600.AppDatabase>()),
    );
    gh.factory<_i597.MediaBloc>(
      () => _i597.MediaBloc(gh<_i270.MediaRepository>()),
    );
    gh.lazySingleton<_i1071.ICastService>(
      () => injectionModule.getICastService(gh<_i869.CastService>()),
    );
    gh.lazySingleton<_i755.PlaybackCoordinator>(
      () => _i755.PlaybackCoordinator(gh<_i187.PlaybackHistoryRepository>()),
    );
    gh.factory<_i445.CastSessionBloc>(
      () => _i445.CastSessionBloc(
        gh<_i1071.ICastService>(),
        gh<_i187.PlaybackHistoryRepository>(),
      ),
    );
    gh.factory<_i619.CastDiscoveryBloc>(
      () => _i619.CastDiscoveryBloc(
        gh<_i1071.ICastService>(),
        gh<_i600.AppDatabase>(),
      ),
    );
    return this;
  }
}

class _$InjectionModule extends _i98.InjectionModule {}
