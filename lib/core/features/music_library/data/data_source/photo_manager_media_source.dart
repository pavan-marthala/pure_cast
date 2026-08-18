import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

abstract class LocalMediaDataSource {
  Future<bool> requestPermission();
  Future<List<PureCastMedia>> fetchLocalMedia({
    RequestType type = RequestType.common,
    int page = 0,
    int size = 50,
  });
  Future<File?> getAssetFile(String assetId);
  Future<List<PureCastMedia>> pickFiles();
}

@LazySingleton(as: LocalMediaDataSource)
class PhotoManagerMediaSource implements LocalMediaDataSource {
  @override
  Future<bool> requestPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state.hasAccess;
  }

  @override
  Future<List<PureCastMedia>> fetchLocalMedia({
    RequestType type = RequestType.common,
    int page = 0,
    int size = 50,
  }) async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      throw const PureCastException('Media permission not granted');
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: type,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    final AssetPathEntity recentAlbum = albums.first;
    final List<AssetEntity> assets = await recentAlbum.getAssetListPaged(
      page: page,
      size: size,
    );

    final List<PureCastMedia> mediaItems = [];

    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) continue;

      final PureCastMediaType mediaType;
      if (asset.type == AssetType.video) {
        mediaType = PureCastMediaType.video;
      } else if (asset.type == AssetType.audio) {
        mediaType = PureCastMediaType.audio;
      } else {
        mediaType = PureCastMediaType.video;
      }

      mediaItems.add(
        PureCastMedia(
          uri: file.path,
          type: mediaType,
          title: asset.title ?? file.path.split('/').last,
          duration: asset.duration > 0
              ? Duration(seconds: asset.duration)
              : null,
          isLocalFile: true,

        ),
      );
    }

    return mediaItems;
  }

  @override
  Future<File?> getAssetFile(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    return asset?.file;
  }

  @override
  Future<List<PureCastMedia>> pickFiles() async {
    final List<PureCastMedia> mediaItems = [];

    List<PlatformFile> files = await FilePicker.pickFiles();

    if (files.isNotEmpty) {
      for (final platformFile in files) {
        final xFile = platformFile.xFile;
        final PureCastMediaType mediaType;
        if (xFile.mimeType != null && xFile.mimeType!.startsWith('video/')) {
          mediaType = PureCastMediaType.video;
        } else if (xFile.mimeType != null &&
            xFile.mimeType!.startsWith('audio/')) {
          mediaType = PureCastMediaType.audio;
        } else {
          mediaType = PureCastMediaType.video;
        }

        mediaItems.add(
          PureCastMedia(
            uri: xFile.path,
            type: mediaType,
            title: xFile.name,
            duration: null,
            isLocalFile: true,
          ),
        );
      }
      return mediaItems;
    } else {
      return mediaItems;
    }
  }
}
