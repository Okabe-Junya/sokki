import AVFoundation
import AudioCapture
import Speech

/// `SpeechEngine` backed by macOS 26 `SpeechAnalyzer` + `SpeechTranscriber`.
///
/// One analyzer and one transcriber live for the engine's lifetime and are
/// reused across utterances. Never attach a transcriber to a second analyzer:
/// that traps at runtime (SIGTRAP) on the second analyzer's first input.
public final class AppleSpeechEngine: SpeechEngine {
  private let session = AnalyzerSession()

  public init() {}

  public func prepare(locale: Locale) async throws {
    try await session.prepare(locale: locale)
  }

  public func preferredAudioFormat() async -> AVAudioFormat? {
    await session.audioFormat
  }

  public func transcribe(_ frames: AsyncStream<AudioFrame>) -> AsyncThrowingStream<
    TranscriptUpdate, Error
  > {
    let (stream, continuation) = AsyncThrowingStream.makeStream(of: TranscriptUpdate.self)
    let task = Task { [session] in
      await session.transcribe(frames, into: continuation)
    }
    continuation.onTermination = { _ in task.cancel() }
    return stream
  }
}
