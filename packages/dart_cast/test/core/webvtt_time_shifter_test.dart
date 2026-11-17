import 'package:dart_cast/src/core/webvtt_time_shifter.dart';
import 'package:test/test.dart';

String _doc(List<String> lines) => '${lines.join('\n')}\n';

String _stamp(int seconds) {
  final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$secs.000';
}

void main() {
  group('WebVttTimeShifter.shift', () {
    test('a zero offset is an identity, byte for byte', () {
      const doc = '\uFEFFWEBVTT\r\n\r\n00:00:10.000 --> 00:00:11.000\r\nhi\r\n';

      expect(WebVttTimeShifter.shift(doc, Duration.zero), doc);
    });

    test('a negative offset throws an ArgumentError', () {
      expect(
        () => WebVttTimeShifter.shift('WEBVTT\n', const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('keeps the header and NOTE/STYLE/REGION blocks, drops the '
        'timestamp map', () {
      final input = _doc([
        'WEBVTT - demo',
        'Kind: captions',
        'X-TIMESTAMP-MAP=MPEGTS:900000,LOCAL:00:00:00.000',
        '',
        'NOTE a note',
        'still the note',
        '',
        'STYLE',
        '::cue { color: yellow }',
        '',
        'REGION',
        'id:fred width:40%',
        '',
        '00:01:10.000 --> 00:01:12.000',
        'hello',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 60)),
        _doc([
          'WEBVTT - demo',
          'Kind: captions',
          '',
          'NOTE a note',
          'still the note',
          '',
          'STYLE',
          '::cue { color: yellow }',
          '',
          'REGION',
          'id:fred width:40%',
          '',
          '00:00:10.000 --> 00:00:12.000',
          'hello',
        ]),
      );
    });

    test('drops a cue that ends before the offset, identifier and payload '
        'included', () {
      final input = _doc([
        'WEBVTT',
        '',
        'old-cue',
        '00:00:10.000 --> 00:00:11.999',
        'gone',
        '',
        '00:01:00.000 --> 00:01:01.000',
        'kept',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 60)),
        _doc(['WEBVTT', '', '00:00:00.000 --> 00:00:01.000', 'kept']),
      );
    });

    test('drops a cue whose shifted end is exactly zero', () {
      final input = _doc([
        'WEBVTT',
        '',
        '00:00:10.000 --> 00:01:00.000',
        'boundary',
        '',
        '00:01:00.001 --> 00:01:01.000',
        'kept',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 60)),
        _doc(['WEBVTT', '', '00:00:00.001 --> 00:00:01.000', 'kept']),
      );
    });

    test('clamps a cue straddling the offset to 00:00:00.000 and shifts '
        'its end', () {
      final input = _doc([
        'WEBVTT',
        '',
        'straddles',
        '00:00:55.000 --> 00:01:05.000',
        'across',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 60)),
        _doc([
          'WEBVTT',
          '',
          'straddles',
          '00:00:00.000 --> 00:00:05.000',
          'across',
        ]),
      );
    });

    test('shifts millisecond timestamps exactly', () {
      final input = _doc([
        'WEBVTT',
        '',
        '01:02:03.456 --> 01:02:04.789',
        'exact',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(minutes: 1)),
        _doc(['WEBVTT', '', '01:01:03.456 --> 01:01:04.789', 'exact']),
      );
    });

    test('accepts mm:ss.mmm and normalises it to hh:mm:ss.mmm', () {
      final input = _doc([
        'WEBVTT',
        '',
        '02:03.400 --> 02:04.500',
        'short form',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 60)),
        _doc(['WEBVTT', '', '00:01:03.400 --> 00:01:04.500', 'short form']),
      );
    });

    test('handles hours with more than two digits', () {
      final input = _doc([
        'WEBVTT',
        '',
        '123:45:56.789 --> 123:45:57.000',
        'long',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(hours: 1)),
        _doc(['WEBVTT', '', '122:45:56.789 --> 122:45:57.000', 'long']),
      );
    });

    test('preserves cue settings after the end timestamp', () {
      final input = _doc([
        'WEBVTT',
        '',
        '00:00:30.000 --> 00:00:32.000 '
            'line:0 position:20% align:start size:50%',
        'styled',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 10)),
        _doc([
          'WEBVTT',
          '',
          '00:00:20.000 --> 00:00:22.000 '
              'line:0 position:20% align:start size:50%',
          'styled',
        ]),
      );
    });

    test('accepts CRLF line endings and outputs LF', () {
      const input = 'WEBVTT\r\n\r\n00:00:10.000 --> 00:00:11.000\r\ncrlf\r\n';

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 5)),
        _doc(['WEBVTT', '', '00:00:05.000 --> 00:00:06.000', 'crlf']),
      );
    });

    test('accepts CR line endings and outputs LF', () {
      const input = 'WEBVTT\r\r00:00:10.000 --> 00:00:11.000\rcr\r';

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 5)),
        _doc(['WEBVTT', '', '00:00:05.000 --> 00:00:06.000', 'cr']),
      );
    });

    test('accepts a leading BOM', () {
      const input = '\uFEFFWEBVTT\n\n00:00:05.000 --> 00:00:06.000\nbom\n';

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 1)),
        _doc(['WEBVTT', '', '00:00:04.000 --> 00:00:05.000', 'bom']),
      );
    });

    test('preserves multi-line cue payloads', () {
      final input = _doc([
        'WEBVTT',
        '',
        '00:00:10.000 --> 00:00:12.000',
        'first line',
        'second <i>line</i>',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 5)),
        _doc([
          'WEBVTT',
          '',
          '00:00:05.000 --> 00:00:07.000',
          'first line',
          'second <i>line</i>',
        ]),
      );
    });

    test('normalises runs of blank lines and a trailing newline', () {
      const input =
          'WEBVTT\n\n\n\n'
          '00:00:10.000 --> 00:00:11.000\na\n\n\n\n'
          '00:00:20.000 --> 00:00:21.000\nb\n\n';

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 5)),
        _doc([
          'WEBVTT',
          '',
          '00:00:05.000 --> 00:00:06.000',
          'a',
          '',
          '00:00:15.000 --> 00:00:16.000',
          'b',
        ]),
      );
    });

    test('adds a trailing newline when the input has none', () {
      const input = 'WEBVTT\n\n00:00:10.000 --> 00:00:11.000\na';

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 5)),
        _doc(['WEBVTT', '', '00:00:05.000 --> 00:00:06.000', 'a']),
      );
    });

    test('drops malformed cue blocks while neighbours survive', () {
      final input = _doc([
        'WEBVTT',
        '',
        '00:00:10.000 --> 00:00:11.000',
        'good one',
        '',
        '00:00:12.000 -> 00:00:13.000',
        'bad arrow',
        '',
        'not a timing line at all',
        'bad block',
        '',
        '00:00:20.000 --> 00:00:21.000',
        'good two',
      ]);

      expect(
        WebVttTimeShifter.shift(input, const Duration(seconds: 5)),
        _doc([
          'WEBVTT',
          '',
          '00:00:05.000 --> 00:00:06.000',
          'good one',
          '',
          '00:00:15.000 --> 00:00:16.000',
          'good two',
        ]),
      );
    });

    test('rejects a document that is not WebVTT', () {
      expect(
        () => WebVttTimeShifter.shift(
          '1\n00:00:01,000 --> 00:00:02,000\nsrt\n',
          const Duration(seconds: 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('shifts a 5 MB document with correct cue boundaries', () {
      final buffer = StringBuffer('WEBVTT\n\n');
      var index = 0;
      while (buffer.length < 5 * 1024 * 1024) {
        final startSeconds = index * 2;
        final start =
            '${(startSeconds ~/ 3600).toString().padLeft(2, '0')}:'
            '${((startSeconds ~/ 60) % 60).toString().padLeft(2, '0')}:'
            '${(startSeconds % 60).toString().padLeft(2, '0')}.000';
        final endSeconds = startSeconds + 1;
        final end =
            '${(endSeconds ~/ 3600).toString().padLeft(2, '0')}:'
            '${((endSeconds ~/ 60) % 60).toString().padLeft(2, '0')}:'
            '${(endSeconds % 60).toString().padLeft(2, '0')}.000';
        buffer.write('$start --> $end\nline $index\n\n');
        index++;
      }
      final input = buffer.toString();
      expect(input.length, greaterThanOrEqualTo(5 * 1024 * 1024));
      final cueCount = index;

      // Wall-clock timing is deliberately not asserted: parallel test
      // isolates make elapsed-time limits flaky. The shifted cue boundaries
      // are the assertions that matter.
      const offset = Duration(seconds: 60);
      final output = WebVttTimeShifter.shift(input, offset);

      expect(output.length, greaterThan(1024));
      // Cues ending at or before zero are dropped, so the first 30 cues (at
      // two seconds apart) are removed.
      expect('-->'.allMatches(output).length, cueCount - 30);
      expect(output, contains('00:00:00.000 --> 00:00:01.000\nline 30\n'));
      expect(output, isNot(contains('\nline 29\n')));

      final lastStart = 2 * (cueCount - 1) - 60;
      final lastEnd = lastStart + 1;
      expect(
        output,
        contains(
          '${_stamp(lastStart)} --> ${_stamp(lastEnd)}\n'
          'line ${cueCount - 1}\n',
        ),
      );
    });
  });
}
