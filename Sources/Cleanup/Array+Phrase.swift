extension Array where Element == Character {
  func element(at index: Int) -> Character? {
    indices.contains(index) ? self[index] : nil
  }

  func hasPhrase(_ phrase: String, at index: Int, ignoringCase: Bool = false) -> Bool {
    let length = phrase.count
    guard index >= 0, index + length <= count else { return false }
    let slice = String(self[index..<index + length])
    return ignoringCase ? slice.lowercased() == phrase.lowercased() : slice == phrase
  }

  /// True when the phrase at `index` is not glued to ASCII letters or digits.
  func isASCIIWord(at index: Int, length: Int) -> Bool {
    element(at: index - 1)?.isASCIIWordCharacter != true
      && element(at: index + length)?.isASCIIWordCharacter != true
  }
}
