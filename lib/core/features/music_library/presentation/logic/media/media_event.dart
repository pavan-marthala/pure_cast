import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photo_manager/photo_manager.dart';

part 'media_event.freezed.dart';

@freezed
abstract class MediaEvent with _$MediaEvent {
  const factory MediaEvent.requestPermission() = RequestPermissionMediaEvent;
  const factory MediaEvent.loadMedia({
    @Default(RequestType.common) RequestType filterType,
    @Default(false) bool refresh,
  }) = LoadMediaItemsEvent;
  const factory MediaEvent.loadNextPage() = LoadNextPageMediaEvent;
}
