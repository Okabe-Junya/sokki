/// Drops the phrase a speaker retracted ("明日、いや、明後日" → "明後日"), at most
/// once per sentence.
enum SelfCorrection {
  private static let alwaysSentenceEnds: Set<Character> = ["。", "！", "？"]
  private static let latinSentenceEnds: Set<Character> = [".", "!", "?"]
  private static let phraseBoundaries: Set<Character> = ["、", ","]
  private static let separators: Set<Character> = ["、", ",", " "]

  static func apply(_ text: String) -> String {
    String(sentences(in: Array(text)).flatMap(correct))
  }

  private static func sentences(in chars: [Character]) -> [[Character]] {
    var sentences: [[Character]] = []
    var current: [Character] = []
    var index = 0
    while index < chars.count {
      let char = chars[index]
      current.append(char)
      index += 1
      guard endsSentence(char, next: chars.element(at: index)) else { continue }
      while chars.element(at: index) == " " {
        current.append(" ")
        index += 1
      }
      sentences.append(current)
      current = []
    }
    if !current.isEmpty { sentences.append(current) }
    return sentences
  }

  /// A Latin period ends a sentence only before a space, so "3.5" stays whole.
  private static func endsSentence(_ char: Character, next: Character?) -> Bool {
    if Self.alwaysSentenceEnds.contains(char) { return true }
    return Self.latinSentenceEnds.contains(char) && (next == nil || next == " ")
  }

  private static func correct(_ sentence: [Character]) -> [Character] {
    guard let (start, end) = firstTrigger(in: sentence) else { return sentence }
    var prefix = keptPrefix(of: sentence, before: start)
    let rest = Array(sentence[end...].drop { Self.separators.contains($0) })
    guard rest.contains(where: isMeaningful) else {
      while let last = prefix.last, Self.separators.contains(last) { prefix.removeLast() }
      return prefix.isEmpty ? [] : prefix + rest
    }
    if prefix.last == "," { prefix.append(" ") }
    return prefix + rest
  }

  private static func firstTrigger(in sentence: [Character]) -> (start: Int, end: Int)? {
    for index in sentence.indices {
      for trigger in CorrectionTrigger.allCases {
        if let end = trigger.end(in: sentence, at: index) { return (index, end) }
      }
    }
    return nil
  }

  /// Everything up to and including the phrase boundary before the retracted phrase.
  private static func keptPrefix(of sentence: [Character], before start: Int) -> [Character] {
    var end = start
    while end > 0, Self.separators.contains(sentence[end - 1]) { end -= 1 }
    guard let boundary = sentence[..<end].lastIndex(where: Self.phraseBoundaries.contains) else {
      return []
    }
    return Array(sentence[...boundary])
  }

  private static func isMeaningful(_ char: Character) -> Bool {
    char.isLetter || char.isNumber
  }
}
