# Spec Delta

## Purpose

Defines how AirPlay receivers are discovered, how the correct transport and authentication path is chosen, and how sessions and pairing failures are surfaced to callers.

## ADDED Requirements

### Requirement: AirPlay receiver discovery

The system SHALL discover AirPlay video receivers advertised on `_airplay._tcp.local` and expose each receiver's name, stable identifier, address, port, and advertised feature bitmask. It SHALL exclude the local host and computer-class receivers from the castable list.

#### Scenario: Receiver is discovered

- **WHEN** an AirPlay receiver advertises `_airplay._tcp.local` on the local network
- **THEN** discovery emits it with its name, identifier, address, port, and parsed feature bits

#### Scenario: Computer receiver is excluded

- **WHEN** a discovered AirPlay receiver reports a computer model such as a Mac
- **THEN** it is not included in the castable device list

#### Scenario: A new scan is not stopped by an old timeout

- **WHEN** discovery is refreshed before the previous scan's timeout expires
- **THEN** the previous scan's timeout does not stop the new scan

### Requirement: Transport selection from advertised capabilities

The system SHALL select the AirPlay 2 transport when the receiver advertises feature bit 38 or bit 48, and AirPlay 1 otherwise. It SHALL reject a receiver that advertises neither video bit 0 nor bit 49 before sending any playback request.

#### Scenario: AirPlay 2 receiver

- **WHEN** the receiver advertises bit 38 or bit 48
- **THEN** the session is established over the encrypted AirPlay 2 transport

#### Scenario: AirPlay 1 receiver

- **WHEN** the receiver advertises video bit 0 but not the AirPlay 2 bits
- **THEN** the session uses the plain AirPlay 1 transport

#### Scenario: No video capability

- **WHEN** the receiver advertises neither video bit 0 nor bit 49
- **THEN** connection or playback fails with a typed unsupported-feature error before any media request is sent

### Requirement: Automatic transient pairing

When no stored credentials are available and the receiver advertises transient pairing through bit 43 or bit 48, the system SHALL establish the encrypted session without asking the user for a PIN.

#### Scenario: Transient pairing succeeds

- **WHEN** a receiver advertises transient pairing and no credentials are stored
- **THEN** the session pairs, encrypts, and connects without a PIN prompt

### Requirement: PIN pairing and credential reuse

When a receiver requires pairing and transient pairing is unavailable, the system SHALL report a typed pairing-required failure. After a successful PIN pair-setup it SHALL persist the credentials for that device and reuse them on later connections without another PIN.

#### Scenario: Pairing is required

- **WHEN** a receiver requires HAP pairing and no usable credentials exist
- **THEN** the caller receives a typed pairing-required failure that identifies the device

#### Scenario: PIN pairing is persisted

- **WHEN** the user completes PIN pair-setup successfully
- **THEN** the resulting credentials are stored for that device

#### Scenario: Stored credentials are reused

- **WHEN** a session connects to a device that has stored credentials
- **THEN** it performs pair-verify and connects without a PIN prompt

#### Scenario: Stale credentials are reported

- **WHEN** stored credentials are rejected by the receiver
- **THEN** the caller receives a typed pairing-required failure rather than a generic connection error

### Requirement: Connection lifecycle and resource release

The system SHALL report connecting, connected, and disconnected states in order, and SHALL release the control socket, timing server, media proxy, and polling resources when a session disconnects or is disposed.

#### Scenario: Session connects

- **WHEN** the handshake and any required authentication complete
- **THEN** the session reports connected and accepts playback commands

#### Scenario: Session disconnects

- **WHEN** disconnect is called
- **THEN** playback is stopped, polling is cancelled, and the socket, timing server, and proxy are released

#### Scenario: Receiver is unreachable

- **WHEN** the receiver cannot be reached at its advertised address and port
- **THEN** the failure is reported as an unreachable-device error rather than a pairing error
