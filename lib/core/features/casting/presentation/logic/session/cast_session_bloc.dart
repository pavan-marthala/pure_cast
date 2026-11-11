import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/database/app_database.dart';
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
  final AppDatabase _db;

  StreamSubscription<PureCastSessionState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  bool _isLoadingMedia = false;

  CastSessionBloc(this._castService, this._historyRepo, this._db)
    : super(const CastSessionState()) {
    on<ConnectDeviceEvent>(_onConnectDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<LoadMediaEvent>(_onLoadMedia);
    on<PlayMediaEvent>(_onPlayMedia);
    on<PauseMediaEvent>(_onPauseMedia);
    on<StopMediaEvent>(_onStopMedia);
    on<SeekMediaEvent>(_onSeekMedia);
    on<SetVolumeEvent>(_onSetVolume);
    on<SetSubtitleEvent>(_onSetSubtitle);
    on<ExtractAndSetSubtitleEvent>(_onExtractAndSetSubtitle);
    on<SessionStateChangedEvent>(_onSessionStateChanged);
    on<PositionUpdatedEvent>(_onPositionUpdated);
    on<DurationUpdatedEvent>(_onDurationUpdated);
    _listenToStreams();
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
    final previousDevice = state.activeDevice;
    emit(
      state.copyWith(
        connectionStatus: StateStatus.loading,
        activeDevice: event.device,
        connectionError: null,
      ),
    );
    try {
      await _castService.connect(event.device);
      await _db.setLastCastedDevice(
        deviceId: event.device.id,
        deviceName: event.device.name,
        protocol: event.device.protocol.name,
      );
      emit(state.copyWith(connectionStatus: StateStatus.loaded));
      if (state.activeMedia != null) {
        add(LoadMediaEvent(state.activeMedia!));
      }
    } catch (e) {
      emit(
        state.copyWith(
          connectionStatus: StateStatus.error,
          connectionError: e.toString(),
          activeDevice: previousDevice,
        ),
      );
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDeviceEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.disconnect();
      _isLoadingMedia = false;
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
    _isLoadingMedia = true;

    emit(
      state.copyWith(
        playbackStatus: StateStatus.loading,
        activeMedia: event.media,
        playbackError: null,
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
      await _castService.loadMedia(event.media);
      emit(state.copyWith(playbackStatus: StateStatus.loaded));

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
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    }
  }

  Future<void> _onStopMedia(
    StopMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.stop();
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    }
  }

  Future<void> _onSeekMedia(
    SeekMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.seek(event.position);
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
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
            // Extract (or reuse cached) subtitle
            final result = await extractionService.extractSubtitle(
              sourcePath: media.uri,
              stream: matchingStream,
            );

            if (!result.isSuccess) {
              emit(
                state.copyWith(
                  playbackError: result.error?.message ?? 'Extraction failed',
                ),
              );
              return;
            }

            final extractedPath = result.outputPath!;

            // Update the subtitle URL to point to the extracted file
            subtitle = subtitle.copyWith(url: extractedPath);
          }
        }
      }
      print("Setting subtitle: ${subtitle?.url ?? 'None'}");
      await _castService.setSubtitle(subtitle);
      emit(state.copyWith(activeSubtitle: subtitle));
    } catch (e) {
      emit(state.copyWith(playbackError: e.toString()));
    }
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

  Future<void> _onExtractAndSetSubtitle(
    ExtractAndSetSubtitleEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    final media = state.activeMedia;
    if (media == null) return;

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
          state.copyWith(playbackError: 'Subtitle stream not found in video'),
        );
        return;
      }

      // Extract (or reuse cached) subtitle
      final result = await extractionService.extractSubtitle(
        sourcePath: sourcePath,
        stream: matchingStream,
      );

      if (!result.isSuccess) {
        emit(
          state.copyWith(
            playbackError: result.error?.message ?? 'Extraction failed',
          ),
        );
        return;
      }

      final extractedPath = result.outputPath!;

      // Update the subtitle track with the extracted file path
      final updatedSubtitle = event.subtitle.copyWith(
        url: extractedPath,
        format: event.subtitle.format,
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
        await _castService.loadMedia(updatedMedia);
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
      emit(state.copyWith(playbackError: e.toString()));
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
      if (state.connectionStatus == StateStatus.loading) {
        emit(state.copyWith(sessionState: event.newState));
        return;
      }
      emit(const CastSessionState());
      return;
    }

    emit(state.copyWith(sessionState: event.newState));
    _checkpointHistory(
      completed: event.newState == PureCastSessionState.completed,
    );
  }

  void _checkpointHistory({bool completed = false}) {
    final media = state.activeMedia;
    if (media != null) {
      _historyRepo.recordHistoryCheckpoint(
        media: media,
        position: state.position,
        duration: state.duration,
        completed: completed,
      );
    }
  }

  void _onPositionUpdated(
    PositionUpdatedEvent event,
    Emitter<CastSessionState> emit,
  ) {
    emit(state.copyWith(position: event.position));
  }

  void _onDurationUpdated(
    DurationUpdatedEvent event,
    Emitter<CastSessionState> emit,
  ) {
    emit(state.copyWith(duration: event.duration));
  }

  @override
  Future<void> close() {
    _isLoadingMedia = false;
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    return super.close();
  }
}
