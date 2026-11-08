import AppKit
import SwiftUI

/// Shows the permission checklist, polls the three TCC states while visible
/// (there is no change notification for them), and closes itself when all
/// are granted.
@MainActor
final class PermissionsWindowController {
  private static let pollIntervalSeconds: TimeInterval = 1

  private let model = PermissionsModel()
  private var window: NSWindow?
  private var timer: Timer?
  private var closesWhenGranted = false

  /// Called on every poll with whether every permission is granted.
  var onChange: ((Bool) -> Void)?

  // Gatekeeper translocates a quarantined app launched outside /Applications,
  // which changes its path on every launch.
  private static func locationWarning() -> String? {
    let path = Bundle.main.bundlePath
    guard !path.hasPrefix("/Applications/"),
      getxattr(path, "com.apple.quarantine", nil, 0, 0, 0) >= 0
    else { return nil }
    return "Sokki is running from \(path). Move it to /Applications first."
  }

  func show() {
    model.refresh()
    // Opened from the menu with everything granted, the window should stay.
    closesWhenGranted = !model.allGranted
    if window == nil {
      let hosting = NSHostingController(
        rootView: PermissionsView(model: model, locationWarning: Self.locationWarning()))
      let panel = NSWindow(contentViewController: hosting)
      panel.title = "Permissions"
      panel.styleMask = [.titled, .closable]
      panel.isReleasedWhenClosed = false
      panel.center()
      window = panel
    }
    NSApp.activate()
    window?.makeKeyAndOrderFront(nil)
    startPolling()
  }

  func close() {
    stopPolling()
    window?.orderOut(nil)
  }

  private func startPolling() {
    guard timer == nil else { return }
    let interval = Self.pollIntervalSeconds
    timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.poll() }
    }
  }

  private func stopPolling() {
    timer?.invalidate()
    timer = nil
  }

  private func poll() {
    guard let window, window.isVisible else {
      stopPolling()
      return
    }
    model.refresh()
    onChange?(model.allGranted)
    if model.allGranted, closesWhenGranted { close() }
  }
}
