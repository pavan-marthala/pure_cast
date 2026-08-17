part of 'music_library_cubit.dart';

sealed class MusicLibraryState extends Equatable {
  const MusicLibraryState();
}

final class MusicLibraryInitialState extends MusicLibraryState {
  const MusicLibraryInitialState();
  
  @override
  List<Object> get props => [];
}
