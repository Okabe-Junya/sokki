import AudioCapture
import Foundation
import HotkeyKit
import TextInsertion
import Transcription
import os

/// Owns the lifecycle of one utterance: hotkey event → recording →
/// transcription → cleanup → insertion. Exactly one utterance is in flight at
/// a time; events that do not fit the current state are ignored.
///
/// Gestures: hold to dictate (release inserts), double-tap to lock hands-free
/// (the next tap inserts), Escape discards in either mode.
actor DictationSession {
  private let engine: any SpeechEngine
  private let recorder: AudioRecorder
  private let inserter: TextInserter
  private let observer: @Sendable (SessionState, String) -> Void
  private let logger = Logger(subsystem: "dev.junya.sokki", category: "session")

  private var state: SessionState = .idle
  private var utterance: Task<String, Error>?
  private var peakLevel: Float = 0

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
      if state == .listening(locked: true) {
        await finishAndInsert()
      } else {
        await startListening()
      }
    case .doubleTapped:
      lock()
    case .cancelled, .escape:
      await cancel()
    case .released:
      await finishAndInsert()
    }
  }

  private func startListening() async {
    guard state == .idle || state.isFailed else { return }
    guard AudioRecorder.hasMicrophoneAccess() else {
      setState(.failed("Microphone permission missing"))
      return
    }
    guard let format = await engine.preferredAudioFormat() else {
      setState(.failed("speech engine not ready"))
      return
    }
    do {
      let frames = try await recorder.start(outputFormat: format)
      let updates = engine.transcribe(metered(frames))
      setState(.listening(locked: false))
      utterance = Task {
        var finalText = ""
        for try await update in updates {
          if update.isFinal {
            finalText = update.text
          } else {
            publishLive(update.text)
          }
        }
        return finalText
      }
    } catch {
      setState(.failed("\(error)"))
    }
  }

  // A denied or muted microphone yields digital silence, which the recognizer
  // still turns into text; the peak level tells the two apart.
  private func metered(_ frames: AsyncStream<AudioFrame>) -> AsyncStream<AudioFrame> {
    peakLevel = 0
    let (stream, continuation) = AsyncStream<AudioFrame>.makeStream()
    Task {
      for await frame in frames {
        peakLevel = max(peakLevel, frame.level)
        continuation.yield(frame)
      }
      continuation.finish()
    }
    return stream
  }

  private func lock() {
    guard state == .listening(locked: false) else { return }
    setState(.listening(locked: true))
  }

  private func publishLive(_ text: String) {
    guard state.isListening else { return }
    observer(state, text)
  }

  private func cancel() async {
    guard state.isListening, let utterance else { return }
    await recorder.stop()
    // Let the engine finalize and return to idle so the next utterance can start.
    _ = try? await utterance.value
    self.utterance = nil
    setState(.idle)
  }

  private func finishAndInsert() async {
    guard state.isListening, let utterance else { return }
    let released = ContinuousClock.now
    setState(.finalizing)
    await recorder.stop()
    defer {
      self.utterance = nil
      if state != .idle, !state.isFailed { setState(.idle) }
    }
    do {
      let text = Cleanup.apply(try await utterance.value)
      let finalAfter = Self.milliseconds(from: released, to: ContinuousClock.now)
      guard peakLevel > 0 else {
        logger.error("no audio captured, final after \(finalAfter) ms")
        setState(.failed("No audio captured: check the Microphone permission and input device"))
        return
      }
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
    logger.debug("state \(String(describing: new))")
    state = new
    observer(new, "")
  }
}
