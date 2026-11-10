import 'dart:async';
import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/database/app_database.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/utils/state_status.dart';
import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';

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
      await _castService.setSubtitle(event.subtitle);
      emit(state.copyWith(activeSubtitle: event.subtitle));
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
