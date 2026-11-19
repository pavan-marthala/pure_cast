part of 'media_bloc.dart';

@freezed
abstract class MediaState with _$MediaState {
  const factory MediaState({
    @Default([]) List<PureCastMedia> mediaItems,
    @Default(StateStatus.initial) StateStatus status,
    @Default(false) bool hasPermission,
    @Default(RequestType.common) RequestType selectedFilter,
    @Default(0) int page,
    @Default(true) bool hasMore,
    /// Saved resume position per media URI, used for the progress bar.
    @Default(<String, Duration>{}) Map<String, Duration> resumePositions,
    String? error,
  }) = _MediaState;
}
