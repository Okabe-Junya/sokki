/// Keys that can drive push-to-talk. All are modifier keys (or fn), so they
/// keep working while secure input is active: the system withholds keyDown /
/// keyUp from event taps then, but still delivers flagsChanged.
public enum HotkeyKey: String, Sendable, Codable, CaseIterable {
  case rightOption
  case leftOption
  case rightCommand
  case fn
}

/// Semantic events the hotkey state machine emits. Raw key edges stay inside
/// `HotkeyMonitor`; the session only sees intent.
public enum HotkeyEvent: Sendable, Equatable {
  /// Key went down. Recording should start immediately so the first
  /// syllable is not lost; a `.cancelled` may follow if the press was short.
  case pressed
  /// Key came up after being held at least `minimumHold`.
  case released(heldFor: Duration)
  /// Key came up before `minimumHold` elapsed (an accidental tap or a
  /// modifier-click). The press is to be discarded.
  case cancelled
  /// Two short presses within `doubleTapWindow` with no other key between.
  case doubleTapped
  /// Escape pressed while the key was held.
  case escape
}

public enum HotkeyError: Error, Sendable {
  case inputMonitoringDenied
  case tapCreationFailed
  case alreadyRunning
}
