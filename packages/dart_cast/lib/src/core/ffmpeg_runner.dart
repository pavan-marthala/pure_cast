import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';

/// Outcome of one FFmpeg run.
class FfmpegResult {
  /// FFmpeg's process return code, or null when it is unknown.
  final int? returnCode;

  /// FFmpeg's combined log output, when available.
  final String? logs;

  /// True when FFmpeg reported a successful return code.
  final bool success;

  /// True when the return code indicates cancellation.
  final bool cancelled;

  /// Creates a result.
  const FfmpegResult({
    required this.returnCode,
    required this.logs,
    required this.success,
    required this.cancelled,
  });
}

/// One running FFmpeg job that can be awaited and cancelled by session id.
abstract interface class FfmpegJob {
  /// The FFmpeg session id as a string, or null when it is not known yet.
  String? get sessionId;

  /// Completes when the FFmpeg process exits.
  Future<FfmpegResult> get done;

  /// Cancels this job's own session, and only that session.
  ///
  /// Throws [StateError] when [sessionId] is still null. Callers must therefore
  /// wait for [FfmpegRunner.start] to complete before calling this.
  Future<void> cancel();
}

/// Starts FFmpeg processes and resolves input paths.
abstract interface class FfmpegRunner {
  /// Starts FFmpeg with [arguments] and returns a handle for the running job.
  ///
  /// [arguments] are passed to FFmpeg verbatim; the final element is normally
  /// the output path.
  Future<FfmpegJob> start(List<String> arguments);

  /// Converts [path] into something FFmpeg can open.
  ///
  /// `file://` URIs become plain paths. `content://` URIs are resolved through
  /// Android's Storage Access Framework; when SAF returns null, or on a
  /// non-Android platform, [path] is returned unchanged and FFmpeg will fail
  /// when it tries to open it.
  Future<String> resolveInput(String path);
}

/// Default [FfmpegRunner] backed by FFmpegKit.
///
/// This is the only class in the subtitle-extraction API that starts FFmpeg;
/// pass a fake [FfmpegRunner] in tests.
class FFmpegKitRunner implements FfmpegRunner {
  /// Creates an FFmpegKit-backed runner.
  const FFmpegKitRunner();

  /// Starts FFmpeg with [arguments].
  @override
  Future<FfmpegJob> start(List<String> arguments) async {
    final completion = Completer<void>();
    final session = await FFmpegKit.executeWithArgumentsAsync(arguments, (
      _,
    ) async {
      if (!completion.isCompleted) completion.complete();
    });
    final id = session.getSessionId();
    if (id == null) {
      throw StateError('FFmpeg session has no id');
    }
    return _FFmpegKitJob(
      session: session,
      sessionId: id.toString(),
      completion: completion.future,
    );
  }

  /// Converts [path] into an FFmpeg input as described on [FfmpegRunner].
  @override
  Future<String> resolveInput(String path) async {
    if (path.startsWith('content://')) {
      if (!Platform.isAndroid) return path;
      final saf = await FFmpegKitConfig.getSafParameterForRead(path);
      return saf ?? path;
    }
    if (path.startsWith('file://')) {
      return Uri.parse(path).toFilePath();
    }
    return path;
  }
}

class _FFmpegKitJob implements FfmpegJob {
  _FFmpegKitJob({
    required FFmpegSession session,
    required String sessionId,
    required Future<void> completion,
  }) : _session = session,
       _sessionId = sessionId,
       _completion = completion;

  final FFmpegSession _session;
  final String? _sessionId;
  final Future<void> _completion;

  @override
  String? get sessionId => _sessionId;

  @override
  Future<FfmpegResult> get done async {
    await _completion;
    final returnCode = await _session.getReturnCode();
    final logs = await _session.getAllLogsAsString();
    return FfmpegResult(
      returnCode: returnCode?.getValue(),
      logs: logs,
      success: ReturnCode.isSuccess(returnCode),
      cancelled: ReturnCode.isCancel(returnCode),
    );
  }

  @override
  Future<void> cancel() async {
    final id = _sessionId;
    if (id == null) {
      throw StateError(
        'FFmpeg session id is not available yet; wait for start to complete',
      );
    }
    await FFmpegKit.cancel(int.parse(id));
  }
}
