part of 'media_bloc.dart';

@freezed
abstract class MediaEvent with _$MediaEvent {
  const factory MediaEvent.requestPermission() = RequestPermissionMediaEvent;
  const factory MediaEvent.loadMediaItems({
    @Default(RequestType.common) RequestType filterType,
  }) = LoadMediaItemsEvent;
  const factory MediaEvent.loadNextPage() = LoadNextPageMediaEvent;
}
