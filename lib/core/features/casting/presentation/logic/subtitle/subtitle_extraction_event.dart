part of 'subtitle_extraction_bloc.dart';

@freezed
abstract class SubtitleExtractionEvent with _$SubtitleExtractionEvent {
  const factory SubtitleExtractionEvent.inspectSubtitles({
    required String filePath,
    required int fileSize,
    required DateTime lastModified,
  }) = InspectSubtitlesEvent;

  const factory SubtitleExtractionEvent.extractSingleTrack({
    required SubtitleStreamInfo stream,
    required String sourcePath,
  }) = ExtractSingleTrackEvent;

  const factory SubtitleExtractionEvent.extractAllTracks({
    required String sourcePath,
  }) = ExtractAllTracksEvent;

  const factory SubtitleExtractionEvent.cancelExtraction() = CancelExtractionEvent;

  const factory SubtitleExtractionEvent.clearResults() = ClearResultsEvent;
}
