import ApplicationServices
import Carbon.HIToolbox

enum SecureInput {
  static func isActive() -> Bool {
    if IsSecureEventInputEnabled() { return true }
    return focusedElementIsSecureTextField()
  }

  private static func focusedElementIsSecureTextField() -> Bool {
    let systemWide = AXUIElementCreateSystemWide()
    var focused: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        == .success,
      let focused, CFGetTypeID(focused) == AXUIElementGetTypeID()
    else { return false }
    var subrole: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(
        focused as! AXUIElement, kAXSubroleAttribute as CFString, &subrole) == .success
    else { return false }
    return (subrole as? String) == kAXSecureTextFieldSubrole
  }
}

enum KeyEvents {
  private static let vKey: CGKeyCode = 0x09
  private static let heldModifiers: CGEventFlags = [
    .maskCommand, .maskAlternate, .maskControl, .maskShift, .maskSecondaryFn,
  ]

  /// A push-to-talk modifier still down would turn ⌘V into e.g. ⌘⌥V.
  static func waitForModifierRelease(timeout: Duration = .milliseconds(500)) async throws {
    let deadline = ContinuousClock.now + timeout
    while !CGEventSource.flagsState(.combinedSessionState).intersection(heldModifiers).isEmpty {
      guard ContinuousClock.now < deadline else { throw InsertionError.modifierStillHeld }
      try? await Task.sleep(for: .milliseconds(10))
    }
  }

  /// Returns when ⌘V-down was posted, the reference point for receipt latency.
  static func postCommandV() async throws -> ContinuousClock.Instant {
    let source = CGEventSource(stateID: .privateState)
    guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
      let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
    else { throw InsertionError.eventPostFailed }
    down.flags = .maskCommand
    up.flags = .maskCommand
    let postedAt = ContinuousClock.now
    down.post(tap: .cghidEventTap)
    try? await Task.sleep(for: .milliseconds(5))
    up.post(tap: .cghidEventTap)
    return postedAt
  }
}
