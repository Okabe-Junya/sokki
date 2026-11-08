# ADR 8: Self-Signed Prebuilt Releases Without a Developer ID

Date: 2026-11-08

## Status

Accepted

## Context

A prebuilt app is wanted so people can try Sokki without a toolchain. Apple's Developer Program costs US$99 a year and is the only way to notarize; without notarization, macOS 26 blocks the first launch of a downloaded app until the user chooses "Open Anyway" in System Settings (the Control-click bypass was removed in macOS 15), and Homebrew's main cask repository has excluded unnotarized apps since 2026-09-01. Ad-hoc and self-signed signatures are treated identically by Gatekeeper, but they differ afterwards: an ad-hoc signature changes on every build, so macOS forgets the microphone, Input Monitoring, and Accessibility grants on each update, while a stable self-signed identity keeps them. Files fetched with `curl` or `URLSession` carry no quarantine flag, so a future in-app updater would not hit Gatekeeper again. The intended audience is the author and other developers.

## Decision

We will publish prebuilt zips on GitHub Releases, signed in CI with a long-lived self-signed identity ("Sokki Development") whose certificate is stored as a repository secret, and we will not join the Developer Program. The README documents the one-time "Open Anyway" step and the `xattr` alternative. The release workflow keeps a notarization step that runs only when Developer ID secrets are present, so moving to notarized releases is a secrets change, not a redesign. Updates are announced in the menu by comparing the latest release tag with the running version; installing them stays manual.

## Consequences

Positive: zero recurring cost; permissions survive updates; releases are reproducible from CI without the author's machine.

Negative: every new user sees the Gatekeeper block once; the app cannot be in Homebrew's main cask repository; the private key is a single point of failure, so it is backed up offline, and losing it would reset every user's permissions on the next update; users have no way to verify who holds the certificate.

Neutral: revisit if downloads exceed about 100 a month or three Gatekeeper-related issues are filed; the switch resets permissions once because the designated requirement changes.
