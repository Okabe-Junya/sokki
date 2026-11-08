import Foundation
import HotkeyKit
import Testing

struct HotkeyCodingTests {
  @Test func singleKeyIsItsName() throws {
    let data = try JSONEncoder().encode(Hotkey(.rightOption))
    #expect(String(bytes: data, encoding: .utf8) == "\"rightOption\"")
    #expect(try JSONDecoder().decode(Hotkey.self, from: data) == Hotkey(.rightOption))
  }

  @Test func chordIsSortedNamesJoinedByPlus() throws {
    let chord = try JSONDecoder().decode(Hotkey.self, from: Data(#""leftOption+leftControl""#.utf8))
    #expect(chord.keys == [.leftControl, .leftOption])
    #expect(
      String(bytes: try JSONEncoder().encode(chord), encoding: .utf8)
        == #""leftControl+leftOption""#)
  }

  @Test(arguments: ["", "+", "leftOption+", "leftOption+hyper"])
  func malformedNameIsRejected(_ name: String) {
    #expect(Hotkey(name: name) == nil)
  }

  @Test func shiftOnlyIsNotRecordable() throws {
    #expect(!Hotkey(.leftShift).isRecordable)
    #expect(try !#require(Hotkey(keys: [.leftShift, .rightShift])).isRecordable)
    #expect(try #require(Hotkey(keys: [.leftShift, .leftCommand])).isRecordable)
  }
}
