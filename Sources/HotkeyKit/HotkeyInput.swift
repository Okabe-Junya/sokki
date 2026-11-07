import CoreGraphics

/// A raw key edge as decoded from a `CGEvent`.
enum HotkeyInput: Equatable {
  case flagsChanged(keyCode: CGKeyCode, flags: CGEventFlags)
  case keyDown(keyCode: CGKeyCode)
  case keyUp(keyCode: CGKeyCode)
}
