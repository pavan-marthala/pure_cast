import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

/// Service contract abstracting the underlying casting engine.
abstract class ICastService {
  /// Stream of discovered devices.
  Stream<List<PureCastDevice>> discoverDevices({Set<PureCastProtocol>? protocols});

  /// Stops device discovery.
  Future<void> stopDiscovery();

  /// Connects to a target cast device.
  Future<void> connect(PureCastDevice device);

  /// Disconnects from the active cast session.
  Future<void> disconnect();

  /// Loads media onto the connected receiver device.
  Future<void> loadMedia(PureCastMedia media);

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
