import 'dart:convert';

/// Maximum number of response-body bytes included in an error preview.
const int maxAirPlayResponsePreviewBytes = 256;

/// Returns a bounded, escaped preview of an AirPlay response body.
///
/// AirPlay error bodies are sometimes binary plists, so the preview is decoded
/// with tolerant UTF-8 and control characters are escaped. The preview never
/// contains more than [maxAirPlayResponsePreviewBytes] of body content; when
/// the body is longer, the original byte count is appended so a truncated
/// preview is obvious in logs.
String formatAirPlayResponsePreview(List<int> body) {
  if (body.isEmpty) return '';

  final truncated = body.length > maxAirPlayResponsePreviewBytes;
  final bytes =
      truncated ? body.sublist(0, maxAirPlayResponsePreviewBytes) : body;
  final text = utf8.decode(bytes, allowMalformed: true);
  final escaped = _escapeControlCharacters(text);

  return truncated ? '$escaped… (${body.length} bytes)' : escaped;
}

String _escapeControlCharacters(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune == 0x0A) {
      buffer.write(r'\n');
    } else if (rune == 0x0D) {
      buffer.write(r'\r');
    } else if (rune == 0x09) {
      buffer.write(r'\t');
    } else if (rune < 0x20 || rune == 0x7F) {
      buffer.write('\\x${rune.toRadixString(16).padLeft(2, '0')}');
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
