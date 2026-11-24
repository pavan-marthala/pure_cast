/// One WebVTT media segment produced by [WebVttHlsSegmenter].
class WebVttHlsSegment {
  /// File name of the segment, for example `sub_00000.vtt`.
  final String name;

  /// Full WebVTT body written to the segment.
  final String content;

  /// Duration reported by the segment's `EXTINF`.
  final double durationSeconds;

  const WebVttHlsSegment({
    required this.name,
    required this.content,
    required this.durationSeconds,
  });
}

/// A WebVTT HLS playlist plus the segments it references.
class WebVttHlsResult {
  /// Media playlist text with a valid `EXT-X-TARGETDURATION`.
  final String playlist;

  /// Segments in playback order.
  final List<WebVttHlsSegment> segments;

  /// Integer target duration advertised by [playlist].
  final int targetDuration;

  const WebVttHlsResult({
    required this.playlist,
    required this.segments,
    required this.targetDuration,
  });
}

/// Splits a full-timeline WebVTT file into HLS subtitle segments.
///
/// The previous AirPlay path wrapped a whole VTT file in a one-segment
/// playlist with `EXT-X-TARGETDURATION:99999`, which is outside the range HLS
/// permits (and that Apple receivers may reject). This segmenter produces
/// several short segments and an accurate target duration instead.
///
/// Cue timestamps are kept on the media timeline: HLS subtitle cues are
/// interpreted relative to the start of the presentation, not the segment.
class WebVttHlsSegmenter {
  WebVttHlsSegmenter._();

  /// Default HLS subtitle segment length in seconds.
  static const double defaultSegmentSeconds = 6.0;

  /// Segments [webVtt] for a presentation lasting [durationSeconds].
  ///
  /// When [durationSeconds] is null or zero, the last cue end is used. The
  /// target duration is the segment length rounded up, so a 6 s segment never
  /// advertises the invalid `99999` value.
  static WebVttHlsResult segment(
    String webVtt, {
    double? durationSeconds,
    double segmentSeconds = defaultSegmentSeconds,
    String fileNamePrefix = 'sub',
  }) {
    if (segmentSeconds <= 0) {
      throw ArgumentError.value(
        segmentSeconds,
        'segmentSeconds',
        'must be positive',
      );
    }

    final normalized = webVtt.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final body =
        normalized.startsWith('\uFEFF') ? normalized.substring(1) : normalized;
    if (!body.startsWith('WEBVTT')) {
      throw const FormatException('Subtitle source is not a WebVTT file');
    }

    final blocks = body.split(RegExp(r'\n{2,}'));
    final header = StringBuffer(blocks.first.trimRight());
    final cues = <_Cue>[];
    for (final block in blocks.skip(1)) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;
      final cue = _Cue.tryParse(trimmed);
      if (cue != null) {
        cues.add(cue);
      } else if (cues.isEmpty) {
        // STYLE/REGION/NOTE blocks before the first cue belong to the header.
        header
          ..writeln()
          ..writeln(trimmed);
      }
    }

    final lastCueEnd =
        cues.isEmpty
            ? 0.0
            : cues.map((c) => c.endSeconds).reduce((a, b) => a > b ? a : b);
    final duration =
        (durationSeconds != null && durationSeconds > 0)
            ? durationSeconds
            : lastCueEnd;
    final targetDuration = segmentSeconds.ceil();

    final segmentCount = duration <= 0 ? 1 : (duration / segmentSeconds).ceil();
    final buckets = List<List<_Cue>>.generate(segmentCount, (_) => <_Cue>[]);
    for (final cue in cues) {
      var index = (cue.startSeconds / segmentSeconds).floor();
      if (index < 0) index = 0;
      if (index >= segmentCount) index = segmentCount - 1;
      buckets[index].add(cue);
    }

    final segments = <WebVttHlsSegment>[];
    for (var i = 0; i < segmentCount; i++) {
      final remaining = duration > 0 ? duration - i * segmentSeconds : -1.0;
      final segmentDuration =
          remaining > 0
              ? (remaining < segmentSeconds ? remaining : segmentSeconds)
              : segmentSeconds;
      final buffer = StringBuffer(header.toString().trimRight());
      if (buckets[i].isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
        for (var j = 0; j < buckets[i].length; j++) {
          if (j > 0) buffer.writeln();
          buffer.writeln(buckets[i][j].raw.trimRight());
        }
      } else {
        buffer.writeln();
        buffer.writeln();
      }
      final name = '${fileNamePrefix}_${i.toString().padLeft(5, '0')}.vtt';
      segments.add(
        WebVttHlsSegment(
          name: name,
          content: '${buffer.toString().trimRight()}\n',
          durationSeconds: segmentDuration,
        ),
      );
    }

    final playlist =
        StringBuffer('#EXTM3U\n')
          ..writeln('#EXT-X-VERSION:3')
          ..writeln('#EXT-X-PLAYLIST-TYPE:VOD')
          ..writeln('#EXT-X-TARGETDURATION:$targetDuration')
          ..writeln('#EXT-X-MEDIA-SEQUENCE:0');
    for (final segment in segments) {
      playlist.writeln(
        '#EXTINF:${segment.durationSeconds.toStringAsFixed(3)},',
      );
      playlist.writeln(segment.name);
    }
    playlist.writeln('#EXT-X-ENDLIST');

    return WebVttHlsResult(
      playlist: playlist.toString(),
      segments: segments,
      targetDuration: targetDuration,
    );
  }
}

class _Cue {
  final String raw;
  final double startSeconds;
  final double endSeconds;

  const _Cue({
    required this.raw,
    required this.startSeconds,
    required this.endSeconds,
  });

  static final RegExp _timestamp = RegExp(
    r'(?:(\d{1,2}):)?(\d{1,2}):(\d{2})\.(\d{3})',
  );

  static _Cue? tryParse(String block) {
    final timingLine = block
        .split('\n')
        .firstWhere((line) => line.contains('-->'), orElse: () => '');
    if (timingLine.isEmpty) return null;
    final matches = _timestamp.allMatches(timingLine).toList();
    if (matches.length < 2) return null;
    return _Cue(
      raw: block,
      startSeconds: _toSeconds(matches[0]),
      endSeconds: _toSeconds(matches[1]),
    );
  }

  static double _toSeconds(RegExpMatch match) {
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final millis = int.parse(match.group(4)!);
    return hours * 3600 + minutes * 60 + seconds + millis / 1000.0;
  }
}
