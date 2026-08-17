import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_event.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_state.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_event.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_state.dart';

abstract interface class IPlaybackCoordinator {
  void start(QueueBloc queueBloc, CastSessionBloc sessionBloc);
  Future<void> dispose();
}

@lazySingleton
class PlaybackCoordinator implements IPlaybackCoordinator {
  final PlaybackHistoryRepository _historyRepo;

  QueueBloc? _queueBloc;
  CastSessionBloc? _sessionBloc;

  StreamSubscription<QueueState>? _queueSubscription;
  StreamSubscription<CastSessionState>? _sessionSubscription;

  bool _isTransitioning = false;
  int? _lastHandledQueueLength;
  int? _lastHandledQueueIndex;
  PureCastSessionState? _lastHandledSessionState;

  PlaybackCoordinator(this._historyRepo);

  @override
  void start(QueueBloc queueBloc, CastSessionBloc sessionBloc) {
    if (_queueBloc == queueBloc && _sessionBloc == sessionBloc) return;

    _disposeSubscriptions();

    _queueBloc = queueBloc;
    _sessionBloc = sessionBloc;

    _queueSubscription = _queueBloc!.stream.listen(_onQueueStateChanged);
    _sessionSubscription = _sessionBloc!.stream.listen(_onSessionStateChanged);
  }

  void _onQueueStateChanged(QueueState queueState) {
    if (_isTransitioning || _sessionBloc == null) return;

    final sessionState = _sessionBloc!.state;
    final items = queueState.items;
    final currentIndex = queueState.currentIndex;

    final previousLength = _lastHandledQueueLength ?? 0;
    _lastHandledQueueLength = items.length;

    // Case 1: First media added to an empty queue
    if (previousLength == 0 && items.isNotEmpty && currentIndex == 0) {
      if (sessionState.activeMedia == null) {
        _loadMediaAtCurrentIndex(items[0]);
        return;
      }
    }

    // Case 2: Explicit queue index advance (Next/Previous/Index change)
    if (_lastHandledQueueIndex != null && _lastHandledQueueIndex != currentIndex) {
      _lastHandledQueueIndex = currentIndex;
      if (currentIndex >= 0 && currentIndex < items.length) {
        _loadMediaAtCurrentIndex(items[currentIndex]);
        return;
      }
    }
    _lastHandledQueueIndex = currentIndex;
  }

  void _onSessionStateChanged(CastSessionState sessionState) async {
    if (_isTransitioning || _queueBloc == null) return;

    final currentState = sessionState.sessionState;
    if (_lastHandledSessionState == currentState) return;
    _lastHandledSessionState = currentState;

    // React to playback completion
    if (currentState == PureCastSessionState.completed) {
      await _handlePlaybackCompletion();
    }
  }

  Future<void> _handlePlaybackCompletion() async {
    if (_isTransitioning || _queueBloc == null || _sessionBloc == null) return;

    _isTransitioning = true;
    try {
      // Check user preferences for autoPlayNext
      final prefs = await _historyRepo.getPreferences();
      if (!prefs.autoPlayNext) return;

      final queueState = _queueBloc!.state;
      final items = queueState.items;
      final currentIndex = queueState.currentIndex;

      if (currentIndex + 1 < items.length) {
        final nextIndex = currentIndex + 1;
        final nextMedia = items[nextIndex];

        _queueBloc!.add(SetCurrentIndexEvent(nextIndex));
        _sessionBloc!.add(LoadMediaEvent(nextMedia));
      }
    } finally {
      _isTransitioning = false;
    }
  }

  void _loadMediaAtCurrentIndex(PureCastMedia media) {
    if (_isTransitioning || _sessionBloc == null) return;

    _isTransitioning = true;
    try {
      _sessionBloc!.add(LoadMediaEvent(media));
    } finally {
      _isTransitioning = false;
    }
  }

  void _disposeSubscriptions() {
    _queueSubscription?.cancel();
    _sessionSubscription?.cancel();
    _queueSubscription = null;
    _sessionSubscription = null;
  }

  @override
  Future<void> dispose() async {
    _disposeSubscriptions();
    _queueBloc = null;
    _sessionBloc = null;
  }
}
