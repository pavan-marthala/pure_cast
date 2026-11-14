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
  Future<void> connect(PureCastDevice device);

  /// Disconnects from the active cast session.
  Future<void> disconnect();

  /// Loads media onto the connected receiver device.
  Future<void> loadMedia(PureCastMedia media, {bool bypassTransform = false});

  /// Loads a local file as a live MKV stream (no disk buffering).
  Future<void> loadLiveMkv({
    required String filePath,
    required int audioIndex,
    required String streamType,
    required bool includeDuration,
  });

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
  ///
  /// [useLive] routes remux plans through the live MKV path (default) instead
  /// of the HLS remux pipeline. Set it to false to compare with the old path.
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    PureCastSubtitleTrack? subtitle,
    List<PureCastSubtitleTrack>? subtitles,
    String? forcePlan,
    bool waitForFinish = false,
    bool includeDuration = false,
    bool useLive = true,
    String streamType = 'BUFFERED',
    String? hlsSegmentFormat,
    String? hlsVideoSegmentFormat,
    String streams = 'both',
    String segments = 'ts',
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

  /// Returns a debug string of the receiver's current media status.
  /// Only meaningful for Chromecast sessions.
  Future<String> getDebugMediaStatus();

  /// Enables raw message logging on the active Chromecast session.
  void enableRawMessageLogging();

  /// Disables raw message logging on the active Chromecast session.
  void disableRawMessageLogging();

  /// Stream of session state changes.
  Stream<PureCastSessionState> get sessionStateStream;

  /// Stream of current playback position updates.
  Stream<Duration> get positionStream;

  /// Stream of media duration updates.
  Stream<Duration> get durationStream;

  /// Currently connected device (null if disconnected).
  PureCastDevice? get currentDevice;

  /// Currently active session state.
  PureCastSessionState get currentState;

  /// Release resources.
  Future<void> dispose();
}
