# ADR 3: Apple's On-Device Speech Recognition Behind a Protocol

Date: 2026-11-08

## Status

Accepted

## Context

Recognition must run on the Mac. Two candidates were measured on an M1 Pro with macOS 26: the system `SpeechAnalyzer` / `SpeechTranscriber` (ja-JP, en-US), and WhisperKit large-v3 (a 627 MB model and one package dependency). Japanese recordings of 10 to 22 seconds finalized in 176 to 372 ms with the system transcriber (real-time factor 0.02 to 0.04), with no memory held by the app and no speech-recognition authorization prompt. Its known weakness is English technical terms inside Japanese speech, which come out as katakana. WhisperKit handles such terms better but costs the download, resident memory, and a dependency (ADR 2).

Two behaviours matter for a live display: volatile results arrive only when `.fastResults` is in the reporting options, and a transcriber can be attached to one analyzer for its lifetime.

## Decision

We will recognize speech with `SpeechTranscriber`, one analyzer and transcriber per engine lifetime, fed from an `AsyncStream` of converted audio buffers and finalized on key release. The engine sits behind the `SpeechEngine` protocol in the `Transcription` module. We will add a second engine only if a bake-off on 20 real recordings shows it at or under 1.0 s warm p95 and at least 30 points better on English terms.

## Consequences

Positive: zero dependencies, no model management, release-to-final latency of about 100 ms on the reference machine, and the system downloads language assets through its own UI.

Negative: katakana for English terms is the main recognition error; it is corrected after the fact by the personal dictionary (ADR 6), which the user has to feed.

Neutral: the protocol boundary keeps the second-engine option open without paying for it now.
