# Tasks

## 1. Baseline and hardware gates

- [ ] 1.1 Record the current baseline: run `flutter test` in `packages/dart_cast` for `test/protocols/airplay` and `flutter test` in the app; note any pre-existing failures in `packages/dart_cast/doc/specs/2026-11-21-airplay-baseline.md` and verify the file records the exact commands and results
- [ ] 1.2 Run `dart run tool/airplay_probe.dart` and `dart run tool/airplay_hardware_check.dart <receiver-ip>` against the available `/play`-capable receiver; record `/play`, `/rate`, and playback results in `packages/dart_cast/doc/specs/2026-11-21-airplay-play-hardware.md` and verify the document states whether the release gate passed
- [ ] 1.3 Attempt a unified-control capture from a working sender to a `/command`-only receiver using packet capture and receiver logs; decode the `streams` `SETUP` and `/command` bodies into `packages/dart_cast/doc/protocol-references/airplay-unified-control.md` and verify the document either contains validated payloads or explicitly records that no working video trace was obtained

## 2. Package: AirPlay media planning and preparation

- [ ] 2.1 Add an AirPlay media planner that maps a probe to direct play, MP4 remux, audio remux, H.264/AAC transcode, HLS, or unsupported; add unit tests for each branch and verify `dart test test/protocols/airplay/airplay_media_plan_test.dart` passes
- [ ] 2.2 Add FFmpeg command builders for MP4 remux and HLS output (video variant plus audio playlists); add argument tests and verify `dart test test/core/cast_ffmpeg_commands_test.dart` passes
- [ ] 2.3 Add an HLS master-playlist writer and a WebVTT HLS segmenter with a valid `EXT-X-TARGETDURATION`; add tests that parse the generated playlists and verify subtitle and audio groups are valid HLS
- [ ] 2.4 Implement `AirPlaySession.loadLocalFile` using the planner and preparation helpers, including cleanup of routes and temporary directories on failure; add tests with a fake prober and preparation seam for every plan and verify the AirPlay session tests pass
- [ ] 2.5 Document the AirPlay media pipeline, startup cost, and compatibility limits in `packages/dart_cast/doc/AIRPLAY.md`; verify the documented cases match the planner tests

## 3. Package: playback correctness, resume, and volume

- [ ] 3.1 Make `AirPlayMediaController.play` duration-aware so AirPlay 1 sends a `Start-Position` fraction and AirPlay 2 sends absolute seconds; add tests for both versions and verify the media-controller tests pass
- [ ] 3.2 Stop polling at the start of every load and add a load-generation token so playback information from a replaced load is ignored; add a stale-poll test and verify it passes
- [ ] 3.3 Honor `hasDuration` and seed known durations so a receiver report without a duration does not overwrite the probe duration; add a test and verify it passes
- [ ] 3.4 Implement AirPlay volume for receivers advertising video volume control (bit 3) and return a typed unsupported result otherwise; add supported/unsupported tests and verify they pass
- [ ] 3.5 Clean previous proxy routes, HLS directories, and temporary files before each reload; add a repeated-reload test and verify no stale routes remain
- [ ] 3.6 Update `packages/dart_cast/doc/AIRPLAY.md` with resume, volume, and state behavior; verify the documented behavior matches the tests

## 4. Package: audio and subtitle tracks

- [ ] 4.1 Add protocol-neutral `audioTracks` and `activeAudioIndex` accessors to `CastSession` with safe defaults, implement them on `AirPlaySession`, and add tests that verify the track list and active index after a local load
- [ ] 4.2 Implement `AirPlaySession.switchLiveAudio` by rebuilding the stream with the selected track and reloading at the requested position; add tests for AirPlay 1 and AirPlay 2 and verify the position is preserved
- [ ] 4.3 Implement `AirPlaySession.setSubtitle` attachment and removal by rebuilding the HLS playlist and reloading at the current position; add tests for attach, remove, and unsupported receivers and verify they pass
- [ ] 4.4 Suppress position and state events from a replaced stream during audio or subtitle switches; add a test with an out-of-order position report and verify it is discarded
- [ ] 4.5 Document AirPlay's restart-at-position track switching and its brief interruption in `packages/dart_cast/doc/AIRPLAY.md`; verify the behavior is described as a reload, not a gapless switch

## 5. Package: pairing and credentials

- [ ] 5.1 Verify `NeedsPairingException` propagates unchanged through `CastService.connect`; add a service-level test with a mock receiver and verify the typed exception reaches the caller
- [ ] 5.2 Add tests for `HapCredentials` JSON and compact serialization round-trips and for a factory-supplied credential using pair-verify instead of transient pairing; verify both tests pass
- [ ] 5.3 Document transient versus PIN pairing, credential reuse, and the iOS-system-AirPlay versus custom-sender distinction in `packages/dart_cast/doc/AIRPLAY.md`; verify the document explains why Android-to-Apple-TV works

## 6. App: protocol exposure, capabilities, and platform configuration

- [ ] 6.1 Add `PureCastProtocol.airplay` and its capabilities, and map AirPlay in both directions in the adapter; add mapping and capability tests and verify they pass
- [ ] 6.2 Register `AirPlayDiscoveryProvider` in DI and the adapter's default provider list, and construct an `AirPlaySession` in the session factory; add an adapter test that an AirPlay device connects and verify no unsupported-protocol path remains
- [ ] 6.3 Carry AirPlay feature metadata into `PureCastDevice` and derive per-device audio, subtitle, and volume capabilities; add tests for receivers with and without HLS and volume bits and verify the UI-facing capabilities are correct
- [ ] 6.4 Gate the audio, subtitle, and volume controls on capabilities and show an `airplay` protocol label; add widget tests and verify the edits preserve the user's existing changes in `device_manager_screen.dart` and `media_crontroller_screen.dart`
- [ ] 6.5 Add `_airplay._tcp` to iOS and macOS `NSBonjourServices`, update the local-network usage text, and verify Android multicast discovery; run `plutil -lint` on both plists and record a successful discovery
- [ ] 6.6 Route local AirPlay media through `loadLocalFile` and resolve `content://` sources to a readable cached file before preparation; add adapter tests for a local path and a content URI and verify both reach AirPlay preparation
- [ ] 6.7 Update the README protocol matrix and AirPlay notes to reflect the new supported cases and limits; verify no “not yet” claim remains for the implemented paths

## 7. App: pairing UX and credential storage

- [ ] 7.1 Add a typed pairing-required domain error and `connectWithPin` to `ICastService`; implement both in the adapter and add tests for success, cancellation, and failure
- [ ] 7.2 Add an `AirPlayCredentialStore` backed by `shared_preferences`, keyed by device identifier, loaded once and cached for the synchronous session factory; add read/write/delete tests and verify they pass
- [ ] 7.3 Add pairing state and events to the session bloc so a pairing-required failure becomes a user-visible pairing request; add bloc tests and verify normal connection still works
- [ ] 7.4 Add the PIN dialog with cancel and error handling; add a widget test for the prompt, successful submission, and cancellation and verify no half-connected session remains
- [ ] 7.5 Wire the session factory to the credential store so a previously paired device reconnects without a prompt; add an integration test with a mock receiver and verify the PIN flow is skipped
- [ ] 7.6 Document the in-app pairing flow and cancellation behavior in the README; verify the steps match the implementation

## 8. AirPlay 2 unified media control (gated by 1.3)

- [ ] 8.1 Add an `AirPlayCommandProfile` registry and detection that classifies `/command`-only receivers without enabling unvalidated playback; add tests for a classic receiver, an unprofiled candidate, and a profiled candidate and verify each follows the specified path
- [ ] 8.2 If 1.3 produced validated payloads, record the exact `SETUP` and command sequence in the protocol reference; if it did not, record the gate failure and verify candidates receive the typed unsupported error
- [ ] 8.3 If the gate passed, implement the streams `SETUP` and media-control-port acquisition; add mock-server tests and verify setup success and failure paths
- [ ] 8.4 If the gate passed, implement play, pause, seek, stop, volume, and status over `/command`; add mock-server tests and verify state and position reporting
- [ ] 8.5 If the gate passed, add the validated receiver profile and run the hardware check; record playback evidence. If the gate failed, verify the unsupported path and record the limitation
- [ ] 8.6 Update `packages/dart_cast/doc/protocol-references/airplay-unified-control.md` and `doc/AIRPLAY.md` with the validated profile or the documented limitation; verify the docs match the implemented behavior

## 9. Integration and release readiness

- [ ] 9.1 Run `flutter analyze` and the AirPlay test files individually in `packages/dart_cast`; verify no new analyzer issues and no failures beyond the recorded baseline
- [ ] 9.2 Run `flutter analyze` and `flutter test` in the app; verify no new issues or failures beyond the recorded baseline
- [ ] 9.3 Run an end-to-end manual checklist on the `/play` receiver: discover, pair, play remote MP4 and HLS, play local MP4 and MKV, switch audio, attach and switch subtitles, seek, resume, and set volume; record the results in the hardware document
- [ ] 9.4 Verify the release documentation has no stale AirPlay limitations for implemented paths and that the supported/unsupported matrix is accurate; record the final matrix in the change notes
- [ ] 9.5 Verify the working tree contains only intended files with `git status --short` and `git diff --stat`; confirm the two user-edited UI files retain their prior changes

## Workflow follow-up

- Review the artifacts, then start the apply workflow only when explicitly requested.
- If the unified-control gate in 1.3 fails, revise this change to remove the unvalidated phase 8 tasks before archiving, or explicitly carry that limitation as a documented release gap.
- Archive the change after all tasks are complete and the project's review requirements are satisfied.
