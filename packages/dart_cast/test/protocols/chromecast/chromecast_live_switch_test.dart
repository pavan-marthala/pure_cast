import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_cast/src/core/cast_device.dart';
import 'package:dart_cast/src/core/cast_exceptions.dart';
import 'package:dart_cast/src/core/cast_media.dart';
import 'package:dart_cast/src/core/cast_session.dart';
import 'package:dart_cast/src/core/live_mkv_stream.dart';
import 'package:dart_cast/src/core/local_tcp_source.dart';
import 'package:dart_cast/src/core/media_probe.dart';
import 'package:dart_cast/src/core/media_proxy.dart';
import 'package:dart_cast/src/protocols/chromecast/cast_media_channel.dart';
import 'package:dart_cast/src/protocols/chromecast/cast_receiver_channel.dart';
import 'package:dart_cast/src/protocols/chromecast/chromecast_session.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _MockCastV2Channel {
  final List<_SentMessage> sentMessages = [];
  final StreamController<_ReceivedMessage> _incoming =
      StreamController<_ReceivedMessage>.broadcast();

  Stream<_ReceivedMessage> get messageStream => _incoming.stream;

  void sendMessage({
    required String namespace,
    required String sourceId,
    required String destinationId,
    required String payload,
  }) {
    sentMessages.add(
      _SentMessage(
        namespace: namespace,
        destinationId: destinationId,
        payload: jsonDecode(payload) as Map<String, dynamic>,
      ),
    );
  }

  Future<void> connect(String host, {int port = 8009}) async {}

  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
  }

  void injectMessage({
    required String namespace,
    required String sourceId,
    required String destinationId,
    required Map<String, dynamic> payload,
  }) {
    _incoming.add(_ReceivedMessage(namespace: namespace, payload: payload));
  }

  void injectError(Object error) {
    _incoming.addError(error);
  }
}

class _SentMessage {
  final String namespace;
  final String destinationId;
  final Map<String, dynamic> payload;

  _SentMessage({
    required this.namespace,
    required this.destinationId,
    required this.payload,
  });
}

class _ReceivedMessage {
  final String namespace;
  final Map<String, dynamic> payload;

  _ReceivedMessage({required this.namespace, required this.payload});
}

/// One fake loopback TCP source. The stream is fed by the test; closing it
/// counts the close exactly as production does.
class _FakeTcpSource implements TcpSource {
  @override
  final int port;
  final StreamController<List<int>> controller = StreamController<List<int>>();
  int closeCount = 0;

  _FakeTcpSource(this.port);

  @override
  Future<Stream<List<int>>> accept({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return controller.stream;
  }

  @override
  Future<void> close() async {
    closeCount++;
    if (!controller.isClosed) unawaited(controller.close());
  }
}

class _LiveHarness {
  final List<List<String>> args = [];
  final List<int> cancelled = [];
  final List<_FakeTcpSource> sources = [];
  late final LiveMkvRunManager manager;
  int _nextId = 1;

  _LiveHarness() {
    manager = LiveMkvRunManager(
      start: (commandArgs) async {
        args.add(commandArgs);
        return _nextId++;
      },
      cancel: (sessionId) async => cancelled.add(sessionId),
      createSource: () async {
        final source = _FakeTcpSource(7100 + sources.length);
        sources.add(source);
        return source;
      },
    );
  }

  int cancelsFor(int sessionId) =>
      cancelled.where((id) => id == sessionId).length;
}

// ---------------------------------------------------------------------------
// Payload helpers
// ---------------------------------------------------------------------------

/// Thrown by the test prepare starter when the HLS path is reached.
class _PreparePathCalled implements Exception {
  @override
  String toString() => '_PreparePathCalled';
}

/// Minimal probe matching the shape `decide()` expects.
MediaProbe _makeProbe({
  String container = 'mkv',
  String audioCodec = 'aac',
  double? durationSeconds,
  int audioCount = 2,
}) {
  return MediaProbe(
    container: container,
    durationSeconds: durationSeconds,
    video: const VideoStream(codec: 'h264', level: 41, pixFmt: 'yuv420p'),
    audio: [
      AudioStream(
        index: 1,
        codec: audioCodec,
        language: 'eng',
        isDefault: true,
      ),
      if (audioCount > 1)
        const AudioStream(index: 2, codec: 'ac3', language: 'spa'),
    ],
  );
}

Map<String, dynamic> _receiverStatusPayload({String transportId = 'web-4'}) {
  return {
    'type': 'RECEIVER_STATUS',
    'requestId': 1,
    'status': {
      'applications': [
        {
          'appId': 'CC1AD845',
          'displayName': 'Default Media Receiver',
          'sessionId': 'session-xyz',
          'transportId': transportId,
          'namespaces': [
            {'name': 'urn:x-cast:com.google.cast.media'},
          ],
        },
      ],
      'volume': {'level': 0.5, 'muted': false},
    },
  };
}

Map<String, dynamic> _mediaStatusPayload({
  required int mediaSessionId,
  String playerState = 'PLAYING',
  double currentTime = 0.0,
  String? idleReason,
  int requestId = 0,
}) {
  final entry = <String, dynamic>{
    'mediaSessionId': mediaSessionId,
    'playerState': playerState,
    'currentTime': currentTime,
    'volume': {'level': 1.0, 'muted': false},
  };
  if (idleReason != null) entry['idleReason'] = idleReason;
  return {
    'type': 'MEDIA_STATUS',
    'requestId': requestId,
    'status': [entry],
  };
}

Future<_SentMessage> _awaitSentLoad(
  _MockCastV2Channel channel, {
  Duration timeout = const Duration(seconds: 5),
  int skip = 0,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final loads =
        channel.sentMessages
            .where(
              (m) =>
                  m.namespace == CastMediaChannel.mediaNamespace &&
                  m.payload['type'] == 'LOAD',
            )
            .toList();
    if (loads.length > skip) return loads[skip];
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('LOAD #${skip + 1} never reached the wire within $timeout');
}

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError(reason ?? 'condition not met within $timeout');
}

/// Starts an HTTP GET against a live stream URL, mimicking the receiver.
///
/// The response is drained in the background and never awaited here: the
/// proxy flushes headers together with the first byte, and the fake live
/// source never emits bytes, so awaiting `request.close()` would hang.
Future<void> _startLiveRequest(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  unawaited(_drainLiveRequest(request));
}

Future<void> _drainLiveRequest(HttpClientRequest request) async {
  try {
    final response = await request.close();
    await response.drain<void>();
  } catch (_) {
    // The test tears the connection down on purpose.
  }
}

void main() {
  late CastDevice device;
  late _MockCastV2Channel channel;
  late MediaProxy proxy;
  late _LiveHarness harness;
  late ChromecastSession session;
  late HttpClient httpClient;
  late MediaProbe nextProbe;
  late Directory subtitleTemp;
  var probeCalls = 0;
  var sessionDisposedInTest = false;

  setUp(() async {
    device = CastDevice(
      id: 'test-device-id',
      name: 'Test Chromecast',
      protocol: CastProtocol.chromecast,
      address: InternetAddress('192.168.1.100'),
      port: 8009,
    );
    channel = _MockCastV2Channel();
    proxy = MediaProxy();
    await proxy.start();
    harness = _LiveHarness();
    nextProbe = _makeProbe();
    probeCalls = 0;
    sessionDisposedInTest = false;
    subtitleTemp = await Directory.systemTemp.createTemp('cast_live_sub_test_');
    session = ChromecastSession.withMocks(
      device: device,
      channel: channel,
      proxy: proxy,
      liveRuns: harness.manager,
      liveSubtitleTempDir: subtitleTemp,
      probeFile: (input) async {
        probeCalls++;
        return nextProbe;
      },
      prepareStarter: ({
        required String inputPath,
        required List<String> Function(String outputDir) buildArgs,
      }) async {
        throw _PreparePathCalled();
      },
    );
    httpClient = HttpClient();
  });

  tearDown(() async {
    httpClient.close(force: true);
    if (!sessionDisposedInTest) session.dispose();
    await proxy.stop();
    try {
      await subtitleTemp.delete(recursive: true);
    } on FileSystemException {
      // Best effort cleanup.
    }
  });

  Future<void> connect() async {
    final connectFuture = session.connect();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    channel.injectMessage(
      namespace: CastReceiverChannel.receiverNamespace,
      sourceId: 'receiver-0',
      destinationId: 'sender-0',
      payload: _receiverStatusPayload(),
    );
    await connectFuture;
  }

  /// Loads the initial live stream and opens its receiver-side HTTP request,
  /// leaving one live run alive at [filePath] with [audioIndex].
  Future<void> startInitialLiveStream({
    String filePath = '/videos/movie.mkv',
  }) async {
    final loadFuture = session.loadLiveMkv(
      filePath: filePath,
      audioIndex: 0,
      streamType: 'LIVE',
    );
    final loadMsg = await _awaitSentLoad(channel);
    final contentId = loadMsg.payload['media']['contentId'] as String;
    await _startLiveRequest(httpClient, contentId);
    await _waitFor(
      () => harness.args.length == 1,
      reason: 'initial live run did not open',
    );
    channel.injectMessage(
      namespace: CastMediaChannel.mediaNamespace,
      sourceId: 'web-4',
      destinationId: 'sender-0',
      payload: _mediaStatusPayload(
        mediaSessionId: 10,
        requestId: loadMsg.payload['requestId'] as int,
      ),
    );
    await loadFuture;
  }

  /// Runs `loadLocalFile` through the live path and serves the request the
  /// receiver would make, leaving one live run alive.
  Future<void> startLiveLocalFile({
    String path = '/videos/movie.mkv',
    int audioStreamIndex = 0,
    int mediaSessionId = 10,
    double? durationSeconds,
    String audioCodec = 'dts',
    String container = 'mkv',
  }) async {
    nextProbe = _makeProbe(
      container: container,
      audioCodec: audioCodec,
      durationSeconds: durationSeconds,
    );
    final loadFuture = session.loadLocalFile(
      path,
      audioStreamIndex: audioStreamIndex,
      streamType: 'LIVE',
    );
    final loadMsg = await _awaitSentLoad(channel);
    final contentId = loadMsg.payload['media']['contentId'] as String;
    await _startLiveRequest(httpClient, contentId);
    await _waitFor(
      () => harness.args.length == 1,
      reason: 'live run from loadLocalFile did not open',
    );
    channel.injectMessage(
      namespace: CastMediaChannel.mediaNamespace,
      sourceId: 'web-4',
      destinationId: 'sender-0',
      payload: _mediaStatusPayload(
        mediaSessionId: mediaSessionId,
        requestId: loadMsg.payload['requestId'] as int,
      ),
    );
    await loadFuture;
  }

  group('ChromecastSession.switchLiveAudio', () {
    test('closes the old live run once and opens the new one with the new '
        'audio index and start seconds', () async {
      await connect();
      await startInitialLiveStream();

      expect(harness.args, hasLength(1));
      final oldArgs = harness.args[0];
      expect(oldArgs, isNot(contains('-ss')));
      expect(oldArgs, containsAllInOrder(['-map', '0:a:0']));

      final switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 2,
        position: const Duration(seconds: 60),
        streamType: 'LIVE',
      );

      final loadMsg = await _awaitSentLoad(channel, skip: 1);
      final contentId = loadMsg.payload['media']['contentId'] as String;
      expect(contentId, contains('/live/'));
      await _startLiveRequest(httpClient, contentId);
      await _waitFor(
        () => harness.args.length == 2,
        reason: 'restarted live run did not open',
      );

      // Old run is torn down exactly once, before the new one serves.
      expect(harness.cancelsFor(1), 1);
      expect(harness.sources[0].closeCount, 1);

      // New run uses the requested audio map and input seek.
      final newArgs = harness.args[1];
      expect(newArgs, containsAllInOrder(['-map', '0:a:2']));
      expect(
        newArgs,
        containsAllInOrder(['-ss', '60.0', '-i', '/videos/movie.mkv']),
      );
      expect(newArgs.indexOf('-ss'), lessThan(newArgs.indexOf('-i')));

      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await switchFuture;

      expect(session.liveStartOffset, const Duration(seconds: 60));
      expect(harness.manager.activeCount, 1);
      expect(harness.cancelsFor(1), 1);
    });

    test('switching away from a direct load uses the supplied duration and '
        'tracks, because a direct load has no live metadata', () async {
      await connect();

      // Direct (non-live) load: h264/aac mkv plans to DirectPlan.
      nextProbe = _makeProbe(
        audioCodec: 'aac',
        container: 'mkv',
        durationSeconds: 100,
      );
      final directFuture = session.loadLocalFile(
        '/videos/movie.mkv',
        streamType: 'BUFFERED',
      );
      final directLoad = await _awaitSentLoad(channel);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 5,
          requestId: directLoad.payload['requestId'] as int,
        ),
      );
      await directFuture;

      expect(session.isLive, isFalse);
      expect(session.liveAudioTracks, isEmpty);
      expect(session.liveDuration, isNull);

      const suppliedDuration = Duration(minutes: 90);
      const suppliedTracks = [
        AudioStream(
          index: 1,
          codec: 'ac3',
          channels: 6,
          language: 'eng',
          isDefault: true,
        ),
        AudioStream(index: 2, codec: 'aac', language: 'spa'),
      ];

      final switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 1,
        position: const Duration(seconds: 30),
        streamType: 'BUFFERED',
        duration: suppliedDuration,
        audioTracks: suppliedTracks,
      );

      final loadMsg = await _awaitSentLoad(channel, skip: 1);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 1);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await switchFuture;

      expect(session.isLive, isTrue);
      expect(session.liveStartOffset, const Duration(seconds: 30));
      expect(session.liveAudioIndex, 1);
      expect(session.liveDuration, suppliedDuration);
      expect(session.liveAudioTracks, equals(suppliedTracks));
    });

    test('two switches in a row leave only the newest run alive', () async {
      await connect();
      await startInitialLiveStream();

      // First switch: run 2.
      var switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 1,
        position: const Duration(seconds: 30),
        streamType: 'LIVE',
      );
      var loadMsg = await _awaitSentLoad(channel, skip: 1);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 2);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await switchFuture;

      // Second switch: run 3 replaces run 2 immediately.
      switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 3,
        position: const Duration(seconds: 90),
        streamType: 'LIVE',
      );
      loadMsg = await _awaitSentLoad(channel, skip: 2);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 3);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 12,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await switchFuture;

      // Runs 1 and 2 were each cancelled exactly once; run 3 is the only
      // run still alive.
      expect(harness.cancelsFor(1), 1);
      expect(harness.cancelsFor(2), 1);
      expect(harness.sources[0].closeCount, 1);
      expect(harness.sources[1].closeCount, 1);
      expect(harness.sources[2].closeCount, 0);
      expect(harness.manager.activeCount, 1);
      expect(session.liveStartOffset, const Duration(seconds: 90));
      expect(harness.args[2], containsAllInOrder(['-map', '0:a:3']));
      expect(
        harness.args[2],
        containsAllInOrder(['-ss', '90.0', '-i', '/videos/movie.mkv']),
      );
    });

    test('a second switch while one is loading throws and the first still '
        'completes cleanly', () async {
      await connect();
      await startInitialLiveStream();

      final firstSwitch = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 1,
        position: const Duration(seconds: 45),
        streamType: 'LIVE',
      );
      final loadMsg = await _awaitSentLoad(channel, skip: 1);

      await expectLater(
        session.switchLiveAudio(
          filePath: '/videos/movie.mkv',
          audioIndex: 2,
          position: const Duration(seconds: 45),
          streamType: 'LIVE',
        ),
        throwsA(isA<StateError>()),
      );

      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 2);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await firstSwitch;

      expect(harness.args, hasLength(2));
      expect(harness.cancelsFor(1), 1);
      expect(harness.cancelsFor(2), 0);
      expect(harness.manager.activeCount, 1);
      expect(session.liveStartOffset, const Duration(seconds: 45));
    });

    test(
      'a failed LOAD cleans up the new run, the new URL, and the offset',
      () async {
        await connect();
        await startInitialLiveStream();

        final switchFuture = session.switchLiveAudio(
          filePath: '/videos/movie.mkv',
          audioIndex: 2,
          position: const Duration(seconds: 60),
          streamType: 'LIVE',
        );
        final loadMsg = await _awaitSentLoad(channel, skip: 1);
        final contentId = loadMsg.payload['media']['contentId'] as String;
        await _startLiveRequest(httpClient, contentId);
        await _waitFor(() => harness.args.length == 2);

        channel.injectMessage(
          namespace: CastMediaChannel.mediaNamespace,
          sourceId: 'web-4',
          destinationId: 'sender-0',
          payload: _mediaStatusPayload(
            mediaSessionId: 11,
            playerState: 'IDLE',
            idleReason: 'ERROR',
            requestId: loadMsg.payload['requestId'] as int,
          ),
        );

        await expectLater(
          switchFuture,
          throwsA(isA<MediaLoadFailedException>()),
        );

        expect(harness.cancelsFor(1), 1); // old run
        expect(harness.cancelsFor(2), 1); // failed new run
        expect(harness.sources[1].closeCount, 1);
        expect(harness.manager.activeCount, 0);
        expect(session.liveStartOffset, Duration.zero);

        // The failed URL was unregistered: the receiver gets a 404 now.
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(contentId));
          final response = await request.close();
          expect(response.statusCode, HttpStatus.notFound);
          await response.drain<void>();
        } finally {
          client.close(force: true);
        }
      },
    );

    test(
      'liveStartOffset plus receiver position is the real position',
      () async {
        await connect();
        await startInitialLiveStream();

        final switchFuture = session.switchLiveAudio(
          filePath: '/videos/movie.mkv',
          audioIndex: 1,
          position: const Duration(minutes: 1),
          streamType: 'LIVE',
        );
        final loadMsg = await _awaitSentLoad(channel, skip: 1);
        await _startLiveRequest(
          httpClient,
          loadMsg.payload['media']['contentId'] as String,
        );
        await _waitFor(() => harness.args.length == 2);
        channel.injectMessage(
          namespace: CastMediaChannel.mediaNamespace,
          sourceId: 'web-4',
          destinationId: 'sender-0',
          payload: _mediaStatusPayload(
            mediaSessionId: 11,
            requestId: loadMsg.payload['requestId'] as int,
          ),
        );
        await switchFuture;

        final positionFuture = session.positionStream.first;
        channel.injectMessage(
          namespace: CastMediaChannel.mediaNamespace,
          sourceId: 'web-4',
          destinationId: 'sender-0',
          payload: _mediaStatusPayload(mediaSessionId: 11, currentTime: 5.0),
        );
        final receiverPosition = await positionFuture;

        expect(receiverPosition, const Duration(seconds: 5));
        expect(session.liveStartOffset, const Duration(minutes: 1));
        expect(
          session.liveStartOffset + session.position,
          const Duration(minutes: 1, seconds: 5),
        );
      },
    );
  });

  group('ChromecastSession.loadLocalFile live routing', () {
    test('a remux-audio plan loads through the live path and never starts '
        'CastPrepareSession', () async {
      await connect();

      await startLiveLocalFile(audioCodec: 'dts');

      expect(probeCalls, 1);
      expect(session.isLive, isTrue);
      expect(session.liveFilePath, '/videos/movie.mkv');
      expect(harness.args, hasLength(1));
      expect(harness.args.single, containsAllInOrder(['-map', '0:a:0']));
      expect(harness.args.single, isNot(contains('-ss')));

      final loads =
          channel.sentMessages
              .where(
                (m) =>
                    m.namespace == CastMediaChannel.mediaNamespace &&
                    m.payload['type'] == 'LOAD',
              )
              .toList();
      expect(loads, hasLength(1));
      expect(
        loads.single.payload['media']['contentId'] as String,
        contains('/live/'),
      );
    });

    test('a remux-container plan also loads through the live path', () async {
      await connect();

      // AVI + compatible audio -> RemuxContainerPlan.
      await startLiveLocalFile(container: 'avi', audioCodec: 'aac');

      expect(session.isLive, isTrue);
      expect(harness.args, hasLength(1));
      expect(probeCalls, 1);
    });

    test('a DirectPlan keeps the direct load (no live URL)', () async {
      await connect();
      nextProbe = _makeProbe(audioCodec: 'aac', container: 'mkv');

      final loadFuture = session.loadLocalFile('/videos/direct.mkv');
      final loadMsg = await _awaitSentLoad(channel);
      final contentId = loadMsg.payload['media']['contentId'] as String;
      expect(contentId, isNot(contains('/live/')));

      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 10,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await loadFuture;

      expect(session.isLive, isFalse);
      expect(harness.args, isEmpty);
      expect(probeCalls, 1);
    });

    test('a failed live load surfaces the error, cleans the run, and never '
        'falls back to HLS', () async {
      await connect();
      nextProbe = _makeProbe(audioCodec: 'dts');

      final loadFuture = session.loadLocalFile('/videos/movie.mkv');
      final loadMsg = await _awaitSentLoad(channel);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 1);

      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 10,
          playerState: 'IDLE',
          idleReason: 'ERROR',
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );

      await expectLater(loadFuture, throwsA(isA<MediaLoadFailedException>()));

      expect(session.isLive, isFalse);
      expect(session.liveFilePath, isNull);
      expect(session.liveDuration, isNull);
      expect(harness.manager.activeCount, 0);
      expect(harness.cancelsFor(1), 1);
      // Only the live LOAD was attempted; no HLS follow-up.
      expect(
        channel.sentMessages
            .where(
              (m) =>
                  m.namespace == CastMediaChannel.mediaNamespace &&
                  m.payload['type'] == 'LOAD',
            )
            .length,
        1,
      );
      expect(probeCalls, 1);
    });

    test(
      'probe duration reaches liveDuration without a second probe',
      () async {
        await connect();

        await startLiveLocalFile(audioCodec: 'dts', durationSeconds: 3723.0);

        expect(
          session.liveDuration,
          const Duration(hours: 1, minutes: 2, seconds: 3),
        );
        expect(probeCalls, 1);
      },
    );

    test('audio getters reflect load, switch, and stop', () async {
      await connect();

      expect(session.isLive, isFalse);
      expect(session.liveAudioTracks, isEmpty);
      expect(session.liveAudioIndex, 0);

      await startLiveLocalFile(
        audioStreamIndex: 1,
        audioCodec: 'dts',
        durationSeconds: 100,
      );

      expect(session.isLive, isTrue);
      expect(session.liveAudioIndex, 1);
      expect(session.liveAudioTracks, hasLength(2));
      expect(session.liveAudioTracks[1].language, 'spa');
      expect(session.liveDuration, const Duration(seconds: 100));

      final switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 0,
        position: const Duration(seconds: 10),
        streamType: 'LIVE',
      );
      final switchLoad = await _awaitSentLoad(channel, skip: 1);
      await _startLiveRequest(
        httpClient,
        switchLoad.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 2);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: switchLoad.payload['requestId'] as int,
        ),
      );
      await switchFuture;

      expect(session.liveAudioIndex, 0);
      expect(session.liveAudioTracks, hasLength(2));
      expect(session.liveDuration, const Duration(seconds: 100));

      await session.stop();

      expect(session.isLive, isFalse);
      expect(session.liveFilePath, isNull);
      expect(session.liveAudioTracks, isEmpty);
      expect(session.liveAudioIndex, 0);
      expect(session.liveDuration, isNull);
    });
  });

  group('ChromecastSession live seek', () {
    test('restarts at the requested position with the current audio index '
        'and clamps to the known duration', () async {
      await connect();

      await startLiveLocalFile(
        audioStreamIndex: 1,
        audioCodec: 'dts',
        durationSeconds: 100,
      );

      // Above the known duration -> clamped to 100s.
      final seekFuture = session.seek(const Duration(seconds: 200));
      var loadMsg = await _awaitSentLoad(channel, skip: 1);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 2);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await seekFuture;

      expect(harness.cancelsFor(1), 1);
      expect(
        harness.args[1],
        containsAllInOrder(['-ss', '100.0', '-i', '/videos/movie.mkv']),
      );
      expect(harness.args[1], containsAllInOrder(['-map', '0:a:1']));
      expect(session.liveStartOffset, const Duration(seconds: 100));

      // In range.
      final secondSeek = session.seek(const Duration(seconds: 30));
      loadMsg = await _awaitSentLoad(channel, skip: 2);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 3);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 12,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await secondSeek;

      expect(harness.cancelsFor(2), 1);
      expect(
        harness.args[2],
        containsAllInOrder(['-ss', '30.0', '-i', '/videos/movie.mkv']),
      );
      expect(harness.args[2], containsAllInOrder(['-map', '0:a:1']));
      expect(session.liveStartOffset, const Duration(seconds: 30));

      // Negative positions are clamped to zero.
      final zeroSeek = session.seek(const Duration(seconds: -5));
      loadMsg = await _awaitSentLoad(channel, skip: 3);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 4);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 13,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await zeroSeek;

      expect(harness.args[3], isNot(contains('-ss')));
      expect(session.liveStartOffset, Duration.zero);
    });

    test(
      'a concurrent live seek is rejected while one restart is loading',
      () async {
        await connect();
        await startLiveLocalFile(audioCodec: 'dts', durationSeconds: 100);

        final firstSeek = session.seek(const Duration(seconds: 40));
        final loadMsg = await _awaitSentLoad(channel, skip: 1);

        await expectLater(
          session.seek(const Duration(seconds: 50)),
          throwsA(isA<StateError>()),
        );

        await _startLiveRequest(
          httpClient,
          loadMsg.payload['media']['contentId'] as String,
        );
        await _waitFor(() => harness.args.length == 2);
        channel.injectMessage(
          namespace: CastMediaChannel.mediaNamespace,
          sourceId: 'web-4',
          destinationId: 'sender-0',
          payload: _mediaStatusPayload(
            mediaSessionId: 11,
            requestId: loadMsg.payload['requestId'] as int,
          ),
        );
        await firstSeek;

        expect(harness.args, hasLength(2));
        expect(harness.cancelsFor(1), 1);
        expect(harness.cancelsFor(2), 0);
        expect(harness.manager.activeCount, 1);
        expect(session.liveStartOffset, const Duration(seconds: 40));
      },
    );

    test('a non-live seek still sends the receiver SEEK', () async {
      await connect();
      nextProbe = _makeProbe(audioCodec: 'aac', container: 'mkv');

      final loadFuture = session.loadLocalFile('/videos/direct.mkv');
      final loadMsg = await _awaitSentLoad(channel);
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: 10,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await loadFuture;

      expect(session.isLive, isFalse);
      await session.seek(const Duration(seconds: 10));

      final seek = channel.sentMessages.lastWhere(
        (m) =>
            m.namespace == CastMediaChannel.mediaNamespace &&
            m.payload['type'] == 'SEEK',
      );
      expect(seek.payload['mediaSessionId'], 10);
      expect(seek.payload['currentTime'], 10.0);
      expect(harness.args, isEmpty);
    });
  });

  group('ChromecastSession live subtitles', () {
    // 30s → 31s, 60s → 62.5s, 125s → 127s, 310s → 312s, 500s → 502s.
    const sourceVtt =
        'WEBVTT\n'
        '\n'
        '00:00:30.000 --> 00:00:31.000\n'
        'before\n'
        '\n'
        '00:01:00.000 --> 00:01:02.500\n'
        'early\n'
        '\n'
        '00:02:05.000 --> 00:02:07.000\n'
        'after\n'
        '\n'
        '00:05:10.000 --> 00:05:12.000\n'
        'five\n'
        '\n'
        '00:08:20.000 --> 00:08:22.000\n'
        'eight\n';

    late File sourceFile;

    setUp(() async {
      sourceFile = File('${subtitleTemp.path}/source.vtt');
      await sourceFile.writeAsString(sourceVtt, flush: true);
    });

    CastSubtitle sourceSubtitle() => CastSubtitle(
      url: Uri.file(sourceFile.path).toString(),
      label: 'English',
      language: 'en',
      format: 'vtt',
    );

    Future<List<File>> shiftedFiles() async {
      if (!await subtitleTemp.exists()) return const [];
      return (await subtitleTemp.list().toList())
          .whereType<File>()
          .where(
            (file) => file.uri.pathSegments.last.startsWith('cast_live_sub_'),
          )
          .toList();
    }

    Future<String> singleShiftedContent() async {
      final files = await shiftedFiles();
      expect(files, hasLength(1));
      return files.single.readAsString();
    }

    int loadCount() =>
        channel.sentMessages
            .where(
              (m) =>
                  m.namespace == CastMediaChannel.mediaNamespace &&
                  m.payload['type'] == 'LOAD',
            )
            .length;

    Future<void> waitForNoShiftedFiles() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if ((await shiftedFiles()).isEmpty) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('shifted subtitle file was not deleted');
    }

    /// Acknowledges the next live LOAD, opens its receiver-side request and
    /// completes [future].
    Future<Map<String, dynamic>> acknowledgeNextLoad({
      required int skip,
      required int mediaSessionId,
      required Future<void> future,
    }) async {
      final loadMsg = await _awaitSentLoad(channel, skip: skip);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(
        () => harness.args.length == skip + 1,
        reason: 'live run #${skip + 1} did not open',
      );
      channel.injectMessage(
        namespace: CastMediaChannel.mediaNamespace,
        sourceId: 'web-4',
        destinationId: 'sender-0',
        payload: _mediaStatusPayload(
          mediaSessionId: mediaSessionId,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await future;
      return loadMsg.payload;
    }

    Future<void> startInitialLiveStreamWithSubtitle() async {
      final future = session.loadLiveMkv(
        filePath: '/videos/movie.mkv',
        audioIndex: 0,
        streamType: 'LIVE',
        subtitle: sourceSubtitle(),
      );
      await acknowledgeNextLoad(skip: 0, mediaSessionId: 10, future: future);
    }

    test(
      'loadLiveMkv attaches one active text track and an unshifted copy',
      () async {
        await connect();
        final loadFuture = session.loadLiveMkv(
          filePath: '/videos/movie.mkv',
          audioIndex: 0,
          streamType: 'LIVE',
          subtitle: sourceSubtitle(),
        );
        final payload = await acknowledgeNextLoad(
          skip: 0,
          mediaSessionId: 10,
          future: loadFuture,
        );

        final media = payload['media'] as Map<String, dynamic>;
        final tracks = media['tracks'] as List;
        expect(tracks, hasLength(1));
        final track = tracks.single as Map<String, dynamic>;
        expect(track['type'], 'TEXT');
        expect(track['trackId'], 1);
        expect(track['name'], 'English');
        expect(track['language'], 'en');
        expect(track['trackContentId'], endsWith('.vtt'));
        expect(payload['activeTrackIds'], [1]);

        expect(await singleShiftedContent(), sourceVtt);
        expect(session.liveSubtitle?.url, Uri.file(sourceFile.path).toString());
      },
    );

    test('switchLiveSubtitle attaches a copy shifted by 120s', () async {
      await connect();
      await startInitialLiveStream();
      expect(session.liveSubtitle, isNull);
      expect(await shiftedFiles(), isEmpty);

      final switchFuture = session.switchLiveSubtitle(
        subtitle: sourceSubtitle(),
        position: const Duration(seconds: 120),
      );
      final payload = await acknowledgeNextLoad(
        skip: 1,
        mediaSessionId: 11,
        future: switchFuture,
      );

      final tracks =
          (payload['media'] as Map<String, dynamic>)['tracks'] as List;
      expect(tracks, hasLength(1));
      expect(payload['activeTrackIds'], [1]);
      expect(session.liveSubtitle?.url, Uri.file(sourceFile.path).toString());
      expect(harness.cancelsFor(1), 1);
      expect(harness.manager.activeCount, 1);
      expect(
        await singleShiftedContent(),
        'WEBVTT\n'
        '\n'
        '00:00:05.000 --> 00:00:07.000\n'
        'after\n'
        '\n'
        '00:03:10.000 --> 00:03:12.000\n'
        'five\n'
        '\n'
        '00:06:20.000 --> 00:06:22.000\n'
        'eight\n',
      );
    });

    test(
      'a later audio switch shifts the original again, not the copy',
      () async {
        await connect();
        await startInitialLiveStream();
        final attach = session.switchLiveSubtitle(
          subtitle: sourceSubtitle(),
          position: const Duration(seconds: 120),
        );
        await acknowledgeNextLoad(skip: 1, mediaSessionId: 11, future: attach);

        final switchFuture = session.switchLiveAudio(
          filePath: '/videos/movie.mkv',
          audioIndex: 2,
          position: const Duration(seconds: 300),
          streamType: 'LIVE',
        );
        final payload = await acknowledgeNextLoad(
          skip: 2,
          mediaSessionId: 12,
          future: switchFuture,
        );

        final tracks =
            (payload['media'] as Map<String, dynamic>)['tracks'] as List;
        expect(tracks, hasLength(1));
        expect(payload['activeTrackIds'], [1]);
        // 310s − 300s = 10s. Shifting the 120s copy again would drop it.
        expect(
          await singleShiftedContent(),
          'WEBVTT\n'
          '\n'
          '00:00:10.000 --> 00:00:12.000\n'
          'five\n'
          '\n'
          '00:03:20.000 --> 00:03:22.000\n'
          'eight\n',
        );
        expect(harness.args[2], containsAllInOrder(['-map', '0:a:2']));
      },
    );

    test('a live seek re-attaches the subtitle shifted by 500s', () async {
      await connect();
      await startInitialLiveStream();
      final attach = session.switchLiveSubtitle(
        subtitle: sourceSubtitle(),
        position: Duration.zero,
      );
      await acknowledgeNextLoad(skip: 1, mediaSessionId: 11, future: attach);

      final seekFuture = session.seek(const Duration(seconds: 500));
      final payload = await acknowledgeNextLoad(
        skip: 2,
        mediaSessionId: 12,
        future: seekFuture,
      );

      final tracks =
          (payload['media'] as Map<String, dynamic>)['tracks'] as List;
      expect(tracks, hasLength(1));
      expect(payload['activeTrackIds'], [1]);
      expect(
        await singleShiftedContent(),
        'WEBVTT\n'
        '\n'
        '00:00:00.000 --> 00:00:02.000\n'
        'eight\n',
      );
      expect(session.liveStartOffset, const Duration(seconds: 500));
    });

    test(
      'switchLiveSubtitle(null) disables in place without a restart',
      () async {
        await connect();
        await startInitialLiveStreamWithSubtitle();
        final loadsBefore = loadCount();
        final runsBefore = harness.args.length;

        await session.switchLiveSubtitle(
          subtitle: null,
          position: Duration.zero,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(loadCount(), loadsBefore);
        expect(harness.args.length, runsBefore);
        expect(session.liveSubtitle, isNull);
        expect(await shiftedFiles(), isEmpty);

        final edit = channel.sentMessages.lastWhere(
          (m) =>
              m.namespace == CastMediaChannel.mediaNamespace &&
              m.payload['type'] == 'EDIT_TRACKS_INFO',
        );
        expect(edit.payload['activeTrackIds'], isEmpty);
        expect(edit.payload['mediaSessionId'], 10);

        // The next audio restart loads without any subtitle track at all.
        final switchFuture = session.switchLiveAudio(
          filePath: '/videos/movie.mkv',
          audioIndex: 1,
          position: const Duration(seconds: 60),
          streamType: 'LIVE',
        );
        final payload = await acknowledgeNextLoad(
          skip: 1,
          mediaSessionId: 11,
          future: switchFuture,
        );
        final media = payload['media'] as Map<String, dynamic>;
        expect(media.containsKey('tracks'), isFalse);
        expect(payload.containsKey('activeTrackIds'), isFalse);
      },
    );

    test(
      'an invalid source throws before any restart and keeps the state',
      () async {
        await connect();
        await startInitialLiveStreamWithSubtitle();
        final before = session.liveSubtitle;
        final loadsBefore = loadCount();
        expect(await shiftedFiles(), hasLength(1));

        final missing = CastSubtitle(
          url: Uri.file('${subtitleTemp.path}/missing.vtt').toString(),
          label: 'Missing',
          language: 'en',
          format: 'vtt',
        );
        await expectLater(
          session.switchLiveSubtitle(
            subtitle: missing,
            position: const Duration(seconds: 30),
          ),
          throwsA(isA<SubtitleAttachException>()),
        );

        final notVtt = File('${subtitleTemp.path}/not_vtt.vtt');
        await notVtt.writeAsString('1\n00:00:01,000 --> 00:00:02,000\nsrt\n');
        await expectLater(
          session.switchLiveSubtitle(
            subtitle: CastSubtitle(
              url: notVtt.path,
              label: 'SRT',
              language: 'en',
              format: 'vtt',
            ),
            position: const Duration(seconds: 30),
          ),
          throwsA(isA<SubtitleAttachException>()),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(loadCount(), loadsBefore);
        expect(harness.cancelsFor(1), 0);
        expect(harness.args.length, 1);
        expect(session.liveSubtitle, same(before));
        expect(await shiftedFiles(), hasLength(1));
      },
    );

    test('switchLiveSubtitle requires a connected live stream', () async {
      await expectLater(
        session.switchLiveSubtitle(subtitle: null, position: Duration.zero),
        throwsA(isA<StateError>()),
      );

      await connect();
      await expectLater(
        session.switchLiveSubtitle(subtitle: null, position: Duration.zero),
        throwsA(isA<StateError>()),
      );
    });

    test('each restart replaces the previous shifted file', () async {
      await connect();
      await startInitialLiveStreamWithSubtitle();
      final firstPath = (await shiftedFiles()).single.path;

      final switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 1,
        position: const Duration(seconds: 60),
        streamType: 'LIVE',
      );
      await acknowledgeNextLoad(
        skip: 1,
        mediaSessionId: 11,
        future: switchFuture,
      );

      final files = await shiftedFiles();
      expect(files, hasLength(1));
      expect(files.single.path, isNot(firstPath));
    });

    test('stop deletes the shifted file', () async {
      await connect();
      await startInitialLiveStreamWithSubtitle();
      expect(await shiftedFiles(), hasLength(1));

      await session.stop();

      expect(await shiftedFiles(), isEmpty);
      expect(session.liveSubtitle, isNull);
    });

    test('disconnect deletes the shifted file', () async {
      await connect();
      await startInitialLiveStreamWithSubtitle();
      expect(await shiftedFiles(), hasLength(1));

      await session.disconnect();

      expect(await shiftedFiles(), isEmpty);
      expect(session.liveSubtitle, isNull);
    });

    test('dispose deletes the shifted file', () async {
      await connect();
      await startInitialLiveStreamWithSubtitle();
      expect(await shiftedFiles(), hasLength(1));

      sessionDisposedInTest = true;
      session.dispose();

      await waitForNoShiftedFiles();
    });

    test('a lost socket deletes the shifted file', () async {
      await connect();
      await startInitialLiveStreamWithSubtitle();
      expect(await shiftedFiles(), hasLength(1));

      channel.injectError(StateError('socket lost'));
      await _waitFor(
        () => session.state == SessionState.disconnected,
        reason: 'socket loss did not disconnect the session',
      );

      await waitForNoShiftedFiles();
    });

    test(
      'a non-live load clears liveSubtitle and deletes the shifted file',
      () async {
        await connect();
        await startInitialLiveStreamWithSubtitle();
        expect(session.liveSubtitle, isNotNull);

        final loadFuture = session.loadMedia(
          const CastMedia(
            url: 'http://example.com/video.mp4',
            type: CastMediaType.mp4,
          ),
        );
        final loadMsg = await _awaitSentLoad(channel, skip: 1);
        channel.injectMessage(
          namespace: CastMediaChannel.mediaNamespace,
          sourceId: 'web-4',
          destinationId: 'sender-0',
          payload: _mediaStatusPayload(
            mediaSessionId: 11,
            requestId: loadMsg.payload['requestId'] as int,
          ),
        );
        await loadFuture;

        expect(session.liveSubtitle, isNull);
        await waitForNoShiftedFiles();
      },
    );

    test('a source that disappears before a restart downgrades to no '
        'subtitles', () async {
      await connect();
      await startInitialLiveStreamWithSubtitle();
      await sourceFile.delete();

      final switchFuture = session.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 0,
        position: const Duration(seconds: 60),
        streamType: 'LIVE',
      );
      final payload = await acknowledgeNextLoad(
        skip: 1,
        mediaSessionId: 11,
        future: switchFuture,
      );

      final media = payload['media'] as Map<String, dynamic>;
      expect(media.containsKey('tracks'), isFalse);
      expect(payload.containsKey('activeTrackIds'), isFalse);
      expect(session.liveSubtitle, isNull);
      expect(await shiftedFiles(), isEmpty);
    });
  });
}
