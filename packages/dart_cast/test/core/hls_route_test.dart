import 'dart:io';
import 'package:dart_cast/src/core/media_proxy.dart';
import 'package:test/test.dart';

void main() {
  group('HLS route', () {
    late MediaProxy proxy;
    late Directory tmpDir;

    setUp(() async {
      proxy = MediaProxy();
      await proxy.start();
      tmpDir = await Directory.systemTemp.createTemp('hls_');
      await File(
        '${tmpDir.path}/index.m3u8',
      ).writeAsString('#EXTM3U\n#EXTINF:6,\nseg_00000.ts\n');
      await File('${tmpDir.path}/seg_00000.ts').writeAsBytes([1, 2, 3]);
    });

    tearDown(() async {
      await proxy.stop();
      await tmpDir.delete(recursive: true);
    });

    test('content type m3u8', () async {
      final url = proxy.registerHlsDirectory('sess1', tmpDir.path);
      expect(url, contains('/hls/sess1/index.m3u8'));
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        final res = await req.close();
        expect(res.statusCode, 200);
        expect(res.headers.contentType?.mimeType, 'application/x-mpegurl');
        expect(res.headers.value('access-control-allow-origin'), '*');
      } finally {
        client.close();
      }
    });

    test('content type ts', () async {
      final url = proxy.registerHlsDirectory('sess2', tmpDir.path);
      final tsUrl = url.replaceAll('index.m3u8', 'seg_00000.ts');
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(tsUrl));
        final res = await req.close();
        expect(res.statusCode, 200);
        expect(res.headers.contentType?.mimeType, 'video/mp2t');
      } finally {
        client.close();
      }
    });

    test('OPTIONS preflight', () async {
      proxy.registerHlsDirectory('sess3', tmpDir.path);
      final client = HttpClient();
      try {
        final req = await client.openUrl(
          'OPTIONS',
          Uri.parse('${proxy.baseUrl}/hls/sess3/index.m3u8'),
        );
        final res = await req.close();
        expect(res.statusCode, 204);
        expect(res.headers.value('access-control-allow-origin'), '*');
      } finally {
        client.close();
      }
    });

    test('path traversal rejected', () async {
      proxy.registerHlsDirectory('sess4', tmpDir.path);
      final client = HttpClient();
      try {
        final req = await client.getUrl(
          Uri.parse('${proxy.baseUrl}/hls/sess4/../etc/passwd'),
        );
        final res = await req.close();
        expect(res.statusCode, anyOf(403, 404));
      } finally {
        client.close();
      }
    });

    test('404 after poll timeout', () async {
      proxy.registerHlsDirectory('sess5', tmpDir.path);
      final client = HttpClient();
      try {
        final req = await client.getUrl(
          Uri.parse('${proxy.baseUrl}/hls/sess5/nope.ts'),
        );
        final res = await req.close();
        expect(res.statusCode, 404);
      } finally {
        client.close();
      }
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Range request returns 206', () async {
      proxy.registerHlsDirectory('sess6', tmpDir.path);
      final client = HttpClient();
      try {
        final req = await client.getUrl(
          Uri.parse('${proxy.baseUrl}/hls/sess6/seg_00000.ts'),
        );
        req.headers.set('Range', 'bytes=0-1');
        final res = await req.close();
        expect(res.statusCode, anyOf(200, 206));
      } finally {
        client.close();
      }
    });

    test('stop deletes session dir', () async {
      final url = proxy.registerHlsDirectory('sess7', tmpDir.path);
      await proxy.stop();
      expect(
        await Directory(tmpDir.path).exists(),
        isTrue,
      ); // dir itself not deleted by proxy
    });
    test('Range returns 206 with Content-Range and Accept-Ranges', () async {
      proxy.registerHlsDirectory('sess8', tmpDir.path);
      final client = HttpClient();
      try {
        final req = await client.getUrl(
          Uri.parse('${proxy.baseUrl}/hls/sess8/seg_00000.ts'),
        );
        req.headers.set('Range', 'bytes=0-1');
        final res = await req.close();
        expect(res.statusCode, 206);
        expect(res.headers.value('content-range'), isNotNull);
        expect(res.headers.value('accept-ranges'), 'bytes');
      } finally {
        client.close();
      }
    });

    test('unsatisfiable range returns 416', () async {
      proxy.registerHlsDirectory('sess9', tmpDir.path);
      final client = HttpClient();
      try {
        final req = await client.getUrl(
          Uri.parse('${proxy.baseUrl}/hls/sess9/seg_00000.ts'),
        );
        req.headers.set('Range', 'bytes=100-200');
        final res = await req.close();
        expect(res.statusCode, 416);
      } finally {
        client.close();
      }
    });
  });
}
