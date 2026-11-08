import SwiftUI

/// The permission checklist as a settings pane; polls while the pane is on screen.
struct PermissionsSettingsView: View {
  private static let pollInterval: Duration = .seconds(1)

  @State private var model = PermissionsModel()

  var body: some View {
    PermissionsView(model: model, locationWarning: nil)
      .task {
        while !Task.isCancelled {
          model.refresh()
          try? await Task.sleep(for: Self.pollInterval)
        }
      }
  }
}
