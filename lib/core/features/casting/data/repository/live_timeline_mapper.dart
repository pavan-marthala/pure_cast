import 'dart:async';

/// Maps raw receiver positions of a live MKV stream onto the source-file
/// ("virtual") timeline, and guards the restart race.
///
/// A live MKV stream restarted with `-ss` makes the receiver's clock start
/// again at ~0. The real playback position is therefore
/// `liveStartOffset + receiverPosition`.
///
/// Right after a restart the receiver can still deliver one late
/// `MEDIA_STATUS` belonging to the media session we just replaced. That event
/// would be mapped with the *new* offset and produce a bogus jump. The
/// receiver assigns a fresh `mediaSessionId` to every LOAD, so those stale
/// events are identifiable: while a restart is pending, position events are
/// dropped until one arrives that carries a different (new) media session id.
/// That first event is guaranteed to belong to the new stream — it already
/// carries the restarted clock — so it is accepted even if the receiver has
/// not reported `PLAYING` yet.
///
/// The guard is a fail-safe: if no event from the new media session arrives
/// within [restartTimeout] (5 seconds by default), it disarms itself so
/// positions can never be dropped forever.
class LiveTimelineMapper {
  LiveTimelineMapper({this.restartTimeout = const Duration(seconds: 5)});

  /// How long the guard waits for the first event of the new media session
  /// before disarming itself.
  final Duration restartTimeout;

  bool _restartPending = false;
  int? _restartedFromMediaSessionId;
  Timer? _restartTimer;

  /// True between [armRestart] and the first position event of the new media
  /// session (or [cancel], or the [restartTimeout] fail-safe).
  bool get isRestartPending => _restartPending;

  /// The media session id being replaced by the pending restart.
  int? get restartedFromMediaSessionId => _restartedFromMediaSessionId;

  /// Arms the guard before issuing a live restart/seek.
  ///
  /// [currentMediaSessionId] is the receiver media session that will be
  /// replaced (captured *before* the new LOAD is sent).
  void armRestart(int? currentMediaSessionId) {
    _restartPending = true;
    _restartedFromMediaSessionId = currentMediaSessionId;
    _restartTimer?.cancel();
    _restartTimer = Timer(restartTimeout, cancel);
  }

  /// Disarms the guard (the restart failed and no new session will report).
  void cancel() {
    _restartTimer?.cancel();
    _restartTimer = null;
    _restartPending = false;
    _restartedFromMediaSessionId = null;
  }

  /// Releases the fail-safe timer. Safe to call more than once.
  void dispose() {
    _restartTimer?.cancel();
    _restartTimer = null;
  }

  /// Returns the virtual position for [receiverPosition], or `null` when the
  /// event must be dropped because it belongs to the replaced media session.
  Duration? mapPosition({
    required Duration receiverPosition,
    required Duration offset,
    required int? mediaSessionId,
  }) {
    if (_restartPending) {
      if (mediaSessionId == null ||
          mediaSessionId == _restartedFromMediaSessionId) {
        return null;
      }
      cancel();
    }
    return offset + receiverPosition;
  }

  /// Duration reported to the UI for a live stream.
  ///
  /// The live stream has no duration on the wire (receiver reports 0), so the
  /// known source duration from the probe is used instead when available.
  Duration mapDuration({
    required Duration reportedDuration,
    required Duration? knownLiveDuration,
  }) {
    if (reportedDuration == Duration.zero && knownLiveDuration != null) {
      return knownLiveDuration;
    }
    return reportedDuration;
  }
}
