import Foundation

enum WhitespaceNormalization {
  private static let spaces: Set<Character> = [" ", "\u{3000}"]
  private static let noSpaceBefore: Set<Character> = ["、", "。", "？", "！", "」"]

  static func apply(_ text: String) -> String {
    var output: [Character] = []
    var pendingSpace = false
    for char in text.trimmingCharacters(in: .whitespacesAndNewlines) {
      if Self.spaces.contains(char) {
        pendingSpace = true
        continue
      }
      if pendingSpace, let previous = output.last, keepsSpace(between: previous, and: char) {
        output.append(" ")
      }
      pendingSpace = false
      output.append(char)
    }
    return String(output)
  }

  private static func keepsSpace(between previous: Character, and next: Character) -> Bool {
    if previous.isNewline || next.isNewline { return false }
    if previous.isCJK, next.isCJK { return false }
    return previous != "「" && !Self.noSpaceBefore.contains(next)
  }
}
