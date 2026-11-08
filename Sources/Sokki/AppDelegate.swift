import ActivityLog
import AppKit
import AudioCapture
import Cleanup
import HotkeyKit
import TextInsertion
import Transcription
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private static let accessPollIntervalSeconds = 2
  private static let liveTextMaxCharacters = 60

  private let logger = Logger(subsystem: "dev.junya.sokki", category: "app")
  private let config = ConfigStore(directory: ConfigDirectory.url)
  private let dictionary = DictionaryStore(file: ConfigDirectory.dictionaryFile)
  private let activityLog = ActivityLog(file: ActivityEntry.file)
  private let permissionsWindow = PermissionsWindowController()
  private var settingsWindow: SettingsWindowController?
  private var statusItem: NSStatusItem?
  private var stateItem = NSMenuItem()
  private var liveItem = NSMenuItem()
  private var permissionsItem = NSMenuItem()
  private var session: DictationSession?
  private var hotkey: HotkeyMonitor?
  private var hotkeyTask: Task<Void, Never>?
  private var lastState: SessionState = .idle
  private var missingPermissions = Permission.missing

  func applicationDidFinishLaunching(_: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Sokki")
    item.menu = buildMenu()
    statusItem = item
    permissionsWindow.onChange = { [weak self] _ in self?.refreshPermissions() }
    settingsWindow = SettingsWindowController(
      store: config,
      actions: SettingsActions(
        openConfigFile: { [weak self] in self?.openConfigFile() },
        showDefaults: { [weak self] in self?.showDefaults() },
        openDictionary: { [weak self] in self?.openDictionary() }))

    let dictation = DictationSession(
      engine: AppleSpeechEngine(),
      recorder: AudioRecorder(),
      inserter: TextInserter(),
      dictionary: dictionary,
      observer: { [weak self] state, live in
        Task { @MainActor in self?.render(state, live: live) }
      },
      reporter: { [weak self] report in
        Task { @MainActor in self?.record(report) }
      })
    session = dictation
    config.onChange = { [weak self] previous, current in
      self?.configChanged(from: previous, to: current)
    }
    config.start()
    Task { await bootstrap(dictation) }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
    if missingPermissions.isEmpty {
      settingsWindow?.show()
    } else {
      permissionsWindow.show()
    }
    return false
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
    refreshPermissions()
    if !missingPermissions.isEmpty { permissionsWindow.show() }
    applyLoginItem(config.config.launchAtLogin)
    await prepareEngine(session)
    startHotkey(session)
  }

  private func configChanged(from previous: Config, to current: Config) {
    let summary =
      "hotkey \(current.hotkey.rawValue), locale \(current.locale), "
      + "launchAtLogin \(current.launchAtLogin)"
    logger.info("config: \(summary, privacy: .public)")
    guard let session else { return }
    if previous.hotkey != current.hotkey { startHotkey(session) }
    if previous.locale != current.locale { Task { await prepareEngine(session) } }
    if previous.launchAtLogin != current.launchAtLogin { applyLoginItem(current.launchAtLogin) }
    if lastState == .idle { render(.idle, live: "") }
  }

  private func record(_ report: UtteranceReport) {
    let entry = ActivityEntry(
      hotkey: config.config.hotkey, locale: config.config.locale, utterance: report)
    Task { [activityLog, logger] in
      do {
        try await activityLog.append(entry)
      } catch {
        logger.error("activity log: \(error)")
      }
    }
  }

  private func applyLoginItem(_ enabled: Bool) {
    do {
      try LoginItem.set(enabled: enabled)
    } catch {
      logger.error("launch at login: \(error)")
      render(.failed("launch at login: \(error.localizedDescription)"), live: "")
    }
  }

  private func prepareEngine(_ session: DictationSession) async {
    let locale = Locale(identifier: config.config.locale)
    render(.finalizing, live: "loading \(locale.identifier) model")
    do {
      try await session.prepare(locale: locale)
      render(.idle, live: "")
    } catch {
      logger.error("prepare failed: \(error)")
      render(.failed("model: \(error)"), live: "")
    }
  }

  private func startHotkey(_ session: DictationSession) {
    hotkeyTask?.cancel()
    hotkey?.stop()
    let monitor = HotkeyMonitor(key: config.config.hotkey)
    do {
      try monitor.start()
    } catch HotkeyError.inputMonitoringDenied {
      // The grant lands in System Settings without any notification; poll until it does.
      render(.failed("grant Input Monitoring in System Settings"), live: "")
      hotkeyTask = Task {
        while !HotkeyMonitor.hasInputMonitoringAccess() {
          try? await Task.sleep(for: .seconds(Self.accessPollIntervalSeconds))
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
    refreshPermissions()
    render(.idle, live: "")
    hotkeyTask = Task {
      for await event in monitor.events {
        await session.handle(event)
      }
    }
  }

  private func refreshPermissions() {
    missingPermissions = Permission.missing
    if lastState == .idle { render(.idle, live: "") }
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

    let settingsItem = NSMenuItem(
      title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
    settingsItem.target = self
    menu.addItem(settingsItem)
    let dictionaryItem = NSMenuItem(
      title: "Open Dictionary…", action: #selector(openDictionary), keyEquivalent: "")
    dictionaryItem.target = self
    menu.addItem(dictionaryItem)
    permissionsItem = NSMenuItem(
      title: "Permissions…", action: #selector(showPermissions), keyEquivalent: "")
    permissionsItem.target = self
    menu.addItem(permissionsItem)
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit Sokki", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    menu.delegate = self
    render(.idle, live: "")
    return menu
  }

  private func render(_ state: SessionState, live: String) {
    lastState = state
    let hotkeyName = config.config.hotkey.displayName
    let symbol: String
    switch state {
    case .idle where !missingPermissions.isEmpty:
      symbol = "mic.slash"
      stateItem.title =
        "Missing: \(missingPermissions.map(\.title).joined(separator: ", ")) — see Permissions…"
    case .idle where config.problem != nil:
      symbol = "exclamationmark.triangle"
      stateItem.title = "config.json could not be read — see Settings…"
    case .idle:
      symbol = "mic"
      stateItem.title = "Idle — hold \(hotkeyName) to dictate, double-tap for hands-free"
    case .listening(let locked):
      symbol = locked ? "waveform" : "mic.fill"
      stateItem.title =
        locked
        ? "Hands-free — tap \(hotkeyName) to insert, Esc to discard"
        : "Listening… (release to insert, Esc to discard)"
    case .finalizing:
      symbol = "ellipsis"
      stateItem.title = live.isEmpty ? "Finalizing…" : live
    case .inserting:
      symbol = "text.cursor"
      stateItem.title = "Inserting…"
    case .failed(let message):
      symbol = "mic.slash"
      stateItem.title = "Error: \(message)"
      if !Permission.missing.isEmpty { permissionsWindow.show() }
    }
    statusItem?.button?.image = NSImage(
      systemSymbolName: symbol, accessibilityDescription: stateItem.title)
    if state.isListening, !live.isEmpty {
      liveItem.title = String(live.suffix(Self.liveTextMaxCharacters))
      liveItem.isHidden = false
    } else {
      liveItem.isHidden = true
    }
  }

  @objc private func showSettings() {
    settingsWindow?.show()
  }

  @objc private func showPermissions() {
    permissionsWindow.show()
  }

  @objc private func openDictionary() {
    do {
      try dictionary.ensureExists()
      NSWorkspace.shared.open(ConfigDirectory.dictionaryFile)
    } catch {
      logger.error("dictionary file: \(error)")
      render(.failed("dictionary file: \(error)"), live: "")
    }
  }

  private func openConfigFile() {
    do {
      try config.ensureFileExists()
      NSWorkspace.shared.open(config.file)
    } catch {
      logger.error("config file: \(error)")
      render(.failed("config file: \(error)"), live: "")
    }
  }

  private func showDefaults() {
    do {
      NSWorkspace.shared.open(try config.defaultsFile())
    } catch {
      logger.error("defaults file: \(error)")
      render(.failed("defaults file: \(error)"), live: "")
    }
  }
}

extension AppDelegate: NSMenuDelegate {
  func menuNeedsUpdate(_: NSMenu) {
    refreshPermissions()
    let missing = missingPermissions.count
    permissionsItem.title = missing == 0 ? "Permissions…" : "Permissions… (\(missing) missing)"
  }
}
