import 'dart:async';
import 'dart:io';

/// A TCP source that binds a [ServerSocket] on 127.0.0.1 and accepts one
/// connection, exposing its byte stream.
class LocalTcpSource {
  ServerSocket? _server;
  Socket? _socket;
  int? _port;

  int get port => _port ?? 0;

  Future<void> bind() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
  }

  /// Accepts the first connection within [timeout].
  /// Returns the socket's byte stream.
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
