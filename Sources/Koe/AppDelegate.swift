import AppKit
import AudioCapture
import HotkeyKit
import TextInsertion
import Transcription
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let settings = Settings()
  private let logger = Logger(subsystem: "dev.okabe.koe", category: "app")
  private var statusItem: NSStatusItem?
  private var stateItem = NSMenuItem()
  private var liveItem = NSMenuItem()
  private var session: DictationSession?
  private var hotkey: HotkeyMonitor?
  private var hotkeyTask: Task<Void, Never>?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Koe")
    item.menu = buildMenu()
    statusItem = item

    let session = DictationSession(
      engine: AppleSpeechEngine(),
      recorder: AudioRecorder(),
      inserter: TextInserter()
    ) { [weak self] state, live in
      Task { @MainActor in self?.render(state, live: live) }
    }
    self.session = session
    Task { await bootstrap(session) }
  }

  private func bootstrap(_ session: DictationSession) async {
    if !AudioRecorder.hasMicrophoneAccess() {
      _ = await AudioRecorder.requestMicrophoneAccess()
    }
    if !HotkeyMonitor.hasInputMonitoringAccess() {
      _ = HotkeyMonitor.requestInputMonitoringAccess()
    }
    if !TextInserter.hasAccessibilityAccess() {
      _ = TextInserter.requestAccessibilityAccess()
    }
    await prepareEngine(session)
    startHotkey(session)
  }

  private func prepareEngine(_ session: DictationSession) async {
    render(.finalizing, live: "loading \(settings.locale.identifier) model")
    do {
      try await session.prepare(locale: settings.locale)
      render(.idle, live: "")
    } catch {
      logger.error("prepare failed: \(error)")
      render(.failed("model: \(error)"), live: "")
    }
  }

  private func startHotkey(_ session: DictationSession) {
    hotkeyTask?.cancel()
    hotkey?.stop()
    let monitor = HotkeyMonitor(key: settings.hotkey)
    do {
      try monitor.start()
    } catch HotkeyError.inputMonitoringDenied {
      // The grant lands in System Settings without any notification; poll until it does.
      render(.failed("grant Input Monitoring in System Settings"), live: "")
      hotkeyTask = Task {
        while !HotkeyMonitor.hasInputMonitoringAccess() {
          try? await Task.sleep(for: .seconds(2))
          if Task.isCancelled { return }
        }
        startHotkey(session)
      }
      return
    } catch {
      logger.error("hotkey start failed: \(error)")
      render(.failed("hotkey: \(error)"), live: "")
      return
    }
    hotkey = monitor
    render(.idle, live: "")
    hotkeyTask = Task {
      for await event in monitor.events {
        await session.handle(event)
      }
    }
  }

  // MARK: Menu

  private func buildMenu() -> NSMenu {
    let menu = NSMenu()
    stateItem.isEnabled = false
    liveItem.isEnabled = false
    liveItem.isHidden = true
    menu.addItem(stateItem)
    menu.addItem(liveItem)
    menu.addItem(.separator())

    let hotkeyMenu = NSMenu()
    for key in HotkeyKey.allCases {
      let item = NSMenuItem(
        title: Self.title(for: key), action: #selector(selectHotkey(_:)), keyEquivalent: "")
      item.representedObject = key.rawValue
      item.target = self
      hotkeyMenu.addItem(item)
    }
    let hotkeyRoot = NSMenuItem(title: "Hotkey", action: nil, keyEquivalent: "")
    hotkeyRoot.submenu = hotkeyMenu
    menu.addItem(hotkeyRoot)

    let localeMenu = NSMenu()
    for locale in Settings.supportedLocales {
      let item = NSMenuItem(
        title: locale.identifier, action: #selector(selectLocale(_:)), keyEquivalent: "")
      item.representedObject = locale.identifier
      item.target = self
      localeMenu.addItem(item)
    }
    let localeRoot = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
    localeRoot.submenu = localeMenu
    menu.addItem(localeRoot)
    menu.addItem(.separator())

    for permission in Permission.allCases {
      let item = NSMenuItem(
        title: permission.title, action: #selector(openPermission(_:)), keyEquivalent: "")
      item.representedObject = permission.rawValue
      item.target = self
      menu.addItem(item)
    }
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit Koe", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    menu.delegate = self
    render(.idle, live: "")
    return menu
  }

  private func render(_ state: SessionState, live: String) {
    let symbol: String
    switch state {
    case .idle:
      symbol = "mic"
      stateItem.title = "Idle — hold \(Self.title(for: settings.hotkey)) to dictate"
    case .listening:
      symbol = "mic.fill"
      stateItem.title = "Listening…"
    case .finalizing:
      symbol = "ellipsis"
      stateItem.title = live.isEmpty ? "Finalizing…" : live
    case .inserting:
      symbol = "text.cursor"
      stateItem.title = "Inserting…"
    case .failed(let message):
      symbol = "mic.slash"
      stateItem.title = "Error: \(message)"
    }
    statusItem?.button?.image = NSImage(
      systemSymbolName: symbol, accessibilityDescription: stateItem.title)
    if state == .listening, !live.isEmpty {
      liveItem.title = String(live.suffix(60))
      liveItem.isHidden = false
    } else {
      liveItem.isHidden = true
    }
  }

  @objc private func selectHotkey(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String, let key = HotkeyKey(rawValue: raw) else {
      return
    }
    settings.hotkey = key
    if let session { startHotkey(session) }
    render(.idle, live: "")
  }

  @objc private func selectLocale(_ sender: NSMenuItem) {
    guard let identifier = sender.representedObject as? String, let session else { return }
    settings.locale = Locale(identifier: identifier)
    Task { await prepareEngine(session) }
  }

  @objc private func openPermission(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String, let permission = Permission(rawValue: raw)
    else { return }
    NSWorkspace.shared.open(permission.settingsURL)
  }

  private static func title(for key: HotkeyKey) -> String {
    switch key {
    case .rightOption: "Right Option (⌥)"
    case .leftOption: "Left Option (⌥)"
    case .rightCommand: "Right Command (⌘)"
    case .fn: "fn / Globe"
    }
  }
}

extension AppDelegate: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    for item in menu.items {
      if let raw = item.representedObject as? String {
        if let permission = Permission(rawValue: raw) {
          item.state = permission.isGranted ? .on : .off
        }
      }
      for sub in item.submenu?.items ?? [] {
        guard let raw = sub.representedObject as? String else { continue }
        sub.state =
          (raw == settings.hotkey.rawValue || raw == settings.locale.identifier) ? .on : .off
      }
    }
  }
}

/// The three TCC permissions the app needs, with the System Settings pane for each.
enum Permission: String, CaseIterable {
  case microphone
  case inputMonitoring
  case accessibility

  var title: String {
    switch self {
    case .microphone: "Microphone"
    case .inputMonitoring: "Input Monitoring"
    case .accessibility: "Accessibility"
    }
  }

  var isGranted: Bool {
    switch self {
    case .microphone: AudioRecorder.hasMicrophoneAccess()
    case .inputMonitoring: HotkeyMonitor.hasInputMonitoringAccess()
    case .accessibility: TextInserter.hasAccessibilityAccess()
    }
  }

  var settingsURL: URL {
    let pane: String
    switch self {
    case .microphone: pane = "Privacy_Microphone"
    case .inputMonitoring: pane = "Privacy_ListenEvent"
    case .accessibility: pane = "Privacy_Accessibility"
    }
    return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
  }
}
