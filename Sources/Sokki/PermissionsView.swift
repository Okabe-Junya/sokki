import SwiftUI

/// The onboarding checklist: one row per permission with its reason and a
/// direct link to the right System Settings pane.
struct PermissionsView: View {
  private enum Layout {
    static let width: CGFloat = 440
    static let padding: CGFloat = 20
    static let rowSpacing: CGFloat = 14
  }

  let model: PermissionsModel
  let locationWarning: String?

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.rowSpacing) {
      Text("Sokki needs three permissions")
        .font(.headline)
      Text("Nothing leaves this Mac. Each permission is used only for the step named below.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      ForEach(Permission.allCases, id: \.self) { permission in
        PermissionRow(permission: permission, granted: model.granted[permission] ?? false)
      }
      if let locationWarning {
        Label(locationWarning, systemImage: "exclamationmark.triangle")
          .font(.footnote)
      }
      Text(
        "This list updates by itself and closes once everything is granted. "
          + "If macOS asks you to quit and reopen Sokki, do that."
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .padding(Layout.padding)
    .frame(width: Layout.width)
  }
}
