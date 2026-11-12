import 'package:shared_preferences/shared_preferences.dart';

class ReceiverCodecMemory {
  static const _prefix = 'receiver_codec_';

  static Future<void> record(String receiverId, String codecKey, bool directOk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${receiverId}_$codecKey', directOk);
  }

  static Future<bool?> lookup(String receiverId, String codecKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('$_prefix${receiverId}_$codecKey')) return null;
    return prefs.getBool('$_prefix${receiverId}_$codecKey');
  }

  static Future<void> clear(String receiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('$_prefix${receiverId}_'));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
