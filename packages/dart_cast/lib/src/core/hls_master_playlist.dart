/// One audio rendition in an HLS master playlist.
class HlsAudioRendition {
  /// `NAME` attribute shown to the viewer.
  final String name;

  /// BCP-47 language tag (`LANGUAGE`), when known.
  final String? language;

  /// Relative or proxy URL of the audio media playlist.
  final String uri;

  /// Whether this rendition is the default one.
  final bool isDefault;

  /// Channel count, used for the `CHANNELS` attribute.
  final int channels;

  const HlsAudioRendition({
    required this.name,
    required this.uri,
    this.language,
    this.isDefault = false,
    this.channels = 2,
  });
}

/// One subtitle rendition in an HLS master playlist.
class HlsSubtitleRendition {
  /// `NAME` attribute shown to the viewer.
  final String name;

  /// BCP-47 language tag (`LANGUAGE`), when known.
  final String? language;

  /// Relative or proxy URL of the WebVTT media playlist.
  final String uri;

  /// Whether this rendition is the default one.
  final bool isDefault;

  const HlsSubtitleRendition({
    required this.name,
    required this.uri,
    this.language,
    this.isDefault = false,
  });
}

/// Composes a master playlist for a locally prepared VOD HLS directory.
///
/// FFmpeg writes the variant streams; this writer adds the exact
/// `EXT-X-MEDIA` groups AirPlay needs, including `DEFAULT`/`AUTOSELECT`,
/// language tags, and a `SUBTITLES` attribute on the variant when a subtitle
/// group exists.
class HlsMasterPlaylistWriter {
  HlsMasterPlaylistWriter._();

  /// Default bandwidth advertised for the prepared variant, in bits/second.
  static const int defaultBandwidth = 5000000;

  /// Builds the playlist text.
  ///
  /// [videoUri] points at the video media playlist (for example
  /// `video.m3u8`). [audio] and [subtitles] become rendition groups. The
  /// first subtitle is marked default when [subtitleDefaultIndex] is 0.
  static String build({
    required String videoUri,
    int bandwidth = defaultBandwidth,
    List<HlsAudioRendition> audio = const [],
    List<HlsSubtitleRendition> subtitles = const [],
    String audioGroupId = 'aud',
    String subtitleGroupId = 'subs',
    int? width,
    int? height,
    String codecs = 'avc1.640028,mp4a.40.2',
  }) {
    final buffer = StringBuffer('#EXTM3U\n');
    buffer.writeln('#EXT-X-VERSION:3');
    buffer.writeln('#EXT-X-INDEPENDENT-SEGMENTS');

    for (final rendition in audio) {
      final attributes = <String>[
        'TYPE=AUDIO',
        'GROUP-ID="${_escape(audioGroupId)}"',
        'NAME="${_escape(rendition.name)}"',
        'DEFAULT=${rendition.isDefault ? 'YES' : 'NO'}',
        'AUTOSELECT=${rendition.isDefault ? 'YES' : 'NO'}',
        if (rendition.language != null && rendition.language!.isNotEmpty)
          'LANGUAGE="${_escape(rendition.language!)}"',
        'CHANNELS="${rendition.channels}"',
        'URI="${_escape(rendition.uri)}"',
      ];
      buffer.writeln('#EXT-X-MEDIA:${attributes.join(',')}');
    }

    final hasDefaultSubtitle = subtitles.any((s) => s.isDefault);
    for (final rendition in subtitles) {
      final isDefault = hasDefaultSubtitle ? rendition.isDefault : false;
      final attributes = <String>[
        'TYPE=SUBTITLES',
        'GROUP-ID="${_escape(subtitleGroupId)}"',
        'NAME="${_escape(rendition.name)}"',
        'DEFAULT=${isDefault ? 'YES' : 'NO'}',
        'AUTOSELECT=${isDefault ? 'YES' : 'NO'}',
        if (rendition.language != null && rendition.language!.isNotEmpty)
          'LANGUAGE="${_escape(rendition.language!)}"',
        'URI="${_escape(rendition.uri)}"',
      ];
      buffer.writeln('#EXT-X-MEDIA:${attributes.join(',')}');
    }

    final streamAttributes = <String>['BANDWIDTH=$bandwidth'];
    if (width != null && height != null) {
      streamAttributes.add('RESOLUTION=${width}x$height');
    }
    if (audio.isNotEmpty) {
      streamAttributes.add('AUDIO="${_escape(audioGroupId)}"');
    }
    if (subtitles.isNotEmpty) {
      streamAttributes.add('SUBTITLES="${_escape(subtitleGroupId)}"');
    }
    if (codecs.isNotEmpty) {
      streamAttributes.add('CODECS="${_escape(codecs)}"');
    }

    buffer.writeln('#EXT-X-STREAM-INF:${streamAttributes.join(',')}');
    buffer.writeln(videoUri);

    return buffer.toString();
  }

  /// Backslash-escapes quotes in an attribute value.
  static String _escape(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll('"', r'\"');
}
