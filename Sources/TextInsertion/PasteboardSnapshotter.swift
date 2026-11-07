import AppKit

typealias PasteboardSnapshot = [[NSPasteboard.PasteboardType: Data]]

@MainActor
enum PasteboardSnapshotter {
  static func snapshot(_ pasteboard: NSPasteboard) -> PasteboardSnapshot {
    (pasteboard.pasteboardItems ?? []).map { item in
      var entry: [NSPasteboard.PasteboardType: Data] = [:]
      for type in item.types {
        if let data = item.data(forType: type) { entry[type] = data }
      }
      return entry
    }
  }

  static func restore(_ snapshot: PasteboardSnapshot, to pasteboard: NSPasteboard) {
    pasteboard.clearContents()
    let items = snapshot.map { entry in
      let item = NSPasteboardItem()
      for (type, data) in entry { item.setData(data, forType: type) }
      return item
    }
    if !items.isEmpty { pasteboard.writeObjects(items) }
  }
}
