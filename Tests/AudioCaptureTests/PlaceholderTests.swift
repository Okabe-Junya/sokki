import Testing
@testable import AudioCapture

@Test func errorsAreSendable() {
    let error: any Error & Sendable = AudioCaptureError.noInputDevice
    #expect(error is AudioCaptureError)
}
