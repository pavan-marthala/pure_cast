# Spec Delta

## Purpose

Defines how media is prepared, delivered, controlled, and reported on AirPlay receivers, including local-file preparation, resume, seeking, state integrity, and volume behavior.

## ADDED Requirements

### Requirement: Remote media is delivered through the local proxy

The system SHALL serve remote MP4 and HLS media through its local proxy and give the receiver a proxy URL that is reachable on the local network. For HLS, every child playlist and segment the receiver requests SHALL also be proxied, and caller-supplied HTTP headers SHALL be applied to those requests.

#### Scenario: Remote MP4 plays

- **WHEN** a remote MP4 URL is loaded
- **THEN** the receiver is given a local proxy URL and playback starts

#### Scenario: Remote HLS is fully proxied

- **WHEN** a remote HLS playlist with headers is loaded
- **THEN** the receiver can fetch the master playlist, child playlists, and segments through the proxy with the headers applied

#### Scenario: Upstream media is unreachable

- **WHEN** the upstream media request fails
- **THEN** the load fails with a typed media error and the session does not remain in a loading state

### Requirement: Compatible local media is played directly

The system SHALL probe a local file and play it directly when it is a compatible container with H.264 video and AAC or MP3 audio and no subtitle or multi-audio requirement exists.

#### Scenario: Compatible MP4

- **WHEN** a local H.264/AAC MP4 is loaded without subtitles
- **THEN** the receiver is given a direct proxy URL for the file and no transcode or remux is performed

### Requirement: Local container and audio incompatibilities are remuxed

The system SHALL remux a local file to MP4 when the video is compatible H.264 but the container is unsupported or the selected audio codec is incompatible. Video SHALL be copied without re-encoding, and incompatible audio SHALL be converted to AAC.

#### Scenario: MKV with compatible video

- **WHEN** a local MKV contains H.264 video and AAC audio
- **THEN** the receiver is given an MP4 remux of the file and the video stream is not re-encoded

#### Scenario: Incompatible audio track

- **WHEN** the selected audio track uses DTS, TrueHD, or another unsupported codec
- **THEN** the remux converts that audio track to AAC while copying the video stream

#### Scenario: Selected audio track is honoured

- **WHEN** a local multi-audio file is loaded with a selected audio index
- **THEN** the prepared output contains that audio track

### Requirement: Incompatible video is transcoded when possible

The system SHALL transcode local video to H.264/AAC when the video codec or bit depth is not AirPlay-compatible and an H.264 encoder and video transcoding are available. It SHALL fail with a typed unsupported-media error when transcoding is unavailable.

#### Scenario: HEVC video is transcoded

- **WHEN** a local HEVC or 10-bit video is loaded and an H.264 encoder is available with transcoding enabled
- **THEN** the receiver receives an H.264/AAC stream

#### Scenario: Transcoding is unavailable

- **WHEN** the video is incompatible and no usable H.264 encoder or transcoding is disabled
- **THEN** the load fails with a typed unsupported-media error before playback starts

### Requirement: Subtitle and multi-audio playback uses seekable VOD HLS

When subtitles are requested or multiple audio tracks must be selectable, the system SHALL prepare a seekable VOD HLS directory with a master playlist and valid audio and subtitle renditions. HLS subtitle playlists SHALL use a valid target duration, and the receiver SHALL not be asked to play the master playlist until it is available.

#### Scenario: Subtitle rendition is valid

- **WHEN** a subtitle is active for a local file
- **THEN** the receiver receives a master playlist whose subtitle rendition is valid HLS with a target duration within the allowed range

#### Scenario: Multi-audio rendition group

- **WHEN** a local file has multiple audio tracks and HLS is used
- **THEN** the master playlist exposes them as audio renditions with the selected track marked as default

#### Scenario: Preparation failure

- **WHEN** HLS preparation fails
- **THEN** playback does not start and the caller receives a typed preparation error

### Requirement: Resume and seek preserve source position

The system SHALL honour a requested start position on both AirPlay versions. AirPlay 2 SHALL send an absolute start position; AirPlay 1 SHALL express it as a fraction of the known duration and MAY follow with a scrub. Seeking after playback SHALL use the receiver's scrub command and SHALL report the requested position to callers.

#### Scenario: AirPlay 2 resume

- **WHEN** media is loaded with a start position on an AirPlay 2 receiver
- **THEN** the receiver is told the absolute start position

#### Scenario: AirPlay 1 resume

- **WHEN** media is loaded with a start position and the duration is known on an AirPlay 1 receiver
- **THEN** the receiver is given the equivalent start fraction or is scrubbed to the position

#### Scenario: Seek during playback

- **WHEN** the user seeks to a new position
- **THEN** the receiver is scrubbed to that position

### Requirement: State and timing stay consistent across reloads

The system SHALL stop polling before a new load and SHALL ignore playback information that belongs to a replaced load. It SHALL NOT overwrite a known duration with a missing duration report, and it SHALL surface receiver-reported playback errors.

#### Scenario: Reload starts

- **WHEN** a new load or a track switch begins
- **THEN** late playback information from the previous load cannot update position, duration, or state

#### Scenario: Duration is missing

- **WHEN** the receiver omits duration in a playback report
- **THEN** a previously known duration is retained

#### Scenario: Receiver reports an error

- **WHEN** the receiver reports a playback error
- **THEN** polling stops and the error is surfaced to the caller

### Requirement: Volume is applied or reported unsupported

The system SHALL send a volume change to receivers that advertise video volume control. It SHALL report volume as unsupported when the receiver does not advertise it, and SHALL NOT report success without sending a command.

#### Scenario: Volume is supported

- **WHEN** volume is set on a receiver that advertises video volume control
- **THEN** a volume command is sent and success is reported only after the receiver accepts it

#### Scenario: Volume is unsupported

- **WHEN** volume is set on a receiver without video volume control
- **THEN** the call reports unsupported and no false success is reported

### Requirement: Reloads release previous media resources

The system SHALL remove the previous load's proxy routes, HLS directories, and temporary files before serving a replacement load.

#### Scenario: Repeated track changes

- **WHEN** audio or subtitle changes cause multiple reloads
- **THEN** each replaced load's routes and temporary files are released
