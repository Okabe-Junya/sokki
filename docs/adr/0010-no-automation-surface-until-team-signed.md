# ADR 10: No Automation Surface Until the App Is Signed with a Team ID

Date: 2026-11-08

## Status

Accepted

Supersedes ADR 9.

## Context

ADR 9 chose App Intents as the only way to drive Sokki from Shortcuts, Spotlight, and `shortcuts run`. ADR 8 chose to sign releases with a self-signed identity and stay out of the Developer Program. Before implementing the intents we checked that the two work together, and they do not: the system service that registers App Intents (`linkd`) only accepts bundles whose signature carries a Team ID, and rejects a self-signed or ad-hoc app with `requiresValidatedBundle`. The metadata can be generated outside Xcode, so the obstacle is the signature alone.

The remaining ways to get a Team ID are a free Apple Development certificate, which is meant for development and testing, expires yearly, and would not change the Gatekeeper experience, or a Developer ID (US$99 a year), which would also allow notarization. The hotkey covers the primary use; automation is a secondary surface.

## Decision

We will ship without any automation surface: no App Intents, and still no URL scheme, command-line tool, or hooks, for the reasons in ADR 9. Scripted use is limited to editing the config and dictionary files (ADR 7). When releases move to a Team ID signature (Developer ID), App Intents come back as the only automation surface, under a new record that revisits ADR 9's three intents.

## Consequences

Positive: the $0 distribution of ADR 8 stands; no build-time metadata step whose processor arguments are undocumented; nothing to keep working against a signature it cannot have.

Negative: Shortcuts, Spotlight actions, and terminal triggering are unavailable; users who want them need the hotkey or the files.

Neutral: the decision to pay for a Developer ID should be driven by the first-launch friction of ADR 8, not by automation alone; whichever reason triggers it also unblocks this record.
