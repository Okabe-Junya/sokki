import SwiftUI

/// Three panes; the selected one is remembered so the window reopens where it was left.
struct SettingsView: View {
  private enum Layout {
    static let width: CGFloat = 480
    static let height: CGFloat = 360
  }

  let store: ConfigStore
  let actions: SettingsActions
  @AppStorage("settings.selectedTab") private var selectedTab = "general"

  var body: some View {
    TabView(selection: $selectedTab) {
      GeneralSettingsView(store: store, actions: actions)
        .tabItem { Label("General", systemImage: "gearshape") }
        .tag("general")
      HotkeySettingsView(store: store)
        .tabItem { Label("Hotkey", systemImage: "keyboard") }
        .tag("hotkey")
      PermissionsSettingsView()
        .tabItem { Label("Permissions", systemImage: "lock.shield") }
        .tag("permissions")
    }
    .frame(width: Layout.width, height: Layout.height)
  }
}
