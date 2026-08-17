import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/music_library/data/data_source/photo_manager_media_source.dart';
import 'package:pure_cast/core/features/music_library/data/repository/media_repository.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_bloc.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/media/media_event.dart';
import 'package:pure_cast/core/utils/state_status.dart';

class FakeLocalMediaDataSource implements LocalMediaDataSource {
  bool permissionGranted = true;
  List<PureCastMedia> mockMedia = [];

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<List<PureCastMedia>> fetchLocalMedia({
    RequestType type = RequestType.common,
    int page = 0,
    int size = 50,
  }) async {
    if (!permissionGranted) {
      throw const PureCastException('Media permission not granted');
    }
    return mockMedia;
  }

  @override
  Future<File?> getAssetFile(String assetId) async => null;
}

void main() {
  late FakeLocalMediaDataSource fakeDataSource;
  late MediaRepository repository;

  setUp(() {
    fakeDataSource = FakeLocalMediaDataSource();
    repository = MediaRepositoryImpl(fakeDataSource);
  });

  group('Task 3A: MediaRepository & MediaBloc photo_manager Integration Tests', () {
    test('1. Requests permission and loads media items into MediaBloc state', () async {
      fakeDataSource.permissionGranted = true;
      fakeDataSource.mockMedia = [
        const PureCastMedia(
          uri: '/storage/emulated/0/Download/sample_video.mp4',
          type: PureCastMediaType.video,
          title: 'sample_video.mp4',
          isLocalFile: true,
        ),
      ];

      final bloc = MediaBloc(repository);
      expect(bloc.state.status, equals(StateStatus.initial));

      bloc.add(const MediaEvent.requestPermission());
      await pumpEventQueue();

      expect(bloc.state.hasPermission, isTrue);
      expect(bloc.state.status, equals(StateStatus.loaded));
      expect(bloc.state.mediaItems.length, equals(1));
      expect(bloc.state.mediaItems.first.title, equals('sample_video.mp4'));

      await bloc.close();
    });

    test('2. Handles permission denied cleanly', () async {
      fakeDataSource.permissionGranted = false;

      final bloc = MediaBloc(repository);

      bloc.add(const MediaEvent.requestPermission());
      await pumpEventQueue();

      expect(bloc.state.hasPermission, isFalse);
      expect(bloc.state.status, equals(StateStatus.error));
      expect(bloc.state.error, contains('Permission denied'));

      await bloc.close();
    });
  });
}
