# Koe

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

## Build and run

```sh
make app      # build/Koe.app
make run
```

Koe is a menu bar app. On first launch it asks for three permissions, each
of which can also be opened from the menu:

| Permission | Why |
|---|---|
| Microphone | Record while the hotkey is held |
| Input Monitoring | Notice the hotkey going down and up in any app |
| Accessibility | Press ⌘V in the frontmost app to insert the text |

The default hotkey is the right Option key. Hold it to dictate; a press
shorter than 300 ms is ignored. fn / Globe is available in the menu; it needs
System Settings → Keyboard → "Press 🌐 key" set to "Do Nothing", and works
only with Apple keyboards.

## Signing

`make app` signs ad-hoc by default, which is fine for a quick try but macOS
forgets the three permissions every time the app is rebuilt. For daily use,
sign with a stable identity:

1. Create one, either by signing in to Xcode with any Apple Account
   (Settings → Accounts → Manage Certificates → Apple Development), or in
   Keychain Access → Certificate Assistant → Create a Certificate with
   type "Code Signing".
2. Build with it:

   ```sh
   CODESIGN_IDENTITY="Apple Development: you@example.com (TEAMID)" make app
   ```

   `security find-identity -v -p codesigning` lists the identities available.

No paid developer program is needed to run the app on your own Mac.

## Layout

| Target | Role |
|---|---|
| `HotkeyKit` | Listen-only event tap, modifier-key press / release / double-tap state machine |
| `AudioCapture` | `AVAudioEngine` microphone capture converted to the engine's format |
| `Transcription` | `SpeechEngine` protocol and the Apple `SpeechAnalyzer` implementation |
| `TextInsertion` | Clipboard paste with promise-based read receipt and clipboard restore |
| `Koe` | Menu bar app and the per-utterance `DictationSession` |

## License

MIT
