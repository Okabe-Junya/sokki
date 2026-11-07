import AVFoundation

func outputFrameCapacity(
  inputFrames: AVAudioFrameCount, inputSampleRate: Double, outputSampleRate: Double
) -> AVAudioFrameCount {
  AVAudioFrameCount((Double(inputFrames) * outputSampleRate / inputSampleRate).rounded(.up))
}

func convert(_ buffer: AVAudioPCMBuffer, with converter: AVAudioConverter, to format: AVAudioFormat)
  -> AVAudioPCMBuffer?
{
  let capacity = outputFrameCapacity(
    inputFrames: buffer.frameLength,
    inputSampleRate: buffer.format.sampleRate,
    outputSampleRate: format.sampleRate
  )
  guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
    return nil
  }
  var consumed = false
  var error: NSError?
  let status = converter.convert(to: output, error: &error) { _, inputStatus in
    if consumed {
      inputStatus.pointee = .noDataNow
      return nil
    }
    consumed = true
    inputStatus.pointee = .haveData
    return buffer
  }
  guard status != .error, output.frameLength > 0 else { return nil }
  return output
}

/// RMS over all channels, normalized so full-scale is 1.
func rmsLevel(of buffer: AVAudioPCMBuffer) -> Float {
  let channels = Int(buffer.format.channelCount)
  let frames = Int(buffer.frameLength)
  guard frames > 0, channels > 0 else { return 0 }
  // Interleaved buffers expose one pointer holding every channel back to back.
  let pointers = buffer.format.isInterleaved ? 1 : channels
  let samplesPerPointer = buffer.format.isInterleaved ? frames * channels : frames
  var sum: Float = 0
  if let data = buffer.floatChannelData {
    for p in 0..<pointers {
      for i in 0..<samplesPerPointer { sum += data[p][i] * data[p][i] }
    }
  } else if let data = buffer.int16ChannelData {
    for p in 0..<pointers {
      for i in 0..<samplesPerPointer {
        let sample = Float(data[p][i]) / Float(Int16.max)
        sum += sample * sample
      }
    }
  } else {
    return 0
  }
  return min(1, (sum / Float(frames * channels)).squareRoot())
}
