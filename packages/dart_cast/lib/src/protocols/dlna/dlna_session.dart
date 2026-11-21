import 'dart:async' show Timer, unawaited;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/cast_decision.dart';
import '../../core/cast_device.dart';
import '../../core/cast_exceptions.dart';
import '../../core/cast_ffmpeg_commands.dart';
import '../../core/cast_media.dart';
import '../../core/cast_prepare_session.dart';
import '../../core/cast_session.dart';
import '../../core/live_mkv_stream.dart';
import '../../core/media_probe.dart';
import '../../core/media_prober.dart';
import '../../core/media_proxy.dart';
import '../../core/media_transformer.dart';
import '../../core/webvtt_time_shifter.dart';
import '../../utils/logger.dart';
import '../../utils/network_utils.dart';
import 'dlna_controller.dart';
import 'dlna_device.dart';

/// A DLNA casting session that controls playback on a DLNA renderer.
///
/// Uses SOAP/UPnP to send AVTransport and RenderingControl actions.
class DlnaSession extends CastSession {
  /// The parsed device description with control URLs.
  final DlnaDeviceDescription description;

  final DlnaHttpClient _httpClient;
  final MediaProxy _proxy;
  final MediaTransformer _mediaTransformer;

  /// Duration we determined ourselves (explicit or probed from the source).
  /// Preferred over whatever the renderer reports for piped streams.
  Duration? _knownDuration;

  /// Whether the current route is a generated TS pipe rather than a real file.
  bool _isPipedStream = false;

  /// Title of the current item, reused when a piped stream is restarted.
  String? _currentTitle;

  /// Offset the current piped stream was restarted at.
  ///
  /// A restarted pipe begins at zero as far as the renderer is concerned, so
  /// this is added back to reported positions to keep the scrub bar absolute.
  Duration _pipedStartOffset = Duration.zero;

  Timer? _pollTimer;
  bool _isPolling = false;
  bool _isLoadingMedia = false;
  CastMedia? _currentMedia;
  CastSubtitle? _currentSubtitle;
  String? _currentProxyUrl;
  String? _currentProtocolInfo;
  int? _currentFileSize;
  Duration? _pendingSeekPosition;

  // ── Live remux state ──
  //
  // A local file whose audio/container is not directly usable is remuxed into
  // an MKV stream on demand (video copied, audio re-encoded to AAC). The
  // renderer's clock for such a stream starts at the point the remux began,
  // so restarts (audio/subtitle changes, seeks) are handled by opening a new
  // stream at the requested source offset.
  final MediaProber _prober;
  final Future<MediaProbe> Function(String input)? _probeFile;
  final LiveMkvRunManager _liveRuns;
  final Directory? _liveSubtitleTempDir;
  Future<void> Function()? _stopPrepare;
  Future<CastPrepareSession> Function({
    required String inputPath,
    required List<String> Function(String outputDir) buildArgs,
  })?
  _prepareStarter;

  bool _isLive = false;
  String? _liveFilePath;
  int _liveAudioIndex = 0;
  List<AudioStream> _liveAudioTracks = const [];
  Duration? _liveDuration;
  String _liveStreamType = 'BUFFERED';
  String? _liveToken;
  CastSubtitle? _liveSubtitle;
  int _liveSessionToken = 0;
  bool _restartInFlight = false;
  bool _handingPreparedToLoad = false;
  String? _shiftedSubtitlePath;
  int _shiftedSubtitleSequence = 0;

  /// How often the renderer is polled for position/state.
  final Duration pollInterval;

  /// Creates a [DlnaSession] for the given [device] and [description].
  ///
  /// An optional [httpClient] can be provided for testing.
  ///
  /// Prefer using [DlnaSession.fromDevice] which automatically extracts
  /// the device description from the metadata set by [DlnaDiscoveryProvider].
  /// An optional [mediaTransformer] can customize how media is prepared
  /// before casting (e.g., custom segmentation, transcoding).
  ///
  /// [prober] overrides media probing; [probeFile] is a test seam that
  /// replaces it entirely. [liveRuns] is a test seam for the live remux
  /// lifecycle and [liveSubtitleTempDir] overrides where shifted live
  /// subtitles are written.
  DlnaSession({
    required CastDevice device,
    required this.description,
    DlnaHttpClient? httpClient,
    MediaProxy? proxy,
    MediaTransformer? mediaTransformer,
    MediaProber? prober,
    Future<MediaProbe> Function(String input)? probeFile,
    LiveMkvRunManager? liveRuns,
    Directory? liveSubtitleTempDir,
    Future<CastPrepareSession> Function({
      required String inputPath,
      required List<String> Function(String outputDir) buildArgs,
    })?
    prepareStarter,
    this.pollInterval = const Duration(seconds: 1),
  }) : _httpClient = httpClient ?? DlnaHttpClient(),
       _proxy = proxy ?? MediaProxy(),
       _mediaTransformer = mediaTransformer ?? const DefaultMediaTransformer(),
       _prober = prober ?? const FfprobeMediaProber(),
       _probeFile = probeFile,
       _liveRuns = liveRuns ?? LiveMkvRunManager.production(),
       _liveSubtitleTempDir = liveSubtitleTempDir,
       _prepareStarter = prepareStarter,
       super(device);

  // ── Live state (parity with Chromecast) ──

  @override
  bool get isLive => _isLive;

  @override
  String? get liveFilePath => _liveFilePath;

  @override
  int get liveAudioIndex => _liveAudioIndex;

  @override
  List<AudioStream> get liveAudioTracks => _liveAudioTracks;

  @override
  Duration? get liveDuration => _liveDuration;

  @override
  Duration get liveStartOffset => _isLive ? _pipedStartOffset : Duration.zero;

  @override
  int get liveSessionToken => _liveSessionToken;

  /// Creates a [DlnaSession] from a [CastDevice] discovered by
  /// [DlnaDiscoveryProvider].
  ///
  /// Automatically extracts the device description (control URLs, etc.)
  /// from the device's metadata. This is the recommended constructor
  /// when using devices from discovery.
  ///
  /// Throws [ArgumentError] if the device metadata is missing required
  /// DLNA control URLs (e.g., if the device was not discovered by
  /// [DlnaDiscoveryProvider]).
  factory DlnaSession.fromDevice(
    CastDevice device, {
    DlnaHttpClient? httpClient,
  }) {
    final avTransportUrl = device.metadata['avTransportControlUrl'];
    final renderingControlUrl = device.metadata['renderingControlUrl'];

    if (avTransportUrl == null || avTransportUrl.isEmpty) {
      throw ArgumentError(
        'CastDevice "${device.name}" is missing the DLNA AVTransport control URL '
        'in its metadata. This usually means the device was not discovered by '
        'DlnaDiscoveryProvider, or the device description XML did not contain '
        'an AVTransport service. '
        'Expected metadata key: "avTransportControlUrl". '
        'Available metadata keys: ${device.metadata.keys.toList()}',
      );
    }

    final connectionManagerControlUrl =
        device.metadata['connectionManagerControlUrl'];

    final description = DlnaDeviceDescription(
      friendlyName: device.name,
      udn: device.id,
      manufacturer: device.metadata['manufacturer'],
      modelName: device.metadata['modelName'],
      avTransportControlUrl: avTransportUrl,
      renderingControlUrl: renderingControlUrl,
      connectionManagerControlUrl: connectionManagerControlUrl,
      locationUrl: 'http://${device.address.address}:${device.port}',
    );

    return DlnaSession(
      device: device,
      description: description,
      httpClient: httpClient,
    );
  }

  /// Connects to the DLNA device by verifying it is reachable.
  @override
  Future<void> connect() async {
    CastLogger.info(
      'DLNA: connecting to ${device.name} at ${device.address.address}:${device.port}',
    );
    stateMachine.transitionTo(SessionState.connecting);
    // For DLNA, "connect" simply means we verified the device is reachable.
    // There is no persistent connection — each action is an HTTP POST.
    stateMachine.transitionTo(SessionState.connected);
    CastLogger.info('DLNA: connected to ${device.name}');
  }

  @override
  Future<void> loadMedia(
    CastMedia media, {
    bool bypassTransform = false,
  }) async {
    if (_isLoadingMedia) {
      CastLogger.warning(
        'DLNA: loadMedia called while already loading — ignoring',
      );
      return;
    }
    _isLoadingMedia = true;
    try {
      // A plain load replaces whatever live remux / prepared HLS / prepare
      // session the previous item owned — except when the prepared HLS URL is
      // being handed to this very load.
      if (!_handingPreparedToLoad) {
        await _cleanupCastResources();
        _releaseLiveToken();
        _resetLiveMetadata();
      }
      await _loadMediaInternal(media);
    } catch (_) {
      // Don't get stuck in `loading` if anything below throws.
      if (stateMachine.canTransitionTo(SessionState.idle)) {
        stateMachine.transitionTo(SessionState.idle);
      }
      rethrow;
    } finally {
      _isLoadingMedia = false;
    }
  }

  /// Loads [media] through the proxy.
  ///
  /// [proxyUrlOverride] skips the transformer for URLs this session already
  /// registered itself (live remux routes). [live] marks the load as a live
  /// remux stream, which changes the advertised seek mode and stops the poll
  /// from adding the live offset twice.
  Future<void> _loadMediaInternal(
    CastMedia media, {
    String? proxyUrlOverride,
    bool live = false,
  }) async {
    CastLogger.info('DLNA: loadMedia called, state=${stateMachine.state}');
    stateMachine.transitionTo(SessionState.loading);
    _currentMedia = media;
    _currentSubtitle = media.defaultSubtitle;

    // Start proxy and transform media
    await _proxy.start(targetDeviceIp: device.address.address);

    // Use transformer for media preparation (register, wrap TS in HLS, etc.)
    // unless the caller already registered the route.
    final transformed = proxyUrlOverride == null
        ? await _mediaTransformer.transform(media, _proxy)
        : null;
    String proxyUrl = proxyUrlOverride ?? transformed!.proxyUrl;
    final effectiveType = transformed?.effectiveType ?? media.type;
    final String protocolInfo;

    // DLNA flags must match between DIDL-Lite protocolInfo and HTTP headers.
    // Use 01700000 (STREAMING + BACKGROUND + CONNECTION_STALL + V1.5) —
    // same as VLC and MiniDLNA. Include DLNA.ORG_PN profile name so the
    // renderer knows the codec without probing the stream.
    const dlnaFlags = '01700000000000000000000000000000';

    // Piped-TS routes are generated on the fly: there is no Content-Length and
    // byte ranges cannot be served. DLNA.ORG_OP is "<time-seek><byte-seek>",
    // so those routes must advertise 10 (time seek only) rather than 01.
    // Claiming byte-range seek on a stream that answers `Accept-Ranges: none`
    // is what made this TV stop playback the moment a seek was issued.
    const opByteSeek = 'DLNA.ORG_OP=01';
    const opTimeSeek = 'DLNA.ORG_OP=10';
    var isPipedStream = false;
    Duration? probedDuration;

    if (live) {
      // Live remux: no length, no byte ranges. Time seek is advertised because
      // this session implements it by restarting the remux at the target.
      protocolInfo =
          'http-get:*:video/x-matroska:$opTimeSeek;DLNA.ORG_CI=1;DLNA.ORG_FLAGS=$dlnaFlags';
    } else if (media.type == CastMediaType.hls) {
      // Remote HLS → pipe as continuous MPEG-TS stream for DLNA. The
      // handler internally detects alternate-audio HLS and muxes
      // video+audio per segment via [TsAltAudioRemuxer] so the TV
      // gets one continuous TS regardless of source layout.
      isPipedStream = true;
      // Probe the source playlist before piping it: a renderer given a
      // length-less TS otherwise reports a 1-second duration and draws no
      // scrub bar.
      probedDuration = await _proxy.probeHlsDuration(
        media.url,
        headers: media.httpHeaders,
      );
      proxyUrl = _proxy.registerHlsAsStream(
        media.url,
        headers: media.httpHeaders,
      );
      protocolInfo =
          'http-get:*:video/mp2t:DLNA.ORG_PN=MPEG_TS_HD_NA_ISO;$opTimeSeek;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=$dlnaFlags';
    } else if (effectiveType == CastMediaType.hls) {
      // Transformer wrapped media in HLS → pipe as TS stream for DLNA
      isPipedStream = true;
      probedDuration = await _proxy.probeHlsDuration(proxyUrl);
      proxyUrl = _proxy.registerHlsAsStream(proxyUrl);
      protocolInfo =
          'http-get:*:video/mp2t:DLNA.ORG_PN=MPEG_TS_HD_NA_ISO;$opTimeSeek;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=$dlnaFlags';
    } else if (effectiveType == CastMediaType.mpegTs) {
      protocolInfo =
          'http-get:*:video/mp2t:DLNA.ORG_PN=MPEG_TS_HD_NA_ISO;$opByteSeek;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=$dlnaFlags';
    } else if (effectiveType == CastMediaType.mkv) {
      protocolInfo =
          'http-get:*:video/x-matroska:$opByteSeek;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=$dlnaFlags';
    } else {
      protocolInfo =
          'http-get:*:video/mp4:DLNA.ORG_PN=AVC_MP4_HP_HD_AAC;$opByteSeek;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=$dlnaFlags';
    }

    _currentProxyUrl = proxyUrl;
    _currentProtocolInfo = protocolInfo;

    CastLogger.info(
      'DLNA: loading media, effectiveType=$effectiveType.name',
    );
    CastLogger.debug('DLNA: proxy URL = $proxyUrl');
    CastLogger.debug('DLNA: protocolInfo=$protocolInfo');

    // Register subtitle in both SRT and VTT formats so the TV can pick
    // whichever it supports. Many DLNA TVs only support SRT, others VTT.
    List<({String url, String format})>? subtitleVariants;
    // Honour the caller's declared default before falling back to the first
    // listed track — same language-selection contract as Chromecast.
    final subtitleSource =
        media.defaultSubtitle ??
        (media.subtitles.isNotEmpty ? media.subtitles.first : _currentSubtitle);
    if (subtitleSource != null) {
      subtitleVariants = _proxy.registerSubtitleVariants(
        subtitleSource.url,
        headers: media.httpHeaders,
      );
    }

    // Build duration string for DIDL-Lite <res> element (HH:MM:SS).
    // An explicit media.duration wins; otherwise use whatever the HLS probe
    // found, so piped streams still get a scrub bar.
    final effectiveDuration = media.duration ?? probedDuration;
    final durationStr =
        effectiveDuration != null
            ? NetworkUtils.formatDuration(effectiveDuration)
            : null;
    if (isPipedStream) {
      CastLogger.info(
        'DLNA: piped TS route, seek mode=time, '
        'duration=${durationStr ?? 'unknown'}',
      );
    }

    // File size for local files — helps DLNA renderer know the content length
    final fileSize = media.isLocalFile ? File(media.url).lengthSync() : null;
    _currentFileSize = fileSize;

    // Send SetAVTransportURI with proxy URL (not original URL)
    await _sendAvTransport(
      'SetAVTransportURI',
      DlnaSoapBuilder.buildSetAVTransportURI(
        proxyUrl,
        title: media.title,
        subtitleVariants: subtitleVariants,
        protocolInfo: protocolInfo,
        duration: durationStr,
        size: fileSize,
      ),
    );

    // Set known duration immediately if available (the TV may report 0
    // for piped streams since it doesn't know the total size upfront)
    _knownDuration = effectiveDuration;
    _isPipedStream = isPipedStream;
    _currentTitle = media.title;
    // A live restart sets its own source offset before loading; every other
    // load starts at zero.
    if (!live) _pipedStartOffset = Duration.zero;
    _liveSessionToken++;
    if (effectiveDuration != null) {
      updateDuration(effectiveDuration);
    }

    // Send Play
    await _sendAvTransport('Play', DlnaSoapBuilder.buildPlay());

    stateMachine.transitionTo(SessionState.playing);

    // Save start position — will seek after TV confirms PLAYING via poll.
    // Seeking immediately after Play fails because the TV hasn't loaded yet.
    if (media.startPosition != null && media.startPosition! > Duration.zero) {
      _pendingSeekPosition = media.startPosition;
      CastLogger.info(
        'DLNA: deferred seek to ${media.startPosition!.inSeconds}s (waiting for TV to load)',
      );
    }

    // Start position polling
    _startPolling();
  }

  @override
  Future<void> play() async {
    CastLogger.info('DLNA: Play');
    await _sendAvTransport('Play', DlnaSoapBuilder.buildPlay());
    if (stateMachine.canTransitionTo(SessionState.playing)) {
      stateMachine.transitionTo(SessionState.playing);
    }
  }

  @override
  Future<void> pause() async {
    CastLogger.info('DLNA: Pause');
    await _sendAvTransport('Pause', DlnaSoapBuilder.buildPause());
    if (stateMachine.canTransitionTo(SessionState.paused)) {
      stateMachine.transitionTo(SessionState.paused);
    }
  }

  @override
  Future<void> stop() async {
    CastLogger.info('DLNA: Stop');
    _stopPolling();
    await _sendAvTransport('Stop', DlnaSoapBuilder.buildStop());
    if (stateMachine.canTransitionTo(SessionState.idle)) {
      stateMachine.transitionTo(SessionState.idle);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    CastLogger.info('DLNA: Seek to ${position.inSeconds}s');

    if (_isLive) {
      // A live remux has no length and no byte offsets; the only seek is a
      // restart of the remux at the target source position.
      if (_restartInFlight) {
        throw StateError('A live restart is already in progress');
      }
      final filePath = _liveFilePath;
      if (filePath == null) {
        throw StateError('Live seek requested without a live source file');
      }
      var target = position;
      final duration = _liveDuration;
      if (target < Duration.zero) {
        target = Duration.zero;
      } else if (duration != null && target > duration) {
        target = duration;
      }
      await _restartLiveStream(
        filePath: filePath,
        audioIndex: _liveAudioIndex,
        position: target,
        streamType: _liveStreamType,
      );
      return;
    }

    if (_isPipedStream) {
      // A piped TS has no length and no byte offsets, so a renderer cannot
      // seek inside it — the TCL Google TV answers a REL_TIME Seek by simply
      // going to STOPPED. Re-point it at the same route with the offset
      // encoded instead: the proxy restarts the stream at that segment, which
      // is a seek from the viewer's point of view.
      await _reloadPipedStreamAt(position);
      _pipedStartOffset = position;
      updatePosition(position);
      return;
    }

    await _sendAvTransport('Seek', DlnaSoapBuilder.buildSeek(position));
    // Update position immediately so the UI reflects the seek without
    // waiting for the next polling cycle.
    updatePosition(position);
  }

  /// Restarts a piped-TS route at [position] by re-issuing SetAVTransportURI.
  Future<void> _reloadPipedStreamAt(Duration position) async {
    final baseUrl = _currentProxyUrl;
    final protocolInfo = _currentProtocolInfo;
    if (baseUrl == null || protocolInfo == null) return;

    final seconds = position.inMilliseconds / 1000.0;
    final separator = baseUrl.contains('?') ? '&' : '?';
    final seekUrl = '$baseUrl${separator}t=${seconds.toStringAsFixed(3)}';

    CastLogger.info('DLNA: restarting piped stream at ${position.inSeconds}s');

    await _sendAvTransport('Stop', DlnaSoapBuilder.buildStop());
    await _sendAvTransport(
      'SetAVTransportURI',
      DlnaSoapBuilder.buildSetAVTransportURI(
        seekUrl,
        title: _currentTitle,
        protocolInfo: protocolInfo,
        duration:
            _knownDuration != null
                ? NetworkUtils.formatDuration(_knownDuration!)
                : null,
      ),
    );
    await _sendAvTransport('Play', DlnaSoapBuilder.buildPlay());
  }

  @override
  Future<void> setVolume(double volume) async {
    CastLogger.info('DLNA: SetVolume ${volume.toStringAsFixed(2)}');
    final intVolume = (volume.clamp(0.0, 1.0) * 100).round();
    final controlUrl = description.renderingControlUrl;
    if (controlUrl == null) return;

    await _httpClient.sendAction(
      controlUrl,
      DlnaServiceType.renderingControl,
      'SetVolume',
      DlnaSoapBuilder.buildSetVolume(intVolume),
    );
    updateVolume(volume);
  }

  @override
  Future<void> setSubtitle(CastSubtitle? subtitle) async {
    // A live remux is restarted at the current position so the subtitle can
    // be re-derived for the new stream's zero point.
    if (_isLive) {
      await switchLiveSubtitle(subtitle: subtitle, position: position);
      return;
    }

    _currentSubtitle = subtitle;
    final media = _currentMedia;
    if (media == null || _currentProxyUrl == null) return;

    // Re-issuing SetAVTransportURI resets the renderer to zero, so remember
    // where playback was and restore it: a subtitle change must never rewind
    // the viewer.
    final resumeAt = position;

    List<({String url, String format})>? subtitleVariants;
    if (subtitle != null) {
      subtitleVariants = _proxy.registerSubtitleVariants(
        subtitle.url,
        headers: media.httpHeaders,
      );
    }

    var uri = _currentProxyUrl!;
    Duration? deferredSeek;
    if (_isPipedStream) {
      // Piped routes carry the start offset in the URL; there is no REL_TIME
      // seek to fall back on.
      if (resumeAt > Duration.zero) {
        final seconds = resumeAt.inMilliseconds / 1000.0;
        final separator = uri.contains('?') ? '&' : '?';
        uri = '$uri${separator}t=${seconds.toStringAsFixed(3)}';
        _pipedStartOffset = resumeAt;
      } else {
        _pipedStartOffset = Duration.zero;
      }
    } else if (resumeAt > Duration.zero) {
      deferredSeek = resumeAt;
    }

    await _sendAvTransport(
      'SetAVTransportURI',
      DlnaSoapBuilder.buildSetAVTransportURI(
        uri,
        title: media.title,
        subtitleVariants: subtitleVariants,
        protocolInfo: _currentProtocolInfo ?? 'http-get:*:video/mp4:*',
        duration:
            _knownDuration != null
                ? NetworkUtils.formatDuration(_knownDuration!)
                : null,
        size: _isPipedStream ? null : _currentFileSize,
      ),
    );

    // Resume playback, then restore the previous position once the renderer
    // reports PLAYING (seeking immediately after a URI change is ignored).
    await _sendAvTransport('Play', DlnaSoapBuilder.buildPlay());
    _pendingSeekPosition = deferredSeek;
    _startPolling();
  }

  /// Loads a local file, choosing direct play, live remux or transcode.
  ///
  /// Mirrors the Chromecast pipeline: the file is probed once and [decide]
  /// picks the cheapest strategy that can work. Direct play keeps the original
  /// file; a remux plan streams an MKV with audio re-encoded to AAC; a
  /// transcode plan prepares an HLS stream with an H.264 encoder.
  @override
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    CastDeviceCaps caps = const CastDeviceCaps(),
    CastSubtitle? subtitle,
    String streamType = 'BUFFERED',
  }) async {
    // A new load replaces any live run / prepared HLS / previous prepare.
    await _cleanupCastResources();
    _releaseLiveToken();
    _resetLiveMetadata();

    final input = _localPathOf(path);
    MediaProbe probe;
    try {
      final probeFile = _probeFile;
      probe =
          probeFile != null
              ? await probeFile(input)
              : await _prober.probe(input);
    } on ProbeFailedException {
      rethrow;
    } catch (e) {
      throw ProbeFailedException('Probe failed: $e', e);
    }

    final plan = decide(probe, caps);
    final audioIdx =
        audioStreamIndex == 0
            ? _defaultAudioIndex(probe.audio)
            : audioStreamIndex;
    final mediaType = CastCompat.mediaTypeForContainer(probe.container);

    if (plan is DirectPlan || plan is UncertainDirectPlan) {
      try {
        await loadMedia(
          CastMedia.file(
            filePath: path,
            type: mediaType,
            duration: probe.duration,
            subtitles: subtitle != null ? [subtitle] : const [],
            defaultSubtitle: subtitle,
          ),
        );
        return;
      } catch (e) {
        // Only a direct attempt we were already unsure about falls through to
        // a transcode; a definite direct plan failing is a hard error.
        final canTranscode =
            caps.transcodeEnabled &&
            (caps.hasH264Encoder ||
                caps.hasLibx264 ||
                caps.hasH264Mediacodec);
        if (plan is! UncertainDirectPlan || !canTranscode) {
          throw UnsupportedMediaException(
            'This DLNA device can\'t play this video '
            '(${probe.video?.codec ?? 'unknown'})',
          );
        }
      }
    }

    if (plan is RemuxAudioPlan || plan is RemuxContainerPlan) {
      await loadLiveMkv(
        filePath: path,
        audioIndex: audioIdx,
        streamType: streamType,
        duration: probe.duration,
        audioTracks: probe.audio,
        subtitle: subtitle,
      );
      return;
    }

    if (plan is TranscodeVideoPlan || plan is UncertainDirectPlan) {
      await _loadTranscoded(
        path: path,
        audioIndex: audioIdx,
        caps: caps,
        duration: probe.duration,
        subtitle: subtitle,
      );
      return;
    }

    if (plan is UnsupportedPlan) {
      throw UnsupportedMediaException('Unsupported: ${plan.reason}');
    }
    throw UnsupportedMediaException('Unsupported: ${plan.runtimeType}');
  }

  /// Loads a local file as a live remux stream (no disk buffering).
  ///
  /// [duration] and [audioTracks] let a caller that already probed the file
  /// hand the results in, avoiding a second FFprobe.
  Future<void> loadLiveMkv({
    required String filePath,
    required int audioIndex,
    required String streamType,
    Duration? duration,
    List<AudioStream> audioTracks = const [],
    CastSubtitle? subtitle,
  }) async {
    await _cleanupCastResources();
    _releaseLiveToken();
    _resetLiveMetadata();
    _liveSubtitle = subtitle;
    _pipedStartOffset = Duration.zero;
    await _proxy.start(targetDeviceIp: device.address.address);

    await _startLiveStream(
      filePath: filePath,
      audioIndex: audioIndex,
      streamType: streamType,
      duration: duration,
      audioTracks: audioTracks,
    );
  }

  /// Registers and loads one live MKV remux stream.
  ///
  /// The caller must already have closed the previous live run and released
  /// its URL. Live metadata is published before the URI is sent so the domain
  /// layer can map receiver time onto the source timeline right away.
  Future<void> _startLiveStream({
    required String filePath,
    required int audioIndex,
    required String streamType,
    required Duration? duration,
    required List<AudioStream> audioTracks,
    double? startSeconds,
  }) async {
    _liveFilePath = filePath;
    _liveAudioIndex = audioIndex;
    _liveAudioTracks = List.unmodifiable(audioTracks);
    _liveDuration = duration;
    _liveStreamType = streamType;
    _isLive = true;

    final liveUrl = _proxy.registerLiveStream(
      open: () => _liveRuns.open(
        filePath: filePath,
        audioIndex: audioIndex,
        startSeconds: startSeconds,
      ),
      contentType: 'video/x-matroska',
    );
    _liveToken = Uri.parse(liveUrl).pathSegments.last;
    CastLogger.info(
      'DLNA: live remux registered (audio=$audioIndex, '
      'start=${startSeconds ?? 0}s)',
    );

    // A failure to prepare subtitles downgrades the stream to "no subtitles"
    // instead of failing the cast.
    final liveSubtitle = await _preparedLiveSubtitle(startSeconds);

    try {
      await _loadMediaInternal(
        CastMedia(
          url: liveUrl,
          type: CastMediaType.mkv,
          title: 'Live MKV',
          duration: duration,
          subtitles: liveSubtitle != null ? [liveSubtitle] : const [],
          defaultSubtitle: liveSubtitle,
        ),
        proxyUrlOverride: liveUrl,
        live: true,
      );
    } catch (e) {
      await _liveRuns.closeAll();
      _releaseLiveToken();
      _resetLiveMetadata();
      rethrow;
    }
  }

  /// Closes the current live stream and starts a new one at [position].
  Future<void> _restartLiveStream({
    required String filePath,
    required int audioIndex,
    required Duration position,
    required String streamType,
    Duration? duration,
    List<AudioStream>? audioTracks,
  }) async {
    if (_restartInFlight || _isLoadingMedia) {
      throw StateError('Another cast load is already in progress');
    }
    _restartInFlight = true;
    try {
      // Switching away from a direct load has no live metadata to keep, so
      // the caller supplies the probe results.
      final effectiveDuration = duration ?? _liveDuration;
      final effectiveTracks = audioTracks ?? _liveAudioTracks;
      await _cleanupCastResources();
      _releaseLiveToken();
      _pipedStartOffset = position;
      await _proxy.start(targetDeviceIp: device.address.address);
      await _startLiveStream(
        filePath: filePath,
        audioIndex: audioIndex,
        streamType: streamType,
        duration: effectiveDuration,
        audioTracks: effectiveTracks,
        startSeconds: position.inMilliseconds / 1000.0,
      );
      CastLogger.info(
        'DLNA: live restart complete (audio=$audioIndex, '
        'offset=${position.inSeconds}s)',
      );
    } catch (e) {
      await _liveRuns.closeAll();
      _releaseLiveToken();
      _resetLiveMetadata();
      rethrow;
    } finally {
      _restartInFlight = false;
    }
  }

  /// Restarts the live remux with a different audio track at [position].
  @override
  Future<void> switchLiveAudio({
    required String filePath,
    required int audioIndex,
    required Duration position,
    required String streamType,
    Duration? duration,
    List<AudioStream>? audioTracks,
  }) => _restartLiveStream(
    filePath: filePath,
    audioIndex: audioIndex,
    position: position,
    streamType: streamType,
    duration: duration,
    audioTracks: audioTracks,
  );

  /// Attaches, replaces or clears the live stream's subtitle.
  ///
  /// The remux restarts at [position] with a time-shifted copy of [subtitle],
  /// so receiver time zero matches that source position. [subtitle] must be a
  /// full-timeline WebVTT file; it is validated before anything changes.
  @override
  Future<void> switchLiveSubtitle({
    required CastSubtitle? subtitle,
    required Duration position,
  }) async {
    final filePath = _liveFilePath;
    if (!_isLive || filePath == null) {
      throw StateError('switchLiveSubtitle requires a live remux stream');
    }
    if (subtitle != null) {
      await _validateLiveSubtitleSource(subtitle, position);
    }
    _liveSubtitle = subtitle;
    await _restartLiveStream(
      filePath: filePath,
      audioIndex: _liveAudioIndex,
      position: position,
      streamType: _liveStreamType,
    );
  }

  /// Prepares an HLS stream with an H.264 encoder and loads it.
  ///
  /// DLNA receives the prepared playlist as a continuous MPEG-TS pipe, which
  /// is the same route remote HLS uses and the format TVs handle best.
  Future<void> _loadTranscoded({
    required String path,
    required int audioIndex,
    required CastDeviceCaps caps,
    required Duration? duration,
    CastSubtitle? subtitle,
  }) async {
    List<String> Function(String outputDir) builder;
    if (caps.hasH264Mediacodec) {
      builder =
          (out) => CastFfmpegCommands.transcodeVideoMediacodec(
            input: path,
            outputDir: out,
            audioStreamIndex: audioIndex,
          );
    } else if (caps.hasLibx264) {
      builder =
          (out) => CastFfmpegCommands.transcodeVideo(
            input: path,
            outputDir: out,
            audioStreamIndex: audioIndex,
            videoEncoder: 'libx264',
          );
    } else {
      throw UnsupportedMediaException('Unsupported: no usable H.264 encoder');
    }

    final prepareStarter = _prepareStarter;
    final prepare =
        prepareStarter != null
            ? await prepareStarter(inputPath: path, buildArgs: builder)
            : await CastPrepareSession.start(
              inputPath: path,
              buildArgs: builder,
            );
    _stopPrepare = prepare.stop;

    await prepare.stateStream.firstWhere(
      (s) => s == PrepareState.ready || s == PrepareState.failed,
    );
    if (prepare.state != PrepareState.ready) {
      await _cleanupCastResources();
      throw PrepareFailedException('Prepare failed: ${prepare.error}');
    }

    await _proxy.start(targetDeviceIp: device.address.address);
    final hlsUrl = _proxy.registerHlsDirectory(
      prepare.sessionId,
      prepare.tempDir.path,
    );

    // This prepare session belongs to this load — keep loadMedia's cleanup
    // from deleting the temp dir we just prepared.
    _handingPreparedToLoad = true;
    try {
      await loadMedia(
        CastMedia(
          url: hlsUrl,
          type: CastMediaType.hls,
          duration: duration,
          subtitles: subtitle != null ? [subtitle] : const [],
          defaultSubtitle: subtitle,
        ),
      );
    } finally {
      _handingPreparedToLoad = false;
    }
  }

  /// Validates [subtitle] for [position] without touching live state.
  Future<void> _validateLiveSubtitleSource(
    CastSubtitle subtitle,
    Duration position,
  ) async {
    final String text;
    try {
      text = await File(_localPathOf(subtitle.url)).readAsString();
    } catch (e) {
      throw SubtitleAttachException(
        'Live subtitle source could not be read',
        e,
      );
    }

    final body = text.startsWith('\uFEFF') ? text.substring(1) : text;
    if (!body.startsWith('WEBVTT')) {
      throw SubtitleAttachException('Live subtitle source is not a WebVTT file');
    }

    try {
      WebVttTimeShifter.shift(text, position);
    } catch (e) {
      throw SubtitleAttachException(
        'Live subtitle source could not be time-shifted',
        e,
      );
    }
  }

  /// Builds the shifted copy of [_liveSubtitle] for a run starting at
  /// [startSeconds], or null when there is nothing to attach.
  Future<CastSubtitle?> _preparedLiveSubtitle(double? startSeconds) async {
    final source = _liveSubtitle;
    if (source == null) return null;

    try {
      final text = await File(_localPathOf(source.url)).readAsString();
      final body = text.startsWith('\uFEFF') ? text.substring(1) : text;
      if (!body.startsWith('WEBVTT')) {
        throw const FormatException('Not a WebVTT document');
      }
      final offset = Duration(
        milliseconds: ((startSeconds ?? 0) * 1000).round(),
      );
      final shifted = WebVttTimeShifter.shift(text, offset);
      final path = await _writeShiftedLiveSubtitle(shifted);
      return CastSubtitle(
        url: Uri.file(path).toString(),
        label: source.label,
        language: source.language,
        format: 'vtt',
      );
    } catch (_) {
      CastLogger.warning(
        'DLNA: live subtitle could not be prepared; continuing without '
        'subtitles',
      );
      _liveSubtitle = null;
      await _deleteShiftedLiveSubtitle();
      return null;
    }
  }

  /// Writes [content] to a fresh shifted-subtitle file and returns its path.
  Future<String> _writeShiftedLiveSubtitle(String content) async {
    await _deleteShiftedLiveSubtitle();
    final dir = await _resolveLiveSubtitleTempDir();
    final path =
        '${dir.path}/dlna_live_sub_'
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${_shiftedSubtitleSequence++}.vtt';
    await File(path).writeAsString(content, flush: true);
    _shiftedSubtitlePath = path;
    return path;
  }

  Future<Directory> _resolveLiveSubtitleTempDir() async {
    final override = _liveSubtitleTempDir;
    final dir =
        override ??
        Directory('${(await getTemporaryDirectory()).path}/dlna_live_sub_');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _deleteShiftedLiveSubtitle() async {
    final path = _shiftedSubtitlePath;
    _shiftedSubtitlePath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _cleanupCastResources() async {
    await _liveRuns.closeAll();
    await _stopPrepareSession();
    await _deleteShiftedLiveSubtitle();
  }

  Future<void> _stopPrepareSession() async {
    final stop = _stopPrepare;
    _stopPrepare = null;
    if (stop != null) {
      try {
        await stop();
      } catch (_) {}
    }
  }

  /// Unregisters the live route so a late renderer request cannot start a
  /// new run after teardown.
  void _releaseLiveToken() {
    final token = _liveToken;
    _liveToken = null;
    if (token != null) _proxy.unregisterLiveStream(token);
  }

  void _resetLiveMetadata() {
    _isLive = false;
    _liveFilePath = null;
    _liveAudioIndex = 0;
    _liveAudioTracks = const [];
    _liveDuration = null;
    _liveStreamType = 'BUFFERED';
    _liveSubtitle = null;
    unawaited(_deleteShiftedLiveSubtitle());
  }

  int _defaultAudioIndex(List<AudioStream> audio) {
    for (var i = 0; i < audio.length; i++) {
      if (audio[i].isDefault) return i;
    }
    return 0;
  }

  String _localPathOf(String url) =>
      url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;

  @override
  Future<void> disconnect() async {
    CastLogger.info('DLNA: disconnecting from ${device.name}');
    _stopPolling();

    // Try to stop playback
    try {
      await _sendAvTransport('Stop', DlnaSoapBuilder.buildStop());
    } catch (e) {
      CastLogger.warning('DLNA: error sending Stop during disconnect: $e');
    }

    await _cleanupCastResources();
    _releaseLiveToken();
    _resetLiveMetadata();
    await _proxy.stop();
    stateMachine.transitionTo(SessionState.disconnected);
    CastLogger.info('DLNA: disconnected from ${device.name}');
  }

  /// Disposes of resources used by this session.
  ///
  /// Prefer calling [disconnect] before [dispose] for a clean shutdown
  /// that awaits the proxy server stop.
  @override
  void dispose() {
    _stopPolling();
    _httpClient.close();
    // Fire-and-forget — callers should await disconnect() before dispose() for clean shutdown
    unawaited(_cleanupCastResources());
    _releaseLiveToken();
    unawaited(_proxy.stop());
    super.dispose();
  }

  /// Checks whether the device supports the given [mimeType].
  ///
  /// Queries the ConnectionManager's GetProtocolInfo action and checks
  /// whether the Sink list contains the specified MIME type.
  /// Returns `false` if no ConnectionManager URL is available.
  Future<bool> supportsMediaType(String mimeType) async {
    final controlUrl = description.connectionManagerControlUrl;
    if (controlUrl == null) return false;

    try {
      final response = await _httpClient.sendAction(
        controlUrl,
        DlnaServiceType.connectionManager,
        'GetProtocolInfo',
        DlnaSoapBuilder.buildGetProtocolInfo(),
      );
      final protocols = DlnaSoapParser.parseProtocolInfo(response);
      return protocols.any((p) => p.contains(mimeType));
    } catch (e) {
      CastLogger.warning('DLNA: failed to query GetProtocolInfo: $e');
      return false;
    }
  }

  // -- Private helpers --

  Future<String> _sendAvTransport(String action, String body) async {
    final controlUrl = description.avTransportControlUrl;
    if (controlUrl == null) {
      throw StateError(
        'No AVTransport control URL available for "${device.name}". '
        'Use DlnaSession.fromDevice() to auto-extract URLs from discovery metadata, '
        'or ensure DlnaDeviceDescription has avTransportControlUrl set.',
      );
    }

    // Non-polling actions get logged at info level
    final isPolling =
        action == 'GetPositionInfo' ||
        action == 'GetTransportInfo' ||
        action == 'GetVolume';
    if (!isPolling) {
      CastLogger.debug('DLNA: $action → $controlUrl');
    }

    final response = await _httpClient.sendAction(
      controlUrl,
      DlnaServiceType.avTransport,
      action,
      body,
    );

    if (!isPolling) {
      CastLogger.info('DLNA: $action response (${response.length} chars)');
      CastLogger.debug('DLNA: $action response body: $response');
    }
    return response;
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      // Get position info
      final positionResponse = await _sendAvTransport(
        'GetPositionInfo',
        DlnaSoapBuilder.buildGetPositionInfo(),
      );
      final posInfo = DlnaSoapParser.parsePositionInfo(positionResponse);
      CastLogger.debug(
        'DLNA: poll position=${posInfo.position.inSeconds}s, duration=${posInfo.duration.inSeconds}s',
      );
      // A live remux restarts at a source offset, but the receiver's clock
      // begins at zero for the new run. The domain layer adds
      // `liveStartOffset` to map it back, so the raw value is emitted here.
      // Piped (non-live) streams have no such mapping and are made absolute
      // in this session.
      // While a live restart is in flight the renderer can still answer for
      // the stream we just replaced (or report 0 before it starts). Emitting
      // either would move the UI's position to a bogus spot, so hold the
      // previous position until the new run reports for itself.
      if (!(_isLive && _restartInFlight)) {
        updatePosition(
          _isLive ? posInfo.position : posInfo.position + _pipedStartOffset,
        );
      }
      // Only trust the device's duration when we have nothing better.
      // A renderer fed a length-less piped TS reports a placeholder — this TV
      // says 0:00:01 — which would otherwise clobber the real duration probed
      // from the HLS playlist and collapse the scrub bar.
      final deviceDuration = posInfo.duration;
      final known = _knownDuration;
      final devicePlaceholder = deviceDuration <= const Duration(seconds: 2);
      if (deviceDuration > Duration.zero &&
          !(known != null && devicePlaceholder)) {
        updateDuration(deviceDuration);
      }

      // Get transport info for state detection
      final transportResponse = await _sendAvTransport(
        'GetTransportInfo',
        DlnaSoapBuilder.buildGetTransportInfo(),
      );
      CastLogger.debug('DLNA: GetTransportInfo response: $transportResponse');
      final transportState = DlnaSoapParser.parseTransportInfo(
        transportResponse,
      );

      _handleTransportState(transportState);

      // Poll volume from RenderingControl
      final controlUrl = description.renderingControlUrl;
      if (controlUrl != null) {
        try {
          final volumeResponse = await _httpClient.sendAction(
            controlUrl,
            DlnaServiceType.renderingControl,
            'GetVolume',
            DlnaSoapBuilder.buildGetVolume(),
          );
          final intVolume = DlnaSoapParser.parseVolume(volumeResponse);
          updateVolume(intVolume / 100.0);
        } catch (e) {
          CastLogger.debug('DLNA: volume polling failed: $e');
        }
      }
    } catch (e) {
      CastLogger.debug('DLNA: polling failed: $e');
    } finally {
      _isPolling = false;
    }
  }

  void _handleTransportState(String transportState) {
    CastLogger.debug(
      'DLNA: transport state: $transportState (current: $state)',
    );
    switch (transportState) {
      case 'PLAYING':
        if (state != SessionState.playing &&
            stateMachine.canTransitionTo(SessionState.playing)) {
          stateMachine.transitionTo(SessionState.playing);
        }
        // Execute deferred seek now that the TV has loaded and is playing.
        if (_pendingSeekPosition != null) {
          final pos = _pendingSeekPosition!;
          _pendingSeekPosition = null;
          CastLogger.info('DLNA: executing deferred seek to ${pos.inSeconds}s');
          seek(pos);
        }
        break;
      case 'PAUSED_PLAYBACK':
        if (state != SessionState.paused &&
            stateMachine.canTransitionTo(SessionState.paused)) {
          stateMachine.transitionTo(SessionState.paused);
        }
        break;
      case 'STOPPED':
        // The renderer briefly reports STOPPED while it swaps the transport
        // URI for a live restart. Treating that as idle would look like
        // playback completion to the app (which can auto-advance the queue)
        // and would also stop polling for the new stream.
        if (_restartInFlight || _isLoadingMedia) {
          CastLogger.debug(
            'DLNA: ignoring transient STOPPED during a load/restart',
          );
          break;
        }
        CastLogger.info('DLNA: device reported STOPPED, transitioning to idle');
        if (state != SessionState.idle &&
            stateMachine.canTransitionTo(SessionState.idle)) {
          stateMachine.transitionTo(SessionState.idle);
          _stopPolling();
        }
        break;
    }
  }
}
