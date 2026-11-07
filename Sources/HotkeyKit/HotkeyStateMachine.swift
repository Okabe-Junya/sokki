import CoreGraphics

/// A raw key edge as decoded from a `CGEvent`.
enum HotkeyInput: Equatable {
  case flagsChanged(keyCode: CGKeyCode, flags: CGEventFlags)
  case keyDown(keyCode: CGKeyCode)
  case keyUp(keyCode: CGKeyCode)
}

/// Turns raw key edges for one push-to-talk key into `HotkeyEvent`s.
/// Timestamps are injected so the machine is testable without an event tap.
struct HotkeyStateMachine {
  static let escapeKeyCode: CGKeyCode = 0x35

  let key: HotkeyKey
  let minimumHold: Duration
  let doubleTapWindow: Duration

  private var pressedAt: Duration?
  private var pressInterrupted = false
  private var lastShortReleaseAt: Duration?

  init(key: HotkeyKey, minimumHold: Duration, doubleTapWindow: Duration) {
    self.key = key
    self.minimumHold = minimumHold
    self.doubleTapWindow = doubleTapWindow
  }

  mutating func handle(_ input: HotkeyInput, at time: Duration) -> HotkeyEvent? {
    switch input {
    case .flagsChanged(let keyCode, let flags) where keyCode == key.keyCode:
      let isDown = key.isDown(in: flags)
      if isDown, pressedAt == nil {
        pressedAt = time
        pressInterrupted = false
        return .pressed
      }
      if !isDown, let pressedAt {
        return release(heldFor: time - pressedAt, at: time)
      }
      return nil
    case .flagsChanged:
      interrupt()
      return nil
    case .keyDown(let keyCode):
      let wasHeld = pressedAt != nil
      interrupt()
      return wasHeld && keyCode == Self.escapeKeyCode ? .escape : nil
    case .keyUp:
      return nil
    }
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
    case .rightOption: 0x3D
    case .leftOption: 0x3A
    case .rightCommand: 0x36
    case .fn: 0x3F
    }
  }

  // NX_DEVICE*KEYMASK bits from IOLLEvent.h. The generic mask alone cannot tell
  // "right Option released while left Option is still held" from "still down".
  private var deviceMask: UInt64? {
    switch self {
    case .rightOption: 0x40
    case .leftOption: 0x20
    case .rightCommand: 0x10
    case .fn: nil
    }
  }

  private var siblingDeviceMasks: UInt64 {
    switch self {
    case .rightOption, .leftOption: 0x60
    case .rightCommand: 0x18
    case .fn: 0
    }
  }

  private var genericMask: CGEventFlags {
    switch self {
    case .rightOption, .leftOption: .maskAlternate
    case .rightCommand: .maskCommand
    case .fn: .maskSecondaryFn
    }
  }

  func isDown(in flags: CGEventFlags) -> Bool {
    guard flags.contains(genericMask) else { return false }
    guard let deviceMask, flags.rawValue & siblingDeviceMasks != 0 else { return true }
    return flags.rawValue & deviceMask != 0
  }
}
