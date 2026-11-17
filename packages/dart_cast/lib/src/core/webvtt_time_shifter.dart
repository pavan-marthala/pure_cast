/// Shifts every cue of a full-timeline WebVTT document onto a virtual timeline
/// that starts at a later point of the source file.
///
/// Live MKV casting restarts the stream at a source offset and the receiver
/// always starts its clock at zero. A full-timeline subtitle therefore has to
/// be moved earlier by the same offset, so the cue that belongs to source time
/// `T` is shown at receiver time `0`.
///
/// [shift] is a single linear pass over the document. It never re-reads or
/// rewrites the same line twice and uses no backtracking-prone regular
/// expressions, so multi-megabyte files are handled in one sweep.
abstract final class WebVttTimeShifter {
  /// Returns [vtt] with every cue moved earlier by [offset].
  ///
  /// * A zero [offset] returns [vtt] unchanged (identity, byte for byte).
  /// * A negative [offset] throws an [ArgumentError].
  /// * A leading byte-order mark is accepted and removed, and `LF`, `CRLF`
  ///   and `CR` line endings are accepted; the result always uses `LF`.
  /// * The `WEBVTT` line and any header text lines are kept. `NOTE`, `STYLE`
  ///   and `REGION` blocks are kept verbatim.
  /// * Any `X-TIMESTAMP-MAP` line is dropped: it maps receiver timestamps to a
  ///   transport stream clock, which would mis-time the shifted cues.
  /// * A cue is shifted with `start' = start - offset` and
  ///   `end' = end - offset`. A cue whose `end'` is zero or negative is removed
  ///   together with its identifier line and payload. A cue whose `start'` is
  ///   negative is clamped to `00:00:00.000`.
  /// * Timestamps may be written as `hh:mm:ss.mmm` or `mm:ss.mmm` (hours may
  ///   have more than two digits); the output is always `hh:mm:ss.mmm`.
  /// * Settings after the end timestamp are preserved exactly.
  /// * A cue block whose timing line cannot be parsed is dropped entirely —
  ///   a mis-timed cue is worse than a missing one. Malformed blocks are not
  ///   counted or reported.
  /// * Runs of blank lines between blocks are normalised to a single blank
  ///   line and the result ends with a single newline.
  ///
  /// Throws a [FormatException] when [vtt] does not start with `WEBVTT` after
  /// an optional byte-order mark.
  static String shift(String vtt, Duration offset) {
    if (offset.isNegative) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
    if (offset == Duration.zero) return vtt;

    var text = vtt;
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    if (!text.startsWith('WEBVTT')) {
      throw const FormatException('Not a WebVTT document');
    }

    final offsetMs = offset.inMilliseconds;
    final blocks = _splitBlocks(text);
    final out = StringBuffer();
    var headerWritten = false;

    for (final block in blocks) {
      if (block.isEmpty) continue;

      if (!headerWritten) {
        // Everything before the first blank line is the header. The blank
        // line itself is re-created below, so header text stays verbatim.
        final header = <String>[];
        for (final line in block) {
          if (_isTimestampMap(line)) continue;
          header.add(line);
        }
        out.write(header.join('\n'));
        headerWritten = true;
        continue;
      }

      if (_isNonCueBlock(block.first)) {
        out.write('\n\n');
        out.write(block.join('\n'));
        continue;
      }

      final cue = _shiftCue(block, offsetMs);
      if (cue == null) continue;
      out.write('\n\n');
      out.write(cue);
    }

    out.write('\n');
    return out.toString();
  }

  /// Splits [text] into blocks separated by blank lines.
  static List<List<String>> _splitBlocks(String text) {
    final blocks = <List<String>>[];
    var current = <String>[];
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty) {
        if (current.isNotEmpty) {
          blocks.add(current);
          current = <String>[];
        }
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) blocks.add(current);
    return blocks;
  }

  /// Whether [line] is an `X-TIMESTAMP-MAP` header line.
  static bool _isTimestampMap(String line) {
    final trimmed = line.trimLeft();
    return trimmed.length >= 15 &&
        trimmed.substring(0, 15).toUpperCase() == 'X-TIMESTAMP-MAP';
  }

  /// Whether a block starting with [first] is a NOTE, STYLE or REGION block.
  static bool _isNonCueBlock(String first) {
    if (first == 'NOTE' || first == 'STYLE' || first == 'REGION') return true;
    return first.startsWith('NOTE ') || first.startsWith('NOTE\t');
  }

  /// Returns the shifted cue block, or null when it must be dropped.
  static String? _shiftCue(List<String> block, int offsetMs) {
    var timingIndex = _parseTiming(block.first) != null ? 0 : -1;
    if (timingIndex == -1 && block.length > 1) {
      if (_parseTiming(block[1]) != null) timingIndex = 1;
    }
    if (timingIndex == -1) return null;

    final timing = _parseTiming(block[timingIndex])!;
    final shiftedEnd = timing.endMs - offsetMs;
    if (shiftedEnd <= 0) return null;
    final shiftedStart =
        timing.startMs - offsetMs < 0 ? 0 : timing.startMs - offsetMs;

    final lines = List<String>.of(block);
    lines[timingIndex] =
        '${_format(shiftedStart)} --> ${_format(shiftedEnd)}'
        '${timing.settings}';
    return lines.join('\n');
  }

  /// Parses `<start> --> <end>[ settings]`, or returns null when malformed.
  static ({int startMs, int endMs, String settings})? _parseTiming(
    String line,
  ) {
    final arrow = line.indexOf(' --> ');
    if (arrow <= 0) return null;

    final startMs = _parseTimestamp(line.substring(0, arrow));
    if (startMs == null) return null;

    final rest = line.substring(arrow + 5);
    final space = rest.indexOf(' ');
    final endToken = space == -1 ? rest : rest.substring(0, space);
    final endMs = _parseTimestamp(endToken);
    if (endMs == null) return null;

    return (
      startMs: startMs,
      endMs: endMs,
      settings: space == -1 ? '' : rest.substring(space),
    );
  }

  /// Parses `hh:mm:ss.mmm` or `mm:ss.mmm` into milliseconds.
  static int? _parseTimestamp(String value) {
    final parts = value.split(':');
    if (parts.length != 2 && parts.length != 3) return null;

    final hasHours = parts.length == 3;
    final hoursPart = hasHours ? parts[0] : '0';
    final minutesPart = parts[parts.length - 2];
    final secondsPart = parts[parts.length - 1];

    if (hasHours && (hoursPart.length < 2 || !_isDigits(hoursPart))) {
      return null;
    }
    if (minutesPart.length != 2 || !_isDigits(minutesPart)) return null;

    final dot = secondsPart.indexOf('.');
    if (dot != 2) return null;
    final secondsDigits = secondsPart.substring(0, dot);
    final millisDigits = secondsPart.substring(dot + 1);
    if (!_isDigits(secondsDigits) || millisDigits.length != 3) return null;
    if (!_isDigits(millisDigits)) return null;

    final hours = int.parse(hoursPart);
    final minutes = int.parse(minutesPart);
    final seconds = int.parse(secondsDigits);
    final millis = int.parse(millisDigits);
    if (minutes > 59 || seconds > 59 || millis > 999) return null;

    return ((hours * 3600 + minutes * 60 + seconds) * 1000) + millis;
  }

  /// Formats milliseconds as `hh:mm:ss.mmm` (hours may exceed two digits).
  static String _format(int millis) {
    final hours = millis ~/ 3600000;
    final minutes = (millis ~/ 60000) % 60;
    final seconds = (millis ~/ 1000) % 60;
    final ms = millis % 1000;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }

  /// Whether every character of [value] is an ASCII digit.
  static bool _isDigits(String value) {
    if (value.isEmpty) return false;
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) return false;
    }
    return true;
  }
}
