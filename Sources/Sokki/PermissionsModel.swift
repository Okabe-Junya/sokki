import Observation

/// Live permission state for the checklist; refreshed by the window's poll.
@MainActor @Observable
final class PermissionsModel {
  private(set) var granted: [Permission: Bool] = [:]

  var allGranted: Bool {
    Permission.allCases.allSatisfy { granted[$0] == true }
  }

  func refresh() {
    for permission in Permission.allCases {
      granted[permission] = permission.isGranted
    }
  }
}
