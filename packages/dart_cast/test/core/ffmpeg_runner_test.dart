import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:test/test.dart';

void main() {
  group('FFmpegKitRunner.resolveInput', () {
    const runner = FFmpegKitRunner();

    test('converts file:// URIs to plain paths', () async {
      expect(
        await runner.resolveInput('file:///videos/a%20movie.mkv'),
        '/videos/a movie.mkv',
      );
    });

    test('passes plain paths through unchanged', () async {
      expect(
        await runner.resolveInput('/videos/movie.mkv'),
        '/videos/movie.mkv',
      );
    });

    test('passes content:// through unchanged on non-Android', () async {
      if (Platform.isAndroid) {
        return;
      }
      expect(
        await runner.resolveInput('content://media/external/video/42'),
        'content://media/external/video/42',
      );
    });
  });
}
