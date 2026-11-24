import 'package:dart_cast/src/protocols/airplay/airplay_client.dart';
import 'package:test/test.dart';

import 'mock_airplay_server.dart';

void main() {
  late MockAirPlayServer mockServer;
  late AirPlayClient client;

  setUp(() async {
    mockServer = MockAirPlayServer();
    await mockServer.start();
    client = AirPlayClient(host: 'localhost', port: mockServer.port);
  });

  tearDown(() async {
    client.close();
    await mockServer.stop();
  });

  group('AirPlayClient', () {
    group('play()', () {
      test('sends a binary plist /play body', () async {
        await client.play('https://example.com/video.m3u8');

        expect(mockServer.lastMethod, equals('POST'));
        expect(mockServer.lastPath, equals('/play'));
        expect(
          mockServer.lastContentType,
          contains('application/x-apple-binary-plist'),
        );

        final body = mockServer.lastPlayBody;
        expect(body, isNotNull);
        expect(body!['Content-Location'], 'https://example.com/video.m3u8');
        expect(body['Start-Position'], closeTo(0.0, 0.0001));
        expect(body['X-Apple-Session-ID'], mockServer.lastSessionId);
      });

      test('sends custom start position as a fraction', () async {
        await client.play('https://example.com/video.m3u8', startPosition: 0.5);

        final body = mockServer.lastPlayBody;
        expect(body, isNotNull);
        expect(body!['Start-Position'], closeTo(0.5, 0.0001));
      });

      test(
        'a 400 carries status and body preview and is not retried',
        () async {
          mockServer
            ..playStatusCode = 400
            ..playErrorBody = 'bad request';

          await expectLater(
            client.play('https://example.com/video.m3u8'),
            throwsA(
              isA<AirPlayClientException>()
                  .having((e) => e.statusCode, 'statusCode', 400)
                  .having(
                    (e) => e.responsePreview,
                    'responsePreview',
                    contains('bad request'),
                  )
                  .having((e) => e.message, 'message', contains('status 400')),
            ),
          );

          expect(mockServer.playRequestCount, 1);
        },
      );
    });

    group('scrub()', () {
      test('sends POST /scrub with position query parameter', () async {
        await client.scrub(300.5);

        expect(mockServer.lastMethod, equals('POST'));
        expect(mockServer.lastPath, equals('/scrub'));
        expect(mockServer.lastQueryParameters['position'], equals('300.5'));
      });
    });

    group('rate()', () {
      test('rate(0) sends POST /rate?value=0.0 to pause', () async {
        await client.rate(0);

        expect(mockServer.lastMethod, equals('POST'));
        expect(mockServer.lastPath, equals('/rate'));
        expect(mockServer.lastQueryParameters['value'], equals('0.0'));
      });

      test('rate(1) sends POST /rate?value=1.0 to play', () async {
        await client.rate(1);

        expect(mockServer.lastMethod, equals('POST'));
        expect(mockServer.lastPath, equals('/rate'));
        expect(mockServer.lastQueryParameters['value'], equals('1.0'));
      });
    });

    group('stop()', () {
      test('sends POST /stop', () async {
        await client.stop();

        expect(mockServer.lastMethod, equals('POST'));
        expect(mockServer.lastPath, equals('/stop'));
      });
    });

    group('getPlaybackInfo()', () {
      test('parses XML plist response correctly', () async {
        final info = await client.getPlaybackInfo();

        expect(info.duration, equals(5400.0));
        expect(info.position, equals(123.456789));
        expect(info.rate, equals(1.0));
        expect(info.readyToPlay, isTrue);
        expect(info.playbackBufferEmpty, isFalse);
        expect(info.playbackLikelyToKeepUp, isTrue);
      });

      test('sends GET request to /playback-info', () async {
        await client.getPlaybackInfo();

        expect(mockServer.lastMethod, equals('GET'));
        expect(mockServer.lastPath, equals('/playback-info'));
      });
    });

    group('getServerInfo()', () {
      test('parses server info XML plist response', () async {
        final info = await client.getServerInfo();

        expect(info.deviceId, equals('AA:BB:CC:DD:EE:FF'));
        expect(info.model, equals('AppleTV3,2'));
        expect(info.features, equals(1518338039));
      });

      test('sends GET request to /server-info', () async {
        await client.getServerInfo();

        expect(mockServer.lastMethod, equals('GET'));
        expect(mockServer.lastPath, equals('/server-info'));
      });
    });

    group('getScrubPosition()', () {
      test('parses text/parameters response', () async {
        final result = await client.getScrubPosition();

        expect(result.duration, equals(5400.0));
        expect(result.position, equals(123.456789));
      });

      test('sends GET request to /scrub', () async {
        await client.getScrubPosition();

        expect(mockServer.lastMethod, equals('GET'));
        expect(mockServer.lastPath, equals('/scrub'));
      });
    });

    group('session ID', () {
      test('X-Apple-Session-ID is present on all requests', () async {
        await client.play('https://example.com/video.m3u8');
        expect(mockServer.lastSessionId, isNotNull);
        expect(mockServer.lastSessionId, isNotEmpty);
      });

      test('X-Apple-Session-ID is consistent across requests', () async {
        await client.play('https://example.com/video.m3u8');
        final firstSessionId = mockServer.lastSessionId;

        await client.rate(1);
        final secondSessionId = mockServer.lastSessionId;

        await client.getPlaybackInfo();
        final thirdSessionId = mockServer.lastSessionId;

        expect(firstSessionId, equals(secondSessionId));
        expect(secondSessionId, equals(thirdSessionId));
      });

      test('session ID changes after stop()', () async {
        await client.play('https://example.com/video.m3u8');
        final firstSessionId = mockServer.lastSessionId;

        await client.stop();
        final stopSessionId = mockServer.lastSessionId;

        // The stop request itself uses the old session ID
        expect(stopSessionId, equals(firstSessionId));

        // After stop, a new session ID is generated for subsequent requests
        await client.play('https://example.com/video2.m3u8');
        final newSessionId = mockServer.lastSessionId;

        expect(newSessionId, isNot(equals(firstSessionId)));
      });
    });

    group('headers', () {
      test('User-Agent is set to MediaControl/1.0', () async {
        await client.play('https://example.com/video.m3u8');

        expect(mockServer.lastUserAgent, equals('MediaControl/1.0'));
      });
    });
  });
}
