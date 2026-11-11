import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_extraction_service.dart';

part 'subtitle_extraction_event.dart';
part 'subtitle_extraction_state.dart';
part 'subtitle_extraction_bloc.freezed.dart';

@injectable
class SubtitleExtractionBloc
    extends Bloc<SubtitleExtractionEvent, SubtitleExtractionState> {
  final SubtitleExtractionService _extractionService;

  SubtitleExtractionBloc(this._extractionService)
    : super(const SubtitleExtractionState()) {
    on<InspectSubtitlesEvent>(_onInspectSubtitles);
    on<ExtractSingleTrackEvent>(_onExtractSingleTrack);
    on<ExtractAllTracksEvent>(_onExtractAllTracks);
    on<CancelExtractionEvent>(_onCancelExtraction);
    on<ClearResultsEvent>(_onClearResults);
  }

  Future<void> _onInspectSubtitles(
    InspectSubtitlesEvent event,
    Emitter<SubtitleExtractionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SubtitleExtractionStatus.inspecting,
        currentFilePath: event.filePath,
        error: null,
      ),
    );

    try {
      final probeResult = await _extractionService.probeAndCacheSubtitles(
        filePath: event.filePath,
        fileSize: event.fileSize,
        lastModified: event.lastModified,
      );

      if (!probeResult.hasSubtitles) {
        emit(
          state.copyWith(
            status: SubtitleExtractionStatus.noSubtitles,
            streams: [],
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: SubtitleExtractionStatus.subtitlesDetected,
          streams: probeResult.streams,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SubtitleExtractionStatus.error,
          error: 'Failed to inspect subtitles: $e',
        ),
      );
    }
  }

  Future<void> _onExtractSingleTrack(
    ExtractSingleTrackEvent event,
    Emitter<SubtitleExtractionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SubtitleExtractionStatus.extracting,
        currentFilePath: event.sourcePath,
        error: null,
      ),
    );

    try {
      final result = await _extractionService.extractSubtitle(
        sourcePath: event.sourcePath,
        stream: event.stream,
      );

      if (result.isSuccess) {
        emit(
          state.copyWith(
            status: SubtitleExtractionStatus.extracted,
            lastResult: result,
            extractionResults: [
              ...state.extractionResults,
              result,
            ],
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SubtitleExtractionStatus.partialFailure,
            lastResult: result,
            extractionResults: [
              ...state.extractionResults,
              result,
            ],
            error: result.error?.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SubtitleExtractionStatus.error,
          error: 'Extraction failed: $e',
        ),
      );
    }
  }

  Future<void> _onExtractAllTracks(
    ExtractAllTracksEvent event,
    Emitter<SubtitleExtractionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SubtitleExtractionStatus.extracting,
        currentFilePath: event.sourcePath,
        error: null,
      ),
    );

    try {
      final batchResult = await _extractionService.extractAllSubtitles(
        sourcePath: event.sourcePath,
        onProgress: (result) {
          emit(
            state.copyWith(
              lastResult: result,
              extractionResults: [
                ...state.extractionResults,
                result,
              ],
            ),
          );
        },
      );

      if (batchResult.allSucceeded) {
        emit(
          state.copyWith(
            status: SubtitleExtractionStatus.extracted,
            extractionResults: batchResult.results,
          ),
        );
      } else if (batchResult.allFailed) {
        emit(
          state.copyWith(
            status: SubtitleExtractionStatus.error,
            extractionResults: batchResult.results,
            error: 'All subtitle extractions failed',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SubtitleExtractionStatus.partialFailure,
            extractionResults: batchResult.results,
            error: 'Some subtitle extractions failed',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SubtitleExtractionStatus.error,
          error: 'Batch extraction failed: $e',
        ),
      );
    }
  }

  void _onCancelExtraction(
    CancelExtractionEvent event,
    Emitter<SubtitleExtractionState> emit,
  ) async {
    await _extractionService.cancelAllExtractions();
    emit(
      state.copyWith(
        status: SubtitleExtractionStatus.cancelled,
      ),
    );
  }

  void _onClearResults(
    ClearResultsEvent event,
    Emitter<SubtitleExtractionState> emit,
  ) {
    emit(const SubtitleExtractionState());
  }

}
