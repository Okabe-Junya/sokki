extension PersonalDictionary {
  /// A problem in `dictionary.json` that did not stop it from loading.
  public enum Warning: Sendable, Equatable, CustomStringConvertible {
    /// An entry with an empty replacement was skipped.
    case emptyReplacement
    /// An empty spoken form under `replacement` was skipped.
    case emptySpokenForm(replacement: String)
    /// A spoken form identical to its own replacement was skipped.
    case spokenFormIsReplacement(String)
    /// A spoken form listed under two replacements; only `kept` applies.
    case duplicateSpokenForm(String, kept: String, ignored: String)
    /// A spoken form that is also another entry's replacement. It is kept,
    /// but replacements are never re-scanned, so the chain stops after one step.
    case chainedSpokenForm(String, replacement: String)

    public var description: String {
      switch self {
      case .emptyReplacement:
        "An entry with an empty replacement was skipped."
      case .emptySpokenForm(let replacement):
        "An empty spoken form for \"\(replacement)\" was skipped."
      case .spokenFormIsReplacement(let replacement):
        "\"\(replacement)\" lists itself as a spoken form; skipped."
      case .duplicateSpokenForm(let form, let kept, let ignored):
        "\"\(form)\" is listed for both \"\(kept)\" and \"\(ignored)\"; using \"\(kept)\"."
      case .chainedSpokenForm(let form, let replacement):
        "\"\(form)\" (for \"\(replacement)\") is also a replacement; it is not replaced again."
      }
    }
  }
}
