part of 'recently_played_bloc.dart';

@freezed
abstract class RecentlyPlayedState with _$RecentlyPlayedState {
  const factory RecentlyPlayedState({
    @Default([]) List<PureCastMedia> media,
    @Default(StateStatus.initial) StateStatus status,
    String? error,
  }) = _RecentlyPlayedState;
}
