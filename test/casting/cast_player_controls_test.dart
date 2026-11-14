import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/home/presentation/home_screen/ui/widgets/player_controls.dart';
import 'package:pure_cast/core/features/music_library/data/repository/media_repository.dart';
import 'package:pure_cast/core/theme/app_theme.dart';

import 'support/fake_cast_session_bloc.dart';

class _NoopMediaRepository implements MediaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

const _device = PureCastDevice(
  id: 'tv_1',
  name: 'Living Room TV',
  protocol: PureCastProtocol.chromecast,
  host: '192.168.1.10',
  port: 8009,
  capabilities: PureCastCapabilities(canSeek: true),
);

const _media = PureCastMedia(
  uri: '/videos/movie.mkv',
  type: PureCastMediaType.mkv,
  title: 'Movie',
  isLocalFile: true,
);

CastSessionState _readyState({
  Duration duration = const Duration(minutes: 10),
  bool restarting = false,
}) {
  return CastSessionState(
    sessionState: PureCastSessionState.playing,
    activeMedia: _media,
    activeDevice: _device,
    duration: duration,
    position: const Duration(seconds: 30),
    restarting: restarting,
  );
}

Widget _wrap({
  required CastSessionBloc sessionBloc,
  required QueueBloc queueBloc,
  required double width,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<CastSessionBloc>.value(value: sessionBloc),
      BlocProvider<QueueBloc>.value(value: queueBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: const PlayerControls()),
        ),
      ),
    ),
  );
}

(StateCastSessionBloc, QueueBloc) _blocs(CastSessionState state) {
  return (
    StateCastSessionBloc(state),
    QueueBloc(NoopAppDatabase(), _NoopMediaRepository()),
  );
}

void _dispose(StateCastSessionBloc sessionBloc, QueueBloc queueBloc) {
  // Not awaited: BlocBase.close() never completes inside the widget tester
  // fake-async zone (broadcast stream done event is not delivered).
  unawaited(sessionBloc.close());
  unawaited(queueBloc.close());
}

void main() {
  testWidgets('renders the seven controls in the requested order', (
    tester,
  ) async {
    final (sessionBloc, queueBloc) = _blocs(_readyState());
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 360),
    );

    final icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .map((icon) => icon.icon)
        .toList();

    expect(icons, [
      Icons.skip_previous,
      Icons.replay_30,
      Icons.replay_10,
      Icons.pause_rounded,
      Icons.forward_10,
      Icons.forward_30,
      Icons.skip_next,
    ]);

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('does not overflow at 360 width', (tester) async {
    final (sessionBloc, queueBloc) = _blocs(_readyState());
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 360),
    );

    expect(tester.takeException(), isNull);

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('does not overflow at 320 width', (tester) async {
    final (sessionBloc, queueBloc) = _blocs(_readyState());
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 320),
    );

    expect(tester.takeException(), isNull);

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('does not overflow at 288 width (320dp screen minus padding)', (
    tester,
  ) async {
    final (sessionBloc, queueBloc) = _blocs(_readyState());
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 288),
    );

    expect(tester.takeException(), isNull);

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('taps dispatch +/-10s and +/-30s relative seeks', (tester) async {
    final (sessionBloc, queueBloc) = _blocs(_readyState());
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 360),
    );

    for (final icon in [
      Icons.replay_30,
      Icons.replay_10,
      Icons.forward_10,
      Icons.forward_30,
    ]) {
      await tester.tap(find.byIcon(icon));
      await tester.pump();
    }

    expect(
      sessionBloc.events.whereType<SeekRelativeEvent>().map((e) => e.delta),
      [
        const Duration(seconds: -30),
        const Duration(seconds: -10),
        const Duration(seconds: 10),
        const Duration(seconds: 30),
      ],
    );

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('seek buttons are disabled when the duration is zero', (
    tester,
  ) async {
    final (sessionBloc, queueBloc) = _blocs(
      _readyState(duration: Duration.zero),
    );
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 360),
    );

    await tester.tap(find.byIcon(Icons.forward_30));
    await tester.pump();

    expect(sessionBloc.events.whereType<SeekRelativeEvent>(), isEmpty);

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('seek buttons are disabled while a restart is pending', (
    tester,
  ) async {
    final (sessionBloc, queueBloc) = _blocs(_readyState(restarting: true));
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 360),
    );

    await tester.tap(find.byIcon(Icons.replay_30));
    await tester.pump();

    expect(sessionBloc.events.whereType<SeekRelativeEvent>(), isEmpty);

    _dispose(sessionBloc, queueBloc);
  });

  testWidgets('seek buttons are disabled when the device cannot seek', (
    tester,
  ) async {
    const noSeekDevice = PureCastDevice(
      id: 'tv_2',
      name: 'No Seek TV',
      protocol: PureCastProtocol.dlna,
      host: '192.168.1.11',
      port: 8009,
      capabilities: PureCastCapabilities(canSeek: false),
    );
    final (sessionBloc, queueBloc) = _blocs(
      CastSessionState(
        sessionState: PureCastSessionState.playing,
        activeMedia: _media,
        activeDevice: noSeekDevice,
        duration: const Duration(minutes: 10),
      ),
    );
    await tester.pumpWidget(
      _wrap(sessionBloc: sessionBloc, queueBloc: queueBloc, width: 360),
    );

    await tester.tap(find.byIcon(Icons.forward_10));
    await tester.pump();

    expect(sessionBloc.events.whereType<SeekRelativeEvent>(), isEmpty);

    _dispose(sessionBloc, queueBloc);
  });
}
