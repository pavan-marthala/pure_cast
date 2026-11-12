import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:path_provider/path_provider.dart';

enum PrepareState { starting, ready, failed, stopped }

class CastPrepareSession {
  final String sessionId;
  final Directory tempDir;
  final List<String> args;
  final StreamController<PrepareState> _state =
      StreamController<PrepareState>.broadcast();
  Stream<PrepareState> get stateStream => _state.stream;
  PrepareState _stateValue = PrepareState.starting;
  PrepareState get state => _stateValue;
  String? _ffmpegSessionId;
  String? logs;
  int? returnCode;
  String? error;

  CastPrepareSession._(this.sessionId, this.tempDir, this.args);

  static Future<CastPrepareSession> start({
    required String inputPath,
    required List<String> Function(String outputDir) buildArgs,
  }) async {
    final dir = await getTemporaryDirectory();
    // Best-effort free-space check.
    try {
      int? sourceSize;
      try {
        final f = File(
          inputPath.startsWith('file://')
              ? Uri.parse(inputPath).toFilePath()
              : inputPath,
        );
        if (await f.exists()) sourceSize = await f.length();
      } catch (_) {}
      final required =
          (sourceSize != null ? sourceSize * 3 : 0) + 50 * 1024 * 1024;
      int? freeBytes;
      // Unix: df
      try {
        final r = await Process.run('df', ['-k', dir.path]);
        if (r.exitCode == 0) {
          final ls = r.stdout.toString().split('\n');
          if (ls.length >= 2) {
            final cols = ls[1].trim().split(RegExp(r'\s+'));
            if (cols.length >= 4) {
              final availKb = int.tryParse(cols[3]);
              if (availKb != null) freeBytes = availKb * 1024;
            }
          }
        }
      } catch (_) {}
      if (freeBytes != null && freeBytes < required) {
        throw Exception('Insufficient free space for prepare session');
      }
      if (freeBytes == null) {
        debugPrint('[HLSDBG] free-space could not be determined; continuing');
      }
    } catch (e) {
      if (e.toString().contains('Insufficient free space')) rethrow;
      debugPrint('[HLSDBG] free-space check skipped/failed: $e');
    }
    final sessionDir = Directory(
      '${dir.path}/cast_prepare_${DateTime.now().millisecondsSinceEpoch}',
    );
    await sessionDir.create(recursive: true);
    String input = inputPath;
    if (input.startsWith('content://')) {
      final saf = await FFmpegKitConfig.getSafParameterForRead(input);
      if (saf != null) input = saf;
    } else if (input.startsWith('file://')) {
      input = Uri.parse(input).toFilePath();
    }
    final args =
        buildArgs(
          sessionDir.path,
        ).map((a) => a == inputPath ? input : a).toList();
    final session = CastPrepareSession._(
      sessionDir.path.split('/').last,
      sessionDir,
      args,
    );
    session._run(args);
    return session;
  }

  Future<void> _run(List<String> finalArgs) async {
    _emit(PrepareState.starting);
    final completer = Completer<void>();
    FFmpegSession? ffmpegSession;
    try {
      ffmpegSession = await FFmpegKit.executeWithArgumentsAsync(finalArgs, (
        s,
      ) async {
        // Completion callback — fires when ffmpeg process exits.
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      _ffmpegSessionId = ffmpegSession.getSessionId().toString();
      final indexFile = File('${tempDir.path}/index.m3u8');
      var waited = 0;
      while (waited < 30000) {
        // Check if ffmpeg has already exited (failure or early completion).
        if (completer.isCompleted) {
          final rc = await ffmpegSession.getReturnCode();
          returnCode = rc?.getValue();
          if (!ReturnCode.isSuccess(rc)) {
            logs = await ffmpegSession.getAllLogsAsString();
            error = 'ffmpeg exited with code ${rc?.getValue()}';
            _chunkLog(logs);
            _emit(PrepareState.failed);
            return;
          }
        }
        if (await indexFile.exists()) {
          final seg0 = File('${tempDir.path}/seg_00000.ts');
          final seg1 = File('${tempDir.path}/seg_00001.ts');
          if (await seg0.exists() && await seg1.exists()) {
            // [HLSDBG] diagnostics
            try {
              final lines =
                  await File('${tempDir.path}/index.m3u8').readAsLines();
              for (final l in lines.take(20)) {
                debugPrint('[HLSDBG] $l');
              }
            } catch (_) {}
            try {
              final segSession = await FFprobeKit.getMediaInformation(
                seg0.path,
              );
              final info = segSession.getMediaInformation();
              debugPrint(
                '[HLSDBG] segment codec=${info?.getStreams().first.getCodec()} start=${info?.getStartTime()}',
              );
            } catch (e) {
              debugPrint('[HLSDBG] ffprobe segment error: $e');
            }
            _emit(PrepareState.ready);
            return;
          }
        }
        await Future.delayed(const Duration(milliseconds: 500));
        waited += 500;
      }
      final rc = await ffmpegSession.getReturnCode();
      returnCode = rc?.getValue();
      logs = await ffmpegSession.getAllLogsAsString();
      error = 'timeout waiting for segments';
      _chunkLog(logs);
      _emit(PrepareState.failed);
    } catch (e) {
      error = e.toString();
      _emit(PrepareState.failed);
    }
  }

  void _chunkLog(String? text) {
    if (text == null) return;
    final lines = text.split('\n');
    final tail = lines.length > 60 ? lines.sublist(lines.length - 60) : lines;
    final joined = tail.join('\n');
    for (var i = 0; i < joined.length; i += 800) {
      final end = (i + 800 < joined.length) ? i + 800 : joined.length;
      debugPrint('[PREPDBG] ${joined.substring(i, end)}');
    }
  }

  void _emit(PrepareState s) {
    _stateValue = s;
    _state.add(s);
  }

  Future<void> stop() async {
    if (_ffmpegSessionId != null) {
      try {
        await FFmpegKit.cancel(int.parse(_ffmpegSessionId!));
      } catch (_) {}
    }
    _emit(PrepareState.stopped);
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  }

  Future<void> dispose() async => stop();
  static Future<void> cleanupLeftovers() async {
    try {
      final dir = await getTemporaryDirectory();
      await for (final e in dir.list()) {
        if (e is Directory && e.path.contains('cast_prepare_')) {
          try {
            await e.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
