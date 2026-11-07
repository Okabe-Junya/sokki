import AVFoundation
import Testing

@testable import AudioCapture

struct BufferConversionTests {
  @Test(arguments: [
    (AVAudioFrameCount(4096), 48_000.0, 16_000.0, AVAudioFrameCount(1366)),
    (4096, 44_100, 16_000, 1487),
    (4096, 16_000, 16_000, 4096),
    (0, 48_000, 16_000, 0),
  ])
  func outputCapacityRoundsUp(
    input: AVAudioFrameCount, inputRate: Double, outputRate: Double, expected: AVAudioFrameCount
  ) {
    #expect(
      outputFrameCapacity(
        inputFrames: input, inputSampleRate: inputRate, outputSampleRate: outputRate) == expected)
  }

  @Test func rmsOfSilenceIsZero() throws {
    let buffer = try makeInt16Buffer(samples: Array(repeating: 0, count: 160))
    #expect(rmsLevel(of: buffer) == 0)
  }

  @Test func rmsOfFullScaleSquareIsOne() throws {
    let samples = (0..<160).map { $0.isMultiple(of: 2) ? Int16.max : -Int16.max }
    #expect(abs(rmsLevel(of: try makeInt16Buffer(samples: samples)) - 1) < 1e-4)
  }

  @Test func rmsOfFloatSineIsAmplitudeOverRootTwo() throws {
    let format = try #require(
      AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false))
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1600))
    buffer.frameLength = 1600
    for i in 0..<1600 {
      buffer.floatChannelData![0][i] = 0.5 * sin(2 * .pi * 100 * Float(i) / 16_000)
    }
    #expect(abs(rmsLevel(of: buffer) - Float(0.5) / Float(2).squareRoot()) < 1e-3)
  }

  @Test func emptyBufferHasZeroLevel() throws {
    #expect(rmsLevel(of: try makeInt16Buffer(samples: [])) == 0)
  }

  private func makeInt16Buffer(samples: [Int16]) throws -> AVAudioPCMBuffer {
    let format = try #require(
      AVAudioFormat(
        commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1, interleaved: true))
    let buffer = try #require(
      AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(max(samples.count, 1))))
    buffer.frameLength = AVAudioFrameCount(samples.count)
    for (i, sample) in samples.enumerated() { buffer.int16ChannelData![0][i] = sample }
    return buffer
  }
}
