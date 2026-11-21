# Spec Delta

## Purpose

Defines playback on AirPlay 2 receivers that do not expose the classic `/play` endpoint and instead drive media through unified media control.

## ADDED Requirements

### Requirement: Unified-control receivers are identified

After an encrypted AirPlay 2 session is established, the system SHALL distinguish a receiver that accepts the classic `/play` path from one that only exposes unified media control. A receiver that does not implement `/play` but advertises AirPlay 2 and exposes `/command` SHALL be treated as a unified-control candidate.

#### Scenario: Classic receiver

- **WHEN** an AirPlay receiver accepts the `/play` request
- **THEN** playback uses the classic path and unified control is not attempted

#### Scenario: Unified-control candidate

- **WHEN** an AirPlay 2 receiver rejects `/play` as not implemented but exposes `/command`
- **THEN** the session classifies it as a unified-control candidate

### Requirement: Unified control is gated by a validated profile

The system SHALL enable unified control only for receiver profiles whose command sequence has been validated against a real working video trace. A candidate with no validated profile SHALL receive a typed unsupported-feature error that explains the limitation and suggests another protocol.

#### Scenario: Validated profile exists

- **WHEN** the receiver matches a validated unified-control profile
- **THEN** the session attempts unified-control playback

#### Scenario: No validated profile

- **WHEN** a unified-control candidate has no validated profile
- **THEN** playback fails with a typed unsupported-feature error and no partial success is reported

### Requirement: Media stream setup yields a control channel

For a validated unified-control receiver, the system SHALL set up the media stream through the AirPlay 2 `SETUP` exchange and SHALL obtain the media control port before sending playback commands. Failure to obtain the control port SHALL be reported as a typed setup error.

#### Scenario: Stream setup succeeds

- **WHEN** the receiver accepts the stream setup
- **THEN** the session records the media control port and can send commands

#### Scenario: Stream setup fails

- **WHEN** the receiver rejects or does not answer the stream setup
- **THEN** the load fails with a typed setup error

### Requirement: Playback commands use the control channel

For a validated unified-control receiver, the system SHALL send play, pause, seek, stop, and volume changes through the control channel and SHALL report state and position from the receiver's responses.

#### Scenario: Play

- **WHEN** media is loaded on a validated unified-control receiver
- **THEN** a play command is sent and playback is reported only after the receiver confirms it

#### Scenario: Pause and resume

- **WHEN** the viewer pauses and later resumes
- **THEN** the corresponding commands are sent and the reported state follows the receiver

#### Scenario: Seek

- **WHEN** the viewer seeks to a position
- **THEN** a seek command is sent and the reported position follows the receiver

#### Scenario: Stop

- **WHEN** playback is stopped
- **THEN** a stop command is sent and the session returns to an idle state

### Requirement: Unified-control failures are explicit

The system SHALL report unified-control failures as typed errors and SHALL NOT leave the session in a loading state when the receiver never confirms playback.

#### Scenario: Receiver never confirms playback

- **WHEN** the receiver accepts a command but never reports playback
- **THEN** the load fails with a typed error after a bounded wait
