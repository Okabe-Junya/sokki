import Testing
@testable import HotkeyKit

@Test func hotkeyKeysAreStable() {
    #expect(HotkeyKey.rightOption.rawValue == "rightOption")
}
