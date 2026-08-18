import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'recently_played_event.dart';
part 'recently_played_state.dart';
part 'recently_played_bloc.freezed.dart';

@injectable
class RecentlyPlayedBloc extends Bloc<RecentlyPlayedEvent, RecentlyPlayedState> {
  final PlaybackHistoryRepository _historyRepository;

  RecentlyPlayedBloc(this._historyRepository) : super(const RecentlyPlayedState()) {
    on<LoadRecentlyPlayedEvent>(_onLoadRecentlyPlayed);
    on<RefreshRecentlyPlayedEvent>(_onRefreshRecentlyPlayed);
    on<RemoveRecentlyPlayedEvent>(_onRemoveRecentlyPlayed);
  }

  Future<void> _onLoadRecentlyPlayed(
    LoadRecentlyPlayedEvent event,
    Emitter<RecentlyPlayedState> emit,
  ) async {
    emit(state.copyWith(status: StateStatus.loading, error: null));
    await _fetchHistory(emit);
  }

  Future<void> _onRefreshRecentlyPlayed(
    RefreshRecentlyPlayedEvent event,
    Emitter<RecentlyPlayedState> emit,
  ) async {
    await _fetchHistory(emit);
  }

  Future<void> _onRemoveRecentlyPlayed(
    RemoveRecentlyPlayedEvent event,
    Emitter<RecentlyPlayedState> emit,
  ) async {
    try {
      await _historyRepository.removeHistory(event.mediaUri);
      await _fetchHistory(emit);
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _fetchHistory(Emitter<RecentlyPlayedState> emit) async {
    try {
      final historyRecords = await _historyRepository.getRecentHistory(limit: 50);
      final mediaList = historyRecords.map((item) {
        return PureCastMedia(
          uri: item.mediaUri,
          type: _mapStringToMediaType(item.mediaType),
          title: item.title,
          thumbnailUrl: item.thumbnailUrl,
          duration: item.totalDurationMs > 0
              ? Duration(milliseconds: item.totalDurationMs)
              : null,
          isLocalFile: item.isLocalFile,
        );
      }).toList();

      final status = mediaList.isEmpty ? StateStatus.empty : StateStatus.loaded;
      emit(state.copyWith(media: mediaList, status: status, error: null));
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  static PureCastMediaType _mapStringToMediaType(String str) {
    switch (str) {
      case 'hls':
        return PureCastMediaType.hls;
      case 'mp4':
        return PureCastMediaType.mp4;
      case 'mkv':
        return PureCastMediaType.mkv;
      case 'audio':
        return PureCastMediaType.audio;
      default:
        return PureCastMediaType.video;
    }
  }
}
