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

  void _onClearResults(
    ClearResultsEvent event,
    Emitter<SubtitleExtractionState> emit,
  ) {
    emit(const SubtitleExtractionState());
  }
}
