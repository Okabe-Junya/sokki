import AppKit
import SwiftUI

struct GeneralSettingsView: View {
  let store: ConfigStore
  let actions: SettingsActions

  var body: some View {
    Form {
      dictation
      files
    }
    .formStyle(.grouped)
  }

  private var dictation: some View {
    Section("Dictation") {
      Picker(
        "Language",
        selection: Binding(
          get: { store.config.locale },
          set: { locale in store.update { $0.locale = locale } })
      ) {
        ForEach(Config.supportedLocales, id: \.self) { identifier in
          Text(Locale.current.localizedString(forIdentifier: identifier) ?? identifier)
        }
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
      if let problem = store.problem {
        Label(problem, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
      }
      LabeledContent("Settings") {
        HStack {
          Button("Open config.json", action: actions.openConfigFile)
          Button("Show Defaults", action: actions.showDefaults)
        }
      }
      LabeledContent("Personal dictionary") {
        Button("Open", action: actions.openDictionary)
      }
      LabeledContent("Folder") {
        HStack {
          Text(store.directory.path(percentEncoded: false))
            .truncationMode(.middle)
            .lineLimit(1)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
          Button("Show in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([store.directory])
          }
        }
      }
    } header: {
      Text("Files")
    } footer: {
      Text("This window edits config.json. Edits made elsewhere apply within a second.")
    }
  }
}
