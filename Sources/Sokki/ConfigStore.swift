import Foundation
import Observation
import os

/// `config.json` is the single source of settings. The store reads it, watches
/// its directory for edits (editors save by rename, so the file itself cannot
/// be watched), and writes it back with sorted keys when the UI changes a value.
@MainActor @Observable
final class ConfigStore {
  private static let reloadDebounceMilliseconds = 200
  private static let logger = Logger(subsystem: "dev.junya.sokki", category: "config")

  let directory: URL
  let file: URL
  private(set) var config = Config.default
  /// Set when `config.json` exists but could not be applied; the previous values stay in effect.
  private(set) var problem: String?
  /// Called with (previous, current) after a change from the file or the UI.
  @ObservationIgnored var onChange: ((Config, Config) -> Void)?

  @ObservationIgnored private var directorySource: (any DispatchSourceFileSystemObject)?
  @ObservationIgnored private var fileSource: (any DispatchSourceFileSystemObject)?
  @ObservationIgnored private var pendingReload: Task<Void, Never>?

  init(directory: URL) {
    self.directory = directory
    file = directory.appending(path: "config.json")
  }

  private static func encode(_ config: Config) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(config)
    data.append(UInt8(ascii: "\n"))
    return data
  }

  func start() {
    load()
    watchDirectory()
  }

  func update(_ change: (inout Config) -> Void) {
    var next = config
    change(&next)
    guard next != config else { return }
    do {
      try write(next)
      problem = nil
      apply(next)
    } catch {
      problem = "could not write \(file.path): \(error.localizedDescription)"
      Self.logger.error("\(self.problem ?? "", privacy: .public)")
    }
  }

  /// Writes the current values if the file does not exist yet, so "Open Config File" has something to open.
  func ensureFileExists() throws {
    guard !FileManager.default.fileExists(atPath: file.path) else { return }
    try write(config)
  }

  /// The built-in defaults as a read-only file, generated from `Config.default` so it cannot drift.
  func defaultsFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "sokki-defaults.json")
    try Self.encode(.default).write(to: url, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: url.path)
    return url
  }

  private func write(_ next: Config) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Self.encode(next).write(to: file, options: .atomic)
  }

  private func load() {
    defer { watchFile() }
    guard FileManager.default.fileExists(atPath: file.path) else {
      problem = nil
      apply(.default)
      return
    }
    do {
      let next = try JSONDecoder().decode(Config.self, from: Data(contentsOf: file))
      problem = nil
      apply(next)
    } catch {
      problem = "config.json not applied: \(error)"
      Self.logger.error("\(self.problem ?? "", privacy: .public)")
    }
  }

  private func apply(_ next: Config) {
    let previous = config
    config = next
    if previous != next { onChange?(previous, next) }
  }

  // Editors that save atomically replace the file (a directory event, new inode);
  // `echo >` and some editors write in place (a file event only). Both are watched,
  // and the file watcher is re-armed after every load because the inode may have changed.
  private func watchDirectory() {
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    directorySource = makeSource(path: directory.path, events: [.write, .rename, .delete])
  }

  private func watchFile() {
    fileSource?.cancel()
    fileSource = makeSource(path: file.path, events: [.write, .extend, .attrib, .rename, .delete])
  }

  private func makeSource(path: String, events: DispatchSource.FileSystemEvent)
    -> (any DispatchSourceFileSystemObject)?
  {
    let descriptor = open(path, O_EVTONLY)
    guard descriptor >= 0 else { return nil }
    let watcher = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: descriptor, eventMask: events, queue: .main)
    watcher.setEventHandler { [weak self] in
      MainActor.assumeIsolated { self?.scheduleReload() }
    }
    watcher.setCancelHandler { close(descriptor) }
    watcher.resume()
    return watcher
  }

  private func scheduleReload() {
    pendingReload?.cancel()
    pendingReload = Task {
      try? await Task.sleep(for: .milliseconds(Self.reloadDebounceMilliseconds))
      if !Task.isCancelled { load() }
    }
  }
}
