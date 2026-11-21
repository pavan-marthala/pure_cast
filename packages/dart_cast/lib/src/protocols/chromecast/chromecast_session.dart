/// ChromecastSession — full lifecycle management for Chromecast casting.
///
/// Extends [CastSession] to manage TLS connection, receiver/media channels,
/// heartbeat keep-alive, media proxy, and playback state synchronisation.
library;

import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/cast_device.dart';
import '../../core/cast_exceptions.dart';
import '../../core/cast_media.dart';
import '../../core/media_probe.dart';
import '../../core/cast_decision.dart';
import '../../core/live_mkv_stream.dart';
import '../../core/direct_attempt_policy.dart';
import '../../core/cast_prepare_session.dart';
import '../../core/cast_ffmpeg_commands.dart';
import '../../core/media_prober.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import '../../core/cast_session.dart';
import '../../core/media_proxy.dart';
import '../../core/media_transformer.dart';
import '../../core/ts_hls_media_transformer.dart';
import '../../core/webvtt_time_shifter.dart';
import '../../utils/logger.dart';
import 'cast_media_channel.dart';
import 'cast_receiver_channel.dart';
import 'castv2_channel.dart';
import 'proto/cast_channel.dart';

/// Strategy used for a single LOAD attempt against the Chromecast.
///
/// Iterated by [ChromecastSession._loadMediaInternal] as a bisect-style
/// retry: the leanest variant is tried first, and if the receiver rejects
/// it the alt-audio muxer + DVB-table stripper variant is tried as the
/// fallback.
enum _LoadMode {
  /// `registerMedia` pass-through with DVB stripper disabled and no
  /// alt-audio muxer. This is the leanest variant.
  bare('bare (no muxer, no DVB stripper)'),

  /// `registerAltAudioMuxed` (with `registerMedia` fallback if the
  /// source has no alt-audio) and the DVB stripper enabled on TS
  /// segments. This is the fallback for sources that need either piece.
  muxed('muxed alt-audio + DVB stripper');

  const _LoadMode(this.label);
  final String label;
}

/// A casting session with a Chromecast device.
///
/// Manages the full lifecycle: TLS connect, receiver LAUNCH, heartbeat,
/// media LOAD/PLAY/PAUSE/STOP/SEEK, and graceful disconnect.
class ChromecastSession extends CastSession {
  /// The sender ID used in all messages.
  static const _senderId = 'sender-0';

  /// The platform receiver destination ID.
  static const _receiverId = 'receiver-0';

  // ---------------------------------------------------------------------------
  // Dependencies (injectable for testing)
  // ---------------------------------------------------------------------------

  final _ChannelAdapter _channel;
  final MediaProxy _proxy;
  final MediaTransformer _mediaTransformer;

  // ---------------------------------------------------------------------------
  // Session state
  // ---------------------------------------------------------------------------

  final CastReceiverChannel _receiverChannel = CastReceiverChannel();
  final CastMediaChannel _mediaChannel = CastMediaChannel();

  String? _transportId;
  String? _sessionId; // Used for STOP app via receiver namespace.
  int? _mediaSessionId;

  /// Fingerprint of the last logged MEDIA_STATUS, used to elide the payload
  /// of unchanged 1 Hz poll answers from the debug log.
  String? _lastMediaStatusFingerprint;
  StreamSubscription<dynamic>? _mediaStatusSubscription;

  /// Periodic timer that polls GET_STATUS on the media channel to keep
  /// the playback position up-to-date. Chromecast only pushes MEDIA_STATUS
  /// on state changes (play, pause, load) — it does NOT send periodic
  /// position updates on its own.
  Timer? _positionPollTimer;

  /// Guard to prevent overlapping GET_STATUS requests.
  bool _isPolling = false;

  /// Guard to prevent concurrent [loadMedia] calls from sending multiple LOADs.
  bool _isLoadingMedia = false;

  /// Tracks the trackId assigned to each subtitle during the current
  /// LOAD, keyed by the subtitle's upstream URL. `setSubtitle` looks up
  /// the active subtitle here to send the correct `EDIT_TRACKS_INFO`
  /// trackId — without this we'd always activate trackId=1, so any
  /// subtitle switch in the UI after LOAD would silently re-select
  /// the first subtitle on the TV.
  final Map<String, int> _subtitleTrackIds = <String, int>{};

  /// The track ids currently meant to be active on the receiver.
  ///
  /// Seeded at LOAD from [CastMedia.defaultSubtitle] and rewritten by
  /// [setSubtitle]. This is the sender's record, deliberately not mirrored
  /// from MEDIA_STATUS: the receiver never changes tracks on its own, and
  /// [_reassertActiveTracks] needs the *intended* set even at the moment
  /// the receiver has stopped honouring it.
  List<int> _activeTrackIds = const [];

  /// MediaSession IDs we've explicitly abandoned during a retry chain.
  ///
  /// When the bisect loop falls through from one attempt to the next, the
  /// failed attempt's receiver-side session is now stale — any late
  /// MEDIA_STATUS broadcasts still carrying its session id (commonly the
  /// IDLE+ERROR settle-down message arriving a few hundred ms after
  /// LOAD_FAILED) would otherwise be processed by [_handleMessage] and
  /// drag the state machine backwards while the new attempt is mid-flight.
  /// Recording the abandoned session id here lets [_handleMessage] drop
  /// those late strays without affecting the live session.
  final Set<int> _deprecatedMediaSessionIds = <int>{};

  /// Live MKV runs owned by this session (one per HTTP request).
  final LiveMkvRunManager _liveRuns;

  /// Stops the HLS [CastPrepareSession] and deletes its temp dir.
  Future<void> Function()? _stopPrepare;

  /// Test seam: replaces the FFprobeKit probe inside [loadLocalFile].
  final Future<MediaProbe> Function(String input)? _probeFile;

  /// Probes local files before casting; replaced in tests via [probeFile].
  final MediaProber _prober;

  /// Test seam: replaces [CastPrepareSession.start].
  final Future<CastPrepareSession> Function({
    required String inputPath,
    required List<String> Function(String outputDir) buildArgs,
  })?
  _prepareStarter;

  /// Token of the currently registered `/live/<token>` stream, if any.
  String? _liveToken;

  /// Source position where the current live stream was restarted.
  Duration _liveStartOffset = Duration.zero;

  /// True while the current media is served by the live MKV path.
  bool _isLive = false;

  /// Source file of the current live stream.
  String? _liveFilePath;

  /// Audio index (`0:a:N`) currently used by the live stream.
  int _liveAudioIndex = 0;

  /// Audio tracks discovered by the probe that started the live stream.
  List<AudioStream> _liveAudioTracks = const [];

  /// Known duration of the live source, when the probe reported one.
  Duration? _liveDuration;

  /// LOAD `streamType` used for the current live stream (kept for restarts).
  String _liveStreamType = 'LIVE';

  /// Caller-supplied full-timeline WebVTT source for the live subtitle.
  ///
  /// This is always the ORIGINAL subtitle file. The file served to the
  /// receiver is a time-shifted copy regenerated from this source on every
  /// live (re)start, never from a previous copy.
  CastSubtitle? _liveSubtitle;

  /// Path of the shifted VTT file currently registered with the proxy.
  ///
  /// At most one such file exists at a time; it is replaced on every restart
  /// and deleted on teardown.
  String? _shiftedLiveSubtitlePath;

  /// Test seam: directory that holds the shifted live subtitle files.
  ///
  /// When null, a `cast_live_sub_` directory is created under the platform
  /// temporary directory, mirroring [CastPrepareSession]'s temp handling.
  final Directory? _liveSubtitleTempDir;

  /// Disambiguates shifted file names created within the same microsecond.
  static int _shiftedSubtitleSequence = 0;

  /// True while [loadLocalFile] hands its freshly prepared HLS dir to
  /// [loadMedia]; prevents the new-load cleanup from deleting it.
  bool _prepareHandedToLoad = false;

  /// Guards [switchLiveAudio] so two restarts cannot interleave.
  bool _switchingLiveAudio = false;

  /// When `true`, [connect] additionally subscribes to the Default Media
  /// Receiver's auxiliary debug namespaces (`com.google.cast.cac` +
  /// `com.google.cast.debugoverlay`) and the receiver-message firehose
  /// is logged at info level instead of debug.
  ///
  /// Off by default — these subscribes add a couple of extra CONNECT
  /// messages on every cast session and the firehose can be very loud
  /// during playback (every MEDIA_STATUS, every queue update, …). Flip
  /// it on when debugging LOAD_FAILED or unexpected receiver behaviour;
  /// leave it off in normal use.
  final bool enableReceiverDebugNamespaces;

  /// The current receiver session ID, if connected.
  String? get sessionId => _sessionId;
  MediaProxy get proxy => _proxy;

  /// Source offset of the current live stream (0 unless the stream was
  /// restarted with [switchLiveAudio] or a live [seek]).
  ///
  /// The restarted stream's receiver time starts at 0, so the real position
  /// is `liveStartOffset + position`.
  @override
  Duration get liveStartOffset => _liveStartOffset;

  /// Whether the current media is served by the live MKV path.
  @override
  bool get isLive => _isLive;

  /// Source file backing the current live stream, if any.
  @override
  String? get liveFilePath => _liveFilePath;

  /// Audio index (`0:a:N`, 0-based among audio streams) in use right now.
  @override
  int get liveAudioIndex => _liveAudioIndex;

  /// Audio tracks found by the probe when the live stream was started.
  @override
  List<AudioStream> get liveAudioTracks => _liveAudioTracks;

  /// Known duration of the live source (null when the probe had none).
  @override
  Duration? get liveDuration => _liveDuration;

  /// Subtitle source attached to the live stream, if any.
  ///
  /// This is the caller-supplied full-timeline WebVTT. The time-shifted copy
  /// that the receiver actually fetches is regenerated internally for each
  /// live (re)start. Null when no live subtitles are attached.
  CastSubtitle? get liveSubtitle => _liveSubtitle;

  @override
  int? get mediaSessionId => _mediaSessionId;

  @override
  int get liveSessionToken => _mediaSessionId ?? 0;
  Timer? _heartbeatTimer;
  StreamSubscription<dynamic>? _messageSubscription;

  /// Whether the heartbeat timer is currently active.
  bool get isHeartbeatActive => _heartbeatTimer?.isActive ?? false;

  /// Whether the position polling timer is currently active.
  bool get isPositionPollingActive => _positionPollTimer?.isActive ?? false;

  // ---------------------------------------------------------------------------
  // Constructors
  // ---------------------------------------------------------------------------

  /// Creates a [ChromecastSession] for the given [device].
  ///
  /// An optional [mediaTransformer] can be provided to customize how media
  /// is prepared before casting (e.g., custom segmentation, transcoding).
  /// Defaults to [TsHlsMediaTransformer] which wraps TS in HLS.
  ///
  /// [prober] overrides media probing; defaults to [FfprobeMediaProber].
  ///
  /// [liveSubtitleTempDir] overrides where shifted live-subtitle files are
  /// written; tests inject a temporary directory. When null, a
  /// `cast_live_sub_` directory under the platform temp directory is used.
  ChromecastSession({
    required CastDevice device,
    MediaTransformer? mediaTransformer,
    MediaProber? prober,
    Directory? liveSubtitleTempDir,
    this.enableReceiverDebugNamespaces = false,
  }) : _channel = _RealChannelAdapter(),
       _proxy = MediaProxy(),
       _liveRuns = LiveMkvRunManager.production(),
       _probeFile = null,
       _prober = prober ?? const FfprobeMediaProber(),
       _prepareStarter = null,
       _liveSubtitleTempDir = liveSubtitleTempDir,
       _mediaTransformer =
           mediaTransformer ?? const TsHlsMediaTransformer(wrapRemoteTs: true),
       super(device);

  /// Creates a [ChromecastSession] with mock dependencies for testing.
  ///
  /// [channel] is a mock for the TLS channel (required for unit/integration
  /// tests that avoid real TLS connections).
  /// [proxy] is an optional [MediaProxy] instance; a real [MediaProxy] is
  /// created if not provided.
  /// [mediaTransformer] is an optional transformer; defaults to
  /// [TsHlsMediaTransformer].
  /// [liveRuns] and [prepareStopper] are test seams for the live MKV and HLS
  /// prepare lifecycles; production code uses the defaults.
  /// [probeFile] and [prepareStarter] are test seams for the probe and
  /// prepare session used by [loadLocalFile].
  /// [prober] overrides media probing when [probeFile] is not provided.
  /// [liveSubtitleTempDir] overrides where shifted live-subtitle files are
  /// written; when null a `cast_live_sub_` directory under the platform temp
  /// directory is used.
  ChromecastSession.withMocks({
    required CastDevice device,
    required dynamic channel,
    MediaProxy? proxy,
    MediaTransformer? mediaTransformer,
    LiveMkvRunManager? liveRuns,
    Future<void> Function()? prepareStopper,
    Future<MediaProbe> Function(String input)? probeFile,
    MediaProber? prober,
    Future<CastPrepareSession> Function({
      required String inputPath,
      required List<String> Function(String outputDir) buildArgs,
    })?
    prepareStarter,
    Directory? liveSubtitleTempDir,
    this.enableReceiverDebugNamespaces = false,
  }) : _channel = _MockChannelAdapter(channel),
       _proxy = proxy ?? MediaProxy(),
       _liveRuns = liveRuns ?? LiveMkvRunManager.production(),
       _stopPrepare = prepareStopper,
       _probeFile = probeFile,
       _prober = prober ?? const FfprobeMediaProber(),
       _prepareStarter = prepareStarter,
       _liveSubtitleTempDir = liveSubtitleTempDir,
       _mediaTransformer =
           mediaTransformer ?? const TsHlsMediaTransformer(wrapRemoteTs: true),
       super(device);

  // ---------------------------------------------------------------------------
  // Connect lifecycle
  // ---------------------------------------------------------------------------

  /// Connects to the Chromecast device and launches the Default Media Receiver.
  ///
  /// Sequence: TLS connect -> CONNECT to receiver-0 -> start heartbeat ->
  /// LAUNCH CC1AD845 -> wait for RECEIVER_STATUS -> extract transportId ->
  /// CONNECT to transportId.
  @override
  Future<void> connect() async {
    CastLogger.info(
      'Chromecast: connecting to ${device.name} at ${device.address.address}:${device.port}',
    );
    stateMachine.transitionTo(SessionState.connecting);

    // 1. TLS connect
    await _channel.connect(device.address.address, port: device.port);

    // 2. Start listening for messages
    final completer = Completer<void>();
    _messageSubscription = _channel.messageStream.listen(
      (msg) {
        _handleMessage(msg, completer);
      },
      onError: (Object error) {
        CastLogger.error('Chromecast: message stream error: $error');
        _onSocketLost();
      },
      onDone: () {
        CastLogger.warning('Chromecast: message stream closed unexpectedly');
        _onSocketLost();
      },
    );

    // 3. CONNECT to receiver-0
    _channel.sendMessage(
      namespace: CastReceiverChannel.connectionNamespace,
      sourceId: _senderId,
      destinationId: _receiverId,
      payload: CastReceiverChannel.buildConnect(),
    );

    // 4. Start heartbeat
    _startHeartbeat();

    // 5. LAUNCH Default Media Receiver
    _channel.sendMessage(
      namespace: CastReceiverChannel.receiverNamespace,
      sourceId: _senderId,
      destinationId: _receiverId,
      payload: _receiverChannel.buildLaunchWithId(),
    );

    // 6. Wait for RECEIVER_STATUS with transportId
    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        CastLogger.error('Chromecast: connect timed out after 15s');
        stateMachine.transitionTo(SessionState.disconnected);
        throw TimeoutException('Chromecast connect timed out after 15 seconds');
      },
    );

    // 7. CONNECT to app transportId
    _channel.sendMessage(
      namespace: CastReceiverChannel.connectionNamespace,
      sourceId: _senderId,
      destinationId: _transportId!,
      payload: CastReceiverChannel.buildConnect(),
    );

    // 8. Opt-in: subscribe to receiver debug + CaC namespaces so any
    //    receiver-side LOAD_FAILED diagnostic surfaces in our message
    //    firehose (same data CaC Tool would render). Off by default —
    //    enable via [enableReceiverDebugNamespaces] when debugging.
    if (enableReceiverDebugNamespaces) {
      _subscribeReceiverDebugNamespaces();
    }

    CastLogger.info(
      'Chromecast: connected to ${device.name}, transportId=$_transportId',
    );
    stateMachine.transitionTo(SessionState.connected);
  }

  /// Subscribes (CONNECT) to the Default Media Receiver's auxiliary
  /// namespaces `urn:x-cast:com.google.cast.cac` and
  /// `urn:x-cast:com.google.cast.debugoverlay` so any messages the
  /// receiver chooses to publish there land in our message firehose.
  ///
  /// Cast V2 requires a sender to send a `CONNECT` on each namespace
  /// before the receiver routes traffic on it — otherwise events are
  /// silently dropped. The CONNECTs are cheap and harmless even when
  /// the receiver never emits on these namespaces; their value is the
  /// odd diagnostic line that does show up.
  void _subscribeReceiverDebugNamespaces() {
    if (_transportId == null) return;
    for (final ns in const [
      CastReceiverChannel.cacNamespace,
      CastReceiverChannel.debugOverlayNamespace,
    ]) {
      try {
        _channel.sendMessage(
          namespace: ns,
          sourceId: _senderId,
          destinationId: _transportId!,
          payload: CastReceiverChannel.buildConnect(),
        );
      } catch (_) {
        // Best-effort — failures here never block playback.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Media loading
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadMedia(
    CastMedia media, {
    String? contentType,
    String? streamType,
    Duration? duration,
    bool bypassTransform = false,
  }) async {
    // Release live runs from a previous load, and the previous HLS prepare
    // session unless this call is the prepared load itself.
    await _liveRuns.closeAll();
    if (!_prepareHandedToLoad) {
      await _stopPrepareSession();
    }
    // A load that is not the current live stream leaves the live path, so
    // drop stale live metadata. Live LOAD/restarts carry the token they just
    // registered, so their metadata survives.
    final mediaPath = Uri.tryParse(media.url)?.pathSegments ?? const <String>[];
    final isCurrentLiveLoad =
        _liveToken != null &&
        mediaPath.isNotEmpty &&
        mediaPath.last == _liveToken;
    if (!isCurrentLiveLoad) _resetLiveMetadata();
    if (_transportId == null) {
      throw StateError('Not connected. Call connect() first.');
    }

    if (_isLoadingMedia) {
      CastLogger.warning(
        'Chromecast: loadMedia called while already loading — ignoring',
      );
      return;
    }
    _isLoadingMedia = true;

    try {
      await _loadMediaInternal(
        media,
        bypassTransform: bypassTransform,
        streamType: streamType,
        duration: duration,
      );
    } finally {
      _isLoadingMedia = false;
    }
  }

  /// Loads a local file, probing and preparing it first.
  @override
  Future<void> loadLocalFile(
    String path, {
    int audioStreamIndex = 0,
    CastDeviceCaps caps = const CastDeviceCaps(),
    CastSubtitle? subtitle,
    String streamType = 'BUFFERED',
    Future<bool?> Function(String receiverId, String codecKey)? memoryLookup,
    Future<void> Function(String receiverId, String codecKey, bool directOk)?
    memoryRecord,
  }) async {
    // A new load replaces any live runs / previous prepared HLS dir.
    await _cleanupCastResources();
    _releaseLiveToken();
    // Probe failure must not leave the previous live stream's metadata behind.
    _resetLiveMetadata();
    // Probe (with fallback)
    String input = path;
    if (input.startsWith('content://')) {
      final saf = await FFmpegKitConfig.getSafParameterForRead(input);
      if (saf != null) input = saf;
    } else if (input.startsWith('file://')) {
      input = Uri.parse(input).toFilePath();
    }
    MediaProbe? probe;
    late CastPlan plan;
    try {
      final probeFile = _probeFile;
      if (probeFile != null) {
        probe = await probeFile(input);
      } else {
        probe = await _prober.probe(input);
      }
      plan = decide(probe, caps);
    } on ProbeFailedException {
      rethrow;
    } catch (e) {
      throw ProbeFailedException('Probe failed: $e', e);
    }
    final audioIdx =
        audioStreamIndex == 0
            ? _defaultAudioIndex(probe.audio)
            : audioStreamIndex;

    if (plan is DirectPlan || plan is UncertainDirectPlan) {
      final codec = probe.video?.codec ?? 'video';
      final depth = bitDepthOf(probe.video?.pixFmt);
      final depthStr = depth >= 10 ? '$depth-bit' : '8-bit';
      final memKey = '${device.metadata['md'] ?? device.id}_${codec}_$depthStr';
      // Check receiver memory before attempting direct playback.
      bool? memResult;
      if (memoryLookup != null) {
        try {
          memResult = await memoryLookup(device.id, memKey);
        } catch (_) {
          memResult = null; // unknown on lookup failure
        }
      }
      if (memResult == false) {
        // Known to fail on this receiver — skip direct, go to fallback/transcode.
        if (plan is UncertainDirectPlan &&
            (caps.hasH264Encoder || caps.hasH264Mediacodec) &&
            caps.transcodeEnabled) {
          // fall through to prepare path
        } else {
          throw UnsupportedMediaException(
            'This Chromecast can\'t play this video ($codec $depthStr)',
          );
        }
      } else {
        // Unknown or supported: attempt direct playback.
        try {
          await loadMedia(
            CastMedia.file(
              filePath: path,
              type: CastCompat.mediaTypeForContainer(probe.container),
              subtitles: subtitle != null ? [subtitle] : const [],
              defaultSubtitle: subtitle,
            ),
          );
          // Record positive result.
          if (memoryRecord != null) {
            try {
              await memoryRecord(device.id, memKey, true);
            } catch (_) {}
          }
          return;
        } catch (e) {
          final isMediaLoadFailed = e is MediaLoadFailedException;
          if (DirectAttemptPolicy.shouldRecordDirectFailed(
            isMediaLoadFailed: isMediaLoadFailed,
            codec: codec,
            hasSubtitle: subtitle != null,
            isDirectAttempt: true,
          )) {
            if (memoryRecord != null) {
              try {
                await memoryRecord(device.id, memKey, false);
              } catch (_) {}
            }
          }
          if (plan is UncertainDirectPlan &&
              (caps.hasH264Mediacodec || caps.hasLibx264) &&
              caps.transcodeEnabled) {
            // fall through to prepare path
          } else {
            throw UnsupportedMediaException(
              'This Chromecast can\'t play this video ($codec $depthStr)',
            );
          }
        }
      }
    }
    if (plan is UnsupportedPlan) {
      final codec = probe.video?.codec ?? 'video';
      final depth = bitDepthOf(probe.video?.pixFmt);
      final depthStr = depth >= 10 ? '$depth-bit' : '8-bit';
      final isAv1 = (probe.video?.codec.toLowerCase() == 'av1');
      bool tryDirect = !(isAv1 || depth >= 10);
      final memKey = '${device.metadata['md'] ?? device.id}_${codec}_$depthStr';
      if (memoryLookup != null) {
        try {
          final memResult = await memoryLookup(device.id, memKey);
          if (memResult == false) {
            tryDirect = false;
          }
        } catch (_) {}
      }
      if (tryDirect) {
        try {
          await loadMedia(
            CastMedia.file(
              filePath: path,
              type: CastCompat.mediaTypeForContainer(probe.container),
              subtitles: subtitle != null ? [subtitle] : const [],
              defaultSubtitle: subtitle,
            ),
          );
          if (memoryRecord != null) {
            try {
              await memoryRecord(device.id, memKey, true);
            } catch (_) {}
          }
          return;
        } catch (e) {
          final isMediaLoadFailed = e is MediaLoadFailedException;
          if (DirectAttemptPolicy.shouldRecordDirectFailed(
            isMediaLoadFailed: isMediaLoadFailed,
            codec: codec,
            hasSubtitle: subtitle != null,
            isDirectAttempt: true,
          )) {
            if (memoryRecord != null) {
              try {
                await memoryRecord(device.id, memKey, false);
              } catch (_) {}
            }
          }
          throw UnsupportedMediaException(
            'This Chromecast can\'t play this video ($codec $depthStr)',
          );
        }
      }
      throw UnsupportedMediaException('Unsupported: ${plan.reason}');
    }

    // Remux plans always go to the live MKV path. Routing happens before the
    // HLS builder so a live failure surfaces to the caller instead of silently
    // falling back to HLS; Direct/UncertainDirect/Transcode/Unsupported plans
    // are untouched.
    final isRemuxPlan = plan is RemuxAudioPlan || plan is RemuxContainerPlan;
    if (isRemuxPlan) {
      final durationSeconds = probe.durationSeconds;
      await loadLiveMkv(
        filePath: path,
        audioIndex: audioIdx,
        streamType: streamType,
        duration:
            durationSeconds != null
                ? Duration(milliseconds: (durationSeconds * 1000).round())
                : null,
        audioTracks: probe.audio,
      );
      return;
    }

    // transcode -> prepare
    List<String> Function(String) builder;
    if (plan is UncertainDirectPlan) {
      if (caps.hasH264Mediacodec) {
        builder =
            (out) => CastFfmpegCommands.transcodeVideoMediacodec(
              input: path,
              outputDir: out,
              audioStreamIndex: (plan as UncertainDirectPlan).audioStreamIndex,
            );
      } else if (caps.hasLibx264) {
        builder =
            (out) => CastFfmpegCommands.transcodeVideo(
              input: path,
              outputDir: out,
              audioStreamIndex: (plan as UncertainDirectPlan).audioStreamIndex,
              videoEncoder: 'libx264',
            );
      } else {
        final codec = probe.video?.codec ?? 'video';
        final depth =
            (probe.video?.pixFmt ?? '').contains('10') ? '10-bit' : '8-bit';
        throw UnsupportedMediaException(
          'This Chromecast can\'t play this video ($codec $depth)',
        );
      }
    } else if (plan is TranscodeVideoPlan) {
      if (caps.hasH264Mediacodec) {
        builder =
            (out) => CastFfmpegCommands.transcodeVideoMediacodec(
              input: path,
              outputDir: out,
              audioStreamIndex: audioIdx,
            );
      } else if (caps.hasLibx264) {
        builder =
            (out) => CastFfmpegCommands.transcodeVideo(
              input: path,
              outputDir: out,
              audioStreamIndex: audioIdx,
              videoEncoder: 'libx264',
            );
      } else {
        throw UnsupportedMediaException('Unsupported: no usable H.264 encoder');
      }
    } else {
      throw UnsupportedMediaException(
        'Plan ${plan.runtimeType} is not supported by the prepare path',
      );
    }

    final args = builder('/tmp/__OUTDIR__');
    if (kDebugMode) {
      debugPrint('[PREPDBG] ffmpeg args: ${args.join(' ')}');
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
    // wait for ready (first 2 segments)
    await prepare.stateStream.firstWhere(
      (s) => s == PrepareState.ready || s == PrepareState.failed,
    );
    if (prepare.state != PrepareState.ready) {
      if (kDebugMode) {
        debugPrint('[PREPDBG] prepare failed: ${prepare.error}');
      }
      // Do not leave the failed prepare's temp dir / ffmpeg session behind.
      await _cleanupCastResources();
      throw PrepareFailedException('Prepare failed: ${prepare.error}');
    }
    // Start the proxy BEFORE registering the HLS directory, because
    // registerHlsDirectory builds the URL from _baseUrl which is only
    // set inside start(). (start is a no-op if already running.)
    await _proxy.start(targetDeviceIp: device.address.address);
    final hlsUrl = _proxy.registerHlsDirectory(
      prepare.sessionId,
      prepare.tempDir.path,
    );
    if (kDebugMode) {
      debugPrint('[HLSDBG] final URL: $hlsUrl');
    }
    // load via proxy url through loadMedia? loadMedia expects CastMedia. Use a remote media with hls url.
    // This prepare session belongs to this load — keep loadMedia's new-load
    // cleanup from deleting the temp dir we just prepared.
    _prepareHandedToLoad = true;
    try {
      await loadMedia(
        CastMedia(
          url: hlsUrl,
          type: CastMediaType.hls,
          subtitles: subtitle != null ? [subtitle] : const [],
          defaultSubtitle: subtitle,
        ),
        contentType: 'application/x-mpegURL',
        bypassTransform: true,
        streamType: streamType,
      );
    } finally {
      _prepareHandedToLoad = false;
    }
  }

  /// Loads a local file as a live MKV stream (no disk buffering).
  ///
  /// [duration] and [audioTracks] let a caller that already probed the file
  /// (notably [loadLocalFile]) hand the probe results in, so no second
  /// FFprobe is needed.
  ///
  /// [subtitle] is a full-timeline WebVTT file (`file://` URI or plain path)
  /// to show over the live stream. It is stored as-is and a time-shifted copy
  /// is served for the current play position; see [liveSubtitle] and
  /// [switchLiveSubtitle].
  Future<void> loadLiveMkv({
    required String filePath,
    required int audioIndex,
    required String streamType,
    Duration? duration,
    List<AudioStream> audioTracks = const [],
    CastSubtitle? subtitle,
  }) async {
    // A new live load replaces any previous live runs / prepared HLS dir.
    await _cleanupCastResources();
    _releaseLiveToken();
    _resetLiveMetadata();
    _liveSubtitle = subtitle;
    await _proxy.start(targetDeviceIp: device.address.address);

    final effectiveDuration = duration;

    await _startLiveStream(
      filePath: filePath,
      audioIndex: audioIndex,
      streamType: streamType,
      duration: effectiveDuration,
      audioTracks: audioTracks,
      sendDurationInLoad: true,
    );
  }

  /// Registers and LOADs one live MKV stream.
  ///
  /// Callers must have closed the previous live run and released its token
  /// already. Live metadata is set before the LOAD so the adapter can map
  /// receiver time onto the virtual timeline while the restart is in flight.
  Future<void> _startLiveStream({
    required String filePath,
    required int audioIndex,
    required String streamType,
    required Duration? duration,
    required List<AudioStream> audioTracks,
    double? startSeconds,
    bool sendDurationInLoad = false,
  }) async {
    _liveFilePath = filePath;
    _liveAudioIndex = audioIndex;
    _liveAudioTracks = List.unmodifiable(audioTracks);
    _liveDuration = duration;
    _liveStreamType = streamType;
    _isLive = true;

    final liveUrl = _proxy.registerLiveStream(
      open:
          () => _liveRuns.open(
            filePath: filePath,
            audioIndex: audioIndex,
            startSeconds: startSeconds,
          ),
      contentType: 'video/x-matroska',
    );
    _liveToken = Uri.parse(liveUrl).pathSegments.last;
    if (kDebugMode) {
      debugPrint('[LIVE] live URL: $liveUrl');
    }

    // The subtitle is always re-derived from the original source for the
    // offset this run starts at (the same value handed to `-ss`). A failure
    // here downgrades the stream to "no subtitles" instead of failing the
    // cast.
    final liveSubtitle = await _preparedLiveSubtitle(startSeconds);

    try {
      await loadMedia(
        CastMedia(
          url: liveUrl,
          type: CastMediaType.mkv,
          title: 'Live MKV',
          subtitles: liveSubtitle != null ? [liveSubtitle] : const [],
          defaultSubtitle: liveSubtitle,
        ),
        contentType: 'video/x-matroska',
        duration: sendDurationInLoad ? duration : null,
        bypassTransform: true,
        streamType: streamType,
      );
    } catch (e) {
      await _liveRuns.closeAll();
      _releaseLiveToken();
      _resetLiveMetadata();
      rethrow;
    }
  }

  /// Closes the current live stream and starts a new one at [position] with
  /// [audioIndex], keeping the current live duration and track list.
  Future<void> _restartLiveStream({
    required String filePath,
    required int audioIndex,
    required Duration position,
    required String streamType,
    Duration? duration,
    List<AudioStream>? audioTracks,
  }) async {
    if (_transportId == null) {
      throw StateError('Not connected. Call connect() first.');
    }
    if (_switchingLiveAudio || _isLoadingMedia) {
      throw StateError('Another cast load is already in progress');
    }
    _switchingLiveAudio = true;
    try {
      debugPrint(
        '[LIVE-SWITCH] restarting audio=$audioIndex '
        'position=${position.inMilliseconds}ms',
      );
      // Callers switching away from a direct (non-live) load must supply the
      // probe metadata: a direct load has already cleared the live duration
      // and track list.
      final effectiveDuration = duration ?? _liveDuration;
      final effectiveAudioTracks = audioTracks ?? _liveAudioTracks;
      // Close old run(s) and release the old URL before registering the new
      // stream. Do not leave the old stream half-closed.
      await _cleanupCastResources();
      _releaseLiveToken();
      _liveStartOffset = position;
      await _proxy.start(targetDeviceIp: device.address.address);
      await _startLiveStream(
        filePath: filePath,
        audioIndex: audioIndex,
        streamType: streamType,
        duration: effectiveDuration,
        audioTracks: effectiveAudioTracks,
        startSeconds: position.inMilliseconds / 1000.0,
      );
      debugPrint(
        '[LIVE-SWITCH] audio=$audioIndex '
        'offset=${position.inMilliseconds}ms loaded',
      );
    } catch (e) {
      // Any failure before _startLiveStream owns the metadata (proxy start,
      // registration) must not leave a half-live session behind.
      await _liveRuns.closeAll();
      _releaseLiveToken();
      _resetLiveMetadata();
      rethrow;
    } finally {
      _switchingLiveAudio = false;
    }
  }

  /// Restarts the live MKV stream with a different audio track, beginning at
  /// [position] in the source file.
  ///
  /// The receiver's clock for the new stream starts at 0, so the real
  /// playback position is [liveStartOffset] + [position].
  ///
  /// [duration] and [audioTracks] describe the source file. They are required
  /// when switching away from a direct (non-live) load, because a direct load
  /// has no live metadata to keep. When omitted, the current live metadata is
  /// preserved (the normal live-to-live switch).
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

  /// Attaches, replaces or clears the subtitle of the current live stream.
  ///
  /// [subtitle] must point at a full-timeline WebVTT file (`file://` URI or
  /// plain path). It is validated *before* anything changes: when it cannot be
  /// read, is not WebVTT, or cannot be shifted for [position], this throws a
  /// [SubtitleAttachException] and the current stream is left untouched. On
  /// success the stream restarts at [position] with a copy of [subtitle]
  /// shifted so receiver time zero matches that source position — the same
  /// restart used by [switchLiveAudio], so the existing in-flight guards apply.
  ///
  /// Passing null clears the subtitle in place: the shifted copy is deleted
  /// and EDIT_TRACKS_INFO deactivates the track. No restart and no new LOAD is
  /// issued.
  ///
  /// Throws a [StateError] when the session is not connected or the current
  /// media is not a live MKV stream.
  @override
  Future<void> switchLiveSubtitle({
    required CastSubtitle? subtitle,
    required Duration position,
  }) async {
    if (_transportId == null) {
      throw StateError('Not connected. Call connect() first.');
    }
    if (!_isLive || _liveFilePath == null) {
      throw StateError('switchLiveSubtitle requires a live MKV stream');
    }

    if (subtitle == null) {
      _liveSubtitle = null;
      await _deleteShiftedLiveSubtitle();
      await setSubtitle(null);
      return;
    }

    await _validateLiveSubtitleSource(subtitle, position);

    _liveSubtitle = subtitle;
    await _restartLiveStream(
      filePath: _liveFilePath!,
      audioIndex: _liveAudioIndex,
      position: position,
      streamType: _liveStreamType,
    );
  }

  /// Validates [subtitle] for [position] without touching live state.
  ///
  /// Reads the source and performs one throw-away shift, so a missing or
  /// malformed file can never leave a half-restarted stream behind. Error
  /// messages deliberately carry no path or URL.
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
      throw SubtitleAttachException(
        'Live subtitle source is not a WebVTT file',
      );
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
  /// [startSeconds] in the source file, or null when there is nothing to
  /// attach.
  ///
  /// Always reads the ORIGINAL source. On failure this logs without the path,
  /// clears [_liveSubtitle] and returns null so the stream still loads — a
  /// subtitle problem must never fail a cast.
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
        'Chromecast: live subtitle could not be prepared; continuing without '
        'subtitles',
      );
      _liveSubtitle = null;
      await _deleteShiftedLiveSubtitle();
      return null;
    }
  }

  /// Writes [content] to a fresh shifted-subtitle file and returns its path.
  ///
  /// The previous shifted file is deleted first, so exactly one exists.
  Future<String> _writeShiftedLiveSubtitle(String content) async {
    await _deleteShiftedLiveSubtitle();
    final dir = await _resolveLiveSubtitleTempDir();
    final path =
        '${dir.path}/cast_live_sub_'
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${_shiftedSubtitleSequence++}.vtt';
    await File(path).writeAsString(content, flush: true);
    _shiftedLiveSubtitlePath = path;
    return path;
  }

  /// Resolves (and creates) the directory that holds shifted subtitle files.
  Future<Directory> _resolveLiveSubtitleTempDir() async {
    final override = _liveSubtitleTempDir;
    final dir =
        override ??
        Directory('${(await getTemporaryDirectory()).path}/cast_live_sub_');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Deletes the current shifted subtitle file. Failures are swallowed.
  Future<void> _deleteShiftedLiveSubtitle() async {
    final path = _shiftedLiveSubtitlePath;
    _shiftedLiveSubtitlePath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover temp file is harmless; never fail teardown over it.
    }
  }

  /// Converts a `file://` URI or plain path to a filesystem path.
  static String _localPathOf(String url) =>
      url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;

  /// Closes every live run (cancelling each by its own session id), stops the
  /// HLS prepare session (which deletes its temp dir) and deletes the current
  /// shifted live-subtitle file. Safe to call repeatedly.
  Future<void> _cleanupCastResources() async {
    await _liveRuns.closeAll();
    await _stopPrepareSession();
    await _deleteShiftedLiveSubtitle();
  }

  /// Stops the HLS prepare session (cancelling its own ffmpeg id and
  /// deleting its temp dir), if one is attached.
  Future<void> _stopPrepareSession() async {
    final stopPrepare = _stopPrepare;
    _stopPrepare = null;
    if (stopPrepare != null) {
      try {
        await stopPrepare();
      } catch (_) {}
    }
  }

  /// Unregisters the currently served `/live/<token>` stream so a late
  /// receiver request cannot start a new run after teardown.
  void _releaseLiveToken() {
    final token = _liveToken;
    _liveToken = null;
    _liveStartOffset = Duration.zero;
    if (token != null) _proxy.unregisterLiveStream(token);
  }

  /// Clears every piece of live state. Called on teardown and whenever a
  /// non-live load replaces the current media.
  ///
  /// Also forgets the live subtitle source and deletes its shifted copy; the
  /// deletion is fire-and-forget because this method is synchronous and is
  /// called from synchronous teardown paths.
  void _resetLiveMetadata() {
    _isLive = false;
    _liveFilePath = null;
    _liveAudioIndex = 0;
    _liveAudioTracks = const [];
    _liveDuration = null;
    _liveStreamType = 'LIVE';
    _liveStartOffset = Duration.zero;
    _liveSubtitle = null;
    unawaited(_deleteShiftedLiveSubtitle());
  }

  int _defaultAudioIndex(List<AudioStream> audio) {
    for (var i = 0; i < audio.length; i++) {
      if (audio[i].isDefault) return i;
    }
    return 0;
  }

  Future<void> _loadMediaInternal(
    CastMedia media, {
    bool bypassTransform = false,
    String? streamType,
    Duration? duration,
  }) async {
    stateMachine.transitionTo(SessionState.loading);

    // Reset the deprecated-session tracker for this fresh LOAD. Anything
    // we accumulate during this load's retry chain is only relevant for
    // the duration of this load — the previous load's failed-attempt ids
    // don't matter anymore.
    _deprecatedMediaSessionIds.clear();

    // Start proxy
    await _proxy.start(targetDeviceIp: device.address.address);

    // Prepared HLS (already served by our own proxy) must NOT go through
    // the remote-HLS bisect path — that path re-registers the URL through
    // the proxy (double-proxy) and applies transformers that corrupt the
    // playlist. Treat it as a direct load instead.
    // Rely ONLY on the explicit bypassTransform flag (no URL heuristic).
    final isPreparedHls = bypassTransform;
    final isRemoteHls =
        media.type == CastMediaType.hls && !media.isLocalFile && !isPreparedHls;

    // Prepared HLS (bypassTransform) — skip the transformer entirely and
    // pass the proxy URL straight to the receiver. The transformer would
    // re-proxy the /hls/... URL (double proxy) and corrupt the playlist.
    if (bypassTransform) {
      await _attemptLoad(
        media: media,
        proxyUrl: media.url,
        effectiveType: media.type,
        attemptLabel: 'prepared-hls',
        duration: duration,
        streamType: streamType ?? 'BUFFERED',
      );
      return;
    }

    // Non-HLS / local media — single attempt, no bisect needed.
    if (!isRemoteHls) {
      final transformed = await _mediaTransformer.transform(media, _proxy);
      await _attemptLoad(
        media: media,
        proxyUrl: transformed.proxyUrl,
        effectiveType: transformed.effectiveType,
        attemptLabel: 'standard',
      );
      return;
    }

    // Remote HLS — two-attempt retry loop:
    //   attempt 1 (BARE) — registerMedia with the DVB-table stripper
    //     and alt-audio muxer both disabled. Pure pass-through, for
    //     sources the receiver can already play unmodified.
    //   attempt 2 (MUXED) — alt-audio muxer + DVB stripper enabled.
    //     Fallback for sources that need either transform.
    //
    // The retry triggers only on MediaLoadFailedException (LOAD_FAILED
    // or 15s timeout). Anything else propagates immediately.
    Object? lastError;
    StackTrace? lastStack;
    for (final mode in const [_LoadMode.bare, _LoadMode.muxed]) {
      // After a failed attempt the receiver may have flipped us to
      // IDLE — get back into LOADING so the next attempt's transitions
      // are valid (idle → loading is allowed; loading → loading is a
      // no-op the state machine ignores).
      if (stateMachine.state != SessionState.loading &&
          stateMachine.canTransitionTo(SessionState.loading)) {
        stateMachine.transitionTo(SessionState.loading);
      }
      try {
        await _attemptHlsLoad(media, mode);
        return;
      } on MediaLoadFailedException catch (e, st) {
        lastError = e;
        lastStack = st;
        CastLogger.warning(
          'Chromecast: LOAD attempt "${mode.label}" failed: $e — '
          'trying next mode',
        );
        // Mark the failed attempt's session id as deprecated so any
        // late MEDIA_STATUS messages still carrying it (notably the
        // IDLE+ERROR broadcast that follows LOAD_FAILED by a few
        // hundred ms) don't pull the state machine back to idle while
        // the next attempt is mid-flight.
        if (_mediaSessionId != null) {
          _deprecatedMediaSessionIds.add(_mediaSessionId!);
          CastLogger.debug(
            'Chromecast: deprecating mediaSessionId=${_mediaSessionId!} '
            'after failed attempt "${mode.label}"',
          );
        }
      }
    }
    if (stateMachine.canTransitionTo(SessionState.idle)) {
      stateMachine.transitionTo(SessionState.idle);
    }
    Error.throwWithStackTrace(lastError!, lastStack!);
  }

  Future<void> _attemptHlsLoad(CastMedia media, _LoadMode mode) async {
    String proxyUrl;
    switch (mode) {
      case _LoadMode.bare:
        proxyUrl = _proxy.registerMedia(
          media.url,
          headers: media.httpHeaders,
          stripDvbTables: false,
        );
        CastLogger.info(
          'Chromecast: LOAD attempt BARE — no muxer, no DVB stripper, '
          'pure pass-through (url=$proxyUrl)',
        );
        break;
      case _LoadMode.muxed:
        final muxedUrl = await _proxy.registerAltAudioMuxed(
          masterUrl: media.url,
          headers: media.httpHeaders,
        );
        if (muxedUrl != null) {
          proxyUrl = muxedUrl;
          CastLogger.info(
            'Chromecast: LOAD attempt MUXED — alt-audio muxer + DVB '
            'stripper enabled (url=$proxyUrl)',
          );
        } else {
          // Source isn't alt-audio — fall back to standard registerMedia
          // but keep the DVB stripper on (still part of "muxed mode").
          proxyUrl = _proxy.registerMedia(
            media.url,
            headers: media.httpHeaders,
          );
          CastLogger.info(
            'Chromecast: LOAD attempt MUXED — source has no alt-audio; '
            'using standard pass-through with DVB stripper '
            '(url=$proxyUrl)',
          );
        }
        break;
    }

    await _attemptLoad(
      media: media,
      proxyUrl: proxyUrl,
      effectiveType: CastMediaType.hls,
      attemptLabel: mode.label,
    );
  }

  Future<void> _attemptLoad({
    required CastMedia media,
    required String proxyUrl,
    required CastMediaType effectiveType,
    required String attemptLabel,
    Duration? duration,
    String streamType = 'BUFFERED',
  }) async {
    // Extract token to keep across cleanup. The token is consistently
    // the second path segment regardless of route shape:
    //   /stream/<token>                 → segments[1] = "<token>"
    //   /stream/<token>/resource.vtt    → segments[1] = "<token>"
    //   /ts-stream/<token>              → segments[1] = "<token>"
    //   /alt-audio/<token>/master.m3u8  → segments[1] = "<token>"
    //   /file/<token>.ext               → segments[1] = "<token>.ext"
    final urlSegments = Uri.parse(proxyUrl).pathSegments;
    final newToken =
        urlSegments.length >= 2 ? urlSegments[1] : urlSegments.last;
    _proxy.cleanupPreviousMedia(excludeToken: newToken);

    final contentType = _contentTypeForMedia(effectiveType);

    CastLogger.info(
      'Chromecast: loading ${media.subtitles.length} subtitle track(s)',
    );
    final subtitles = <CastMediaTrack>[];
    _subtitleTrackIds.clear();
    for (var i = 0; i < media.subtitles.length; i++) {
      final sub = media.subtitles[i];
      final proxySubUrl = _proxy.registerSubtitle(
        sub.url,
        headers: media.httpHeaders,
      );
      final trackId = i + 1;
      _subtitleTrackIds[sub.url] = trackId;
      subtitles.add(
        CastMediaTrack(
          trackId: trackId,
          url: proxySubUrl,
          name: sub.label,
          language: sub.language,
        ),
      );
    }

    // Resolve which track starts active. No default = no subtitle shown;
    // activating subtitles[0] here is exactly the bug this replaces (the
    // track-list order chose the language on the TV).
    int? defaultTrackId;
    if (media.defaultSubtitle != null) {
      defaultTrackId = _subtitleTrackIds[media.defaultSubtitle!.url];
      if (defaultTrackId == null) {
        CastLogger.warning(
          'Chromecast: defaultSubtitle url is not in the subtitle list — '
          'starting with no active track. '
          'url=${media.defaultSubtitle!.url}',
        );
      }
    }
    _activeTrackIds = defaultTrackId != null ? [defaultTrackId] : const [];

    final loadPayload = _mediaChannel.buildLoad(
      contentId: proxyUrl,
      contentType: contentType,
      title: media.title,
      imageUrl: media.imageUrl,
      startPosition:
          media.startPosition != null
              ? media.startPosition!.inMilliseconds / 1000.0
              : null,
      duration: duration != null ? duration.inMilliseconds / 1000.0 : null,
      subtitles: subtitles.isNotEmpty ? subtitles : null,
      activeTrackIds: defaultTrackId != null ? [defaultTrackId] : null,
      streamType: streamType,
    );

    final loadRequestId =
        (jsonDecode(loadPayload) as Map<String, dynamic>)['requestId'] as int;

    CastLogger.info(
      'Chromecast: LOAD contentId=$proxyUrl contentType=$contentType '
      'requestId=$loadRequestId',
    );

    final priorMediaSessionId = _mediaSessionId;

    final completer = Completer<void>();
    _waitForMediaStatus(
      completer,
      expectedRequestId: loadRequestId,
      priorMediaSessionId: priorMediaSessionId,
    );

    final loadSentAt = DateTime.now();
    _channel.sendMessage(
      namespace: CastMediaChannel.mediaNamespace,
      sourceId: _senderId,
      destinationId: _transportId!,
      payload: loadPayload,
    );

    try {
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          final elapsed = DateTime.now().difference(loadSentAt);
          CastLogger.error(
            'Chromecast: loadMedia timed out after ${elapsed.inMilliseconds}ms '
            '(no playable MEDIA_STATUS received from receiver, '
            'attempt=$attemptLabel)',
          );
          _mediaStatusSubscription?.cancel();
          _mediaStatusSubscription = null;
          throw MediaLoadFailedException(
            'Chromecast loadMedia timed out after 15 seconds — '
            'receiver never reported a playable state (attempt=$attemptLabel)',
          );
        },
      );
      final elapsed = DateTime.now().difference(loadSentAt);
      CastLogger.info(
        'Chromecast: LOAD acknowledged + playable in '
        '${elapsed.inMilliseconds}ms (attempt=$attemptLabel)',
      );
    } on MediaLoadFailedException {
      // Let the bisect loop decide whether to retry — only flip to
      // `idle` once we run out of attempts.
      rethrow;
    } catch (e) {
      if (stateMachine.canTransitionTo(SessionState.idle)) {
        stateMachine.transitionTo(SessionState.idle);
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Playback controls
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async {
    _requireMediaSession();
    CastLogger.info('Chromecast: PLAY');
    _sendMediaCommand(_mediaChannel.buildPlay(_mediaSessionId!));
  }

  @override
  Future<void> pause() async {
    _requireMediaSession();
    CastLogger.info('Chromecast: PAUSE');
    _sendMediaCommand(_mediaChannel.buildPause(_mediaSessionId!));
  }

  @override
  Future<void> stop() async {
    // Release live ffmpeg runs and the prepared HLS temp dir even if the
    // media session is already gone.
    await _cleanupCastResources();
    _releaseLiveToken();
    _resetLiveMetadata();
    _requireMediaSession();
    CastLogger.info('Chromecast: STOP');
    _stopPositionPolling();
    _sendMediaCommand(_mediaChannel.buildStop(_mediaSessionId!));
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isLive) {
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
      CastLogger.info(
        'Chromecast: LIVE SEEK (restart) to '
        '${(target.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
      );
      await _restartLiveStream(
        filePath: filePath,
        audioIndex: _liveAudioIndex,
        position: target,
        streamType: _liveStreamType,
      );
      return;
    }
    _requireMediaSession();
    final seconds = position.inMilliseconds / 1000.0;
    CastLogger.info(
      'Chromecast: SEEK to ${seconds.toStringAsFixed(1)}s '
      '(${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')})',
    );
    _sendMediaCommand(_mediaChannel.buildSeek(_mediaSessionId!, seconds));
  }

  @override
  Future<void> setVolume(double volume) async {
    _requireMediaSession();
    CastLogger.info('Chromecast: SET_VOLUME ${volume.toStringAsFixed(2)}');
    // Device-level volume uses receiver namespace to receiver-0.
    // The device responds with RECEIVER_STATUS containing the actual volume,
    // which is handled in _handleMessage() to update the volume stream.
    _channel.sendMessage(
      namespace: CastReceiverChannel.receiverNamespace,
      sourceId: _senderId,
      destinationId: _receiverId,
      payload: _receiverChannel.buildSetVolumeWithId(level: volume),
    );
  }

  @override
  Future<void> setSubtitle(CastSubtitle? subtitle) async {
    _requireMediaSession();
    if (subtitle == null) {
      CastLogger.info('Chromecast: EDIT_TRACKS_INFO disable subtitles');
      _activeTrackIds = const [];
      _sendMediaCommand(
        _mediaChannel.buildEditTracksInfo(_mediaSessionId!, []),
      );
      return;
    }

    // Look up the trackId assigned at LOAD time. Without this map we'd
    // always activate trackId=1, so switching subtitles from the UI
    // would silently re-select the first track on the TV.
    final trackId = _subtitleTrackIds[subtitle.url];
    if (trackId == null) {
      CastLogger.warning(
        'Chromecast: setSubtitle called with subtitle whose URL is not '
        'in the loaded track list — falling back to trackId=1. '
        'url=${subtitle.url}, '
        'known=${_subtitleTrackIds.keys.take(4).join(", ")}'
        '${_subtitleTrackIds.length > 4 ? ", …" : ""}',
      );
      _activeTrackIds = const [1];
      _sendMediaCommand(
        _mediaChannel.buildEditTracksInfo(_mediaSessionId!, [1]),
      );
      return;
    }
    CastLogger.info(
      'Chromecast: EDIT_TRACKS_INFO activate trackId=$trackId '
      '(label="${subtitle.label}", lang=${subtitle.language})',
    );
    _activeTrackIds = [trackId];
    _sendMediaCommand(
      _mediaChannel.buildEditTracksInfo(_mediaSessionId!, [trackId]),
    );
  }

  /// Re-applies [_activeTrackIds] after a pause → resume transition.
  ///
  /// The Default Media Receiver can stop *rendering* subtitle cues after a
  /// pause/resume cycle (TV-remote pause included) while MEDIA_STATUS keeps
  /// reporting the track as active — so the sender's state looks perfectly
  /// healthy while the screen shows nothing. Changing the active track via
  /// EDIT_TRACKS_INFO re-attaches the cue renderer, which is exactly how
  /// users fix it by hand. A plain re-send of the same set risks being
  /// diffed away as a no-op, so this toggles: deactivate, then reactivate.
  /// Cues are fetched once at LOAD and cached receiver-side — the toggle
  /// costs two small messages, no network.
  void _reassertActiveTracks() {
    final sessionId = _mediaSessionId;
    if (sessionId == null || _activeTrackIds.isEmpty) return;
    CastLogger.info(
      'Chromecast: re-asserting active tracks $_activeTrackIds after resume',
    );
    _sendMediaCommand(_mediaChannel.buildEditTracksInfo(sessionId, []));
    _sendMediaCommand(
      _mediaChannel.buildEditTracksInfo(sessionId, _activeTrackIds),
    );
  }

  // ---------------------------------------------------------------------------
  // Disconnect
  // ---------------------------------------------------------------------------

  @override
  Future<void> disconnect() async {
    CastLogger.info('Chromecast: disconnecting from ${device.name}');
    _stopHeartbeat();
    _stopPositionPolling();
    _mediaStatusSubscription?.cancel();
    _mediaStatusSubscription = null;

    // Send CLOSE messages (fire-and-forget — don't wait for response)
    try {
      if (_transportId != null) {
        _channel.sendMessage(
          namespace: CastReceiverChannel.connectionNamespace,
          sourceId: _senderId,
          destinationId: _transportId!,
          payload: CastReceiverChannel.buildClose(),
        );
      }
      _channel.sendMessage(
        namespace: CastReceiverChannel.connectionNamespace,
        sourceId: _senderId,
        destinationId: _receiverId,
        payload: CastReceiverChannel.buildClose(),
      );
    } catch (e) {
      CastLogger.warning('Chromecast: error sending CLOSE messages: $e');
    }

    // Transition state immediately so the UI responds. This must happen before
    // the live-resource teardown: that teardown can block on FFmpeg and would
    // otherwise leave the UI (and CastService.connect) waiting while the
    // previous session keeps the receiver playing.
    _transportId = null;
    _sessionId = null;
    _mediaSessionId = null;
    stateMachine.transitionTo(SessionState.disconnected);
    _releaseLiveToken();
    _resetLiveMetadata();
    try {
      // Close all live runs and stop the HLS prepare session, but never let a
      // stuck FFmpeg job hang the disconnect.
      await _cleanupCastResources().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      CastLogger.warning(
        'Chromecast: live cleanup timed out during disconnect',
      );
    } catch (e) {
      CastLogger.warning(
        'Chromecast: live cleanup error during disconnect: $e',
      );
    }

    // Clean up socket and proxy with a timeout so we don't hang
    try {
      await Future.wait([
        _messageSubscription?.cancel() ?? Future.value(),
        _channel.close(),
        _proxy.stop(),
      ]).timeout(const Duration(seconds: 3), onTimeout: () => []);
    } catch (e) {
      CastLogger.warning('Chromecast: cleanup error during disconnect: $e');
    }
    _messageSubscription = null;
    CastLogger.info('Chromecast: disconnected from ${device.name}');
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _stopPositionPolling();
    _mediaStatusSubscription?.cancel();
    unawaited(_cleanupCastResources());
    _releaseLiveToken();
    _resetLiveMetadata();
    unawaited(_proxy.stop());
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _requireMediaSession() {
    if (_mediaSessionId == null) {
      throw StateError('No active media session. Call loadMedia() first.');
    }
  }

  /// Called when the TLS socket drops unexpectedly (stream error or done).
  /// Cleans up timers and transitions to disconnected so the UI can react.
  void _onSocketLost() {
    if (stateMachine.state == SessionState.disconnected) return;
    CastLogger.warning(
      'Chromecast: socket lost, transitioning to disconnected',
    );
    _stopHeartbeat();
    _stopPositionPolling();
    _mediaStatusSubscription?.cancel();
    _mediaStatusSubscription = null;
    _transportId = null;
    _sessionId = null;
    _mediaSessionId = null;
    _isLoadingMedia = false;
    unawaited(_cleanupCastResources());
    _releaseLiveToken();
    _resetLiveMetadata();
    stateMachine.transitionTo(SessionState.disconnected);
  }

  void _sendMediaCommand(String payload) {
    _channel.sendMessage(
      namespace: CastMediaChannel.mediaNamespace,
      sourceId: _senderId,
      destinationId: _transportId!,
      payload: payload,
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _channel.sendMessage(
        namespace: CastReceiverChannel.heartbeatNamespace,
        sourceId: _senderId,
        destinationId: _receiverId,
        payload: CastReceiverChannel.buildPing(),
      );
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Starts a 1-second periodic timer that sends GET_STATUS on the media
  /// channel. The response triggers [_handleMediaStatus] which updates
  /// position, duration, and state.
  void _startPositionPolling() {
    _stopPositionPolling();
    _positionPollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPolling || _mediaSessionId == null || _transportId == null) {
        return;
      }
      _isPolling = true;
      _sendMediaCommand(_mediaChannel.buildGetStatus());
      _isPolling = false;
    });
  }

  /// Stops the position polling timer.
  void _stopPositionPolling() {
    _positionPollTimer?.cancel();
    _positionPollTimer = null;
    _isPolling = false;
  }

  void _handleMessage(dynamic msg, Completer<void> connectCompleter) {
    final namespace = _getNamespace(msg);
    final payload = _getPayload(msg);
    if (payload == null) return;

    // Receiver-bound message firehose for diagnostics. Equivalent to the
    // stream CaC Tool renders — every namespaced message the receiver
    // sends back. PING/PONG heartbeats are dropped to keep the log
    // readable. Always at debug; promoted to info only when
    // [enableReceiverDebugNamespaces] is on (the same opt-in that
    // subscribes the auxiliary debug namespaces in the first place).
    final type = payload['type'];
    final isHeartbeat =
        namespace == CastReceiverChannel.heartbeatNamespace &&
        (type == 'PING' || type == 'PONG');
    if (!isHeartbeat) {
      if (enableReceiverDebugNamespaces) {
        CastLogger.debug('Chromecast: RX ns=$namespace type=$type — $payload');
      } else if (namespace == CastMediaChannel.mediaNamespace &&
          type == 'MEDIA_STATUS') {
        // The 1 Hz position poll answers with a full MEDIA_STATUS every
        // second; dumping each payload floods a session log with megabytes
        // of identical JSON. Log the full payload only when something other
        // than the clock changed, and a one-line summary otherwise.
        final parsed = CastMediaChannel.parseMediaStatus(payload);
        final fingerprint =
            '${parsed?.mediaSessionId}/${parsed?.playerState}/'
            '${parsed?.idleReason}/${parsed?.duration}';
        if (parsed == null || fingerprint != _lastMediaStatusFingerprint) {
          _lastMediaStatusFingerprint = fingerprint;
          CastLogger.debug(
            'Chromecast: RX ns=$namespace type=$type — $payload',
          );
        } else {
          CastLogger.debug(
            'Chromecast: RX MEDIA_STATUS ${parsed.playerState} '
            't=${parsed.currentTime.toStringAsFixed(1)}s (unchanged, '
            'payload elided)',
          );
        }
      } else {
        CastLogger.debug('Chromecast: RX ns=$namespace type=$type — $payload');
      }
    }

    // Handle RECEIVER_STATUS — extract volume and session info
    if (namespace == CastReceiverChannel.receiverNamespace &&
        payload['type'] == 'RECEIVER_STATUS') {
      final status = CastReceiverChannel.parseReceiverStatus(payload);
      if (status != null) {
        // Always update volume from device state
        updateVolume(status.volumeLevel);

        // Complete connection if still connecting
        if (!connectCompleter.isCompleted) {
          _transportId = status.transportId;
          _sessionId = status.sessionId;
          connectCompleter.complete();
        }
      }
    }

    // Handle MEDIA_STATUS
    if (namespace == CastMediaChannel.mediaNamespace &&
        payload['type'] == 'MEDIA_STATUS') {
      // Drop late status broadcasts from a failed retry-loop attempt.
      // See [_deprecatedMediaSessionIds] for the rationale — without
      // this filter the stale IDLE+ERROR that follows LOAD_FAILED can
      // arrive after the next attempt has already started and pull
      // the live state machine backwards.
      final parsed = CastMediaChannel.parseMediaStatus(payload);
      final sid = parsed?.mediaSessionId;
      if (sid != null && _deprecatedMediaSessionIds.contains(sid)) {
        CastLogger.debug(
          'Chromecast: dropping stale MEDIA_STATUS from deprecated '
          'mediaSessionId=$sid (playerState=${parsed!.playerState}, '
          'idleReason=${parsed.idleReason ?? "-"})',
        );
        return;
      }
      _handleMediaStatus(payload);
    }
  }

  void _handleMediaStatus(Map<String, dynamic> payload) {
    final status = CastMediaChannel.parseMediaStatus(payload);
    if (status == null) return;

    _mediaSessionId = status.mediaSessionId;

    // Update position
    updatePosition(Duration(milliseconds: (status.currentTime * 1000).round()));

    // Update duration
    if (status.duration != null) {
      updateDuration(Duration(milliseconds: (status.duration! * 1000).round()));
    }

    // Note: MEDIA_STATUS volume is the stream-level volume (usually 1.0),
    // NOT the device volume. Device volume comes from RECEIVER_STATUS
    // and is handled in _handleMessage(). Don't overwrite it here.

    // Update state machine based on playerState
    _updateState(status.playerState, status.idleReason);
  }

  void _updateState(String playerState, String? idleReason) {
    final targetState = switch (playerState) {
      'PLAYING' => SessionState.playing,
      'PAUSED' => SessionState.paused,
      'BUFFERING' => SessionState.buffering,
      'IDLE' => SessionState.idle,
      'LOADING' => SessionState.loading,
      _ => null,
    };

    // Detected here rather than in play(): resuming from the TV remote
    // never passes through play(), only through this status update.
    final resumedFromPause =
        stateMachine.state == SessionState.paused &&
        targetState == SessionState.playing;

    // When the receiver reports an error, force the transition to idle
    // even if it's not in the normal transition table.
    if (targetState == SessionState.idle && idleReason == 'ERROR') {
      try {
        stateMachine.forceState(SessionState.idle);
      } catch (_) {}
    } else if (targetState != null &&
        stateMachine.canTransitionTo(targetState)) {
      stateMachine.transitionTo(targetState);
    }

    if (resumedFromPause) {
      _reassertActiveTracks();
    }

    // Start/stop position polling based on playback state.
    // Poll during PLAYING and BUFFERING to keep the seek slider current.
    // Stop polling on IDLE to avoid sending commands after media ends.
    if (playerState == 'PLAYING' || playerState == 'BUFFERING') {
      if (_positionPollTimer == null || !_positionPollTimer!.isActive) {
        _startPositionPolling();
      }
    } else if (playerState == 'IDLE') {
      _stopPositionPolling();
    }
    // PAUSED: keep polling so seek-while-paused still updates position.
  }

  /// Waits for the receiver to report a *playable* state after LOAD.
  ///
  /// The receiver may emit several MEDIA_STATUS messages after LOAD — for
  /// example: LOADING → BUFFERING → PLAYING on success, or LOADING → IDLE
  /// with `idleReason=ERROR` on failure. The Cast protocol also has dedicated
  /// `LOAD_FAILED` / `LOAD_CANCELLED` / `INVALID_*` message types that
  /// indicate the LOAD never reached the player at all.
  ///
  /// Completion logic:
  ///   - On `LOAD_FAILED` / `LOAD_CANCELLED` / `INVALID_*`: complete with
  ///     [MediaLoadFailedException] carrying the receiver-reported detail.
  ///   - On MEDIA_STATUS with `playerState=IDLE` + `idleReason=ERROR`:
  ///     complete with [MediaLoadFailedException].
  ///   - On MEDIA_STATUS with a non-IDLE `playerState` (LOADING, BUFFERING,
  ///     PLAYING, PAUSED): complete normally — playback is underway.
  ///   - On MEDIA_STATUS with `playerState=IDLE` and no error reason: keep
  ///     waiting (this can occur briefly between LOAD and the first real
  ///     status), the surrounding `Future.timeout` is the final backstop.
  ///
  /// Also logs every relevant payload at info level for diagnostics.
  ///
  /// [expectedRequestId], when set, restricts which LOAD response
  /// messages this listener treats as "ours". Stale `LOAD_FAILED` /
  /// `LOAD_CANCELLED` from earlier LOADs on the same session (e.g.
  /// after a quick re-load) would otherwise terminate this waiter
  /// incorrectly.
  void _waitForMediaStatus(
    Completer<void> completer, {
    int? expectedRequestId,
    int? priorMediaSessionId,
  }) {
    _mediaStatusSubscription?.cancel();

    // The mediaSessionId the receiver assigned to OUR load, learned from
    // the first MEDIA_STATUS that answers [expectedRequestId]. Needed to
    // attribute *unsolicited* failure broadcasts: a LOAD that failed on a
    // previous attempt leaves a receiver-side session behind whose dying
    // IDLE+ERROR (requestId=0) can arrive milliseconds after the next
    // attempt's LOAD goes out — and must not be read as that attempt
    // failing. Seen live: the retry was declared dead 1ms after it was
    // sent, while the receiver went on to play it fine.
    int? ourMediaSessionId;

    _mediaStatusSubscription = _channel.messageStream.listen((msg) {
      final namespace = _getNamespace(msg);
      final payload = _getPayload(msg);
      if (namespace != CastMediaChannel.mediaNamespace || payload == null) {
        return;
      }

      final type = payload['type'] as String?;
      final responseRequestId = payload['requestId'];

      // Hard LOAD failure — receiver couldn't even prepare the media.
      // These messages always carry the requestId of the LOAD they refer
      // to, so when we know our own LOAD's requestId we can ignore stale
      // responses from earlier attempts.
      if (type == 'LOAD_FAILED' ||
          type == 'LOAD_CANCELLED' ||
          type == 'INVALID_PLAYER_STATE' ||
          type == 'INVALID_REQUEST' ||
          type == 'ERROR') {
        if (expectedRequestId != null &&
            responseRequestId != null &&
            responseRequestId != expectedRequestId) {
          CastLogger.debug(
            'Chromecast: ignoring stale $type '
            '(requestId=$responseRequestId, expected=$expectedRequestId)',
          );
          return;
        }

        CastLogger.error(
          'Chromecast: receiver returned $type during LOAD — payload: $payload',
        );
        if (!completer.isCompleted) {
          completer.completeError(
            MediaLoadFailedException(
              'Receiver returned $type${_formatErrorDetail(payload)}',
            ),
          );
        }
        _mediaStatusSubscription?.cancel();
        _mediaStatusSubscription = null;
        return;
      }

      if (type != 'MEDIA_STATUS') return;

      // Log the parsed status for diagnostics. MEDIA_STATUS fires on every
      // play/pause/seek and during the LOAD handshake, so log at debug —
      // the surrounding error / playable transitions are still at
      // info/error.
      final parsed = CastMediaChannel.parseMediaStatus(payload);
      if (parsed != null) {
        CastLogger.debug(
          'Chromecast: MEDIA_STATUS playerState=${parsed.playerState} '
          'idleReason=${parsed.idleReason ?? "-"} '
          'currentTime=${parsed.currentTime.toStringAsFixed(2)}s '
          'duration=${parsed.duration?.toStringAsFixed(2) ?? "-"}s '
          'volume=${parsed.volumeLevel.toStringAsFixed(2)} '
          'muted=${parsed.isMuted}',
        );
      } else {
        CastLogger.debug(
          'Chromecast: MEDIA_STATUS with no status entries — payload: $payload',
        );
      }

      // Filter out stale MEDIA_STATUS messages from a previous attempt.
      // The receiver assigns a fresh mediaSessionId for each LOAD it
      // processes, so any MEDIA_STATUS still carrying the prior
      // attempt's session id is leftover cleanup chatter and must not
      // terminate the current waiter.
      if (priorMediaSessionId != null &&
          parsed != null &&
          parsed.mediaSessionId == priorMediaSessionId) {
        CastLogger.debug(
          'Chromecast: ignoring stale MEDIA_STATUS '
          '(mediaSessionId=${parsed.mediaSessionId} '
          'matches priorMediaSessionId — leftover from previous attempt)',
        );
        return;
      }

      // A status answering our LOAD's requestId names our session.
      if (parsed != null &&
          expectedRequestId != null &&
          responseRequestId == expectedRequestId) {
        ourMediaSessionId ??= parsed.mediaSessionId;
      }

      // An IDLE+ERROR we cannot attribute to our LOAD — neither a direct
      // response to its requestId nor carrying its session id — is the
      // corpse of an earlier attempt announcing its death. Deprecate the
      // session so the main handler drops its further chatter, and keep
      // waiting: if OUR load is also doomed, its own attributed error or
      // the 15s timeout ends the wait.
      if (parsed != null &&
          parsed.playerState == 'IDLE' &&
          parsed.idleReason == 'ERROR') {
        final isOurs =
            (expectedRequestId != null &&
                responseRequestId == expectedRequestId) ||
            (ourMediaSessionId != null &&
                parsed.mediaSessionId == ourMediaSessionId);
        if (!isOurs) {
          _deprecatedMediaSessionIds.add(parsed.mediaSessionId);
          CastLogger.info(
            'Chromecast: ignoring unattributed IDLE/ERROR from '
            'mediaSessionId=${parsed.mediaSessionId} '
            '(requestId=$responseRequestId, expected=$expectedRequestId, '
            'ours=${ourMediaSessionId ?? "unknown"}) — '
            'stale corpse of a previous attempt, continuing to wait',
          );
          return;
        }
      }

      _handleMediaStatus(payload);

      if (parsed == null) {
        // Empty MEDIA_STATUS — keep waiting.
        return;
      }

      // Hard receiver-side playback failure (attributed to our LOAD above).
      if (parsed.playerState == 'IDLE' && parsed.idleReason == 'ERROR') {
        CastLogger.error(
          'Chromecast: receiver entered IDLE with idleReason=ERROR — '
          'full payload: $payload',
        );
        if (!completer.isCompleted) {
          completer.completeError(
            MediaLoadFailedException(
              'Receiver rejected media (IDLE/ERROR)'
              '${_formatErrorDetail(payload)}',
            ),
          );
        }
        _mediaStatusSubscription?.cancel();
        _mediaStatusSubscription = null;
        return;
      }

      // Playable state — LOAD succeeded.
      if (parsed.playerState != 'IDLE') {
        if (!completer.isCompleted) {
          completer.complete();
        }
        _mediaStatusSubscription?.cancel();
        _mediaStatusSubscription = null;
        return;
      }

      // playerState == IDLE without ERROR — keep waiting for the next status.
      CastLogger.debug(
        'Chromecast: MEDIA_STATUS IDLE without error reason '
        '(idleReason=${parsed.idleReason ?? "-"}) — continuing to wait',
      );
    });
  }

  /// Extracts a short human-readable error detail from an error/LOAD_FAILED
  /// payload. Cast receivers commonly include `reason`, `detailedErrorCode`,
  /// `errorMessage`, or `errorReason` fields. We pluck whichever is present.
  static String _formatErrorDetail(Map<String, dynamic> payload) {
    final parts = <String>[];
    for (final key in const [
      'reason',
      'detailedErrorCode',
      'errorCode',
      'errorMessage',
      'errorReason',
      'customData',
    ]) {
      final v = payload[key];
      if (v != null) parts.add('$key=$v');
    }
    if (parts.isEmpty) return '';
    return ' [${parts.join(', ')}]';
  }

  String? _getNamespace(dynamic msg) {
    if (msg is CastMessage) return msg.namespace_;
    // Mock message
    if (msg is Map) return msg['namespace'] as String?;
    // Dynamic mock object
    try {
      return (msg as dynamic).namespace as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _getPayload(dynamic msg) {
    if (msg is CastMessage) {
      try {
        return jsonDecode(msg.payloadUtf8) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    // Mock message
    if (msg is Map) return msg['payload'] as Map<String, dynamic>?;
    // Dynamic mock object
    try {
      return (msg as dynamic).payload as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static String _contentTypeForMedia(CastMediaType type) {
    return switch (type) {
      CastMediaType.hls => 'application/x-mpegURL',
      CastMediaType.mp4 => 'video/mp4',
      CastMediaType.mkv => 'video/x-matroska',
      CastMediaType.mpegTs => 'video/mp2t',
    };
  }
}

// ---------------------------------------------------------------------------
// Adapter interfaces for testability
// ---------------------------------------------------------------------------

/// Adapter over CastV2Channel or a mock.
abstract class _ChannelAdapter {
  Future<void> connect(String host, {int port});
  Stream<dynamic> get messageStream;
  void sendMessage({
    required String namespace,
    required String sourceId,
    required String destinationId,
    required String payload,
  });
  Future<void> close();
}

// ---------------------------------------------------------------------------
// Real adapters (wrap actual implementations)
// ---------------------------------------------------------------------------

class _RealChannelAdapter implements _ChannelAdapter {
  final CastV2Channel _channel = CastV2Channel();

  @override
  Future<void> connect(String host, {int port = 8009}) =>
      _channel.connect(host, port: port);

  @override
  Stream<CastMessage> get messageStream => _channel.messageStream;

  @override
  void sendMessage({
    required String namespace,
    required String sourceId,
    required String destinationId,
    required String payload,
  }) {
    _channel.sendMessage(
      namespace: namespace,
      sourceId: sourceId,
      destinationId: destinationId,
      payload: payload,
    );
  }

  @override
  Future<void> close() => _channel.close();
}

// ---------------------------------------------------------------------------
// Mock adapters (wrap test doubles)
// ---------------------------------------------------------------------------

class _MockChannelAdapter implements _ChannelAdapter {
  final dynamic _mock;

  _MockChannelAdapter(this._mock);

  @override
  Future<void> connect(String host, {int port = 8009}) =>
      (_mock as dynamic).connect(host, port: port) as Future<void>;

  @override
  Stream<dynamic> get messageStream =>
      (_mock as dynamic).messageStream as Stream<dynamic>;

  @override
  void sendMessage({
    required String namespace,
    required String sourceId,
    required String destinationId,
    required String payload,
  }) {
    (_mock as dynamic).sendMessage(
      namespace: namespace,
      sourceId: sourceId,
      destinationId: destinationId,
      payload: payload,
    );
  }

  @override
  Future<void> close() => (_mock as dynamic).close() as Future<void>;
}
