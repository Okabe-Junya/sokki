import HotkeyKit

/// Everything in `config.json`. A missing key takes the default below, so the
/// file only needs to contain what differs.
struct Config: Codable, Equatable, Sendable {
  static let supportedLocales = ["ja-JP", "en-US"]
  static let `default` = Self()

  var hotkey = Hotkey.default
  var locale = "ja-JP"
  var launchAtLogin = false

  init() {}

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    hotkey = try container.decodeIfPresent(Hotkey.self, forKey: .hotkey) ?? Self.default.hotkey
    locale = try container.decodeIfPresent(String.self, forKey: .locale) ?? Self.default.locale
    launchAtLogin =
      try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? Self.default.launchAtLogin
  }
}

extension HotkeyKey {
  var displayName: String {
    switch self {
    case .leftControl: "Left ⌃"
    case .rightControl: "Right ⌃"
    case .leftOption: "Left ⌥"
    case .rightOption: "Right ⌥"
    case .leftShift: "Left ⇧"
    case .rightShift: "Right ⇧"
    case .leftCommand: "Left ⌘"
    case .rightCommand: "Right ⌘"
    case .fn: "fn / Globe"
    }
  }
}

extension Hotkey {
  /// The single-key choices offered before chords could be recorded.
  static let presets: [Self] = [.rightOption, .leftOption, .rightCommand, .fn].map(Self.init)

  var displayName: String {
    keys.map(\.displayName).joined(separator: " + ")
  }
}
