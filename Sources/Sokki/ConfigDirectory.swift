import Foundation

/// `$XDG_CONFIG_HOME/sokki`, by default `~/.config/sokki`. The only place the
/// app keeps user-editable files.
enum ConfigDirectory {
  static var url: URL {
    let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? ""
    let base =
      xdg.isEmpty
      ? FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config")
      : URL(fileURLWithPath: xdg, isDirectory: true)
    return base.appending(path: "sokki", directoryHint: .isDirectory)
  }

  static var dictionaryFile: URL {
    url.appending(path: "dictionary.json")
  }
}
