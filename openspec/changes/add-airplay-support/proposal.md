# Proposal

## Why

AirPlay is the only supported protocol that has not reached parity with Chromecast and DLNA. The package can discover, pair with, and hand-shake an AirPlay receiver, but it cannot prepare local media for playback, switch audio or subtitles, or reliably resume, and the app deliberately hides AirPlay from discovery and connection. Shipping without it leaves Apple TV users with no working path and makes the product's protocol matrix inconsistent.

## What Changes

- **Package — media pipeline**: `AirPlaySession.loadLocalFile` probes the source and chooses direct play, container/audio remux, or H.264/AAC transcode; prepares MP4 for the common case and a seekable VOD HLS directory when subtitles or multi-audio are involved.
- **Package — track control**: audio tracks are exposed from the session; `switchLiveAudio` and `setSubtitle` rebuild the stream and reload at the current position so the change never rewinds.
- **Package — playback correctness**: AirPlay 1 can resume/restart at an absolute position by converting it to the `/play` start fraction; polling is stopped and generation-guarded across reloads; proxy routes and temporaries are cleaned before each load.
- **Package — pairing and credentials**: stored `HapCredentials` can be supplied to the session through the service factory, pairing failures remain typed, and the app can trigger a PIN flow and persist credentials per device.
- **Package — AirPlay 2 unified media control**: receivers that only expose `/command` and a `mediaControlPort` (for example the TCL Google TV) get a `streams` `SETUP` path and `/command`-based play/pause/seek/stop/status. This path is explicitly gated on a captured, working video trace; if the gate cannot be met, those receivers keep a clear, actionable unsupported error.
- **App — first-class AirPlay**: add the `airplay` protocol, map it in both directions, register `AirPlayDiscoveryProvider`, include AirPlay in default discovery, and provide protocol-specific capabilities.
- **App — pairing UX**: transient pairing stays automatic (no PIN where the receiver allows it); receivers that require a PIN show a dialog, and credentials are stored per device so later sessions reconnect without prompting.
- **App — platform and UI**: add `_airplay._tcp` to iOS and macOS Bonjour declarations, update local-network usage text, gate audio/subtitle/volume controls on real capabilities, and preserve the existing user edits in the two edited UI screens.
- **Verification and documentation**: package unit/mock-integration coverage for every new path, app adapter/bloc/UI tests, a recorded hardware run on a `/play`-capable receiver, and updated AirPlay docs.

**Out of scope**: screen mirroring, RAOP audio streaming, FairPlay DRM, queueing, and unified media control for receivers that cannot be validated with a real video trace.

## Capabilities

### New Capabilities

- `airplay-connectivity`: discovery, transport selection, transient and PIN pairing, stored credentials, connection lifecycle, and typed failure reporting.
- `airplay-playback`: local and remote media preparation (direct, remux, transcode, HLS), playback control, seek/resume, position/duration/state reporting, and volume behavior.
- `airplay-media-tracks`: audio-track inventory and switching plus subtitle attachment, switching, and removal at the current playback position.
- `airplay-unified-control`: the AirPlay 2 `/command` + `mediaControlPort` path for receivers without `/play`, including its capture-based validation gate.
- `pure-cast-airplay-integration`: the application bridge — protocol enumeration and mapping, discovery registration, capability flags, pairing UX, credential storage, platform permissions, and capability-driven controls.

### Modified Capabilities

- None. The repository has no existing specs; this change introduces the first capability set.

## Impact

- **Package code**: `packages/dart_cast/lib/src/protocols/airplay/` (session, controller, client, features, discovery, new HLS/prep helpers), `lib/src/core/` (FFmpeg commands, prepare session, media proxy, cast session/factory, discovery manager), and `lib/dart_cast.dart` exports.
- **App code**: `lib/core/DI/injection.dart`, `lib/core/features/casting/data/repository/dart_cast_adapter.dart`, `lib/core/features/casting/data/model/pure_cast_models.dart`, `lib/core/features/casting/data/data_source/i_cast_service.dart`, the session and discovery blocs, and the casting/home UI.
- **Platform config**: `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, and any Android multicast-lock handling needed for mDNS.
- **Dependencies**: FFmpeg Kit and the existing media prober are reused; no new runtime dependency is expected. Credential storage uses `shared_preferences` already present in the app.
- **Compatibility**: adds enum values and API surface; no existing protocol behavior changes. AirPlay 1 receivers keep working; `/play`-less receivers either gain unified control or fail with a precise message.
- **Risk**: unified media control cannot be guaranteed without a captured working video trace from a sender to the target receiver. That phase is a gate, not an assumed success.
