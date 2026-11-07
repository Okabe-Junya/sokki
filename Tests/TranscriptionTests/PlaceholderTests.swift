import Testing
@testable import Transcription

@Test func updatesAreEquatable() {
    #expect(TranscriptUpdate(text: "a", isFinal: true) == TranscriptUpdate(text: "a", isFinal: true))
}
