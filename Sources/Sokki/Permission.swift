import AudioCapture
import Foundation
import HotkeyKit
import TextInsertion

/// The three TCC permissions the app needs, with the System Settings pane for each.
enum Permission: String, CaseIterable {
  case microphone = "microphone"
  case inputMonitoring = "inputMonitoring"
  case accessibility = "accessibility"

  static var missing: [Self] {
    Self.allCases.filter { !$0.isGranted }
  }

  var title: String {
    switch self {
    case .microphone: "Microphone"
    case .inputMonitoring: "Input Monitoring"
    case .accessibility: "Accessibility"
    }
  }

  /// One line, shown next to the checkbox, saying what the permission is used for.
  var reason: String {
    switch self {
    case .microphone: "Records your voice only while the hotkey is held."
    case .inputMonitoring: "Notices the hotkey going down and up in any app."
    case .accessibility: "Presses ⌘V in the frontmost app to insert the text."
    }
  }

  var isGranted: Bool {
    switch self {
    case .microphone: AudioRecorder.hasMicrophoneAccess()
    case .inputMonitoring: HotkeyMonitor.hasInputMonitoringAccess()
    case .accessibility: TextInserter.hasAccessibilityAccess()
    }
  }

  var settingsURL: URL {
    let pane: String
    switch self {
    case .microphone: pane = "Privacy_Microphone"
    case .inputMonitoring: pane = "Privacy_ListenEvent"
    case .accessibility: pane = "Privacy_Accessibility"
    }
    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")
    else { fatalError("invalid System Settings URL for pane \(pane)") }
    return url
  }
}
