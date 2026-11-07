import CoreGraphics
import Testing

@testable import HotkeyKit

struct HotkeyStateMachineTests {
  private struct Driver {
    var machine: HotkeyStateMachine
    var events: [HotkeyEvent] = []

    init(_ key: HotkeyKey) {
      machine = HotkeyStateMachine(
        key: key, minimumHold: .milliseconds(300), doubleTapWindow: .milliseconds(300))
    }

    mutating func send(_ input: HotkeyInput, atMs milliseconds: Int) {
      if let event = machine.handle(input, at: .milliseconds(milliseconds)) { events.append(event) }
    }

    mutating func rightOption(down: Bool, atMs milliseconds: Int) {
      send(
        .flagsChanged(
          keyCode: 0x3D, flags: down ? [.maskAlternate, CGEventFlags(rawValue: 0x40)] : []),
        atMs: milliseconds)
    }
  }

  @Test func shortTapIsCancelled() {
    var driver = Driver(.rightOption)
    driver.rightOption(down: true, atMs: 0)
    driver.rightOption(down: false, atMs: 100)
    #expect(driver.events == [.pressed, .cancelled])
  }

  @Test func holdIsReleasedWithDuration() {
    var driver = Driver(.rightOption)
    driver.rightOption(down: true, atMs: 1_000)
    driver.rightOption(down: false, atMs: 1_400)
    #expect(driver.events == [.pressed, .released(heldFor: .milliseconds(400))])
  }

  @Test func twoShortTapsWithinWindowAreDoubleTap() {
    var driver = Driver(.rightOption)
    driver.rightOption(down: true, atMs: 0)
    driver.rightOption(down: false, atMs: 80)
    driver.rightOption(down: true, atMs: 160)
    driver.rightOption(down: false, atMs: 240)
    #expect(driver.events == [.pressed, .cancelled, .pressed, .doubleTapped])
  }

  @Test func twoShortTapsOutsideWindowAreTwoCancels() {
    var driver = Driver(.rightOption)
    driver.rightOption(down: true, atMs: 0)
    driver.rightOption(down: false, atMs: 80)
    driver.rightOption(down: true, atMs: 500)
    driver.rightOption(down: false, atMs: 580)
    #expect(driver.events == [.pressed, .cancelled, .pressed, .cancelled])
  }

  @Test func interveningKeyBreaksDoubleTap() {
    var driver = Driver(.rightOption)
    driver.rightOption(down: true, atMs: 0)
    driver.rightOption(down: false, atMs: 80)
    driver.send(.keyDown(keyCode: 0x00), atMs: 120)
    driver.send(.keyUp(keyCode: 0x00), atMs: 130)
    driver.rightOption(down: true, atMs: 160)
    driver.rightOption(down: false, atMs: 240)
    #expect(driver.events == [.pressed, .cancelled, .pressed, .cancelled])
  }

  @Test func escapeWhileHeld() {
    var driver = Driver(.rightOption)
    driver.send(.keyDown(keyCode: 0x35), atMs: 0)
    driver.rightOption(down: true, atMs: 100)
    driver.send(.keyDown(keyCode: 0x35), atMs: 300)
    driver.rightOption(down: false, atMs: 600)
    #expect(driver.events == [.pressed, .escape, .released(heldFor: .milliseconds(500))])
  }

  @Test func fnWorksFromFlagsChangedAlone() {
    var driver = Driver(.fn)
    driver.send(.flagsChanged(keyCode: 0x3F, flags: .maskSecondaryFn), atMs: 0)
    driver.send(.flagsChanged(keyCode: 0x3F, flags: []), atMs: 350)
    driver.send(.flagsChanged(keyCode: 0x3F, flags: .maskSecondaryFn), atMs: 1_000)
    driver.send(.flagsChanged(keyCode: 0x3F, flags: []), atMs: 1_050)
    driver.send(.flagsChanged(keyCode: 0x3F, flags: .maskSecondaryFn), atMs: 1_100)
    driver.send(.flagsChanged(keyCode: 0x3F, flags: []), atMs: 1_150)
    #expect(
      driver.events == [
        .pressed, .released(heldFor: .milliseconds(350)), .pressed, .cancelled, .pressed,
        .doubleTapped,
      ])
  }

  @Test func rightOptionReleaseIsSeenWhileLeftOptionHeld() {
    var driver = Driver(.rightOption)
    driver.rightOption(down: true, atMs: 0)
    driver.send(
      .flagsChanged(keyCode: 0x3A, flags: [.maskAlternate, CGEventFlags(rawValue: 0x60)]), atMs: 100
    )
    driver.send(
      .flagsChanged(keyCode: 0x3D, flags: [.maskAlternate, CGEventFlags(rawValue: 0x20)]), atMs: 400
    )
    #expect(driver.events == [.pressed, .released(heldFor: .milliseconds(400))])
  }

  @Test func otherModifierKeyCodeIsIgnored() {
    var driver = Driver(.rightOption)
    driver.send(
      .flagsChanged(keyCode: 0x3A, flags: [.maskAlternate, CGEventFlags(rawValue: 0x20)]), atMs: 0)
    driver.send(.flagsChanged(keyCode: 0x3A, flags: []), atMs: 400)
    #expect(driver.events.isEmpty)
  }
}
