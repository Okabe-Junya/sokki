import HotkeyKit

/// Everything in `config.json`. A missing key takes the default below, so the
/// file only needs to contain what differs.
struct Config: Codable, Equatable, Sendable {
  static let supportedLocales = ["ja-JP", "en-US"]
  static let `default` = Self()

  var hotkey: HotkeyKey = .rightOption
  var locale = "ja-JP"
  var launchAtLogin = false

  init() {}

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    hotkey = try container.decodeIfPresent(HotkeyKey.self, forKey: .hotkey) ?? Self.default.hotkey
    locale = try container.decodeIfPresent(String.self, forKey: .locale) ?? Self.default.locale
    launchAtLogin =
      try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? Self.default.launchAtLogin
  }
}

extension HotkeyKey {
  var displayName: String {
    switch self {
    case .rightOption: "Right Option (⌥)"
    case .leftOption: "Left Option (⌥)"
    case .rightCommand: "Right Command (⌘)"
    case .fn: "fn / Globe"
    }
  }
}
