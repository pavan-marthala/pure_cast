# AirPlay `/play` hardware gate — 2026-11-21

## Result

**Not passed.** The release gate has not produced a 200 from a receiver.

Two receivers were examined:

- A TCL Google TV has no `/play` endpoint at all (404).
- A "Living Room" receiver at `192.168.31.20:27131` selected the plain AirPlay 1
  path and answered `/play` with **HTTP 400** when the request used the legacy
  `text/parameters` body. That body has since been replaced with an Apple
  binary plist; the replacement has **not** been run against this receiver, so
  the gate is still open.

This is a missing measurement, not evidence that the new body fails.

## Recorded failure — "Living Room" receiver

From the sender log:

```text
AirPlay: found "Living Room" at 192.168.31.20:27131
features=0x1e527ffff7 (v2=false, videoV1=true, videoV2=false, transient=false)
/info and /server-info both non-200
AirPlay: connected to Living Room (AirPlay 1, plain)
AirPlay /play failed with status 400
```

The bitmask has video bit 0 and HLS bit 4 set, with no HAP or AirPlay 2 bits,
so the plain AirPlay 1 path was correct. The receiver exports neither `/info`
nor `/server-info`, so the 400 cannot be diagnosed from device metadata. pyatv's
AirPlay 1 implementation and the published protocol notes send `/play` as an
Apple binary plist (`Content-Type: application/x-apple-binary-plist`), which is
how `AirPlayClient.play` and `AirPlayMediaController.playV1` now send it.

## What was attempted from this environment

```sh
cd packages/dart_cast
dart run tool/airplay_probe.dart
```

The probe fails before it can list receivers:

```
SocketException: Send failed, OS Error: ... 0.0.0.0:5353
```

mDNS multicast is unavailable in this environment, so no receiver address was
obtained here. The Living Room trace above came from the app on the machine that
can reach the LAN.

## Commands to run on the "Living Room" receiver

```sh
dart run tool/airplay_probe.dart
dart run tool/airplay_hardware_check.dart 192.168.31.20 --port 27131
```

The hardware check performs connect → pair → RTSP `SETUP` → `/play` → poll and
prints every wire step. Record:

- advertised feature bits and pairing mode
- the `/play` body format actually sent and its status
- whether `/rate` is accepted
- `/playback-info` position and rate after several seconds
- whether the receiver is still playing when checked again later

Judge success on values the receiver reports, not on numbers computed by the
tool. A session that transitions to `playing` locally is not evidence that the
screen is playing.

If `/play` still returns 400, capture the status, the response body and whether
the receiver implements `/command` before changing the request again. Do not
send a second body automatically.

## Status of local-file preparation

The direct/remux/transcode/HLS paths are covered by unit tests and mocks with a
fake prober and preparer. They have not been exercised against a physical
receiver. Do not describe them as hardware-verified until this document records
a passed run.
