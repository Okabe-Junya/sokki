enum FillerRemoval {
  /// Longest first so that えーと wins over えー and あのー over あの.
  private static let japanese = [
    "えーと", "ええと", "あのー", "うーん", "えっと", "なんか", "えー", "あの", "その", "まあ",
  ]
  /// These also work as ordinary words, so they count as fillers only before 、.
  private static let japaneseBeforeCommaOnly: Set<String> = ["その", "まあ"]
  private static let japaneseBoundaries: Set<Character> = ["、", "。", " "]
  private static let english = ["uhm", "erm", "um", "uh"]
  /// Ordinary words too, so they count as fillers only as `, like,`.
  private static let englishBetweenCommas = ["you know", "like"]
  private static let commaSpace: [Character] = [",", " "]

  static func apply(_ text: String) -> String {
    let chars = Array(text)
    var output: [Character] = []
    var index = 0
    while index < chars.count {
      if let end = japaneseFillerEnd(in: chars, at: index, after: output.last) {
        index = consumeAfterJapanese(chars, from: end, into: &output)
      } else if let end = englishFillerEnd(in: chars, at: index, after: output) {
        index = consumeAfterEnglish(chars, from: end, into: &output)
      } else {
        output.append(chars[index])
        index += 1
      }
    }
    return String(output)
  }

  private static func japaneseFillerEnd(
    in chars: [Character], at index: Int, after previous: Character?
  ) -> Int? {
    if let previous, !Self.japaneseBoundaries.contains(previous) { return nil }
    for filler in Self.japanese where chars.hasPhrase(filler, at: index) {
      let end = index + filler.count
      let next = chars.element(at: end)
      let accepted =
        Self.japaneseBeforeCommaOnly.contains(filler)
        ? next == "、" : next.map(Self.japaneseBoundaries.contains) ?? true
      if accepted { return end }
    }
    return nil
  }

  private static func consumeAfterJapanese(
    _ chars: [Character], from end: Int, into output: inout [Character]
  ) -> Int {
    let next = chars.element(at: end)
    if next == "、" || next == " " { return end + 1 }
    if output.last == "、" { output.removeLast() }
    if next == "。", output.last.map({ $0 == "。" }) ?? true { return end + 1 }
    return end
  }

  private static func englishFillerEnd(
    in chars: [Character], at index: Int, after output: [Character]
  ) -> Int? {
    for filler in Self.english
    where chars.hasPhrase(filler, at: index, ignoringCase: true)
      && chars.isASCIIWord(at: index, length: filler.count)
    {
      return index + filler.count
    }
    let previous = output.last { $0 != " " }
    for filler in Self.englishBetweenCommas
    where previous == "," && chars.hasPhrase(filler, at: index, ignoringCase: true)
      && chars.element(at: index + filler.count) == ","
    {
      return index + filler.count
    }
    return nil
  }

  private static func consumeAfterEnglish(
    _ chars: [Character], from end: Int, into output: inout [Character]
  ) -> Int {
    var index = end
    if chars.element(at: index) == "," {
      index += 1
    } else if output.suffix(Self.commaSpace.count) == Self.commaSpace {
      output.removeLast(Self.commaSpace.count)
      output.append(" ")
    }
    if chars.element(at: index) == " " {
      index += 1
    } else if output.last == " " {
      output.removeLast()
    }
    return index
  }
}
