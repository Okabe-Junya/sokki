import AudioCapture
import Foundation
import HotkeyKit
import TextInsertion

/// The three TCC permissions the app needs, with the System Settings pane for each.
enum Permission: String, CaseIterable {
  case microphone = "microphone"
  case inputMonitoring = "inputMonitoring"
  case accessibility = "accessibility"

  var title: String {
    switch self {
    case .microphone: "Microphone"
    case .inputMonitoring: "Input Monitoring"
    case .accessibility: "Accessibility"
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
