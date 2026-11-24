# AirPlay parity baseline — 2026-11-21

Recorded before any change in the `add-airplay-support` work. Commands were run
from the repository root unless stated otherwise.

## Package

```sh
cd packages/dart_cast
flutter test test/protocols/airplay test/integration/airplay_integration_test.dart
```

Result: **328 tests passed, 0 failed** (`All tests passed!`).

The full `dart test` suite is not used as the baseline: six tests in unrelated
suites time out under parallel load and pass when run individually. That
flakiness predates this change and is tracked in the change notes.

## Application

```sh
flutter test
```

Result: **169 passed, 4 failed**.

The four failures are all in `test/casting/cast_player_controls_test.dart` and
are pre-existing:

- `renders the seven controls in the requested order`
- `seek buttons are disabled when the duration is zero`
- `seek buttons are disabled while a restart is pending`
- `taps dispatch +/-10s and +/-30s relative seeks`

They assert an icon/control layout that the current screen no longer renders;
they are unrelated to AirPlay. Release verification compares against this list
so no new failure is hidden.

## Post-change verification — 2026-11-23

### Package

```sh
cd packages/dart_cast
flutter test
```

Result: **1078 passed, 0 failed** (`All tests passed!`), including the new
AirPlay planning, preparation, HLS, resume, volume and pairing tests.

```sh
cd packages/dart_cast
dart analyze lib test
```

One info-level diagnostic remains in `test/protocols/dlna/dlna_session_test.dart:29`;
no errors or warnings.

`dart test` in this environment fails while compiling Flutter framework sources
(`invalid-type` errors from the local Flutter SDK) before it reaches the tests.
Non-Flutter suites such as `test/core/cast_service_test.dart` pass under
`dart test`; Flutter-dependent suites were verified with `flutter test`.

### Application

```sh
flutter test
```

Result: **196 passed, 4 failed** — the same four pre-existing
`cast_player_controls_test.dart` failures listed above. 27 new tests were
added: 16 adapter mapping/pairing tests, 4 session-bloc pairing tests,
4 credential-store tests and 3 PIN-dialog tests.

```sh
flutter analyze
```

Only info-level diagnostics, matching the pre-existing set (deprecated Material
imports, one `hash_and_equals`, one private-type-in-public-API test info).

### Not measured

- End-to-end playback on a `/play` receiver (no such receiver available; see
  `2026-11-21-airplay-play-hardware.md`).
- AirPlay 2 unified media control over `/command` (no working sender trace; see
  `../protocol-references/airplay-unified-control.md`).
- Android multicast discovery (mDNS unavailable in this environment).

## Re-verification after the binary `/play` body — 2026-11-24

The plain AirPlay 1 `/play` body changed from `text/parameters` to an Apple
binary plist, and `/play` errors now carry the status and a bounded response
preview. Everything below was re-run.

### Package

```sh
cd packages/dart_cast
dart analyze lib/ test/
dart format --output=none --set-exit-if-changed lib/ test/
flutter test test/protocols/airplay
flutter test $(find test -name '*_test.dart' ! -name 'media_proxy_hls_test.dart')
flutter test test/core/media_proxy_hls_test.dart
```

Results:

- `dart analyze`: one pre-existing info in
  `test/protocols/dlna/dlna_session_test.dart:29`; no warnings or errors.
- `dart format`: only the six pre-existing unrelated files listed in the change
  notes are flagged; every file this change touched is clean.
- AirPlay tests: **355 passed**.
- Remaining suite: **1047 passed**.
- `media_proxy_hls_test.dart` alone: **32 passed**. It times out under the full
  suite's parallel load because it drives FFmpeg against a temp file; run
  alone it passes, which matches the pre-existing flakiness above.
- Combined: **1079 passed, 0 failed**.

### Application

```sh
flutter analyze
flutter test
```

Results: analyze reports only the five pre-existing info diagnostics; tests are
**196 passed, 4 failed**, the same four `cast_player_controls_test.dart`
failures listed at the top of this document. No new failure.

### Still not measured

The three items in "Not measured" above also apply to this run. The binary
`/play` body has still never been accepted by a physical receiver.

