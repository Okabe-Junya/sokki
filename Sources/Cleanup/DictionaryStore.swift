import Foundation
import os

/// Loads a `dictionary.json` and re-reads it when its modification date
/// changes, so an edit applies to the next utterance without a restart.
public actor DictionaryStore {
  private static let template = """
    {
      "GitHub": ["ギットハブ"]
    }

    """

  /// The `dictionary.json` this store watches.
  public let file: URL
  private let logger = Logger(subsystem: "dev.junya.sokki", category: "dictionary")
  private var loaded = PersonalDictionary.empty
  private var loadedAt: Date?

  /// Creates a store for `file`; nothing is read until `current()` is called.
  public init(file: URL) {
    self.file = file
  }

  /// Creates the file with an example entry if it does not exist yet.
  nonisolated public func ensureExists() throws {
    let manager = FileManager.default
    guard !manager.fileExists(atPath: file.path) else { return }
    try manager.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Self.template.write(to: file, atomically: true, encoding: .utf8)
  }

  /// The dictionary as of the file's current contents; unparseable contents
  /// keep the last good dictionary, a missing file yields `.empty`.
  public func current() -> PersonalDictionary {
    guard let modified = modificationDate() else {
      if loadedAt != nil { logger.info("dictionary removed; using none") }
      loaded = .empty
      loadedAt = nil
      return loaded
    }
    if modified != loadedAt { reload(modified: modified) }
    return loaded
  }

  private func modificationDate() -> Date? {
    try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
  }

  private func reload(modified: Date) {
    do {
      let (dictionary, warnings) = try PersonalDictionary.parse(try Data(contentsOf: file))
      for warning in warnings {
        logger.warning("dictionary: \(warning.description)")
      }
      loaded = dictionary
      loadedAt = modified
      logger.info("dictionary loaded from \(self.file.path), \(warnings.count) warnings")
    } catch {
      // Keep the last good dictionary; a half-saved file should not drop every term.
      logger.error("dictionary not loaded, keeping previous: \(error)")
      loadedAt = modified
    }
  }
}
