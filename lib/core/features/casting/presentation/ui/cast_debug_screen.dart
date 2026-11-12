import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_cast/core/features/casting/data/data_source/receiver_codec_memory.dart';
import 'package:pure_cast/core/features/casting/data/data_source/transcode_settings.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';
import 'package:pure_cast/core/DI/injection.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';
import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CastDebugScreen extends StatefulWidget {
  const CastDebugScreen({super.key});

  @override
  State<CastDebugScreen> createState() => _CastDebugScreenState();
}

class _CastDebugScreenState extends State<CastDebugScreen> {
  final List<String> _log = [];
  bool _experimentalTranscode = false;

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

  Future<void> _caps() async {
    _logLine('=== Capabilities ===');
    await dart_cast.CastFfmpegDiagnostics.dumpCapabilities();
    _logLine('done');
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

  Future<void> _av1Test() async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    _logLine('AV1 test src=$src');
    final args = ['-t', '10', '-c:v', 'av1_mediacodec', '-analyzeduration', '30M', '-probesize', '30M', '-i', src, '-map', '0:v:0', '-map', '0:a:0', '-c:a', 'aac', '-ac', '2', '-c:v', 'h264_mediacodec', '-b:v', '5M', '-pix_fmt', 'nv12', '-vf', "scale=-2:min(1080\\,ih)", '-g', '48', '${Directory.systemTemp.path}/out.ts'];
    _logLine('RUN: ${args.join(' ')}');
    final session = await FFmpegKit.executeWithArguments(args);
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

  Future<void> _forcedPlan(String plan) async {
    final res = await FilePicker.pickFiles();
    if (res.isEmpty) return;
    final src = res.first.path;
    if (src == null) return;
    _logLine('forced plan=$plan src=$src');
    final bloc = context.read<CastSessionBloc>();
    final dev = bloc.state.activeDevice;
    if (dev == null) {
      _logLine('Connect to a Chromecast first');
      return;
    }
    _logLine('receiver=${dev.id} ${dev.name}');
    try {
      final service = getIt<ICastService>();
      await service.loadLocalFile(src, forcePlan: plan);
      _logLine('loadLocalFile completed');
    } catch (e, st) {
      _logLine('error: $e');
      _logLine(st.toString());
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
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: _caps,
                child: const Text('Capabilities'),
              ),
              ElevatedButton(
                onPressed: _makeClips,
                child: const Text('Make clips'),
              ),
              ElevatedButton(
                onPressed: _av1Test,
                child: const Text('AV1 test'),
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
            ],
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
