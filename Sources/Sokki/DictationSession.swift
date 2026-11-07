import AudioCapture
import Foundation
import HotkeyKit
import TextInsertion
import Transcription
import os

/// Owns the lifecycle of one utterance: hotkey event → recording →
/// transcription → cleanup → insertion. Exactly one utterance is in flight at
/// a time; events that do not fit the current state are ignored.
actor DictationSession {
  private let engine: any SpeechEngine
  private let recorder: AudioRecorder
  private let inserter: TextInserter
  private let observer: @Sendable (SessionState, String) -> Void
  private let logger = Logger(subsystem: "dev.junya.sokki", category: "session")

  private var state: SessionState = .idle
  private var utterance: Task<String, Error>?

  init(
    engine: any SpeechEngine,
    recorder: AudioRecorder,
    inserter: TextInserter,
    observer: @escaping @Sendable (SessionState, String) -> Void
  ) {
    self.engine = engine
    self.recorder = recorder
    self.inserter = inserter
    self.observer = observer
  }

  private static func milliseconds(
    from start: ContinuousClock.Instant, to end: ContinuousClock.Instant
  )
    -> Int
  {
    Int((end - start) / .milliseconds(1))
  }

  func prepare(locale: Locale) async throws {
    try await engine.prepare(locale: locale)
  }

  func handle(_ event: HotkeyEvent) async {
    switch event {
    case .pressed:
      await startListening()
    case .cancelled, .escape:
      await cancel()
    case .released:
      await finishAndInsert()
    case .doubleTapped:
      break
    }
  }

  private func startListening() async {
    guard state == .idle || isFailed(state) else { return }
    guard let format = await engine.preferredAudioFormat() else {
      setState(.failed("speech engine not ready"))
      return
    }
    do {
      let frames = try await recorder.start(outputFormat: format)
      let updates = engine.transcribe(frames)
      setState(.listening)
      utterance = Task { [observer] in
        var finalText = ""
        for try await update in updates {
          if update.isFinal {
            finalText = update.text
          } else {
            observer(.listening, update.text)
          }
        }
        return finalText
      }
    } catch {
      setState(.failed("\(error)"))
    }
  }

  private func cancel() async {
    guard state == .listening, let utterance else { return }
    await recorder.stop()
    // Let the engine finalize and return to idle so the next utterance can start.
    _ = try? await utterance.value
    self.utterance = nil
    setState(.idle)
  }

  private func finishAndInsert() async {
    guard state == .listening, let utterance else { return }
    let released = ContinuousClock.now
    setState(.finalizing)
    await recorder.stop()
    defer {
      self.utterance = nil
      if state != .idle, !isFailed(state) { setState(.idle) }
    }
    do {
      let text = Cleanup.apply(try await utterance.value)
      let finalAfter = Self.milliseconds(from: released, to: ContinuousClock.now)
      guard !text.isEmpty else {
        logger.info("empty utterance, final after \(finalAfter) ms")
        setState(.idle)
        return
      }
      setState(.inserting)
      let outcome = try await inserter.insert(text)
      let insertAfter = Self.milliseconds(from: released, to: ContinuousClock.now)
      logger.info(
        "final +\(finalAfter) ms, inserted +\(insertAfter) ms, \(text.count) chars, \(String(describing: outcome))"
      )
      setState(.idle)
    } catch {
      logger.error("utterance failed: \(error)")
      setState(.failed("\(error)"))
    }
  }

  private func setState(_ new: SessionState) {
    state = new
    observer(new, "")
  }

  private func isFailed(_ state: SessionState) -> Bool {
    if case .failed = state { return true }
    return false
  }
}
