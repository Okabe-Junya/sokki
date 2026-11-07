/// One transcription result for the utterance in progress.
public struct TranscriptUpdate: Sendable, Equatable {
  /// Full text of the utterance so far (not a delta). Volatile updates are
  /// replaced by later ones; the final update is the complete transcript.
  public let text: String
  /// Whether this is the utterance's last, finalized update.
  public let isFinal: Bool

  /// Creates an update carrying `text`.
  public init(text: String, isFinal: Bool) {
    self.text = text
    self.isFinal = isFinal
  }
}
