import 'dart:async';
import 'dart:io';

/// A loopback TCP source that FFmpeg writes into and the proxy reads from.
///
/// This is a seam so the live MKV transport can be tested without a real
/// socket or FFmpeg process.
abstract class TcpSource {
  /// TCP port FFmpeg should connect to.
  int get port;

  /// Waits for the first connection and returns its byte stream.
  Future<Stream<List<int>>> accept({
    Duration timeout = const Duration(seconds: 15),
  });

  /// Closes the accepted socket (if any) and the listening server.
  Future<void> close();
}

/// A TCP source that binds a [ServerSocket] on 127.0.0.1 and accepts one
/// connection, exposing its byte stream.
class LocalTcpSource implements TcpSource {
  ServerSocket? _server;
  Socket? _socket;
  int? _port;

  @override
  int get port => _port ?? 0;

  Future<void> bind() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
  }

  /// Accepts the first connection within [timeout].
  /// Returns the socket's byte stream.
  @override
  Future<Stream<List<int>>> accept({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_server == null) throw StateError('Not bound');
    try {
      _socket = await _server!.first.timeout(timeout);
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw TimeoutException('No connection within $timeout');
    }
    return _socket!;
  }

  @override
  Future<void> close() async {
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    try {
      await _server?.close();
    } catch (_) {}
    _server = null;
  }
}
