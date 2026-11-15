/// A non-empty set of modifier keys held together, written in JSON as key names
/// joined by `+` (`"leftControl+leftOption"`); a single name is a chord of one key.
public struct Hotkey: Sendable, Hashable, Codable {
  public static let `default` = Self(.rightOption)

  /// The keys in canonical order (⌃ ⌥ ⇧ ⌘ fn, left before right).
  public let keys: [HotkeyKey]

  /// Whether the recorder accepts this chord: Shift alone is held while typing capitals.
  public var isRecordable: Bool {
    !keys.allSatisfy(\.isShift)
  }

  /// The form stored in `config.json`.
  public var name: String {
    keys.map(\.rawValue).joined(separator: "+")
  }

  public init(_ key: HotkeyKey) {
    keys = [key]
  }

  /// Returns nil for an empty set.
  public init?(keys: some Sequence<HotkeyKey>) {
    let sorted = Set(keys).sorted()
    guard !sorted.isEmpty else { return nil }
    self.keys = sorted
  }

  /// Returns nil for an empty string or an unknown key name.
  public init?(name: String) {
    var parsed: [HotkeyKey] = []
    for part in name.split(separator: "+", omittingEmptySubsequences: false) {
      guard let key = HotkeyKey(rawValue: String(part)) else { return nil }
      parsed.append(key)
    }
    self.init(keys: parsed)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let stored = try container.decode(String.self)
    guard let hotkey = Self(name: stored) else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "unknown hotkey \"\(stored)\"")
    }
    self = hotkey
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(name)
  }
}
