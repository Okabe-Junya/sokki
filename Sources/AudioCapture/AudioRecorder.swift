import AVFoundation
import os

/// Push-to-talk microphone capture. One instance lives for the app's lifetime;
/// `start` is called on key down and `stop` on key up.
///
/// Contract:
/// - `start(outputFormat:)` starts the engine and returns a stream of frames
///   converted to `outputFormat`. Calling it while already running throws.
/// - `stop()` stops the engine and finishes the stream. Calling it while idle
///   is a no-op.
/// - The time between `start` returning and the first frame is the engine
///   start latency; it is logged so experiment E5 can read it.
public actor AudioRecorder {
  private static let logger = Logger(subsystem: "dev.junya.sokki", category: "audio")

  private var engine: AVAudioEngine?
  private var configurationObserver: (any NSObjectProtocol)?
  private var continuation: AsyncStream<AudioFrame>.Continuation?

  public init() {}

  public static func hasMicrophoneAccess() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
  }

  public static func requestMicrophoneAccess() async -> Bool {
    await AVCaptureDevice.requestAccess(for: .audio)
  }

  public func start(outputFormat: AVAudioFormat) throws -> AsyncStream<AudioFrame> {
    guard continuation == nil else {
      throw AudioCaptureError.engineStartFailed("already running")
    }
    let startedAt = ContinuousClock.now
    let engine = currentEngine()
    let input = engine.inputNode
    let inputFormat = input.outputFormat(forBus: 0)
    guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
      throw AudioCaptureError.noInputDevice
    }
    guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
      throw AudioCaptureError.converterUnavailable
    }
    // Priming would shift timestamps against the analyzer's timeline (Apple's BufferConversion.swift).
    converter.primeMethod = .none

    let (stream, continuation) = AsyncStream.makeStream(
      of: AudioFrame.self, bufferingPolicy: .unbounded)
    input.installTap(
      onBus: 0,
      bufferSize: 4096,
      format: inputFormat,
      block: Self.makeTapBlock(
        converter: converter, outputFormat: outputFormat, continuation: continuation)
    )
    do {
      try engine.start()
    } catch {
      input.removeTap(onBus: 0)
      continuation.finish()
      throw AudioCaptureError.engineStartFailed(error.localizedDescription)
    }
    self.continuation = continuation
    let elapsed = ContinuousClock.now - startedAt
    let ms = Int(
      elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000)
    Self.logger.info("engine start \(ms) ms")
    return stream
  }

  public func stop() {
    guard let continuation else { return }
    if let engine {
      engine.inputNode.removeTap(onBus: 0)
      // stop() + prepare() restarted faster than pause() in a local benchmark and releases the device.
      engine.stop()
      engine.prepare()
    }
    continuation.finish()
    self.continuation = nil
  }

  private func currentEngine() -> AVAudioEngine {
    if let engine { return engine }
    let engine = AVAudioEngine()
    configurationObserver = NotificationCenter.default.addObserver(
      forName: .AVAudioEngineConfigurationChange,
      object: engine,
      queue: nil
    ) { [weak self] _ in
      // Releasing the engine inside the notification handler can deadlock, so hop first.
      Task { await self?.handleConfigurationChange() }
    }
    self.engine = engine
    return engine
  }

  private func handleConfigurationChange() {
    stop()
    if let configurationObserver {
      NotificationCenter.default.removeObserver(configurationObserver)
    }
    configurationObserver = nil
    engine = nil
  }

  // Built outside actor isolation: a closure formed in an actor method would inherit
  // the actor's isolation and trap when Core Audio calls it on its real-time thread.
  private nonisolated static func makeTapBlock(
    converter: AVAudioConverter,
    outputFormat: AVAudioFormat,
    continuation: AsyncStream<AudioFrame>.Continuation
  ) -> AVAudioNodeTapBlock {
    return { buffer, _ in
      guard let converted = convert(buffer, with: converter, to: outputFormat) else { return }
      continuation.yield(AudioFrame(buffer: converted, level: rmsLevel(of: converted)))
    }
  }
}
