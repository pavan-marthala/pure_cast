# Design

## Context

See `proposal.md` for motivation. The current implementation and constraints that shape this design:

- `AirPlaySession` already establishes AirPlay 1 and AirPlay 2 sessions, including transient and PIN pairing, HAP encryption, RTSP `SETUP`/`RECORD`, a UDP timing server, `/play`, `/rate`, `/scrub`, `/stop`, and `/playback-info` polling. It has no local-media preparation and no track switching.
- The shared `CastSession` contract already has the parity surface used by Chromecast and DLNA: `loadLocalFile`, `switchLiveAudio`, `switchLiveSubtitle`, `isLive`, `liveStartOffset`, `liveAudioTracks`, and `liveSessionToken`. AirPlay can implement the same surface without protocol-specific gates in the app.
- AirPlay has no in-place track-selection command for `/play`-based streams. A change must rebuild the stream or playlist and reload it.
- AirPlay 1 `/play` expresses the start position as a fraction; AirPlay 2 accepts absolute seconds.
- Receivers that only expose `/command` and a `mediaControlPort` are a different protocol path. The only receiver examined (TCL Google TV) does not implement `/play`, and even Apple's sender negotiates an audio session with it, so a working video trace has never been captured for that device.
- The app currently maps AirPlay to Chromecast, rejects it in the session factory, and excludes it from default discovery.
- The user has edited `device_manager_screen.dart` and `media_crontroller_screen.dart`; those changes must be preserved.

## Goals / Non-Goals

**Goals:**

- Full `/play`-based AirPlay parity for local files, remote media, resume/seek, audio tracks, subtitles, and state reporting.
- A pairing model that works for both transient receivers and PIN-protected receivers, with credentials persisted per device.
- First-class AirPlay in the app, including discovery, capabilities, pairing UX, platform permissions, and capability-driven controls.
- A guarded unified-media-control path for `/command`-only receivers, with a capture-based validation gate so the app never claims unverified playback.
- Package and app tests that cover each new behavior, plus a recorded hardware run on a `/play`-capable receiver.

**Non-Goals:**

- Screen mirroring, RAOP audio streaming, FairPlay DRM, queueing, and AirPlay 3.
- Making a receiver that cannot video-cast from Apple's own sender work through a speculative protocol implementation.
- Supporting audio-only media as a first-class AirPlay cast target; it fails with a clear error instead of being silently treated as video.
- A general redesign of the casting domain; the app changes stay within the existing adapter/bloc/model patterns.

## Decisions

### 1. Implement AirPlay through the shared `CastSession` surface

AirPlay will override `loadLocalFile`, `switchLiveAudio`, and `switchLiveSubtitle` and use the existing session state/position/duration plumbing. The app continues to call the protocol-neutral `ICastService` API.

**Why:** Chromecast and DLNA already establish the contract, the app's bloc already handles live/parity behavior, and adding `is AirPlaySession` branches would recreate the protocol gates this work is meant to remove.

**Alternative considered:** a separate AirPlay-specific app API. Rejected because it would fork the bloc and UI and make future protocols harder.

### 2. Use a dedicated AirPlay media planner

A small AirPlay-specific planner will inspect the probe and choose:

| Input | Output |
|---|---|
| H.264 (≤ level 4.2) + AAC/MP3 + MP4/MOV, no subtitle or multi-audio need | Direct play |
| H.264 + MKV/TS/AVI/WebM, or incompatible audio | MP4 remux (`-c:v copy`, audio copy or AAC) |
| HEVC/VP9/AV1/10-bit | H.264/AAC transcode when enabled |
| Subtitles requested, or HLS chosen for track switching | Seekable VOD HLS with a master playlist |
| No video stream | Typed unsupported-media error |

**Why:** the shared `decide()` treats MKV/WebM as direct containers and AC3 as compatible, which is tuned for Chromecast and DLNA. Reusing it unchanged would send containers AirPlay receivers commonly reject.

**Alternative considered:** extend `CastDeviceCaps` with per-protocol container sets. Rejected because it would make the shared decision function harder to reason about and risk regressions in the other two protocols.

### 3. Prefer direct MP4, use prepared VOD HLS only when needed

The common case stays a direct MP4 URL. VOD HLS is prepared when subtitles are active or when a track switch needs audio renditions. Preparation completes before `/play`.

**Why:** AirPlay's `/scrub` is reliable on a static VOD playlist. A live TS pipe like DLNA's gives faster startup but makes forward seeks into not-yet-produced segments unreliable, and AirPlay has no equivalent of Chromecast's media-session restart semantics.

**Trade-off:** long transcodes delay playback. Mitigation: the fast MP4 path covers most files; transcode uses the existing `veryfast` preset and 1080p cap; the UI already has a `preparing` state for local files.

**Alternative considered:** always HLS. Rejected because it adds unnecessary FFmpeg work to files that AirPlay can already play.

### 4. Track changes rebuild and reload at the current position

`switchLiveAudio` and `setSubtitle` will:

1. Remember the source path, active audio index, subtitle list, duration, and current position.
2. Rebuild the MP4/HLS output with the requested audio track or subtitle rendition.
3. Reload at the current position:
   - AirPlay 2: `Start-Position-Seconds`.
   - AirPlay 1: `Start-Position` fraction (`position / duration`), followed by `/scrub` as a safety net when the duration is unknown.
4. Increment a load generation so late `/playback-info` responses from the replaced stream are ignored.

For multi-audio files the HLS/remux output is prepared lazily on the first switch, preserving fast startup for viewers who never switch.

**Why:** this is the only mechanism the protocol offers, and it satisfies the “no rewind” requirement by preserving position.

**Alternative considered:** prepare HLS for every multi-audio file at load time. Rejected as unnecessary startup cost.

### 5. HLS output is generated by FFmpeg and a Dart master writer

FFmpeg produces the video variant and audio playlists (H.264/AAC, TS segments for broad compatibility). A Dart helper composes `master.m3u8` with `EXT-X-MEDIA` audio and subtitle groups, and a WebVTT HLS segmenter produces subtitle playlists with a valid `EXT-X-TARGETDURATION` (splitting long files rather than emitting the current `99999` value).

**Why:** FFmpeg's `var_stream_map` covers the heavy lifting; composing the master in Dart gives exact control over `DEFAULT=YES`, language, and subtitle names, and makes the playlist easy to unit test.

**Alternative considered:** keep `registerSubtitleWrapper` and add the `99999` playlist. Rejected because that target duration is outside HLS limits and Apple receivers may reject it.

### 6. Preserve AirPlay 1 start positions with a known duration

`AirPlayMediaController.play` will accept the media duration. If it is known, a non-zero start is sent as a fraction. If it is not, the session plays from zero and scrubs to the position.

**Why:** the current code drops the start position on AirPlay 1, which breaks resume and every restart-based track change.

### 7. AirPlay 1 `/play` always uses a binary plist body

Both AirPlay 1 transports will send `POST /play` with `Content-Type: application/x-apple-binary-plist` and an Apple binary property list containing `Content-Location`, `Start-Position` (the 0.0–1.0 fraction), and `X-Apple-Session-ID`. This replaces the plain HTTP client's `text/parameters` body; the HAP controller already uses the binary form.

**Why:** the recorded Living Room receiver (mDNS features `0x1e527ffff7`: video bit 0 and HLS bit 4 set, no HAP or AirPlay 2 bits) answers the plain text body with HTTP 400 before it fetches the media. The failure is on the `/play` request itself, so the local MKV remux and the media proxy are not implicated. pyatv's AirPlay 1 implementation and the published protocol notes both use the binary plist for `/play`; the text body is a legacy alternative that this receiver rejects. The receiver also exports neither `/info` nor `/server-info`, so the 400 cannot be resolved from device metadata and must be verified on the receiver.

**Alternative considered:** automatically retry with the other body encoding after a 400. Rejected: a second `/play` can start a second item, and feature bits do not distinguish body-format support. If a text-only receiver appears, it gets an explicit compatibility profile and one recorded fallback rather than every rejection issuing two play commands.

**Diagnostics:** the exception and log include the status code and a bounded, escaped preview of the response body. This is required because a 400 from a receiver with no device-info endpoint is otherwise indistinguishable from an unreachable media URL.

### 8. Pairing: transient when allowed, PIN when required, credentials persisted

- No credentials and bit 43/48 → transient pairing, no prompt.
- No credentials and no transient support → typed pairing-required failure; the app shows a PIN dialog; successful `pairSetup` credentials are stored per device and reused.
- Stored credentials rejected → discard and re-prompt.

**Why iOS/macOS feel PIN-free:** when an Apple app uses the system AirPlay picker, the operating system is the sender and owns the trust relationship, so the user rarely sees a PIN. Pure Cast implements its own cross-platform sender, so it must perform HAP pairing itself. Receivers set to “Everyone” accept transient pairing; receivers set to require a password, or Apple TV on first use, need the on-screen PIN.

**Android → Apple TV:** the AirPlay sender protocol is application-layer and platform-independent. The Dart implementation runs on Android and connects to an Apple TV over the LAN exactly as it does from iOS or macOS. The only platform concerns are multicast permissions for discovery and cleartext HTTP to the receiver, both already available in the manifest.

**Credential storage:** a small `AirPlayCredentialStore` backed by `shared_preferences`, keyed by the AirPlay `deviceid`, loaded once and cached so the synchronous `SessionFactory` can read it. Secure storage is a later hardening step; the spec does not require it.

### 9. Unified media control is profile-gated and capture-validated

A unified-control implementation will not be enabled by feature bit alone. The design introduces an `AirPlayCommandProfile` registry keyed by receiver model/feature fingerprint. A profile is added only after a captured working video trace documents the `SETUP` streams payload and the `/command` body for play, pause, seek, stop, and status.

Recommended sequence:

1. Capture a working sender→receiver video session (Apple device or a known-good implementation) with packet capture and receiver logs.
2. Decode the `streams` `SETUP` and `/command` requests and record them in `doc/protocol-references/`.
3. Implement the controller and add one allowlisted profile.
4. Verify against the receiver.

If step 1 cannot produce a working video trace, the `/play` path still ships and unified-control candidates receive the existing explicit unsupported error. This is deliberate: a speculative implementation that reports success without playback is worse than a clear failure.

**Alternative considered:** implement from public reverse-engineering notes without a trace. Rejected because there is no authoritative specification and the receiver-side behavior is the only proof that matters.

### 10. App integration stays thin and capability-driven

- Add `PureCastProtocol.airplay`; map AirPlay both ways; add AirPlay to the default discovery set and DI providers.
- Add per-device capability inputs so AirPlay can hide volume when bit 3 is clear and subtitles when HLS bit 4 is clear. `PureCastCapabilities.forProtocol` remains the fallback.
- Add a typed pairing-required domain error and `connectWithPin` to `ICastService`; the session bloc exposes a pairing state, and the UI shows the PIN dialog.
- Gate the audio row on `canChangeAudioTrack` (a minimal edit in the user-edited screen, preserving the rest of the file) and hide/disable volume and subtitles when unsupported.
- Add `_airplay._tcp` to iOS and macOS `NSBonjourServices`, update the local-network description, and verify Android multicast discovery.

**Why:** this mirrors how Chromecast and DLNA are already integrated and avoids a second casting architecture.

### 11. Test seams and verification

- Reuse the package's FFmpeg/prober seams and mock AirPlay servers for deterministic tests.
- Add tests for: planner branches, MP4 remux arguments, HLS master and subtitle validity, AirPlay 1 binary `/play` body and fraction start, `/play` status/preview errors with no retry, stale-poll suppression, switch-at-position, credential reuse, and unified-control profile gating.
- App tests for mapping, capabilities, pairing state, and UI gates.
- Hardware run with `tool/airplay_hardware_check.dart` on the recorded Living Room receiver at `192.168.31.20:27131`, recorded in `doc/specs/`.
- Run the package suite with the known parallel-load flakiness in mind (individually for the affected tests) and the app suite against its known `cast_player_controls_test.dart` baseline.

## Risks / Trade-offs

- **[Unified control has no working trace]** → Ship it behind the profile gate; the rest of AirPlay parity does not depend on it. Document the unsupported error and keep the capture task as a hard phase gate.
- **[Long transcodes delay AirPlay startup]** → Direct MP4 fast path, lazy HLS, `veryfast`/1080p limits, and visible preparation state.
- **[AirPlay 1 fraction rounding]** → Use the known probe duration and follow with `/scrub`; keep AirPlay 2 on absolute seconds.
- **[AirPlay 1 body-format compatibility]** → Use the binary plist form that pyatv and the protocol notes specify; the recorded receiver rejects the text form. Keep the legacy text helper for diagnostics only, and add a recorded fallback profile if a genuinely text-only receiver appears. Never retry two bodies automatically.
- **[Living Room still rejects the binary `/play`]** → The receiver advertises play-queue bit 33 but no HAP or unified-control bit. If the binary request still returns 400, capture the response body and the receiver's `/command` exchange, then implement the play-queue path only under the same captured-trace gate as unified control; otherwise record the receiver as unsupported with a precise error. Do not guess a `/command` body.
- **[Subtitle HLS compatibility]** → Segment WebVTT with a valid target duration and test the generated playlists; gate subtitles on HLS support.
- **[Credential security in `shared_preferences`]** → Accept for release; plan secure storage as a follow-up. Credentials are device pairing keys, not account passwords.
- **[iOS local-network privacy / Bonjour]** → Add the service declarations and usage text; verify on device. Android multicast may need a `MulticastLock` on some devices; verify and add only if needed.
- **[`content://` local files]** → Resolve through Android's Storage Access Framework (`FFmpegKitConfig.getSafParameterForRead`) before FFprobe/FFmpeg preparation; otherwise AirPlay cannot read the source. If SAF returns null, fail with a readable error instead of handing FFmpeg the raw URI. Include this in the app routing work.
- **[User-edited UI files]** → Keep edits to the smallest capability-gate change and avoid reformatting.
- **[Package test-suite flakiness]** → Validate new tests individually and note pre-existing parallel timeouts.

## Migration Plan

- No database migration. `PureCastProtocol` gains a value; existing persisted media/history is unaffected.
- Credentials live under a new `airplay.credentials.<deviceId>` namespace and are ignored by older builds.
- Rollback: remove `AirPlayDiscoveryProvider` from the provider list and restore the AirPlay rejection in the session factory. No destructive data changes; stored credentials can remain.
- Release sequencing: land package support first, then app integration, then the hardware run. Unified control is released only for validated profiles.

## Open Questions

- The exact unified-control `SETUP` and `/command` payloads are unknown until the capture task is completed. This blocks only that phase; the approach and the rest of the task breakdown do not change.
- Whether the available receiver requires a PIN on first connection is environment-specific; the flow covers both paths, so acceptance does not depend on the answer.
- Whether to move credentials to secure storage before public release is a product/security decision that can be made after the functional pass.
