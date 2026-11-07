import Foundation

/// Reasons a `SpeechEngine` can fail to prepare or transcribe.
public enum SpeechEngineError: Error, Sendable {
  /// No on-device model supports the requested locale.
  case localeUnsupported(Locale)
  /// The model assets could not be downloaded or installed; the payload describes why.
  case assetsUnavailable(String)
  /// `transcribe` was called before a successful `prepare`.
  case notPrepared
  /// An utterance is already being transcribed.
  case alreadyTranscribing
  /// The final result did not arrive in time after the input ended.
  case finalizationTimedOut
}
