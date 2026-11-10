import 'dart:async';
import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';

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
    log("Queue State Changed", name: "Playback Coordinator");
    final sessionState = _sessionBloc!.state;
    final items = queueState.items;
    log("Queue Length ${items.length}", name: "Playback Coordinator");
    final currentIndex = queueState.currentIndex;

    final hasActivePlayback = sessionState.activeMedia != null &&
        sessionState.sessionState != PureCastSessionState.disconnected &&
        sessionState.sessionState != PureCastSessionState.completed;

    // Track the queue index. On the very first Next/Previous click,
    // _lastHandledQueueIndex is null, so we can't compare. Instead,
    // we detect that the index has changed from the previously tracked
    // value and load the media at the new index.
    final prevIndex = _lastHandledQueueIndex;
    final indexChanged = prevIndex != null && prevIndex != currentIndex;

    // Case 1: First item added, or item added when there is NO active playback
    if (!hasActivePlayback && items.isNotEmpty) {
      int targetIndex = currentIndex;

      // If currentIndex is out of bounds, load the last item.
      if (currentIndex < 0 || currentIndex >= items.length) {
        targetIndex = items.length - 1;
      }
      // If currentIndex points to the previously playing media (now stopped/
      // completed) and a new item was added, load the most recent one.
      else if (sessionState.activeMedia != null &&
          currentIndex >= 0 &&
          currentIndex < items.length &&
          items[currentIndex].uri == sessionState.activeMedia!.uri) {
        targetIndex = items.length - 1;
      }
      // If nothing is playing (activeMedia cleared after disconnect) and there
      // are multiple items, a new item was likely just added — load it.
      else if (sessionState.activeMedia == null && items.length > 1) {
        targetIndex = items.length - 1;
      }

      if (targetIndex >= 0 && targetIndex < items.length) {
        log("Loading media (no active playback) index $targetIndex",
            name: "Playback Coordinator");
        _lastHandledQueueIndex = targetIndex;
        _loadMediaAtCurrentIndex(items[targetIndex]);
        return;
      }
    }

    // Case 2: Explicit queue index advance (Next/Previous/Manual Index change)
    if (indexChanged && currentIndex >= 0 && currentIndex < items.length) {
      log("Queue index changed to $currentIndex", name: "Playback Coordinator");
      _lastHandledQueueIndex = currentIndex;
      _loadMediaAtCurrentIndex(items[currentIndex]);
      return;
    }

    // Always update the tracked index so subsequent clicks are detected.
    // On first click (_lastHandledQueueIndex == null), set it so the
    // second click will be detected as a change.
    if (prevIndex == null) {
      _lastHandledQueueIndex = currentIndex;
    }
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
      log("Loading media event", name: "Playback Coordinator");
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
