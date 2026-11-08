import AVFoundation
import AudioCapture
import Foundation
import Speech
import Testing

@testable import Transcription

// Hosted CI runners have no speech model installed and cannot download one.
private let needsJapaneseModel: ConditionTrait = .enabled("ja-JP speech model is not installed") {
  await SpeechTranscriber.installedLocales.contains { $0.identifier(.bcp47) == "ja-JP" }
}

@Suite(.serialized)
struct AppleSpeechEngineTests {
  @Test(needsJapaneseModel) func reusesOneAnalyzerAcrossUtterances() async throws {
    let engine = AppleSpeechEngine()
    try await engine.prepare(locale: Locale(identifier: "ja-JP"))
    let format = try #require(await engine.preferredAudioFormat())

    let first = try await run(engine, fixture: "ja-short", format: format)
    let firstFinal = try #require(first.last)
    #expect(firstFinal.isFinal)
    #expect(!firstFinal.text.isEmpty)
    #expect(first.dropLast().contains { !$0.isFinal })

    let second = try await run(engine, fixture: "ja-mixed", format: format)
    let secondFinal = try #require(second.last)
    #expect(secondFinal.isFinal)
    #expect(!secondFinal.text.isEmpty)
    #expect(!secondFinal.text.contains(firstFinal.text))
    #expect(second.dropLast().contains { !$0.isFinal })
    #expect(second.allSatisfy { !$0.text.contains(firstFinal.text) })
    #expect(second.filter(\.isFinal).count == 1)
  }

  @Test(needsJapaneseModel) func trailingAndPureSilenceStillFinalize() async throws {
    let engine = AppleSpeechEngine()
    try await engine.prepare(locale: Locale(identifier: "ja-JP"))
    let format = try #require(await engine.preferredAudioFormat())

    let speech = try loadFrames("ja-short", format: format) + silence(seconds: 2, format: format)
    let speechFinal = try #require(
      try await run(engine, label: "speech+silence", frames: speech).last)
    #expect(speechFinal.isFinal && !speechFinal.text.isEmpty)

    let silent = try #require(
      try await run(engine, label: "silence", frames: silence(seconds: 2, format: format)).last)
    #expect(silent.isFinal)
  }

  @Test(needsJapaneseModel)
  func volatileArrivesWhileInputIsOpenAndConcurrentCallThrows() async throws {
    let engine = AppleSpeechEngine()
    try await engine.prepare(locale: Locale(identifier: "ja-JP"))
    let format = try #require(await engine.preferredAudioFormat())
    let (frames, continuation) = AsyncStream.makeStream(of: AudioFrame.self)
    var first = engine.transcribe(frames).makeAsyncIterator()
    for frame in try loadFrames("ja-short", format: format) { continuation.yield(frame) }
    let live = try await first.next()
    #expect(live?.isFinal == false)

    await #expect(throws: SpeechEngineError.self) {
      _ = try await collect(engine.transcribe(AsyncStream { $0.finish() }))
    }
    continuation.finish()
    while let update = try await first.next() {
      if update.isFinal { #expect(!update.text.isEmpty) }
    }
  }

  @Test(needsJapaneseModel) func emptyInputYieldsEmptyFinal() async throws {
    let engine = AppleSpeechEngine()
    try await engine.prepare(locale: Locale(identifier: "ja-JP"))
    let updates = try await collect(engine.transcribe(AsyncStream { $0.finish() }))
    #expect(updates == [TranscriptUpdate(text: "", isFinal: true)])
  }

  @Test func transcribeBeforePrepareThrows() async {
    let engine = AppleSpeechEngine()
    await #expect(throws: SpeechEngineError.self) {
      _ = try await collect(engine.transcribe(AsyncStream { $0.finish() }))
    }
  }

  private func run(_ engine: AppleSpeechEngine, fixture: String, format: AVAudioFormat) async throws
    -> [TranscriptUpdate]
  {
    try await run(engine, label: fixture, frames: loadFrames(fixture, format: format))
  }

  private func run(_ engine: AppleSpeechEngine, label fixture: String, frames: [AudioFrame])
    async throws -> [TranscriptUpdate]
  {
    let (stream, continuation) = AsyncStream.makeStream(of: AudioFrame.self)
    let updates = engine.transcribe(stream)
    for frame in frames { continuation.yield(frame) }
    let framesFinished = ContinuousClock.now
    continuation.finish()

    var collected: [TranscriptUpdate] = []
    for try await update in updates {
      collected.append(update)
      if update.isFinal {
        let finalAfter = ContinuousClock.now - framesFinished
        print(
          "\(fixture): frames finished -> final \(finalAfter), \(collected.count - 1) volatile, text: \(update.text)"
        )
      }
    }
    return collected
  }

  private func silence(seconds: Double, format: AVAudioFormat) throws -> [AudioFrame] {
    let chunk: AVAudioFrameCount = 1_600
    return try (0..<Int(seconds * format.sampleRate) / Int(chunk)).map { _ in
      let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunk))
      buffer.frameLength = chunk
      return AudioFrame(buffer: buffer, level: 0)
    }
  }

  private func loadFrames(_ fixture: String, format: AVAudioFormat) throws -> [AudioFrame] {
    let url = try #require(
      Bundle.module.url(forResource: fixture, withExtension: "aiff", subdirectory: "Fixtures"))
    let file = try AVAudioFile(forReading: url)
    let converter = try #require(AVAudioConverter(from: file.processingFormat, to: format))
    converter.primeMethod = .none
    let chunk: AVAudioFrameCount = 4_096
    var frames: [AudioFrame] = []
    while file.framePosition < file.length {
      let input = try #require(
        AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: chunk))
      try file.read(into: input, frameCount: chunk)
      let capacity = AVAudioFrameCount(
        (Double(input.frameLength) * format.sampleRate / input.format.sampleRate).rounded(.up))
      let output = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity))
      var consumed = false
      var error: NSError?
      converter.convert(to: output, error: &error) { _, status in
        if consumed {
          status.pointee = .noDataNow
          return nil
        }
        consumed = true
        status.pointee = .haveData
        return input
      }
      if let error { throw error }
      frames.append(AudioFrame(buffer: output, level: 0))
    }
    return frames
  }
}

private func collect(_ stream: AsyncThrowingStream<TranscriptUpdate, Error>) async throws
  -> [TranscriptUpdate]
{
  var updates: [TranscriptUpdate] = []
  for try await update in stream { updates.append(update) }
  return updates
}
