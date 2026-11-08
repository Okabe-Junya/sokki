import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
  private let store: ConfigStore
  private let actions: SettingsActions
  private var window: NSWindow?

  init(store: ConfigStore, actions: SettingsActions) {
    self.store = store
    self.actions = actions
  }

  func show() {
    if window == nil {
      let hosting = NSHostingController(rootView: SettingsView(store: store, actions: actions))
      let panel = NSWindow(contentViewController: hosting)
      panel.title = "Settings"
      panel.styleMask = [.titled, .closable]
      panel.isReleasedWhenClosed = false
      panel.center()
      window = panel
    }
    NSApp.activate()
    window?.makeKeyAndOrderFront(nil)
  }
}
