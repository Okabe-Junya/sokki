import AppKit

/// Supplies the text lazily so the target app's read doubles as a receipt.
@MainActor
final class PromiseProvider: NSObject {
  let text: String
  private(set) var receivedAt: ContinuousClock.Instant?

  init(text: String) {
    self.text = text
  }
}

extension PromiseProvider: @MainActor NSPasteboardTypeOwner {
  func pasteboard(_ sender: NSPasteboard, provideDataForType type: NSPasteboard.PasteboardType) {
    guard type == .string else { return }
    if receivedAt == nil { receivedAt = .now }
    sender.setString(text, forType: .string)
  }
}
