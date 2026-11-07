import CoreGraphics
import Foundation
import os

/// Listens for one push-to-talk key with a listen-only `CGEventTap` and emits
/// `HotkeyEvent`s.
///
/// Contract:
/// - `events` is a single-consumer stream; it yields for the app's lifetime.
/// - `start()` creates the tap on a dedicated thread's run loop and re-enables
///   it on `.tapDisabledByTimeout` / `.tapDisabledByUserInput`.
/// - `stop()` tears the tap down and finishes `events`.
/// - Press / release / cancel / double-tap classification follows the timing
///   constants given to `init`.
public final class HotkeyMonitor: @unchecked Sendable {
  public let key: HotkeyKey
  public let minimumHold: Duration
  public let doubleTapWindow: Duration

  public let events: AsyncStream<HotkeyEvent>
  private let continuation: AsyncStream<HotkeyEvent>.Continuation

  private struct State {
    var machine: HotkeyStateMachine
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var runLoop: CFRunLoop?
  }

  private let state: OSAllocatedUnfairLock<State>

  public init(
    key: HotkeyKey,
    minimumHold: Duration = .milliseconds(300),
    doubleTapWindow: Duration = .milliseconds(300)
  ) {
    self.key = key
    self.minimumHold = minimumHold
    self.doubleTapWindow = doubleTapWindow
    (events, continuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)
    state = OSAllocatedUnfairLock(
      uncheckedState: State(
        machine: HotkeyStateMachine(
          key: key, minimumHold: minimumHold, doubleTapWindow: doubleTapWindow)
      ))
  }

  public static func hasInputMonitoringAccess() -> Bool {
    CGPreflightListenEventAccess()
  }

  /// Prompts the system dialog once; returns the current state.
  public static func requestInputMonitoringAccess() -> Bool {
    CGRequestListenEventAccess()
  }

  public func start() throws {
    guard Self.hasInputMonitoringAccess() else { throw HotkeyError.inputMonitoringDenied }

    try state.withLockUnchecked { state in
      guard state.tap == nil else { throw HotkeyError.alreadyRunning }
      let mask: CGEventMask = [CGEventType.flagsChanged, .keyDown, .keyUp]
        .reduce(0) { $0 | (1 << $1.rawValue) }
      guard
        let tap = CGEvent.tapCreate(
          tap: .cgSessionEventTap,
          place: .headInsertEventTap,
          options: .listenOnly,
          eventsOfInterest: mask,
          callback: { _, type, event, userInfo in
            if let userInfo {
              Unmanaged<HotkeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                .handle(type: type, event: event)
            }
            return Unmanaged.passUnretained(event)
          },
          // The tap thread's closure retains self until the run loop exits.
          userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
      else { throw HotkeyError.tapCreationFailed }
      state.tap = tap
      state.source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    }

    let ready = DispatchSemaphore(value: 0)
    let thread = Thread { [self] in runTapLoop(signalling: ready) }
    thread.name = "HotkeyKit.EventTap"
    thread.qualityOfService = .userInteractive
    thread.start()
    ready.wait()
  }

  public func stop() {
    state.withLockUnchecked { state in
      if let tap = state.tap {
        CGEvent.tapEnable(tap: tap, enable: false)
        CFMachPortInvalidate(tap)
      }
      if let runLoop = state.runLoop {
        CFRunLoopStop(runLoop)
      }
      state.tap = nil
      state.source = nil
      state.runLoop = nil
      state.machine = HotkeyStateMachine(
        key: key, minimumHold: minimumHold, doubleTapWindow: doubleTapWindow)
    }
    continuation.finish()
  }

  private func runTapLoop(signalling ready: DispatchSemaphore) {
    let runLoop = CFRunLoopGetCurrent()
    let tap = state.withLockUnchecked { state -> CFMachPort? in
      guard let tap = state.tap, let source = state.source else { return nil }
      state.runLoop = runLoop
      CFRunLoopAddSource(runLoop, source, .commonModes)
      CGEvent.tapEnable(tap: tap, enable: true)
      return tap
    }
    ready.signal()
    guard tap != nil else { return }
    CFRunLoopRun()
  }

  private func handle(type: CGEventType, event: CGEvent) {
    let keyCode = CGKeyCode(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
    let input: HotkeyInput
    switch type {
    case .flagsChanged: input = .flagsChanged(keyCode: keyCode, flags: event.flags)
    case .keyDown: input = .keyDown(keyCode: keyCode)
    case .keyUp: input = .keyUp(keyCode: keyCode)
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
      state.withLockUnchecked { state in
        if let tap = state.tap { CGEvent.tapEnable(tap: tap, enable: true) }
      }
      return
    default: return
    }
    let now = Duration.nanoseconds(clock_gettime_nsec_np(CLOCK_UPTIME_RAW))
    if let output = state.withLockUnchecked({ $0.machine.handle(input, at: now) }) {
      continuation.yield(output)
    }
  }
}
