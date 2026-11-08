import Foundation
import Testing

@testable import Cleanup

struct DictionaryStoreTests {
  private static func temporaryFile() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "sokki-\(UUID().uuidString)")
      .appending(path: "dictionary.json")
  }

  private static func write(_ json: String, to file: URL, modified: Date) throws {
    try json.write(to: file, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: file.path)
  }

  @Test func missingFileIsEmptyAndEnsureExistsCreatesTemplate() async throws {
    let file = Self.temporaryFile()
    let store = DictionaryStore(file: file)
    #expect(await store.current() == .empty)
    try store.ensureExists()
    #expect(await store.current().apply(to: "ギットハブ") == "GitHub")
  }

  @Test func reloadsWhenModificationDateChanges() async throws {
    let file = Self.temporaryFile()
    try FileManager.default.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    let first = Date(timeIntervalSince1970: 1_000)
    try Self.write(#"{"PR": ["プルリク"]}"#, to: file, modified: first)
    let store = DictionaryStore(file: file)
    #expect(await store.current().apply(to: "プルリク") == "PR")

    try Self.write(#"{"Kubernetes": ["クバネティス"]}"#, to: file, modified: first + 60)
    let reloaded = await store.current()
    #expect(reloaded.apply(to: "クバネティス") == "Kubernetes")
    #expect(reloaded.apply(to: "プルリク") == "プルリク")
  }

  @Test func malformedFileKeepsPreviousDictionary() async throws {
    let file = Self.temporaryFile()
    try FileManager.default.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    let first = Date(timeIntervalSince1970: 1_000)
    try Self.write(#"{"PR": ["プルリク"]}"#, to: file, modified: first)
    let store = DictionaryStore(file: file)
    _ = await store.current()

    try Self.write("{ not json", to: file, modified: first + 60)
    #expect(await store.current().apply(to: "プルリク") == "PR")
  }
}
