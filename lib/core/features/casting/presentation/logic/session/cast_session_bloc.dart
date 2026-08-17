import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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
  StreamSubscription<PureCastSessionState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  CastSessionBloc(this._castService, this._historyRepo)
    : super(const CastSessionState()) {
    on<ConnectDeviceEvent>(_onConnectDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<LoadMediaEvent>(_onLoadMedia);
    on<PlayMediaEvent>(_onPlayMedia);
    on<PauseMediaEvent>(_onPauseMedia);
    on<StopMediaEvent>(_onStopMedia);
    on<SeekMediaEvent>(_onSeekMedia);
    on<SetVolumeEvent>(_onSetVolume);
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
    emit(
      state.copyWith(
        sessionStatus: StateStatus.loading,
        activeDevice: event.device,
        sessionError: null,
      ),
    );
    try {
      await _castService.connect(event.device);
      emit(state.copyWith(sessionStatus: StateStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          sessionStatus: StateStatus.error,
          sessionError: e.toString(),
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
      emit(const CastSessionState());
    } catch (e) {
      emit(state.copyWith(sessionError: e.toString()));
    }
  }

  Future<void> _onLoadMedia(
    LoadMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    emit(
      state.copyWith(
        playbackStatus: StateStatus.loading,
        activeMedia: event.media,
        playbackError: null,
      ),
    );
    try {
      await _castService.loadMedia(event.media);
      emit(state.copyWith(playbackStatus: StateStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          playbackStatus: StateStatus.error,
          playbackError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPlayMedia(
    PlayMediaEvent event,
    Emitter<CastSessionState> emit,
  ) async {
    try {
      await _castService.play();
    } catch (e) {
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

  void _onSessionStateChanged(
    SessionStateChangedEvent event,
    Emitter<CastSessionState> emit,
  ) {
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
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    return super.close();
  }
}
