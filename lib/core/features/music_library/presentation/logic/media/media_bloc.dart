import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/music_library/data/repository/media_repository.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'media_event.dart';
part 'media_state.dart';
part 'media_bloc.freezed.dart';

@injectable
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final MediaRepository _mediaRepository;

  MediaBloc(this._mediaRepository) : super(const MediaState()) {
    on<RequestPermissionMediaEvent>(_onRequestPermission);
    on<LoadMediaItemsEvent>(_onLoadMedia);
    on<LoadNextPageMediaEvent>(_onLoadNextPage);
  }

  Future<void> _onRequestPermission(
    RequestPermissionMediaEvent event,
    Emitter<MediaState> emit,
  ) async {
    try {
      final granted = await _mediaRepository.checkAndRequestPermission();
      emit(state.copyWith(hasPermission: granted));
      if (granted) {
        add(const LoadMediaItemsEvent());
      } else {
        emit(state.copyWith(
          status: StateStatus.error,
          error: 'Permission denied to access local media library',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: StateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMedia(
    LoadMediaItemsEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(state.copyWith(
      status: StateStatus.loading,
      error: null,
      selectedFilter: event.filterType,
      page: 0,
    ));

    try {
      final granted = await _mediaRepository.checkAndRequestPermission();
      if (!granted) {
        emit(state.copyWith(
          hasPermission: false,
          status: StateStatus.error,
          error: 'Permission to access media library not granted',
        ));
        return;
      }

      final items = await _mediaRepository.getLocalMedia(
        type: event.filterType,
        page: 0,
        size: 50,
      );

      final status = items.isEmpty ? StateStatus.empty : StateStatus.loaded;
      emit(state.copyWith(
        hasPermission: true,
        mediaItems: items,
        status: status,
        page: 0,
        hasMore: items.length == 50,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadNextPage(
    LoadNextPageMediaEvent event,
    Emitter<MediaState> emit,
  ) async {
    if (!state.hasMore || state.status == StateStatus.loading) return;

    final nextPage = state.page + 1;
    try {
      final newItems = await _mediaRepository.getLocalMedia(
        type: state.selectedFilter,
        page: nextPage,
        size: 50,
      );

      final updatedList = List.of(state.mediaItems)..addAll(newItems);
      emit(state.copyWith(
        mediaItems: updatedList,
        page: nextPage,
        hasMore: newItems.length == 50,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
