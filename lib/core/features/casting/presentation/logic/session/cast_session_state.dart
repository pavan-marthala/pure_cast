import 'package:equatable/equatable.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

class CastSessionBlocState extends Equatable {
  final PureCastSessionState status;
  final PureCastDevice? activeDevice;
  final PureCastMedia? activeMedia;
  final Duration position;
  final Duration duration;
  final double volume;
  final String? errorMessage;

  const CastSessionBlocState({
    this.status = PureCastSessionState.disconnected,
    this.activeDevice,
    this.activeMedia,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.errorMessage,
  });

  bool get isConnected => status != PureCastSessionState.disconnected;
  bool get isPlaying => status == PureCastSessionState.playing;
  bool get isPaused => status == PureCastSessionState.paused;
  bool get isBuffering => status == PureCastSessionState.buffering;

  CastSessionBlocState copyWith({
    PureCastSessionState? status,
    PureCastDevice? activeDevice,
    PureCastMedia? activeMedia,
    Duration? position,
    Duration? duration,
    double? volume,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CastSessionBlocState(
      status: status ?? this.status,
      activeDevice: activeDevice ?? this.activeDevice,
      activeMedia: activeMedia ?? this.activeMedia,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeDevice,
    activeMedia,
    position,
    duration,
    volume,
    errorMessage,
  ];
}
