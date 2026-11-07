import CoreGraphics

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

    public init(
        key: HotkeyKey,
        minimumHold: Duration = .milliseconds(300),
        doubleTapWindow: Duration = .milliseconds(300)
    ) {
        self.key = key
        self.minimumHold = minimumHold
        self.doubleTapWindow = doubleTapWindow
    }

    public var events: AsyncStream<HotkeyEvent> {
        fatalError("unimplemented")
    }

    public static func hasInputMonitoringAccess() -> Bool {
        fatalError("unimplemented")
    }

    /// Prompts the system dialog once; returns the current state.
    public static func requestInputMonitoringAccess() -> Bool {
        fatalError("unimplemented")
    }

    public func start() throws {
        fatalError("unimplemented")
    }

    public func stop() {
        fatalError("unimplemented")
    }
}
