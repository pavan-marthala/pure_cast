import 'dart:async';

import 'package:dart_cast/src/core/live_mkv_stream.dart';
import 'package:dart_cast/src/core/local_tcp_source.dart';
import 'package:test/test.dart';

class _FakeTcpSource implements TcpSource {
  @override
  final int port;
  final StreamController<List<int>> _controller =
      StreamController<List<int>>();
  int closeCount = 0;
  bool failAccept = false;

  _FakeTcpSource(this.port);

  @override
  Future<Stream<List<int>>> accept({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (failAccept) {
      throw TimeoutException('no connection', timeout);
    }
    return _controller.stream;
  }

  @override
  Future<void> close() async {
    closeCount++;
    // Do not await: a single-subscription controller with no listener never
    // completes its close future.
    if (!_controller.isClosed) unawaited(_controller.close());
  }
}

class _Harness {
  final List<List<String>> args = [];
  final List<int> cancelled = [];
  final List<_FakeTcpSource> sources = [];
  late final LiveMkvRunManager manager;
  int _nextId = 1;

  _Harness({bool failStart = false, bool failAccept = false}) {
    manager = LiveMkvRunManager(
      start: (commandArgs) async {
        args.add(commandArgs);
        if (failStart) throw StateError('ffmpeg start failed');
        return _nextId++;
      },
      cancel: (sessionId) async => cancelled.add(sessionId),
      createSource: () async {
        final source = _FakeTcpSource(7000 + sources.length)
          ..failAccept = failAccept;
        sources.add(source);
        return source;
      },
    );
  }
}

void main() {
  group('LiveMkvRunManager', () {
    test('close cancels only its own session and closes its source', () async {
      final h = _Harness();
      final run = await h.manager.open(filePath: '/video.mkv', audioIndex: 2);

      expect(h.manager.activeCount, 1);
      await run.close();

      expect(h.cancelled, [1]);
      expect(h.sources.single.closeCount, 1);
      expect(h.manager.activeCount, 0);
    });

    test('closing one of two concurrent runs leaves the other active', () async {
      final h = _Harness();
      final first = await h.manager.open(filePath: '/a.mkv', audioIndex: 0);
      final second = await h.manager.open(filePath: '/b.mkv', audioIndex: 1);
      expect(h.manager.activeCount, 2);

      await first.close();

      expect(h.cancelled, [1]);
      expect(h.sources[0].closeCount, 1);
      expect(h.sources[1].closeCount, 0);
      expect(h.manager.activeCount, 1);

      await second.close();
      expect(h.cancelled, [1, 2]);
      expect(h.sources[1].closeCount, 1);
      expect(h.manager.activeCount, 0);
    });

    test('double close is safe', () async {
      final h = _Harness();
      final run = await h.manager.open(filePath: '/video.mkv', audioIndex: 0);

      await run.close();
      await run.close();

      expect(h.cancelled, [1]);
      expect(h.sources.single.closeCount, 1);
    });

    test('closeAll cancels every run', () async {
      final h = _Harness();
      await h.manager.open(filePath: '/a.mkv', audioIndex: 0);
      await h.manager.open(filePath: '/b.mkv', audioIndex: 3);

      await h.manager.closeAll();

      expect(h.cancelled, [1, 2]);
      expect(h.sources.every((s) => s.closeCount == 1), isTrue);
      expect(h.manager.activeCount, 0);
    });

    test('ffmpeg start failure closes the source and tracks no run', () async {
      final h = _Harness(failStart: true);

      await expectLater(
        h.manager.open(filePath: '/video.mkv', audioIndex: 0),
        throwsA(isA<StateError>()),
      );

      expect(h.sources.single.closeCount, 1);
      expect(h.cancelled, isEmpty);
      expect(h.manager.activeCount, 0);
    });

    test('accept timeout cancels its own session and closes the source', () async {
      final h = _Harness(failAccept: true);

      await expectLater(
        h.manager.open(filePath: '/video.mkv', audioIndex: 0),
        throwsA(isA<TimeoutException>()),
      );

      expect(h.cancelled, [1]);
      expect(h.sources.single.closeCount, 1);
      expect(h.manager.activeCount, 0);
    });

    test('open passes the source port to ffmpeg', () async {
      final h = _Harness();
      final run = await h.manager.open(filePath: '/video.mkv', audioIndex: 4);

      expect(h.args.single.last, 'tcp://127.0.0.1:7000');
      expect(h.args.single, containsAllInOrder(['-map', '0:a:4']));

      await run.close();
    });

    test('open passes startSeconds to ffmpeg as an input seek', () async {
      final h = _Harness();
      final run = await h.manager.open(
        filePath: '/video.mkv',
        audioIndex: 1,
        startSeconds: 42.5,
      );

      expect(
        h.args.single,
        containsAllInOrder(['-ss', '42.5', '-i', '/video.mkv']),
      );

      await run.close();
    });

    test('open omits -ss when no startSeconds is given', () async {
      final h = _Harness();
      final run = await h.manager.open(filePath: '/video.mkv', audioIndex: 0);

      expect(h.args.single, isNot(contains('-ss')));

      await run.close();
    });
  });
}
