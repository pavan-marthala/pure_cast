import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_cast/src/core/cast_device.dart';
import 'package:dart_cast/src/core/cast_exceptions.dart';
import 'package:dart_cast/src/core/live_mkv_stream.dart';
import 'package:dart_cast/src/core/local_tcp_source.dart';
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
    _incoming.add(
      _ReceivedMessage(
        namespace: namespace,
        payload: payload,
      ),
    );
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
  final StreamController<List<int>> controller =
      StreamController<List<int>>();
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
    session = ChromecastSession.withMocks(
      device: device,
      channel: channel,
      proxy: proxy,
      liveRuns: harness.manager,
    );
    httpClient = HttpClient();
  });

  tearDown(() async {
    httpClient.close(force: true);
    session.dispose();
    await proxy.stop();
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
  Future<void> startInitialLiveStream({String filePath = '/videos/movie.mkv'}) async {
    final loadFuture = session.loadLiveMkv(
      filePath: filePath,
      audioIndex: 0,
      streamType: 'LIVE',
      includeDuration: false,
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
      expect(
        newArgs.indexOf('-ss'),
        lessThan(newArgs.indexOf('-i')),
      );

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

    test('a failed LOAD cleans up the new run, the new URL, and the offset',
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
    });

    test('liveStartOffset plus receiver position is the real position',
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
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          currentTime: 5.0,
        ),
      );
      final receiverPosition = await positionFuture;

      expect(receiverPosition, const Duration(seconds: 5));
      expect(session.liveStartOffset, const Duration(minutes: 1));
      expect(
        session.liveStartOffset + session.position,
        const Duration(minutes: 1, seconds: 5),
      );
    });
  });
}
