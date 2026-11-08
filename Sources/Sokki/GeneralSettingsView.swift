import SwiftUI

struct GeneralSettingsView: View {
  let store: ConfigStore
  let actions: SettingsActions

  var body: some View {
    Form {
      values
      files
    }
    .formStyle(.grouped)
  }

  private var values: some View {
    Section {
      Picker(
        "Language",
        selection: Binding(
          get: { store.config.locale },
          set: { locale in store.update { $0.locale = locale } })
      ) {
        ForEach(Config.supportedLocales, id: \.self) { Text($0) }
      }
      Toggle(
        "Launch at login",
        isOn: Binding(
          get: { store.config.launchAtLogin },
          set: { enabled in store.update { $0.launchAtLogin = enabled } }))
    }
  }

  private var files: some View {
    Section {
      LabeledContent("Config file") {
        HStack {
          Button("Open", action: actions.openConfigFile)
          Button("Show Defaults", action: actions.showDefaults)
        }
      }
      LabeledContent("Dictionary") {
        Button("Open", action: actions.openDictionary)
      }
      Text(store.directory.path)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
      if let problem = store.problem {
        Label(problem, systemImage: "exclamationmark.triangle")
          .font(.footnote)
      }
    } footer: {
      Text(
        "Settings live in config.json; this window edits that file. "
          + "Edits made elsewhere apply within a second.")
    }
  }
}
