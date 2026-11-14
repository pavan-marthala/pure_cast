import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/cast_audio_controls.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

import 'support/fake_cast_session_bloc.dart';

const _tracks = [
  PureCastAudioTrack(
    index: 0,
    language: 'eng',
    codec: 'ac3',
    channels: 6,
    isDefault: true,
  ),
  PureCastAudioTrack(
    index: 1,
    language: 'spa',
    codec: 'ac3',
    channels: 2,
  ),
];

Widget _wrap({
  required Widget child,
  required RecordingCastSessionBloc bloc,
}) {
  // The app provides CastSessionBloc above MaterialApp; modal sheets use the
  // root navigator, so the provider has to be above it here too.
  return BlocProvider<CastSessionBloc>.value(
    value: bloc,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('audio sheet lists tracks, marks the active one, and dispatches '
      'selectAudio on tap', (tester) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => AudioTrackSwitcher.show(
              context,
              tracks: _tracks,
              activeIndex: 0,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('English · AC3 5.1'), findsOneWidget);
    expect(find.text('Spanish · AC3 2.0'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Spanish · AC3 2.0'));
    await tester.pumpAndSettle();

    final selects = bloc.events.whereType<SelectAudioEvent>().toList();
    expect(selects, hasLength(1));
    expect(selects.single.index, 1);

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });

  testWidgets('a single-track row shows the label and is not tappable', (
    tester,
  ) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: AudioTrackRow(
          tracks: [_tracks.first],
          activeIndex: 0,
          canChange: true,
          restarting: false,
        ),
      ),
    );

    expect(find.text('English · AC3 5.1'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    expect(find.byType(AudioTrackSwitcher), findsNothing);
    expect(bloc.events, isEmpty);

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });

  testWidgets('a multi-track row opens the audio sheet', (tester) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: const AudioTrackRow(
          tracks: _tracks,
          activeIndex: 0,
          canChange: true,
          restarting: false,
        ),
      ),
    );

    expect(find.text('English · AC3 5.1'), findsOneWidget);

    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    expect(find.byType(AudioTrackSwitcher), findsOneWidget);

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });

  testWidgets('the row shows N/A when the device cannot change audio', (
    tester,
  ) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: const AudioTrackRow(
          tracks: _tracks,
          activeIndex: 0,
          canChange: false,
          restarting: false,
        ),
      ),
    );

    expect(find.text('N/A'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });
}
