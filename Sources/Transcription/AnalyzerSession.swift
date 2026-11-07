import AVFoundation
import AudioCapture
import CoreMedia
import Speech

actor AnalyzerSession {
  private static let finalizationTimeout = Duration.seconds(2)

  private var locale: Locale?
  private var analyzer: SpeechAnalyzer?
  private var resultsTask: Task<Void, Never>?
  private(set) var audioFormat: AVAudioFormat?

  private var utterance: Utterance?
  private var finalizationWaiter: CheckedContinuation<Bool, Never>?
  private var finalizationTimeoutTask: Task<Void, Never>?
  // The analyzer's timeline keeps running across utterances, so each one owns the results from here on.
  private var nextUtteranceStart = CMTime.zero

  func prepare(locale requested: Locale) async throws {
    if analyzer != nil, locale == requested { return }
    guard utterance == nil else { throw SpeechEngineError.alreadyTranscribing }
    guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: requested) else {
      throw SpeechEngineError.localeUnsupported(requested)
    }
    await tearDown()

    let transcriber = SpeechTranscriber(
      locale: locale,
      transcriptionOptions: [],
      // Without .fastResults no volatile result arrives until the input sequence ends (measured 2026-11-08).
      reportingOptions: [.volatileResults, .fastResults],
      attributeOptions: [.audioTimeRange]
    )
    let installed = await SpeechTranscriber.installedLocales
    if !installed.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
      do {
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]
        ) {
          try await request.downloadAndInstall()
        }
      } catch {
        throw SpeechEngineError.assetsUnavailable(String(describing: error))
      }
    }

    let analyzer = SpeechAnalyzer(modules: [transcriber])
    try await analyzer.prepareToAnalyze(in: nil)
    audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

    let results = transcriber.results
    resultsTask = Task { [weak self] in
      do {
        for try await result in results {
          await self?.receive(result)
        }
      } catch {
        await self?.resultsFailed(error)
      }
    }
    self.analyzer = analyzer
    self.locale = requested
    nextUtteranceStart = .zero
  }

  func transcribe(
    _ frames: AsyncStream<AudioFrame>,
    into output: AsyncThrowingStream<TranscriptUpdate, Error>.Continuation
  ) async {
    guard let analyzer else { return output.finish(throwing: SpeechEngineError.notPrepared) }
    guard utterance == nil else {
      return output.finish(throwing: SpeechEngineError.alreadyTranscribing)
    }
    utterance = Utterance(start: nextUtteranceStart, output: output)
    defer { utterance = nil }

    do {
      let input = AsyncStream<AnalyzerInput> { continuation in
        let forward = Task {
          for await frame in frames {
            continuation.yield(AnalyzerInput(buffer: frame.buffer))
          }
          continuation.finish()
        }
        continuation.onTermination = { _ in forward.cancel() }
      }
      guard let lastTime = try await analyzer.analyzeSequence(input) else {
        output.yield(TranscriptUpdate(text: "", isFinal: true))
        return output.finish()
      }
      nextUtteranceStart = lastTime
      try await analyzer.finalize(through: lastTime)
      utterance?.end = lastTime
      guard await waitUntilFinalized() else { throw SpeechEngineError.finalizationTimedOut }
      output.yield(TranscriptUpdate(text: utterance?.finalizedText ?? "", isFinal: true))
      output.finish()
    } catch {
      output.finish(throwing: error)
    }
  }

  private func waitUntilFinalized() async -> Bool {
    if utterance?.isFinalized ?? true { return true }
    return await withCheckedContinuation { continuation in
      finalizationWaiter = continuation
      finalizationTimeoutTask = Task {
        guard (try? await Task.sleep(for: Self.finalizationTimeout)) != nil else { return }
        self.resumeWaiter(finalized: false)
      }
    }
  }

  private func resumeWaiter(finalized: Bool) {
    finalizationTimeoutTask?.cancel()
    finalizationTimeoutTask = nil
    finalizationWaiter?.resume(returning: finalized)
    finalizationWaiter = nil
  }

  private func receive(_ result: SpeechTranscriber.Result) {
    guard var current = utterance, result.range.start >= current.start else { return }
    let text = String(result.text.characters)
    let resultEnd = CMTimeRangeGetEnd(result.range)
    if result.isFinal {
      current.finalizedText += text
      current.finalizedThrough = max(current.finalizedThrough, resultEnd)
      // A volatile range may extend into trailing silence past the final's end; the final still replaces it.
      if let pending = current.volatileStart, pending < resultEnd { current.volatileStart = nil }
    } else {
      current.volatileStart = result.range.start
      current.output.yield(TranscriptUpdate(text: current.finalizedText + text, isFinal: false))
    }
    utterance = current
    if current.isFinalized { resumeWaiter(finalized: true) }
  }

  private func resultsFailed(_ error: any Error) {
    // A throwing results sequence ends the analyzer session; the next prepare rebuilds it.
    utterance?.output.finish(throwing: error)
    resumeWaiter(finalized: false)
    analyzer = nil
    locale = nil
  }

  private func tearDown() async {
    resultsTask?.cancel()
    resultsTask = nil
    await analyzer?.cancelAndFinishNow()
    analyzer = nil
    audioFormat = nil
  }
}

private struct Utterance {
  let start: CMTime
  let output: AsyncThrowingStream<TranscriptUpdate, Error>.Continuation
  /// Set once `finalize(through:)` has returned.
  var end: CMTime?
  var finalizedText = ""
  var finalizedThrough: CMTime
  var volatileStart: CMTime?

  init(start: CMTime, output: AsyncThrowingStream<TranscriptUpdate, Error>.Continuation) {
    self.start = start
    self.output = output
    self.finalizedThrough = start
  }

  // Trailing silence yields no result reaching `end`, so a finalized utterance is one
  // with no volatile text left waiting for its final result.
  var isFinalized: Bool {
    guard let end else { return false }
    return finalizedThrough >= end || volatileStart == nil
  }
}
