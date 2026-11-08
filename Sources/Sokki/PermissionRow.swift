import AppKit
import SwiftUI

struct PermissionRow: View {
  let permission: Permission
  let granted: Bool

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: granted ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(granted ? Color.green : Color.secondary)
        .imageScale(.large)
        .accessibilityLabel(granted ? "Granted" : "Not granted")
      VStack(alignment: .leading) {
        Text(permission.title)
          .bold()
        Text(permission.reason)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Spacer()
      if !granted {
        Button("Open Settings") {
          NSWorkspace.shared.open(permission.settingsURL)
        }
      }
    }
  }
}
