import 'dart:typed_data';

import 'package:dart_cast/dart_cast.dart' as dart_cast;
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/data_source/airplay_credential_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

dart_cast.HapCredentials _credentials() => dart_cast.HapCredentials(
  clientPrivateKey: Uint8List(64),
  clientPublicKey: Uint8List(32),
  clientId: 'client',
  devicePublicKey: Uint8List(32),
  deviceId: 'receiver',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AirPlayCredentialStore.instance.resetForTesting();
  });

  test('an unknown device has no credentials', () async {
    await AirPlayCredentialStore.instance.ensureLoaded();
    expect(AirPlayCredentialStore.instance.credentialsFor('tv-1'), isNull);
  });

  test('saved credentials survive a reload from shared preferences', () async {
    await AirPlayCredentialStore.instance.ensureLoaded();
    await AirPlayCredentialStore.instance.save('tv-1', _credentials());

    AirPlayCredentialStore.instance.resetForTesting();
    await AirPlayCredentialStore.instance.ensureLoaded();

    final loaded = AirPlayCredentialStore.instance.credentialsFor('tv-1');
    expect(loaded, isNotNull);
    expect(loaded!.clientId, 'client');
    expect(loaded.deviceId, 'receiver');
  });

  test('deleting credentials removes them from storage', () async {
    await AirPlayCredentialStore.instance.ensureLoaded();
    await AirPlayCredentialStore.instance.save('tv-1', _credentials());
    await AirPlayCredentialStore.instance.delete('tv-1');

    expect(AirPlayCredentialStore.instance.credentialsFor('tv-1'), isNull);

    AirPlayCredentialStore.instance.resetForTesting();
    await AirPlayCredentialStore.instance.ensureLoaded();
    expect(AirPlayCredentialStore.instance.credentialsFor('tv-1'), isNull);
  });

  test('credentials are keyed per device', () async {
    await AirPlayCredentialStore.instance.ensureLoaded();
    await AirPlayCredentialStore.instance.save('tv-1', _credentials());

    expect(AirPlayCredentialStore.instance.credentialsFor('tv-1'), isNotNull);
    expect(AirPlayCredentialStore.instance.credentialsFor('tv-2'), isNull);
  });
}
