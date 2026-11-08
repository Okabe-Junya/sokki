# ADR 9: App Intents Are the Only Automation Surface

Date: 2026-11-08

## Status

Superseded by ADR 10 on 2026-11-08: the self-signed releases of ADR 8 cannot register App Intents.

## Context

Users of developer tools expect to drive them from scripts and launchers. Candidates were a URL scheme (`sokki://start`), a command-line tool, hook commands run around each utterance, and App Intents. A URL scheme fires from any web page the user clicks, which for a microphone trigger is an unacceptable default; tools that expose state-changing URLs guard them with a confirmation dialog or a token. A CLI would duplicate what the files (ADR 7) and the system already provide. Hook commands would put an external process inside the 400 ms budget. App Intents appear in Shortcuts, Siri, and the macOS 26 Spotlight with one implementation, need no dependency, and are runnable from a terminal with `shortcuts run`.

## Decision

We will expose three App Intents, "Toggle Dictation", "Set Language", and "Add Dictionary Entry", through an `AppShortcutsProvider`, and nothing else: no URL scheme, no bundled command-line tool, no hooks. Scripted use goes through `shortcuts run`, the config file, and the dictionary file.

## Consequences

Positive: one surface to document and test; the system handles permissions and discovery; terminal use is possible without shipping a binary.

Negative: a Shortcut invocation is slower than a local socket and goes through the Shortcuts app; users who want a deep link to a settings pane will have to wait for a later record that adds an open-only URL.

Neutral: the intents call the same session and settings code the menu uses, so nothing is reachable through automation that is not reachable through the UI.
