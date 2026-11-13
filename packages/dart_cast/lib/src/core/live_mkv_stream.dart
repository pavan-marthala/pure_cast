import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';

import 'cast_ffmpeg_commands.dart';
import 'local_tcp_source.dart';
import 'media_proxy.dart';

/// Starts an FFmpeg command and returns its session id.
typedef LiveFfmpegStarter = Future<int> Function(List<String> args);

/// Cancels one FFmpeg session by id.
typedef LiveFfmpegCanceller = Future<void> Function(int sessionId);

/// Creates (and binds) a loopback TCP source for one live run.
typedef TcpSourceFactory = Future<TcpSource> Function();

/// One live MKV FFmpeg run and the TCP source it writes into.
class LiveMkvRun {
  final int sessionId;
  final TcpSource source;
  final LiveFfmpegCanceller _cancel;
  bool _closed = false;

  LiveMkvRun({
    required this.sessionId,
    required this.source,
    required LiveFfmpegCanceller cancel,
  }) : _cancel = cancel;

  bool get isClosed => _closed;

  /// Cancels this run's own FFmpeg session and closes its TCP source.
  ///
  /// Safe to call more than once.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _cancel(sessionId);
    } catch (_) {}
    try {
      await source.close();
    } catch (_) {}
  }
}

/// Owns the live MKV runs of one cast session.
///
/// Each HTTP request calls [open], which starts a dedicated FFmpeg process
/// writing to its own loopback TCP port. Runs are tracked as objects so a
/// run can always cancel only its own session id.
class LiveMkvRunManager {
  final Set<LiveMkvRun> _runs = <LiveMkvRun>{};
  final LiveFfmpegStarter _start;
  final LiveFfmpegCanceller _cancel;
  final TcpSourceFactory _createSource;

  LiveMkvRunManager({
    required LiveFfmpegStarter start,
    required LiveFfmpegCanceller cancel,
    required TcpSourceFactory createSource,
  }) : _start = start,
       _cancel = cancel,
       _createSource = createSource;

  /// Real FFmpeg + loopback sockets.
  factory LiveMkvRunManager.production() => LiveMkvRunManager(
    start: (args) async {
      final session = await FFmpegKit.executeWithArgumentsAsync(args);
      final id = session.getSessionId();
      if (id == null) {
        throw StateError('FFmpeg session has no id');
      }
      return id;
    },
    cancel: (sessionId) => FFmpegKit.cancel(sessionId),
    createSource: () async {
      final source = LocalTcpSource();
      await source.bind();
      return source;
    },
  );

  /// Number of runs that have been opened but not closed yet.
  int get activeCount => _runs.length;

  /// Opens one live run for [filePath] / [audioIndex].
  ///
  /// On any failure (FFmpeg start error or accept timeout) the partially
  /// created run is cancelled and its source closed before rethrowing.
  Future<LiveStreamRun> open({
    required String filePath,
    required int audioIndex,
    Duration acceptTimeout = const Duration(seconds: 15),
  }) async {
    final source = await _createSource();
    LiveMkvRun? run;
    try {
      final args = CastFfmpegCommands.liveMkv(
        input: filePath,
        audioStreamIndex: audioIndex,
        output: 'tcp://127.0.0.1:${source.port}',
      );
      debugPrint('[LIVE] open: ffmpeg args: ${args.join(' ')}');
      final sessionId = await _start(args);
      run = LiveMkvRun(sessionId: sessionId, source: source, cancel: _cancel);
      _runs.add(run);
      final stream = await source.accept(timeout: acceptTimeout);
      debugPrint('[LIVE] open: connection accepted (session=$sessionId)');
      final activeRun = run;
      return LiveStreamRun(
        stream: stream,
        close: () async {
          _runs.remove(activeRun);
          await activeRun.close();
        },
      );
    } catch (e) {
      final failedRun = run;
      if (failedRun != null) {
        _runs.remove(failedRun);
        await failedRun.close();
      } else {
        try {
          await source.close();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Cancels every active run and closes its TCP source.
  Future<void> closeAll() async {
    final runs = _runs.toList(growable: false);
    _runs.clear();
    await Future.wait(runs.map((run) => run.close()));
  }
}
