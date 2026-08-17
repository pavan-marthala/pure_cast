import 'package:dart_cast/dart_cast.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@module
abstract class InjectionModule {
  @lazySingleton
  CastService get castService => CastService(
        discoveryProviders: [
          ChromecastDiscoveryProvider(),
          DlnaDiscoveryProvider(),
        ],
        sessionFactory: (device) {
          switch (device.protocol) {
            case CastProtocol.chromecast:
              return ChromecastSession(device: device);
            case CastProtocol.dlna:
              return DlnaSession.fromDevice(device);
            case CastProtocol.airplay:
              throw UnsupportedError('AirPlay is not enabled for V1');
          }
        },
      );

  @lazySingleton
  ICastService getICastService(CastService castService) =>
      DartCastAdapter(castService: castService);
}

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.init();
}
