# pure_cast

A Flutter app for casting local and remote media to Chromecast, DLNA, and
AirPlay receivers.

## Supported protocols

| Capability | Chromecast | DLNA | AirPlay |
|---|---|---|---|
| Discovery | Yes | Yes (SSDP) | Yes (Bonjour `_airplay._tcp`) |
| Remote MP4 / HLS | Yes | Partial (MP4 not supported) | Yes (`/play` receivers) |
| Local files | Yes | Yes | Yes, including MKV/TS via remux or transcode |
| Seek / resume | Yes | Yes | Yes |
| Audio track switching | Yes | Yes | Yes, rebuilds the stream at the current position |
| Subtitle switching | Yes | Reload | Yes, rebuilds a VOD HLS stream at the current position |
| Volume | Yes | Yes | Only when the receiver advertises video volume control |
| PIN pairing | — | — | Yes, when the receiver requires it |

AirPlay playback requires a receiver that exposes the `/play` endpoint. The
package-level status and compatibility notes live in
[`packages/dart_cast/doc/AIRPLAY.md`](packages/dart_cast/doc/AIRPLAY.md).
AirPlay video has not been verified end to end on hardware yet: the recorded
"Living Room" receiver rejected the old `/play` body with HTTP 400, and the
replacement binary plist form still needs a run on that device.

## AirPlay pairing

1. Tap the AirPlay receiver in the device sheet.
2. If it supports transient pairing, the connection completes without a PIN.
3. If it requires pairing, the receiver shows a 4-digit code. Enter it in the
   in-app prompt and tap **Connect**.
4. Credentials are stored per receiver, so later connections use pair-verify
   and skip the prompt.
5. Cancelling the prompt discards the half-connected session; nothing is saved.

If a stored credential is rejected (for example after resetting the receiver),
it is deleted automatically and the next attempt asks for a PIN again.

## Platform notes

- iOS and macOS list `_airplay._tcp` in `NSBonjourServices` and require local
  network access for discovery and playback.
- Android discovers AirPlay receivers over multicast DNS on the local network.
- On iOS, system AirPlay owns the sender trust relationship; the in-app pairing
  flow is for the cross-platform AirPlay sender used by this app.

## Getting Started

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
