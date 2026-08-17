import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'cast_session_event.dart';
import 'cast_session_state.dart';

@injectable
class CastSessionBloc extends Bloc<CastSessionEvent, CastSessionBlocState> {
  final ICastService _castService;
  StreamSubscription<PureCastSessionState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  CastSessionBloc(this._castService) : super(const CastSessionBlocState()) {
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
    Emitter<CastSessionBlocState> emit,
  ) async {
    emit(state.copyWith(
      status: PureCastSessionState.connecting,
      activeDevice: event.device,
      clearError: true,
    ));
    try {
      await _castService.connect(event.device);
    } catch (e) {
      emit(state.copyWith(
        status: PureCastSessionState.disconnected,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDeviceEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    try {
      await _castService.disconnect();
      emit(const CastSessionBlocState());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMedia(
    LoadMediaEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    emit(state.copyWith(
      status: PureCastSessionState.loading,
      activeMedia: event.media,
      clearError: true,
    ));
    try {
      await _castService.loadMedia(event.media);
    } catch (e) {
      emit(state.copyWith(
        status: PureCastSessionState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPlayMedia(
    PlayMediaEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    try {
      await _castService.play();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onPauseMedia(
    PauseMediaEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    try {
      await _castService.pause();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onStopMedia(
    StopMediaEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    try {
      await _castService.stop();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSeekMedia(
    SeekMediaEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    try {
      await _castService.seek(event.position);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSetVolume(
    SetVolumeEvent event,
    Emitter<CastSessionBlocState> emit,
  ) async {
    try {
      await _castService.setVolume(event.volume);
      emit(state.copyWith(volume: event.volume));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onSessionStateChanged(
    SessionStateChangedEvent event,
    Emitter<CastSessionBlocState> emit,
  ) {
    emit(state.copyWith(status: event.newState));
  }

  void _onPositionUpdated(
    PositionUpdatedEvent event,
    Emitter<CastSessionBlocState> emit,
  ) {
    emit(state.copyWith(position: event.position));
  }

  void _onDurationUpdated(
    DurationUpdatedEvent event,
    Emitter<CastSessionBlocState> emit,
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
