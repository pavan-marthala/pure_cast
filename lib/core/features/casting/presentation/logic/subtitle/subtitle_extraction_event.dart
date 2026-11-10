part of 'subtitle_extraction_bloc.dart';

@freezed
abstract class SubtitleExtractionEvent with _$SubtitleExtractionEvent {
  const factory SubtitleExtractionEvent.inspectSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
  }) = InspectSubtitlesEvent;

  const factory SubtitleExtractionEvent.clearResults() = ClearResultsEvent;
}
