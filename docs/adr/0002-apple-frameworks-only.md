# ADR 2: Apple Frameworks Only, No Third-Party Packages

Date: 2026-11-08

## Status

Accepted

## Context

The app promises that audio and text never leave the Mac. Every dependency widens the surface that has to be audited for that promise, and the usual macOS utility packages (hotkey recorders, update frameworks, speech models) each pull in their own update channel or model download. macOS 26 ships on-device speech recognition, audio capture, event taps, pasteboard, settings UI, launch-at-login, and App Intents as system frameworks.

## Decision

We will build on Apple frameworks only. `Package.swift` declares no package dependencies. A third-party package is added only when a measured gap cannot be closed with a system framework, and the record that adds it names the measurement.

## Consequences

Positive: nothing to audit for network access except our own code; `swift build` needs no network after the toolchain is installed; the binary is a few megabytes.

Negative: no Sparkle-style updater, no ready-made hotkey recorder, no Whisper-family model unless a later record admits one (see ADR 3). Each of those is reimplemented in a smaller form or left out.

Neutral: the module boundaries in `Package.swift` (`HotkeyKit`, `AudioCapture`, `Transcription`, `TextInsertion`, `Cleanup`) exist so that a dependency, if ever admitted, is confined to one module.
