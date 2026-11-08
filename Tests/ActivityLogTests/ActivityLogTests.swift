import Foundation
import Testing

@testable import ActivityLog

struct ActivityLogTests {
  private struct Entry: Codable, Equatable {
    let index: Int
    let note: String
  }

  private static func temporaryFile() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "sokki-\(UUID().uuidString)")
      .appending(path: "activity.jsonl")
  }

  private static func lines(of file: URL) throws -> [Entry] {
    try String(contentsOf: file, encoding: .utf8)
      .split(separator: "\n")
      .map { try JSONDecoder().decode(Entry.self, from: Data($0.utf8)) }
  }

  @Test func appendsOneObjectPerLineAndCreatesTheDirectory() async throws {
    let log = ActivityLog(file: Self.temporaryFile())
    try await log.append(Entry(index: 0, note: "a/b"))
    try await log.append(Entry(index: 1, note: "c"))
    #expect(
      try Self.lines(of: log.file) == [Entry(index: 0, note: "a/b"), Entry(index: 1, note: "c")])
  }

  @Test func previousFileKeepsTheExtension() {
    let log = ActivityLog(file: URL(filePath: "/tmp/sokki/activity.jsonl"))
    #expect(log.previousFile.lastPathComponent == "activity.1.jsonl")
  }

  @Test func rotationKeepsTwoGenerationsWithinTheBound() async throws {
    let maxBytes = 200
    let log = ActivityLog(file: Self.temporaryFile(), maxBytes: maxBytes)
    for index in 0..<50 {
      try await log.append(Entry(index: index, note: "padding"))
    }
    let manager = FileManager.default
    let directory = log.file.deletingLastPathComponent()
    let names = try manager.contentsOfDirectory(atPath: directory.path).sorted()
    #expect(names == ["activity.1.jsonl", "activity.jsonl"])
    for file in [log.file, log.previousFile] {
      let size = try #require(try manager.attributesOfItem(atPath: file.path)[.size] as? Int)
      #expect(size <= maxBytes)
    }
    let kept = try Self.lines(of: log.previousFile) + Self.lines(of: log.file)
    #expect(kept.map(\.index) == Array((50 - kept.count)..<50))
  }

  @Test func oversizedLineIsStillWrittenToAnEmptyFile() async throws {
    let log = ActivityLog(file: Self.temporaryFile(), maxBytes: 10)
    try await log.append(Entry(index: 0, note: "longer than ten bytes"))
    #expect(try Self.lines(of: log.file).count == 1)
    #expect(!FileManager.default.fileExists(atPath: log.previousFile.path))
  }
}
