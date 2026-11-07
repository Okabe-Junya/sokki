/// Reasons `AudioRecorder.start(outputFormat:)` can fail.
public enum AudioCaptureError: Error, Sendable {
  /// Microphone access has not been granted.
  case microphoneAccessDenied
  /// No usable input device is connected.
  case noInputDevice
  /// The audio engine failed to start; the payload describes why.
  case engineStartFailed(String)
  /// No converter exists from the input format to the requested format.
  case converterUnavailable
}
