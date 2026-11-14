import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';
import 'package:pure_cast/core/features/casting/data/repository/live_timeline_mapper.dart';

const String _mediaNamespace = 'urn:x-cast:com.google.cast.media';
const String _receiverNamespace = 'urn:x-cast:com.google.cast.receiver';

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
    required Map<String, dynamic> payload,
  }) {
    _incoming.add(_ReceivedMessage(namespace: namespace, payload: payload));
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
        final source = _FakeTcpSource(7200 + sources.length);
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
            {'name': _mediaNamespace},
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
  double? duration,
  int requestId = 0,
}) {
  return {
    'type': 'MEDIA_STATUS',
    'requestId': requestId,
    'status': [
      {
        'mediaSessionId': mediaSessionId,
        'playerState': playerState,
        'currentTime': currentTime,
        'duration': ?duration,
        'volume': {'level': 1.0, 'muted': false},
      },
    ],
  };
}

Future<_SentMessage> _awaitSentLoad(
  _MockCastV2Channel channel, {
  Duration timeout = const Duration(seconds: 5),
  int skip = 0,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final loads = channel.sentMessages
        .where(
          (m) => m.namespace == _mediaNamespace && m.payload['type'] == 'LOAD',
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

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 80));

void main() {
  group('LiveTimelineMapper', () {
    test('applies the offset while playing', () {
      final mapper = LiveTimelineMapper();
      expect(
        mapper.mapPosition(
          receiverPosition: const Duration(seconds: 5),
          offset: const Duration(minutes: 1),
          mediaSessionId: 10,
        ),
        const Duration(minutes: 1, seconds: 5),
      );
    });

    test('drops stale events from the replaced media session until a new one '
        'reports, then accepts it', () {
      final mapper = LiveTimelineMapper()..armRestart(10);

      // Late event from the old session (same id) -> dropped.
      expect(
        mapper.mapPosition(
          receiverPosition: const Duration(seconds: 59),
          offset: const Duration(minutes: 1),
          mediaSessionId: 10,
        ),
        isNull,
      );
      expect(mapper.isRestartPending, isTrue);

      // Event without an id cannot be proven to be the new session -> dropped.
      expect(
        mapper.mapPosition(
          receiverPosition: const Duration(seconds: 59),
          offset: const Duration(minutes: 1),
          mediaSessionId: null,
        ),
        isNull,
      );

      // First event carrying the new media session id is accepted.
      expect(
        mapper.mapPosition(
          receiverPosition: const Duration(seconds: 1),
          offset: const Duration(minutes: 1),
          mediaSessionId: 11,
        ),
        const Duration(minutes: 1, seconds: 1),
      );
      expect(mapper.isRestartPending, isFalse);

      // Subsequent events are accepted even if the id never changes again.
      expect(
        mapper.mapPosition(
          receiverPosition: const Duration(seconds: 2),
          offset: const Duration(minutes: 1),
          mediaSessionId: 11,
        ),
        const Duration(minutes: 1, seconds: 2),
      );
    });

    test('cancel disarms the guard', () {
      final mapper = LiveTimelineMapper()..armRestart(10);
      mapper.cancel();
      expect(
        mapper.mapPosition(
          receiverPosition: const Duration(seconds: 1),
          offset: Duration.zero,
          mediaSessionId: 10,
        ),
        const Duration(seconds: 1),
      );
    });

    test('duration fallback uses the known live duration', () {
      final mapper = LiveTimelineMapper();
      expect(
        mapper.mapDuration(
          reportedDuration: Duration.zero,
          knownLiveDuration: const Duration(minutes: 90),
        ),
        const Duration(minutes: 90),
      );
      expect(
        mapper.mapDuration(
          reportedDuration: const Duration(minutes: 2),
          knownLiveDuration: const Duration(minutes: 90),
        ),
        const Duration(minutes: 2),
      );
      expect(
        mapper.mapDuration(
          reportedDuration: Duration.zero,
          knownLiveDuration: null,
        ),
        Duration.zero,
      );
    });
  });

  group('DartCastAdapter live timeline', () {
    late CastDevice device;
    late _MockCastV2Channel channel;
    late MediaProxy proxy;
    late _LiveHarness harness;
    late ChromecastSession session;
    late DartCastAdapter adapter;
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
      adapter = DartCastAdapter(
        castService: CastService(sessionFactory: (_) => session),
      );
      httpClient = HttpClient();
    });

    tearDown(() async {
      httpClient.close(force: true);
      await adapter.dispose();
      await proxy.stop();
    });

    Future<void> connect() async {
      final connectFuture = adapter.connect(
        PureCastDevice(
          id: device.id,
          name: device.name,
          protocol: PureCastProtocol.chromecast,
          host: device.address.address,
          port: device.port,
          capabilities: PureCastCapabilities.forProtocol(
            PureCastProtocol.chromecast,
          ),
        ),
      );
      await _settle();
      channel.injectMessage(
        namespace: _receiverNamespace,
        payload: _receiverStatusPayload(),
      );
      await connectFuture;
    }

    /// Starts a live stream with a known duration and two audio tracks.
    Future<void> startLive({
      Duration? duration = const Duration(minutes: 90),
    }) async {
      final loadFuture = session.loadLiveMkv(
        filePath: '/videos/movie.mkv',
        audioIndex: 0,
        streamType: 'LIVE',
        includeDuration: false,
        duration: duration,
        audioTracks: const [
          AudioStream(index: 1, codec: 'dts', language: 'eng', isDefault: true),
          AudioStream(index: 2, codec: 'ac3', language: 'spa'),
        ],
      );
      final loadMsg = await _awaitSentLoad(channel);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 1);
      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(
          mediaSessionId: 10,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await loadFuture;
      await _settle();
    }

    test('non-live positions are emitted raw', () async {
      await connect();
      final positions = <Duration>[];
      final sub = adapter.positionStream.listen(positions.add);

      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(mediaSessionId: 5, currentTime: 7.0),
      );
      await _settle();

      expect(positions, [const Duration(seconds: 7)]);
      await sub.cancel();
    });

    test('live positions are offset by liveStartOffset and the known duration '
        'is emitted when the receiver reports none', () async {
      await connect();
      final durations = <Duration>[];
      final durationSub = adapter.durationStream.listen(durations.add);

      await startLive(duration: const Duration(minutes: 90));

      // loadLiveMkv's first MEDIA_STATUS (t=0) already triggered the known
      // duration emission; the receiver never sends a duration field.
      expect(durations, contains(const Duration(minutes: 90)));

      final positions = <Duration>[];
      final positionSub = adapter.positionStream.listen(positions.add);
      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(mediaSessionId: 10, currentTime: 5.0),
      );
      await _settle();

      expect(positions, [const Duration(seconds: 5)]);
      expect(adapter.isLiveStream, isTrue);
      await positionSub.cancel();
      await durationSub.cancel();
    });

    test('a switch arms the race guard: the stale old-session position is '
        'dropped and the first new-session position is offset', () async {
      await connect();
      await startLive(duration: const Duration(minutes: 90));

      final positions = <Duration>[];
      final sub = adapter.positionStream.listen(positions.add);

      final switchFuture = adapter.switchLiveAudio(
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

      // Late MEDIA_STATUS from the replaced media session (id 10).
      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(mediaSessionId: 10, currentTime: 59.0),
      );
      await _settle();
      expect(positions, isEmpty, reason: 'stale position was not dropped');

      // First event from the restarted session (id 11).
      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          currentTime: 0.5,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await switchFuture;
      await _settle();

      expect(positions, isNotEmpty);
      expect(
        positions.every(
          (p) => p == const Duration(minutes: 1, milliseconds: 500),
        ),
        isTrue,
        reason: 'every accepted event must use offset + new receiver time',
      );
      expect(adapter.liveStartOffset, const Duration(minutes: 1));
      expect(adapter.activeAudioIndex, 1);
      await sub.cancel();
    });

    test('audio getters follow load, switch, and stop', () async {
      await connect();

      expect(adapter.isLiveStream, isFalse);
      expect(adapter.audioTracks, isEmpty);
      expect(adapter.activeAudioIndex, 0);

      await startLive();

      expect(adapter.isLiveStream, isTrue);
      expect(adapter.audioTracks, hasLength(2));
      expect(adapter.audioTracks[0].index, 0);
      expect(adapter.audioTracks[0].codec, 'dts');
      expect(adapter.audioTracks[1].index, 1);
      expect(adapter.audioTracks[1].language, 'spa');
      expect(adapter.audioTracks[1].isDefault, isFalse);
      expect(adapter.activeAudioIndex, 0);

      final switchFuture = adapter.switchLiveAudio(
        filePath: '/videos/movie.mkv',
        audioIndex: 1,
        position: const Duration(seconds: 30),
        streamType: 'LIVE',
      );
      final loadMsg = await _awaitSentLoad(channel, skip: 1);
      await _startLiveRequest(
        httpClient,
        loadMsg.payload['media']['contentId'] as String,
      );
      await _waitFor(() => harness.args.length == 2);
      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(
          mediaSessionId: 11,
          requestId: loadMsg.payload['requestId'] as int,
        ),
      );
      await switchFuture;
      await _settle();

      expect(adapter.activeAudioIndex, 1);
      expect(adapter.audioTracks[1].language, 'spa');

      await session.stop();
      await _settle();

      expect(adapter.isLiveStream, isFalse);
      expect(adapter.audioTracks, isEmpty);
      expect(adapter.activeAudioIndex, 0);
    });

    test('positions are raw again after the live stream is stopped', () async {
      await connect();
      await startLive();
      final positions = <Duration>[];
      final sub = adapter.positionStream.listen(positions.add);

      await session.stop();
      await _settle();
      channel.injectMessage(
        namespace: _mediaNamespace,
        payload: _mediaStatusPayload(mediaSessionId: 20, currentTime: 3.0),
      );
      await _settle();

      expect(positions, [const Duration(seconds: 3)]);
      await sub.cancel();
    });
  });
}
