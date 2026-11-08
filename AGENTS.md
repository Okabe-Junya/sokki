# AGENTS.md

Working agreement for AI agents in this repository.

- Everything runs on-device. Do not add network calls, telemetry, or
  third-party packages; Apple frameworks only.
- Swift 6 language mode with complete strict concurrency. Fix data-race
  diagnostics properly instead of silencing them.
- Keep the module boundaries in `Package.swift`: `HotkeyKit`, `AudioCapture`,
  `Transcription`, `TextInsertion`, `Cleanup` know nothing about each other;
  only the `Sokki` target wires them together.
- One `SpeechTranscriber` is bound to one `SpeechAnalyzer` for its whole
  lifetime. Never attach a transcriber to a second analyzer (runtime trap).
- Tools come from `mise.toml` (`mise install`); do not add `brew install` steps.
  Verify with `task check` and `task app`; run the `.app`, not the bare
  binary, when a change touches permissions or the hotkey.
- Comments in English, only where the reason is not obvious from the code.
- Conventional Commits, single line, no attribution trailers.
- Decisions that are hard to reverse live in `docs/adr` (Nygard format, one
  per file). Read the relevant record before changing the speech engine,
  hotkey model, insertion method, settings location, signing, or automation
  surface; a changed decision gets a new superseding record.
