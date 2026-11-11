import TextInsertion

/// What happened to one utterance, without its text: timings, sizes, and the
/// outcome, so settings can be tuned from the activity log afterwards.
struct UtteranceReport: Encodable, Sendable {
  enum Outcome: String, Encodable, Sendable {
    case inserted = "inserted"
    case unread = "unread"
    case blockedBySecureInput = "blockedBySecureInput"
    case discarded = "discarded"
    case empty = "empty"
    case noAudio = "noAudio"
    case failed = "failed"
  }

  var outcome: Outcome
  var handsFree: Bool
  /// From the start of recording to release, the second tap, or Escape.
  var recordedMs: Int
  /// From release to the final transcript.
  var finalMs: Int?
  /// From release to the target reading the pasted text, or to the receipt timeout.
  var insertMs: Int?
  var rawCharacters: Int?
  /// After filler removal, self-correction, and the dictionary.
  var characters: Int?
  var peakLevel: Float
  var error: String?
}

extension UtteranceReport.Outcome {
  init(_ insertion: InsertionOutcome) {
    switch insertion {
    case .pasted: self = .inserted
    case .unread: self = .unread
    case .blockedBySecureInput: self = .blockedBySecureInput
    }
  }
}
