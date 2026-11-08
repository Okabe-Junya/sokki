import SwiftUI

/// The permission checklist as a settings pane; polls while the pane is on screen.
struct PermissionsSettingsView: View {
  private static let pollInterval: Duration = .seconds(1)

  @State private var model = PermissionsModel()

  var body: some View {
    Form {
      Section {
        ForEach(Permission.allCases, id: \.self) { permission in
          PermissionRow(permission: permission, granted: model.granted[permission] ?? false)
        }
      } header: {
        Text(model.allGranted ? "All permissions granted" : "Sokki needs three permissions")
      } footer: {
        Text("Nothing leaves this Mac. If macOS asks you to quit and reopen Sokki, do that.")
      }
    }
    .formStyle(.grouped)
    .task {
      while !Task.isCancelled {
        model.refresh()
        try? await Task.sleep(for: Self.pollInterval)
      }
    }
  }
}
