import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/receiver_codec_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('store and read', () async {
    await ReceiverCodecMemory.record('r1', 'hevc8', true);
    expect(await ReceiverCodecMemory.lookup('r1', 'hevc8'), true);
  });

  test('clear', () async {
    await ReceiverCodecMemory.record('r1', 'hevc8', true);
    await ReceiverCodecMemory.clear('r1');
    expect(await ReceiverCodecMemory.lookup('r1', 'hevc8'), null);
  });

  test('expiry: 31-day-old entry returns null', () async {
    final now = DateTime.now();
    final old = now.subtract(const Duration(days: 31));
    await ReceiverCodecMemory.record('r1', 'hevc8', false, now: old);
    expect(await ReceiverCodecMemory.lookup('r1', 'hevc8', now: now), null);
  });

  test('expiry: 29-day-old entry returns value', () async {
    final now = DateTime.now();
    final recent = now.subtract(const Duration(days: 29));
    await ReceiverCodecMemory.record('r1', 'hevc8', false, now: recent);
    expect(await ReceiverCodecMemory.lookup('r1', 'hevc8', now: now), false);
  });
}
