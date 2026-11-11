# Development

## Setup

```sh
brew install mise   # or https://mise.jdx.dev/getting-started.html
mise install        # task and SwiftLint at the versions in mise.toml / mise.lock
```

If `mise` is not activated in your shell, prefix the task commands with
`mise exec --`.

## Build and run

```sh
task app      # build/Sokki.app
task run
```

Run the `.app`, not the bare binary, when a change touches permissions or the
hotkey: macOS grants permissions to the app bundle.

## Signing

`task app` signs ad-hoc by default, which is fine for a quick try but macOS
forgets the three permissions every time the app is rebuilt. For daily use,
sign with a stable identity:

```sh
task identity                        # self-signed "Sokki Development" in your login keychain
task app IDENTITY="Sokki Development"
```

An Apple Development or Developer ID certificate works the same way;
`security find-identity -v -p codesigning` lists what is available. Every build
uses the hardened runtime with `scripts/Sokki.entitlements`, as releases do.

Releases are signed with the maintainer's Developer ID Application certificate
and notarized in CI. To install a new or renewed certificate, create the
request with `openssl req -new -newkey rsa:2048 -nodes -keyout key.pem -out
request.csr`, upload `request.csr` under Certificates in the Apple Developer
account, then run `sh scripts/pack-identity.sh key.pem
developerID_application.cer` and follow the commands it prints. Notarization
reads an App Store Connect API key from the `APPLE_API_KEY_P8`,
`APPLE_API_KEY_ID`, and `APPLE_API_ISSUER_ID` secrets.

## Checks

```sh
task check    # swift-format lint, SwiftLint (every rule, strict), analyzer rules, tests
task fix      # autocorrect what the linters can, then format
```

Formatting is `swift format` with its defaults. SwiftLint runs with every rule
enabled and warnings treated as errors; the few rules switched off, and why,
are listed in `.swiftlint.yml`.

## Layout

| Target | Role |
|---|---|
| `HotkeyKit` | Listen-only event tap, modifier-key press / release / double-tap state machine |
| `AudioCapture` | `AVAudioEngine` microphone capture converted to the engine's format |
| `Transcription` | `SpeechEngine` protocol and the Apple `SpeechAnalyzer` implementation |
| `TextInsertion` | Clipboard paste with promise-based read receipt and clipboard restore |
| `Cleanup` | Deterministic transcript cleanup (whitespace, fillers, self-corrections) and the JSON personal dictionary |
| `ActivityLog` | Size-bounded JSON Lines file with one rotated generation |
| `Sokki` | Menu bar app and the per-utterance `DictationSession` |

## Design decisions

The choices that are hard to reverse (speech engine, hotkey model, insertion
method, settings location, signing and distribution, automation surface,
activity log) are
recorded in [adr](adr), one short record per decision.
