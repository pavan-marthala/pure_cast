import 'package:shared_preferences/shared_preferences.dart';

/// Stores per-receiver codec compatibility results.
///
/// Keyed by receiver model (mDNS `md` record) with fallback to device id,
/// plus codec and bit depth. Results expire after 30 days.
class ReceiverCodecMemory {
  static const _prefix = 'receiver_codec_';
  static const _expiryDays = 30;

  static String _key(String receiverId, String codecKey) =>
      '$_prefix${receiverId}_$codecKey';

  static Future<void> record(String receiverId, String codecKey, bool directOk, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = now ?? DateTime.now();
    await prefs.setBool(_key(receiverId, codecKey), directOk);
    await prefs.setInt('${_key(receiverId, codecKey)}_ts', currentTime.millisecondsSinceEpoch);
  }

  static Future<bool?> lookup(String receiverId, String codecKey, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(receiverId, codecKey);
    if (!prefs.containsKey(key)) return null;
    // Check expiry
    final ts = prefs.getInt('${key}_ts');
    if (ts != null) {
      final currentTime = now ?? DateTime.now();
      final age = currentTime.millisecondsSinceEpoch - ts;
      if (age > _expiryDays * 24 * 60 * 60 * 1000) {
        await prefs.remove(key);
        await prefs.remove('${key}_ts');
        return null;
      }
    }
    return prefs.getBool(key);
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
