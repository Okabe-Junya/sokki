import AVFAudio
import AudioCapture

/// A speech-to-text backend. Apple's `SpeechTranscriber` is the only
/// implementation in v1; the protocol exists so a second engine can be
/// swapped in behind the same session code.
public protocol SpeechEngine: Sendable {
  /// Loads models for `locale`. Called once at launch; safe to call again
  /// to switch locale when no transcription is in flight.
  func prepare(locale: Locale) async throws

  /// The PCM format the engine wants microphone audio in. Nil before `prepare`.
  func preferredAudioFormat() async -> AVAudioFormat?

  /// Transcribes one utterance. Consumes `frames` until it finishes, then
  /// finalizes and emits exactly one update with `isFinal == true` as the
  /// last element (an empty string if nothing was recognized).
  func transcribe(_ frames: AsyncStream<AudioFrame>) -> AsyncThrowingStream<TranscriptUpdate, Error>
}
