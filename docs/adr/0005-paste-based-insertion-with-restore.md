# ADR 5: Insert Text by Pasting, Then Restore the Clipboard

Date: 2026-11-08

## Status

Accepted

## Context

The transcript must land at the caret of whatever app is in front. Setting the value through the Accessibility API works only in native AppKit text fields and is unreliable in browsers and Electron apps. Synthesizing key events per character is slow and interferes with input methods. Pasting works everywhere a text field accepts ⌘V, but it overwrites the user's clipboard and, if the clipboard is restored too early, the app pastes the old contents instead.

## Decision

We will insert by writing the transcript to the general pasteboard with a promise-based provider, sending ⌘V from a private event source after any held modifiers are released, treating the provider callback as the receipt that the app has read the text, and then restoring every previous pasteboard item and type after a short settle time, with a 1.5 s fallback if no receipt arrives. The written item carries the transient, concealed, and auto-generated marker types so clipboard managers ignore it. If secure input is active or the focused element is a secure text field, we will not insert and will report why.

## Consequences

Positive: works in native, web, and Electron apps alike; the clipboard is back within about 100 ms on the reference machine; the measured release-to-inserted time is 123 to 160 ms.

Negative: needs the Accessibility permission for the key event; clipboard managers that ignore the marker types may still record the transcript; an app that reads the pasteboard without triggering the provider falls back to the timeout.

Neutral: direct Accessibility insertion for an allowlist of native apps remains possible later and would reuse the same `TextInserter` entry point.
