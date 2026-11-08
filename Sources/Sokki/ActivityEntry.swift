import Foundation
import HotkeyKit

/// One line of `~/Library/Logs/Sokki/activity.jsonl`: an utterance report plus
/// the settings it ran under.
struct ActivityEntry: Encodable, Sendable {
  static var file: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appending(path: "Library/Logs/Sokki/activity.jsonl")
  }

  static let version =
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"

  let time: Date
  let version: String
  let hotkey: Hotkey
  let locale: String
  let utterance: UtteranceReport

  init(hotkey: Hotkey, locale: String, utterance: UtteranceReport) {
    time = Date()
    version = Self.version
    self.hotkey = hotkey
    self.locale = locale
    self.utterance = utterance
  }
}
