/// Reasons `HotkeyMonitor.start()` can fail.
public enum HotkeyError: Error, Sendable {
  /// Input Monitoring has not been granted in System Settings.
  case inputMonitoringDenied
  /// The system refused to create the event tap.
  case tapCreationFailed
  /// `start()` was called on a monitor that is already running.
  case alreadyRunning
}
