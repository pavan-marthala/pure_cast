import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';

import '../../core/cast_decision.dart';
import '../../core/cast_exceptions.dart';
import '../../core/cast_media.dart';
import '../../core/cast_session.dart';
import '../../core/media_probe.dart';
import '../../core/media_prober.dart';
import '../../core/media_proxy.dart';
import '../../core/media_transformer.dart';
import '../../utils/logger.dart';
import 'airplay_client.dart';
import 'airplay_features.dart';
import 'airplay_media_controller.dart';
import 'airplay_media_plan.dart';
import 'airplay_media_preparer.dart';
import 'auth/airplay_auth.dart';
import 'auth/airplay_transient_auth.dart';
import 'auth/hap_credentials.dart';
import 'auth/hap_session.dart';
import 'plist_codec.dart';

/// AirPlay 1/2 cast session with playback control and position polling.
///
/// Extends [CastSession] to implement AirPlay-specific behavior:
/// - Connects to a device via [AirPlayClient]
/// - Proxies media through [MediaProxy] so the AirPlay device can reach it
/// - Probes and prepares local files (direct MP4, remux, transcode, VOD HLS)
/// - Restarts the stream at the current position for audio/subtitle changes
/// - Polls `/playback-info` to update position/duration/state
/// - Supports HAP authentication for devices that require it (Apple TV)
class AirPlaySession extends CastSession {
  AirPlayClient? _client;
  HapSession? _hapSession;
  AirPlayMediaController? _mediaController;
  final MediaProxy _proxy = MediaProxy();
  final MediaTransformer _mediaTransformer;
  final MediaProber _prober;
  final AirPlayMediaPreparer _preparer;
  Timer? _pollTimer;
  bool _isPolling = false;
  int _pollFailures = 0;
  bool _isLoadingMedia = false;
  CastMedia? _currentMedia;

  /// Monotonic token that changes on every load. A poll captures it before
  /// awaiting `/playback-info` and discards the answer if the load was
  /// replaced in the meantime.
  int _loadGeneration = 0;

  /// Duration from the probe or caller, used when a receiver omits `duration`.
  Duration? _expectedDuration;

  /// Local-file state kept across restarts.
  String? _localPath;
  String? _localInput;
  MediaProbe? _localProbe;
  CastDeviceCaps _localCaps = const CastDeviceCaps();
  List<AudioStream> _localAudioTracks = const [];
  int _localAudioIndex = 0;
  Duration? _localDuration;
  CastSubtitle? _localSubtitle;
  AirPlayPreparedMedia? _prepared;

  /// Stored HAP credentials for pair-verify. Set these before calling
  /// [connect] if the device requires authentication.
  HapCredentials? credentials;

  /// Creates an [AirPlaySession] for the given AirPlay [device].
  ///
  /// [mediaTransformer] customizes how remote media is registered.
  /// [prober] and [preparer] are test seams for local-file loading.
  AirPlaySession(
    super.device, {
    this.credentials,
    MediaTransformer? mediaTransformer,
    MediaProber prober = const FfprobeMediaProber(),
    AirPlayMediaPreparer preparer = const FfmpegAirPlayPreparer(),
  }) : _mediaTransformer = mediaTransformer ?? const DefaultMediaTransformer(),
       _prober = prober,
       _preparer = preparer;

  /// The underlying AirPlay HTTP client (available after [connect]).
  AirPlayClient? get client => _client;

  /// Audio tracks discovered for the loaded local file.
  @override
  List<AudioStream> get audioTracks => _localAudioTracks;

  /// 0-based index among audio streams currently used by the local load.
  @override
  int get activeAudioIndex => _localAudioIndex;

  /// Whether local playback is served by a prepared stream.
  ///
  /// AirPlay's prepared HLS is VOD, not a live pipe, so [isLive] stays false.
  /// This getter exists so callers can tell "prepared local media" from
  /// "direct local media" without protocol-specific checks.
  bool get hasPreparedLocalMedia => _prepared != null;

  /// Connects to the AirPlay device.
  ///
  /// Probes the device with `GET /info`, falling back to `GET /server-info`.
  /// The transport is then chosen from the device's **advertised feature
  /// bits**, not from the HTTP status:
  ///
  /// - AirPlay 2 receiver (bit 38 or 48) → raw socket, pairing, encrypted HAP
  ///   session with an [AirPlayMediaController]. Transient pairing is used
  ///   when the device advertises bit 43 or 48, otherwise stored
  ///   [credentials] drive a pair-verify.
  /// - anything else that answered 403 → the same path, but pair-verify only.
  /// - otherwise → the plain HTTP AirPlay 1 client.
  ///
  /// Throws [NeedsPairingException] when pairing is required and no usable
  /// route to it exists.
  @override
  Future<void> connect() async {
    CastLogger.info(
      'AirPlay: connecting to ${device.name} at ${device.address.address}:${device.port}',
    );
    stateMachine.transitionTo(SessionState.connecting);

    _client = AirPlayClient(host: device.address.address, port: device.port);

    try {
      final probe = await _client!.probeDeviceInfo();
      final features = _parseFeatures();
      CastLogger.info(
        'AirPlay: ${device.name} features=$features '
        '(v2=${features.isV2Protocol}, videoV1=${features.supportsVideoV1}, '
        'videoV2=${features.supportsVideoV2}, '
        'transient=${features.supportsTransientPairing})',
      );
      if (probe.properties.isEmpty && !probe.authRequired) {
        CastLogger.warning(
          'AirPlay: ${device.name} answered neither /info nor /server-info '
          'with 200 — continuing with mDNS-advertised capabilities only',
        );
      }

      if (features.isV2Protocol || probe.authRequired) {
        await _establishEncryptedSession(features);
        return;
      }

      CastLogger.info(
        'AirPlay: connected to ${device.name} (AirPlay 1, plain)',
      );
      stateMachine.transitionTo(SessionState.connected);
    } on NeedsPairingException {
      rethrow;
    } catch (e) {
      CastLogger.error('AirPlay: connection failed to ${device.name}: $e');
      _client?.close();
      _client = null;
      stateMachine.transitionTo(SessionState.disconnected);
      rethrow;
    }
  }

  /// Opens the encrypted HAP channel used by AirPlay 2 and paired devices.
  ///
  /// Opens a SINGLE raw TCP socket and pairs over it. On success, that SAME
  /// socket is promoted to an encrypted HAP session. This is critical because
  /// AirPlay devices bind authentication state to the TCP connection — a new
  /// socket would be unauthenticated.
  Future<void> _establishEncryptedSession(AirPlayFeatures features) async {
    final useTransient =
        credentials == null && features.supportsTransientPairing;

    if (!useTransient && credentials == null) {
      _client?.close();
      _client = null;
      stateMachine.transitionTo(SessionState.disconnected);
      throw NeedsPairingException(
        'AirPlay device "${device.name}" requires pairing. '
        'Call pairSetup(pin) first.',
      );
    }

    Socket? rawSocket;
    StreamController<Uint8List>? socketBroadcast;
    try {
      CastLogger.info('AirPlay: opening raw socket for pairing + HAP session');
      rawSocket = await Socket.connect(device.address.address, device.port);

      // Wrap the socket's single-subscription stream in a broadcast controller.
      // This lets both the pairing step and HapSession subscribe independently.
      socketBroadcast = StreamController<Uint8List>.broadcast();
      rawSocket.listen(
        (data) => socketBroadcast!.add(Uint8List.fromList(data)),
        onError: (e) => socketBroadcast!.addError(e),
        onDone: () => socketBroadcast!.close(),
      );

      final Uint8List sharedSecret;
      if (useTransient) {
        CastLogger.info(
          'AirPlay: using transient pairing (no PIN, no stored credentials)',
        );
        final transient = AirPlayTransientPairing.withSocket(
          rawSocket,
          host: device.address.address,
          port: device.port,
          dataStream: socketBroadcast.stream,
        );
        sharedSecret = await transient.execute();
        // Stop the pairing reader before the encrypted reader takes over,
        // otherwise it keeps a copy of every encrypted byte for the life of
        // the session.
        await transient.releaseSocket();
      } else {
        final pairVerify = AirPlayPairVerify.withSocket(
          rawSocket,
          host: device.address.address,
          port: device.port,
          dataStream: socketBroadcast.stream,
        );
        CastLogger.info(
          'AirPlay: attempting pair-verify with stored credentials',
        );
        sharedSecret = await pairVerify.execute(credentials!);
        await pairVerify.releaseSocket();
      }

      CastLogger.info('AirPlay: pairing successful, creating HAP session');

      // Derive encryption keys and create HAP session on the SAME socket
      // using the SAME broadcast stream for reading
      final keys = await deriveHapSessionKeys(sharedSecret);
      _hapSession = HapSession(
        socket: rawSocket,
        outputKey: keys.outputKey,
        inputKey: keys.inputKey,
        host: device.address.address,
        port: device.port,
        sessionId: _client!.sessionId,
        sharedSecret: sharedSecret,
        dataStream: socketBroadcast.stream,
      );

      _mediaController = AirPlayMediaController(
        session: _hapSession!,
        features: features,
      );

      CastLogger.info('AirPlay: HAP encrypted session established');
      stateMachine.transitionTo(SessionState.connected);
    } on AirPlayAuthException catch (e) {
      // Auth failure — credentials may be stale, need re-pairing
      CastLogger.error('AirPlay: pairing failed: $e');
      rawSocket?.destroy();
      _client?.close();
      _client = null;
      stateMachine.transitionTo(SessionState.disconnected);
      throw NeedsPairingException(
        'AirPlay pairing failed for "${device.name}": ${e.message}',
      );
    } catch (e) {
      // Network error — don't discard credentials
      CastLogger.error('AirPlay: pairing network error: $e');
      rawSocket?.destroy();
      _client?.close();
      _client = null;
      stateMachine.transitionTo(SessionState.disconnected);
      rethrow;
    }
  }

  /// Performs HAP pair-setup with the device using the given [pin].
  ///
  /// This triggers the device to display a 4-digit PIN, which the user
  /// must enter. On success, stores [credentials] for future sessions.
  ///
  /// [clientId] is an optional identifier for this client. If not provided,
  /// a random UUID is generated.
  Future<HapCredentials> pairSetup(
    String pin, {
    String? clientId,
    bool triggerPinDisplay = true,
  }) async {
    final id = clientId ?? _generateUuid();

    final pairSetup = AirPlayPairSetup(
      host: device.address.address,
      port: device.port,
    );

    try {
      // Trigger PIN display on TV (skip if already triggered externally)
      if (triggerPinDisplay) {
        CastLogger.info('AirPlay: triggering PIN display on TV');
        pairSetup.startPinDisplay(); // Fire-and-forget — TV may not respond
      }

      // Run pair-setup SRP flow with the user-entered PIN
      CastLogger.info('AirPlay: starting SRP pair-setup with PIN');
      credentials = await pairSetup.pairSetup(pin: pin, clientId: id);

      CastLogger.info('AirPlay: pair-setup complete, credentials stored');
      return credentials!;
    } finally {
      pairSetup.close();
    }
  }

  /// Loads media onto the AirPlay device.
  ///
  /// Starts the media proxy, registers the media URL, and sends a `POST /play`
  /// to the device. Begins position polling after playback starts.
  @override
  Future<void> loadMedia(
    CastMedia media, {
    bool bypassTransform = false,
  }) async {
    if (_isLoadingMedia) {
      CastLogger.warning(
        'AirPlay: loadMedia called while already loading — ignoring',
      );
      return;
    }
    _isLoadingMedia = true;
    try {
      await _cleanupLocalLoad();
      await _loadMediaInternal(media);
    } finally {
      _isLoadingMedia = false;
    }
  }

  /// Loads a local file, choosing direct play, MP4 remux, transcode, or HLS.
  ///
  /// The file is probed once; [planAirPlayMedia] picks the cheapest strategy
  /// that can work. A subtitle request selects seekable VOD HLS because an
  /// external subtitle needs a rendition.
  @override
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    CastDeviceCaps caps = const CastDeviceCaps(),
    CastSubtitle? subtitle,
    String streamType = 'BUFFERED',
  }) async {
    await _cleanupLocalLoad();
    final input = await _resolveInput(path);

    MediaProbe probe;
    try {
      probe = await _prober.probe(input);
    } on ProbeFailedException {
      rethrow;
    } catch (e) {
      throw ProbeFailedException('Probe failed: $e', e);
    }

    final audioIndex = _resolveAudioIndex(probe.audio, audioStreamIndex);
    var plan = planAirPlayMedia(
      probe,
      audioIndex: audioIndex,
      subtitlesRequested: subtitle != null,
      caps: caps,
    );
    // `content://` cannot be served by the proxy directly, so even direct-play
    // media is rewrapped into a readable temporary MP4.
    if (plan is AirPlayDirectPlan && path.startsWith('content://')) {
      plan = AirPlayContainerRemuxPlan(
        'content:// source needs a readable MP4 copy',
        audioIndex: audioIndex,
      );
    }

    if (plan is AirPlayHlsPlan && !_parseFeatures().supportsHLS) {
      throw UnsupportedFeatureException(
        'AirPlay receiver "${device.name}" does not advertise HLS support '
        '(bit 4), so subtitles cannot be attached',
      );
    }

    _localPath = path;
    _localInput = input;
    _localProbe = probe;
    _localCaps = caps;
    _localAudioTracks = List.unmodifiable(probe.audio);
    _localAudioIndex = audioIndex;
    _localDuration = probe.duration;
    _localSubtitle = subtitle;

    switch (plan) {
      case AirPlayDirectPlan():
        CastLogger.info('AirPlay: local direct play (${plan.reason})');
        await _loadMediaInternal(
          CastMedia.file(
            filePath: path,
            type: CastMediaType.mp4,
            duration: probe.duration,
            subtitles: subtitle != null ? [subtitle] : const [],
            defaultSubtitle: subtitle,
          ),
        );
      case AirPlayContainerRemuxPlan():
      case AirPlayAudioRemuxPlan():
      case AirPlayTranscodePlan():
        CastLogger.info('AirPlay: local ${plan.runtimeType} (${plan.reason})');
        await _loadPreparedMp4(
          inputPath: input,
          audioIndex: audioIndex,
          probe: probe,
          caps: caps,
          subtitle: subtitle,
          transcodeVideo: plan is AirPlayTranscodePlan,
          transcodeAudio: plan is AirPlayAudioRemuxPlan,
        );
      case AirPlayHlsPlan():
        CastLogger.info('AirPlay: local HLS (${plan.reason})');
        await _loadPreparedHls(
          inputPath: input,
          audioIndex: audioIndex,
          probe: probe,
          caps: caps,
          subtitle: subtitle,
          transcodeVideo: plan.transcodeVideo,
        );
      case AirPlayUnsupportedPlan():
        throw UnsupportedMediaException('Unsupported: ${plan.reason}');
    }
  }

  /// Restarts a local file with a different audio track at [position].
  ///
  /// AirPlay has no in-place track selection: the stream is rebuilt as VOD HLS
  /// with the selected audio rendition and reloaded at [position]. The new
  /// stream is prepared before the old one is replaced, so a preparation
  /// failure leaves the current playback untouched.
  @override
  Future<void> switchLiveAudio({
    required String filePath,
    required int audioIndex,
    required Duration position,
    required String streamType,
    Duration? duration,
    List<AudioStream>? audioTracks,
  }) async {
    final path = _localPath ?? filePath;
    final probe = _localProbe;
    if (probe == null) {
      throw StateError(
        'switchLiveAudio requires a local file to have been loaded first',
      );
    }
    if (!_parseFeatures().supportsHLS) {
      throw UnsupportedFeatureException(
        'AirPlay receiver does not advertise HLS support, so audio track '
        'switching cannot be prepared',
      );
    }
    final tracks = audioTracks ?? _localAudioTracks;
    if (audioIndex < 0 || audioIndex >= tracks.length) {
      throw ArgumentError.value(
        audioIndex,
        'audioIndex',
        'is not a valid audio track index',
      );
    }

    await _restartLocal(
      path: path,
      probe: probe,
      audioIndex: audioIndex,
      position: position,
      duration: duration ?? _localDuration,
      audioTracks: tracks,
      subtitle: _localSubtitle,
    );
  }

  /// Attaches, replaces or clears the local stream's subtitle at [position].
  ///
  /// A subtitle needs an HLS rendition. Receivers that clear the HLS bit get a
  /// typed [UnsupportedFeatureException] and playback is not interrupted.
  @override
  Future<void> switchLiveSubtitle({
    required CastSubtitle? subtitle,
    required Duration position,
  }) async {
    final path = _localPath;
    final probe = _localProbe;
    if (path == null || probe == null) {
      throw StateError(
        'switchLiveSubtitle requires a local file to have been loaded first',
      );
    }
    if (!_parseFeatures().supportsHLS) {
      throw UnsupportedFeatureException(
        'AirPlay receiver does not advertise HLS support, so subtitles '
        'cannot be attached',
      );
    }
    if (subtitle == null && _localSubtitle == null) return;

    await _restartLocal(
      path: path,
      probe: probe,
      audioIndex: _localAudioIndex,
      position: position,
      duration: _localDuration,
      audioTracks: _localAudioTracks,
      subtitle: subtitle,
    );
  }

  Future<void> _loadPreparedMp4({
    required String inputPath,
    required int audioIndex,
    required MediaProbe probe,
    required CastDeviceCaps caps,
    required CastSubtitle? subtitle,
    required bool transcodeVideo,
    required bool transcodeAudio,
  }) async {
    final prepared = await _preparer.prepareMp4(
      inputPath: inputPath,
      audioIndex: audioIndex,
      audioTracks: probe.audio,
      transcodeVideo: transcodeVideo,
      transcodeAudio: transcodeAudio,
      caps: caps,
      duration: probe.duration,
      subtitle: subtitle,
    );
    try {
      await _activatePrepared(prepared, start: Duration.zero);
    } catch (_) {
      _prepared = null;
      await prepared.dispose();
      rethrow;
    }
  }

  Future<void> _loadPreparedHls({
    required String inputPath,
    required int audioIndex,
    required MediaProbe probe,
    required CastDeviceCaps caps,
    required CastSubtitle? subtitle,
    required bool transcodeVideo,
  }) async {
    final prepared = await _preparer.prepareHls(
      inputPath: inputPath,
      audioIndex: audioIndex,
      audioTracks: probe.audio,
      transcodeVideo: transcodeVideo,
      caps: caps,
      duration: probe.duration,
      subtitle: subtitle,
    );
    try {
      await _activatePrepared(prepared, start: Duration.zero);
    } catch (_) {
      _prepared = null;
      await prepared.dispose();
      rethrow;
    }
  }

  /// Registers [prepared] with the proxy and loads it at [start].
  Future<void> _activatePrepared(
    AirPlayPreparedMedia prepared, {
    required Duration start,
  }) async {
    await _proxy.start(targetDeviceIp: device.address.address);
    final url =
        prepared.type == CastMediaType.hls
            ? _proxy.registerHlsDirectory(
              prepared.sessionId,
              prepared.directory.path,
            )
            : _proxy.registerFile(prepared.path);

    _prepared = prepared;
    _localAudioIndex = prepared.audioIndex;
    _localSubtitle = prepared.subtitle;
    if (prepared.duration != null) _localDuration = prepared.duration;

    await _loadMediaInternal(
      CastMedia(
        url: url,
        type: prepared.type,
        duration: prepared.duration,
        startPosition: start == Duration.zero ? null : start,
        title: 'AirPlay prepared',
      ),
      proxyUrlOverride: url,
    );
  }

  /// Rebuilds the current local stream at [position] with new tracks.
  Future<void> _restartLocal({
    required String path,
    required MediaProbe probe,
    required int audioIndex,
    required Duration position,
    required Duration? duration,
    required List<AudioStream> audioTracks,
    required CastSubtitle? subtitle,
  }) async {
    if (_isLoadingMedia) {
      throw StateError('Another cast load is already in progress');
    }
    _isLoadingMedia = true;
    try {
      final inputPath = _localInput ?? _localPathOf(path);
      final plan = planAirPlayMedia(
        probe,
        audioIndex: audioIndex,
        subtitlesRequested: subtitle != null,
        forceHls: true,
        caps: _localCaps,
      );
      if (plan is! AirPlayHlsPlan) {
        throw UnsupportedFeatureException(
          plan is AirPlayUnsupportedPlan
              ? 'Cannot rebuild the stream: ${plan.reason}'
              : 'Cannot rebuild the stream for this media',
        );
      }

      // Prepare first: a failure leaves the old stream running.
      final prepared = await _preparer.prepareHls(
        inputPath: inputPath,
        audioIndex: audioIndex,
        audioTracks: audioTracks,
        transcodeVideo: plan.transcodeVideo,
        caps: _localCaps,
        duration: duration,
        subtitle: subtitle,
      );

      _stopPolling();
      _loadGeneration++;
      _proxy.cleanupPreviousMedia();
      final previous = _prepared;
      _prepared = null;
      if (previous != null) {
        _proxy.unregisterHlsDirectory(previous.sessionId);
        await previous.dispose();
      }

      try {
        await _activatePrepared(prepared, start: position);
        _localAudioIndex = audioIndex;
        _localSubtitle = subtitle;
        _localDuration = duration ?? _localDuration;
        _localAudioTracks = List.unmodifiable(audioTracks);
      } catch (_) {
        _prepared = null;
        await prepared.dispose();
        rethrow;
      }
      CastLogger.info(
        'AirPlay: local restart complete (audio=$audioIndex, '
        'offset=${position.inSeconds}s)',
      );
    } finally {
      _isLoadingMedia = false;
    }
  }

  Future<void> _loadMediaInternal(
    CastMedia media, {
    String? proxyUrlOverride,
  }) async {
    _ensureClient();
    // A replacement load must never be updated by the previous load's poll.
    _stopPolling();
    _loadGeneration++;
    stateMachine.transitionTo(SessionState.loading);

    try {
      await _proxy.start(targetDeviceIp: device.address.address);

      _currentMedia = media;
      _expectedDuration = media.duration ?? _localDuration;

      final proxyUrl =
          proxyUrlOverride ??
          (await _mediaTransformer.transform(media, _proxy)).proxyUrl;

      String playUrl;
      if (media.subtitles.isNotEmpty && media.type == CastMediaType.hls) {
        playUrl = _buildSubtitleWrapper(
          proxyUrl,
          media.subtitles,
          media.httpHeaders,
        );
      } else {
        playUrl = proxyUrl;
      }

      final startSeconds =
          (media.startPosition ?? Duration.zero).inMilliseconds / 1000.0;
      final duration = media.duration ?? _localDuration;

      CastLogger.info(
        'AirPlay: sending /play with URL: '
        '${playUrl.substring(0, playUrl.length.clamp(0, 80))}... '
        '(start=${startSeconds}s)',
      );
      await _playOnDevice(playUrl, startSeconds, duration);

      _startPolling();
    } catch (e) {
      CastLogger.error('AirPlay: loadMedia failed: $e');
      if (stateMachine.canTransitionTo(SessionState.idle)) {
        stateMachine.transitionTo(SessionState.idle);
      }
      rethrow;
    }
  }

  /// Sends `/play` with the best start-position encoding for the transport.
  Future<void> _playOnDevice(
    String url,
    double startSeconds,
    Duration? duration,
  ) async {
    final controller = _mediaController;
    if (controller != null) {
      await controller.play(
        url,
        startPositionSeconds: startSeconds,
        duration: duration,
      );
      // AirPlay 1 fractions are only reliable with a known duration; when
      // none was available the fraction path started at zero, so scrub.
      if (startSeconds > 0 && (duration == null || duration <= Duration.zero)) {
        await controller.seek(startSeconds);
      }
      return;
    }

    final totalMs = duration?.inMilliseconds ?? 0;
    var fraction = 0.0;
    if (startSeconds > 0 && totalMs > 0) {
      fraction = (startSeconds * 1000.0 / totalMs).clamp(0.0, 1.0);
    }
    await _client!.play(url, startPosition: fraction);
    if (startSeconds > 0 && fraction == 0.0) {
      await _client!.scrub(startSeconds);
    }
  }

  /// Builds a wrapper m3u8 that adds subtitle tracks to the original HLS stream.
  String _buildSubtitleWrapper(
    String originalProxyUrl,
    List<CastSubtitle> subtitles,
    Map<String, String> headers,
  ) {
    final subtitleEntries = <({String name, String language, String url})>[];

    for (final sub in subtitles) {
      // Register each subtitle as an HLS subtitle playlist
      final subPlaylistUrl = _proxy.registerSubtitlePlaylist(
        sub.url,
        headers: headers,
      );
      subtitleEntries.add((
        name: sub.label,
        language: sub.language,
        url: subPlaylistUrl,
      ));
    }

    return _proxy.registerSubtitleWrapper(
      originalM3u8ProxyUrl: originalProxyUrl,
      subtitleEntries: subtitleEntries,
    );
  }

  /// Resumes playback (sends rate=1 to device).
  @override
  Future<void> play() async {
    _ensureClient();
    CastLogger.info('AirPlay: Play (resume)');
    if (_mediaController != null) {
      await _mediaController!.resume();
    } else {
      await _client!.rate(1);
    }
    if (stateMachine.canTransitionTo(SessionState.playing)) {
      stateMachine.transitionTo(SessionState.playing);
    }
  }

  /// Pauses playback (sends rate=0 to device).
  @override
  Future<void> pause() async {
    _ensureClient();
    CastLogger.info('AirPlay: Pause');
    if (_mediaController != null) {
      await _mediaController!.pause();
    } else {
      await _client!.rate(0);
    }
    if (stateMachine.canTransitionTo(SessionState.paused)) {
      stateMachine.transitionTo(SessionState.paused);
    }
  }

  /// Stops playback, cancels polling, and transitions to idle.
  @override
  Future<void> stop() async {
    _ensureClient();
    CastLogger.info('AirPlay: Stop');
    _stopPolling();
    if (_mediaController != null) {
      await _mediaController!.stop();
    } else {
      await _client!.stop();
    }
    await _cleanupLocalLoad();
    if (stateMachine.canTransitionTo(SessionState.idle)) {
      stateMachine.transitionTo(SessionState.idle);
    }
  }

  /// Seeks to the given [position] and reports it immediately.
  @override
  Future<void> seek(Duration position) async {
    _ensureClient();
    final seconds = position.inMilliseconds / 1000.0;
    CastLogger.info('AirPlay: Seek to ${seconds.toStringAsFixed(1)}s');
    if (_mediaController != null) {
      await _mediaController!.seek(seconds);
    } else {
      await _client!.scrub(seconds);
    }
    updatePosition(position);
  }

  /// Sets volume on receivers that advertise video volume control (bit 3).
  ///
  /// Throws [UnsupportedFeatureException] otherwise instead of pretending the
  /// change was applied.
  @override
  Future<void> setVolume(double volume) async {
    if (!_parseFeatures().supportsVideoVolumeControl) {
      throw UnsupportedFeatureException(
        'AirPlay receiver "${device.name}" does not advertise video volume '
        'control (feature bit 3)',
      );
    }
    _ensureClient();
    final clamped = volume.clamp(0.0, 1.0);
    if (_mediaController != null) {
      await _mediaController!.setVolume(clamped);
    } else {
      await _client!.setVolume(clamped);
    }
    updateVolume(clamped);
  }

  /// Sets the active subtitle track.
  ///
  /// Local playback restarts the prepared stream at the current position.
  /// Remote HLS keeps the existing rewrite-the-playlist behavior.
  @override
  Future<void> setSubtitle(CastSubtitle? subtitle) async {
    if (_localPath != null) {
      await switchLiveSubtitle(subtitle: subtitle, position: position);
      return;
    }
    if (_currentMedia == null || _client == null) return;

    final media = _currentMedia!;

    // Build new media with only the selected subtitle (or none)
    final newMedia = CastMedia(
      url: media.url,
      type: media.type,
      httpHeaders: media.httpHeaders,
      title: media.title,
      imageUrl: media.imageUrl,
      startPosition: media.startPosition,
      subtitles: subtitle != null ? [subtitle] : const [],
    );

    // Clean up old proxy routes and re-register
    _proxy.cleanupPreviousMedia();

    final newTransformed = await _mediaTransformer.transform(newMedia, _proxy);
    final proxyUrl = newTransformed.proxyUrl;

    String playUrl;
    if (newMedia.subtitles.isNotEmpty && newMedia.type == CastMediaType.hls) {
      playUrl = _buildSubtitleWrapper(
        proxyUrl,
        newMedia.subtitles,
        newMedia.httpHeaders,
      );
    } else {
      playUrl = proxyUrl;
    }

    if (_mediaController != null) {
      await _mediaController!.play(playUrl);
    } else {
      await _client!.play(playUrl, startPosition: 0.0);
    }
  }

  /// Disconnects from the device, stopping playback and cleaning up.
  @override
  Future<void> disconnect() async {
    CastLogger.info('AirPlay: disconnecting from ${device.name}');
    _stopPolling();

    try {
      if (_mediaController != null) {
        await _mediaController!.stop();
      } else if (_client != null) {
        await _client!.stop();
      }
    } catch (e) {
      CastLogger.warning('AirPlay: error sending Stop during disconnect: $e');
    }

    await _cleanupLocalLoad();
    await _mediaController?.dispose();
    _mediaController = null;
    await _hapSession?.close();
    _hapSession = null;
    _client?.close();
    _client = null;
    await _proxy.stop();
    stateMachine.transitionTo(SessionState.disconnected);
    CastLogger.info('AirPlay: disconnected from ${device.name}');
  }

  /// Disposes all resources.
  @override
  void dispose() {
    _stopPolling();
    _prepared?.dispose();
    _prepared = null;
    _mediaController?.dispose();
    _mediaController = null;
    _hapSession?.close();
    _hapSession = null;
    _client?.close();
    _client = null;
    // Don't await — fire and forget during dispose
    _proxy.stop();
    super.dispose();
  }

  /// Releases the previous prepared output, HLS directory, routes and local
  /// metadata before a new local load.
  Future<void> _cleanupLocalLoad() async {
    _proxy.cleanupPreviousMedia();
    final previous = _prepared;
    _prepared = null;
    if (previous != null) {
      _proxy.unregisterHlsDirectory(previous.sessionId);
      await previous.dispose();
    }
    _localPath = null;
    _localInput = null;
    _localProbe = null;
    _localAudioTracks = const [];
    _localAudioIndex = 0;
    _localDuration = null;
    _localSubtitle = null;
  }

  /// Starts periodic polling of playback info.
  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _pollPlaybackInfo(),
    );
  }

  /// Stops the polling timer.
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Polls the device for playback info and updates session state.
  ///
  /// The load generation is captured before awaiting the response. If a new
  /// load replaced this one while the request was in flight, the stale values
  /// are discarded rather than jumping the position backwards.
  Future<void> _pollPlaybackInfo() async {
    if (_client == null || _isPolling) return;
    final generation = _loadGeneration;
    _isPolling = true;

    try {
      final PlaybackInfo info;
      if (_mediaController != null) {
        info = await _mediaController!.getPlaybackInfo();
      } else {
        info = await _client!.getPlaybackInfo();
      }
      if (generation != _loadGeneration) {
        CastLogger.debug(
          'AirPlay: discarding playback-info from replaced load',
        );
        return;
      }
      _pollFailures = 0;
      _updateFromPlaybackInfo(info);
    } catch (e) {
      _pollFailures++;
      if (_pollFailures == 1 || _pollFailures % 10 == 0) {
        CastLogger.warning(
          'AirPlay: playback-info polling failed '
          '($_pollFailures consecutive): $e',
        );
      } else {
        CastLogger.debug('AirPlay: playback-info polling failed: $e');
      }
    } finally {
      _isPolling = false;
    }
  }

  /// Updates session state based on parsed playback info.
  void _updateFromPlaybackInfo(PlaybackInfo info) {
    // The receiver telling us it failed is authoritative — stop polling and
    // surface it rather than sitting in `loading` forever.
    final error = info.error;
    if (error != null) {
      CastLogger.error(
        'AirPlay: receiver reported playback error ${error.code ?? 'unknown'} '
        '(${error.domain ?? 'unknown domain'}) — stopping playback',
      );
      _stopPolling();
      if (stateMachine.canTransitionTo(SessionState.idle)) {
        stateMachine.transitionTo(SessionState.idle);
      }
      return;
    }

    updatePosition(Duration(milliseconds: (info.position * 1000).round()));

    // A report without `duration` must not erase the probe duration. Seed the
    // known value instead so the UI still gets a seekable range.
    if (info.hasDuration && info.duration > 0) {
      updateDuration(Duration(milliseconds: (info.duration * 1000).round()));
    } else if (duration == Duration.zero && _expectedDuration != null) {
      updateDuration(_expectedDuration!);
    }

    // Update playback state based on rate and readiness
    if (!info.readyToPlay) {
      if (stateMachine.canTransitionTo(SessionState.buffering)) {
        stateMachine.transitionTo(SessionState.buffering);
      }
    } else if (info.rate == 0.0) {
      if (stateMachine.canTransitionTo(SessionState.paused)) {
        stateMachine.transitionTo(SessionState.paused);
      }
    } else if (info.rate > 0.0) {
      if (stateMachine.canTransitionTo(SessionState.playing)) {
        stateMachine.transitionTo(SessionState.playing);
      }
    }
  }

  void _ensureClient() {
    if (_client == null) {
      throw StateError(
        'AirPlaySession is not connected. Call connect() first.',
      );
    }
  }

  /// Parses AirPlay feature flags from device metadata.
  AirPlayFeatures _parseFeatures() {
    final featuresStr =
        device.metadata['features'] ?? device.metadata['ft'] ?? '';
    return AirPlayFeatures.parse(featuresStr);
  }

  static int _resolveAudioIndex(List<AudioStream> audio, int requested) {
    if (audio.isEmpty) return 0;
    if (requested >= 0 && requested < audio.length) return requested;
    for (var i = 0; i < audio.length; i++) {
      if (audio[i].isDefault) return i;
    }
    return 0;
  }

  static String _localPathOf(String path) {
    if (path.startsWith('file://')) return Uri.parse(path).toFilePath();
    return path;
  }

  /// Resolves an input path into something FFprobe and FFmpeg can open.
  ///
  /// Android `content://` URIs go through the Storage Access Framework; the
  /// returned parameter is understood by FFmpegKit's probe and prepare runs.
  /// Plain paths and `file://` URIs are handled locally.
  static Future<String> _resolveInput(String path) async {
    if (path.startsWith('content://')) {
      final saf = await FFmpegKitConfig.getSafParameterForRead(path);
      if (saf == null || saf.isEmpty) {
        throw UnsupportedMediaException(
          'Cannot read the selected local file: the content URI could not be '
          'opened. Pick the file again from storage.',
        );
      }
      return saf;
    }
    return _localPathOf(path);
  }

  /// Generates a UUID v4-like string.
  static String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
