import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

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
    final colors = context.appColors;
    final typo = context.appTypography;
    return Container(
      padding: .all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: .circular(12),
      ),
      child: Row(
        spacing: 14,
        children: [
          Container(
            padding: .all(6),
            decoration: BoxDecoration(
              color: colors.gray,
              borderRadius: .circular(8),
            ),
            child: Icon(Icons.tv, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text("Nothing Playing right now", style: typo.titleSmall),
                Text("Pick something form your media to start casting"),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "Browse Files",
              style: typo.titleSmall.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
