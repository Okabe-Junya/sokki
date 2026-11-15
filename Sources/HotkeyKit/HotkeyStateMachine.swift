import Carbon.HIToolbox
import CoreGraphics
import IOKit.hidsystem

/// Turns raw key edges for one push-to-talk chord into `HotkeyEvent`s.
/// Timestamps are injected so the machine is testable without an event tap.
struct HotkeyStateMachine {
  static let escapeKeyCode = CGKeyCode(kVK_Escape)

  let hotkey: Hotkey
  let minimumHold: Duration
  let doubleTapWindow: Duration

  private var pressedAt: Duration?
  private var pressInterrupted = false
  // Set when another key cancelled the press: the chord's release that follows is not a gesture.
  private var awaitingRelease = false
  private var lastShortReleaseAt: Duration?

  init(hotkey: Hotkey, minimumHold: Duration, doubleTapWindow: Duration) {
    self.hotkey = hotkey
    self.minimumHold = minimumHold
    self.doubleTapWindow = doubleTapWindow
  }

  mutating func handle(_ input: HotkeyInput, at time: Duration) -> HotkeyEvent? {
    switch input {
    case .flagsChanged(let keyCode, let flags) where hotkey.contains(keyCode: keyCode):
      if pressedAt == nil, !awaitingRelease, hotkey.isExactlyDown(in: flags) {
        pressedAt = time
        pressInterrupted = false
        return .pressed
      }
      guard !hotkey.isDown(in: flags) else { return nil }
      if awaitingRelease {
        awaitingRelease = false
        return nil
      }
      if let pressedAt {
        return release(heldFor: time - pressedAt, at: time)
      }
      return nil
    case .flagsChanged(_, let flags):
      interrupt()
      return hotkey.hasForeignModifier(in: flags) ? cancelIfStillShort(at: time) : nil
    case .keyDown(let keyCode) where keyCode == Self.escapeKeyCode:
      interrupt()
      return .escape
    case .keyDown:
      interrupt()
      return cancelIfStillShort(at: time)
    case .keyUp:
      return nil
    }
  }

  /// A key joining the chord early makes it a shortcut; once the press counts as a hold it is ignored.
  private mutating func cancelIfStillShort(at time: Duration) -> HotkeyEvent? {
    guard let pressedAt, time - pressedAt < minimumHold else { return nil }
    self.pressedAt = nil
    awaitingRelease = true
    return .cancelled
  }

  private mutating func interrupt() {
    lastShortReleaseAt = nil
    if pressedAt != nil { pressInterrupted = true }
  }

  private mutating func release(heldFor: Duration, at time: Duration) -> HotkeyEvent {
    pressedAt = nil
    if heldFor >= minimumHold {
      lastShortReleaseAt = nil
      return .released(heldFor: heldFor)
    }
    if !pressInterrupted, let last = lastShortReleaseAt, time - last <= doubleTapWindow {
      lastShortReleaseAt = nil
      return .doubleTapped
    }
    lastShortReleaseAt = pressInterrupted ? nil : time
    return .cancelled
  }
}

extension HotkeyKey {
  var keyCode: CGKeyCode {
    switch self {
    case .leftControl: CGKeyCode(kVK_Control)
    case .rightControl: CGKeyCode(kVK_RightControl)
    case .leftOption: CGKeyCode(kVK_Option)
    case .rightOption: CGKeyCode(kVK_RightOption)
    case .leftShift: CGKeyCode(kVK_Shift)
    case .rightShift: CGKeyCode(kVK_RightShift)
    case .leftCommand: CGKeyCode(kVK_Command)
    case .rightCommand: CGKeyCode(kVK_RightCommand)
    case .fn: CGKeyCode(kVK_Function)
    }
  }

  var family: ModifierFamily {
    switch self {
    case .leftControl, .rightControl: .control
    case .leftOption, .rightOption: .option
    case .leftShift, .rightShift: .shift
    case .leftCommand, .rightCommand: .command
    case .fn: .fn
    }
  }

  // The generic mask alone cannot tell
  // "right Option released while left Option is still held" from "still down".
  var deviceMask: UInt64 {
    switch self {
    case .leftControl: UInt64(NX_DEVICELCTLKEYMASK)
    case .rightControl: UInt64(NX_DEVICERCTLKEYMASK)
    case .leftOption: UInt64(NX_DEVICELALTKEYMASK)
    case .rightOption: UInt64(NX_DEVICERALTKEYMASK)
    case .leftShift: UInt64(NX_DEVICELSHIFTKEYMASK)
    case .rightShift: UInt64(NX_DEVICERSHIFTKEYMASK)
    case .leftCommand: UInt64(NX_DEVICELCMDKEYMASK)
    case .rightCommand: UInt64(NX_DEVICERCMDKEYMASK)
    case .fn: 0
    }
  }

  func isDown(in flags: CGEventFlags) -> Bool {
    guard flags.contains(family.genericMask) else { return false }
    // Events without device bits (some virtual keyboards) only say the family is down.
    guard flags.rawValue & family.deviceMasks != 0 else { return true }
    return flags.rawValue & deviceMask != 0
  }
}

extension Hotkey {
  func contains(keyCode: CGKeyCode) -> Bool {
    keys.contains { $0.keyCode == keyCode }
  }

  /// Every key of the chord is down; other modifiers may be held too.
  func isDown(in flags: CGEventFlags) -> Bool {
    keys.allSatisfy { $0.isDown(in: flags) }
  }

  /// Every key of the chord is down and no other modifier is.
  func isExactlyDown(in flags: CGEventFlags) -> Bool {
    isDown(in: flags) && !hasForeignModifier(in: flags)
  }

  /// A modifier outside the chord is held. Caps Lock and the other non-modifier bits do not
  /// count, nor does the fn flag unless fn is in the chord: laptop arrow and function keys set it.
  func hasForeignModifier(in flags: CGEventFlags) -> Bool {
    ModifierFamily.allCases.contains { family in
      if family == .fn { return false }
      let members = keys.filter { $0.family == family }
      if members.isEmpty { return flags.contains(family.genericMask) }
      let others = family.deviceMasks & ~members.reduce(0) { $0 | $1.deviceMask }
      return flags.rawValue & others != 0
    }
  }
}
