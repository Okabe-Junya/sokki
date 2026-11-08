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
  /// Escape went down. Reported whether or not the key is held, so a
  /// hands-free session (no key held) can be discarded too; the session
  /// ignores it while idle.
  case escape
}
