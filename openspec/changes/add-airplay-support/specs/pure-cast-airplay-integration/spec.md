# Spec Delta

## Purpose

Defines how the Pure Cast application exposes AirPlay as a first-class casting protocol and how its UI, pairing flow, and platform configuration support it.

## ADDED Requirements

### Requirement: AirPlay is a first-class protocol value

The application SHALL represent AirPlay as its own protocol value in its domain model and SHALL expose protocol-specific capabilities rather than reusing Chromecast's value. AirPlay capabilities SHALL include playback, pause, and seek, SHALL include audio and subtitle switching when the package supports it, and SHALL NOT include queueing.

#### Scenario: AirPlay device is mapped

- **WHEN** the package reports an AirPlay device
- **THEN** the application maps it to the AirPlay protocol, not Chromecast

#### Scenario: Capabilities are read

- **WHEN** the UI reads an AirPlay device's capabilities
- **THEN** it receives AirPlay's capabilities with queueing disabled

### Requirement: AirPlay is discovered and connected by default

The application SHALL include AirPlay in default discovery and SHALL construct an AirPlay session when the user connects to an AirPlay device. It SHALL NOT reject AirPlay with an unsupported-protocol error.

#### Scenario: Default discovery

- **WHEN** the user opens device discovery without selecting protocols
- **THEN** AirPlay devices are included alongside Chromecast and DLNA

#### Scenario: Connect

- **WHEN** the user selects an AirPlay device
- **THEN** an AirPlay session is created and connected

### Requirement: Pairing is prompted only when required

When a connection reports that pairing is required, the application SHALL show a PIN entry dialog for that device. When pairing is not required, the application SHALL connect without showing a dialog. Cancelling the dialog SHALL return the user to the device list without leaving a half-connected session.

#### Scenario: Transient pairing

- **WHEN** a device accepts transient pairing
- **THEN** connection completes without a PIN dialog

#### Scenario: PIN required

- **WHEN** a device reports that pairing is required
- **THEN** the application shows a PIN dialog and connects after a successful PIN

#### Scenario: Pairing cancelled

- **WHEN** the user cancels the PIN dialog
- **THEN** no session is left connected and the device list is shown

### Requirement: Pairing credentials persist per device

The application SHALL store successful pairing credentials keyed by the device's stable identifier and SHALL reuse them on later connections. It SHALL discard credentials that the device rejects.

#### Scenario: Reconnect without a PIN

- **WHEN** the user connects again to a previously paired device
- **THEN** the stored credentials are used and no PIN dialog is shown

#### Scenario: Rejected credentials

- **WHEN** the device rejects the stored credentials
- **THEN** the credentials are discarded and the pairing flow is shown again

### Requirement: Controls follow AirPlay capabilities

The UI SHALL show audio-track switching only when the device supports it, SHALL show subtitle controls only when the device supports them, and SHALL hide or disable volume when the device does not support volume. The device's protocol label SHALL read AirPlay.

#### Scenario: Audio switching is supported

- **WHEN** an AirPlay device reports audio switching support and the media has multiple tracks
- **THEN** the audio-track control is available

#### Scenario: Audio switching is unsupported

- **WHEN** the device does not report audio switching support
- **THEN** the audio-track control is not shown as an available action

#### Scenario: Volume is unsupported

- **WHEN** the device does not report volume support
- **THEN** the volume control is hidden or disabled

### Requirement: AirPlay platform declarations are present

The application SHALL declare `_airplay._tcp` in the Bonjour service list on iOS and macOS and SHALL describe local-network access consistently with the protocols it discovers. Android SHALL retain the permissions required for multicast discovery.

#### Scenario: iOS discovery

- **WHEN** the app browses for AirPlay devices on iOS
- **THEN** the AirPlay service declaration permits the browse

#### Scenario: Android discovery

- **WHEN** the app browses for AirPlay devices on Android
- **THEN** multicast discovery is permitted by the manifest and runtime configuration

### Requirement: Local media uses AirPlay preparation

When a local file is cast to AirPlay, the application SHALL route it through the package's AirPlay local-file preparation so probing, remuxing, and transcoding apply. It SHALL NOT send an unprepared MKV, TS, or other unsupported container to the receiver.

#### Scenario: Local MKV

- **WHEN** the user casts a local MKV to AirPlay
- **THEN** the package prepares a compatible stream before playback

#### Scenario: Preparation fails

- **WHEN** the local file cannot be made compatible
- **THEN** the UI shows an actionable error and does not claim playback started
