/// Phrases a speaker uses to retract what they just said. Cases sharing a
/// prefix are listed longest first so the longer phrase wins.
enum CorrectionTrigger: String, CaseIterable {
  case iyaCommaChigau = "いや、違う"
  case iyaChigau = "いや違う"
  case iyaComma = "いや、"
  case janakute = "じゃなくて"
  case janaku = "じゃなく"
  case noCommaWait = "no, wait"
  case noWait = "no wait"
  case iMean = "I mean"
  case makeThat = "make that"
  case scratchThat = "scratch that"

  private static let sentenceEnds: Set<Character> = [".", "!", "?"]

  private var isLatin: Bool {
    rawValue.allSatisfy(\.isASCII)
  }

  /// Returns the end index of this trigger when it starts at `index`.
  func end(in sentence: [Character], at index: Int) -> Int? {
    guard sentence.hasPhrase(rawValue, at: index, ignoringCase: isLatin) else { return nil }
    let end = index + rawValue.count
    let previous = sentence[..<index].last { $0 != " " }
    return accepts(previous: previous, next: sentence.element(at: end)) ? end : nil
  }

  private func accepts(previous: Character?, next: Character?) -> Bool {
    switch self {
    case .iyaCommaChigau, .iyaChigau, .iyaComma:
      return previous == nil || previous == "、"
    case .janakute:
      // じゃなくても / じゃなくては mean "even if not" / "must", not a retraction.
      return next != "も" && next != "は"
    case .janaku:
      // Bare じゃなく also starts じゃなくなる ("stops being"), so require 、.
      return next == "、"
    case .noCommaWait, .noWait, .iMean, .makeThat, .scratchThat:
      // Comma-delimited only, so "I mean it" or "make that cake" stay intact.
      let previousOK = previous == nil || previous == ","
      let nextOK = next.map { $0 == "," || Self.sentenceEnds.contains($0) } ?? true
      return previousOK && nextOK
    }
  }
}
