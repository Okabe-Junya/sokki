/// Reasons `TextInserter.insert(_:)` can fail.
public enum InsertionError: Error, Sendable {
  /// Accessibility access has not been granted, so ⌘V cannot be posted.
  case accessibilityDenied
  /// A modifier key was still held when the paste was due.
  case modifierStillHeld
  /// The ⌘V keyboard events could not be created.
  case eventPostFailed
}
