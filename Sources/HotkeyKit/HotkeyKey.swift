/// Modifier keys that can be part of the push-to-talk chord. Only modifiers
/// (and fn) are allowed: the system withholds keyDown / keyUp from event taps
/// during secure input but still delivers flagsChanged, and a listen-only tap
/// cannot keep an ordinary key from reaching the frontmost app.
public enum HotkeyKey: String, Sendable, Codable, CaseIterable {
  case leftControl = "leftControl"
  case rightControl = "rightControl"
  case leftOption = "leftOption"
  case rightOption = "rightOption"
  case leftShift = "leftShift"
  case rightShift = "rightShift"
  case leftCommand = "leftCommand"
  case rightCommand = "rightCommand"
  case fn = "fn"

  public var isShift: Bool { self == .leftShift || self == .rightShift }
}

extension HotkeyKey: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    allCases.firstIndex(of: lhs) ?? 0 < allCases.firstIndex(of: rhs) ?? 0
  }
}
