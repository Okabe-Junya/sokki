import HotkeyKit
import SwiftUI

struct HotkeySettingsView: View {
  let store: ConfigStore

  var body: some View {
    Form {
      Picker(
        "Hold to dictate",
        selection: Binding(
          get: { store.config.hotkey },
          set: { key in store.update { $0.hotkey = key } })
      ) {
        ForEach(Hotkey.presets, id: \.self) { Text($0.displayName) }
      }
      Section("Gestures") {
        LabeledContent("Hold, speak, release", value: "Inserts the text")
        LabeledContent("Double-tap", value: "Hands-free; the next tap inserts")
        LabeledContent("Escape", value: "Discards the current dictation")
        LabeledContent("Tap under 300 ms", value: "Ignored")
      }
      Section {
        Text(
          "fn / Globe needs System Settings → Keyboard → \"Press 🌐 key\" set to \"Do Nothing\" "
            + "and works only with Apple keyboards."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}
