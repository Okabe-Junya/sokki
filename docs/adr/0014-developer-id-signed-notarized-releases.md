# ADR 14: Developer ID Signed and Notarized Releases

Date: 2026-11-11

## Status

Accepted

Supersedes ADR 8.

## Context

ADR 8 shipped self-signed releases to avoid the Apple Developer Program fee. Installing the first release showed the cost of that choice more sharply than expected: macOS records provenance on any downloaded or copied app, so Gatekeeper blocked the first launch even after the quarantine attribute was removed, and the only ways through were "Open Anyway" in System Settings or a `sudo spctl` rule. Every user, including the author, meets that block on every version. ADR 10 also kept App Intents off because only a signature with a Team ID registers them.

The author has joined the Developer Program, which provides a Developer ID Application certificate with a Team ID and lets Apple notarize builds.

## Decision

We will sign releases with the author's Developer ID Application certificate, using the hardened runtime, a secure timestamp, and an entitlement for microphone input, and notarize and staple every release in CI with an App Store Connect API key. A release that is not notarized fails the workflow instead of shipping. The certificate and the API key live in repository secrets; `scripts/pack-identity.sh` packs a new or renewed certificate. Local builds keep accepting any identity, and every build uses the hardened runtime so local and released apps behave alike.

## Consequences

Positive: a downloaded release opens without a Gatekeeper prompt; the app can be offered through Homebrew's main cask repository; the Team ID meets the condition ADR 10 set for reconsidering App Intents.

Negative: US$99 a year; the certificate has to be renewed before it expires (the first one on 2027-12-11) and the membership yearly, and a lapsed membership blocks new releases (published ones keep working); the designated requirement changes, so permissions granted to the self-signed builds are asked for once more.

Neutral: App Intents stay off until a new record revisits ADR 9's intents; an in-app updater would still avoid Gatekeeper because files fetched with `URLSession` carry no quarantine flag.
