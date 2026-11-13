import 'dart:async';
import 'dart:io';
import 'package:dart_cast/src/core/local_tcp_source.dart';
import 'package:test/test.dart';

void main() {
  group('LocalTcpSource', () {
    test('binds and accepts a connection', () async {
      final src = LocalTcpSource();
      await src.bind();
      expect(src.port, greaterThan(0));

      final client = await Socket.connect('127.0.0.1', src.port);
      final stream = await src.accept(timeout: const Duration(seconds: 5));
      client.add([1, 2, 3]);
      await client.flush();
      final received = await stream.first.timeout(const Duration(seconds: 5));
      expect(received, [1, 2, 3]);
      await src.close();
      await client.close();
    });

    test('timeout when nobody connects', () async {
      final src = LocalTcpSource();
      await src.bind();
      expect(
        () => src.accept(timeout: const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
      await src.close();
    });

    test('close destroys socket and closes server', () async {
      final src = LocalTcpSource();
      await src.bind();
      final client = await Socket.connect('127.0.0.1', src.port);
      final stream = await src.accept(timeout: const Duration(seconds: 5));
      await src.close();
      // After close, accepting should fail
      expect(
        () => src.accept(timeout: const Duration(seconds: 1)),
        throwsStateError,
      );
      await client.close();
    });
  });
}
