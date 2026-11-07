import AVFoundation

/// Push-to-talk microphone capture. One instance lives for the app's lifetime;
/// `start` is called on key down and `stop` on key up.
///
/// Contract:
/// - `start(outputFormat:)` starts the engine and returns a stream of frames
///   converted to `outputFormat`. Calling it while already running throws.
/// - `stop()` stops the engine and finishes the stream. Calling it while idle
///   is a no-op.
/// - The time between `start` returning and the first frame is the engine
///   start latency; it is logged so experiment E5 can read it.
public actor AudioRecorder {
    public init() {}

    public static func hasMicrophoneAccess() -> Bool {
        fatalError("unimplemented")
    }

    public static func requestMicrophoneAccess() async -> Bool {
        fatalError("unimplemented")
    }

    public func start(outputFormat: AVAudioFormat) throws -> AsyncStream<AudioFrame> {
        fatalError("unimplemented")
    }

    public func stop() {
        fatalError("unimplemented")
    }
}
