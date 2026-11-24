import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

/// Service contract abstracting the underlying casting engine.
abstract class ICastService {
  /// Stream of discovered devices.
  Stream<List<PureCastDevice>> discoverDevices({
    Set<PureCastProtocol>? protocols,
  });

  /// Stops device discovery.
  Future<void> stopDiscovery();

  /// Connects to a target cast device.
  ///
  /// Throws [PairingRequiredException] when the receiver needs a PIN before
  /// the session can be established.
  Future<void> connect(PureCastDevice device);

  /// Completes a pairing-required connection with the PIN shown on the
  /// receiver.
  ///
  /// Must be called after [connect] threw [PairingRequiredException] for the
  /// same device. Credentials are persisted for future reconnects.
  Future<void> connectWithPin(PureCastDevice device, String pin);

  /// Disconnects from the active cast session.
  Future<void> disconnect();

  /// Loads media onto the connected receiver device.
  Future<void> loadMedia(PureCastMedia media, {bool bypassTransform = false});

  /// Restarts the live MKV stream with another audio track, resuming at
  /// [position] in the source file.
  ///
  /// [duration] and [audioTracks] describe the source file. Supply them when
  /// switching away from a direct (non-live) load, which has no live metadata
  /// to preserve.
  Future<void> switchLiveAudio({
    required String filePath,
    required int audioIndex,
    required Duration position,
    required String streamType,
    Duration? duration,
    List<PureCastAudioTrack>? audioTracks,
  });

  /// Attaches, replaces or clears the subtitle of the current live MKV stream.
  ///
  /// A non-null [subtitle] restarts the stream at [position] with a
  /// time-shifted copy attached. Passing null disables subtitles in place,
  /// without a restart. Throws a [PureCastException] when there is no active
  /// Chromecast session or the switch fails.
  Future<void> switchLiveSubtitle({
    required PureCastSubtitleTrack? subtitle,
    required Duration position,
  });

  /// Probes a local file and returns its audio tracks.
  ///
  /// [PureCastAudioTrack.index] is the 0-based index among audio streams.
  Future<List<PureCastAudioTrack>> probeAudioTracks(String filePath);

  /// Source offset of the current live stream (zero when not restarted).
  Duration get liveStartOffset;

  /// Whether the active session is playing through the live MKV path.
  bool get isLiveStream;

  /// Audio tracks of the current live stream (empty when not live).
  ///
  /// [PureCastAudioTrack.index] is the 0-based index among audio streams,
  /// i.e. the `N` in `0:a:N`.
  List<PureCastAudioTrack> get audioTracks;

  /// Audio index (`0:a:N`) currently used by the live stream.
  int get activeAudioIndex;

  /// Current playback position of the active session.
  Duration get position;

  /// Loads a local file, probing/preparing it for Chromecast when needed.
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    PureCastSubtitleTrack? subtitle,
    List<PureCastSubtitleTrack>? subtitles,
    String streamType = 'BUFFERED',
  });

  /// Starts or resumes media playback.
  Future<void> play();

  /// Pauses active media playback.
  Future<void> pause();

  /// Stops playback.
  Future<void> stop();

  /// Seeks to the specified position in the media.
  Future<void> seek(Duration position);

  /// Sets volume level (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Sets the active subtitle track (null to disable subtitles).
  Future<void> setSubtitle(PureCastSubtitleTrack? subtitle);

  /// Stream of session state changes.
  Stream<PureCastSessionState> get sessionStateStream;

  /// Stream of current playback position updates.
  Stream<Duration> get positionStream;

  /// Stream of media duration updates.
  Stream<Duration> get durationStream;

  /// Currently active session state.
  PureCastSessionState get currentState;

  /// Release resources.
  Future<void> dispose();
}
