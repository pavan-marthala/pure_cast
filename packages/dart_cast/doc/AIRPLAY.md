# AirPlay status

**Short version: the package now implements the full `/play` video path —
direct play, local-file preparation, resume, track switching, subtitles and
volume. It has not been run end to end on a receiver that implements `/play`.
One receiver ("Living Room") answers `/play` with HTTP 400 when
the request uses the legacy `text/parameters` body; that body has been replaced
with the binary plist form pyatv uses, and the replacement is still untested on
that receiver. On the receivers tested so far `/play` is either absent or
rejected, so video casting there still fails; use Chromecast or DLNA for those
devices.**

Pairing and session setup work on a physical TV, and local-file planning,
preparation commands, HLS playlists and session behavior are covered by tests.
Whether a real AirPlay receiver accepts the prepared stream is the one thing
tests cannot answer. The first receiver with `/play` should be treated as an
unverified target until a trace is recorded.

## What works

- Device discovery, including correct decoding of the capability bitmask
- Transient pairing (`X-Apple-HKP: 4`) — no PIN, no stored credentials, which is
  what modern smart TVs use
- PIN-based HAP pairing (`X-Apple-HKP: 3`) for devices that show a passcode
- The encrypted session: pair-verify, RTSP `SETUP` with a live UDP timing
  server, the event channel, `RECORD` and keep-alive
- Remote MP4/HLS playback over `POST /play`, with an Apple binary plist body
  carrying `Content-Location`, `Start-Position` and `X-Apple-Session-ID`
- Local-file playback through direct play, MP4 remux, H.264/AAC transcode, or
  seekable VOD HLS
- Resume at an absolute position on AirPlay 2, and at a duration fraction on
  AirPlay 1
- Audio-track and subtitle selection, performed by rebuilding the stream and
  reloading at the current position
- Volume on receivers advertising video volume control (bit 3)

Discovery, pairing and the encrypted session are confirmed against a physical
TV. Everything below the `/play` line is verified by tests and mocks, not by a
recorded hardware trace.

## The playback path

Both AirPlay 1 transports (the plain HTTP client and the HAP-backed media
controller) send `/play` with `Content-Type: application/x-apple-binary-plist`
and an Apple binary property list. The legacy `text/parameters` body is kept as
`AirPlayMediaController.playV1Text` for diagnostics only; it is never sent
automatically. A non-200 `/play` throws with the status code and a bounded,
escaped preview of the response body, and is not retried with the other body
encoding — a second request would hide which body the receiver rejected.

`AirPlaySession.loadMedia` accepts a remote URL or application-supplied bytes
and hands it to the proxy. `AirPlaySession.loadLocalFile` probes a local file
once and chooses a preparation strategy:

| Plan | When | Output |
|---|---|---|
| Direct | MP4/MOV/M4V, H.264 ≤ level 4.2 8-bit, AAC/MP3/MP2 audio | Original file served through the proxy |
| Container remux | Compatible streams in MKV/TS/other containers | `-c copy` fast-start MP4 |
| Audio remux | Compatible video, AC-3/E-AC-3/FLAC/Opus/Vorbis/DTS audio | Video copied, stereo AAC 192 kbit/s |
| Transcode | HEVC/VP9/AV1, 10-bit or high-level H.264, with an FFmpeg H.264 encoder | H.264 High profile, stereo AAC, fast-start MP4 |
| HLS | A subtitle is requested, or a track switch needs multiple renditions | VOD HLS directory with a master playlist, video variant, one audio rendition per track, optional WebVTT subtitle rendition |
| Unsupported | No video stream, or a codec needing a transcode with no encoder | Typed `UnsupportedMediaException` before anything is sent |

The planner lives in
[`airplay_media_plan.dart`](../lib/src/protocols/airplay/airplay_media_plan.dart).
AC-3 is deliberately not treated as directly playable: only some receivers
decode it, and the same conservative rule is used by the Chromecast and DLNA
pipelines.

### Startup cost

- Direct play: no local work; one proxy registration, then `/play`.
- Container/audio remux: roughly the time to copy the file. For a large MKV
  this is disk-bound but still waits for the whole file before `/play`.
- Transcode: full encode time before playback starts. FFmpegKit uses
  `h264_mediacodec` when the device advertises it, otherwise `libx264`.
- HLS: one video pass plus **one audio pass per track**, plus local WebVTT
  segmentation. A file with three audio tracks is four FFmpeg runs. With
  `-c copy` each is fast; with a video transcode each re-encodes the video
  unless the video is copied.

Preparation is synchronous from the caller's point of view: `loadLocalFile`
completes only after the output is ready. There is no progress stream yet, so
the UI should show an indeterminate loading state rather than a percentage.

### Compatibility limits

- Direct video requires H.264 (AVC) at 8-bit and level 4.2 or below. The level
  bound is conservative; a receiver that accepts higher levels still gets a
  transcode.
- Direct audio is AAC, MP3 or MP2. Everything else is converted to stereo AAC.
- Multi-channel audio is downmixed to stereo for remux/transcode/HLS paths.
- Subtitles require HLS support (feature bit 4). A receiver without it gets a
  typed `UnsupportedFeatureException` and playback is not interrupted.
- Prepared HLS is VOD, not a live pipe: `AirPlaySession.isLive` stays `false`.
- Preparation output is written under the platform temporary directory and is
  deleted on the next load, on `stop`/`disconnect`, and on failures.

## Resume and seeking

- AirPlay 2 sends `Start-Position-Seconds` as an absolute value.
- AirPlay 1 only has a 0.0–1.0 `Start-Position`. When the duration is known the
  session converts the absolute offset to a fraction. When it is not known it
  starts at the beginning and sends `/scrub` immediately afterwards.
- `/scrub` is used for explicit seeks.

A load stops the previous poll timer and increments a generation token before
`/play`. A `/playback-info` reply that arrives after a replacement load is
discarded, so an old position cannot jump the new stream backwards.

`/playback-info` is polled once per second. If a report omits `duration`, the
session keeps the duration from the probe or the caller instead of overwriting
it with zero. A receiver-reported playback error stops polling and returns the
session to `idle`.

## Audio tracks

`CastSession.audioTracks` and `CastSession.activeAudioIndex` expose the tracks of
the loaded local file. On AirPlay they describe the probe, not a receiver-side
track list.

AirPlay has no in-place track selection. `switchLiveAudio` rebuilds the stream
as VOD HLS with the selected audio rendition, then reloads it at the requested
position. The new stream is prepared **before** the old one is replaced, so a
preparation failure leaves current playback untouched.

The interruption is a reload: the receiver loses its buffer and starts a new
`/play`. This is not a gapless switch, and the UI should not claim otherwise.

## Subtitles

`setSubtitle` and `switchLiveSubtitle` attach, replace or clear a subtitle by
rebuilding the HLS master playlist and reloading at the current position.
WebVTT is split into short HLS subtitle segments with a valid
`EXT-X-TARGETDURATION` (6 seconds by default) rather than a single 99999-second
segment.

Subtitle cues stay on the media timeline, which is what HLS subtitle renditions
expect. A receiver without HLS support returns a typed error and keeps playing
the current stream.

## Volume

`setVolume` sends `/volume?volume=<0.0–1.0>` only when the receiver advertises
video volume control (bit 3). Without that bit the session throws
`UnsupportedFeatureException`; it does not store a local value and pretend the
change happened.

## Pairing and credentials

The transport is chosen from advertised feature bits, never by probing:

- AirPlay 2 (bit 38 or 48) opens a single raw socket and pairs on it.
- Transient pairing (bit 43 or 48) is used automatically when the caller has no
  stored credentials. No PIN is involved.
- Otherwise the receiver requires typed pairing: `connect()` throws
  `NeedsPairingException`, the app shows a PIN dialog, and `pairSetup(pin)`
  stores `HapCredentials` for the next connection. Pair-verify reuses those
  credentials on the same socket.

The same TCP connection is used for pairing and for the encrypted HAP session,
because receivers bind authentication state to the connection.

### iOS system AirPlay versus this sender

On iOS, the operating system owns the AirPlay trust relationship. An app that
hands a URL to the system picker rarely sees a PIN prompt and never manages
credentials itself. `dart_cast` is a cross-platform sender and therefore has to
pair on its own behalf: transient pairing when the receiver allows it, typed
pairing otherwise. That difference is expected, not a bug.

Android can cast to an Apple TV at the application layer because both devices
speak AirPlay over the LAN. The Android app performs pairing and HAP itself;
the Apple TV does not require an Apple ID or an iOS device.

## Devices tested

| Device | `features` | Video V1 (bit 0) | Video V2 (bit 49) | `/play` |
|---|---|---|---|---|
| TCL JX32B / Google TV | `0x000bcf46007f8ad0` | No | Yes | **404 — endpoint absent** |
| Roku Express | `0x038bcf46007f8ad0` | No | Yes | Not tested |
| "Living Room" receiver | `0x1e527ffff7` | Yes | No | **400 with `text/parameters`; binary plist not yet verified** |
| macOS AirPlay receiver | `0x38174fde4a7fcfd5` | Yes | Yes | Not tested |
| Apple TV | — | — | — | Never tested |

The "Living Room" receiver accepts the plain AirPlay 1 path (bit 0, HLS bit 4, no HAP or
AirPlay 2 bits) but exports neither `/info` nor `/server-info`, so its 400 has
to be resolved from the `/play` request itself. Neither smart TV advertises
AirPlay 1 video, and all of them want PIN-less transient pairing — which is why
the package picks its protocol version from the advertised bits rather than
probing.

## Trying it on your own device

Other receivers may implement `/play` — an Apple TV is the obvious candidate,
and none has been tested. Two scripts will tell you without guesswork:

```bash
# What the device advertises: capability bits, pairing mode, reachable ports.
# Touches nothing.
dart run tool/airplay_probe.dart

# Full connect → pair → SETUP → play → poll, printing every wire step.
dart run tool/airplay_hardware_check.dart <TV_IP>
```

If `/play` returns 200 on your device, playback should work and I'd be glad to
hear about it — please open an issue with the trace.

## Deeper detail

Raw traces, the receiver's own ADB logs and the full investigation are in
[`specs/2026-07-25-airplay-hardware-results.md`](specs/2026-07-25-airplay-hardware-results.md).

The unified-control investigation is in
[`protocol-references/airplay-unified-control.md`](protocol-references/airplay-unified-control.md).

One finding worth flagging for anyone comparing implementations: **pyatv
mis-parses two-part feature strings.** Its `parse_features` concatenates the two
hex strings rather than shifting the upper word by 32 bits, so a device that
omits leading zeros (`0x7F8AD0,0xBCF46`) is decoded 24 bits off and reports no
video support. This package shifts, which matches the value the device reports
for itself.
