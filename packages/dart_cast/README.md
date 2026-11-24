# dart_cast

Cast media to Chromecast, AirPlay, and DLNA devices from pure Dart.

<!-- Badges placeholder -->
<!-- [![pub package](https://img.shields.io/pub/v/dart_cast.svg)](https://pub.dev/packages/dart_cast) -->
<!-- [![build](https://github.com/abdelaziz-mahdy/dart_cast/actions/workflows/ci.yml/badge.svg)](https://github.com/abdelaziz-mahdy/dart_cast/actions) -->

## Features

- **Chromecast (CASTV2)** -- TLS + protobuf with default media receiver
- **AirPlay** -- HTTP video casting with HAP authentication and feature detection
- **DLNA/UPnP** -- SSDP discovery, SOAP AVTransport control
- **Cross-platform** -- Android, iOS, macOS, Windows, Linux
- **Built-in HTTP proxy** -- injects custom headers transparently for cast devices
- **HLS rewriting** -- rewrites m3u8 playlist URLs through proxy automatically
- **Subtitle support** -- WebVTT and SRT with automatic SRT-to-VTT conversion
- **Local file serving** -- serves downloaded content via proxy with `MediaTransformer` interface
- **Pluggable discovery** -- swap in native mDNS (e.g., bonsoir) on Apple platforms
- **750+ tests** -- mock servers for each protocol

## Protocol Status

| Protocol | Use it for | Status |
|---|---|---|
| **Chromecast** | Streaming, local files, subtitles | **Recommended** |
| **DLNA** | Local files, especially MKV with embedded subtitles | Works |
| **AirPlay** | `/play` receivers, local files, tracks | Implemented; not yet verified end to end on a `/play` receiver — [status](doc/AIRPLAY.md) |

> For local file casting, remux `.ts` to `.mp4` with ffmpeg.
> See [`doc/LOCAL_FILE_CASTING.md`](doc/LOCAL_FILE_CASTING.md).

### What Works Where

| Use Case | Chromecast | DLNA | AirPlay |
|----------|-----------|------|---------|
| Stream HLS (remote) | Yes | Partial (piped as TS) | Implemented† |
| Stream MP4 (remote) | Yes | No | Implemented† |
| Local MP4 / TS files | Yes | Yes | Implemented† |
| Local MKV files | No | Yes | Implemented† |
| Custom byte sources (`content://`, assets) | Yes | Yes | Implemented† |
| Subtitles (sidecar VTT) | Yes | No | Via VOD HLS (requires HLS bit)† |
| Subtitles (MKV embedded) | — | Yes | — |
| Seeking / resume from position | Yes | Yes | Implemented† |
| Volume control | Yes | Yes | Bit 3 receivers only† |
| Subtitle switching | Yes | Requires reload | Reloads at position (requires HLS bit)† |

\† Implemented for receivers that expose `/play`. The receivers tested so far
do not, so end-to-end playback is not yet recorded on hardware — see
[`doc/AIRPLAY.md`](doc/AIRPLAY.md).

### Protocol Notes

**Chromecast**
- Best overall support; recommended for streaming
- Sidecar VTT subtitles with auto SRT-to-VTT conversion
- Wraps local TS files in HLS via `TsHlsMediaTransformer`

**DLNA**
- Best for local/downloaded files
- Uses HTTP/1.0 raw socket server -- Dart's HTTP/1.1 breaks some TVs (e.g., TCL Google TV)
- Embed SRT in MKV for subtitles (most TVs ignore sidecar files)
- TV controls subtitle styling
- HLS is piped as MPEG-TS; seeking works by restarting the pipe at the requested offset
- Local file seeking via byte-range requests (206 Partial Content)

**AirPlay**
- Pairing and session setup work. Local files are planned as direct play, MP4
  remux, H.264/AAC transcode, or seekable VOD HLS; audio/subtitle switches
  rebuild the stream and reload at the current position.
- Playback over `/play` is implemented but not yet verified end to end. One
  receiver answered `/play` with HTTP 400 when the request used the legacy
  `text/parameters` body; that body is now the binary plist form pyatv sends,
  which has not yet been run on that receiver. Other tested receivers do not
  expose `/play`. See [`doc/AIRPLAY.md`](doc/AIRPLAY.md) for the matrix and how
  to test your device.
- Screen mirroring and RAOP audio are unimplemented.

### Known Limitations

- **AirPlay video**: implemented for `/play` receivers; the recorded run on a
  "Living Room" receiver returned HTTP 400 before the binary plist body was
  adopted, and that body is not yet verified. TCL Google TVs lack the endpoint
  — see [`doc/AIRPLAY.md`](doc/AIRPLAY.md). On those devices, use Chromecast or
  DLNA.
- **AirPlay track switches**: audio and subtitle changes are a reload, not a
  gapless switch, and need a receiver that advertises HLS support.
- **Local TS on Chromecast**: `TsHlsMediaTransformer` has per-segment buffering and subtitle drift. Remux to MP4 via ffmpeg instead -- see [`example/lib/ffmpeg_media_transformer.dart`](example/lib/ffmpeg_media_transformer.dart).
- **DLNA streaming**: HLS is piped as MPEG-TS, so a renderer's own on-screen duration may show a placeholder even though `durationStream` reports the real length.
- **DLNA subtitle styling**: The TV controls styling, not the app.

## Supported Platforms

| Protocol   | Android | iOS | macOS | Windows | Linux |
|------------|---------|-----|-------|---------|-------|
| Chromecast | yes     | yes | yes   | yes     | yes   |
| AirPlay    | yes     | yes | yes   | yes     | yes   |
| DLNA       | yes     | yes | yes   | yes     | yes   |

## Media tracks: probing, subtitle extraction and live subtitles

These APIs cover the media-track path: inspect a local file, extract an
embedded subtitle track, and attach it to a Chromecast live MKV stream. They do
not resolve app-specific directories; the caller supplies the cache directory.

### Probing

`FfprobeMediaProber` (or any `MediaProber`) returns a `MediaProbe` with the
container, duration, video stream, audio streams and subtitle streams. Two
indices are reported for every stream: `index` is the absolute container index
(use with `-map 0:N`), while `trackIndex` is the 0-based position among streams
of that type (use with `-map 0:a:N` / `-map 0:s:N`).

```dart
const prober = FfprobeMediaProber();
final probe = await prober.probe('/movies/example.mkv');
for (final subtitle in probe.subtitles) {
  print('${subtitle.displayLabel}: '
      'index=${subtitle.index} track=${subtitle.trackIndex}');
}
```

### Extracting subtitles

`SubtitleCache` stores extracted files keyed by source identity (path, size and
modification time), stream index and extension, so a changed video no longer
serves a stale subtitle. The caller injects the directory; the cache never
resolves a platform directory itself. Defaults: unused entries expire after
7 days, and the cache is trimmed to 512 MB (least recently used first).
`cleanup` only touches files that match the cache's own names.

```dart
final cache = SubtitleCache(directory: cacheDirectory);
final extractor = SubtitleExtractor(
  runner: const FFmpegKitRunner(),
  cache: cache,
);

// Protect files that are still being written.
await cache.cleanup(protectedPaths: extractor.inFlightPaths);
```

`SubtitleExtractor.extract` converts a track to its native format by default,
or to WebVTT for casting with `SubtitleOutputFormat.webVtt`. Concurrent calls
for the same source/track are deduplicated, `cancel` stops one track, and
`timeout` bounds a run. Failures are typed `MediaTrackException`s:
`SubtitleSourceUnreadable`, `SubtitleUnsupportedCodec` (image-based tracks
cannot become text), `SubtitleFfmpegFailed`, `SubtitleExtractionCancelled`,
`SubtitleExtractionTimedOut`, `SubtitleEmptyOutput` and `SubtitleCacheFailure`.

```dart
final result = await extractor.extract(
  source: MediaFileIdentity(
    path: '/movies/example.mkv',
    sizeBytes: 1024,
    modified: DateTime.now(),
  ),
  track: probe.subtitles.first,
  format: SubtitleOutputFormat.webVtt,
);
print(result.file.path);
```

### Live MKV subtitles

`ChromecastSession.loadLiveMkv` accepts a `subtitle` for a new live stream, and
`switchLiveSubtitle` attaches, replaces or clears it on a running stream.
Attaching a non-null subtitle restarts the stream at the requested position;
clearing it uses `EDIT_TRACKS_INFO` only. A restart re-prepares the subtitle
from the original file for the new start offset; `WebVttTimeShifter.shift`
moves the caller's full-timeline WebVTT by that same offset. The live subtitle
source must be a full-timeline WebVTT file on the local filesystem (a plain
path or a `file://` URI): the package reads and time-shifts it, and remote URLs
are not supported on the live path.

```dart
const subtitle = CastSubtitle(
  url: '/data/subtitles/en.vtt',
  label: 'English',
  language: 'en',
  format: 'vtt',
);

await session.loadLiveMkv(
  filePath: '/movies/example.mkv',
  audioIndex: 0,
  streamType: 'BUFFERED',
  subtitle: subtitle,
);

await session.switchLiveSubtitle(subtitle: null, position: position);
```

### Platform note

The FFmpeg-backed features (`FfprobeMediaProber`, `FFmpegKitRunner` and
`FFmpegKitFfprobeRunner`) require the `ffmpeg_kit_flutter_new_min` platforms:
Android, iOS, macOS, Windows and Linux. They are not available on web.

## Quick Start

```dart
import 'package:dart_cast/dart_cast.dart';

final castService = CastService(
  discoveryProviders: [
    DlnaDiscoveryProvider(),
    ChromecastDiscoveryProvider(),
    AirPlayDiscoveryProvider(),
  ],
  sessionFactory: (device) {
    switch (device.protocol) {
      case CastProtocol.chromecast:
        return ChromecastSession(device: device);
      case CastProtocol.airplay:
        return AirPlaySession(device);
      case CastProtocol.dlna:
        // DLNA requires a device description with control URLs.
        // Use DlnaDeviceDescription.fetch(device) then DlnaSession(device, description).
        return DlnaSession(device, dlnaDescription);
    }
  },
);

// Discover devices on the local network
final devices = await castService.startDiscovery().first;

// Connect to the first device found
final session = await castService.connect(devices.first);

// Cast an HLS stream with custom headers
await session.loadMedia(CastMedia(
  url: 'https://example.com/video.m3u8',
  type: CastMediaType.hls,
  httpHeaders: {'Referer': 'https://example.com'},
  title: 'My Video',
));

// Control playback
await session.pause();
await session.seek(Duration(minutes: 5));
await session.play();

// Monitor state
session.stateStream.listen((state) => print('State: $state'));
session.positionStream.listen((pos) => print('Position: $pos'));

// Clean up
await session.disconnect();
castService.dispose();
```

## API Overview

### CastService

The main entry point. Manages discovery, connections, and sessions.

```dart
final service = CastService(
  discoveryProviders: [...],  // protocol-specific providers
  sessionFactory: (device) => ...,  // creates sessions by protocol
);
```

- `startDiscovery()` -- returns a `Stream<List<CastDevice>>`
- `connect(device)` -- returns a `Future<CastSession>`
- `reconnect()` -- reconnects to the last-used device
- `activeSession` -- the current session, if any
- `dispose()` -- releases all resources

### CastDevice

A discovered device on the network.

- `id`, `name` -- identity
- `protocol` -- `CastProtocol.chromecast`, `.airplay`, or `.dlna`
- `address`, `port` -- network location
- `toJson()` / `CastDevice.fromJson()` -- serialization for persistence

### CastSession

An active connection to a cast device with full playback control.

- `loadMedia(CastMedia)` -- start playing content
- `play()`, `pause()`, `stop()`, `seek(Duration)` -- playback controls
- `setVolume(double)` -- 0.0 to 1.0
- `setSubtitle(CastSubtitle?)` -- subtitle track selection
- `stateStream`, `positionStream`, `durationStream`, `volumeStream` -- reactive streams
- `disconnect()` -- end the session

### CastMedia

Describes what to play.

```dart
CastMedia(
  url: 'https://example.com/video.m3u8',
  type: CastMediaType.hls,        // hls, mp4, mkv, or mpegTs
  httpHeaders: {'Referer': '...'}, // injected via proxy
  title: 'Episode 1',
  imageUrl: 'https://example.com/thumb.jpg',
  startPosition: Duration(seconds: 30),
  subtitles: [
    CastSubtitle(
      url: 'https://example.com/subs.vtt',
      label: 'English',
      language: 'en',
      format: 'vtt',
    ),
  ],
);
```

### MediaProxy

Built-in HTTP proxy that injects headers. Protocol sessions use it internally, but you can use it directly.

- `start()` / `stop()` -- lifecycle
- `registerMedia(url, headers: {...})` -- returns a proxy URL
- `registerFile(filePath)` -- serves a local file over HTTP

### SubtitleConverter

Converts between subtitle formats.

- `SubtitleConverter.srtToVtt(srtContent)` -- convert SRT to WebVTT (for Chromecast)
- `SubtitleConverter.vttToSrt(vttContent)` -- convert VTT to SRT (for DLNA MKV embedding)
- `SubtitleConverter.toAss(content)` -- convert to ASS format

### DeviceDiscoveryProvider

Abstract interface for pluggable discovery. Each protocol ships a default implementation; inject alternatives (e.g., `bonsoir`) on Apple platforms.

## Platform Setup

### iOS

Add to `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app discovers cast devices on your local network.</string>
<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
  <string>_airplay._tcp</string>
</array>
```

### Android

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<!-- Android 12+ -->
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

### macOS

Add to your entitlements file:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

### Windows

No special permissions. Users may need to allow the app through Windows Firewall for proxy and multicast.

## How the Proxy Works

Cast devices cannot send custom HTTP headers (like `Referer` or cookies) when fetching media. `MediaProxy` runs a local HTTP server on the device's WiFi IP, rewrites media URLs to route through itself, and forwards requests with the required headers. For HLS streams, it also rewrites segment and variant URLs inside m3u8 playlists so every subsequent request routes through the proxy.

## DLNA Local Files

DLNA local file casting works out of the box -- use `CastMedia.file()` with `CastMediaType.mp4` or `.mkv`. The proxy serves files over HTTP/1.0 for maximum TV compatibility.

Most DLNA TVs ignore sidecar subtitle URLs. Embed SRT into an MKV container with ffmpeg before casting:

```bash
# Remux video + subtitle into MKV (fast, no re-encoding)
ffmpeg -i video.mp4 -i subtitle.srt -map 0 -map 1 -c copy -c:s srt output.mkv
```

```dart
// Cast the MKV with embedded subtitles
await session.loadMedia(CastMedia.file(
  filePath: '/path/to/output.mkv',
  type: CastMediaType.mkv,
  title: 'My Video',
  startPosition: Duration(minutes: 5), // resume from saved position
));
```

See the [example app](example/) for a complete implementation with ffmpeg remuxing.

## Pluggable Discovery

The default mDNS discovery uses `multicast_dns` (pure Dart), which works on Android, Windows, and Linux. On Apple platforms (iOS/macOS), the app sandbox may block raw UDP multicast. Inject a `bonsoir`-based provider instead:

```dart
// In your Flutter app
import 'package:bonsoir/bonsoir.dart';

class BonsoirChromecastProvider implements DeviceDiscoveryProvider {
  @override
  CastProtocol get protocol => CastProtocol.chromecast;

  @override
  Stream<List<CastDevice>> startDiscovery({
    Duration timeout = const Duration(seconds: 10),
  }) {
    // Use BonsoirDiscovery to find _googlecast._tcp services
    // and map them to CastDevice instances.
  }

  // ...
}

final service = CastService(
  discoveryProviders: [BonsoirChromecastProvider()],
  sessionFactory: ...,
);
```

## AirPlay Capabilities

### Feature Flag Detection

AirPlay devices advertise capabilities as a bitmask in the `features` (or `ft`) TXT record. dart_cast parses this during discovery and exposes it via `AirPlayFeatures`:

```dart
final features = AirPlayFeatures.parse('0x5A7FFFF7,0x1E');

features.supportsVideo    // true if bit 0 (V1) or bit 49 (V2) is set
features.supportsScreen   // true if bit 7 is set (screen mirroring)
features.supportsAudio    // true if bit 9 is set (RAOP audio)
features.requiresHapPairing // true if bit 43, 46 or 48 is set
features.supportsTransientPairing // true if bit 43 or 48 is set (no PIN)
features.isV2Protocol     // true if bit 38 or 48 is set
```

### AirPlay Modes and Current Support

| Mode | Feature Bits | Status |
|------|-------------|--------|
| Video URL casting (V1) | Bit 0 | Implemented -- plain HTTP `POST /play`, no RTSP setup |
| Video URL casting (V2) | Bits 38/48 + bit 49 | Implemented -- requires transient pairing, RTSP `SETUP` with a live UDP timing server, `RECORD`, and a `/rate` after `/play`. Not yet verified against hardware |
| Screen mirroring | Bit 7 | Not yet implemented (see [doc/FUTURE_WORK.md](doc/FUTURE_WORK.md)) |
| Audio streaming (RAOP) | Bit 9 | Not yet implemented (see [doc/FUTURE_WORK.md](doc/FUTURE_WORK.md)) |

### Capability-Driven Version Selection

`AirPlayMediaController.play()` decides which protocol to speak **before sending anything**, from the bitmask the device advertises over mDNS:

- Bit 38 or bit 48 set -> AirPlay 2. Bit 49 is then required; the session pairs
  transiently, runs RTSP `SETUP` (advertising a live UDP timing port) and
  `RECORD`, sends `POST /play`, and follows it with `POST /rate?value=1.000000`.
  **That last command is not optional** -- an AirPlay 2 `/play` starts the item
  paused, so without it the receiver sits on a black frame.
- Otherwise -> AirPlay 1. Bit 0 is required; a plain `POST /play` with a binary
  plist body, no RTSP setup.

There is no fallback ladder. Earlier versions tried a V1 `/play` first and only
reached the V2 path if the device answered 404 or 415. Every AirPlay 2-only
receiver answers that first request with 404 -- correctly, since it never
advertised V1 -- and the 404 was then misread as "this TV cannot cast video".

### Devices Without Video Support

If a device advertises neither video bit (0 nor 49), `play()` throws `UnsupportedFeatureException` before any request goes out. An AirPlay 2 receiver with bits 38/48 but no bit 49 is a mirroring-only or audio-only device; use Chromecast or DLNA for those.

```dart
try {
  await airPlaySession.loadMedia(media);
} on UnsupportedFeatureException catch (e) {
  // Device supports screen mirroring only — video URL cast not available
  print(e.message);
}
```

### Hardware status

Playback over `/play` is implemented for both AirPlay 1 and AirPlay 2, including
local-file preparation, resume, track switching, subtitles and volume. No
hardware run has been recorded yet. The receivers tested so far do not expose
`/play` at all, for a reason specific to those devices rather than to this
package. No Apple TV has been tried. See [`doc/AIRPLAY.md`](doc/AIRPLAY.md) for
which devices were tested, why they fail, and how to check your own — results
from other hardware are welcome.

## Error Handling

| Exception                      | When                                                         |
|--------------------------------|--------------------------------------------------------------|
| `CastException`               | Base class for all casting errors                            |
| `DeviceUnreachableException`   | Device found but connection failed (offline, refused)        |
| `ConnectionLostException`      | Connection dropped (network change, device sleep)            |
| `MediaLoadFailedException`     | Device rejected the media (unsupported format, bad URL)      |
| `ProxyUpstreamException`       | Proxy failed to fetch upstream content (403, timeout)        |
| `DiscoveryException`           | Discovery failed (permissions denied, no network)            |
| `ProtocolException`            | Protocol-specific error (bad SOAP response, protobuf err)    |
| `UnsupportedFeatureException`  | AirPlay device lacks the required feature (e.g. video bits)  |
| `PlaybackException`            | AirPlay device rejected `/play`, or the `/rate` that must follow it |

All exceptions carry a `message` and optional `cause`.

## Example

See [example/](example/) for a Flutter app with device discovery, connection, and a full remote control UI.

## Architecture

```
Consumer App (any Dart/Flutter app)
  Uses: CastService, CastSession, CastMedia
          |
Core Layer (protocol-agnostic)
  CastService -> DiscoveryManager
              -> CastSession (state machine)
              -> MediaProxy (header injection)
          |
Protocol Layer (isolated per protocol)
  DLNA         Chromecast       AirPlay
  SSDP         mDNS             mDNS
  SOAP/XML     TLS+Protobuf     HTTP
```

## Acknowledgments and References

Built with help from these open-source projects, specifications, and community resources:

### Protocol References

- **[pyatv](https://github.com/postlund/pyatv)** by Erik Hilsdale -- The most complete open-source Apple TV / AirPlay protocol implementation. Our AirPlay HAP authentication (SRP-6a, pair-setup, pair-verify) is based on pyatv's protocol analysis.
- **[node-castv2](https://github.com/thibauts/node-castv2)** by Thibaut Séguy -- Reference implementation of the Chromecast CASTV2 protocol. Our protobuf message framing and channel architecture follows this implementation.
- **[dart_chromecast](https://github.com/terrabythia/dart_chromecast)** -- Dart Chromecast implementation that informed our CASTV2 TLS connection and message handling.
- **[dlna_dart](https://github.com/nicedayzhu/dlna-dart)** -- Lightweight DLNA client in Dart. Our SSDP discovery and SOAP action patterns were influenced by this package.
- **[pair_ap](https://github.com/ejurgensen/pair_ap)** by ejurgensen -- C library for AirPlay pairing used by shairport-sync and owntone-server. Referenced for FairPlay-SAP authentication flow details.

### Protocol Specifications

- [RFC 8216](https://www.rfc-editor.org/rfc/rfc8216) -- HTTP Live Streaming (HLS) specification
- [RFC 5054](https://www.rfc-editor.org/rfc/rfc5054) -- SRP-6a protocol and group parameters
- [UPnP AV Transport Service](https://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf) -- DLNA/UPnP media control
- [Unofficial AirPlay Protocol Specification](https://nto.github.io/AirPlay.html) -- Community-maintained AirPlay reverse engineering docs
- [Google Cast Media Messages](https://developers.google.com/cast/docs/media/messages) -- Official Chromecast media protocol documentation
- [OpenAirPlay Spec](https://openairplay.github.io/airplay-spec/) -- AirPlay 2 protocol documentation including HAP pairing

### Dart Packages

- **[cryptography](https://pub.dev/packages/cryptography)** -- Ed25519, X25519, ChaCha20-Poly1305, HKDF-SHA512 for AirPlay authentication
- **[multicast_dns](https://pub.dev/packages/multicast_dns)** -- mDNS service discovery for Chromecast and AirPlay
- **[protobuf](https://pub.dev/packages/protobuf)** -- Protocol Buffers for Chromecast CASTV2 message serialization
- **[http](https://pub.dev/packages/http)** -- HTTP client for DLNA SOAP, AirPlay control, and media proxy

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and PR guidelines.

## License

MIT -- see [LICENSE](LICENSE) for details.

## Prepared casting (direct + remux)

This fork can probe a local file and, when needed, remux it to HLS for
Chromecast playback. Video transcode is deferred.

Limitations: no audio track switching UI, no device-verified playback table yet.
