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
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart'
    as _i1071;
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart'
    as _i944;
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart'
    as _i619;
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart'
    as _i445;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i600.AppDatabase>(() => _i600.AppDatabase());
    gh.lazySingleton<_i1071.ICastService>(
      () => _i944.DartCastAdapter(castService: gh<_i869.CastService>()),
    );
    gh.factory<_i445.CastSessionBloc>(
      () => _i445.CastSessionBloc(gh<_i1071.ICastService>()),
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
