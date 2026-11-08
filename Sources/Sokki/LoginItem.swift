import ServiceManagement

/// Launch-at-login through the system login items list.
enum LoginItem {
  static var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  static func set(enabled: Bool) throws {
    guard enabled != isEnabled else { return }
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }
}
