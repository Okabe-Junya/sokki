import Foundation

/// User-defined replacements for words the recognizer gets wrong, loaded from
/// a JSON object such as `{"Kubernetes": ["クバネティス"], "PR": ["プルリク"]}`:
/// each key is the replacement text, each value lists its spoken forms.
public struct PersonalDictionary: Sendable, Equatable {
  struct Entry: Sendable, Equatable {
    let key: String
    let length: Int
    let ignoresCase: Bool
    let replacement: String

    init(spokenForm: String, replacement: String) {
      key = PersonalDictionary.matchKey(spokenForm)
      length = spokenForm.count
      ignoresCase = !spokenForm.contains(where: \.isCJK)
      self.replacement = replacement
    }

    func matches(_ chars: [Character], at index: Int) -> Bool {
      if ignoresCase {
        return chars.isASCIIWord(at: index, length: length)
          && chars.hasPhrase(key, at: index, ignoringCase: true)
      }
      return chars.hasPhrase(key, at: index)
    }
  }

  /// A dictionary that changes nothing.
  public static let empty = Self(entries: [])

  /// Longest spoken form first, so that プルリクエスト wins over プルリク.
  let entries: [Entry]

  init(entries: [Entry]) {
    self.entries = entries.sorted { lhs, rhs in
      lhs.length != rhs.length
        ? lhs.length > rhs.length : (lhs.key, lhs.replacement) < (rhs.key, rhs.replacement)
    }
  }

  /// Parses `dictionary.json`. Entries that cannot be applied are skipped and
  /// reported as warnings; keys are processed in sorted order, so the first
  /// key in that order wins a contested spoken form.
  /// - Throws: `ParseError` when the data is not a JSON object of string arrays.
  public static func parse(_ data: Data) throws -> (
    dictionary: Self, warnings: [Warning]
  ) {
    let root: Any
    do {
      root = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    } catch {
      throw ParseError.malformedJSON(error.localizedDescription)
    }
    guard let object = root as? [String: Any] else { throw ParseError.notAnObject }
    var builder = Builder(replacements: Set(object.keys))
    for replacement in object.keys.sorted() {
      guard let forms = object[replacement] as? [String] else {
        throw ParseError.notAStringArray(replacement: replacement)
      }
      builder.add(replacement, spokenForms: forms)
    }
    return (Self(entries: builder.entries), builder.warnings)
  }

  /// Latin forms compare case-insensitively; anything containing CJK compares exactly.
  static func matchKey(_ form: String) -> String {
    form.contains(where: \.isCJK) ? form : form.lowercased()
  }

  /// Replaces every spoken form with its replacement in one left-to-right
  /// pass. Inserted replacements are never re-scanned, so A → B, B → C turns
  /// A into B.
  public func apply(to text: String) -> String {
    guard !entries.isEmpty else { return text }
    let chars = Array(text)
    var output = ""
    var index = 0
    while index < chars.count {
      if let entry = entries.first(where: { $0.matches(chars, at: index) }) {
        output += entry.replacement
        index += entry.length
      } else {
        output.append(chars[index])
        index += 1
      }
    }
    return output
  }
}
