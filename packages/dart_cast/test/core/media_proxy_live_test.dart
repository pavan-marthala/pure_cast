import 'dart:async';
import 'dart:io';

import 'package:dart_cast/src/core/media_proxy.dart';
import 'package:test/test.dart';

void main() {
  group('MediaProxy live streams', () {
    late MediaProxy proxy;

    setUp(() async {
      proxy = MediaProxy();
      await proxy.start();
    });

    tearDown(() async {
      await proxy.stop();
    });

    test('open() failure returns 500, not 200', () async {
      final url = proxy.registerLiveStream(
        open: () async => throw StateError('boom'),
        contentType: 'video/x-matroska',
      );

      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        expect(response.statusCode, HttpStatus.internalServerError);
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
    });

    test('stop() clears registered live routes', () async {
      final url = proxy.registerLiveStream(
        open: () async => LiveStreamRun(
          stream: Stream<List<int>>.value(<int>[1, 2, 3]),
          close: () async {},
        ),
      );
      final token = Uri.parse(url).pathSegments.last;

      await proxy.stop();
      await proxy.start();

      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse('${proxy.baseUrl}/live/$token'),
        );
        final response = await request.close();
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
    });
  });
}
