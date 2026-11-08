# Sokki

Push-to-talk dictation for macOS that never leaves your Mac.

Hold a modifier key, speak, release. The transcript is inserted at the caret
of whatever app is in front. Recognition runs on Apple's on-device speech
models (macOS 26 `SpeechAnalyzer`); nothing is sent to a server and there are
no third-party dependencies.

## Requirements

- macOS 26 or later on Apple Silicon
- Xcode 26 or later (for `swift build`)
- Japanese and English are supported; the first launch downloads the chosen
  language's speech model through the system if it is not already installed

## Install

1. Download `Sokki-vX.Y.Z.zip` from
   [Releases](https://github.com/Okabe-Junya/sokki/releases), unzip it, and
   move `Sokki.app` to `/Applications`.
2. Open it. The app is not notarized, so macOS blocks the first launch. Go to
   System Settings → Privacy & Security and click "Open Anyway" (the button
   stays for about an hour after the blocked attempt), or run
   `xattr -d com.apple.quarantine /Applications/Sokki.app` and open it again.
3. Grant the three permissions it asks for (see the table below).

## Build and run

```sh
task app      # build/Sokki.app
task run
```

Sokki is a menu bar app. On first launch it asks for three permissions, each
of which can also be opened from the menu:

| Permission | Why |
|---|---|
| Microphone | Record while the hotkey is held |
| Input Monitoring | Notice the hotkey going down and up in any app |
| Accessibility | Press ⌘V in the frontmost app to insert the text |

The default hotkey is the right Option key. Hold it to dictate; a press
shorter than 300 ms is ignored. Double-tap it to keep listening hands-free
until the next tap; Escape discards. fn / Globe is available in Settings; it needs
System Settings → Keyboard → "Press 🌐 key" set to "Do Nothing", and works
only with Apple keyboards.

## Settings

Settings live in `~/.config/sokki/config.json` and nowhere else; the Settings
window (menu → Settings…, or ⌘, while Sokki is active) edits that file, and
edits made with any editor apply within a second. A missing key keeps its
default, so the file only needs what differs:

```json
{
  "hotkey": "rightOption",
  "launchAtLogin": false,
  "locale": "ja-JP"
}
```

| key | values | default |
|---|---|---|
| `hotkey` | `rightOption`, `leftOption`, `rightCommand`, `fn` | `rightOption` |
| `locale` | `ja-JP`, `en-US` | `ja-JP` |
| `launchAtLogin` | `true`, `false` | `false` |

"Show Defaults" in the Settings window opens the current version's defaults as a
read-only file. A file that cannot be parsed is reported in the menu and in
Settings; the previous values stay in effect.

## Personal dictionary

Words the recognizer keeps getting wrong go in
`~/.config/sokki/dictionary.json` ("Open Dictionary…" in the menu creates it).
Each key is the text you want; the value lists what the recognizer produces:

```json
{
  "GitHub": ["ギットハブ"],
  "Kubernetes": ["クバネティス", "くばねてぃす"],
  "PR": ["プルリク", "プルリクエスト"]
}
```

The longest match wins, Latin forms match regardless of case, and an edit
applies to the next utterance. `XDG_CONFIG_HOME` is honoured.

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

## Development

```sh
brew install mise   # or https://mise.jdx.dev/getting-started.html
mise install        # task and SwiftLint at the versions in mise.toml / mise.lock
task check          # swift-format lint, SwiftLint (every rule, strict), analyzer rules, tests
task fix            # autocorrect what the linters can, then format
```

If `mise` is not activated in your shell, prefix the task commands with
`mise exec --`.

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
| `Sokki` | Menu bar app and the per-utterance `DictationSession` |

## Design decisions

The choices that are hard to reverse (speech engine, hotkey model, insertion
method, settings location, signing and distribution, automation surface) are
recorded in [docs/adr](docs/adr), one short record per decision.

## License

MIT
