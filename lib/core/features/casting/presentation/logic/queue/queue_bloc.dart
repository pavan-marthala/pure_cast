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
    on<PlayMediaInQueueEvent>(_onPlayMediaInQueue);
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
              thumbnailBytes: r.thumbnailBytes,
              duration: r.durationMs != null
                  ? Duration(milliseconds: r.durationMs!)
                  : null,
              isLocalFile: r.isLocalFile,
            ),
          )
          .toList();

      final status = items.isEmpty ? StateStatus.empty : StateStatus.loaded;
      emit(
        state.copyWith(
          items: items,
          currentIndex: items.isEmpty ? 0 : state.currentIndex,
          status: status,
          restoredFromStorage: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _onAddToQueue(
    AddToQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    try {
      // Never queue the same media twice. Selecting the existing entry also
      // makes a repeated tap play it instead of creating a duplicate.
      final existingIndex = state.items.indexWhere(
        (i) => i.uri == event.media.uri,
      );
      if (existingIndex != -1) {
        emit(
          state.copyWith(
            currentIndex: existingIndex,
            status: StateStatus.loaded,
            restoredFromStorage: false,
            playRequestId: state.playRequestId + 1,
            pendingStartPosition: null,
          ),
        );
        return;
      }

      final updatedItems = List<PureCastMedia>.from(state.items)
        ..add(event.media);

      // If the queue was empty, start playing from the first item.
      final newIndex = state.items.isEmpty ? 0 : state.currentIndex;

      emit(
        state.copyWith(
          items: updatedItems,
          currentIndex: newIndex,
          status: StateStatus.loaded,
          restoredFromStorage: false,
        ),
      );
      await _persistQueue(updatedItems);
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _onPlayMediaInQueue(
    PlayMediaInQueueEvent event,
    Emitter<QueueState> emit,
  ) async {
    try {
      // The queue entry itself never stores the one-shot resume offset.
      final item = _withoutStartPosition(event.media);
      final updatedItems = List<PureCastMedia>.from(state.items);
      final existingIndex = updatedItems.indexWhere((i) => i.uri == item.uri);

      final int index;
      var shouldPersist = false;
      if (existingIndex == -1) {
        updatedItems.add(item);
        index = updatedItems.length - 1;
        shouldPersist = true;
      } else {
        updatedItems[existingIndex] = item;
        index = existingIndex;
      }

      emit(
        state.copyWith(
          items: updatedItems,
          currentIndex: index,
          status: StateStatus.loaded,
          restoredFromStorage: false,
          playRequestId: state.playRequestId + 1,
          pendingStartPosition: event.startPosition,
        ),
      );
      if (shouldPersist) {
        await _persistQueue(updatedItems);
      }
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

      // Adjust currentIndex if it's now out of bounds or points to a removed item.
      int newIndex = state.currentIndex;
      if (newIndex >= updatedItems.length) {
        newIndex = updatedItems.isEmpty ? 0 : updatedItems.length - 1;
      }

      final status = updatedItems.isEmpty
          ? StateStatus.empty
          : StateStatus.loaded;
      emit(
        state.copyWith(
          items: updatedItems,
          currentIndex: newIndex,
          status: status,
        ),
      );
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

      emit(
        state.copyWith(
          items: updatedItems,
          status: StateStatus.loaded,
        ),
      );
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
          restoredFromStorage: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  void _onNextQueueItem(NextQueueItemEvent event, Emitter<QueueState> emit) {
    if (state.items.isEmpty) return;
    if (state.currentIndex < state.items.length - 1) {
      emit(
        state.copyWith(
          currentIndex: state.currentIndex + 1,
          restoredFromStorage: false,
        ),
      );
    }
  }

  void _onPreviousQueueItem(
    PreviousQueueItemEvent event,
    Emitter<QueueState> emit,
  ) {
    if (state.items.isEmpty) return;
    if (state.currentIndex > 0) {
      emit(
        state.copyWith(
          currentIndex: state.currentIndex - 1,
          restoredFromStorage: false,
        ),
      );
    }
  }

  void _onSetCurrentIndex(
    SetCurrentIndexEvent event,
    Emitter<QueueState> emit,
  ) {
    if (event.index >= 0 && event.index < state.items.length) {
      emit(
        state.copyWith(
          currentIndex: event.index,
          restoredFromStorage: false,
        ),
      );
    }
  }

  Future<void> _onPickFiles(
    PicFilesEvent event,
    Emitter<QueueState> emit,
  ) async {
    emit(state.copyWith(status: StateStatus.loading, error: null));
    try {
      final pickedItems = await _mediaRepository.pickFiles();
      // User cancelled or picker returned nothing — keep existing queue intact.
      if (pickedItems.isEmpty) {
        emit(
          state.copyWith(
            status: state.items.isEmpty
                ? StateStatus.empty
                : StateStatus.loaded,
            error: null,
          ),
        );
        return;
      }

      // Add picked files to the existing queue instead of replacing it, and
      // skip files that are already queued.
      final knownUris = state.items.map((i) => i.uri).toSet();
      final newItems = <PureCastMedia>[];
      for (final item in pickedItems) {
        if (knownUris.add(item.uri)) {
          newItems.add(item);
        }
      }
      if (newItems.isEmpty) {
        emit(
          state.copyWith(
            status: state.items.isEmpty
                ? StateStatus.empty
                : StateStatus.loaded,
            error: null,
          ),
        );
        return;
      }

      final updatedItems = List<PureCastMedia>.from(state.items)
        ..addAll(newItems);

      // If the queue was previously empty, start at the first item.
      final newIndex = state.items.isEmpty ? 0 : state.currentIndex;

      emit(
        state.copyWith(
          items: updatedItems,
          currentIndex: newIndex,
          status: StateStatus.loaded,
          error: null,
          restoredFromStorage: false,
        ),
      );
      await _persistQueue(updatedItems);
    } catch (e) {
      emit(state.copyWith(status: StateStatus.error, error: e.toString()));
    }
  }

  Future<void> _persistQueue(List<PureCastMedia> items) async {
    final companions = items.asMap().entries.map((e) {
      final index = e.key;
      final media = e.value;
      return PlaybackQueueTableCompanion(
        id: drift.Value(media.uri),
        mediaUri: drift.Value(media.uri),
        mediaType: drift.Value(media.type.name),
        title: drift.Value(media.title),
        thumbnail: drift.Value(media.thumbnailUrl),
        thumbnailBytes: drift.Value(media.thumbnailBytes),
        durationMs: drift.Value(media.duration?.inMilliseconds),
        isLocalFile: drift.Value(media.isLocalFile),
        queueOrder: drift.Value(index),
        createdAt: drift.Value(DateTime.now()),
      );
    }).toList();

    await _db.saveQueue(companions);
  }

  /// A copy of [media] without the transient resume offset.
  ///
  /// Queue entries must never carry a start position: auto-advance loads the
  /// next entry without seeking.
  static PureCastMedia _withoutStartPosition(PureCastMedia media) {
    return PureCastMedia(
      uri: media.uri,
      type: media.type,
      title: media.title,
      thumbnailUrl: media.thumbnailUrl,
      thumbnailBytes: media.thumbnailBytes,
      duration: media.duration,
      isLocalFile: media.isLocalFile,
      subtitles: media.subtitles,
      defaultSubtitle: media.defaultSubtitle,
    );
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
