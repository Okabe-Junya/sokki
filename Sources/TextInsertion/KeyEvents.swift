import Carbon.HIToolbox
import CoreGraphics

enum KeyEvents {
  private static let vKey = CGKeyCode(kVK_ANSI_V)
  private static let modifierReleaseTimeoutMilliseconds = 500
  private static let modifierPollIntervalMilliseconds = 10
  private static let keyDownHoldMilliseconds = 5
  private static let heldModifiers: CGEventFlags = [
    .maskCommand, .maskAlternate, .maskControl, .maskShift, .maskSecondaryFn,
  ]

  /// A push-to-talk modifier still down would turn ⌘V into e.g. ⌘⌥V.
  static func waitForModifierRelease(
    timeout: Duration = .milliseconds(modifierReleaseTimeoutMilliseconds)
  ) async throws {
    let deadline = ContinuousClock.now + timeout
    while !CGEventSource.flagsState(.combinedSessionState).isDisjoint(with: heldModifiers) {
      guard ContinuousClock.now < deadline else { throw InsertionError.modifierStillHeld }
      try? await Task.sleep(for: .milliseconds(modifierPollIntervalMilliseconds))
    }
  }

  /// Returns when ⌘V-down was posted, the reference point for receipt latency.
  static func postCommandV() async throws -> ContinuousClock.Instant {
    let source = CGEventSource(stateID: .privateState)
    guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
    else { throw InsertionError.eventPostFailed }
    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand
    let postedAt = ContinuousClock.now
    keyDown.post(tap: .cghidEventTap)
    try? await Task.sleep(for: .milliseconds(keyDownHoldMilliseconds))
    keyUp.post(tap: .cghidEventTap)
    return postedAt
  }
}
