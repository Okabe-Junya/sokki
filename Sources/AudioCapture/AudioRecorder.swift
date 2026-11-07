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
  private static let tapBufferSize: AVAudioFrameCount = 4_096

  private var engine: AVAudioEngine?
  private var configurationObserver: (any NSObjectProtocol)?
  private var continuation: AsyncStream<AudioFrame>.Continuation?

  /// Creates an idle recorder; the audio engine is built on the first `start`.
  public init() {}

  /// Whether the user has granted microphone access.
  public static func hasMicrophoneAccess() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
  }

  /// Prompts for microphone access if undecided; returns whether access is granted.
  public static func requestMicrophoneAccess() async -> Bool {
    await AVCaptureDevice.requestAccess(for: .audio)
  }

  // Built outside actor isolation: a closure formed in an actor method would inherit
  // the actor's isolation and trap when Core Audio calls it on its real-time thread.
  nonisolated private static func makeTapBlock(
    converter: AVAudioConverter,
    outputFormat: AVAudioFormat,
    continuation: AsyncStream<AudioFrame>.Continuation
  ) -> AVAudioNodeTapBlock {
    { buffer, _ in
      guard let converted = convert(buffer, with: converter, to: outputFormat) else { return }
      continuation.yield(AudioFrame(buffer: converted, level: rmsLevel(of: converted)))
    }
  }

  /// Starts capturing and returns frames converted to `outputFormat`.
  /// Throws if already running or if no converter to `outputFormat` exists.
  public func start(outputFormat: AVAudioFormat) throws -> AsyncStream<AudioFrame> {
    guard continuation == nil else {
      throw AudioCaptureError.engineStartFailed("already running")
    }
    let startedAt = ContinuousClock.now
    let audioEngine = currentEngine()
    let input = audioEngine.inputNode
    let inputFormat = input.outputFormat(forBus: 0)
    guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
      throw AudioCaptureError.noInputDevice
    }
    guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
      throw AudioCaptureError.converterUnavailable
    }
    // Priming would shift timestamps against the analyzer's timeline (Apple's BufferConversion.swift).
    converter.primeMethod = .none

    let (stream, frameContinuation) = AsyncStream.makeStream(
      of: AudioFrame.self, bufferingPolicy: .unbounded)
    input.installTap(
      onBus: 0,
      bufferSize: Self.tapBufferSize,
      format: inputFormat,
      block: Self.makeTapBlock(
        converter: converter, outputFormat: outputFormat, continuation: frameContinuation)
    )
    do {
      try audioEngine.start()
    } catch {
      input.removeTap(onBus: 0)
      frameContinuation.finish()
      throw AudioCaptureError.engineStartFailed(error.localizedDescription)
    }
    continuation = frameContinuation
    let elapsedMilliseconds = Int((ContinuousClock.now - startedAt) / .milliseconds(1))
    Self.logger.info("engine start \(elapsedMilliseconds) ms")
    return stream
  }

  /// Stops capturing and finishes the stream returned by `start`; a no-op while idle.
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
    let newEngine = AVAudioEngine()
    configurationObserver = NotificationCenter.default.addObserver(
      forName: .AVAudioEngineConfigurationChange,
      object: newEngine,
      queue: nil
    ) { [weak self] _ in
      // Releasing the engine inside the notification handler can deadlock, so hop first.
      Task { await self?.handleConfigurationChange() }
    }
    engine = newEngine
    return newEngine
  }

  private func handleConfigurationChange() {
    stop()
    if let configurationObserver {
      NotificationCenter.default.removeObserver(configurationObserver)
    }
    configurationObserver = nil
    engine = nil
  }
}
