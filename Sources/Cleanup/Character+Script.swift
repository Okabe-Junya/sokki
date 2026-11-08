extension Character {
  /// CJK punctuation, Hiragana, Katakana, Han, and full-width forms.
  private static let cjkScalars: [ClosedRange<Unicode.Scalar>] = [
    "\u{3000}"..."\u{30FF}", "\u{31F0}"..."\u{31FF}", "\u{3400}"..."\u{4DBF}",
    "\u{4E00}"..."\u{9FFF}", "\u{F900}"..."\u{FAFF}", "\u{FF00}"..."\u{FFEF}",
  ]

  var isCJK: Bool {
    guard let scalar = unicodeScalars.first else { return false }
    return Self.cjkScalars.contains { $0.contains(scalar) }
  }

  var isASCIIWordCharacter: Bool {
    isASCII && (isLetter || isNumber)
  }
}
