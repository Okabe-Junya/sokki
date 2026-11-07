import AVFoundation
import AudioCapture
import Speech

/// `SpeechEngine` backed by macOS 26 `SpeechAnalyzer` + `SpeechTranscriber`.
///
/// One analyzer and one transcriber live for the engine's lifetime and are
/// reused across utterances. Never attach a transcriber to a second analyzer:
/// that traps at runtime (SIGTRAP) on the second analyzer's first input.
public final class AppleSpeechEngine: SpeechEngine {
    public init() {}

    public func prepare(locale: Locale) async throws {
        fatalError("unimplemented")
    }

    public func preferredAudioFormat() async -> AVAudioFormat? {
        fatalError("unimplemented")
    }

    public func transcribe(_ frames: AsyncStream<AudioFrame>) -> AsyncThrowingStream<TranscriptUpdate, Error> {
        fatalError("unimplemented")
    }
}
