import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/music_library/data/data_source/music_library_data_source.dart';

abstract class MusicLibraryRepository {}

@LazySingleton(as: MusicLibraryRepository)
class MusicLibraryRepositoryImp implements MusicLibraryRepository {
  MusicLibraryRepositoryImp(this._remoteDataSource);

  final MusicLibraryDataSource _remoteDataSource;
}
