# ADR 4: Push-to-Talk on a Lone Modifier Key via a Listen-Only Event Tap

Date: 2026-11-08

## Status

Superseded by ADR 12 on 2026-11-09: the hotkey becomes a recorded chord of modifier keys.

## Context

The trigger must work in every app, including password fields where secure input is enabled. Key-down and key-up of ordinary keys are withheld during secure input; modifier-state changes (`flagsChanged`) still arrive. macOS has no system recorder control for a single modifier key, and `fn` / Globe can only be used after the user sets "Press 🌐 key" to "Do Nothing" in System Settings and only with Apple keyboards. Right Option is free on most layouts and needs no system change. A left/right distinction requires the device-specific flag bits, because the generic Option mask cannot tell "right Option released while left Option is held" from "still down". Long dictations are tiring to hold.

## Decision

We will observe one modifier key with a listen-only `CGEventTap` on a dedicated thread, and classify edges in a small state machine: a press shorter than 300 ms is ignored, a longer hold dictates until release, two short taps within 300 ms lock a hands-free session that the next tap ends, and Escape discards. The default key is right Option; the user chooses among a fixed list of modifier presets instead of recording an arbitrary shortcut.

## Consequences

Positive: works during secure input, in full-screen apps, and with any keyboard; no shortcut conflicts with ordinary chords; the state machine is unit-tested without an event tap.

Negative: needs the Input Monitoring permission, which only takes effect after the grant and is polled for; while a hands-free session is locked, any press of the hotkey ends it, so Option-based shortcuts are unavailable until then; no custom key combinations.

Neutral: the tap is listen-only, so it cannot swallow the key; the modifier still reaches the frontmost app.
