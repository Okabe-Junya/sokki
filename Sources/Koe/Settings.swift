import Foundation
import HotkeyKit

/// User-visible settings, persisted in `UserDefaults`.
@MainActor
final class Settings {
  private let defaults = UserDefaults.standard

  var hotkey: HotkeyKey {
    get { defaults.string(forKey: "hotkey").flatMap(HotkeyKey.init(rawValue:)) ?? .rightOption }
    set { defaults.set(newValue.rawValue, forKey: "hotkey") }
  }

  var locale: Locale {
    get { Locale(identifier: defaults.string(forKey: "locale") ?? "ja-JP") }
    set { defaults.set(newValue.identifier, forKey: "locale") }
  }

  static let supportedLocales = ["ja-JP", "en-US"].map(Locale.init(identifier:))
}
