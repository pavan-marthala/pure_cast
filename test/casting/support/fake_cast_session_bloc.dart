import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';

/// Minimal [ICastService] for widget tests: only the streams the bloc
/// subscribes to are implemented.
class NoopCastService implements ICastService {
  @override
  Stream<PureCastSessionState> get sessionStateStream =>
      Stream<PureCastSessionState>.empty();

  @override
  Stream<Duration> get positionStream => Stream<Duration>.empty();

  @override
  Stream<Duration> get durationStream => Stream<Duration>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class NoopAppDatabase implements AppDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// A bloc that records events instead of processing them. This keeps widget
/// tests focused on what the widget dispatches.
class RecordingCastSessionBloc extends CastSessionBloc {
  RecordingCastSessionBloc()
    : super(
        NoopCastService(),
        PlaybackHistoryRepository(NoopAppDatabase()),
        NoopAppDatabase(),
      );

  final List<CastSessionEvent> events = <CastSessionEvent>[];

  @override
  void add(CastSessionEvent event) {
    events.add(event);
  }
}
