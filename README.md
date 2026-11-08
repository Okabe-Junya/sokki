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

## Usage

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

## Activity log

Each utterance appends one JSON line to `~/Library/Logs/Sokki/activity.jsonl`
with its outcome, timings, character counts, input level, and the hotkey and
locale it ran under. The transcript itself is never written. Use it to see how
settings behave over time:

```sh
# median time from release to insertion, per locale
jq -s 'map(select(.utterance.outcome == "inserted"))
  | group_by(.locale)
  | map({locale: .[0].locale, n: length,
         medianInsertMs: (map(.utterance.insertMs) | sort | .[length / 2 | floor])})' \
  ~/Library/Logs/Sokki/activity.jsonl
```

The log keeps two files of about 1 MB each: when `activity.jsonl` fills up it
becomes `activity.1.jsonl` and the older one is deleted. Delete either file at
any time.

## Contributing

Bug reports and feature requests are welcome as
[issues](https://github.com/Okabe-Junya/sokki/issues). Pull requests are
limited to collaborators, so please open an issue instead of a pull request.

To build from source, see [docs/development.md](docs/development.md).

## License

MIT
