import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/cast_seek_bar.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

import 'support/fake_cast_session_bloc.dart';

Widget _wrap({
  required Widget child,
  required RecordingCastSessionBloc bloc,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: BlocProvider<CastSessionBloc>.value(
      value: bloc,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('dispatches exactly one SeekMediaEvent when the drag ends', (
    tester,
  ) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: const CastSeekBar(
          position: Duration(seconds: 10),
          duration: Duration(seconds: 100),
          canSeek: true,
          restarting: false,
        ),
      ),
    );

    expect(find.text('00:10'), findsOneWidget);
    expect(find.text('01:40'), findsOneWidget);

    final slider = find.byType(Slider);
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();

    expect(
      bloc.events.whereType<SeekMediaEvent>(),
      isEmpty,
      reason: 'no seek may be dispatched while the finger is down',
    );

    await gesture.up();
    await tester.pump();

    final seeks = bloc.events.whereType<SeekMediaEvent>().toList();
    expect(seeks, hasLength(1));
    expect(seeks.single.position, greaterThan(const Duration(seconds: 10)));
    expect(
      seeks.single.position,
      lessThanOrEqualTo(const Duration(seconds: 100)),
    );

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });

  testWidgets('is disabled when the duration is zero', (tester) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: const CastSeekBar(
          position: Duration(seconds: 10),
          duration: Duration.zero,
          canSeek: true,
          restarting: false,
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(60, 0));
    await gesture.up();
    await tester.pump();

    expect(bloc.events.whereType<SeekMediaEvent>(), isEmpty);

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });

  testWidgets('is disabled when the device cannot seek', (tester) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: const CastSeekBar(
          position: Duration(seconds: 10),
          duration: Duration(seconds: 100),
          canSeek: false,
          restarting: false,
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    // Not awaited: bloc.close() never completes inside the widget tester
    // fake-async zone (broadcast stream done event is not delivered).
    unawaited(bloc.close());
  });

  testWidgets('shows the pending seek preview in the slider and the label', (
    tester,
  ) async {
    final bloc = RecordingCastSessionBloc();
    await tester.pumpWidget(
      _wrap(
        bloc: bloc,
        child: const CastSeekBar(
          position: Duration(seconds: 10),
          duration: Duration(seconds: 100),
          canSeek: true,
          restarting: false,
          seekPreview: Duration(seconds: 42),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 42000);
    expect(find.text('00:42'), findsOneWidget);
    expect(find.text('00:10'), findsNothing);
    expect(find.text('01:40'), findsOneWidget);

    unawaited(bloc.close());
  });
}
