import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'music_library_state.dart';

class MusicLibraryCubit extends Cubit<MusicLibraryState> {
  MusicLibraryCubit() : super(const MusicLibraryInitialState());
}
