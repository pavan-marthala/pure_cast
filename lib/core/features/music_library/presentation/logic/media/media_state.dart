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
    String? error,
  }) = _MediaState;
}
