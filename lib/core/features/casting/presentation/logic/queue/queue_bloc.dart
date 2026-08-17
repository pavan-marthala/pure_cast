import 'package:drift/drift.dart' as drift;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/music_library/data/repository/media_repository.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'queue_event.dart';
part 'queue_state.dart';
part 'queue_bloc.freezed.dart';

@injectable
class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final AppDatabase _db;
  final MediaRepository _mediaRepository;
  QueueBloc(this._db, this._mediaRepository) : super(const QueueState()) {
    on<LoadQueueEvent>(_onLoadQueue);
    on<AddToQueueEvent>(_onAddToQueue);
    on<RemoveFromQueueEvent>(_onRemoveFromQueue);
    on<ReorderQueueEvent>(_onReorderQueue);
    on<ClearQueueEvent>(_onClearQueue);
    on<NextQueueItemEvent>(_onNextQueueItem);
    on<PreviousQueueItemEvent>(_onPreviousQueueItem);
    on<SetCurrentIndexEvent>(_onSetCurrentIndex);
    on<PicFilesEvent>(_onPickFiles);
  }

  Future<void> _onLoadQueue(
    LoadQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    emit(state.copyWith(status: StateStatus.loading, error: null));
    try {
      final rows = await _db.getQueue();
      final items = rows
          .map(
            (r) => PureCastMedia(
              uri: r.mediaUri,
              type: _mapStringToMediaType(r.mediaType),
              title: r.title,
              thumbnailUrl: r.thumbnail,
              duration: r.durationMs != null
                  ? Duration(milliseconds: r.durationMs!)
                  : null,
              isLocalFile: r.isLocalFile,
            ),
          )
          .toList();

      final status = items.isEmpty ? StateStatus.empty : StateStatus.loaded;
      emit(state.copyWith(items: items, status: status));
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _onAddToQueue(
    AddToQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final updatedItems = List<PureCastMedia>.from(state.items)
        ..add(event.media);
      emit(state.copyWith(items: updatedItems, status: StateStatus.loaded));
      await _persistQueue(updatedItems);
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRemoveFromQueue(
    RemoveFromQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final updatedItems = state.items
          .where((i) => i.uri != event.mediaUri)
          .toList();
      final status = updatedItems.isEmpty
          ? StateStatus.empty
          : StateStatus.loaded;
      emit(state.copyWith(items: updatedItems, status: status));
      await _persistQueue(updatedItems);
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _onReorderQueue(
    ReorderQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final updatedItems = List<PureCastMedia>.from(state.items);
      int newIdx = event.newIndex;
      if (newIdx > event.oldIndex) newIdx -= 1;
      final item = updatedItems.removeAt(event.oldIndex);
      updatedItems.insert(newIdx, item);

      emit(state.copyWith(items: updatedItems, status: StateStatus.loaded));
      await _persistQueue(updatedItems);
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _onClearQueue(
    ClearQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await _db.clearQueue();
      emit(
        state.copyWith(
          items: const [],
          currentIndex: 0,
          status: StateStatus.empty,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  void _onNextQueueItem(NextQueueItemEvent event, Emitter<QueueState> emit) {
    if (state.items.isEmpty) return;
    if (state.currentIndex < state.items.length - 1) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }

  void _onPreviousQueueItem(
    PreviousQueueItemEvent event,
    Emitter<QueueState> emit,
  ) {
    if (state.items.isEmpty) return;
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  void _onSetCurrentIndex(
    SetCurrentIndexEvent event,
    Emitter<QueueState> emit,
  ) {
    if (event.index >= 0 && event.index < state.items.length) {
      emit(state.copyWith(currentIndex: event.index));
    }
  }

  Future<void> _onPickFiles(
    PicFilesEvent event,
    Emitter<QueueState> emit,
  ) async {
    emit(state.copyWith(status: StateStatus.loading, error: null));
    try {
      final items = await _mediaRepository.pickFiles();
      final status = items.isEmpty ? StateStatus.empty : StateStatus.loaded;
      emit(state.copyWith(items: items, status: status));
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _persistQueue(List<PureCastMedia> items) async {
    final companions = items.asMap().entries.map((e) {
      final index = e.key;
      final media = e.value;
      return PlaybackQueueTableCompanion(
        id: drift.Value('${media.uri}_$index'),
        mediaUri: drift.Value(media.uri),
        mediaType: drift.Value(media.type.name),
        title: drift.Value(media.title),
        thumbnail: drift.Value(media.thumbnailUrl),
        durationMs: drift.Value(media.duration?.inMilliseconds),
        isLocalFile: drift.Value(media.isLocalFile),
        queueOrder: drift.Value(index),
        createdAt: drift.Value(DateTime.now()),
      );
    }).toList();

    await _db.saveQueue(companions);
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
