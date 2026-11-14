import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/features/casting/data/data_source/receiver_codec_memory.dart';
import 'package:pure_cast/core/features/casting/data/data_source/transcode_settings.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CastDebugScreen extends StatefulWidget {
  const CastDebugScreen({super.key});

  @override
  State<CastDebugScreen> createState() => _CastDebugScreenState();
}

class _CastDebugScreenState extends State<CastDebugScreen> {
  final List<String> _log = [];
  bool _experimentalTranscode = false;
  bool _waitForFinish = false;
  bool _includeDuration = false;
  bool _useLive = false;
  bool _useLivePathForRemux = true;
  String _streams = 'both';
  String _segments = 'ts';
  int _pipeAudioIdx = 0;
  String? _liveFilePath;
  int _liveAudioIndex = 0;
  List<Map<String, dynamic>> _liveAudioTracks = [];

  @override
  void initState() {
    super.initState();
    TranscodeSettings.isEnabled().then((v) {
      if (mounted) setState(() => _experimentalTranscode = v);
    });
  }

  void _logLine(String s) {
    setState(() => _log.add(s));
    debugPrint(s);
  }

  Future<List<String>> _listLargeFiles() async {
    final result = <String>[];
    for (final dir in [Directory.systemTemp, await getApplicationCacheDirectory()]) {
      try {
        await for (final e in dir.list(recursive: true)) {
          if (e is File) {
            final stat = await e.stat();
            if (stat.size > 1024 * 1024) {
              result.add('${e.path} (${stat.size} bytes)');
            }
          }
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> _caps() async {
    _logLine('=== Capabilities ===');
    await dart_cast.CastFfmpegDiagnostics.dumpCapabilities();
    _logLine('done');
  }

  Future<void> _ffenv() async {
    _logLine('=== FFmpeg Environment ===');
    for (final cmd in ['-hide_banner -protocols', '-hide_banner -h muxer=matroska', '-hide_banner -muxers']) {
      _logLine('RUN: $cmd');
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      final out = await session.getOutput() ?? '';
      _logLine('RC=${rc?.getValue()}');
      final lines = out.split('\n');
      for (var i = 0; i < lines.length; i += 20) {
        final chunk = lines.sublist(i, i + 20 > lines.length ? lines.length : i + 20).join('\n');
        _logLine('[FFENV] $chunk');
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    try {
      final protSession = await FFmpegKit.execute('-hide_banner -protocols');
      final protOut = (await protSession.getOutput()) ?? '';
      final hasPipe = protOut.contains('pipe');
      final hasTcp = protOut.contains('tcp');
      final hasFile = protOut.contains('file');
      final hasHttp = protOut.contains('http');
      final hasUnix = protOut.contains('unix');
      final muxSession = await FFmpegKit.execute('-hide_banner -h muxer=matroska');
      final muxOut = (await muxSession.getOutput()) ?? '';
      final hasLive = muxOut.toLowerCase().contains('live');
      _logLine('[FFENV] protocols: pipe=$hasPipe tcp=$hasTcp file=$hasFile http=$hasHttp unix=$hasUnix; matroska live option present=$hasLive');
    } catch (e) {
      _logLine('[FFENV] parse error: $e');
    }
  }

  Future<void> _makeClips() async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    _logLine('src=$src');
    final dir = Directory('${Directory.systemTemp.path}/cast_debug');
    await dir.create(recursive: true);
    for (final cmd in [
      '-t 60 -i "$src" -map 0:v:0 -map 0:a:0 -c:v copy -c:a eac3 -b:a 384k ${dir.path}/clip_h264_eac3.mkv',
      '-t 60 -i "$src" -map 0:v:0 -map 0:a:0 -c:v copy -c:a aac ${dir.path}/clip_h264_aac.avi',
    ]) {
      _logLine('RUN: $cmd');
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      final logs = await session.getAllLogsAsString();
      _logLine('RC=${rc?.getValue()}');
      _logLine((logs ?? '').split('\n').take(40).join('\n'));
    }
  }

  /// Probes [src] for audio streams and returns the debug-track maps used by
  /// the UI. `index` is the 0-based position among AUDIO streams (the same
  /// value `-map 0:a:N` and `loadLiveMkv(audioIndex:)` expect), not the global
  /// stream index.
  Future<List<Map<String, dynamic>>> _probeAudioTracks(
    String src, {
    required String tag,
  }) async {
    final tracks = <Map<String, dynamic>>[];
    try {
      final probeSession = await FFprobeKit.getMediaInformation(src);
      final info = probeSession.getMediaInformation();
      if (info != null) {
        var audioIdx = 0;
        for (final st in info.getStreams()) {
          if (st.getType() == 'audio') {
            tracks.add({
              'index': audioIdx,
              'codec': st.getCodec() ?? 'unknown',
              'channels': st.getAllProperties()?['channels'] ?? 2,
              'language': st.getTags()?['language'] ?? 'und',
            });
            audioIdx++;
          }
        }
      }
    } catch (e) {
      _logLine('[$tag] probe error: $e');
    }
    if (tracks.isEmpty) {
      tracks.add({
        'index': 0,
        'codec': 'unknown',
        'channels': 2,
        'language': 'und',
      });
    }
    _logLine('[$tag] audio tracks: $tracks');
    return tracks;
  }

  Future<void> _pipeTest() async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    _logLine('=== Pipe Test ===');
    _logLine('src=$src');

    // Probe for audio tracks
    await _probeAudioTracks(src, tag: 'PIPETEST');
    _pipeAudioIdx = 0;

    final audioIdx = _pipeAudioIdx;

    // TCP transport only
    _logLine('[PIPETEST] Transport: tcp');
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    _logLine('[PIPETEST] tcp port=$port');

    final args = [
      '-nostdin', '-i', src, '-t', '15', '-map', '0:v:0', '-map', '0:a:$audioIdx',
      '-c:v', 'copy', '-c:a', 'aac', '-ac', '2', '-b:a', '192k',
      '-f', 'matroska', 'tcp://127.0.0.1:$port',
    ];
    _logLine('[PIPETEST] transport=tcp args=${args.join(' ')}');

    final beforeFiles = await _listLargeFiles();
    _logLine('[PIPETEST] files before: ${beforeFiles.length}');

    final stopwatch = Stopwatch()..start();
    int? firstByteMs;
    int totalBytes = 0;
    bool ebmlHeader = false;
    int? rc;
    FFmpegSession? session;
    Socket? socket;

    final watchdog = Timer(const Duration(seconds: 20), () {
      _logLine('[PIPETEST] WATCHDOG fired at ${stopwatch.elapsedMilliseconds}ms');
      try { server.close(); } catch (_) {}
      final sid = session?.getSessionId();
      if (sid != null) {
        _logLine('[PIPETEST] watchdog: cancelling ffmpeg session $sid');
        unawaited(FFmpegKit.cancel(sid));
      }
    });

    try {
      _logLine('[PIPETEST] step: starting ffmpeg');
      session = await FFmpegKit.executeWithArgumentsAsync(args);
      _logLine('[PIPETEST] step: ffmpeg session created id=${session.getSessionId()}');

      _logLine('[PIPETEST] step: waiting for connection');
      final accepted = await server.first.timeout(const Duration(seconds: 18));
      socket = accepted;
      _logLine('[PIPETEST] step: connection accepted');

      _logLine('[PIPETEST] step: reading');
      await for (final chunk in accepted) {
        if (firstByteMs == null) {
          firstByteMs = stopwatch.elapsedMilliseconds;
          _logLine('[PIPETEST] step: first chunk after ${firstByteMs}ms');
          if (chunk.length >= 4) {
            ebmlHeader = chunk[0] == 0x1A && chunk[1] == 0x45 && chunk[2] == 0xDF && chunk[3] == 0xA3;
          }
        }
        totalBytes += chunk.length;
      }
      stopwatch.stop();
      _logLine('[PIPETEST] step: reader done total=$totalBytes');
      rc = (await session.getReturnCode())?.getValue();
      final logs = await session.getAllLogsAsString();
      final errorLines = (logs ?? '').split('\n').where((l) => l.toLowerCase().contains('error') || l.toLowerCase().contains('warning')).toList();
      _logLine('[PIPETEST] transport=tcp timeToFirstByte=${firstByteMs}ms totalBytes=$totalBytes ebmlHeader=$ebmlHeader eof=true rc=$rc');
      if (errorLines.isNotEmpty) {
        _logLine('[PIPETEST] ffmpeg errors/warnings: ${errorLines.take(10).join('\n')}');
      }
    } catch (e) {
      stopwatch.stop();
      _logLine('[PIPETEST] transport=tcp error: $e timeToFirstByte=${firstByteMs}ms totalBytes=$totalBytes');
    } finally {
      watchdog.cancel();
      try { await server.close(); } catch (_) {}
      try { socket?.destroy(); } catch (_) {}
      final sid = session?.getSessionId();
      if (sid != null) {
        try { await FFmpegKit.cancel(sid); } catch (_) {}
      }
      final afterFiles = await _listLargeFiles();
      final newLarge = afterFiles.where((f) => !beforeFiles.contains(f)).toList();
      if (newLarge.isNotEmpty) {
        _logLine('[PIPETEST] NEW large files: ${newLarge.join(', ')}');
      } else {
        _logLine('[PIPETEST] no new large files created');
      }
    }
  }

  Future<void> _av1Test() async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    _logLine('AV1 test src=$src');
    final cmd = '-t 10 -c:v av1_mediacodec -i "$src" -map 0:v:0 -map 0:a:0 -c:a aac -ac 2 -c:v h264_mediacodec -b:v 5M -pix_fmt nv12 -vf scale=-2:min(1080,ih) -g 48 ${Directory.systemTemp.path}/out.ts';
    _logLine('RUN: $cmd');
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();
    _logLine('RC=${rc?.getValue()}');
    final lines = (logs ?? '').split('\n');
    final tail = lines.length > 60 ? lines.sublist(lines.length - 60) : lines;
    final joined = tail.join('\n');
    for (var i = 0; i < joined.length; i += 800) {
      final endi = (i + 800 < joined.length) ? i + 800 : joined.length;
      _logLine(joined.substring(i, endi));
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _receiverInfo() async {
    final bloc = context.read<CastSessionBloc>();
    final dev = bloc.state.activeDevice;
    _logLine('receiver id=${dev?.id} name=${dev?.name}');
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('receiver_codec_'));
    _logLine('memory keys: ${keys.join(', ')}');
  }

  Future<void> _clearMemory() async {
    await ReceiverCodecMemory.clearAll();
    _logLine('memory cleared');
  }

  /// Logs the seek experiment sample for one second of the RXDBG poll.
  ///
  /// `[SEEKTEST]` shows the receiver's raw `currentTime` (the engine's
  /// unmapped position, as printed by [ICastService.getDebugMediaStatus]) and
  /// the mapped UI position. `supportedMediaCommands` is not exposed by the
  /// adapter; it is visible in the raw MEDIA_STATUS payload logged by the
  /// engine as `[RXDBG-RAW] ns=urn:x-cast:com.google.cast.media`.
  void _logSeekTest(String status, CastSessionBloc bloc) {
    final raw =
        RegExp(r'position=(\S+)').firstMatch(status)?.group(1) ?? '<none>';
    _logLine(
      '[SEEKTEST] rawCurrentTime=$raw '
      'mapped=${bloc.state.position.inMilliseconds}ms '
      'supportedMediaCommands=n/a (see [RXDBG-RAW])',
    );
  }

  Future<void> _forcedPlan(String plan) async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    // With the live path enabled (default) the plan is left to the probe so
    // remux plans take the live MKV route; disabling it forces the selected
    // HLS plan for comparison.
    final useLivePath = _useLivePathForRemux;
    final variant = 'streams=$_streams segments=$_segments waitForFinish=$_waitForFinish includeDuration=$_includeDuration streamType=${_useLive ? 'LIVE' : 'BUFFERED'} useLivePath=$useLivePath';
    _logLine('[RXDBG] variant: $variant');
    _logLine('plan=$plan src=$src useLivePath=$useLivePath');
    final bloc = context.read<CastSessionBloc>();
    final dev = bloc.state.activeDevice;
    if (dev == null) {
      _logLine('Connect to a Chromecast first');
      return;
    }
    _logLine('receiver=${dev.id} ${dev.name}');
    final service = getIt<ICastService>();
    service.enableRawMessageLogging();
    try {
      await service.loadLocalFile(
        src,
        forcePlan: useLivePath ? null : plan,
        waitForFinish: _waitForFinish,
        includeDuration: _includeDuration,
        useLive: useLivePath,
        streamType: _useLive ? 'LIVE' : 'BUFFERED',
        streams: _streams,
        segments: _segments,
      );
      _logLine('loadLocalFile completed');
      await service.play();
      _logLine('play() called');
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final status = await service.getDebugMediaStatus();
        _logSeekTest(status, bloc);
        _logLine('[RXDBG] t=${i + 1}s\n$status');
      }
      service.disableRawMessageLogging();
    } catch (e, st) {
      _logLine('error: $e');
      _logLine(st.toString());
      service.disableRawMessageLogging();
    }
  }

  Future<void> _controlPublicHls() async {
    _logLine('=== Control: direct HLS ===');
    final service = getIt<ICastService>();
    final bloc = context.read<CastSessionBloc>();
    final dev = bloc.state.activeDevice;
    if (dev == null) {
      _logLine('Connect to a Chromecast first');
      return;
    }
    _logLine('receiver=${dev.id} ${dev.name}');
    service.enableRawMessageLogging();
    const url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/DesigningForGoogleCast.m3u8';
    _logLine('URL: $url (unverified reachable)');
    try {
      final media = PureCastMedia(
        uri: url,
        type: PureCastMediaType.hls,
        title: 'Public HLS Test',
        isLocalFile: false,
      );
      await service.loadMedia(media, bypassTransform: true);
      _logLine('loadMedia completed');
      await service.play();
      _logLine('play() called');
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final status = await service.getDebugMediaStatus();
        _logSeekTest(status, bloc);
        _logLine('[RXDBG] t=${i + 1}s\n$status');
      }
      service.disableRawMessageLogging();
    } catch (e, st) {
      _logLine('error: $e');
      _logLine(st.toString());
      service.disableRawMessageLogging();
    }
  }

  Future<void> _liveMkvCast() async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    _logLine('=== Live MKV cast ===');
    _logLine('src=$src');
    final bloc = context.read<CastSessionBloc>();
    final dev = bloc.state.activeDevice;
    if (dev == null) {
      _logLine('Connect to a Chromecast first');
      return;
    }
    _logLine('receiver=${dev.id} ${dev.name}');
    final service = getIt<ICastService>();
    _liveFilePath = src;
    _liveAudioTracks = await _probeAudioTracks(src, tag: 'LIVE');
    _liveAudioIndex = 0;
    _logLine(
      '[LIVE] using audio=$_liveAudioIndex '
      'streamType=${_useLive ? 'LIVE' : 'BUFFERED'}',
    );
    service.enableRawMessageLogging();
    try {
      await service.loadLiveMkv(
        filePath: src,
        audioIndex: _liveAudioIndex,
        streamType: _useLive ? 'LIVE' : 'BUFFERED',
        includeDuration: _includeDuration,
      );
      _logLine('loadLiveMkv completed');
      await service.play();
      _logLine('play() called');
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final status = await service.getDebugMediaStatus();
        final offset = service.liveStartOffset;
        if (offset > Duration.zero) {
          _logLine(
            '[LIVE-SWITCH] position=${offset + service.position} '
            'receiver=${service.position} offset=$offset',
          );
        }
        _logSeekTest(status, bloc);
        _logLine('[RXDBG] t=${i + 1}s\n$status');
      }
      service.disableRawMessageLogging();
    } catch (e, st) {
      _logLine('error: $e');
      _logLine(st.toString());
      service.disableRawMessageLogging();
    }
  }

  /// Restarts the live MKV stream with [audioIndex] at the current real
  /// position. The receiver's clock restarts at zero for the new stream, so
  /// the real position is `liveStartOffset + position`.
  Future<void> _switchLiveAudio(int audioIndex) async {
    final filePath = _liveFilePath;
    if (filePath == null) {
      _logLine('[LIVE-SWITCH] no live file loaded');
      return;
    }
    if (audioIndex == _liveAudioIndex) {
      _logLine('[LIVE-SWITCH] audio already $audioIndex');
      return;
    }
    final service = getIt<ICastService>();
    final from = _liveAudioIndex;
    final offset = service.liveStartOffset;
    final position = offset + service.position;
    _logLine(
      '[LIVE-SWITCH] from=$from to=$audioIndex '
      'position=${position.inMilliseconds}ms '
      'receiver=${service.position.inMilliseconds}ms '
      'offset=${offset.inMilliseconds}ms',
    );
    final stopwatch = Stopwatch()..start();
    String? playerState;
    try {
      await service.switchLiveAudio(
        filePath: filePath,
        audioIndex: audioIndex,
        position: position,
        streamType: _useLive ? 'LIVE' : 'BUFFERED',
      );
      setState(() => _liveAudioIndex = audioIndex);
      _logLine(
        '[LIVE-SWITCH] loaded to=$audioIndex '
        'loadMs=${stopwatch.elapsedMilliseconds} '
        'offset=${service.liveStartOffset.inMilliseconds}ms',
      );
      // Autoplay is requested by LOAD; this is a no-op if the receiver is
      // already playing but recovers a paused/buffering restart.
      await service.play();
      // The LOAD acknowledgement is not necessarily PLAYING yet.
      for (var i = 0; i < 40; i++) {
        final status = await service.getDebugMediaStatus();
        playerState =
            RegExp(r'playerState=(\S+)').firstMatch(status)?.group(1);
        if (playerState == 'PLAYING') break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _logLine(
        '[LIVE-SWITCH] to=$audioIndex '
        'playerState=${playerState ?? '<none>'} '
        'timeToPlayingMs=${stopwatch.elapsedMilliseconds}',
      );
    } catch (e, st) {
      _logLine('[LIVE-SWITCH] error from=$from to=$audioIndex: $e');
      _logLine(st.toString());
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cast Debug')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Experimental: convert unsupported videos'),
            value: _experimentalTranscode,
            onChanged: (v) async {
              await TranscodeSettings.setEnabled(v);
              setState(() => _experimentalTranscode = v);
              _logLine('experimental transcode = $v');
            },
          ),
          SwitchListTile(
            title: const Text('Use live path for remux plans'),
            value: _useLivePathForRemux,
            onChanged: (v) {
              setState(() => _useLivePathForRemux = v);
              _logLine('use live path for remux plans = $v');
            },
          ),
          SwitchListTile(
            title: const Text('streamType LIVE (experiment)'),
            value: _useLive,
            onChanged: (v) {
              setState(() => _useLive = v);
              _logLine('streamType LIVE experiment = $v');
            },
          ),
          DropdownButton<String>(
            value: _streams,
            items: const [
              DropdownMenuItem(value: 'both', child: Text('Streams: both')),
              DropdownMenuItem(value: 'video', child: Text('Streams: video only')),
              DropdownMenuItem(value: 'audio', child: Text('Streams: audio only')),
            ],
            onChanged: (v) => setState(() => _streams = v ?? 'both'),
          ),
          DropdownButton<String>(
            value: _segments,
            items: const [
              DropdownMenuItem(value: 'ts', child: Text('Segments: TS')),
              DropdownMenuItem(value: 'fmp4', child: Text('Segments: fMP4')),
            ],
            onChanged: (v) => setState(() => _segments = v ?? 'ts'),
          ),
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: _caps,
                child: const Text('Capabilities'),
              ),
              ElevatedButton(
                onPressed: _ffenv,
                child: const Text('FFmpeg environment'),
              ),
              ElevatedButton(
                onPressed: _pipeTest,
                child: const Text('Pipe test'),
              ),
              ElevatedButton(
                onPressed: _receiverInfo,
                child: const Text('Receiver info'),
              ),
              ElevatedButton(
                onPressed: _clearMemory,
                child: const Text('Clear memory'),
              ),
              ElevatedButton(
                onPressed: () => _forcedPlan('remuxAudio'),
                child: const Text('Force remuxAudio'),
              ),
              ElevatedButton(
                onPressed: () => _forcedPlan('remuxContainer'),
                child: const Text('Force remuxContainer'),
              ),
              ElevatedButton(
                onPressed: _controlPublicHls,
                child: const Text('Control: direct HLS'),
              ),
              ElevatedButton(
                onPressed: _liveMkvCast,
                child: const Text('Live MKV cast'),
              ),
            ],
          ),
          if (_liveFilePath != null && _liveAudioTracks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Switch audio:'),
                  for (final t in _liveAudioTracks)
                    ElevatedButton(
                      onPressed: (t['index'] as int) == _liveAudioIndex
                          ? null
                          : () => _switchLiveAudio(t['index'] as int),
                      child: Text(
                        '#${t['index']} ${t['language']}/'
                        '${t['codec']}/${t['channels']}ch',
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (_, i) =>
                  SelectableText(_log[i], style: const TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
