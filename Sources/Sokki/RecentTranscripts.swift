import AppKit
import TextInsertion

/// The last few transcripts, held in memory only, and the status-menu items that copy them.
/// Nothing reaches the clipboard unless the user picks an item.
@MainActor
final class RecentTranscripts: NSObject {
  private static let capacity = 5
  private static let previewCharacters = 40

  /// Placed right under the state line; shown only while the newest transcript was not inserted.
  let copyLastItem = NSMenuItem(title: "Copy Last Transcript", action: nil, keyEquivalent: "")
  let submenuItem = NSMenuItem(title: "Copy Recent Transcript", action: nil, keyEquivalent: "")

  /// Called after a copy, so the state line can drop the notice.
  var onCopy: (() -> Void)?

  private var texts: [String] = []
  private var failure: InsertionOutcome?

  /// The state line while the newest transcript was not inserted.
  var notice: String? {
    switch failure {
    case .blockedBySecureInput: "Not inserted: secure input is on"
    case .unread: "Not inserted: nothing accepted the paste"
    case .pasted, nil: nil
    }
  }

  override init() {
    super.init()
    copyLastItem.action = #selector(copyLast)
    copyLastItem.target = self
    copyLastItem.isHidden = true
    submenuItem.submenu = NSMenu()
    rebuildSubmenu()
  }

  func add(_ text: String, outcome: InsertionOutcome) {
    texts.insert(text, at: 0)
    texts = Array(texts.prefix(Self.capacity))
    failure = outcome == .pasted ? nil : outcome
    copyLastItem.isHidden = failure == nil
    rebuildSubmenu()
  }

  func clearNotice() {
    failure = nil
    copyLastItem.isHidden = true
  }

  private func rebuildSubmenu() {
    guard let menu = submenuItem.submenu else { return }
    menu.removeAllItems()
    guard !texts.isEmpty else {
      let empty = NSMenuItem(title: "No recent transcripts", action: nil, keyEquivalent: "")
      empty.isEnabled = false
      menu.addItem(empty)
      return
    }
    for (index, text) in texts.enumerated() {
      let preview =
        text.count > Self.previewCharacters ? text.prefix(Self.previewCharacters) + "…" : text
      let item = NSMenuItem(
        title: String(preview), action: #selector(copyItem(_:)), keyEquivalent: "")
      item.target = self
      item.tag = index
      menu.addItem(item)
    }
  }

  private func copy(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    clearNotice()
    onCopy?()
  }

  @objc private func copyLast() {
    if let text = texts.first { copy(text) }
  }

  @objc private func copyItem(_ sender: NSMenuItem) {
    guard texts.indices.contains(sender.tag) else { return }
    copy(texts[sender.tag])
  }
}
