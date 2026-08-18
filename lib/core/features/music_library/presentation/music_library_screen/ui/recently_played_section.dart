import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pure_cast/core/features/music_library/presentation/logic/recently_played/recently_played_bloc.dart';

import 'music_library_screen.dart';

class RecentlyPlayedSection extends StatelessWidget {
  const RecentlyPlayedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyPlayedBloc, RecentlyPlayedState>(
      builder: (context, state) {
        return state.status == .loading
            ? Center(child: CircularProgressIndicator())
            : MasonryGridView.count(
                itemCount: state.media.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                itemBuilder: (BuildContext context, int index) {
                  return MediaWidget(media: state.media[index]);
                },
              );
      },
    );
  }
}
