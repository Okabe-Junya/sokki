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

An Apple Development certificate from Xcode (any Apple Account, no paid
program) works the same way; `security find-identity -v -p codesigning` lists
what is available.

To let GitHub Releases sign with the same identity, run
`sh scripts/export-identity.sh` and follow the commands it prints.

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
