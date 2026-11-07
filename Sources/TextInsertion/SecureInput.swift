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
        unsafeDowncast(focused, to: AXUIElement.self), kAXSubroleAttribute as CFString, &subrole)
        == .success
    else { return false }
    return (subrole as? String) == kAXSecureTextFieldSubrole
  }
}
