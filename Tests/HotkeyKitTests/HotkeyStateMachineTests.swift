import CoreGraphics
import Testing

@testable import HotkeyKit

private struct Driver {
  var machine: HotkeyStateMachine
  var events: [HotkeyEvent] = []

  init(_ key: HotkeyKey) {
    machine = HotkeyStateMachine(
      key: key, minimumHold: .milliseconds(300), doubleTapWindow: .milliseconds(300))
  }

  mutating func send(_ input: HotkeyInput, atMs ms: Int) {
    if let event = machine.handle(input, at: .milliseconds(ms)) { events.append(event) }
  }

  mutating func rightOption(down: Bool, atMs ms: Int) {
    send(
      .flagsChanged(
        keyCode: 0x3D, flags: down ? [.maskAlternate, CGEventFlags(rawValue: 0x40)] : []), atMs: ms)
  }
}

@Test func shortTapIsCancelled() {
  var d = Driver(.rightOption)
  d.rightOption(down: true, atMs: 0)
  d.rightOption(down: false, atMs: 100)
  #expect(d.events == [.pressed, .cancelled])
}

@Test func holdIsReleasedWithDuration() {
  var d = Driver(.rightOption)
  d.rightOption(down: true, atMs: 1_000)
  d.rightOption(down: false, atMs: 1_400)
  #expect(d.events == [.pressed, .released(heldFor: .milliseconds(400))])
}

@Test func twoShortTapsWithinWindowAreDoubleTap() {
  var d = Driver(.rightOption)
  d.rightOption(down: true, atMs: 0)
  d.rightOption(down: false, atMs: 80)
  d.rightOption(down: true, atMs: 160)
  d.rightOption(down: false, atMs: 240)
  #expect(d.events == [.pressed, .cancelled, .pressed, .doubleTapped])
}

@Test func twoShortTapsOutsideWindowAreTwoCancels() {
  var d = Driver(.rightOption)
  d.rightOption(down: true, atMs: 0)
  d.rightOption(down: false, atMs: 80)
  d.rightOption(down: true, atMs: 500)
  d.rightOption(down: false, atMs: 580)
  #expect(d.events == [.pressed, .cancelled, .pressed, .cancelled])
}

@Test func interveningKeyBreaksDoubleTap() {
  var d = Driver(.rightOption)
  d.rightOption(down: true, atMs: 0)
  d.rightOption(down: false, atMs: 80)
  d.send(.keyDown(keyCode: 0x00), atMs: 120)
  d.send(.keyUp(keyCode: 0x00), atMs: 130)
  d.rightOption(down: true, atMs: 160)
  d.rightOption(down: false, atMs: 240)
  #expect(d.events == [.pressed, .cancelled, .pressed, .cancelled])
}

@Test func escapeWhileHeld() {
  var d = Driver(.rightOption)
  d.send(.keyDown(keyCode: 0x35), atMs: 0)
  d.rightOption(down: true, atMs: 100)
  d.send(.keyDown(keyCode: 0x35), atMs: 300)
  d.rightOption(down: false, atMs: 600)
  #expect(d.events == [.pressed, .escape, .released(heldFor: .milliseconds(500))])
}

@Test func fnWorksFromFlagsChangedAlone() {
  var d = Driver(.fn)
  d.send(.flagsChanged(keyCode: 0x3F, flags: .maskSecondaryFn), atMs: 0)
  d.send(.flagsChanged(keyCode: 0x3F, flags: []), atMs: 350)
  d.send(.flagsChanged(keyCode: 0x3F, flags: .maskSecondaryFn), atMs: 1_000)
  d.send(.flagsChanged(keyCode: 0x3F, flags: []), atMs: 1_050)
  d.send(.flagsChanged(keyCode: 0x3F, flags: .maskSecondaryFn), atMs: 1_100)
  d.send(.flagsChanged(keyCode: 0x3F, flags: []), atMs: 1_150)
  #expect(
    d.events == [
      .pressed, .released(heldFor: .milliseconds(350)), .pressed, .cancelled, .pressed,
      .doubleTapped,
    ])
}

@Test func rightOptionReleaseIsSeenWhileLeftOptionHeld() {
  var d = Driver(.rightOption)
  d.rightOption(down: true, atMs: 0)
  d.send(
    .flagsChanged(keyCode: 0x3A, flags: [.maskAlternate, CGEventFlags(rawValue: 0x60)]), atMs: 100)
  d.send(
    .flagsChanged(keyCode: 0x3D, flags: [.maskAlternate, CGEventFlags(rawValue: 0x20)]), atMs: 400)
  #expect(d.events == [.pressed, .released(heldFor: .milliseconds(400))])
}

@Test func otherModifierKeyCodeIsIgnored() {
  var d = Driver(.rightOption)
  d.send(
    .flagsChanged(keyCode: 0x3A, flags: [.maskAlternate, CGEventFlags(rawValue: 0x20)]), atMs: 0)
  d.send(.flagsChanged(keyCode: 0x3A, flags: []), atMs: 400)
  #expect(d.events.isEmpty)
}
