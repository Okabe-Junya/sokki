extension PersonalDictionary {
  /// Why `dictionary.json` could not be loaded at all.
  public enum ParseError: Error, Equatable, CustomStringConvertible {
    /// The data is not valid JSON; carries the parser's message.
    case malformedJSON(String)
    /// The JSON root is not an object.
    case notAnObject
    /// The value for `replacement` is not an array of strings.
    case notAStringArray(replacement: String)

    public var description: String {
      switch self {
      case .malformedJSON(let message):
        "dictionary.json is not valid JSON: \(message)"
      case .notAnObject:
        "dictionary.json must be a JSON object mapping each replacement to its spoken forms."
      case .notAStringArray(let replacement):
        "The value for \"\(replacement)\" must be an array of strings."
      }
    }
  }
}
