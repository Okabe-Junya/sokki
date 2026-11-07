/// Keys that can drive push-to-talk. All are modifier keys (or fn), so they
/// keep working while secure input is active: the system withholds keyDown /
/// keyUp from event taps then, but still delivers flagsChanged.
public enum HotkeyKey: String, Sendable, Codable, CaseIterable {
  case rightOption = "rightOption"
  case leftOption = "leftOption"
  case rightCommand = "rightCommand"
  case fn = "fn"
}
