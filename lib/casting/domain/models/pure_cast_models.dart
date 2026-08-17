/// Supported casting protocols in Pure Cast.
enum PureCastProtocol { chromecast, dlna }

/// Types of media supported by Pure Cast.
enum PureCastMediaType { video, audio, hls, mp4, mkv }

/// Session state of the cast engine.
enum PureCastSessionState {
  disconnected,
  connecting,
  connected,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

/// Device capabilities exposed to the UI.
class PureCastCapabilities {
  final bool canPlay;
  final bool canPause;
  final bool canSeek;
  final bool canSetVolume;
  final bool canChangeAudioTrack;
  final bool canChangeSubtitle;
  final bool canQueue;

  const PureCastCapabilities({
    this.canPlay = true,
    this.canPause = true,
    this.canSeek = true,
    this.canSetVolume = true,
    this.canChangeAudioTrack = false,
    this.canChangeSubtitle = false,
    this.canQueue = false,
  });

  factory PureCastCapabilities.forProtocol(PureCastProtocol protocol) {
    switch (protocol) {
      case PureCastProtocol.chromecast:
        return const PureCastCapabilities(
          canPlay: true,
          canPause: true,
          canSeek: true,
          canSetVolume: true,
          canChangeAudioTrack: true,
          canChangeSubtitle: true,
          canQueue: true,
        );
      case PureCastProtocol.dlna:
        return const PureCastCapabilities(
          canPlay: true,
          canPause: true,
          canSeek: true,
          canSetVolume: true,
          canChangeAudioTrack: false,
          canChangeSubtitle: false,
          canQueue: false,
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PureCastCapabilities &&
          canPlay == other.canPlay &&
          canPause == other.canPause &&
          canSeek == other.canSeek &&
          canSetVolume == other.canSetVolume &&
          canChangeAudioTrack == other.canChangeAudioTrack &&
          canChangeSubtitle == other.canChangeSubtitle &&
          canQueue == other.canQueue;

  @override
  int get hashCode => Object.hash(
        canPlay,
        canPause,
        canSeek,
        canSetVolume,
        canChangeAudioTrack,
        canChangeSubtitle,
        canQueue,
      );
}

/// Unified Cast Device domain model.
class PureCastDevice {
  final String id;
  final String name;
  final PureCastProtocol protocol;
  final String host;
  final int port;
  final PureCastCapabilities capabilities;

  const PureCastDevice({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.capabilities,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PureCastDevice &&
          id == other.id &&
          name == other.name &&
          protocol == other.protocol &&
          host == other.host &&
          port == other.port &&
          capabilities == other.capabilities;

  @override
  int get hashCode => Object.hash(id, name, protocol, host, port, capabilities);
}

/// Media subtitle track domain model.
class PureCastSubtitleTrack {
  final String id;
  final String label;
  final String language;
  final String url;

  const PureCastSubtitleTrack({
    required this.id,
    required this.label,
    required this.language,
    required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PureCastSubtitleTrack &&
          id == other.id &&
          label == other.label &&
          language == other.language &&
          url == other.url;

  @override
  int get hashCode => Object.hash(id, label, language, url);
}

/// Media item domain model.
class PureCastMedia {
  final String uri;
  final PureCastMediaType type;
  final String title;
  final String? thumbnailUrl;
  final Duration? duration;
  final bool isLocalFile;
  final List<PureCastSubtitleTrack> subtitles;

  const PureCastMedia({
    required this.uri,
    required this.type,
    required this.title,
    this.thumbnailUrl,
    this.duration,
    this.isLocalFile = false,
    this.subtitles = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PureCastMedia &&
          uri == other.uri &&
          type == other.type &&
          title == other.title &&
          thumbnailUrl == other.thumbnailUrl &&
          duration == other.duration &&
          isLocalFile == other.isLocalFile;

  @override
  int get hashCode => Object.hash(uri, type, title, thumbnailUrl, duration, isLocalFile);
}

/// Domain exception for casting failures.
class PureCastException implements Exception {
  final String message;
  final Object? originalError;

  const PureCastException(this.message, [this.originalError]);

  @override
  String toString() => 'PureCastException: $message';
}
