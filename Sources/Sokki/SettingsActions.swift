/// Buttons in the settings window that need the app, not just the config store.
struct SettingsActions {
  let openConfigFile: @MainActor () -> Void
  let showDefaults: @MainActor () -> Void
  let openDictionary: @MainActor () -> Void
}
