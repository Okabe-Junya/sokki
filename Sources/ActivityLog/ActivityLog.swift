import Foundation

/// Appends one JSON object per line to `file`, bounded to two generations:
/// once the next line would push `file` past `maxBytes`, it is renamed to
/// `previousFile` (replacing the older one) and a fresh file starts.
public actor ActivityLog {
  /// About 1 MB per generation.
  public static let defaultMaxBytes = 1_000_000

  /// The file lines are appended to.
  nonisolated public let file: URL
  /// The size `file` may reach before it rotates.
  nonisolated public let maxBytes: Int
  private let encoder: JSONEncoder

  /// `activity.jsonl` → `activity.1.jsonl`.
  nonisolated public var previousFile: URL {
    file.deletingPathExtension()
      .appendingPathExtension("1")
      .appendingPathExtension(file.pathExtension)
  }

  /// Creates a log at `file`; nothing is written until the first `append`.
  public init(file: URL, maxBytes: Int = defaultMaxBytes) {
    self.file = file
    self.maxBytes = maxBytes
    encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
  }

  /// Encodes `entry` as one line, rotating first if the line would not fit.
  public func append(_ entry: some Encodable & Sendable) throws {
    var line = try encoder.encode(entry)
    line.append(UInt8(ascii: "\n"))
    let manager = FileManager.default
    try manager.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    let size = (try? manager.attributesOfItem(atPath: file.path)[.size] as? Int) ?? 0
    if size > 0, size + line.count > maxBytes {
      try? manager.removeItem(at: previousFile)
      try manager.moveItem(at: file, to: previousFile)
    }
    if !manager.fileExists(atPath: file.path) {
      manager.createFile(atPath: file.path, contents: nil)
    }
    let handle = try FileHandle(forWritingTo: file)
    defer { try? handle.close() }
    try handle.seekToEnd()
    try handle.write(contentsOf: line)
  }
}
