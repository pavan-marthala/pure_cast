import 'dart:async';
import 'dart:io';

import 'package:dart_cast/src/core/cast_device.dart';
import 'package:dart_cast/src/core/live_mkv_stream.dart';
import 'package:dart_cast/src/core/local_tcp_source.dart';
import 'package:dart_cast/src/protocols/chromecast/chromecast_session.dart';
import 'package:test/test.dart';

class _FakeTcpSource implements TcpSource {
  @override
  final int port;
  int closeCount = 0;

  _FakeTcpSource(this.port);

  @override
  Future<Stream<List<int>>> accept({
    Duration timeout = const Duration(seconds: 15),
  }) async => const Stream<List<int>>.empty();

  @override
  Future<void> close() async {
    closeCount++;
  }
}

class _FakeChannel {
  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();

  Stream<dynamic> get messageStream => _incoming.stream;

  void sendMessage({
    required String namespace,
    required String sourceId,
    required String destinationId,
    required String payload,
  }) {}

  Future<void> connect(String host, {int port = 8009}) async {}

  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

void main() {
  group('ChromecastSession resource lifecycle', () {
    late List<int> cancelled;
    late List<_FakeTcpSource> sources;
    late LiveMkvRunManager manager;
    late bool prepareStopped;
    late ChromecastSession session;

    CastDevice device() => CastDevice(
      id: 'test-device',
      name: 'Test Chromecast',
      protocol: CastProtocol.chromecast,
      address: InternetAddress('192.168.1.100'),
      port: 8009,
    );

    void setUpSession() {
      cancelled = <int>[];
      sources = <_FakeTcpSource>[];
      prepareStopped = false;
      var nextId = 1;
      manager = LiveMkvRunManager(
        start: (args) async => nextId++,
        cancel: (sessionId) async => cancelled.add(sessionId),
        createSource: () async {
          final source = _FakeTcpSource(8000 + sources.length);
          sources.add(source);
          return source;
        },
      );
      session = ChromecastSession.withMocks(
        device: device(),
        channel: _FakeChannel(),
        liveRuns: manager,
        prepareStopper: () async => prepareStopped = true,
      );
    }

    test('stop() closes all runs and stops the prepare session', () async {
      setUpSession();
      await manager.open(filePath: '/video.mkv', audioIndex: 0);

      // No media session was loaded, so stop() still rejects the STOP
      // command, but resources must already be released.
      await expectLater(session.stop(), throwsA(isA<StateError>()));

      expect(cancelled, [1]);
      expect(sources.single.closeCount, 1);
      expect(manager.activeCount, 0);
      expect(prepareStopped, isTrue);
      session.dispose();
    });

    test('disconnect() closes all runs and stops the prepare session', () async {
      setUpSession();
      await manager.open(filePath: '/video.mkv', audioIndex: 0);

      await session.disconnect();

      expect(cancelled, [1]);
      expect(sources.single.closeCount, 1);
      expect(manager.activeCount, 0);
      expect(prepareStopped, isTrue);
      session.dispose();
    });

    test('dispose() closes all runs and stops the prepare session', () async {
      setUpSession();
      await manager.open(filePath: '/video.mkv', audioIndex: 0);

      session.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(cancelled, [1]);
      expect(sources.single.closeCount, 1);
      expect(manager.activeCount, 0);
      expect(prepareStopped, isTrue);
    });
  });
}
