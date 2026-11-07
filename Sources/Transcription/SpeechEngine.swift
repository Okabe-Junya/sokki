import AVFoundation
import AudioCapture

public struct TranscriptUpdate: Sendable, Equatable {
    /// Full text of the utterance so far (not a delta). Volatile updates are
    /// replaced by later ones; the final update is the complete transcript.
    public let text: String
    public let isFinal: Bool

    public init(text: String, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
}

public enum SpeechEngineError: Error, Sendable {
    case localeUnsupported(Locale)
    case assetsUnavailable(String)
    case notPrepared
    case alreadyTranscribing
    case finalizationTimedOut
}

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
