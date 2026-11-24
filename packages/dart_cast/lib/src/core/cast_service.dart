import 'dart:async';

import 'cast_device.dart';
import 'cast_exceptions.dart';
import 'cast_session.dart';
import 'discovery_manager.dart';
import 'discovery_provider.dart';
import '../utils/logger.dart';

/// Factory function for creating protocol-specific sessions.
typedef SessionFactory = CastSession Function(CastDevice device);

/// Unified entry point for casting to Chromecast, AirPlay, and DLNA devices.
///
/// Provides device discovery, session management, and reconnection support.
///
/// ```dart
/// final service = CastService();
/// service.startDiscovery().listen((devices) => print(devices));
/// final session = await service.connect(devices.first);
/// await session.loadMedia(media);
/// ```
class CastService {
  final DiscoveryManager _discoveryManager;
  final SessionFactory? _sessionFactory;

  CastSession? _activeSession;
  CastDevice? _lastDevice;

  /// Session that asked for pairing during the last [connect].
  ///
  /// Some protocols (AirPlay) create the session before discovering that the
  /// receiver needs a PIN. Keeping it lets the caller complete pairing on the
  /// same object and adopt it rather than starting over.
  CastSession? _pendingPairingSession;

  /// Upper bound for tearing down the previous session before connecting.
  ///
  /// Teardown stops live FFmpeg runs and the local proxy; if any of those
  /// never finishes, waiting for them would block the new connection and the
  /// UI would stay on "Connecting..." indefinitely.
  final Duration disconnectTimeout;

  /// Creates a [CastService].
  ///
  /// [discoveryProviders] are the protocol-specific discovery providers.
  /// [sessionFactory] creates sessions — if not provided, callers must
  /// supply protocol-specific session implementations.
  CastService({
    List<DeviceDiscoveryProvider>? discoveryProviders,
    SessionFactory? sessionFactory,
    this.disconnectTimeout = const Duration(seconds: 5),
  }) : _discoveryManager = DiscoveryManager(discoveryProviders ?? []),
       _sessionFactory = sessionFactory;

  /// Starts discovering cast devices on the local network.
  ///
  /// [protocols] filters which protocols to scan. Defaults to all.
  /// [timeout] controls how long discovery runs before the stream closes.
  ///
  /// Calling this while a previous discovery is active stops the previous one.
  Stream<List<CastDevice>> startDiscovery({
    Set<CastProtocol>? protocols,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _discoveryManager.startDiscovery(
      protocols: protocols,
      timeout: timeout,
    );
  }

  /// Stops any active device discovery.
  void stopDiscovery() {
    _discoveryManager.stopDiscovery();
  }

  /// Connects to a cast device, creating a protocol-specific session.
  ///
  /// If already connected to another device, the previous session is
  /// automatically disconnected first.
  ///
  /// Sets [lastDevice] to the connected device for later [reconnect].
  Future<CastSession> connect(CastDevice device) async {
    CastLogger.info(
      'CastService: connecting to ${device.name} (${device.protocol})',
    );

    // Auto-disconnect previous session. Stop tracking it first: its teardown
    // emits `disconnected`, and that must not be mistaken for the new session
    // failing. The teardown is bounded so a stuck FFmpeg/proxy cleanup cannot
    // block the new connection forever.
    final previousSession = _activeSession;
    _activeSession = null;
    if (previousSession != null) {
      try {
        await previousSession.disconnect().timeout(disconnectTimeout);
      } on TimeoutException {
        CastLogger.warning(
          'CastService: timed out disconnecting previous session, continuing',
        );
      } catch (e) {
        CastLogger.warning(
          'CastService: error disconnecting previous session: $e',
        );
      }
    }

    final pending = _pendingPairingSession;
    _pendingPairingSession = null;
    if (pending != null && !identical(pending, previousSession)) {
      try {
        await pending.disconnect().timeout(disconnectTimeout);
      } catch (e) {
        CastLogger.warning(
          'CastService: error discarding pairing-pending session: $e',
        );
      }
    }

    final session = _createSession(device);
    try {
      await session.connect();
    } on NeedsPairingException {
      // Keep the half-connected session so a PIN can be entered on it.
      _pendingPairingSession = session;
      rethrow;
    }
    _pendingPairingSession = null;
    _activeSession = session;
    _lastDevice = device;
    CastLogger.info('CastService: connected to ${device.name}');
    return session;
  }

  /// The session that requested pairing during the last [connect], if any.
  CastSession? get pendingPairingSession => _pendingPairingSession;

  /// Finishes connecting a session kept by a pairing failure.
  ///
  /// The caller is expected to have completed pairing on
  /// [pendingPairingSession] already (for example by entering a PIN). This
  /// retries the handshake on the same object and adopts it as the active
  /// session.
  Future<CastSession> completePendingConnect(CastDevice device) async {
    final session = _pendingPairingSession;
    if (session == null) {
      throw StateError('No pairing-pending session to complete');
    }
    try {
      await session.connect();
    } on NeedsPairingException {
      rethrow;
    } catch (_) {
      _pendingPairingSession = null;
      rethrow;
    }
    _pendingPairingSession = null;
    _activeSession = session;
    _lastDevice = device;
    CastLogger.info('CastService: pairing completed for ${device.name}');
    return session;
  }

  /// The currently active cast session, or null if not connected.
  CastSession? get activeSession => _activeSession;

  /// Forgets the active session without disconnecting it.
  ///
  /// Call this after the caller has already disconnected the session so the
  /// next [connect] does not tear it down a second time.
  void clearActiveSession() {
    _activeSession = null;
  }

  /// The last device connected to, for [reconnect] support.
  CastDevice? get lastDevice => _lastDevice;

  /// Sets the last device for [reconnect] support.
  ///
  /// Useful for restoring a saved device from persistent storage.
  void setLastDevice(CastDevice? device) {
    _lastDevice = device;
  }

  /// Reconnects to the [lastDevice].
  ///
  /// Returns null if no [lastDevice] is set.
  Future<CastSession?> reconnect() async {
    if (_lastDevice == null) return null;
    return connect(_lastDevice!);
  }

  /// Releases all resources: stops discovery, disconnects active session,
  /// and disposes all discovery providers.
  Future<void> dispose() async {
    _discoveryManager.dispose();

    final pending = _pendingPairingSession;
    _pendingPairingSession = null;
    if (pending != null) {
      try {
        await pending.disconnect();
      } catch (e) {
        CastLogger.warning(
          'CastService: error during dispose of pairing session: $e',
        );
      }
    }

    if (_activeSession != null) {
      try {
        await _activeSession!.disconnect();
      } catch (e) {
        CastLogger.warning('CastService: error during dispose disconnect: $e');
      }
      _activeSession = null;
    }
  }

  CastSession _createSession(CastDevice device) {
    if (_sessionFactory != null) {
      return _sessionFactory(device);
    }
    throw StateError(
      'No sessionFactory provided. Supply a sessionFactory in the '
      'CastService constructor or use protocol-specific session classes.',
    );
  }
}
