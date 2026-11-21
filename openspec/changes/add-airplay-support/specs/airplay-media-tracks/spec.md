# Spec Delta

## Purpose

Defines how AirPlay audio and subtitle tracks are inventoried and how a track change is applied without losing the viewer's place in the media.

## ADDED Requirements

### Requirement: Audio tracks are exposed after loading

After a local file is loaded, the session SHALL expose the available audio tracks with their zero-based audio index, language, codec, channel count, and default flag. It SHALL identify the track currently in use.

#### Scenario: Multi-audio file

- **WHEN** a local file with multiple audio tracks is loaded
- **THEN** callers can read every track and the index of the active one

#### Scenario: Single-audio file

- **WHEN** a local file with one audio track is loaded
- **THEN** callers see one track marked active

### Requirement: Audio switching restarts at the current position

When an audio track change is requested, the system SHALL rebuild the stream with the selected track, reload it at the current playback position, and report the new active index. It SHALL NOT restart from the beginning.

#### Scenario: Switch during playback

- **WHEN** the viewer selects a different audio track at position 00:12:30
- **THEN** playback resumes with the selected track at 00:12:30

#### Scenario: Switch while paused

- **WHEN** the viewer selects a different audio track while paused
- **THEN** the new stream is positioned at the paused position

#### Scenario: Switch fails

- **WHEN** rebuilding the stream for the selected track fails
- **THEN** the caller receives a typed error and the previous stream is not silently replaced

### Requirement: Subtitles are attached and removed at the current position

The system SHALL attach a subtitle track by adding a WebVTT rendition to the stream and reload at the current position. Passing no subtitle SHALL remove the active subtitle rendition. Attachment SHALL be available only when the receiver supports HLS.

#### Scenario: Attach a subtitle

- **WHEN** a subtitle is selected at position 00:05:00
- **THEN** playback resumes with the subtitle active at 00:05:00

#### Scenario: Remove a subtitle

- **WHEN** subtitles are turned off during playback
- **THEN** the stream reloads at the current position without an active subtitle

#### Scenario: Receiver cannot show subtitles

- **WHEN** subtitles are selected on a receiver without HLS support
- **THEN** the caller receives a typed unsupported-feature error and playback is not interrupted

### Requirement: Subtitle switching does not rewind

When one subtitle is replaced by another, the system SHALL keep only the newly selected rendition active and SHALL preserve the current playback position across the reload.

#### Scenario: Change subtitle language

- **WHEN** the viewer changes from English to Spanish subtitles at 00:08:15
- **THEN** playback resumes at 00:08:15 with Spanish active and English no longer selectable

### Requirement: Late events from a replaced stream are ignored

When a track change replaces the receiver-side stream, the system SHALL ignore position and state events that belong to the replaced stream so the reported position cannot jump backwards.

#### Scenario: Stale position after switch

- **WHEN** the replaced stream reports its final position after the new stream has started
- **THEN** the stale position is discarded
