import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_state.dart';

class PlayerSection extends StatelessWidget {
  const PlayerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CastSessionBloc, CastSessionState, bool>(
      selector: (state) {
        return state.isCasting;
      },
      builder: (context, isCasting) {
        return isCasting ? CurrentlyPlaying() : NothingPlayingSection();
      },
    );
  }
}

class CurrentlyPlaying extends StatelessWidget {
  const CurrentlyPlaying({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class NothingPlayingSection extends StatelessWidget {
  const NothingPlayingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
