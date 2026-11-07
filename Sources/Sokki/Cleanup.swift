import Foundation

/// Deterministic text cleanup applied between recognition and insertion.
/// v1 only trims; the filler / self-correction / dictionary pipeline lands in
/// its own module later.
enum Cleanup {
  static func apply(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
