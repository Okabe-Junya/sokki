import HotkeyKit
import SwiftUI

struct HotkeySettingsView: View {
  let store: ConfigStore

  var body: some View {
    Form {
      Section {
        Picker(
          "Hold to dictate",
          selection: Binding(
            get: { store.config.hotkey },
            set: { key in store.update { $0.hotkey = key } })
        ) {
          ForEach(HotkeyKey.allCases, id: \.self) { Text($0.displayName) }
        }
      } footer: {
        if store.config.hotkey == .fn {
          Text(
            "fn / Globe needs System Settings → Keyboard → \"Press 🌐 key\" set to "
              + "\"Do Nothing\" and works only with Apple keyboards.")
        }
      }
      Section("Gestures") {
        gesture("Hold, speak, release", "Inserts the text", symbol: "hand.point.down")
        gesture("Double-tap", "Hands-free; the next tap inserts", symbol: "hand.tap")
        gesture("Escape", "Discards the current dictation", symbol: "escape")
        gesture("Tap under 300 ms", "Ignored", symbol: "timer")
      }
    }
    .formStyle(.grouped)
  }

  private func gesture(_ title: String, _ effect: String, symbol: String) -> some View {
    LabeledContent {
      Text(effect)
    } label: {
      Label(title, systemImage: symbol)
    }
  }
}
