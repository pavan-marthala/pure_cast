# Proposal

## Why

AirPlay is the only supported protocol that has not reached parity with Chromecast and DLNA. The package can discover, pair with, and hand-shake an AirPlay receiver, but it cannot prepare local media for playback, switch audio or subtitles, or reliably resume, and the app deliberately hides AirPlay from discovery and connection. Shipping without it leaves Apple TV users with no working path and makes the product's protocol matrix inconsistent.

## What Changes

- **Package — media pipeline**: `AirPlaySession.loadLocalFile` probes the source and chooses direct play, container/audio remux, or H.264/AAC transcode; prepares MP4 for the common case and a seekable VOD HLS directory when subtitles or multi-audio are involved.
- **Package — track control**: audio tracks are exposed from the session; `switchLiveAudio` and `setSubtitle` rebuild the stream and reload at the current position so the change never rewinds.
- **Package — playback correctness**: AirPlay 1 can resume/restart at an absolute position by converting it to the `/play` start fraction; polling is stopped and generation-guarded across reloads; proxy routes and temporaries are cleaned before each load.
- **Package — AirPlay 1 `/play` request format**: send the Apple binary plist body (`Content-Type: application/x-apple-binary-plist`, `Content-Location`, `Start-Position`, `X-Apple-Session-ID`) on the plain AirPlay 1 transport, matching the HAP path, instead of `text/parameters`. The recorded Living Room receiver (features `0x1e527ffff7`, video bit 0 set, no HAP or AirPlay 2 bits) rejects the text body with HTTP 400 before fetching the media. `/play` failures also carry the status and a bounded response preview so the next receiver rejection is diagnosable without a packet capture.
- **Package — pairing and credentials**: stored `HapCredentials` can be supplied to the session through the service factory, pairing failures remain typed, and the app can trigger a PIN flow and persist credentials per device.
- **Package — AirPlay 2 unified media control**: receivers that only expose `/command` and a `mediaControlPort` (for example the TCL Google TV) get a `streams` `SETUP` path and `/command`-based play/pause/seek/stop/status. This path is explicitly gated on a captured, working video trace; if the gate cannot be met, those receivers keep a clear, actionable unsupported error.
- **App — first-class AirPlay**: add the `airplay` protocol, map it in both directions, register `AirPlayDiscoveryProvider`, include AirPlay in default discovery, and provide protocol-specific capabilities.
- **App — pairing UX**: transient pairing stays automatic (no PIN where the receiver allows it); receivers that require a PIN show a dialog, and credentials are stored per device so later sessions reconnect without prompting.
- **App — platform and UI**: add `_airplay._tcp` to iOS and macOS Bonjour declarations, update local-network usage text, gate audio/subtitle/volume controls on real capabilities, and preserve the existing user edits in the two edited UI screens.
- **Verification and documentation**: package unit/mock-integration coverage for every new path, app adapter/bloc/UI tests, a recorded hardware run on the Living Room receiver at `192.168.31.20:27131`, and updated AirPlay docs.

**Out of scope**: screen mirroring, RAOP audio streaming, FairPlay DRM, queueing, and unified media control for receivers that cannot be validated with a real video trace. The Living Room receiver advertises the video play-queue bit (33) but no HAP or unified-control bit; a speculative `/command` implementation is not added unless the `/play` fix fails and a working trace is captured.

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

- **Package code**: `packages/dart_cast/lib/src/protocols/airplay/` (session, controller, client, features, discovery, new HLS/prep helpers), `lib/src/core/` (FFmpeg commands, prepare session, media proxy, cast session/factory, discovery manager), and `lib/dart_cast.dart` exports. The AirPlay 1 request-format fix touches `airplay_client.dart`, its mock server and client tests, and the hardware-check trace.
- **App code**: `lib/core/DI/injection.dart`, `lib/core/features/casting/data/repository/dart_cast_adapter.dart`, `lib/core/features/casting/data/model/pure_cast_models.dart`, `lib/core/features/casting/data/data_source/i_cast_service.dart`, the session and discovery blocs, and the casting/home UI.
- **Platform config**: `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, and any Android multicast-lock handling needed for mDNS.
- **Dependencies**: FFmpeg Kit and the existing media prober are reused; no new runtime dependency is expected. Credential storage uses `shared_preferences` already present in the app.
- **Compatibility**: adds enum values and API surface. AirPlay 1 `/play` changes from a `text/parameters` body to the binary plist body the recorded receiver and pyatv require; Chromecast and DLNA are unchanged. `/play`-less receivers either gain unified control or fail with a precise message.
- **Risk**: unified media control cannot be guaranteed without a captured working video trace from a sender to the target receiver. That phase is a gate, not an assumed success. If the Living Room receiver still rejects the binary `/play`, its `/command` path must be captured before it is implemented rather than guessed.

## Verification status

Recorded at implementation time. "Hardware" means a receiver was observed; "tests" means unit or mock coverage only.

| Capability | Tests | Hardware |
|---|---|---|
| AirPlay discovery and feature decoding | Yes | Yes (TCL JX32B, Roku Express, Living Room) |
| Transient and PIN pairing, credential reuse | Yes | Pairing confirmed on a physical TV; PIN reuse on the Living Room receiver not recorded |
| Remote MP4/HLS over `/play` | Yes | **No** — TCL has no `/play`; Living Room returned 400 with the old text body, binary plist not yet run |
| Local MP4/MKV/TS preparation and playback | Yes | **No** |
| Seek and resume | Yes | **No** |
| Audio and subtitle switching (reload) | Yes | **No** |
| Volume (bit 3) | Yes | **No** — recorded receivers clear bit 3 |
| `/command` unified media control | Not implemented | Gate not met (no working trace) |

The matrix in `packages/dart_cast/doc/AIRPLAY.md` and the package/app READMEs matches this table. The open hardware tasks (1.2, 3.9, 9.3) are the measurements that would move the "No" rows to "Yes".
