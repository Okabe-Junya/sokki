import CoreGraphics
import IOKit.hidsystem

/// The generic flag of one modifier family and the device bits of its two sides.
enum ModifierFamily: CaseIterable {
  case control, option, shift, command, fn

  var genericMask: CGEventFlags {
    switch self {
    case .control: .maskControl
    case .option: .maskAlternate
    case .shift: .maskShift
    case .command: .maskCommand
    case .fn: .maskSecondaryFn
    }
  }

  var deviceMasks: UInt64 {
    switch self {
    case .control: UInt64(NX_DEVICELCTLKEYMASK | NX_DEVICERCTLKEYMASK)
    case .option: UInt64(NX_DEVICELALTKEYMASK | NX_DEVICERALTKEYMASK)
    case .shift: UInt64(NX_DEVICELSHIFTKEYMASK | NX_DEVICERSHIFTKEYMASK)
    case .command: UInt64(NX_DEVICELCMDKEYMASK | NX_DEVICERCMDKEYMASK)
    case .fn: 0
    }
  }
}
