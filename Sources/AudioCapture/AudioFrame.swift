import AVFAudio

/// One chunk of microphone audio, already converted to the format the
/// speech engine asked for. Buffers are never mutated after creation, so
/// handing them across isolation boundaries is safe despite `AVAudioPCMBuffer`
/// not being `Sendable`.
public struct AudioFrame: @unchecked Sendable {
  public let buffer: AVAudioPCMBuffer
  /// RMS level of this frame normalized to 0...1, for a level meter.
  public let level: Float

  public init(buffer: AVAudioPCMBuffer, level: Float) {
    self.buffer = buffer
    self.level = level
  }
}
