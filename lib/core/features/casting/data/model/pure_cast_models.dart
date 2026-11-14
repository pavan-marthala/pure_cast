import 'dart:typed_data';

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

/// Audio track of the media currently loaded by the cast engine.
///
/// [index] is the 0-based index among audio streams (the `N` in
/// `0:a:N`), i.e. the value accepted by the live audio switching API.
class PureCastAudioTrack {
  final int index;
  final String language;
  final String codec;
  final int channels;
  final bool isDefault;

  const PureCastAudioTrack({
    required this.index,
    this.language = '',
    this.codec = 'unknown',
    this.channels = 2,
    this.isDefault = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PureCastAudioTrack &&
          index == other.index &&
          language == other.language &&
          codec == other.codec &&
          channels == other.channels &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(index, language, codec, channels, isDefault);

  @override
  String toString() =>
      'PureCastAudioTrack(index: $index, language: $language, codec: $codec, '
      'channels: $channels, isDefault: $isDefault)';
}

/// Media subtitle track domain model.
class PureCastSubtitleTrack {
  final String id;
  final String label;
  final String language;
  final String url;
  final String format;

  const PureCastSubtitleTrack({
    required this.id,
    required this.label,
    required this.language,
    required this.url,
    this.format = 'vtt',
  });

  PureCastSubtitleTrack copyWith({
    String? id,
    String? label,
    String? language,
    String? url,
    String? format,
  }) {
    return PureCastSubtitleTrack(
      id: id ?? this.id,
      label: label ?? this.label,
      language: language ?? this.language,
      url: url ?? this.url,
      format: format ?? this.format,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PureCastSubtitleTrack &&
          id == other.id &&
          label == other.label &&
          language == other.language &&
          url == other.url &&
          format == other.format;

  @override
  int get hashCode => Object.hash(id, label, language, url, format);
}

/// Media item domain model.
class PureCastMedia {
  final String uri;
  final PureCastMediaType type;
  final String title;
  final String? thumbnailUrl;
  final Uint8List? thumbnailBytes;
  final Duration? duration;
  final bool isLocalFile;
  final List<PureCastSubtitleTrack> subtitles;
  final PureCastSubtitleTrack? defaultSubtitle;

  const PureCastMedia({
    required this.uri,
    required this.type,
    required this.title,
    this.thumbnailUrl,
    this.thumbnailBytes,
    this.duration,
    this.isLocalFile = false,
    this.subtitles = const [],
    this.defaultSubtitle,
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
  factory PureCastMedia.skeleton() {
    return PureCastMedia(uri: 'kjgd', type: .video, title: 'TEmhcd.mp4');
  }

  PureCastMedia copyWith({
    String? uri,
    PureCastMediaType? type,
    String? title,
    String? thumbnailUrl,
    Uint8List? thumbnailBytes,
    Duration? duration,
    bool? isLocalFile,
    List<PureCastSubtitleTrack>? subtitles,
    PureCastSubtitleTrack? defaultSubtitle,
  }) {
    return PureCastMedia(
      uri: uri ?? this.uri,
      type: type ?? this.type,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      duration: duration ?? this.duration,
      isLocalFile: isLocalFile ?? this.isLocalFile,
      subtitles: subtitles ?? this.subtitles,
      defaultSubtitle: defaultSubtitle ?? this.defaultSubtitle,
    );
  }

  @override
  String toString() {
    return 'PureCastMedia('
        'uri: $uri, '
        'type: $type, '
        'title: $title, '
        'thumbnailUrl: $thumbnailUrl, '
        'thumbnailBytes: ${thumbnailBytes != null ? '<${thumbnailBytes!.lengthInBytes} bytes>' : null}, '
        'duration: $duration, '
        'isLocalFile: $isLocalFile, '
        'subtitles: $subtitles'
        ')';
  }
}

/// Domain exception for casting failures.
class PureCastException implements Exception {
  final String message;
  final Object? originalError;

  const PureCastException(this.message, [this.originalError]);

  @override
  String toString() => 'PureCastException: $message';
}
