import 'dart:convert';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent AirPlay pairing credentials, keyed by device identifier.
///
/// AirPlay session factories are synchronous, so credentials are loaded once
/// into a cache before any session is created. A device with cached
/// credentials reconnects with pair-verify instead of showing a PIN.
class AirPlayCredentialStore {
  AirPlayCredentialStore._();

  /// Shared instance used by the app's session factories.
  static final AirPlayCredentialStore instance = AirPlayCredentialStore._();

  static const String _prefsKey = 'airplay_credentials_v1';

  final Map<String, dart_cast.HapCredentials> _cache = {};
  Future<void>? _loading;

  /// Loads stored credentials into memory. Safe to call repeatedly.
  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  /// Alias for [ensureLoaded], kept for call sites that read better as load.
  Future<void> load() => ensureLoaded();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _cache[entry.key] = dart_cast.HapCredentials.deserialize(
          entry.value as String,
        );
      }
    } catch (_) {
      // No plugins (unit tests) or corrupt/old-format data: start unpaired
      // rather than failing the whole connect.
      _cache.clear();
    }
  }

  /// Cached credentials for [deviceId], or null when the device is unpaired.
  dart_cast.HapCredentials? credentialsFor(String deviceId) => _cache[deviceId];

  /// Stores credentials produced by a successful pair-setup.
  Future<void> save(
    String deviceId,
    dart_cast.HapCredentials credentials,
  ) async {
    _cache[deviceId] = credentials;
    await _persist();
  }

  /// Forgets a device's credentials.
  Future<void> delete(String deviceId) async {
    if (_cache.remove(deviceId) == null) return;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      for (final entry in _cache.entries) entry.key: entry.value.serialize(),
    });
    await prefs.setString(_prefsKey, encoded);
  }

  /// Clears the in-memory cache and allows the next [ensureLoaded] to re-read.
  void resetForTesting() {
    _cache.clear();
    _loading = null;
  }
}
