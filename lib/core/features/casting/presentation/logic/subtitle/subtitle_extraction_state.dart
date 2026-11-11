part of 'subtitle_extraction_bloc.dart';

enum SubtitleExtractionStatus {
  initial,
  inspecting,
  noSubtitles,
  subtitlesDetected,
  extracting,
  extracted,
  partialFailure,
  error,
  cancelled,
}

@freezed
abstract class SubtitleExtractionState with _$SubtitleExtractionState {
  const SubtitleExtractionState._();
  const factory SubtitleExtractionState({
    @Default(SubtitleExtractionStatus.initial)
    SubtitleExtractionStatus status,
    String? currentFilePath,
    String? error,
    @Default([]) List<SubtitleStreamInfo> streams,
    SubtitleExtractionResult? lastResult,
    @Default([]) List<SubtitleExtractionResult> extractionResults,
  }) = _SubtitleExtractionState;
}
