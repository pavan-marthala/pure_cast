part of 'recently_played_bloc.dart';

@freezed
abstract class RecentlyPlayedEvent with _$RecentlyPlayedEvent {
  const factory RecentlyPlayedEvent.load() = LoadRecentlyPlayedEvent;
  const factory RecentlyPlayedEvent.refresh() = RefreshRecentlyPlayedEvent;
  const factory RecentlyPlayedEvent.remove(String mediaUri) = RemoveRecentlyPlayedEvent;
}
