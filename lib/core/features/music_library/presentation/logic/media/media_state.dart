import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';

part 'media_state.freezed.dart';

@freezed
abstract class MediaState with _$MediaState {
  const factory MediaState({
    @Default([]) List<PureCastMedia> mediaItems,
    @Default(StateStatus.initial) StateStatus status,
    String? error,
    @Default(false) bool hasPermission,
    @Default(RequestType.common) RequestType selectedFilter,
    @Default(0) int page,
    @Default(false) bool hasMore,
  }) = _MediaState;
}
