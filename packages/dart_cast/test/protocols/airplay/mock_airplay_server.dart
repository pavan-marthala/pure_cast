import 'dart:io';
import 'dart:typed_data';

import 'package:dart_cast/src/protocols/airplay/auth/binary_plist.dart';

/// A mock AirPlay HTTP server for testing.
///
/// Simulates AirPlay device endpoints and records request details
/// for verification in tests.
class MockAirPlayServer {
  HttpServer? _server;

  /// The port the mock server is listening on.
  int get port => _server!.port;

  // Recorded request details
  String? lastMethod;
  String? lastPath;
  String? lastBody;
  Uint8List? lastBodyBytes;
  String? lastContentType;
  String? lastSessionId;
  String? lastUserAgent;
  Map<String, String> lastQueryParameters = {};

  /// Decoded `/play` body when it is an Apple binary plist, otherwise null.
  Map<String, dynamic>? get lastPlayBody {
    final bytes = lastBodyBytes;
    if (bytes == null || bytes.length < 8) return null;
    if (String.fromCharCodes(bytes.take(8)) != 'bplist00') return null;
    try {
      return BinaryPlistDecoder.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// `Content-Location` from the last `/play` binary plist body.
  String? get lastPlayLocation => lastPlayBody?['Content-Location'] as String?;

  /// `Start-Position` fraction from the last `/play` binary plist body.
  double? get lastPlayStartPosition {
    final value = lastPlayBody?['Start-Position'];
    return value is num ? value.toDouble() : null;
  }

  /// Status code returned by `/play` (default 200).
  int playStatusCode = HttpStatus.ok;

  /// Optional body returned by `/play`, used to exercise error diagnostics.
  String? playErrorBody;

  /// Number of `/play` requests received.
  int playRequestCount = 0;

  /// Configurable playback rate returned by /playback-info (default 1.0).
  double playbackRate = 1.0;

  /// Configurable readyToPlay returned by /playback-info (default true).
  bool readyToPlay = true;

  /// Position reported by /playback-info.
  double playbackPosition = 123.456789;

  /// Duration reported by /playback-info.
  double playbackDuration = 5400.0;

  /// Whether /playback-info includes a `duration` key.
  bool includePlaybackDuration = true;

  /// How long /playback-info waits before answering, in seconds.
  double playbackInfoDelaySeconds = 0;

  /// Number of /playback-info requests received.
  int playbackInfoRequests = 0;

  /// Last volume the receiver was asked to apply.
  double? volume;

  /// Starts the mock server on a random available port.
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  /// Stops the mock server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Record request details
    lastMethod = request.method;
    lastPath = request.uri.path;
    lastQueryParameters = request.uri.queryParameters;
    lastContentType = request.headers.contentType?.toString();
    lastSessionId = request.headers.value('X-Apple-Session-ID');
    lastUserAgent = request.headers.value('User-Agent');

    // Read body for POST requests
    if (request.method == 'POST') {
      final bodyBytes = await request.fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      lastBodyBytes = Uint8List.fromList(bodyBytes);
      lastBody = String.fromCharCodes(bodyBytes);
    } else {
      lastBody = null;
      lastBodyBytes = null;
    }

    // Route to appropriate handler
    switch (request.uri.path) {
      case '/play':
        _handlePlay(request);
        break;
      case '/scrub':
        if (request.method == 'GET') {
          _handleGetScrub(request);
        } else {
          _handlePostScrub(request);
        }
        break;
      case '/rate':
        _handleRate(request);
        break;
      case '/stop':
        _handleStop(request);
        break;
      case '/playback-info':
        _handlePlaybackInfo(request);
        break;
      case '/server-info':
        _handleServerInfo(request);
        break;
      case '/volume':
        volume =
            double.tryParse(request.uri.queryParameters['volume'] ?? '') ??
            volume;
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        break;
      default:
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
    }
  }

  void _handlePlay(HttpRequest request) {
    playRequestCount++;
    request.response.statusCode = playStatusCode;
    final body = playErrorBody;
    if (body != null) request.response.write(body);
    request.response.close();
  }

  void _handlePostScrub(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
  }

  void _handleGetScrub(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('text', 'parameters');
    request.response.write('duration: 5400.000000\nposition: 123.456789\n');
    request.response.close();
  }

  void _handleRate(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
  }

  void _handleStop(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
  }

  Future<void> _handlePlaybackInfo(HttpRequest request) async {
    playbackInfoRequests++;
    // Snapshot the values when the request arrives so a delayed answer is a
    // genuine stale response, not the receiver's current state.
    final position = playbackPosition;
    final duration = playbackDuration;
    final rate = playbackRate;
    final ready = readyToPlay;
    if (playbackInfoDelaySeconds > 0) {
      await Future<void>.delayed(
        Duration(milliseconds: (playbackInfoDelaySeconds * 1000).round()),
      );
    }
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType(
      'text',
      'x-apple-plist+xml',
    );
    request.response.write('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    ${includePlaybackDuration ? '<key>duration</key>\n    <real>${duration.toStringAsFixed(6)}</real>' : ''}
    <key>position</key>
    <real>${position.toStringAsFixed(6)}</real>
    <key>rate</key>
    <real>${rate.toStringAsFixed(6)}</real>
    <key>readyToPlay</key>
    <$ready/>
    <key>playbackBufferEmpty</key>
    <false/>
    <key>playbackLikelyToKeepUp</key>
    <true/>
</dict>
</plist>''');
    await request.response.close();
  }

  void _handleServerInfo(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType(
      'text',
      'x-apple-plist+xml',
    );
    request.response.write('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>deviceid</key>
    <string>AA:BB:CC:DD:EE:FF</string>
    <key>features</key>
    <integer>1518338039</integer>
    <key>model</key>
    <string>AppleTV3,2</string>
    <key>protovers</key>
    <string>1.0</string>
    <key>srcvers</key>
    <string>220.68</string>
</dict>
</plist>''');
    request.response.close();
  }
}
