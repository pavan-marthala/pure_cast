import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
import 'package:pure_cast/core/features/casting/data/data_source/subtitle_extraction_service.dart';
import 'package:pure_cast/core/DI/injection.dart';

part 'cast_session_event.dart';
part 'cast_session_state.dart';
part 'cast_session_bloc.freezed.dart';

@injectable
class CastSessionBloc extends Bloc<CastSessionEvent, CastSessionState> {
  final ICastService _castService;
  final PlaybackHistoryRepository _historyRepo;

  StreamSubscription<PureCastSessionState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  bool _isLoadingMedia = false;

  /// True while a live restart (audio switch, seek or subtitle switch) is
  /// awaiting the engine. Checked when an event is enqueued so commands issued
  /// during the restart are dropped instead of racing it.
  bool _restartInFlight = false;

  /// Accumulates quick relative-seek taps into a single seek.
  Timer? _seekRelativeDebounce;

  /// How long relative-seek taps are collected before one seek is issued.
  static const Duration _seekRelativeDelay = Duration(milliseconds: 600);

  /// How much playback progress is collected before another history checkpoint
  /// is written while playing.
  static const Duration _checkpointInterval = Duration(seconds: 10);

  /// Position of the last written checkpoint, used to throttle writes.
  Duration? _lastCheckpointPosition;

  /// Upper bound for a single connect attempt, including the teardown of any
  /// previous session.
  ///
  /// A legitimate attempt can take ~20 s (5 s TLS + 15 s receiver handshake),
  /// so this only trips when a teardown or the receiver never responds. Without
  /// it a stuck connect leaves the UI on "Connecting..." forever.
  final Duration connectTimeout;

  /// Device id of the connect currently in flight, if any.
  ///
  /// Guards against overlapping connects (a double tap, or the discovery
  /// auto-reconnect racing a manual tap). Both would tear down each other's
  /// session and can leave the receiver connected while the UI stays in
  /// [StateStatus.loading].
  String? _connectingDeviceId;

  CastSessionBloc(
    this._castService,
    this._historyRepo, {
    @ignoreParam this.connectTimeout = const Duration(seconds: 30),
  }) : super(const CastSessionState()) {
    on<ConnectDeviceEvent>(_onConnectDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<LoadMediaEvent>(_onLoadMedia);
    on<PlayMediaEvent>(_onPlayMedia);
    on<PauseMediaEvent>(_onPauseMedia);
    on<StopMediaEvent>(_onStopMedia);
    on<SeekMediaEvent>(_onSeekMedia);
    on<SeekRelativeEvent>(_onSeekRelative);
    on<CommitSeekPreviewEvent>(_onCommitSeekPreview);
    on<SelectAudioEvent>(_onSelectAudio);
    on<SetVolumeEvent>(_onSetVolume);
    on<SetSubtitleEvent>(_onSetSubtitle);
    on<ExtractAndSetSubtitleEvent>(_onExtractAndSetSubtitle);
    on<SessionStateChangedEvent>(_onSessionStateChanged);
    on<PositionUpdatedEvent>(_onPositionUpdated);
    on<DurationUpdatedEvent>(_onDurationUpdated);
    _listenToStreams();
  }

  @override
  void add(CastSessionEvent event) {
    if (_restartInFlight &&
        (event is SeekMediaEvent ||
            event is SeekRelativeEvent ||
            event is CommitSeekPreviewEvent ||
            event is SelectAudioEvent ||
            // Only live sessions restart in place; a non-live session can set
            // this flag only while its audio switch is already restarting.
            (state.isLive &&
                (event is SetSubtitleEvent ||
                    event is ExtractAndSetSubtitleEvent)))) {
      log(
        'Dropping ${event.runtimeType} while a live restart is in flight',
        name: 'Cast Session Bloc',
      );
      return;
    }
    super.add(event);
  }

  void _listenToStreams() {
    _stateSubscription = _castService.sessionStateStream.listen((state) {
      add(SessionStateChangedEvent(state));
    });

    _positionSubscription = _castService.positionStream.listen((pos) {
      add(PositionUpdatedEvent(pos));
    });

    _durationSubscription = _castService.durationStream.listen((dur) {
      add(DurationUpdatedEvent(dur));
    });
  }

  Future<void> _onConnectDevice(
    ConnectDeviceEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    if (_connectingDeviceId != null) {
      log(
        'Ignoring connect to ${event.device.name}: '
        'a connect to $_connectingDeviceId is already in flight',
        name: 'Cast Session Bloc',
      );
      return;
    }

    final previousDevice = state.activeDevice;
    _connectingDeviceId = event.device.id;
    emit(
      state.copyWith(
        connectionStatus: StateStatus.loading,
        activeDevice: event.device,
        connectionError: null,
      ),
    );
    try {
      await _castService.connect(event.device).timeout(connectTimeout);
      emit(state.copyWith(connectionStatus: StateStatus.loaded));
      if (state.activeMedia != null) {
        add(LoadMediaEvent(state.activeMedia!));
      }
    } on TimeoutException {
      // Keep the requested device selected: the timed-out connect may still
      // complete underneath (e.g. a slow receiver handshake). If it does, the
      // session stream reports connected/playing and the status self-heals.
      emit(
        state.copyWith(
          connectionStatus: StateStatus.error,
          connectionError:
              'Timed out connecting to ${event.device.name}. '
              'Check that the device is on the same network.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          connectionStatus: StateStatus.error,
          connectionError: e.toString(),
          activeDevice: previousDevice,
        ),
      );
    } finally {
      _connectingDeviceId = null;
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDeviceEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.disconnect();
      _checkpointHistory(force: true);
      _isLoadingMedia = false;
      _restartInFlight = false;
      _cancelSeekPreview();
      _lastCheckpointPosition = null;
      emit(const CastSessionState());
    } catch (e) {
      emit(state.copyWith(connectionError: e.toString()));
    }
  }

  Future<void> _onLoadMedia(
    LoadMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    // Skip if we're already loading this exact media (prevents duplicate
    // loadMedia() calls from coordinator + connect handler racing together).
    if (_isLoadingMedia && state.activeMedia?.uri == event.media.uri) {
      log(
        "Already loading ${event.media.title} — skipping duplicate",
        name: "Cast Session Bloc",
      );
      return;
    }
    // Save where the outgoing media stopped before its state is replaced.
    if (state.activeMedia != null && state.activeMedia!.uri != event.media.uri) {
      _checkpointHistory(force: true);
    }
    _lastCheckpointPosition = null;
    _isLoadingMedia = true;
    _cancelSeekPreview();

    emit(
      state.copyWith(
        playbackStatus: StateStatus.loading,
        activeMedia: event.media,
        playbackError: null,
        // The previous media's progress must not leak into this one. Seed the
        // duration from the media so checkpoints work even when the device
        // never reports one; a real duration from the receiver replaces it.
        position: Duration.zero,
        duration: event.media.duration ?? Duration.zero,
        // A new load invalidates any audio/seeking state from the previous
        // media.
        audioTracks: const [],
        activeAudioIndex: null,
        isLive: false,
        restarting: false,
        seekPreview: null,
      ),
    );

    if (state.activeDevice == null) {
      log("No active device connected, retaining media as pending");
      emit(state.copyWith(playbackStatus: StateStatus.initial));
      _isLoadingMedia = false;
      return;
    }

    try {
      log(
        "Loading media on device: ${state.activeDevice?.name}",
        name: "Cast Session Bloc",
      );
      if (event.media.isLocalFile) {
        emit(state.copyWith(preparing: true, prepareError: null));
      }
      await _castService.loadMedia(event.media);
      if (event.media.isLocalFile) {
        emit(state.copyWith(preparing: false));
      }

      // Apply the one-shot resume offset (if the user chose to continue).
      final startAt = event.media.startPosition;
      if (startAt != null && startAt > Duration.zero) {
        try {
          log(
            "Seeking to resume position $startAt",
            name: "Cast Session Bloc",
          );
          await _castService.seek(startAt);
        } catch (e) {
          // Resuming is best effort: playback still starts from the beginning.
          log(
            "Failed to seek to resume position: $e",
            name: "Cast Session Bloc",
          );
        }
      }

      // Fill the audio state from the engine. Remux plans are live and expose
      // their tracks directly; a direct load has no live metadata, so probe
      // the file (best effort — failures never block playback).
      final isLive = _castService.isLiveStream;
      var tracks = _castService.audioTracks;
      int? activeIndex = isLive ? _castService.activeAudioIndex : null;
      if (!isLive && event.media.isLocalFile) {
        final probed = await _probeAudioTracks(event.media.uri);
        if (probed != null) {
          tracks = probed;
          activeIndex = _defaultAudioTrackIndex(probed);
        }
      }

      emit(
        state.copyWith(
          playbackStatus: StateStatus.loaded,
          audioTracks: tracks,
          activeAudioIndex: activeIndex,
          isLive: isLive,
          restarting: false,
        ),
      );

      // dart_cast LOAD already sets autoplay: true — the receiver should
      // start playing automatically. Only send PLAY if the session isn't
      // already playing (avoids redundant commands that can fail on a
      // session still settling after LOAD).
      if (state.activeDevice != null &&
          _castService.currentState != PureCastSessionState.playing) {
        log(
          "Media loaded successfully, sending PLAY",
          name: "Cast Session Bloc",
        );
        add(PlayMediaEvent());
      } else {
        log(
          "Media loaded and receiver is already playing — skipping PLAY",
          name: "Cast Session Bloc",
        );
      }
    } catch (e) {
      log(
        "Error when loading media active device is: ${state.activeDevice?.name}",
        error: e,
        name: "Cast Session Bloc",
      );

      log(
        "Failed media details:",
        error: state.activeMedia.toString(),
        name: "Cast Session Bloc",
      );

      emit(
        state.copyWith(
          playbackStatus: StateStatus.error,
          playbackError: e.toString(),
        ),
      );
    } finally {
      _isLoadingMedia = false;
    }
  }

  Future<void> _onPlayMedia(
    PlayMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.play();
    } catch (e) {
      log("Error when playing media", error: e);
      emit(state.copyWith(playbackError: e.toString()));
    }
  }

  Future<void> _onPauseMedia(
    PauseMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.pause();
      _checkpointHistory(force: true);
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    }
  }

  Future<void> _onStopMedia(
    StopMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    _cancelSeekPreview();
    try {
      await _castService.stop();
      
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    } finally {
      _restartInFlight = false;
      emit(
        state.copyWith(
          audioTracks: const [],
          activeAudioIndex: null,
          isLive: false,
          restarting: false,
          seekPreview: null,
        ),
      );
      _checkpointHistory(force: true);
    }
  }

  Future<void> _onSeekMedia(
    SeekMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    // A slider drag supersedes any pending relative-seek preview.
    _cancelSeekPreview();
    // A restart owns the stream; seeking now would race the new LOAD.
    if (state.restarting || _restartInFlight) {
      if (state.seekPreview != null) {
        emit(state.copyWith(seekPreview: null));
      }
      return;
    }
    await _seekTo(event.position, emit);
  }

  /// Accumulates relative-seek taps and commits one seek after a short pause.
  void _onSeekRelative(
    SeekRelativeEvent event,
    Emitter<CastSessionState> emit,
  ) {
    final device = state.activeDevice;
    if (state.activeMedia == null || device == null) return;
    if (!device.capabilities.canSeek) return;
    if (state.duration <= Duration.zero) return;
    if (state.restarting || _restartInFlight) return;

    var target = (state.seekPreview ?? state.position) + event.delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > state.duration) target = state.duration;

    _seekRelativeDebounce?.cancel();
    _seekRelativeDebounce = Timer(_seekRelativeDelay, () {
      _seekRelativeDebounce = null;
      add(const CommitSeekPreviewEvent());
    });

    emit(state.copyWith(seekPreview: target));
  }

  Future<void> _onCommitSeekPreview(
    CommitSeekPreviewEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    final target = state.seekPreview;
    if (target == null) return;
    if (state.restarting || _restartInFlight) {
      emit(state.copyWith(seekPreview: null));
      return;
    }
    await _seekTo(target, emit, fromPreview: true);
  }

  /// Runs the existing seek path and clears the preview when it settles.
  Future<void> _seekTo(
    Duration position,
    Emitter<CastSessionState> emit, {
    bool fromPreview = false,
  }) async {
    if (state.restarting || _restartInFlight) {
      if (fromPreview && state.seekPreview != null) {
        emit(state.copyWith(seekPreview: null));
      }
      return;
    }

    final live = state.isLive;
    _restartInFlight = live;
    if (live) emit(state.copyWith(restarting: true));
    try {
      await _castService.seek(position);
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    } finally {
      _restartInFlight = false;
      emit(
        state.copyWith(
          restarting: live ? false : state.restarting,
          seekPreview: fromPreview ? null : state.seekPreview,
        ),
      );
    }
  }

  void _cancelSeekPreview() {
    _seekRelativeDebounce?.cancel();
    _seekRelativeDebounce = null;
  }

  Future<void> _onSelectAudio(
    SelectAudioEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    final media = state.activeMedia;
    final device = state.activeDevice;

    if (media == null || device == null) return;
    if (state.restarting || _restartInFlight) return;
    if (event.index == state.activeAudioIndex) return;
    if (device.protocol != PureCastProtocol.chromecast) return;
    if (!device.capabilities.canChangeAudioTrack) return;
    if (!state.audioTracks.any((t) => t.index == event.index)) return;

    _restartInFlight = true;
    _cancelSeekPreview();
    emit(
      state.copyWith(
        restarting: true,
        playbackError: null,
        seekPreview: null,
      ),
    );
    try {
      await _castService.switchLiveAudio(
        filePath: media.uri,
        audioIndex: event.index,
        position: state.position,
        // The app's normal load path uses the adapter default.
        streamType: 'BUFFERED',
        duration: state.duration,
        audioTracks: state.audioTracks,
      );

      final refreshed = _castService.audioTracks;
      emit(
        state.copyWith(
          audioTracks: refreshed.isNotEmpty ? refreshed : state.audioTracks,
          activeAudioIndex: event.index,
          isLive: _castService.isLiveStream,
          restarting: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          restarting: false,
          playbackError: e.toString(),
        ),
      );
    } finally {
      _restartInFlight = false;
    }
  }

  Future<void> _onSetVolume(
    SetVolumeEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.setVolume(event.volume);
      emit(state.copyWith(volume: event.volume));
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    }
  }

  Future<void> _onSetSubtitle(
    SetSubtitleEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    if (state.isLive) {
      await _setLiveSubtitle(event.subtitle, emit);
      return;
    }

    try {
      var subtitle = event.subtitle;

      // If subtitle needs extraction (url points to media file, not extracted file),
      // extract it first before sending to the casting layer.
      if (subtitle != null && !_isExtractedSubtitle(subtitle)) {
        final extractionService = getIt<SubtitleExtractionService>();
        final media = state.activeMedia;
        if (media != null && media.isLocalFile) {
          final file = File(media.uri);
          final fileSize = await file.length();
          final lastModified = await file.lastModified();

          final probeResult = await extractionService.probeAndCacheSubtitles(
            filePath: media.uri,
            fileSize: fileSize,
            lastModified: lastModified,
          );

          // Find the matching stream by ID (format: "mediaUri:streamIndex")
          SubtitleStreamInfo? matchingStream;
          final streamIndexStr = subtitle.id.split(':').last;
          for (final stream in probeResult.streams) {
            if (stream.streamIndex.toString() == streamIndexStr) {
              matchingStream = stream;
              break;
            }
          }

          if (matchingStream != null) {
            // Extract (or reuse cached) cast-ready VTT subtitle
            final result = await extractionService.extractCastSubtitle(
              sourcePath: media.uri,
              stream: matchingStream,
            );

            if (!result.isSuccess) {
              emit(
                state.copyWith(
                  prepareSubtitlesError:
                      result.error?.message ?? 'Extraction failed',
                ),
              );
              return;
            }

            final extractedPath = result.outputPath!;

            // Update the subtitle URL to point to the extracted VTT file
            subtitle = subtitle.copyWith(url: extractedPath, format: 'vtt');
          }
        }
      }

      // If a device is connected, make sure the subtitle track is declared in
      // the loaded media before activating it. Reload at the current position.
      final media = state.activeMedia;
      if (subtitle != null && state.activeDevice != null && media != null) {
        final updatedSubtitles = [...media.subtitles];
        final idx = updatedSubtitles.indexWhere((s) => s.id == subtitle!.id);
        if (idx >= 0) {
          updatedSubtitles[idx] = subtitle;
        } else {
          updatedSubtitles.add(subtitle);
        }
        final updatedMedia = media.copyWith(
          subtitles: updatedSubtitles,
          defaultSubtitle: subtitle,
        );
        try {
          if (updatedMedia.isLocalFile) {
            emit(state.copyWith(preparingSubtitles: true, prepareError: null));
          }
          await _castService.loadMedia(updatedMedia);
          if (updatedMedia.isLocalFile) {
            emit(state.copyWith(preparingSubtitles: false));
          }
          emit(state.copyWith(activeMedia: updatedMedia));
        } catch (e) {
          // Fall through; setSubtitle may still work if track was declared.
        }
      }

      await _castService.setSubtitle(subtitle);
      emit(state.copyWith(activeSubtitle: subtitle));
    } catch (e) {
      emit(state.copyWith(prepareSubtitlesError: e.toString()));
    }
  }

  Future<List<PureCastAudioTrack>?> _probeAudioTracks(String filePath) async {
    try {
      return await _castService
          .probeAudioTracks(filePath)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      log(
        'Audio track probe failed for $filePath',
        error: e,
        name: 'Cast Session Bloc',
      );
      return null;
    }
  }

  int? _defaultAudioTrackIndex(List<PureCastAudioTrack> tracks) {
    if (tracks.isEmpty) return null;
    for (final track in tracks) {
      if (track.isDefault) return track.index;
    }
    return tracks.first.index;
  }

  bool _isExtractedSubtitle(PureCastSubtitleTrack subtitle) {
    // Check if the URL points to an extracted subtitle file (not the media file)
    return subtitle.url.contains('pure_cast_subtitles') ||
        subtitle.url.contains('pure_cast_subtitle_cache') ||
        subtitle.url.endsWith('.srt') ||
        subtitle.url.endsWith('.vtt') ||
        subtitle.url.endsWith('.ass') ||
        subtitle.url.endsWith('.ssa') ||
        subtitle.url.endsWith('.sub') ||
        subtitle.url.endsWith('.sup');
  }

  /// Applies a subtitle choice to the live MKV stream.
  ///
  /// Passing null disables subtitles in place. A non-null subtitle is
  /// extracted first when it still points at the media file, then the live
  /// stream is restarted at the current position with a time-shifted copy
  /// attached. Both paths mirror the guards of [_onSelectAudio].
  Future<void> _setLiveSubtitle(
    PureCastSubtitleTrack? subtitle,
    Emitter<CastSessionState> emit,
  ) async {
    final media = state.activeMedia;
    final device = state.activeDevice;
    if (media == null || device == null) return;
    if (state.restarting || _restartInFlight) return;
    if (device.protocol != PureCastProtocol.chromecast) return;

    if (subtitle == null) {
      _restartInFlight = true;
      try {
        await _castService.switchLiveSubtitle(
          subtitle: null,
          position: state.position,
        );
        emit(state.copyWith(activeSubtitle: null, prepareSubtitlesError: null));
      } catch (e) {
        emit(state.copyWith(prepareSubtitlesError: e.toString()));
      } finally {
        _restartInFlight = false;
      }
      return;
    }

    var resolved = subtitle;
    if (!_isExtractedSubtitle(resolved) && media.isLocalFile) {
      emit(state.copyWith(preparingSubtitles: true, prepareError: null));
      try {
        final extracted = await _extractLiveSubtitle(resolved, media, emit);
        if (extracted == null) return;
        resolved = extracted;
      } catch (e) {
        emit(state.copyWith(prepareSubtitlesError: e.toString()));
        return;
      } finally {
        if (media.isLocalFile) {
          emit(state.copyWith(preparingSubtitles: false));
        }
      }
    }

    _restartInFlight = true;
    _cancelSeekPreview();
    emit(
      state.copyWith(restarting: true, playbackError: null, seekPreview: null),
    );
    try {
      await _castService.switchLiveSubtitle(
        subtitle: resolved,
        position: state.position,
      );

      final updatedSubtitles = [...media.subtitles];
      final index = updatedSubtitles.indexWhere((s) => s.id == resolved.id);
      if (index >= 0) {
        updatedSubtitles[index] = resolved;
      } else {
        updatedSubtitles.add(resolved);
      }

      final refreshed = _castService.audioTracks;
      emit(
        state.copyWith(
          activeSubtitle: resolved,
          activeMedia: media.copyWith(subtitles: updatedSubtitles),
          prepareSubtitlesError: null,
          audioTracks: refreshed.isNotEmpty ? refreshed : state.audioTracks,
          isLive: _castService.isLiveStream,
          restarting: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(restarting: false, prepareSubtitlesError: e.toString()),
      );
    } finally {
      _restartInFlight = false;
    }
  }

  /// Extracts [subtitle]'s stream into cast-ready WebVTT for [media].
  ///
  /// This intentionally duplicates the stream matching of the non-live
  /// handlers instead of sharing it, so their behaviour stays untouched.
  /// Returns null after emitting [CastSessionState.prepareSubtitlesError] when
  /// extraction cannot proceed.
  Future<PureCastSubtitleTrack?> _extractLiveSubtitle(
    PureCastSubtitleTrack subtitle,
    PureCastMedia media,
    Emitter<CastSessionState> emit,
  ) async {
    final extractionService = getIt<SubtitleExtractionService>();

    final file = File(media.uri);
    final fileSize = await file.length();
    final lastModified = await file.lastModified();

    final probeResult = await extractionService.probeAndCacheSubtitles(
      filePath: media.uri,
      fileSize: fileSize,
      lastModified: lastModified,
    );

    SubtitleStreamInfo? matchingStream;
    final streamIndexStr = subtitle.id.split(':').last;
    for (final stream in probeResult.streams) {
      if (stream.streamIndex.toString() == streamIndexStr) {
        matchingStream = stream;
        break;
      }
    }

    if (matchingStream == null) {
      emit(
        state.copyWith(
          prepareSubtitlesError: 'Subtitle stream not found in video',
        ),
      );
      return null;
    }

    final result = await extractionService.extractCastSubtitle(
      sourcePath: media.uri,
      stream: matchingStream,
    );

    if (!result.isSuccess) {
      emit(
        state.copyWith(
          prepareSubtitlesError: result.error?.message ?? 'Extraction failed',
        ),
      );
      return null;
    }

    return subtitle.copyWith(url: result.outputPath!, format: 'vtt');
  }

  Future<void> _onExtractAndSetSubtitle(
    ExtractAndSetSubtitleEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    final media = state.activeMedia;
    if (media == null) return;

    if (state.isLive) {
      await _setLiveSubtitle(event.subtitle, emit);
      return;
    }

    try {
      final extractionService = getIt<SubtitleExtractionService>();
      final sourcePath = media.uri;

      final file = File(sourcePath);
      final fileSize = await file.length();
      final lastModified = await file.lastModified();

      // Probe to get the stream info
      final probeResult = await extractionService.probeAndCacheSubtitles(
        filePath: sourcePath,
        fileSize: fileSize,
        lastModified: lastModified,
      );

      // Find the matching stream
      SubtitleStreamInfo? matchingStream;
      for (final stream in probeResult.streams) {
        if (stream.streamIndex.toString() ==
            event.subtitle.id.split(':').last) {
          matchingStream = stream;
          break;
        }
      }

      if (matchingStream == null) {
        emit(
          state.copyWith(
            prepareSubtitlesError: 'Subtitle stream not found in video',
          ),
        );
        return;
      }

      // Extract (or reuse cached) cast-ready VTT subtitle
      final result = await extractionService.extractCastSubtitle(
        sourcePath: sourcePath,
        stream: matchingStream,
      );

      if (!result.isSuccess) {
        emit(
          state.copyWith(
            prepareSubtitlesError: result.error?.message ?? 'Extraction failed',
          ),
        );
        return;
      }

      final extractedPath = result.outputPath!;

      // Update the subtitle track with the extracted file path
      final updatedSubtitle = event.subtitle.copyWith(
        url: extractedPath,
        format: 'vtt',
      );

      // Update the media's subtitle list with the extracted track
      final subtitleId = event.subtitle.id;
      final updatedSubtitles = media.subtitles.map((s) {
        if (s.id == subtitleId) {
          return updatedSubtitle;
        }
        return s;
      }).toList();

      // If not already in list, add it
      if (!updatedSubtitles.any((s) => s.id == subtitleId)) {
        updatedSubtitles.add(updatedSubtitle);
      }

      final updatedMedia = media.copyWith(subtitles: updatedSubtitles);

      // If device is connected, reload media with updated subtitles, then set subtitle
      if (state.activeDevice != null) {
        if (updatedMedia.isLocalFile) {
          emit(state.copyWith(preparingSubtitles: true, prepareError: null));
        }
        await _castService.loadMedia(updatedMedia);
        if (updatedMedia.isLocalFile) {
          emit(state.copyWith(preparingSubtitles: false));
        }
        emit(state.copyWith(activeMedia: updatedMedia));
        await _castService.setSubtitle(updatedSubtitle);
        emit(state.copyWith(activeSubtitle: updatedSubtitle));
      } else {
        emit(
          state.copyWith(
            activeMedia: updatedMedia,
            activeSubtitle: updatedSubtitle,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(prepareSubtitlesError: e.toString()));
    }
  }

  void _onSessionStateChanged(
    SessionStateChangedEvent event,
    Emitter<CastSessionState> emit,
  ) {
    if (event.newState == PureCastSessionState.disconnected) {
      // Don't clear activeDevice if we're in the middle of connecting.
      // dart_cast auto-disconnects the previous session during connect()
      // handshake, which emits disconnected on the stream. Clearing activeDevice
      // there would break the connect flow on Android where the receiver
      // shows connected but the BLoC state says disconnected.
      if (_connectingDeviceId != null ||
          state.connectionStatus == StateStatus.loading) {
        emit(state.copyWith(sessionState: event.newState));
        return;
      }
      _checkpointHistory(force: true);
      _isLoadingMedia = false;
      _restartInFlight = false;
      _cancelSeekPreview();
      _lastCheckpointPosition = null;
      emit(const CastSessionState());
      return;
    }

    // The receiver can report connected/playing before the connect future
    // resolves (or when a session was opened outside this bloc). Treat that as
    // a successful connection so the UI never stays latched on "Connecting...".
    final healedConnectionStatus =
        (event.newState == PureCastSessionState.connected ||
                event.newState == PureCastSessionState.playing) &&
            state.activeDevice != null &&
            state.connectionStatus != StateStatus.loaded
        ? StateStatus.loaded
        : state.connectionStatus;

    emit(
      state.copyWith(
        sessionState: event.newState,
        connectionStatus: healedConnectionStatus,
      ),
    );
    // Never derive "completed" from the session state here: an idle receiver
    // (a normal stop) maps to `completed` too. Completion is inferred from the
    // position instead, otherwise stopping would disable the resume prompt.
    _checkpointHistory(force: true);
  }

  void _checkpointHistory({bool force = false}) {
    final media = state.activeMedia;
    final duration = state.duration;
    if (media == null || duration <= Duration.zero) return;

    final position = state.position;
    final isCompleted = position >= duration - const Duration(seconds: 2);

    // A zero position is either a fresh load or the receiver resetting to the
    // start while it stops. Writing it would erase real saved progress (and
    // disable the resume prompt), so it is never persisted — even when forced.
    if (!isCompleted && position <= Duration.zero) return;

    // While playing, only write when enough new progress has accumulated.
    if (!force && !isCompleted) {
      final last = _lastCheckpointPosition;
      if (last != null &&
          (position - last).abs() < _checkpointInterval) {
        return;
      }
    }

    _lastCheckpointPosition = position;
    unawaited(
      _historyRepo
          .recordHistoryCheckpoint(
            media: media,
            position: position,
            duration: duration,
            completed: isCompleted,
          )
          .catchError((Object e) {
            log(
              'Failed to write playback checkpoint: $e',
              name: 'Cast Session Bloc',
            );
          }),
    );
  }

  void _onPositionUpdated(
    PositionUpdatedEvent event,
    Emitter<CastSessionState> emit,
  ) {
    emit(state.copyWith(position: event.position));
    _checkpointHistory();
  }

  void _onDurationUpdated(
    DurationUpdatedEvent event,
    Emitter<CastSessionState> emit,
  ) {
    emit(state.copyWith(duration: event.duration));
  }

  @override
  Future<void> close() {
    _checkpointHistory(force: true);
    _isLoadingMedia = false;
    _restartInFlight = false;
    _connectingDeviceId = null;
    _cancelSeekPreview();
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    return super.close();
  }
}
