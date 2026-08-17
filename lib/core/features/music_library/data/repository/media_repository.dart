import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/music_library/data/data_source/photo_manager_media_source.dart';

abstract class MediaRepository {
  Future<bool> checkAndRequestPermission();
  Future<List<PureCastMedia>> getLocalMedia({
    RequestType type = RequestType.common,
    int page = 0,
    int size = 50,
  });
  Future<File?> getMediaFile(String assetId);
}

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final LocalMediaDataSource _localMediaSource;

  MediaRepositoryImpl(this._localMediaSource);

  @override
  Future<bool> checkAndRequestPermission() async {
    return _localMediaSource.requestPermission();
  }

  @override
  Future<List<PureCastMedia>> getLocalMedia({
    RequestType type = RequestType.common,
    int page = 0,
    int size = 50,
  }) async {
    return _localMediaSource.fetchLocalMedia(
      type: type,
      page: page,
      size: size,
    );
  }

  @override
  Future<File?> getMediaFile(String assetId) async {
    return _localMediaSource.getAssetFile(assetId);
  }
}
