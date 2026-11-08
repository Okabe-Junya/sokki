extension PersonalDictionary {
  struct Builder {
    private(set) var entries: [Entry] = []
    private(set) var warnings: [Warning] = []
    private var owners: [String: String] = [:]
    private let replacementKeys: Set<String>

    init(replacements: Set<String>) {
      replacementKeys = Set(replacements.map(PersonalDictionary.matchKey))
    }

    private static func isBlank(_ text: String) -> Bool {
      text.allSatisfy(\.isWhitespace)
    }

    mutating func add(_ replacement: String, spokenForms: [String]) {
      guard !Self.isBlank(replacement) else {
        warnings.append(.emptyReplacement)
        return
      }
      for form in spokenForms {
        add(form, for: replacement)
      }
    }

    private mutating func add(_ form: String, for replacement: String) {
      if Self.isBlank(form) {
        warnings.append(.emptySpokenForm(replacement: replacement))
        return
      }
      if form == replacement {
        warnings.append(.spokenFormIsReplacement(replacement))
        return
      }
      let key = PersonalDictionary.matchKey(form)
      if let owner = owners[key] {
        if owner != replacement {
          warnings.append(.duplicateSpokenForm(form, kept: owner, ignored: replacement))
        }
        return
      }
      if replacementKeys.contains(key), key != PersonalDictionary.matchKey(replacement) {
        warnings.append(.chainedSpokenForm(form, replacement: replacement))
      }
      owners[key] = replacement
      entries.append(Entry(spokenForm: form, replacement: replacement))
    }
  }
}
