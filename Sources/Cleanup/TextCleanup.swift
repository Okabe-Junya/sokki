import Foundation

/// Turns raw recognizer output into insert-ready text. Every rule is
/// deterministic and conservative: text a rule is unsure about is left as is.
public enum TextCleanup {
  /// Normalizes whitespace, removes fillers, applies self-corrections, then
  /// the personal dictionary, and trims the result.
  public static func apply(_ text: String, dictionary: PersonalDictionary = .empty) -> String {
    let normalized = WhitespaceNormalization.apply(text)
    let corrected = SelfCorrection.apply(FillerRemoval.apply(normalized))
    return dictionary.apply(to: corrected).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
