# AirPlay 2 unified media control — reference and gate status

## Result

**No validated payload was obtained.** The unified-control implementation in
`dart_cast` remains disabled behind a documented gate.

A working video trace from a sender to a `/command`-only receiver was not
available:

- The TCL JX32B / Google TV receiver examined in
  [`../specs/2026-07-25-airplay-hardware-results.md`](../specs/2026-07-25-airplay-hardware-results.md)
  exports only `/command`, `/feedback`, `/info` and `/server-info`.
- No sender produced a video stream on that receiver, from this package or from
  QuickTime Player, so there is no sequence of `streams` `SETUP` and `/command`
  bodies to decode.
- Packet capture was not performed against a working receiver.

Without decoded, accepted payloads, implementing `SETUP` and `/command` would
be guesswork. Receivers that expose only `/command` therefore still receive a
typed `UnsupportedFeatureException` after the AirPlay 2 handshake.

## What is known

- The receiver accepts the HAP handshake up to and including `RECORD`.
- It answers AirPlay 1 `/play` with **404**, not 403 or 470. The endpoint is
  absent rather than unauthorized.
- The string `Content-Location` — the key every AirPlay 1 `/play` body is built
  around — does not appear in the receiver binary.
- The receiver advertises AirPlay 2 unified media control (feature bit 38).
- Screen mirroring works on the receiver; media casting does not, for any
  sender.

## Why the gate exists

AirPlay 2 unified media control replaces the HTTP `/play`, `/rate`, `/scrub`
and `/playback-info` endpoints with:

- a `streams` `SETUP` that declares the media and its data channels
- a `mediaControlPort` used to open an event/command channel
- `/command` bodies carrying play, pause, seek and status

The exact key names, value types and ordering matter. A plausible-looking body
that a receiver rejects is worse than a clear unsupported error, because it
looks like playback was requested and leaves the user waiting.

Feature bit 38 is not sufficient evidence to enable the path. It says the
receiver can use unified control; it does not say which payload shape this
sender should use.

## What to capture before implementing

From a sender that successfully plays a video on a `/command`-only receiver:

1. The complete `SETUP` request for the `streams` data channel, including
   timing/event ports and any plist body.
2. The `mediaControlPort` value and how the command channel is opened.
3. The exact `/command` bodies for play, pause, seek, stop, volume and status.
4. The receiver's replies and any asynchronous status messages.
5. A second run with an audio track change and a subtitle, if supported.

Record raw bytes, not reconstructed summaries. Then implement against the
trace, add mock-server tests that reject malformed bodies, and repeat the
hardware check.

## Current behavior

`AirPlayMediaController.play` classifies the device from its feature bits:

- video V1 (bit 0) → AirPlay 1 `/play`
- video V2 (bit 49) → AirPlay 2 `/play`
- AirPlay 2 handshake but no video bit and a 404 from `/play` → typed
  `UnsupportedFeatureException` naming unified media control

No unified-control command is sent on any path. See
[`../AIRPLAY.md`](../AIRPLAY.md) for the device matrix.
