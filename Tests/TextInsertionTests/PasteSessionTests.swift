import AppKit
import Testing

@testable import TextInsertion

@MainActor
@Suite(.serialized)
struct PasteSessionTests {
  let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.okabe.koe.test"))
  let custom = NSPasteboard.PasteboardType("dev.okabe.koe.test.custom")

  private func seed() -> PasteboardSnapshot {
    let first = NSPasteboardItem()
    first.setString("first", forType: .string)
    first.setData(Data([0x01, 0x02]), forType: custom)
    let second = NSPasteboardItem()
    second.setString("second", forType: .string)
    second.setData(Data([0x03]), forType: custom)
    pasteboard.clearContents()
    pasteboard.writeObjects([first, second])
    return [
      [.string: Data("first".utf8), custom: Data([0x01, 0x02])],
      [.string: Data("second".utf8), custom: Data([0x03])],
    ]
  }

  @Test func snapshotRoundTripsThroughRestore() {
    let expected = seed()
    let snapshot = PasteboardSnapshotter.snapshot(pasteboard)
    #expect(snapshot == expected)

    pasteboard.clearContents()
    pasteboard.setString("other", forType: .string)
    PasteboardSnapshotter.restore(snapshot, to: pasteboard)

    #expect(PasteboardSnapshotter.snapshot(pasteboard) == expected)
  }

  @Test func readingPromiseRecordsReceipt() {
    let expected = seed()
    let session = PasteSession(text: "こんにちは koe", pasteboard: pasteboard)
    #expect(session.provider.receivedAt == nil)
    #expect(pasteboard.types?.contains(.transient) == true)
    #expect(pasteboard.types?.contains(.concealed) == true)

    #expect(pasteboard.string(forType: .string) == "こんにちは koe")
    #expect(session.provider.receivedAt != nil)

    #expect(session.restoreIfUnchanged())
    #expect(PasteboardSnapshotter.snapshot(pasteboard) == expected)
  }

  @Test func restoreSkippedWhenPasteboardChanged() {
    _ = seed()
    let session = PasteSession(text: "dictated", pasteboard: pasteboard)
    pasteboard.clearContents()
    pasteboard.setString("user copy", forType: .string)

    #expect(!session.restoreIfUnchanged())
    #expect(pasteboard.string(forType: .string) == "user copy")
  }

  @Test func finishRestoresAfterReceipt() async {
    let expected = seed()
    let session = PasteSession(text: "dictated", pasteboard: pasteboard)
    let postedAt = ContinuousClock.now
    _ = pasteboard.string(forType: .string)

    await session.finish(postedAt: postedAt, receiptTimeout: .milliseconds(200))

    #expect(PasteboardSnapshotter.snapshot(pasteboard) == expected)
  }
}
